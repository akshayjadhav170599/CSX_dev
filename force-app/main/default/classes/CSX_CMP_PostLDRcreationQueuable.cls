/*
RICEF ID : 413 - Implement L&D Creation Page
@author : Infosys
@description : This class is used to handle post creation external calls.
Modification Log:
Ver   Date         Author                               Modification
1.0                Subodh/Vaibhav                       Initial Version
*/
public class CSX_CMP_PostLDRcreationQueuable implements Queueable, Database.AllowsCallouts {
	public String ldrId;
	public String externalSource;
	public CSX_CMP_Creation_Request__c stagingRec;

	public CSX_CMP_PostLDRcreationQueuable(String ldrId, String source, CSX_CMP_Creation_Request__c stagingrecord) {
		this.ldrId = ldrId;
		this.externalSource = source;
		this.stagingRec = stagingrecord;
	}

	public void execute(QueueableContext context) {
		try {
			processLDR();
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_PostLDRCreationQueuable',
				'execute',
				JSON.serialize(stagingRec),
				e
			);
		}
	}

	public void processLDR() {
		CSX_CMP_LD_Report__c ldr = [
			SELECT
				Id,
				Name,
				CSX_CMP_LD_Type__c,
				CSX_CMP_Source__c,
				CSX_CMP_RAR_Num__c,
				CSX_CMP_Incident_Date__c,
				CSX_CMP_Track_ID__c,
				CSX_CMP_Multiple_BAD_Orders__c,
				CSX_CMP_Incident_State__c,
				CSX_CMP_Reported_Date__c,
				(SELECT Id, CSX_CMP_Equipment_Num__c, CSX_CMP_Equipment_Initial__c, CSX_CMP_Waybill_Date__c FROM Equipments__r)
			FROM CSX_CMP_LD_Report__c
			WHERE Id = :ldrId
			WITH SECURITY_ENFORCED
		];
		if (!ldr.Equipments__r.isEmpty()) {
			if (externalSource == 'UMLER') {
				List<String> equipmentIds = new List<String>();
				//need to do a callout and get the UMLER details for each equipment but with one callout
				Map<String, CSX_CMP_Equipment__c> eqpMap = new Map<String, CSX_CMP_Equipment__c>();
				List<CSX_CMP_Equipment__c> eqpListToUpdate = new List<CSX_CMP_Equipment__c>();
                
				for (CSX_CMP_Equipment__c eqp : ldr.Equipments__r) {
                    string equipInitial ='';
					string equipNumber ='';
                    string equipmentId ='';
					String equipmentIdForMap = eqp.CSX_CMP_Equipment_Initial__c;
                    if (eqp.CSX_CMP_Equipment_Initial__c.length() < 4) {
                        equipInitial = eqp.CSX_CMP_Equipment_Initial__c.rightPad(4, ' ');
                    } else {
                        equipInitial = eqp.CSX_CMP_Equipment_Initial__c;
                    }

					if(string.isNotBlank(eqp.CSX_CMP_Equipment_Num__c)){
						if (eqp.CSX_CMP_Equipment_Num__c.length() < 6) {
							equipNumber = eqp.CSX_CMP_Equipment_Num__c.leftPad(6, ' ');	
						} else {
							equipNumber = eqp.CSX_CMP_Equipment_Num__c;
						}
					}

                    if (string.isNotBlank(equipInitial) && string.isNotBlank(equipNumber)) {
                        equipmentId = equipInitial + equipNumber;
						equipNumber = equipNumber.replace(' ','0');
						equipmentIdForMap += equipNumber;
                    }
					equipmentIds.add(equipmentId);
					eqpMap.put(equipmentIdForMap, eqp);
				}
				stagingRec.CSX_CMP_UMLER_Fetch_Status__c = 'Pending';
				Map<String, List<CSX_CMP_InterfaceUtility.UmlerResponseWrapper>> umlerResponse = CSX_CMP_InterfaceUtility.fetchUmlerdetails(
					equipmentIds
				);
				if (umlerResponse.get('Success') != null) {
					for (CSX_CMP_InterfaceUtility.UmlerResponseWrapper umlerEqp : umlerResponse.get('Success')) {
						if(umlerEqp != null){

							CSX_CMP_Equipment__c eqp;
							if (eqpMap.containsKey(umlerEqp.carId)) {
								eqp = eqpMap.get(umlerEqp.carId);
							} else if (eqpMap.containsKey(umlerEqp.equipmentNumber)){
								eqp = eqpMap.get(umlerEqp.equipmentNumber);
							}
							if (eqp != null) {
								eqp.CSX_CMP_AAR_Car_Type__c = umlerEqp.aaaCarType != null ? umlerEqp.aaaCarType : '';
								eqp.CSX_CMP_Equipment_Group__c = umlerEqp.equipmentGroup != null ? umlerEqp.equipmentGroup : '';
								eqp.CSX_CMP_Inside_Length__c = umlerEqp.insideLength != null ? umlerEqp.insideLength : null;
								eqp.CSX_CMP_Inside_Width__c = umlerEqp.insideWidth != null ? umlerEqp.insideWidth : null;
								eqp.CSX_CMP_Actual_Owner__c = umlerEqp.actualOwner != null ? umlerEqp.actualOwner : '';
								eqp.CSX_CMP_Lessee__c = umlerEqp.lessee != null ? umlerEqp.lessee : '';
								eqp.CSX_CMP_Outer_Length__c = umlerEqp.outerLength != null ? umlerEqp.outerLength : null;

								eqpListToUpdate.add(eqp);
							}

							/*if(eqpMap.containsKey(umlerEqp.carId)){
								CSX_CMP_Equipment__c eqp = eqpMap.get(umlerEqp.carId);
								system.debug('eqp if::'+eqp);
								eqp.CSX_CMP_AAR_Car_Type__c = umlerEqp.aaaCarType != null ? umlerEqp.aaaCarType : '';
								eqp.CSX_CMP_Equipment_Group__c = umlerEqp.equipmentGroup != null ? umlerEqp.equipmentGroup : '';
								eqp.CSX_CMP_Inside_Length__c = umlerEqp.insideLength != null ? umlerEqp.insideLength : null;
								eqp.CSX_CMP_Inside_Width__c = umlerEqp.insideWidth != null ? umlerEqp.insideWidth : null;
								eqp.CSX_CMP_Actual_Owner__c = umlerEqp.actualOwner != null ? umlerEqp.actualOwner : '';
								eqp.CSX_CMP_Lessee__c = umlerEqp.lessee != null ? umlerEqp.lessee : '';
								eqp.CSX_CMP_Outer_Length__c = umlerEqp.outerLength != null ? umlerEqp.outerLength : null;
								eqpListToUpdate.add(eqp);
							}else{
								CSX_CMP_Equipment__c eqp = eqpMap.get(umlerEqp.equipmentNumber);
								system.debug('eqp else::'+eqp);
								eqp.CSX_CMP_AAR_Car_Type__c = umlerEqp.aaaCarType != null ? umlerEqp.aaaCarType : '';
								eqp.CSX_CMP_Equipment_Group__c = umlerEqp.equipmentGroup != null ? umlerEqp.equipmentGroup : '';
								eqp.CSX_CMP_Inside_Length__c = umlerEqp.insideLength != null ? umlerEqp.insideLength : null;
								eqp.CSX_CMP_Inside_Width__c = umlerEqp.insideWidth != null ? umlerEqp.insideWidth : null;
								eqp.CSX_CMP_Actual_Owner__c = umlerEqp.actualOwner != null ? umlerEqp.actualOwner : '';
								eqp.CSX_CMP_Lessee__c = umlerEqp.lessee != null ? umlerEqp.lessee : '';
								eqp.CSX_CMP_Outer_Length__c = umlerEqp.outerLength != null ? umlerEqp.outerLength : null;
								eqpListToUpdate.add(eqp);
							}*/
							
						}
					}
					stagingRec.CSX_CMP_UMLER_Fetch_Status__c = 'Completed';
				}

				CSX_CMP_LDRCreationController.updateStagingRecord(stagingRec);
				Database.SaveResult[] srEqp = Database.update(eqpListToUpdate, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_PostLDRCreationQueuable',
					'execute',
					srEqp,
					'CSX_CMP_Equipment__c'
				);
			} else if (externalSource == 'MTI') {
				for (CSX_CMP_Equipment__c eqp : ldr.Equipments__r) {
					CSX_CMP_InterfaceUtility.MTIRequestWrapper mtiRequest = new CSX_CMP_InterfaceUtility.MTIRequestWrapper();
					// mtiRequest.equipmentId = eqp.Id;
					// mtiRequest.incidentState = ldr.CSX_CMP_Incident_State__c;
					// mtiRequest.reportedDate = String.valueOf(eqp.CSX_CMP_Waybill_Date__c);

					mtiRequest.equipmentInitial = eqp.CSX_CMP_Equipment_Initial__c;
					mtiRequest.equipmentNumber = eqp.CSX_CMP_Equipment_Num__c;
					mtiRequest.waybillDate = String.valueOf(eqp.CSX_CMP_Waybill_Date__c);
					stagingRec.CSX_CMP_MTI_Fetch_Status__c = 'Pending';
					CSX_CMP_InterfaceUtility.MTIResponseWrapper mtiResponse = CSX_CMP_InterfaceUtility.fetchMTIDetail(mtiRequest);

					if (mtiResponse.status != 'error') {
						ldr.CSX_CMP_Track_ID__c = mtiResponse.trackId;
						ldr.CSX_CMP_Multiple_BAD_Orders__c = mtiResponse.multipleBadOrders != null
							? Boolean.valueOf(mtiResponse.multipleBadOrders)
							: false;
						ldr.CSX_CMP_Bad_Order_Comments__c = mtiResponse.badOrderNotes;
						stagingRec.CSX_CMP_MTI_Fetch_Status__c = 'Completed';
					} else {
						stagingRec.CSX_CMP_MTI_Fetch_Status__c = 'Error';
					}
					ldr.CSX_CMP_Incident_Date__c = mtiResponse.incidentDate != null
						? Date.valueOf(mtiResponse.incidentDate)
						: System.today();
				}

				CSX_CMP_LDRCreationController.updateStagingRecord(stagingRec);
				CSX_CMP_LDRCreationController.updateLDReportRecord(ldr);
			} else if (externalSource == 'RARS') {
				Date incidentDate = null;
				for (CSX_CMP_Equipment__c eqp : ldr.Equipments__r) {
					CSX_CMP_InterfaceUtility.RARSRequestWrapper rarsRequest = new CSX_CMP_InterfaceUtility.RARSRequestWrapper();
					rarsRequest.equipmentId = eqp.CSX_CMP_Equipment_Initial__c + '%20' + eqp.CSX_CMP_Equipment_Num__c;
					rarsRequest.incidentState = ldr.CSX_CMP_Incident_State__c;
					rarsRequest.fromReportedDate = String.valueOf(ldr.CSX_CMP_Reported_Date__c);
					CSX_CMP_InterfaceUtility.RARSResponseWrapper rarsResponse = CSX_CMP_InterfaceUtility.fetchRARSDetail(
						rarsRequest
					);
					incidentDate = rarsResponse.incidentDate != null ? Date.valueOf(rarsResponse.incidentDate) : System.today();
					if (rarsResponse.status == 'Success' || rarsResponse.status == 'No Results Found') {
						ldr.CSX_CMP_RAR_Num__c = rarsResponse.rarNumber;
						stagingRec.CSX_CMP_RARS_Fetch_Status__c = 'Completed';
						break;
					} else if (rarsResponse.status == 'Error') {
						stagingRec.CSX_CMP_RARS_Fetch_Status__c = 'Error';
						break;
					}
				}
				ldr.CSX_CMP_Incident_Date__c = incidentDate;

				CSX_CMP_LDRCreationController.updateStagingRecord(stagingRec);
				CSX_CMP_LDRCreationController.updateLDReportRecord(ldr);
			}
		}

		if (externalSource == 'UMLER' && ldr.CSX_CMP_LD_Type__c == 'In transit' && ldr.CSX_CMP_Source__c == 'Manual') {
			System.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(ldrId, 'MTI', stagingRec));
		} else if (
			externalSource == 'UMLER' &&
			ldr.CSX_CMP_LD_Type__c == 'Derailment' &&
			ldr.CSX_CMP_Source__c == 'Manual'
		) {
			System.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(ldrId, 'RARS', stagingRec));
		} else {
			stagingRec.CSX_CMP_Creation_Status__c = 'Completed';
			CSX_CMP_LDRCreationController.updateStagingRecord(stagingRec);
		}
	}
}