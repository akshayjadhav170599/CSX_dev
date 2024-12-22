/**************************************************************************************
Apex Class Name     : CSX_CMP_InspectionAppWebservice
Function            : Class for Webservice to create Inspection & Detail Records.
                      Expected Format would be JSON with list of Headers & Details in seperate request.
                      May add limit on the no of records in single request. Assumption is max 100 records per request.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys             01/05/2024       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/inspections/*')
global with sharing class CSX_CMP_InspectionAppWebservice {
	@HttpPost
	global static void inspectionCreate() {
		RestRequest req = RestContext.request;
		RestResponse response = RestContext.response;
		integer statusCode;
		Boolean isRequestCompleted = true;
		String responseMessage = '';

		try {
			Schema.SObjectField externalIdField = CSX_CMP_Inspection_Header__c.Fields.CSX_CMP_External_ID__c;
			statusCode = response.statusCode;
			Map<String, String> detailDamageErrorMap = new Map<String, String>();
			Map<String, String> headerVINMap = new Map<String, String>();
			InspectionWrapper inspectionRec = (InspectionWrapper) JSON.deserialize(
				req.requestBody.toString(),
				InspectionWrapper.class
			);
			List<Vehicles> vehList = inspectionRec.Vehicles;
			if (!vehList.isEmpty()) {
				List<CSX_CMP_Inspection_Header__c> headerList = new List<CSX_CMP_Inspection_Header__c>();
				Map<String, String> vehMap = new Map<String, String>();
				Set<String> duplicateVehicleMap = new Set<String>();
				for (Vehicles veh : vehList) {
					if (!duplicateVehicleMap.contains(veh.VIN)) {
						String externalId = veh.VIN + '_' + inspectionRec.InspectionDateTime.split('T')[0];
						CSX_CMP_Inspection_Header__c header = new CSX_CMP_Inspection_Header__c();
						header.CSX_CMP_Source__c = inspectionRec.source;
						header.CSX_CMP_Inspection_Road__c = 'TDSI';
						header.CSX_CMP_Haulaway_Transaction_ID__c = inspectionRec.haulawayTransactionId;
						header.CSX_CMP_Ramp_Id__c = inspectionRec.rampId;
						header.CSX_CMP_Terminal_Name__c = inspectionRec.terminalName;
						header.CSX_CMP_Inspector_ID__c = inspectionRec.inspectorId;
						header.CSX_CMP_Inspection_City__c = inspectionRec.inspectionCity;
						header.CSX_CMP_Inspection_state__c = inspectionRec.inspectionState;
						header.CSX_CMP_Inspection_Date__c = Date.valueOf(inspectionRec.inspectionDateTime);
                        

						header.CSX_CMP_Company_SCAC__c = inspectionRec.Driver.companyScac;
						header.CSX_CMP_Haulaway_Company__c = inspectionRec.Driver.companyName;
						header.CSX_CMP_Driver_License_ID__c = inspectionRec.Driver.driverLicenseId;
						header.CSX_CMP_Driver_Name__c = inspectionRec.Driver.driverName;
						header.CSX_CMP_Driver_Email__c = inspectionRec.Driver.emailAddress;
						header.CSX_CMP_Driver_Phone_Number__c = inspectionRec.Driver.phoneNumber;

						header.CSX_CMP_VIN__c = veh.vin;
						header.CSX_CMP_Vehicle_Type__c = veh.vehicleType;
						header.CSX_CMP_Equipment_Initial__c = veh.RailCar.equipmentInitial;
						header.CSX_CMP_Equipment_Number__c = veh.RailCar.equipmentNumber;
						header.CSX_CMP_AAR_Equipment_Type__c = veh.RailCar.aarCarType;
						header.CSX_CMP_Seal_Status__c = veh.RailCar.sealStatus;
						header.CSX_CMP_Origin_Carrier__c = veh.originCarrier;
						header.CSX_CMP_Destination_Carrier__c = veh.destinationCarrier;
						if (!(String.isBlank(veh.shipDate))) {
							header.CSX_CMP_Shipment_Date__c = Date.valueOf(veh.shipDate);
						}
						header.CSX_CMP_Dealer_Code__c = veh.dealerCode;
						header.CSX_CMP_Route_Code__c = veh.routeCode;
						header.CSX_CMP_Bay_Locate__c = veh.bayLocation;
						header.CSX_CMP_Manufacturer__c = veh.mfrsCode;
						header.CSX_CMP_Image_Comments__c = veh.imageComments;
                        header.CSX_CMP_Inspection_Report_Type__c = veh.inspectionType;
                        header.CSX_CMP_Previous_Damage_Indicator__c = veh.previousDamageIndicator;
                        header.CSX_CMP_Verification_Reminder__c = veh.verificationReminder;
                        header.CSX_CMP_Haulaway_Comments__c = veh.haulawayComments;
                        header.CSX_CMP_Haulaway_Company__c = veh.haulawayCompanyName;

						header.CSX_CMP_External_ID__c = externalId;
						headerList.add(header);
						vehMap.put(externalId, '');
						duplicateVehicleMap.add(externalId);
					}
				}

				List<Id> headerIds = new List<Id>();
				Database.upsertresult[] sr = Database.upsert(headerList, externalIdField, false);
				for (Database.upsertresult s : sr) {
					if (s.isSuccess()) {
						headerIds.add(s.getId());
					} else {
						isRequestCompleted = false;
						for (Database.Error e : s.getErrors()) {
							responseMessage = e.getMessage();
						}
					}
				}

				Schema.SObjectField detailIdField = CSX_CMP_Inspection_Detail__c.Fields.CSX_CMP_External_ID__c;
				if (!headerIds.isEmpty()) {
					List<CSX_CMP_Inspection_Header__c> updatedHeaders = [
						SELECT Id, CSX_CMP_VIN__c, CSX_CMP_Inspection_Date__c
						FROM CSX_CMP_Inspection_Header__c
						WHERE Id IN :headerIds WITH SECURITY_ENFORCED
					];

					for (CSX_CMP_Inspection_Header__c header : updatedHeaders) {
						String key = header.CSX_CMP_VIN__c + '_' + String.valueOf(header.CSX_CMP_Inspection_Date__c).split('T')[0];
						vehMap.put(key, header.Id);
						headerVINMap.put(header.Id, header.CSX_CMP_VIN__c);
					}
					List<CSX_CMP_Inspection_Detail__c> damageList = new List<CSX_CMP_Inspection_Detail__c>();
					Set<String> duplicateDetailMap = new Set<String>();
					for (Vehicles veh : vehList) {
						String key = veh.VIN + '_' + inspectionRec.InspectionDatetime.split('T')[0];
						if (!veh.Damages.isEmpty()) {
							for (Damages dmg : veh.Damages) {
								String externalIdDetail = vehMap.get(key) + '_' + dmg.DamageItem + '_' + dmg.DamageType;
								if (!duplicateDetailMap.contains(externalIdDetail)) {
									CSX_CMP_Inspection_Detail__c damage = new CSX_CMP_Inspection_Detail__c();
									damage.CSX_CMP_Inspection_Header__c = vehMap.get(key);
									damage.CSX_CMP_Damage_Area__c = dmg.damageType;
									//damage.CSX_CMP_Damaged_Area__c = dmg.damageItem;
									damage.CSX_CMP_Damage_Type__c = dmg.damageItem;
									damage.CSX_CMP_Damage_Severity__c = dmg.damageSeverity;
									damage.CSX_CMP_Damage_Exc_Indicator__c = dmg.damageExclusionIndicator;
									damage.CSX_CMP_External_ID__c = externalIdDetail;
									damageList.add(damage);
									duplicateDetailMap.add(externalIdDetail);
								}
							}
						}
					}

					if (!damageList.isEmpty()) {
						Database.UpsertResult[] sr1 = Database.upsert(damageList, detailIdField, false);
						for (Integer i = 0; i < sr1.size(); i++) {
							if (sr1.get(i).isSuccess()) {
								isRequestCompleted = true;
							} else {
								for (Database.Error e : sr1.get(i).getErrors()) {
									isRequestCompleted = false;
									detailDamageErrorMap.put(
										headerVINMap.get(damageList.get(i).CSX_CMP_External_ID__c.split('_')[0]),
										e.getMessage()
									);
								}
							}
						}
					}
				}
			}

			if (detailDamageErrorMap.size() > 0) {
				responseMessage += JSON.serialize(detailDamageErrorMap);
			}

			if (!isRequestCompleted) {
				response.statusCode = 400;
				response.responseBody = Blob.valueOf('{"error" : ' + responseMessage + '}');
			} else {
				response.statusCode = 201;
				response.responseBody = Blob.valueOf(
					'{"success" : "Successfully Processed Inspection Data in Salesforce Claims."}'
				);
			}
		} catch (System.StringException ex) {
			response.statusCode = 400;
			response.responseBody = Blob.valueOf('{"error" : ' + ex.getMessage() + '}');
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Create Inspection Report',
				req.requestBody.toString(),
				''
			);
		} catch (System.QueryException ex) {
			response.statusCode = 404;
			response.responseBody = Blob.valueOf('{"error" : ' + ex.getMessage() + '}');
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Create Inspection Report',
				req.requestBody.toString(),
				''
			);
		} catch (Exception ex) {
			statusCode = response.statusCode;
			response.statusCode = 500;
			response.responseBody = Blob.valueOf('{"error" : ' + ex.getMessage() + '}');
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Create Inspection Report',
				req.requestBody.toString(),
				''
			);
		}
	}

	public class InspectionWrapper {
		public String source;
		public String haulawayTransactionId;
		public String rampId;
		public String terminalName;
		public String inspectorId;
		public String inspectionCity;
		public String inspectionState;
		public String inspectionDateTime;
		public Driver driver;
		public List<Vehicles> vehicles;
	}

	public class Driver {
		public String companyScac;
		public String companyName;
		public String driverLicenseId;
		public String driverName;
		public String emailAddress;
		public String phoneNumber;
	}

	public class Vehicles {
		public String vin;
		public String vehicleType;
		public String originCarrier;
		public String destinationCarrier;
		public String shipDate;
		public String dealerCode;
		public String routeCode;
		public String bayLocation;
		public String mfrsCode;
		public String imageComments;
        public String inspectionType;
        public String previousDamageIndicator;
        public String verificationReminder;
        public String haulawayComments;
        public String haulawayCompanyName;
		public RailCar railCar;
		public List<Damages> damages;
	}

	public class RailCar {
		public String equipmentInitial;
		public String equipmentNumber;
		public String aarCarType;
		public String sealStatus;
	}

	public class Damages {
		public String damageItem;
		public String damageType;
		public String damageSeverity;
		public String damageExclusionIndicator;
	}
}