/*
RICEF ID : 413 - Implement L&D Creation Page
@author : Infosys
@description : This class is used to create new L&D Reports
@name : CSX_CMP_LDRCreationController
Modification Log:
Ver   Date         Author                               Modification
1.0                Subodh/Vaibhav                       Initial Version
*/
public with sharing class CSX_CMP_LDRCreationController {
	/*
    @description : This method is used to convert map from LDR creation page to wrapper
    @param : recordMap : Map of string and string which contains the LDR data
    @return : CSX_CMP_LDRRequestWrapper
    */
	public static CSX_CMP_LDRRequestWrapper convertMaptoWrapper(Map<String, String> recordMap) {
		CSX_CMP_LDRRequestWrapper ldReportWrapper = new CSX_CMP_LDRRequestWrapper();
		ldReportWrapper.reportType = recordMap.get('reportType');
		ldReportWrapper.contactName = recordMap.get('contactName');
		ldReportWrapper.phone = recordMap.get('phone');
		ldReportWrapper.email = recordMap.get('email');
		ldReportWrapper.incidentAction = recordMap.get('incidentAction');
		ldReportWrapper.estimatedLadingLoss = recordMap.get('estimatedLadingLoss');
		ldReportWrapper.incidentComments = recordMap.get('incidentComments');
		ldReportWrapper.bracingMethod = recordMap.get('bracingMethod');
		ldReportWrapper.disposition = recordMap.get('disposition');
		ldReportWrapper.productCondition = recordMap.get('productCondition');
		ldReportWrapper.source = recordMap.get('source');
		ldReportWrapper.visibleDamage = recordMap.get('visibleDamage') != null
			? Boolean.valueOf(recordMap.get('visibleDamage'))
			: false;
		ldReportWrapper.canNotUnload = recordMap.get('canNotUnload') != null
			? Boolean.valueOf(recordMap.get('canNotUnload'))
			: false;
		ldReportWrapper.damageReason = recordMap.get('damageReason');
		ldReportWrapper.cause = recordMap.get('cause');
		ldReportWrapper.damageLocation = recordMap.get('damageLocation');
		ldReportWrapper.trackId = recordMap.get('trackId');
		ldReportWrapper.unloadingExceededHours = recordMap.get('unloadingExceededHours') != null
			? Boolean.valueOf(recordMap.get('unloadingExceededHours'))
			: false;
		ldReportWrapper.incidentDate = String.isNotBlank(recordMap.get('incidentDate'))
			? Date.valueOf(recordMap.get('incidentDate'))
			: null;
		ldReportWrapper.multipleBadOrders = recordMap.get('multipleBadOrders') != null
			? Boolean.valueOf(recordMap.get('multipleBadOrders'))
			: false;
		ldReportWrapper.racfId = recordMap.get('racfId');
		ldReportWrapper.reportedDate = recordMap.get('reportedDate') != null
			? Date.valueOf(recordMap.get('reportedDate'))
			: Date.today();
		ldReportWrapper.sendEmail = recordMap.get('sendEmail') != null
			? Boolean.valueOf(recordMap.get('sendEmail'))
			: false;
		ldReportWrapper.noWaybillFlag = recordMap.get('noWaybillFlag') != null
			? Boolean.valueOf(recordMap.get('noWaybillFlag'))
			: false;
		ldReportWrapper.productRecords = recordMap.get('productRecords');
		ldReportWrapper.recoveryAmount = recordMap.get('recoveryAmount') != null
			? Decimal.valueOf(recordMap.get('recoveryAmount'))
			: null;
		ldReportWrapper.equipNo = recordMap.get('equipNo');
		ldReportWrapper.vin = recordMap.get('vin');
		ldReportWrapper.pickupAddress = recordMap.get('pickupAddress');

		ldReportWrapper.incidentState = recordMap.get('incidentState');
		ldReportWrapper.incidentCity = recordMap.get('incidentCity');
		ldReportWrapper.milepost = recordMap.get('milepost');
		ldReportWrapper.pickupState = recordMap.get('pickupState');
		ldReportWrapper.pickupCity = recordMap.get('pickupCity');
		ldReportWrapper.productConditionOther = recordMap.get('productConditionOther');
		ldReportWrapper.bracingMethodOther = recordMap.get('bracingMethodOther');
		ldReportWrapper.dispositionOther = recordMap.get('dispositionOther');
		ldReportWrapper.badOrderComments = recordMap.get('badOrderComments');
		//Populating Incident State
		if (String.isNotBlank(recordMap.get('incidentLocation'))) {
			ldReportWrapper.incidentLocation = recordMap.get('incidentLocation');
		}

		ldReportWrapper.contacts = new List<CSX_CMP_LD_Contact__c>();

		//Populating ReportedBy field
		ldReportWrapper.reportedBy = recordMap.get('reportedBy');
		ldReportWrapper.contactId = recordMap.get('contactId');

		Map<String, Contact> contactRACFMap = new Map<String, Contact>();
		Map<Id, Contact> contactIdMap = new Map<Id, Contact>();
		String contactQuery = 'SELECT Id, Name, Phone, Email,CSX_CMP_RACF_Id__c FROM Contact';
		List<String> whereClause = new List<String>();
		String reportedByValue = '';
		String contactIdValue = '';
		if (String.isNotBlank(ldReportWrapper.reportedBy)) {
			// whereClause.add('CSX_CMP_RACF_Id__c = \'' + ldReportWrapper.reportedBy + '\'');
			reportedByValue = String.valueOf(ldReportWrapper.reportedBy);
			whereClause.add('CSX_CMP_RACF_Id__c =: reportedByValue');
		}
		if (String.isNotBlank(ldReportWrapper.contactId)) {
			// whereClause.add('Id = \'' + ldReportWrapper.contactId + '\'');
			contactIdValue = String.valueOf(ldReportWrapper.contactId);
			whereClause.add('Id =: contactIdValue');
		}

		if (whereClause.size() > 0) {
			contactQuery = contactQuery + ' WHERE ' + String.join(whereClause, ' OR ');
			List<Contact> contacts = Database.query(String.escapeSingleQuotes(contactQuery));
			if (!contacts.isEmpty()) {
				for (Contact con : contacts) {
					contactRACFMap.put(con.CSX_CMP_RACF_Id__c, con);
					contactIdMap.put(con.Id, con);
				}
			}
		}

		if (String.isNotBlank(ldReportWrapper.reportedBy)) {
			if (contactRACFMap.containsKey(ldReportWrapper.reportedBy)) {
				CSX_CMP_LD_Contact__c newLDcontact = ldContact(
					null,
					contactRACFMap.get(ldReportWrapper.reportedBy),
					null,
					'ReportedBy'
				);
				ldReportWrapper.reportedById = contactRACFMap.get(ldReportWrapper.reportedBy).Id;
				ldReportWrapper.contacts.add(newLDcontact);
			}
		}

		if (String.isNotBlank(ldReportWrapper.contactId)) {
			if (contactIdMap.containsKey(ldReportWrapper.contactId)) {
				CSX_CMP_LD_Contact__c newLDcontact = ldContact(
					null,
					contactIdMap.get(ldReportWrapper.contactId),
					null,
					'L&D Contacts'
				);
				ldReportWrapper.contacts.add(newLDcontact);
			}
		}

		CSX_CMP_LD_Contact__c newContact = new CSX_CMP_LD_Contact__c();
		if (String.isNotBlank(ldReportWrapper.contactName)) {
			newContact.CSX_CMP_Contact_Name__c = ldReportWrapper.contactName;
		}
		if (String.isNotBlank(ldReportWrapper.phone)) {
			newContact.CSX_CMP_Phone_Number__c = ldReportWrapper.phone;
		}
		if (String.isNotBlank(ldReportWrapper.email)) {
			newContact.CSX_CMP_Email__c = ldReportWrapper.email;
		}

		if (String.isNotBlank(ldReportWrapper.racfId)) {
			newContact.CSX_CMP_RACF_ID__c = ldReportWrapper.racfId;
		}

		if (
			newContact.CSX_CMP_Contact_Name__c != null ||
			newContact.CSX_CMP_Phone_Number__c != null ||
			newContact.CSX_CMP_Email__c != null ||
			newContact.CSX_CMP_RACF_ID__c != null
		) {
			newContact.CSX_CMP_Contact_Role__c = 'L&D Contacts';
			ldReportWrapper.contacts.add(newContact);
		}

		ldReportWrapper.equipment = new List<Equipment>();
		if (String.isNotBlank(recordMap.get('equipment'))) {
			List<Object> shipments = (List<Object>) JSON.deserializeUntyped(recordMap.get('equipment'));
			if (!shipments.isEmpty()) {
				for (Object shipment : shipments) {
					Map<String, Object> shipmentMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(shipment));
					Equipment equip = new Equipment();
					equip.waybillDate = shipmentMap.get('waybillDate') != null
						? Date.valueOf(String.valueOf(shipmentMap.get('waybillDate')))
						: null;
					equip.waybillNumber = shipmentMap.get('waybillNumber') != null
						? String.valueOf(shipmentMap.get('waybillNumber'))
						: null;
					if (isNotNullOrEmpty(shipmentMap.get('shipper'))) {
						equip.shipper = String.valueOf(shipmentMap.get('shipper'));
					} else if (isNotNullOrEmpty(shipmentMap.get('shipperName'))) {
						equip.shipper = String.valueOf(shipmentMap.get('shipperName'));
					}
					if (isNotNullOrEmpty(shipmentMap.get('consignee'))) {
						equip.consignee = String.valueOf(shipmentMap.get('consignee'));
					} else if (isNotNullOrEmpty(shipmentMap.get('consigneeName'))) {
						equip.consignee = String.valueOf(shipmentMap.get('consigneeName'));
					}
					equip.urrwinNumber = shipmentMap.get('urrwinNumber') != null
						? String.valueOf(shipmentMap.get('urrwinNumber'))
						: null;
					equip.urrwinDate = shipmentMap.get('urrwinDate') != null
						? Date.valueOf(String.valueOf(shipmentMap.get('urrwinDate')))
						: null;
					equip.equipmentInitial = shipmentMap.get('equipmentInitial') != null
						? String.valueOf(shipmentMap.get('equipmentInitial'))
						: '';
					equip.equipmentInitial = String.isNotBlank(equip.equipmentInitial)
						? equip.equipmentInitial
						: System.Label.CSX_CMP_Default_Equipment_Initial;
					equip.equipmentNumber = shipmentMap.get('equipmentNumber') != null
						? String.valueOf(shipmentMap.get('equipmentNumber'))
						: '';
					equip.equipmentNumber = String.isNotBlank(equip.equipmentNumber)
						? equip.equipmentNumber
						: System.Label.CSX_CMP_Default_Equipment_Num;
					equip.stcc = shipmentMap.get('commodityNumber') != null
						? String.valueOf(shipmentMap.get('commodityNumber'))
						: null;
					if (equip.stcc == null) {
						equip.stcc = shipmentMap.get('stcc') != null ? String.valueOf(shipmentMap.get('stcc')) : null;
					}
					equip.stccDescription = shipmentMap.get('stccDescription') != null
						? String.valueOf(shipmentMap.get('stccDescription'))
						: null;
					equip.actualOriginState = shipmentMap.get('actualOriginState') != null
						? String.valueOf(shipmentMap.get('actualOriginState'))
						: null;
					if (equip.actualOriginState == null) {
						equip.actualOriginState = shipmentMap.get('actualOriginStateCode') != null
							? String.valueOf(shipmentMap.get('actualOriginStateCode'))
							: null;
					}

					equip.actualOriginCity = shipmentMap.get('actualOriginCity') != null
						? String.valueOf(shipmentMap.get('actualOriginCity'))
						: null;
					if (equip.actualOriginCity == null) {
						equip.actualOriginCity = shipmentMap.get('actualOriginCityName') != null
							? String.valueOf(shipmentMap.get('actualOriginCityName'))
							: null;
					}
					equip.actualOriginSCAC = shipmentMap.get('actualOriginSCAC') != null
						? String.valueOf(shipmentMap.get('actualOriginSCAC'))
						: null;
					equip.originRoadNumber = shipmentMap.get('originRoadNumber') != null
						? String.valueOf(shipmentMap.get('originRoadNumber'))
						: null;
					equip.originAuditNumber = shipmentMap.get('originAuditNumber') != null
						? String.valueOf(shipmentMap.get('originAuditNumber'))
						: null;
					equip.actDestinationState = shipmentMap.get('actDestinationState') != null
						? String.valueOf(shipmentMap.get('actDestinationState'))
						: null;
					if (equip.actDestinationState == null) {
						equip.actDestinationState = shipmentMap.get('actualDestinationStateCode') != null
							? String.valueOf(shipmentMap.get('actualDestinationStateCode'))
							: null;
					}
					equip.actDestinationCity = shipmentMap.get('actualDestinationCityName') != null
						? String.valueOf(shipmentMap.get('actualDestinationCityName'))
						: null;
					equip.unitType = shipmentMap.get('unitType') != null ? String.valueOf(shipmentMap.get('unitType')) : null;
					equip.numberOfCars = shipmentMap.get('numberOfCars') != null
						? Integer.valueOf(shipmentMap.get('numberOfCars'))
						: null;
					equip.unitRefundPrice = shipmentMap.get('unitRefundPrice') != null
						? Decimal.valueOf((String) shipmentMap.get('unitRefundPrice'))
						: null;
					equip.flatCar = shipmentMap.get('flatCar') != null ? String.valueOf(shipmentMap.get('flatCar')) : null;
					if (equip.flatCar == null) {
						equip.flatCar = shipmentMap.get('flatCarId') != null ? String.valueOf(shipmentMap.get('flatCarId')) : null;
					}
					if (isNotNullOrEmpty(shipmentMap.get('shipperLegalEntityCode'))) {
						equip.shipperLegalEntityCode = String.valueOf(shipmentMap.get('shipperLegalEntityCode'));
					} else if (isNotNullOrEmpty(shipmentMap.get('shipperLegalEntityId'))) {
						equip.shipperLegalEntityCode = String.valueOf(shipmentMap.get('shipperLegalEntityId'));
					}

					if (isNotNullOrEmpty(shipmentMap.get('consigneeLegalEntityCode'))) {
						equip.consigneeLegalEntityCode = String.valueOf(shipmentMap.get('consigneeLegalEntityCode'));
					} else if (isNotNullOrEmpty(shipmentMap.get('consigneeLegalEntityId'))) {
						equip.consigneeLegalEntityCode = String.valueOf(shipmentMap.get('consigneeLegalEntityId'));
					}

					if (isNotNullOrEmpty(shipmentMap.get('waybillControlCode'))) {
						equip.waybillControlCode = String.valueOf(shipmentMap.get('waybillControlCode'));
					} else if (isNotNullOrEmpty(shipmentMap.get('waybillControls'))) {
						equip.waybillControlCode = String.valueOf(shipmentMap.get('waybillControls'));
					}
					equip.destinationAuditNumber = shipmentMap.get('destinationAuditNumber') != null
						? String.valueOf(shipmentMap.get('destinationAuditNumber'))
						: null;

					if (isNotNullOrEmpty(shipmentMap.get('actDestinationRoad'))) {
						equip.actualDestinationSCAC = String.valueOf(shipmentMap.get('actDestinationRoad'));
					} else if (isNotNullOrEmpty(shipmentMap.get('actualDestinationSCAC'))) {
						equip.actualDestinationSCAC = String.valueOf(shipmentMap.get('actualDestinationSCAC'));
					}
					equip.products = new List<Product>();

					if (shipmentMap.get('products') != null) {
						List<Product> products = (List<Product>) JSON.deserialize(
							JSON.serialize(shipmentMap.get('products')),
							List<Product>.class
						);
						equip.products.addAll(products);
					}
					ldReportWrapper.equipment.add(equip);
				}
			}
		}

		return ldReportWrapper;
	}

	/*
    @description : This method is used to create new LDR report into staging record
    @param : recordMap : Map of string and string which contains the LDR data
    @return : CSX_CMP_LDRResponseWrapper
    */
	@AuraEnabled
	public static CSX_CMP_LDRResponseWrapper createLDReport(Map<String, String> recordMap) {
		CSX_CMP_Creation_Request__c stagingrecord = new CSX_CMP_Creation_Request__c();
		CSX_CMP_LDRResponseWrapper ldrResponse = new CSX_CMP_LDRResponseWrapper();
		String response;
		try {
			CSX_CMP_LDRRequestWrapper ldReportWrapper = convertMaptoWrapper(recordMap);
			stagingrecord.CSX_CMP_Request_Payload__c = JSON.serialize(ldReportWrapper);
			stagingrecord.CSX_CMP_Source__c = ldReportWrapper.source;
			stagingrecord.CSX_CMP_Object_Type__c = 'L&D Report';
			stagingrecord.CSX_CMP_Creation_Status__c = 'Not Started';
			stagingrecord.CSX_CMP_UMLER_Fetch_Status__c = 'Pending';
			stagingrecord.CSX_CMP_MTI_Fetch_Status__c = (ldReportWrapper.reportType == 'In transit')
				? 'Pending'
				: 'Not Applicable';
			stagingRecord.CSX_CMP_RARS_Fetch_Status__c = (ldReportWrapper.reportType == 'Derailment')
				? 'Pending'
				: 'Not Applicable';
			if (stagingrecord.CSX_CMP_Request_Payload__c != null) {
				Database.SaveResult ldrStagingRecord = Database.Insert(stagingrecord, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_LDRCreationController',
					'createLDReport',
					ldrStagingRecord,
					'CSX_CMP_Creation_Request__c'
				);
				if (ldrStagingRecord.isSuccess()) {
					response = insertLDReport(stagingrecord);
					if (response.length() != 18) {
						ldrResponse.errorMessage = response;
					} else {
						CSX_CMP_LD_Report__c ldr = [
							SELECT Id, Name, CSX_CMP_ECM_Link__c
							FROM CSX_CMP_LD_Report__c
							WHERE Id = :response
							WITH SECURITY_ENFORCED
						];
						ldrResponse.ldrId = ldr.Id;
						ldrResponse.ldrName = ldr.Name;
						ldrResponse.ecmLink = ldr.CSX_CMP_ECM_Link__c;
					}
				}

				if (response != null) {
					system.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(response, 'UMLER', stagingrecord));
				}
			}
		} catch (Exception e) {
			ldrResponse.errorMessage = e.getMessage();
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LDRCreationController',
				'createLDReport',
				JSON.serialize(recordMap),
				e
			);
		}
		return ldrResponse;
	}

	/*
    @description : This method is used to insert new LDR report from staging record
    @param : stagingrecord : CSX_CMP_Creation_Request__c which contains the LDR data
    @return : Id of CSX_CMP_LD_Report__c
    */
	public static String insertLDReport(CSX_CMP_Creation_Request__c stagingrecord) {
		String response;
		String recordTypeId = Schema.SObjectType.CSX_CMP_LD_Report__c.getRecordTypeInfosByDeveloperName()
			.get('L_D_Report')
			.getRecordTypeId();
		try {
			String ldrName;
			CSX_CMP_LDRRequestWrapper ldReportWrapper = (CSX_CMP_LDRRequestWrapper) JSON.deserialize(
				stagingrecord.CSX_CMP_Request_Payload__c,
				CSX_CMP_LDRRequestWrapper.class
			);
			CSX_CMP_LD_Report__c ldReport = new CSX_CMP_LD_Report__c();
			ldReport.RecordTypeId = recordTypeId;
			ldReport.CSX_CMP_LD_Type__c = ldReportWrapper.reportType;
			ldReport.CSX_CMP_Incident_Location__c = ldReportWrapper.incidentLocation;
			ldReport.CSX_CMP_Reported_By__c = ldReportWrapper.reportedBy;
			ldReport.CSX_CMP_Source__c = ldReportWrapper.source;
			ldReport.CSX_CMP_Damage_Reason__c = ldReportWrapper.damageReason;
			ldReport.CSX_CMP_Incident_Date__c = ldReportWrapper.incidentDate;
			ldReport.CSX_CMP_Cause__c = ldReportWrapper.cause;
			ldReport.CSX_CMP_Incident_Action__c = ldReportWrapper.incidentAction;
			ldReport.CSX_CMP_Est_Value_Exceed_Threshold__c = ldReportWrapper.estimatedLadingLoss != null
				? Boolean.valueOf(ldReportWrapper.estimatedLadingLoss)
				: false;
			ldReport.CSX_CMP_Incident_Comments__c = ldReportWrapper.incidentComments;
			ldReport.CSX_CMP_Bracing_Method__c = ldReportWrapper.bracingMethod;
			ldReport.CSX_CMP_Disposition__c = ldReportWrapper.disposition;
			ldReport.CSX_CMP_Product_Condition__c = ldReportWrapper.productCondition;
			ldReport.CSX_CMP_Visible_Damage__c = ldReportWrapper.visibleDamage;
			ldReport.CSX_CMP_Can_Not_Unload__c = ldReportWrapper.canNotUnload;
			ldReport.CSX_CMP_Damage_Location__c = ldReportWrapper.damageLocation;
			ldReport.CSX_CMP_Unloading_Exceeded_hr__c = ldReportWrapper.unloadingExceededHours;
			ldReport.CSX_CMP_Reported_Date__c = ldReportWrapper.reportedDate != null
				? ldReportWrapper.reportedDate
				: Date.today();
			ldReport.CSX_CMP_Recovery_Amount__c = ldReportWrapper.recoveryAmount;
			ldReport.CSX_CMP_Pick_Up_Address__c = ldReportWrapper.pickupAddress;
			ldReport.CSX_CMP_Multiple_BAD_Orders__c = ldReportWrapper.multipleBadOrders;
			ldReport.CSX_CMP_Track_ID__c = ldReportWrapper.trackId;
			ldReport.CSX_CMP_Pick_Up_City__c = ldReportWrapper.pickupCity;
			ldReport.CSX_CMP_Pick_Up_State__c = ldReportWrapper.pickupState;
			ldReport.CSX_CMP_Product_Condition_Other__c = ldReportWrapper.productConditionOther;
			ldReport.CSX_CMP_Disposition_other__c = ldReportWrapper.dispositionOther;
			ldReport.CSX_CMP_Bracing_Method_Other__c = ldReportWrapper.bracingMethodOther;
			ldReport.CSX_CMP_Bad_Order_Comments__c = ldReportWrapper.badOrderComments;
			if(ldReportWrapper.reportedById != null){
				ldReport.CSX_CMP_Reported_By_Lookup__c = ldReportWrapper.reportedById;
			}
			/*
                Owner Assignment Logic
                //invoke Owner assignment based on L&D assignment Business rules
                //Below mentioned method name is not final, it will be updated once the business rules are finalized
                CSX_CMP_BusinessRulesUtility.fetchOwner(ldReport);
            */
			Database.SaveResult ldReportResults = Database.insert(ldReport, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_LDRCreationController',
				'insertLDReport',
				ldReportResults,
				'CSX_CMP_LD_Report__c'
			);

			if (ldReportResults.isSuccess()) {
				CSX_CMP_LD_Report__c ldr = [
					SELECT Id, Name, CSX_CMP_Auto_Number__c
					FROM CSX_CMP_LD_Report__c
					WHERE Id = :ldReportResults.getId()
					WITH SECURITY_ENFORCED
				];
				//add in querry CSX_CMP_Auto_Number__c
				if (ldReportWrapper.reportType == 'Derailment') {
					ldrName = 'D-' + ldr.CSX_CMP_Auto_Number__c;
				} else if (ldReportWrapper.reportType == 'Customer') {
					ldrName = 'C-' + ldr.CSX_CMP_Auto_Number__c;
				} else if (ldReportWrapper.reportType == 'In transit') {
					ldrName = 'I-' + ldr.CSX_CMP_Auto_Number__c;
				} else if (ldReportWrapper.reportType == 'Recovery') {
					ldrName = 'R-' + ldr.CSX_CMP_Auto_Number__c;
				}
				ldr.Name = ldrName;
				Database.SaveResult[] ldReportUpdateResults = Database.update(new List<CSX_CMP_LD_Report__c>{ ldr }, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_LDRCreationController',
					'insertLDReport',
					ldReportUpdateResults,
					'CSX_CMP_LD_Report__c'
				);

				stagingrecord.CSX_CMP_LD_Report__c = ldr.Id;
				stagingRecord.CSX_CMP_Creation_Status__c = 'In Progress';
				updateStagingRecord(stagingrecord);

				if (!ldReportWrapper.equipment.isEmpty()) {
					// for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equip : ldReportWrapper.equipment) {
					// 	equip.ldReportId = ldReport.Id;
					// }
					for (Equipment equip : ldReportWrapper.equipment) {
						equip.ldReportId = ldReport.Id;
					}
				}

				List<CSX_CMP_Equipment__c> newEquipments = new List<CSX_CMP_Equipment__c>();
				if (!ldReportWrapper.equipment.isEmpty()) {
					Map<String, object> equipmentResponse = createEquipment(ldReportWrapper.equipment);
					if (equipmentResponse.containsKey('error')) {
						response = (String) equipmentResponse.get('error');
					} else if (equipmentResponse.containsKey('success')) {
						newEquipments = (List<CSX_CMP_Equipment__c>) equipmentResponse.get('success');
						Map<String, String> equipmentIdNumberMap = new Map<String, String>();
						for (CSX_CMP_Equipment__c equipment : newEquipments) {
							equipmentIdNumberMap.put(
								equipment.CSX_CMP_Equipment_Initial__c +
								equipment.CSX_CMP_Equipment_Num__c +
								equipment.CSX_CMP_Waybill_Num__c,
								equipment.Id
							);
						}
						//This logic will only be applied for Customer and this will only contain one equipment
						if (
							String.isNotBlank(ldReportWrapper.productRecords) &&
							ldReportWrapper.reportType == 'Customer' &&
							!newEquipments.isEmpty()
						) {
							List<Product> products = (List<Product>) JSON.deserialize(
								ldReportWrapper.productRecords,
								List<Product>.class
							);
							for (Equipment equip : ldReportWrapper.equipment) {
								equip.products.addAll(products);
							}
						}
						createProduct(ldReportWrapper.equipment, equipmentIdNumberMap);
						// if(ldReportWrapper.reportType == 'Customer'){
						// String con;
						// if(ldReportWrapper.contactId != null && ldReportWrapper.contactId != ''){
						//     con = ldReportWrapper.contactId;
						// }
						// } else if(String.isNotBlank(ldReportWrapper.contactName) || String.isNotBlank(ldReportWrapper.phone) || String.isNotBlank(ldReportWrapper.email)){
						//     String query = 'SELECT Id FROM Contact WHERE ';
						//     List<String> whereClause = new List<String>();
						//     if(String.isNotBlank(ldReportWrapper.contactName)){
						//         whereClause.add('Name LIKE '+ '\'%'+String.escapeSingleQuotes(ldReportWrapper.contactName)+'%\'');
						//     }
						//     if(String.isNotBlank(ldReportWrapper.phone)){
						//         whereClause.add('Phone LIKE '+ '\'%'+String.escapeSingleQuotes(ldReportWrapper.phone)+'%\'');
						//     }
						//     if(String.isNotBlank(ldReportWrapper.email)){
						//         whereClause.add('Email LIKE '+ '\'%'+String.escapeSingleQuotes(ldReportWrapper.email)+'%\'');
						//     }
						//     query = query + String.join(whereClause,' AND ');
						//     query = query + ' LIMIT 1';
						//     List<Contact> contacts = Database.query(query);
						//     if(!contacts.isEmpty()){
						//         con = contacts[0].Id;
						//     }
						// }

						// if (String.isNotBlank(ldReportWrapper.contactId)) {
						// 	CSX_CMP_LD_Contact__c newLDcontact = ldContact(null, ldReportWrapper.contactId, ldr.Id, 'ReportedBy');
						// 	Database.SaveResult ldContactInsert = Database.insert(newLDcontact, false);
						// 	CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						// 		'CSX_CMP_LDRCreationController',
						// 		'insertLDReport',
						// 		ldContactInsert,
						// 		'CSX_CMP_LD_Contact__c'
						// 	);
						// }

						// }

						if (ldReportWrapper.contacts != null && !ldReportWrapper.contacts.isEmpty()) {
							for (CSX_CMP_LD_Contact__c contact : ldReportWrapper.contacts) {
								contact.CSX_CMP_LD_Report__c = ldr.Id;
							}
							Database.SaveResult[] ldContactInsert = Database.insert(ldReportWrapper.contacts, false);
							CSX_CMP_LoggerUtility.addApexDMLErrorLog(
								'CSX_CMP_LDRCreationController',
								'insertLDReport',
								ldContactInsert,
								'CSX_CMP_LD_Contact__c'
							);
						}

						//only use Patron_Type__c 'SH' and 'CN'
						if (!newEquipments.isEmpty()) {
							if (
								ldReport.CSX_CMP_LD_Type__c == 'Derailment' ||
								ldReport.CSX_CMP_LD_Type__c == 'In transit' ||
								ldReport.CSX_CMP_LD_Type__c == 'Recovery'
							) {
								associateLDContacts(newEquipments);
							}
						}
						if (ldReportWrapper.sendEmail == true && ldReport.CSX_CMP_LD_Type__c == 'Customer') {
							sendConfirmationEmail(ldReport.Id, newEquipments[0].Id);
						}

						// if (ldReport.Id != null && ldReportWrapper.noWaybillFlag == false) {
						// if (ldReport.Id != null) {
						// 	Id jobId = system.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(ldReport.Id, 'UMLER', stagingrecord));
						// }
						response = ldReport.Id;
					}
				}
			} else {
				response = ldReportResults.getErrors()[0].getMessage();
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRCreationController', 'insertLDReport', '', e);
			response = e.getMessage();
		}
		return response;
	}

	/*
    @description : This method is used to create new Equipment records
    @param : equipmentList : List of CSX_CMP_NewClaimWrapper.EquipmentORClaimLine which contains the Equipment data
    @return : List of CSX_CMP_Equipment__c
    */
	// private static Map<String, object> createEquipment(List<CSX_CMP_NewClaimWrapper.EquipmentORClaimLine> equipmentList) {
	private static Map<String, object> createEquipment(List<Equipment> equipmentList) {
		Map<String, object> response = new Map<String, object>();
		try {
			List<CSX_CMP_Equipment__c> newEquipmentList = new List<CSX_CMP_Equipment__c>();
			// for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : equipmentList) {
			for (Equipment equipWrap : equipmentList) {
				CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
				if (String.isNotBlank(equipWrap.equipmentNumber) && String.isNotBlank(equipWrap.equipmentInitial)) {
					equipment.CSX_CMP_Equipment_Initial__c = equipWrap.equipmentInitial;
					equipment.CSX_CMP_Equipment_Num__c = equipWrap.equipmentNumber;
				} else {
					//this is a default value when EquipmentId is not entered
					equipment.CSX_CMP_Equipment_Initial__c = System.Label.CSX_CMP_Default_Equipment_Initial;
					equipment.CSX_CMP_Equipment_Num__c = System.Label.CSX_CMP_Default_Equipment_Num;
				}

				equipment.CSX_CMP_Waybill_Date__c = equipWrap.waybillDate;
				equipment.CSX_CMP_Waybill_Num__c = equipWrap.waybillNumber;
				equipment.CSX_CMP_Waybill_Controls__c = equipWrap.waybillControlCode;
				equipment.CSX_CMP_Shipper__c = equipWrap.shipper;
				equipment.CSX_CMP_Consignee__c = equipWrap.consignee;
				equipment.CSX_CMP_STCC__c = equipWrap.stcc;
				equipment.CSX_CMP_STCC_Description__c = equipWrap.stccDescription;
				equipment.CSX_CMP_Act_Origin_State__c = equipWrap.actualOriginState;
				equipment.CSX_CMP_Act_Origin_City__c = equipWrap.actualOriginCity;
				equipment.CSX_CMP_Act_Destination_State__c = equipWrap.actDestinationState;
				equipment.CSX_CMP_Act_Destination_City__c = equipWrap.actDestinationCity;
				equipment.CSX_CMP_Act_Origin_Road__c = equipWrap.actualOriginSCAC;
				equipment.CSX_CMP_Origin_Road_Num__c = equipWrap.originRoadNumber;
				equipment.CSX_CMP_Origin_Audit_Num__c = equipWrap.originAuditNumber;
				equipment.CSX_CMP_Flat_Car__c = equipWrap.flatCar;
				equipment.CSX_CMP_Shipper_LE_code__c = equipWrap.shipperLegalEntityCode != null
					? String.valueOf(Integer.valueOf(equipWrap.shipperLegalEntityCode))
					: null;
				equipment.CSX_CMP_Consignee_LE_code__c = equipWrap.consigneeLegalEntityCode != null
					? String.valueOf(Integer.valueOf(equipWrap.consigneeLegalEntityCode))
					: null;
				equipment.CSX_CMP_Act_Destination_Road__c = equipWrap.actualDestinationSCAC;
				equipment.CSX_CMP_Destination_Audit__c = equipWrap.destinationAuditNumber;
				equipment.CSX_CMP_LD_Report__c = equipWrap.ldReportId;
				newEquipmentList.add(equipment);
			}

			Database.SaveResult[] equipmentRec = Database.Insert(newEquipmentList);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_LDRCreationController',
				'createEquipment',
				equipmentRec,
				'CSX_CMP_Equipment__c'
			);
			response.put('success', newEquipmentList);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LDRCreationController',
				'createEquipment',
				String.valueOf(equipmentList),
				ex
			);
			response.put('error', ex.getMessage());
		}
		return response;
	}

	/*
    @description : This method is used to create new Product records
    @param : equipmentList : List of CSX_CMP_NewClaimWrapper.EquipmentORClaimLine which contains the Equipment data
    @param : equipmentIdNumberMap : Map of string and string which contains the Equipment record Id and Equipment Number
    */
	private static String createProduct(
		// List<CSX_CMP_NewClaimWrapper.EquipmentORClaimLine> equipmentList,
		List<Equipment> equipmentList,
		Map<String, String> equipmentIdNumberMap
	) {
		List<CSX_CMP_Product__c> productList = new List<CSX_CMP_Product__c>();
		String response;
		try {
			if (!equipmentList.isEmpty()) {
				// for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : equipmentList) {
				// 	for (CSX_CMP_NewClaimWrapper.Product prod : equipWrap.products) {
				for (Equipment equipWrap : equipmentList) {
					for (Product prod : equipWrap.products) {
						CSX_CMP_Product__c product = new CSX_CMP_Product__c();
						if (String.isNotBlank(prod.vin)) {
							product.CSX_CMP_VIN__c = prod.vin;
						} else {
							product.CSX_CMP_Quantity__c = prod.quantity;
							product.CSX_CMP_Product_Description__c = prod.description;
							product.CSX_CMP_UOM__c = prod.uom;
						}
						product.CSX_CMP_Equipment__c = equipmentIdNumberMap.get(
							equipWrap.equipmentInitial +
							equipWrap.equipmentNumber +
							equipWrap.waybillNumber
						);
						productList.add(product);
					}
				}
			}
			if (!productList.isEmpty()) {
				Database.SaveResult[] productRec = Database.Insert(productList, false);
				response = 'Success';
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_LDRCreationController',
					'createProduct',
					productRec,
					'CSX_CMP_Product__c'
				);
			}
		} catch (Exception ex) {
			response = ex.getMessage();
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_LDRCreationController',
				'createProduct',
				String.valueOf(equipmentList),
				ex
			);
		}
		return response;
	}

	/*
    RICEF ID : CMPE0452
    @description: This method will be called in LDR Report creation method to associate the LD contacts to the LDR only for intransit and derailment
    @param : inputEquipments : List of CSX_CMP_Equipment__c which contains the Equipment data
    */
	public static void associateLDContacts(List<CSX_CMP_Equipment__c> inputEquipments) {
		try {
			List<CSX_CMP_LD_Contact__c> ldcontactlist = new List<CSX_CMP_LD_Contact__c>();
			Map<String, String> patronTypeMap = new Map<String, String>();
			Set<String> leatCodes = new Set<String>();

			for (CSX_CMP_Equipment__c equip : inputEquipments) {
				if (equip.CSX_CMP_Shipper_LE_code__c != null) {
					patronTypeMap.put(equip.CSX_CMP_Shipper_LE_code__c, 'Shipper');
					leatCodes.add(equip.CSX_CMP_Shipper_LE_code__c);
				}
				if (equip.CSX_CMP_Consignee_LE_code__c != null) {
					patronTypeMap.put(equip.CSX_CMP_Consignee_LE_code__c, 'Consignee');
					leatCodes.add(equip.CSX_CMP_Consignee_LE_code__c);
				}
			}

			List<Account> accountList = [
				SELECT Id, Type, Le_Code__c, Patron_Code__c, (SELECT Id, Name, Email, Phone, CSX_CMP_RACF_ID__c FROM Contacts)
				FROM Account
				WHERE
					Le_Code__c IN :leatCodes
					AND RecordType.DeveloperName = 'Location'
					AND Status__c = 'Active'
					AND (Type = 'Customer'
					OR Type = 'Supplier')
					AND Location_Type__c = 'Billing Address'
				WITH SECURITY_ENFORCED
			];
			Map<String, List<Account>> accountMap = new Map<String, List<Account>>();

			if (accountList.isEmpty()) {
				return;
			}
			for (Account acc : accountList) {
				if (accountMap.containsKey(acc.Le_Code__c)) {
					accountMap.get(acc.Le_Code__c).add(acc);
				} else {
					accountMap.put(acc.Le_Code__c, new List<Account>{ acc });
				}
			}
			for (CSX_CMP_Equipment__c equipment : inputEquipments) {
				List<Account> accListForShipper = accountMap.get(equipment.CSX_CMP_Shipper_LE_code__c);
				List<Account> accListforConsignee = accountMap.get(equipment.CSX_CMP_Consignee_LE_code__c);
				if (accListForShipper != null && !accListForShipper.isEmpty()) {
					for (Account acc : accListForShipper) {
						if (!acc.Contacts.isEmpty()) {
							for (Contact contact : acc.Contacts) {
								ldcontactlist.add(
									ldContact(
										equipment.Id,
										contact,
										equipment.CSX_CMP_LD_Report__c,
										patronTypeMap.get(equipment.CSX_CMP_Shipper_LE_code__c)
									)
								);
							}
						}
					}
				}
				if (accListforConsignee != null && !accListforConsignee.isEmpty()) {
					for (Account acc : accListforConsignee) {
						if (!acc.Contacts.isEmpty()) {
							for (Contact contact : acc.Contacts) {
								ldcontactlist.add(
									ldContact(
										equipment.Id,
										contact,
										equipment.CSX_CMP_LD_Report__c,
										patronTypeMap.get(equipment.CSX_CMP_Consignee_LE_code__c)
									)
								);
							}
						}
					}
				}
			}
			if (!ldcontactlist.isempty()) {
				Database.SaveResult[] ldContactResults = Database.insert(ldcontactlist, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_LDRCreationController',
					'associateLDContacts',
					ldContactResults,
					'CSX_CMP_LD_Contact__c'
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRCreationController', 'associateLDContacts', '', ex);
		}
	}

	/*
    @description : This method is a generic method to return the LD contact record
    @param : equipmentId : String which contains the Equipment Id
    @param : contactId : String which contains the Contact Id
    @param : ldReportId : String which contains the LD Report Id
    @param : patronType : String which contains the Patron Type
    @return : CSX_CMP_LD_Contact__c
    */
	private static CSX_CMP_LD_Contact__c ldContact(
		String equipmentId,
		Contact contact,
		String ldReportId,
		String patronType
	) {
		CSX_CMP_LD_Contact__c newLDcontact = new CSX_CMP_LD_Contact__c();
		newLDcontact.CSX_CMP_Equipment__c = equipmentId != null ? equipmentId : null;
		// Contact contact = [
		// 	SELECT Id, Name, Phone, email, CSX_CMP_RACF_ID__c
		// 	FROM Contact
		// 	WHERE Id = :contactId
		// 	WITH SECURITY_ENFORCED
		// ];
		if (contact != null) {
			newLDcontact.CSX_CMP_Contact_Name__c = contact.Name;
			newLDcontact.CSX_CMP_Phone_Number__c = contact.Phone;
			newLDcontact.CSX_CMP_Email__c = contact.email;
			newLDcontact.CSX_CMP_RACF_ID__c = contact.CSX_CMP_RACF_ID__c;
		}
		newLDcontact.CSX_CMP_LD_Report__c = ldReportId;
		newLDcontact.CSX_CMP_Contact_Role__c = patronType;
		return newLDcontact;
	}

	/*
    @description : This method is used to send confirmation email to the contacts for Customer LDR type
    @param : ldrId : String which contains the LD Report Id
    @param : equipId : String which contains the Equipment Id
    */
	@future
	public static void sendConfirmationEmail(String ldrId, String equipId) {
		List<Messaging.SendEmailResult> emailRes = new List<Messaging.SendEmailResult>();
		try {
			CSX_CMP_LD_Report__c ldReport = [
				SELECT Id, CSX_CMP_Source__c, (SELECT Id, CSX_CMP_Email__c FROM L_D_Contacts__r)
				FROM CSX_CMP_LD_Report__c
				WHERE Id = :ldrId
				WITH SECURITY_ENFORCED
			];
			if (!ldReport.L_D_Contacts__r.isEmpty()) {
				List<String> toAddresses = new List<String>();
				for (CSX_CMP_LD_Contact__c ldContact : ldReport.L_D_Contacts__r) {
					if (ldContact.CSX_CMP_Email__c != null) {
						toAddresses.add(ldContact.CSX_CMP_Email__c);
					}
				}

				if (!toAddresses.isEmpty()) {
					CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
					emailWrap.sourceRecordId = equipId;
					emailWrap.toEmailIdList = toAddresses;
					/*if(ldReport.CSX_CMP_Source__c == 'ShipCSX'){
					emailWrap.templateDeveloperName = 'CSX_CMP_LDR_Confirmation_Email';
                    }else{
                    emailWrap.templateDeveloperName = 'CSX_CMP_LDR_Confirmation_Email';    
                    }*/
					emailWrap.templateDeveloperName = 'CSX_CMP_LDR_Confirmation_Email';
					Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap);
					Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
					CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_LDRCreationController', 'sendConfirmationEmail', results);
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_LDRCreationController', 'sendConfirmationEmail', emailRes[0]);
		}
	}

	public static void updateStagingRecord(CSX_CMP_Creation_Request__c stagingRec) {
		try {
			Database.SaveResult sr = Database.update(stagingRec, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_LDRCreationController',
				'execute',
				sr,
				'CSX_CMP_Creation_Request__c'
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRCreationController', 'execute', JSON.serialize(stagingRec), e);
		}
	}

	public static void updateLDReportRecord(CSX_CMP_LD_Report__c ldReport) {
		try {
			Database.SaveResult sr = Database.update(ldReport, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_LDRCreationController', 'execute', sr, 'CSX_CMP_LD_Report__c');
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LDRCreationController', 'execute', JSON.serialize(ldReport), e);
		}
	}

	/*
    @description : Wrapper class for LDR Request
    */
	public class CSX_CMP_LDRRequestWrapper {
		//common fields on all types
		public String reportType; //change this to type
		public String damageReason; //on UI this is Issue
		public String cause;
		public String incidentAction;
		public string incidentLocation; //Id will be passed from UI and if state and city are provided through API will be populated
		public String incidentState; //used only in JSON
		public String incidentCity; //used only in JSON
		public String milepost; //used only in JSON // rename to incidentMilepost
		public String pickupAddress;
		public String estimatedLadingLoss; // except in Recovery
		public String incidentComments;
		public Date reportedDate;
		public string reportedBy;
		public String source; //From UI this will always be Manual
		public Date incidentDate; //used only in JSON
		public String reportedById; //Technical Field not used anywhere

		//Customer specific fields
		public string contactId; //this variable stores Id of contact fro UI
		public String contactName; //used only in JSON
		public String phone; //used only in JSON
		public String email; //used only in JSON
		public String damageLocation; //on UI this is Product Location
		public String bracingMethod;
		public String disposition;
		public String productCondition;
		public Boolean visibleDamage;
		public Boolean canNotUnload;
		public Boolean unloadingExceededHours;
		public String productRecords;
		public Boolean sendEmail;
		public String trackId; //only used in JSON
		public String racfId; //only used in JSON
		public string pickupState; // Not yet implemented
		public string pickupCity; // Not yet implemented
		public string productConditionOther; // Not yet implemented
		public string bracingMethodOther; // Not yet implemented
		public string dispositionOther; // Not yet implemented

		//In transit specific fields
		public Boolean multipleBadOrders; // only used in JSON
		public String badOrderComments; // only used in JSON
		public Boolean noWaybillFlag; // UI only
		public String equipNo; // UI only
		public String vin; // UI only

		//Recovery specific fields
		public Decimal recoveryAmount;

		public List<Equipment> equipment;
		public List<CSX_CMP_LD_Contact__c> contacts; // only for internal technical use
	}

	public class Equipment {
		public String equipmentInitial;
		public String equipmentNumber;
		public String shipper;
		public String consignee;
		public String shipperLegalEntityCode;
		public String consigneeLegalEntityCode;
		public String waybillNumber;
		public Date waybillDate;
		public String waybillControlCode;
		public String stcc;
		public String stccDescription;
		public String actualOriginState;
		public String actualOriginCity;
		public String actualOriginSCAC;
		public String actDestinationState;
		public String actDestinationCity;
		public String actualDestinationSCAC;
		public String originRoadNumber;
		public String originAuditNumber;
		public String destinationAuditNumber;
		public String flatCar;
		public String urrwinNumber; // not mapped
		public Date urrwinDate; // not mapped
		public String unitType;
		public Integer numberOfCars;
		public Decimal unitRefundPrice;
		public String ldReportId;

		public list<Product> products;
	}

	public class Product {
		public String vin;
		public Decimal quantity;
		public String description;
		public String uom;
	}

	/*
    @description : Wrapper class for LDR Response
    */
	public class CSX_CMP_LDRResponseWrapper {
		@AuraEnabled
		public String ldrId;
		@AuraEnabled
		public String ldrName;
		@AuraEnabled
		public String ecmLink;
		@AuraEnabled
		public string errorMessage;
	}

	private static Boolean isNotNullOrEmpty(Object obj) {
		String str = String.valueOf(obj);
		if (String.isNotBlank(str) && str != 'null') {
			return true;
		} else {
			return false;
		}
	}
}