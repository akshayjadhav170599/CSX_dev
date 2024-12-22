/**************************************************************************************
/*
@author             : Infosys
@description        : Class for Salvage Claim Creation and related operations.

Apex Class Name     : CSX_CMP_SalvageClaimCreationController
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/

public with sharing class CSX_CMP_SalvageClaimCreationController {
	/*

    @description : This method is used to create new Salvage claims
    @param : sourceId - Id of the Salvage record
    @param : timestamp - TimeStamp to append to External Id
    @param : data - JSON string containing the comment

    */
	@AuraEnabled
	public static String createSalvageClaim(String sourceId, String data) {
		String timeStamp = String.valueOf(datetime.now().formatGMT('MMDDYYYYHHmmss'));
		String message = '';
		Map<String, String> dataMap = (Map<String, String>) JSON.deserialize(data, Map<String, String>.class);
		String equipmentId = dataMap.get('equipmentId');
		// String productId = dataMap.get('productId');
		String ldrId = dataMap.get('ldrId');
		String productDescription = dataMap.get('productDescription');
		String caseRecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Freight').getRecordTypeId();
		try {
			Id claimId;
			Integer numberofCopies = 1;
			Map<String, String> relatedClaimCreationMap = new Map<String, String>();
			String salvageQuery =
				'SELECT ' +
				CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Salvage__c') +
				' FROM CSX_CMP_Salvage__c WHERE Id = :sourceId LIMIT 1';
			CSX_CMP_Salvage__c salvage = Database.query(String.escapeSingleQuotes(salvageQuery));
			String equipmentQuery =
				'SELECT ' +
				CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Equipment__c') +
				' FROM CSX_CMP_Equipment__c WHERE Id = :equipmentId LIMIT 1';
			CSX_CMP_Equipment__c equipment = Database.query(String.escapeSingleQuotes(equipmentQuery));
			// String productQuery = 'SELECT '+ CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Product__c') + ' FROM CSX_CMP_Product__c WHERE Id = :productId LIMIT 1';
			// CSX_CMP_Product__c product = Database.query(String.escapeSingleQuotes(productQuery));

			if (salvage.CSX_CMP_Salvage_Claim__c == null) {
				List<Case> newClaimList = new List<Case>();
				Case newClaim = new Case();
				newClaim.Type = System.Label.CSX_CMP_Type_For_Salvage_Claim;
				newClaim.CSX_CMP_Claim_Reason__c = System.Label.CSX_CMP_Claim_Reason_For_Salvage_Claim;
				newClaim.Origin = System.Label.CSX_CMP_Origin_For_Salvage_Claim;
				String externalId = ldrId + '_' + timestamp + '_' + String.valueOf(numberofCopies);
				newClaim.CSX_CMP_External_Id__c = externalId;
				newClaim.CSX_CMP_Customer__c = salvage.CSX_CMP_Salvor_Name__c;
				newClaim.CSX_CMP_Claim_Amount__c = 0 - salvage.CSX_CMP_Salvage_Amount__c;
				newClaim.CSX_CMP_Original_Amount__c = 0 - salvage.CSX_CMP_Salvage_Amount__c;
				newClaim.RecordTypeId = caseRecordTypeID;
				newClaimList.add(newClaim);
				// relatedClaimCreationMap.put(ldrId, JSON.serialize(new Case(CSX_CMP_External_Id__c = externalId)));

				if (newClaimList.size() > 0) {
					Database.SaveResult[] claimInsertResultList = Database.insert(newClaimList, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_SalvageClaimCreationController',
						'createSalvageClaim',
						claimInsertResultList,
						'Case'
					);
					for (Database.SaveResult claimInsertResult : claimInsertResultList) {
						if (claimInsertResult.isSuccess()) {
							claimId = claimInsertResult.getId();
						}
					}
				}

				if (claimId != null) {
					Set<Id> deskIds = new Set<Id>();
					deskIds.add(claimId);
					Map<Id, String> deskAssignment = CSX_CMP_BusinessRulesUtility.runClaimDeskAssignmentBusinessRules(
						deskIds,
						'CSX_CMP_Claim_Desk_Assignment',
						null
					);
					if (deskAssignment.containsKey(claimId)) {
						Case deskAssignmentCase = new Case(Id = claimId);
						String returnedString = deskAssignment.get(claimId);
						List<String> deskAndOwner = returnedString.split('###');
						deskAssignmentCase.CSX_CMP_Desk_Name__r = new CSX_CMP_Desk__c(Name = deskAndOwner[0]);
						Database.SaveResult[] deskAssignmentUpdateResultList = Database.update(
							new List<Case>{ deskAssignmentCase },
							false
						);
						CSX_CMP_LoggerUtility.addApexDMLErrorLog(
							'CSX_CMP_SalvageClaimCreationController',
							'createSalvageClaim',
							deskAssignmentUpdateResultList,
							'Case'
						);
					}
					relatedClaimCreationMap.put(ldrId,claimId);
					CSX_CMP_ClaimCreationHelper.createRelatedClaimForLDReport(relatedClaimCreationMap);
					if (equipment != null) {
						List<CSX_CMP_Equipment__c> equipmentList = new List<CSX_CMP_Equipment__c>{ equipment };
						CSX_CMP_ClaimCloneHelper.cloneEquipment(equipmentList, timestamp, numberofCopies, 'CSX_CMP_LD_Report__c');
					}
					// if(product != null && productDescription != null && productDescription != ''){
					//     List<CSX_CMP_Product__c> productList = new List<CSX_CMP_Product__c>{product};
					//     CSX_CMP_ClaimCloneHelper.cloneProduct(productList,timestamp,numberofCopies);
					// }
					if (productDescription != null && productDescription != '') {
						CSX_CMP_Product__c product = new CSX_CMP_Product__c();
						product.CSX_CMP_Product_Description__c = productDescription;
						String parentExternalId = equipmentId + '_' + timeStamp + '_' + String.valueOf(numberofCopies);
						product.CSX_CMP_Equipment__r = new CSX_CMP_Equipment__c(CSX_CMP_External_Id__c = parentExternalId);
						Database.SaveResult[] productInsertResultList = Database.insert(
							new List<CSX_CMP_Product__c>{ product },
							false
						);
						CSX_CMP_LoggerUtility.addApexDMLErrorLog(
							'CSX_CMP_SalvageClaimCreationController',
							'createSalvageClaim',
							productInsertResultList,
							'CSX_CMP_Product__c'
						);
					}
					salvage.CSX_CMP_Salvage_Claim__c = claimId;
					Database.SaveResult[] salvageUpdateResultList = Database.update(
						new List<CSX_CMP_Salvage__c>{ salvage },
						false
					);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_SalvageClaimCreationController',
						'createSalvageClaim',
						salvageUpdateResultList,
						'CSX_CMP_Salvage__c'
					);
					message = 'Success';
				}
			} else {
				message = 'Salvage Claim already exists';
			}
		} catch (Exception ex) {
			message = ex.getMessage();
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SalvageClaimCreationController', 'createSalvageClaim', sourceId, ex);
		}
		return message;
	}
}