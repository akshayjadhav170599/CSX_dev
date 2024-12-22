/*
RICEFW Id       : 
@description    : This class is used to create new Recharge claims
@author         : Infosys
@name           : CSX_CMP_RechargeClaimCreationController
*/

public with sharing class CSX_CMP_RechargeClaimCreationController {
	/*
    @description : This method is used to create new Recharge claims
    @param : sourceId - Id of the Equipment record
    @param : timestamp - TimeStamp to append to External Id
    @param : data - JSON string containing the comment 
    */
	@AuraEnabled
	public static String createRechargeClaim(String sourceId, String data) {
		String timestamp = String.valueOf(datetime.now().formatGMT('MMDDYYYYHHmmss'));
		List<Id> claimIds = new List<Id>();
		Map<Id, String> caseOldIDToNewIDMap = new Map<Id, String>();
		String message = '';
		Map<String, String> dataMap = (Map<String, String>) JSON.deserialize(data, Map<String, String>.class);
		List<Case> existingClaimsforUpdate = new List<Case>();

		try {
			if (sourceId != null || sourceId != '') {
				claimIds = sourceId.split(',');
			} else {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_RechargeClaimCreationController',
					'createRechargeClaim',
					'Source Id is null or undefined',
					null
				);
				throw new AuraHandledException('Source Id is null or undefined');
			}
			if (claimIds.size() > 0) {
				Integer numberofCopies = 0;
				List<Case> newClaimList = new List<Case>();
				List<CSX_CMP_Equipment__c> oldEquipmentList = new List<CSX_CMP_Equipment__c>();
				List<CSX_CMP_Claim_Contact__c> oldContactList = new List<CSX_CMP_Claim_Contact__c>();
				String relatedClaimLookupFields = 'CSX_CMP_Related_Claim__r.Status,CSX_CMP_Related_Claim__r.Type';
				String equipmentFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Equipment__c');
				String relatedClaimFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Related_Claim__c');
				String claimContactFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Claim_Contact__c');
				String claimFields = CSX_CMP_ClaimCloneHelper.getFields('Case');
				relatedClaimFields = relatedClaimFields + ',' + relatedClaimLookupFields;
				claimFields = claimFields + ',(SELECT ' + equipmentFields + ' FROM Equipments__r limit 1)';
				claimFields = claimFields + ',(SELECT ' + claimContactFields + ' FROM Claim_Contacts__r limit 1)';
				claimFields = claimFields + ',(SELECT ' + relatedClaimFields + ' FROM Related_Claims__r limit 10)';
				String query = 'SELECT ' + claimFields + ' FROM Case WHERE Id In : claimIds LIMIT 100';
				List<Case> existingClaimRecords = Database.query(String.escapeSingleQuotes(query));
				if (!existingClaimRecords.isEmpty()) {
					for (Case claim : existingClaimRecords) {
						Boolean createNewClaim = true;
						if (!claim.Related_Claims__r.isEmpty()) {
							for (CSX_CMP_Related_Claim__c relatedClaim : claim.Related_Claims__r) {
								if (relatedClaim.CSX_CMP_Related_Claim__r.Status != 'Cancelled' && relatedClaim.CSX_CMP_Related_Claim__r.Type == 'Recharges Outbound Claim') {
									createNewClaim = false;
								}
							}
						}

						if (
							(claim.CSX_CMP_Suspense_Status__c != 'Recharged' && createNewClaim) ||
							(claim.CSX_CMP_Suspense_Status__c == 'Recharged' && createNewClaim)
						) {
							numberofCopies++;

							//logic to create new Claim
							Case newClaim = claim.clone(false, false, false, false);
							newClaim.CSX_CMP_External_Id__c = claim.Id + '_' + timestamp + '_' + String.valueOf(numberofCopies);
							newClaim.CSX_CMP_FCD_Rule_Code__c = '104';
							newClaim.CSX_CMP_Remarks__c = '00615';
							newClaim.Type = 'Recharges Outbound Claim';
							newClaim.Status = 'Pending Monthly Settlement';
							newClaim.CSX_CMP_Claim_Amount__c = claim.CSX_CMP_Claim_Amount__c != null
								? -claim.CSX_CMP_Claim_Amount__c
								: null;
							newClaim.CSX_CMP_Original_Amount__c = claim.CSX_CMP_Original_Amount__c != null
								? -claim.CSX_CMP_Original_Amount__c
								: null;
							newClaim.Origin = 'Manual';

							newClaim.CSX_CMP_Service_Period__c =
								'PER-' +
								String.valueOf(Date.today().month()) +
								'-' +
								String.valueOf(Date.today().year()).substring(2, 4);
							newClaim.CSX_CMP_Suspense_Status__c = '';
							// 6-June Change for Total Cost of claim
							newClaim.ParentId = claim.Id;
							newClaim.ClosedDate = null;
							newClaimList.add(newClaim);

							//Collecting all equipment records
							if (claim.Equipments__r != null) {
								oldEquipmentList.addAll(claim.Equipments__r);
							}
							if (claim.Claim_Contacts__r != null) {
								oldContactList.addAll(claim.Claim_Contacts__r);
							}

							Case childExternalIdForRelatedClaim = new Case(
								CSX_CMP_External_Id__c = claim.Id + '_' + timestamp + '_' + String.valueOf(numberofCopies)
							);
							caseOldIDToNewIDMap.put(claim.Id, JSON.serialize(childExternalIdForRelatedClaim));
							message = message + claim.CaseNumber + ',';

							//update Suspense Status on Parent Claim
							Case updCase = new Case();
							updCase.Id = claim.Id;
							updCase.CSX_CMP_Suspense_Status__c = 'Recharged';
							existingClaimsforUpdate.add(updCase);
						}
					}
				}

				message = message.removeEnd(',');

				List<Id> newClaimIdList = new List<Id>();
				if (!newClaimList.isEmpty()) {
					Database.SaveResult[] claimInsertResultList = Database.insert(newClaimList, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_RechargeClaimCreationController',
						'createRechargeClaim',
						claimInsertResultList,
						'Case'
					);
					for (Database.SaveResult claimInsertResult : claimInsertResultList) {
						if (claimInsertResult.isSuccess()) {
							newClaimIdList.add(claimInsertResult.getId());
						}
					}
					//Updating old claim status
					Database.SaveResult[] claimUpdateResultList = Database.update(existingClaimsforUpdate, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_RechargeClaimCreationController',
						'createRechargeClaim',
						claimUpdateResultList,
						'Case'
					);
				}

				//Cloning Equipment records
				if (!oldEquipmentList.isEmpty() && newClaimIdList.size() > 0) {
					CSX_CMP_ClaimCloneHelper.cloneEquipment(oldEquipmentList, timestamp, numberofCopies, 'CSX_CMP_Claim__c');
				}

				//Cloning Contact records
				if (!oldContactList.isEmpty() && newClaimIdList.size() > 0) {
					CSX_CMP_ClaimCloneHelper.cloneClaimContact(oldContactList, timestamp, numberofCopies);
				}

				List<CSX_CMP_Notes__c> newNotesList = new List<CSX_CMP_Notes__c>();
				if (!newClaimIdList.isEmpty()) {
					for (Id claim : newClaimIdList) {
						CSX_CMP_Notes__c newNote = new CSX_CMP_Notes__c();
						newNote.CSX_CMP_Claim__c = claim;
						newNote.CSX_CMP_Notes__c = dataMap.get('comment');
						newNote.CSX_CMP_Note_Type__c = 'Recharge Reason';
						newNotesList.add(newNote);
					}
				}

				if (!newNotesList.isEmpty()) {
					Database.SaveResult[] notesInsertResultList = Database.insert(newNotesList, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_RechargeClaimCreationController',
						'createRechargeClaim',
						notesInsertResultList,
						'CSX_CMP_Notes__c'
					);
				}

				List<Id> oldEquipmentIds = new List<Id>();
				for (CSX_CMP_Equipment__c equipment : oldEquipmentList) {
					oldEquipmentIds.add(equipment.Id);
				}

				//logic to fetch existing distribution and product records to be clone under new claims
				String distributionAmountFromClaim = 'CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c';
				String distributionCarrier = 'CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant__c';
				String productFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Product__c');
				String distributionFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Distribution__c');
				String equipmentQuery =
					'SELECT Id,(SELECT ' +
					distributionCarrier +
					',' +
					distributionAmountFromClaim +
					',' +
					distributionFields +
					' FROM Distributions__r limit 1),(SELECT ' +
					productFields +
					' FROM Products__r) FROM CSX_CMP_Equipment__c WHERE Id In : oldEquipmentIds';
				List<CSX_CMP_Equipment__c> oldEquipmentRecords = Database.query(String.escapeSingleQuotes(equipmentQuery));
				List<CSX_CMP_Product__c> oldProductList = new List<CSX_CMP_Product__c>();
				List<CSX_CMP_Distribution__c> oldDistributionList = new List<CSX_CMP_Distribution__c>();
				if (!oldEquipmentRecords.isEmpty()) {
					for (CSX_CMP_Equipment__c equipment : oldEquipmentRecords) {
						if (equipment.Products__r != null) {
							oldProductList.addAll(equipment.Products__r);
						}
						if (equipment.Distributions__r != null) {
							for (CSX_CMP_Distribution__c distribution : equipment.Distributions__r) {
								distribution.CSX_CMP_Manual_Adj_Amt__c = -(Decimal) distribution.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c;
								distribution.CSX_CMP_Account__c = (String) distribution.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant__c;
							}
							oldDistributionList.addAll(equipment.Distributions__r);
						}
					}
				}

				//Cloning Product records
				if (!oldProductList.isEmpty()) {
					CSX_CMP_ClaimCloneHelper.cloneProduct(oldProductList, timestamp, numberofCopies);
				}

				//Cloning Distribution records
				if (!oldDistributionList.isEmpty()) {
					CSX_CMP_ClaimCloneHelper.cloneDistribution(oldDistributionList, timestamp, numberofCopies);
				}

				//logic to fetch existing customer and inspection damage records and cloning them under new claims.
				String customerDamageFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Customer_Damage__c');
				String inspectionDamageFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Inspection_Damage__c');
				String productQuery =
					'SELECT Id,(SELECT ' +
					customerDamageFields +
					' FROM Customer_Damages__r),(SELECT ' +
					inspectionDamageFields +
					' FROM Inspection_Damages__r) FROM CSX_CMP_Product__c WHERE Id In : oldProductList LIMIT 100';
				List<CSX_CMP_Product__c> oldProductRecords = Database.query(String.escapeSingleQuotes(productQuery));
				List<CSX_CMP_Customer_Damage__c> oldCustomerDamageList = new List<CSX_CMP_Customer_Damage__c>();
				List<CSX_CMP_Inspection_Damage__c> oldInspectionDamageList = new List<CSX_CMP_Inspection_Damage__c>();
				if (!oldProductRecords.isEmpty()) {
					for (CSX_CMP_Product__c product : oldProductRecords) {
						if (product.Customer_Damages__r != null) {
							oldCustomerDamageList.addAll(product.Customer_Damages__r);
						}
						if (product.Inspection_Damages__r != null) {
							oldInspectionDamageList.addAll(product.Inspection_Damages__r);
						}
					}
				}

				//Cloning Customer Damage records
				if (!oldCustomerDamageList.isEmpty()) {
					CSX_CMP_ClaimCloneHelper.cloneCustomerDamage(oldCustomerDamageList, timestamp, numberofCopies);
				}

				//Cloning Inspection Damage records
				if (!oldInspectionDamageList.isEmpty()) {
					CSX_CMP_ClaimCloneHelper.cloneInspectionDamage(oldInspectionDamageList, timestamp, numberofCopies);
				}
				List<Case> newInsertedClaimList = new List<Case>();
				newInsertedClaimList = [
					SELECT Id, CSX_CMP_External_Id__c, CaseNumber
					FROM Case
					WHERE Id IN :newClaimIdList
					WITH SECURITY_ENFORCED
				];

				if(!newInsertedClaimList.isEmpty()){
					for (Case insertedClaim : newInsertedClaimList) {
						String parentId = insertedClaim.CSX_CMP_External_Id__c.substringBefore('_');
						caseOldIDToNewIDMap.put(insertedClaim.Id, parentId);
					}
				}

				// if(!caseOldIDToNewIDMap.isEmpty()){
				//     CSX_CMP_ClaimCreationHelper.createRelatedClaim(caseOldIDToNewIDMap);
				// }
				//calling generate recharge letters
				if (!newClaimIdList.isEmpty()) {
					CSX_CMP_LetterGenerationController.generateLetters(newClaimIdList, 'CSX_CMP_RechargeLetterpage');
				}
			}
			return message;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_RechargeClaimCreationController', 'createRechargeClaim', sourceId, ex);
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static Map<String, String> checkExistingRechargeClaims(List<String> claimIds) {
		Map<String, String> dataMap = new Map<String, String>();
		try {
			List<Case> existingClaims = [
				SELECT
					Id,
					CaseNumber,
					(
						SELECT CSX_CMP_Related_Claim__r.Status
						FROM Related_Claims__r
						WHERE CSX_CMP_Related_Claim__r.Type = 'Recharges Outbound Claim'
					)
				FROM Case
				WHERE Id IN :claimIds
				WITH SECURITY_ENFORCED
			];
			if (!existingClaims.isEmpty()) {
				for (Case claim : existingClaims) {
					Boolean createNewClaim = true;
					if (!claim.Related_Claims__r.isEmpty()) {
						for (CSX_CMP_Related_Claim__c relatedClaim : claim.Related_Claims__r) {
							if (relatedClaim.CSX_CMP_Related_Claim__r.Status != 'Cancelled') {
								createNewClaim = false;
							}
						}
					}
					dataMap.put(claim.CaseNumber, String.valueOf(createNewClaim));
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_RechargeClaimCreationController',
				'checkExistingRechargeClaims',
				String.valueOf(claimIds),
				e
			);
		}
		return dataMap;
	}
}