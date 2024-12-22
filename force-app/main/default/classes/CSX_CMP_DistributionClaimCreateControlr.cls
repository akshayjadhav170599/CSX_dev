/** 
@description : This class is used to create new claim for Distribution claim type
@author : Infosys
@name : CSX_CMP_DistributionClaimCreateControlr
*/

public with sharing class CSX_CMP_DistributionClaimCreateControlr {
	/*

    @description : This method is used to create new claim for Distribution claim type
    @param : sourceId - Id of the Equipment record
    @return : response - JSON String of newly created claims
    */
	@AuraEnabled
	public static String createDistributionClaim(String sourceId) {
		String timestamp = String.valueOf(datetime.now().formatGMT('MMDDYYYYHHmmss'));
		String response = '';
		String csxCarrierAlphaCode = System.Label.CSX_CMP_Railroad_Alpha_Code_For_Distribution_Claim;
		Integer claimRecordsInserted = 0;
		// Map<Id, String> caseOldIDToNewIDMap = new Map<Id, String>();
		try {
			List<Id> equipmentIds = new List<Id>();
			equipmentIds.add(sourceId);
			List<Case> newClaimList = new List<Case>();
			List<String> caseRelatedFieldsonEquipment = new List<String>{
				'CSX_CMP_Claim__r.CSX_CMP_FCD_Rule_Code__c',
				'CSX_CMP_Claim__r.CSX_CMP_FCD_Cause_Code__c',
				'CSX_CMP_Claim__r.CSX_CMP_Salvage_Code__c',
				'CSX_CMP_Claim__r.CSX_CMP_Remarks__c'
			}; //CSX_CMP_Claim__r.CSX_CMP_FCD_Rule_Code__c
			List<String> distrubutionRelatedFieldsonEquipment = new List<String>{
				'CSX_CMP_Account__r.CSX_CMP_Exclude_from_Distribution__c',
				'CSX_CMP_Account__r.Type',
				'CSX_CMP_Account__r.CSX_CMP_FC_SCAC__c',
				'CSX_CMP_Account__r.CSX_CMP_Customer_Name__c'
			};

			String productFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Product__c');
			String distributionFields =
				CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Distribution__c') +
				',' +
				String.join(distrubutionRelatedFieldsonEquipment, ', ');
			String equipmentFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Equipment__c');
			equipmentFields = equipmentFields + ',(SELECT ' + distributionFields + ' FROM Distributions__r)';
			equipmentFields = equipmentFields + ', (SELECT ' + productFields + ' FROM Products__r)';
			equipmentFields = equipmentFields + ',' + String.join(caseRelatedFieldsonEquipment, ', ');
			equipmentFields = equipmentFields.removeEnd(',');
			String query = 'SELECT ' + equipmentFields + ' FROM CSX_CMP_Equipment__c WHERE Id In : equipmentIds LIMIT 100';
			List<CSX_CMP_Equipment__c> equipmentListToGetCaseIds = Database.query(String.escapeSingleQuotes(query));
			Integer numberofCopies = 0;
			String caseRecordTypeID = Schema.getGlobalDescribe()
				.get('Case')
				.getDescribe()
				.getRecordTypeInfosByDeveloperName()
				.get('Freight')
				.getRecordTypeId();

			Map<String, String> distributionErrorMap = new Map<String, String>();

			for (CSX_CMP_Distribution__c dist : equipmentListToGetCaseIds[0].Distributions__r) {
				if (
					dist.CSX_CMP_Distribution_Claim__c == null &&
					dist.CSX_CMP_Account__r.CSX_CMP_Exclude_from_Distribution__c == false &&
					dist.CSX_CMP_Hold_RR_Distribution__c == false &&
					dist.CSX_CMP_Account__r.Type == 'Supplier' &&
					dist.CSX_CMP_Account__r.CSX_CMP_FC_SCAC__c != csxCarrierAlphaCode &&
					((dist.CSX_CMP_Calculated_Amount__c >= 21 && dist.CSX_CMP_Manual_Adj_Amt__c == null) ||
					dist.CSX_CMP_Manual_Adj_Amt__c >= 21)
				) {
					numberofCopies++;
					Case newClaim = new Case();
					newClaim.CSX_CMP_Customer_Claim_Date__c = Date.Today();
					newClaim.Status = System.Label.CSX_CMP_Status_For_Distribution_Claim;
					newClaim.Type = System.Label.CSX_CMP_Type_For_Distribution_Claim;
					CSX_CMP_Desk__c desk = new CSX_CMP_Desk__c(Name = System.Label.CSX_CMP_Desk_For_Distribution_Claim);
					newClaim.CSX_CMP_Desk_Name__r = desk;
					// newClaim.CSX_CMP_Desk__c = System.Label.CSX_CMP_Desk_For_Distribution_Claim;
					newClaim.Origin = System.Label.CSX_CMP_Origin_For_Distribution_Claim;
					newClaim.CSX_CMP_FCD_Rule_Code__c = equipmentListToGetCaseIds[0].CSX_CMP_Claim__r.CSX_CMP_FCD_Rule_Code__c;
					newClaim.CSX_CMP_FCD_Cause_Code__c = equipmentListToGetCaseIds[0].CSX_CMP_Claim__r.CSX_CMP_FCD_Cause_Code__c;
					newClaim.CSX_CMP_Salvage_Code__c = equipmentListToGetCaseIds[0].CSX_CMP_Claim__r.CSX_CMP_Salvage_Code__c;
					newClaim.CSX_CMP_Remarks__c = equipmentListToGetCaseIds[0].CSX_CMP_Claim__r.CSX_CMP_Remarks__c;
					String externalId =
						equipmentListToGetCaseIds[0].CSX_CMP_Claim__c +
						'_' +
						timestamp +
						'_' +
						String.valueOf(numberofCopies);
					newClaim.CSX_CMP_External_Id__c = externalId;
					newClaim.CSX_CMP_Customer__c = dist.CSX_CMP_Account__r.CSX_CMP_Customer_Name__c;
					//newClaim.CSX_CMP_Service_Period__c ='PER-' + String.valueOf(Date.today()).substring(5,7) + '-' + String.valueOf(Date.today()).substring(2,4);
					// newClaim.CSX_CMP_Service_Period__c =
					// 	'PER-' +
					// 	String.valueOf(Date.today().month()) +
					// 	'-' +
					// 	String.valueOf(Date.today().year()).substring(2, 4);
					newClaim.CSX_CMP_Supplier_Claimant__c = dist.CSX_CMP_Account__c;
					if (dist.CSX_CMP_Manual_Adj_Amt__c != null) {
						Decimal manualAdjAmt = dist.CSX_CMP_Manual_Adj_Amt__c.setScale(2, System.RoundingMode.HALF_UP);
						newClaim.CSX_CMP_Claim_Amount__c = -manualAdjAmt;
						newClaim.CSX_CMP_Original_Amount__c = -manualAdjAmt;
					} else {
						Decimal calculatedAmount = dist.CSX_CMP_Manual_Adj_Amt__c.setScale(2, System.RoundingMode.HALF_UP);
						newClaim.CSX_CMP_Claim_Amount__c = -calculatedAmount;
						newClaim.CSX_CMP_Original_Amount__c = -calculatedAmount;
					}
					newClaim.CSX_CMP_Distribution_Id__c = dist.id;
					// 6-June Change for Total Cost of claim
					newClaim.parentId = equipmentListToGetCaseIds[0].CSX_CMP_Claim__c;

					newClaim.RecordTypeId = caseRecordTypeID;
					newClaimList.add(newClaim);

					// Case childExternalIdForRelatedClaim = new Case(CSX_CMP_External_Id__c = equipmentListToGetCaseIds[0].CSX_CMP_Claim__c+'_'+timestamp+'_'+String.valueOf(numberofCopies));
					// caseOldIDToNewIDMap.put(equipmentListToGetCaseIds[0].CSX_CMP_Claim__c, JSON.serialize(childExternalIdForRelatedClaim));
				} else if(dist.CSX_CMP_Distribution_Claim__c != null){
					distributionErrorMap.put(dist.Id, 'Claim Already Present');
				} else if (dist.CSX_CMP_Account__r.CSX_CMP_Exclude_from_Distribution__c == true) {
					distributionErrorMap.put(dist.Id, 'Account is excluded from Distribution');
				} else if (dist.CSX_CMP_Account__r.Type != 'Supplier') {
					distributionErrorMap.put(dist.Id, 'Account is not a Supplier');
				} else if (dist.CSX_CMP_Account__r.CSX_CMP_FC_SCAC__c == csxCarrierAlphaCode) {
					distributionErrorMap.put(dist.Id, 'Account is a CSX Carrier');
				} else if (
					dist.CSX_CMP_Calculated_Amount__c <= 21 ||
					dist.CSX_CMP_Manual_Adj_Amt__c == null ||
					dist.CSX_CMP_Manual_Adj_Amt__c <= 21
				) {
					distributionErrorMap.put(dist.Id, 'Amount is less than 21');
				} else if (dist.CSX_CMP_Hold_RR_Distribution__c == true) {
					distributionErrorMap.put(dist.Id, 'Distribution is on Hold');
				}
			}

			List<Id> newClaimIdList = new List<Id>();
			if (newClaimList.size() > 0) {
				Database.SaveResult[] claimInsertResultList = Database.insert(newClaimList, false);
				claimRecordsInserted = CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_DistributionClaimCreateControlr',
					'createDistributionClaim',
					claimInsertResultList,
					'Case'
				);
				for (Database.SaveResult claimInsertResult : claimInsertResultList) {
					if (claimInsertResult.isSuccess()) {
						newClaimIdList.add(claimInsertResult.getId());
					}
				}
			}
			

			//distributionListToUpdate : distribution list to update Id on newly created claims
			//List<CSX_CMP_Distribution__c> distributionListToUpdate = new List<CSX_CMP_Distribution__c>();
			// List<CSX_CMP_Equipment__c> equipmentList = new List<CSX_CMP_Equipment__c>();
			List<Object> responseMapList = new List<Object>();
			responseMapList.add(distributionErrorMap);
			if (newClaimIdList.size() > 0) {
				List<Case> newInsertedClaimList = [
					SELECT Id, CSX_CMP_Distribution_Id__c, CSX_CMP_External_Id__c, CaseNumber
					FROM Case
					WHERE Id IN :newClaimIdList
					WITH SECURITY_ENFORCED
				];
				for (Case insertedClaim : newInsertedClaimList) {
					// String parentId = insertedClaim.CSX_CMP_External_Id__c.substringBefore('_');
					// caseOldIDToNewIDMap.put(insertedClaim.Id,parentId);
					Map<String, String> responseMap = new Map<String, String>();
					responseMap.put('CaseNumber', insertedClaim.CaseNumber);
					responseMap.put('claimId', insertedClaim.Id);
					responseMap.put('distributionId', insertedClaim.CSX_CMP_Distribution_Id__c);
					responseMapList.add(responseMap);
				}
			}
			response = JSON.serialize(responseMapList);

			for (CSX_CMP_Equipment__c equipment : equipmentListToGetCaseIds) {
				Map<String, Object> newRecordMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(equipment));
				for (String field : caseRelatedFieldsonEquipment) {
					newRecordMap.remove(field);
				}
				equipment = (CSX_CMP_Equipment__c) JSON.deserialize(JSON.serialize(newRecordMap), CSX_CMP_Equipment__c.class);
			}

			if (!equipmentListToGetCaseIds.isEmpty()) {
				executeChildRecordClone(equipmentListToGetCaseIds, timeStamp, numberofCopies);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_DistributionClaimCreateControlr',
				'createDistributionClaim',
				sourceId,
				ex
			);
			response = ex.getMessage();
		}

		return response;
	}

	/*

    @description : This method is used to clone records of Equipment and child records of Equipment
    @param : sourceEquipmentList - List of Equipment records to clone
    @param : timeStamp - TimeStamp to append to External Id
    @param : count - Number of claims created
    @return : response - JSON String of newly created claims

    */
	private static String executeChildRecordClone(
		List<CSX_CMP_Equipment__c> sourceEquipmentList,
		String timeStamp,
		Integer count
	) {
		String response = '';
		try {
			List<CSX_CMP_Product__c> productListToClone = new List<CSX_CMP_Product__c>();
			for (CSX_CMP_Equipment__c sourceEquipment : sourceEquipmentList) {
				if (!sourceEquipment.Products__r.isEmpty()) {
					productListToClone.addAll(sourceEquipment.Products__r);
				}
			}

			if (!sourceEquipmentList.isEmpty()) {
				CSX_CMP_ClaimCloneHelper.cloneEquipment(sourceEquipmentList, timeStamp, count, 'CSX_CMP_Claim__c');
			}
			if (!productListToClone.isEmpty()) {
				CSX_CMP_ClaimCloneHelper.cloneProduct(productListToClone, timeStamp, count);
			}

			List<Id> oldProductIdList = new List<Id>();
			for (CSX_CMP_Product__c product : productListToClone) {
				oldProductIdList.add(product.Id);
			}

			List<CSX_CMP_Customer_Damage__c> customerDamageListToClone = new List<CSX_CMP_Customer_Damage__c>();
			List<CSX_CMP_Inspection_Damage__c> inspectionDamageListToClone = new List<CSX_CMP_Inspection_Damage__c>();

			if (!oldProductIdList.isEmpty()) {
				String customerDamageFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Customer_Damage__c');
				String inspectionDamageFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Inspection_Damage__c');
				String productFields =
					'Id,(SELECT ' +
					customerDamageFields +
					' FROM Customer_Damages__r),(SELECT ' +
					inspectionDamageFields +
					' FROM Inspection_Damages__r)';
				String query = 'Select ' + productFields + ' FROM CSX_CMP_Product__c WHERE Id IN : oldProductIdList Limit 100';
				List<CSX_CMP_Product__c> productList = Database.query(String.escapeSingleQuotes(query));
				for (CSX_CMP_Product__c product : productList) {
					if (!product.Customer_Damages__r.isEmpty()) {
						customerDamageListToClone.addAll(product.Customer_Damages__r);
					}
					if (!product.Inspection_Damages__r.isEmpty()) {
						inspectionDamageListToClone.addAll(product.Inspection_Damages__r);
					}
				}
			}

			if (!customerDamageListToClone.isEmpty()) {
				CSX_CMP_ClaimCloneHelper.cloneCustomerDamage(customerDamageListToClone, timeStamp, count);
			}

			if (!inspectionDamageListToClone.isEmpty()) {
				CSX_CMP_ClaimCloneHelper.cloneInspectionDamage(inspectionDamageListToClone, timeStamp, count);
			}
			response = 'success';
			return response;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_DistributionClaimCreateControlr',
				'executeChildRecordClone',
				string.valueOf(sourceEquipmentList),
				ex
			);
			return ex.getMessage();
		}
	}

	/*
    @description : This method is used to fetch Equipment details
    @param : reocrdId : recordId of Equipment Record
    @return : Equipment record
    */
	@AuraEnabled
	public static CSX_CMP_Equipment__c getEquipmentDetails(String recordId) {
		try {
			CSX_CMP_Equipment__c equipment = [
				SELECT Id, CSX_CMP_Total_Manual_Adj_Amount__c, CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c, Name
				FROM CSX_CMP_Equipment__c
				WHERE Id = :recordId
				WITH SECURITY_ENFORCED
			];
			return equipment;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
    @description : This method is used to fetch Distribution details and calculate amount 
    @param : equipmentID : List of Equipment Ids
    @return : List of Distribution records
    */
	@AuraEnabled
	public static List<CSX_CMP_Distribution__c> calculateDistributionAmount(List<ID> equipmentID) {
		List<CSX_CMP_Equipment__c> equipmentList = new List<CSX_CMP_Equipment__c>();
		List<CSX_CMP_Distribution__c> distributionList = new List<CSX_CMP_Distribution__c>();

		try {
			equipmentList = [
				SELECT
					Id,
					CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c,
					(
						SELECT
							ID,
							CSX_CMP_Point__c,
							CSX_CMP_Adj_Miles__c,
							Name,
							CSX_CMP_Miles__c,
							CSX_CMP_Calculated_Amount__c,
							CSX_CMP_Account__r.CSX_CMP_Exclude_from_Distribution__c
						FROM Distributions__r
					)
				FROM CSX_CMP_Equipment__c
				WHERE ID IN :equipmentID
				WITH SECURITY_ENFORCED
			];

			if (!equipmentList.isEmpty()) {
				for (CSX_CMP_Equipment__c equip : equipmentList) {
					//Calculate Total Miles and Points for the Equipment
					Decimal totalMiles = 0;
					Decimal totalAdjMiles = 0;
					Decimal totalPoints = 0;
					if (!equip.Distributions__r.isEmpty()) {
						for (CSX_CMP_Distribution__c d1 : equip.Distributions__r) {
							if (d1.CSX_CMP_Miles__c != null) {
								totalMiles += d1.CSX_CMP_Miles__c;
							}
							if (d1.CSX_CMP_Adj_Miles__c != null) {
								totalAdjMiles += d1.CSX_CMP_Adj_Miles__c;
							}
							if (d1.CSX_CMP_Point__c != null) {
								totalPoints += d1.CSX_CMP_Point__c;
							}
						}
					}

					//Calculate Amount based on Point/Adjusted Miles/Miles
					if (!equip.Distributions__r.isEmpty()) {
						for (CSX_CMP_Distribution__c dist : equip.Distributions__r) {
							if (
								equip.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c != 0 &&
								equip.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c != null &&
								dist.CSX_CMP_Account__r.CSX_CMP_Exclude_from_Distribution__c == false
							) {
								if (dist.CSX_CMP_Point__c != null) {
									dist.CSX_CMP_Calculated_Amount__c = ((dist.CSX_CMP_Point__c / totalPoints) *
										equip.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c)
										.setScale(2, System.RoundingMode.HALF_UP);
									dist.CSX_CMP_Manual_Adj_Amt__c = dist.CSX_CMP_Calculated_Amount__c;
								} else if (dist.CSX_CMP_Point__c == null && dist.CSX_CMP_Adj_Miles__c != dist.CSX_CMP_Miles__c) {
									dist.CSX_CMP_Calculated_Amount__c = ((dist.CSX_CMP_Adj_Miles__c / totalAdjMiles) *
										equip.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c)
										.setScale(2, System.RoundingMode.HALF_UP);
									dist.CSX_CMP_Manual_Adj_Amt__c = dist.CSX_CMP_Calculated_Amount__c;
								} else {
									dist.CSX_CMP_Calculated_Amount__c = ((dist.CSX_CMP_Miles__c / totalAdjMiles) *
										equip.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c)
										.setScale(2, System.RoundingMode.HALF_UP);
									dist.CSX_CMP_Manual_Adj_Amt__c = dist.CSX_CMP_Calculated_Amount__c;
								}
							} else {
								dist.CSX_CMP_Calculated_Amount__c = 0;
								dist.CSX_CMP_Manual_Adj_Amt__c = 0;
							}
							distributionList.add(dist);
						}
					}
				}
			}
			if (!distributionList.isEmpty()) {
				Database.SaveResult[] sr = Database.update(distributionList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_DistributionClaimCreateControlr',
					'calculateDistributionAmount',
					sr,
					'CSX_CMP_Distribution__c'
				);
			}
			return distributionList;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_DistributionClaimCreateControlr',
				'calculateDistributionAmount',
				string.valueOf(equipmentID),
				ex
			);
			return null;
		}
	}
	// @AuraEnabled
	// public static void RemoveDistriClaimNumber(List<ID> cancelledcaseID){
	//     List<CSX_CMP_Distribution__c> distributionClaimList = new List<CSX_CMP_Distribution__c>();
	//     List<CSX_CMP_Distribution__c> distributionList = [SELECT Id,CSX_CMP_Distribution_Claim__c FROM CSX_CMP_Distribution__c WHERE Id IN:cancelledcaseID];
	//     for(CSX_CMP_Distribution__c canceldist : distributionList){
	//         canceldist.CSX_CMP_Distribution_Claim__c = null;
	//     }

	//     if(!distributionList.isEmpty()){
	//         Database.update(distributionList);
	//     }
	// }
}