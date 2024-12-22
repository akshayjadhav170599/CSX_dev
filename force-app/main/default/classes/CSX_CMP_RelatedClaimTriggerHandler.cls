/**************************************************************************************
Apex class Name     : CSX_CMP_RelatedClaimTriggerHandler
Function            : Create a reverserelated claim for the related claim.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           07/29/2024       First version of this class.
*************************************************************************************/

public with sharing class CSX_CMP_RelatedClaimTriggerHandler {
	public static Boolean bypassTrigger = false;

	public static void handleAfterInsert(List<CSX_CMP_Related_Claim__c> newRelatedClaimList) {
		try {
			//if (isFirstTime) {
				Set<Id> claimIds = new Set<Id>();
				List<CSX_CMP_Related_Claim__c> relatedClaimList = new List<CSX_CMP_Related_Claim__c>();
				//isFirstTime = false;
				for (CSX_CMP_Related_Claim__c objRelatedClaim : newRelatedClaimList) {
					claimIds.add(objRelatedClaim.CSX_CMP_Claim__c);
					claimIds.add(objRelatedClaim.CSX_CMP_Related_Claim__c);
				}
				Map<Id, Case> caseMap = new Map<Id, Case>(
					[
						SELECT
							Id,
							CaseNumber,
							CSX_CMP_VIN__c,
							CSX_CMP_Equipment_Num__c,
							CSX_CMP_Equipment_Initial__c,
							RecordType.Name
						FROM Case
						WHERE Id IN :claimIds
					]
				);
				for (CSX_CMP_Related_Claim__c objRelatedClaim : newRelatedClaimList) {
					CSX_CMP_Related_Claim__c reverseRelatedClaim = CSX_CMP_Utility.createRelatedClaimInstance(
						caseMap.get(objRelatedClaim.CSX_CMP_Related_Claim__c),
						caseMap.get(objRelatedClaim.CSX_CMP_Claim__c)
					);
					relatedClaimList.add(reverseRelatedClaim);
				}

				if (!relatedClaimList.isEmpty()) {
					Database.UpsertResult[] relatedClaimUpsertResultList = Database.upsert(
						relatedClaimList,
						CSX_CMP_Related_Claim__c.CSX_CMP_External_ID__c,
						false
					);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_RelatedClaimTriggerHandler',
						'handleAfterInsert',
						relatedClaimUpsertResultList,
						'CSX_CMP_Related_Claim__c'
					);
				}
			//}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_RelatedClaimTriggerHandler',
				'handleAfterInsert',
				JSON.serialize(newRelatedClaimList),
				ex
			);
		}
	}
}