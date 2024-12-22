/**************************************************************************************
Apex Class Name     : CSX_CMP_RelatedCasesController
Function            : Create Related case to the claim using lightning component.
Modification Log    :
* Developer         : 
* Date              : 18th April,2024
* ----------------------------------------------------------------------------                  
* author :Infosys           18/04/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_RelatedCasesController {
	@AuraEnabled
	public static Boolean linkRelatedCases(string claimId, String selectedCases) {
		Boolean isSuccess = false;
		try {
			List<Object> cases = (List<Object>) JSON.deserializeUntyped(selectedCases);
			List<CSX_CMP_Related_Case__c> relatedCases = new List<CSX_CMP_Related_Case__c>();
			for (Object obj : cases) {
				Map<String, Object> caseObject = (Map<String, Object>) obj;
				CSX_CMP_Related_Case__c relatedCase = new CSX_CMP_Related_Case__c();
				relatedCase.CSX_CMP_Claim__c = claimId;
				relatedCase.CSX_CMP_Status__c = (String) caseObject.get('status');
				relatedCase.CSX_CMP_CreatedBy__c = (String) caseObject.get('createdBy');
				relatedCase.CSX_CMP_Company_Name__c = (String) caseObject.get('companyName');
				relatedCase.CSX_CMP_Case_Number__c = (String) caseObject.get('caseNumber');
				relatedCase.CSX_CMP_Case_Date__c = Date.valueOf(
					CSX_CMP_Utility.formatDateforDML((String) caseObject.get('caseDate'))
				);
				relatedCases.add(relatedCase);
			}

			if (!relatedCases.isEmpty()) {
				Database.SaveResult[] insertResults = Database.INSERT(relatedCases, false);
				for (Database.SaveResult sr : insertResults) {
					if (sr.isSuccess()) {
						isSuccess = true;
					} else {
						isSuccess = false;
					}
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_RelatedCasesController',
						'linkRelatedCases',
						insertResults,
						'CSX_CMP_Related_Case__c'
					);
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_RelatedCasesController',
				'linkRelatedCases',
				claimId +
				'_ ' +
				selectedCases,
				e
			);
		}
		return isSuccess;
	}

	@AuraEnabled
	public static string getEquipmentNumber(string claimId) {
		String equipmentNumber = '';
		try {
			if (string.isNotBlank(claimId) && claimId != null) {
				// Case objClaim = [Select Id,CaseNumber,CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c from Case where Id =: claimId];
				CSX_CMP_Equipment__c objEquip = [
					SELECT id, CSX_CMP_Claim__c, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c
					FROM CSX_CMP_Equipment__c
					WHERE CSX_CMP_Claim__c = :claimId
					WITH SECURITY_ENFORCED
					LIMIT 1
				];
				if (objEquip != null) {
					if (objEquip.CSX_CMP_Equipment_Initial__c != null && objEquip.CSX_CMP_Equipment_Num__c != null) {
						equipmentNumber = objEquip.CSX_CMP_Equipment_Initial__c + objEquip.CSX_CMP_Equipment_Num__c;
					}
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_RelatedCasesController', 'getEquipmentNumber', claimId, e);
		}
		return equipmentNumber;
	}
}