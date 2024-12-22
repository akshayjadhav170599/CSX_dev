/*
@author: Infosys
@description  : This class is used to clone the claim record and its related records
*/
public with sharing class CSX_CMP_ClaimCloneHelper {
	/*

    @description : This method is used to clone Equipment records
    @param : sourceEquipmentList - List of Equipment records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create

    */

	public static void cloneEquipment(
		List<CSX_CMP_Equipment__c> sourceEquipmentList,
		String timeStamp,
		Integer count,
		String parentField
	) {
		try {
			List<CSX_CMP_Equipment__c> newRecordList = new List<CSX_CMP_Equipment__c>();
			for (CSX_CMP_Equipment__c sourceEquipment : sourceEquipmentList) {
				for (Integer i = 1; i <= count; i++) {
					CSX_CMP_Equipment__c newEquipment = sourceEquipment.clone(false, false, false, false);
					Map<String, Object> newEquipmentMap = (Map<String, Object>) JSON.deserializeUntyped(
						JSON.serialize(newEquipment)
					);
					newEquipmentMap.remove(parentField);
					newEquipment = (CSX_CMP_Equipment__c) JSON.deserialize(
						JSON.serialize(newEquipmentMap),
						CSX_CMP_Equipment__c.class
					);
					String newExternalId = sourceEquipment.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId = sourceEquipment.get(parentField) + '_' + timeStamp + '_' + String.valueOf(i);
					newEquipment.CSX_CMP_External_ID__c = newExternalId;
					newEquipment.CSX_CMP_Claim__r = new Case(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newEquipment);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] equipmentInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneEquipment',
					equipmentInsertResultList,
					'CSX_CMP_Equipment__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneEquipment',JSON.serialize(sourceEquipmentList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*

    @description : This method is used to clone claim Contact records
    @param : sourceProductList - List of contact records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create

    */

	public static void cloneClaimContact(
		List<CSX_CMP_Claim_Contact__c> sourceContactList,
		String timeStamp,
		Integer count
	) {
		try {
			List<CSX_CMP_Claim_Contact__c> newRecordList = new List<CSX_CMP_Claim_Contact__c>();
			for (CSX_CMP_Claim_Contact__c sourceContact : sourceContactList) {
				for (Integer i = 1; i <= count; i++) {
					CSX_CMP_Claim_Contact__c newContact = sourceContact.clone(false, false, false, false);
					Map<String, Object> newContactMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(newContact));
					newContactMap.remove('CSX_CMP_Claim__c');
					newContact = (CSX_CMP_Claim_Contact__c) JSON.deserialize(
						JSON.serialize(newContactMap),
						CSX_CMP_Claim_Contact__c.class
					);
					String newExternalId = sourceContact.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId = sourceContact.CSX_CMP_Claim__c + '_' + timeStamp + '_' + String.valueOf(i);
					newContact.CSX_CMP_External_ID__c = newExternalId;
					newContact.CSX_CMP_Claim__r = new Case(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newContact);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] contactInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneClaimContact',
					contactInsertResultList,
					'CSX_CMP_Claim_Contact__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneClaimContact',JSON.serialize(sourceContactList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*

    @description : This method is used to clone Product records
    @param : sourceProductList - List of Product records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create

    */

	public static void cloneProduct(List<CSX_CMP_Product__c> sourceProductList, String timeStamp, Integer count) {
		try {
			List<CSX_CMP_Product__c> newRecordList = new List<CSX_CMP_Product__c>();
			for (CSX_CMP_Product__c sourceProduct : sourceProductList) {
				for (Integer i = 1; i <= count; i++) {
					CSX_CMP_Product__c newProduct = sourceProduct.clone(false, false, false, false);
					Map<String, Object> newProductMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(newProduct));
					newProductMap.remove('CSX_CMP_Equipment__c');
					newProduct = (CSX_CMP_Product__c) JSON.deserialize(JSON.serialize(newProductMap), CSX_CMP_Product__c.class);
					String newExternalId = sourceProduct.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId = sourceProduct.CSX_CMP_Equipment__c + '_' + timeStamp + '_' + String.valueOf(i);
					newProduct.CSX_CMP_External_ID__c = newExternalId;
					newProduct.CSX_CMP_Equipment__r = new CSX_CMP_Equipment__c(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newProduct);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] productInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneProduct',
					productInsertResultList,
					'CSX_CMP_Product__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneProduct',JSON.serialize(sourceProductList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*
    @description : This method is used to clone Distribution records
    @param : sourceDistributionList - List of Distribution records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create
    */
	public static void cloneDistribution(
		List<CSX_CMP_Distribution__c> sourceDistributionList,
		String timeStamp,
		Integer count
	) {
		try {
			Account csxAccount = [
				SELECT Id
				FROM Account
				WHERE CSX_CMP_FC_Railroad_Road_Code__c = '0712' AND CSX_CMP_FC_SCAC__c = 'CSXT' AND RecordType.DeveloperName = 'Location' AND Location_Type__c = 'Billing Address' AND Type = 'Supplier'
				WITH SECURITY_ENFORCED
				LIMIT 1 
			];
			List<CSX_CMP_Distribution__c> newRecordList = new List<CSX_CMP_Distribution__c>();
			for (CSX_CMP_Distribution__c sourceDistribution : sourceDistributionList) {
				for (Integer i = 1; i <= count; i++) {
					CSX_CMP_Distribution__c newDistribution = sourceDistribution.clone(false, false, false, false);
					newDistribution.CSX_CMP_Manual_Adj_Amt__c = newDistribution.CSX_CMP_Manual_Adj_Amt__c != null
						? -newDistribution.CSX_CMP_Manual_Adj_Amt__c
						: null;

					Map<String, Object> newDistributionMap = (Map<String, Object>) JSON.deserializeUntyped(
						JSON.serialize(newDistribution)
					);
					newDistributionMap.remove('CSX_CMP_Equipment__c');
					newDistribution = (CSX_CMP_Distribution__c) JSON.deserialize(
						JSON.serialize(newDistributionMap),
						CSX_CMP_Distribution__c.class
					);
					if (newDistribution.CSX_CMP_Account__c == csxAccount.Id) {
						newDistribution.CSX_CMP_Hold_RR_Distribution__c = true;
					}

					String newExternalId = sourceDistribution.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId = sourceDistribution.CSX_CMP_Equipment__c + '_' + timeStamp + '_' + String.valueOf(i);
					newDistribution.CSX_CMP_External_ID__c = newExternalId;
					newDistribution.CSX_CMP_Equipment__r = new CSX_CMP_Equipment__c(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newDistribution);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] distributionInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneDistribution',
					distributionInsertResultList,
					'CSX_CMP_Distribution__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneDistribution',JSON.serialize(sourceDistributionList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*

    @description : This method is used to clone Customer Damage records
    @param : sourceCustomerDamageList - List of Customer Damage records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create

    */

	public static void cloneCustomerDamage(
		List<CSX_CMP_Customer_Damage__c> sourceCustomerDamageList,
		String timeStamp,
		Integer count
	) {
		try {
			List<CSX_CMP_Customer_Damage__c> newRecordList = new List<CSX_CMP_Customer_Damage__c>();
			for (CSX_CMP_Customer_Damage__c sourceCustomerDamage : sourceCustomerDamageList) {
				for (Integer i = 1; i <= count; i++) {
					CSX_CMP_Customer_Damage__c newCustomerDamage = sourceCustomerDamage.clone(false, false, false, false);
					Map<String, Object> newCustomerDamageMap = (Map<String, Object>) JSON.deserializeUntyped(
						JSON.serialize(newCustomerDamage)
					);
					newCustomerDamageMap.remove('CSX_CMP_Product__c');
					newCustomerDamage = (CSX_CMP_Customer_Damage__c) JSON.deserialize(
						JSON.serialize(newCustomerDamageMap),
						CSX_CMP_Customer_Damage__c.class
					);
					String newExternalId = sourceCustomerDamage.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId = sourceCustomerDamage.CSX_CMP_Product__c + '_' + timeStamp + '_' + String.valueOf(i);
					newCustomerDamage.CSX_CMP_External_ID__c = newExternalId;
					newCustomerDamage.CSX_CMP_Product__r = new CSX_CMP_Product__c(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newCustomerDamage);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] customerDamageInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneCustomerDamage',
					customerDamageInsertResultList,
					'CSX_CMP_Customer_Damage__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneCustomerDamage',JSON.serialize(sourceCustomerDamageList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*

    @description : This method is used to clone Inspection Damage records
    @param : sourceInspectionDamageList - List of Inspection Damage records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : counter - Number of copies to create

    */

	public static void cloneInspectionDamage(
		List<CSX_CMP_Inspection_Damage__c> sourceInspectionDamageList,
		String timeStamp,
		Integer counter
	) {
		try {
			List<CSX_CMP_Inspection_Damage__c> newRecordList = new List<CSX_CMP_Inspection_Damage__c>();
			for (CSX_CMP_Inspection_Damage__c sourceInspectionDamage : sourceInspectionDamageList) {
				for (Integer i = 1; i <= counter; i++) {
					CSX_CMP_Inspection_Damage__c newInspectionDamage = sourceInspectionDamage.clone(false, false, false, false);
					Map<String, Object> newInspectionDamageMap = (Map<String, Object>) JSON.deserializeUntyped(
						JSON.serialize(newInspectionDamage)
					);
					newInspectionDamageMap.remove('CSX_CMP_Product__c');
					newInspectionDamage = (CSX_CMP_Inspection_Damage__c) JSON.deserialize(
						JSON.serialize(newInspectionDamageMap),
						CSX_CMP_Inspection_Damage__c.class
					);
					String newExternalId = sourceInspectionDamage.Id + '_' + timeStamp + '_' + String.valueOf(i);
					String parentExternalId =
						sourceInspectionDamage.CSX_CMP_Product__c +
						'_' +
						timeStamp +
						'_' +
						String.valueOf(i);
					newInspectionDamage.CSX_CMP_External_ID__c = newExternalId;
					newInspectionDamage.CSX_CMP_Product__r = new CSX_CMP_Product__c(CSX_CMP_External_ID__c = parentExternalId);
					newRecordList.add(newInspectionDamage);
				}
			}

			if (newRecordList.size() > 0) {
				Database.SaveResult[] inspectionDamageInsertResultList = Database.insert(newRecordList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCloneHelper',
					'cloneInspectionDamage',
					inspectionDamageInsertResultList,
					'CSX_CMP_Inspection_Damage__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCloneHelper','cloneInspectionDamage',JSON.serialize(sourceInspectionDamageList),e);
			// throw new AuraHandledException(e.getMessage());
		}
	}

	/*

    @description : This method is used to get fields of an object
    @param : objectName - Name of the object
    @return : String - comma separated fields of an object

    */

	public static String getFields(String objectName) {
		String excludedFields = 'ownerid, isdeleted, name, createddate, createdbyid, lastmodifieddate, lastmodifiedbyid, systemmodstamp, lastactivitydate';
		List<String> fieldList = new List<String>();
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
			.get(objectName)
			.getDescribe()
			.fields.getMap();
		for (String fieldName : fieldsMap.keySet()) {
			if (!excludedFields.contains(fieldName) && fieldsMap.get(fieldName).getDescribe().isCalculated() == false) {
				fieldList.add(fieldName);
			}
		}
		return String.join(fieldList, ', ');
	}
}