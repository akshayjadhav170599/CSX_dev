/**
@Author       - Infosys
@Name         - CSX_CMP_TotalCostofClaimHelper
@Created Date - 2/17/2024
@Description  - The class to calculate total cost of claim based on AR Settlement and related claim
@RICEFW reference - CMP-E-0420
*/
public with sharing class CSX_CMP_TotalCostofClaimHelper {
	/* 
	@description : method for UI logic to display total cost of claim total and breakup
	@param : claimId
    @return : List<CostofClaimTransactionWrapper>
	*/
	@AuraEnabled
	public static List<CostofClaimTransactionWrapper> fetchCostofClaimTransactions(Id claimId) {
		List<CostofClaimTransactionWrapper> result = new List<CostofClaimTransactionWrapper>();
		try {
			if (claimId != null) {
				Case claimFullDetails = getCaseDetails(new Set<Id>{ claimId })[0];
				result = prepareCostofClaimTransactions(claimFullDetails);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_TotalCostofClaimHelper',
				'fetchCostofClaimTransactions',
				claimId,
				e
			);
		}

		return result;
	}
	/* 
	@description : method to calculate total cost of claim
	@param : casedata
    @return : List<CostofClaimTransactionWrapper>
	*/
	private static List<CostofClaimTransactionWrapper> prepareCostofClaimTransactions(Case casedata) {
		List<CostofClaimTransactionWrapper> result = new List<CostofClaimTransactionWrapper>();
		Decimal totalChildClaimsAmount = 0;
		Decimal totalARSettlementAmount = 0;
		Decimal claimAmountFromField = 0;
		Decimal projectAmount = 0;
		Decimal totalAmount = 0;
		Decimal salvageAmount = 0;
		Decimal frevAmount = 0;
		try {
			if (caseData.CSX_CMP_Claim_Amount__c != null && caseData.CaseNumber != null) {
				claimAmountFromField = caseData.CSX_CMP_Claim_Amount__c != null ? caseData.CSX_CMP_Claim_Amount__c : 0;
				result.add(
					prepareCostofClaimTransInstance('Current Claim', caseData.CaseNumber, caseData.Id, claimAmountFromField)
				);
			}
			if (casedata.CSX_CMP_Project_Amount__c != null && casedata.CSX_CMP_Project_Num__c != null) {
				Decimal positivePRAmt = casedata.CSX_CMP_Project_Amount__c < 0
					? (0 - casedata.CSX_CMP_Project_Amount__c)
					: casedata.CSX_CMP_Project_Amount__c;
				projectAmount = positivePRAmt;
				result.add(
					prepareCostofClaimTransInstance(
						'Project Billing',
						casedata.CSX_CMP_Project_Num__c,
						casedata.Id,
						0 - positivePRAmt
					)
				);
			}

			if (casedata.CSX_CMP_Salvage_Amount__c != null) {
				Decimal salvagePRAmt = casedata.CSX_CMP_Salvage_Amount__c < 0
					? (0 - casedata.CSX_CMP_Salvage_Amount__c)
					: casedata.CSX_CMP_Salvage_Amount__c;
				salvageAmount = salvagePRAmt;
				result.add(
					prepareCostofClaimTransInstance('Salvage Amount', casedata.CaseNumber, casedata.Id, 0 - salvagePRAmt)
				);
			}

			if (casedata.CSX_CMP_Freight_Revenue_Amount__c != null) {
				Decimal frevPRAmt = casedata.CSX_CMP_Freight_Revenue_Amount__c < 0
					? (0 - casedata.CSX_CMP_Freight_Revenue_Amount__c)
					: casedata.CSX_CMP_Freight_Revenue_Amount__c;
				frevAmount = frevPRAmt;
				result.add(prepareCostofClaimTransInstance('FREV Amount', casedata.CaseNumber, casedata.Id, 0 - frevPRAmt));
			}

			if (!casedata.AR_Settlement__r.isEmpty()) {
				for (CSX_CMP_AR_Settlement__c arSettlement : casedata.AR_Settlement__r) {
					if (arSettlement.CSX_CMP_Invoice_Amount__c != null) {
						Decimal positiveAmt = arSettlement.CSX_CMP_Invoice_Amount__c < 0
							? (0 - arSettlement.CSX_CMP_Invoice_Amount__c)
							: arSettlement.CSX_CMP_Invoice_Amount__c;
						totalARSettlementAmount += positiveAmt;
						if (arSettlement.Name != null) {
							result.add(
								prepareCostofClaimTransInstance('AR Settlement', arSettlement.Name, arSettlement.Id, 0 - positiveAmt)
							);
						}
					}
				}
			}

			//excluding related claims in calculation on child claims.
			if (
				!casedata.Related_Claims__r.isEmpty() &&
				casedata.Type != 'FC RR Outbound Claim' &&
				casedata.Type != 'Recharges Outbound Claim'
			) {
				for (CSX_CMP_Related_Claim__c relatedClaim : casedata.Related_Claims__r) {
					if (relatedClaim.CSX_CMP_Claim_Amount__c != null && relatedClaim.CSX_CMP_Related_Claim__r.parentId != null) {
						Decimal positiveRCAmt = relatedClaim.CSX_CMP_Claim_Amount__c < 0
							? (0 - relatedClaim.CSX_CMP_Claim_Amount__c)
							: relatedClaim.CSX_CMP_Claim_Amount__c;
						totalChildClaimsAmount += positiveRCAmt;
						String type = '';
						if (relatedClaim.CSX_CMP_Claim_Type__c == 'FC RR Outbound Claim') {
							type = 'Distribution Claim';
						} else if (relatedClaim.CSX_CMP_Claim_Type__c == 'Recharges Outbound Claim') {
							type = 'Recharge Claim';
						}
						result.add(
							prepareCostofClaimTransInstance(
								type,
								relatedClaim.CSX_CMP_Related_Claim__r.CaseNumber,
								relatedClaim.CSX_CMP_Related_Claim__c,
								0 - positiveRCAmt
							)
						);
					}
				}
			}

			totalAmount =
				claimAmountFromField -
				(totalChildClaimsAmount +
				projectAmount +
				totalARSettlementAmount +
				salvageAmount +
				frevAmount);

			result.add(prepareCostofClaimTransInstance('Total Amount', '', '', totalAmount));
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_TotalCostofClaimHelper', 'totalcostcalculation', '', ex);
		}
		for (CostofClaimTransactionWrapper ct : result) {
		}
		return result;
	}
	/* 
	@description : method to prepare CostofClaimTransactionWrapper object
	@param : type,referrenceNum,referrenceRecordId,amount
    @return : CostofClaimTransactionWrapper
	*/
	private static CostofClaimTransactionWrapper prepareCostofClaimTransInstance(
		String type,
		String referrenceNum,
		String referrenceRecordId,
		Decimal amount
	) {
		CostofClaimTransactionWrapper newObj = new CostofClaimTransactionWrapper();
		newObj.type = type;
		newObj.referrenceNum = referrenceNum;
		newObj.referrenceRecordId = referrenceRecordId;
		newObj.amount = amount;
		return newObj;
	}
	/* 
	@description : method to fetch required transactions and update Total cost of claim
	@param : Set<Id> targetClaimIds
	*/
	public static void updateTotalCostofClaim(Set<Id> targetClaimIds) {
		try {
			List<Case> claimsToBeUpdated = new List<Case>();
			Map<Case, List<CostofClaimTransactionWrapper>> inputTransactions = new Map<Case, List<CostofClaimTransactionWrapper>>();
			if (!targetClaimIds.isEmpty()) {
				List<Case> targetClaims = getCaseDetails(targetClaimIds);

				//fetch required transactions
				if (!targetClaims.isEmpty()) {
					for (Case claim : targetClaims) {
						inputTransactions.put(claim, prepareCostofClaimTransactions(claim));
					}
				}
			}

			Map<String, Decimal> claimAmountMap = new Map<String, Decimal>();
			//add logic to find the total and update the claim
			for (Case claim : inputTransactions.keySet()) {
				List<CostofClaimTransactionWrapper> claimTransactions = inputTransactions.get(claim);
				for (CostofClaimTransactionWrapper wrap : claimTransactions) {
					if (wrap.type == 'Total Amount') {
						// Case newClaim = new Case(Id = claim.Id);
						// newClaim.CSX_CMP_Total_Cost_of_Claim__c = wrap.amount;
						// claimsToBeUpdated.add(newClaim);
						claimAmountMap.put(claim.Id, wrap.amount);
						break;
					}
				}
			}

			claimsToBeUpdated = [
				SELECT Id, CSX_CMP_Total_Cost_of_Claim__c, CSX_CMP_System_Action_Toggle__c
				FROM Case
				WHERE Id IN :claimAmountMap.keySet() WITH SECURITY_ENFORCED
			];
			for (Case claim : claimsToBeUpdated) {
				claim.CSX_CMP_Total_Cost_of_Claim__c = claimAmountMap.get(claim.Id);
			}

			Database.SaveResult[] updateClaimAmount = Database.update(claimsToBeUpdated, false);

			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_TotalCostofClaimHelper',
				'updateTotalCostofClaim',
				updateClaimAmount,
				'Case'
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_TotalCostofClaimHelper', 'updateTotalCostofClaim', JSON.serialize(targetClaimIds), e);
		}
	}
	/* 
	@description : method to case details using query
	@param : Set<Id> targetClaimIds
	@return : casedata
	*/
	private static List<Case> getCaseDetails(Set<Id> targetClaimIds) {
		try {
			List<Case> casedata = [
				SELECT
					Id,
					CSX_CMP_Project_Amount__c,
					CSX_CMP_Claim_Amount__c,
					CSX_CMP_Freight_Revenue_Amount__c,
					CSX_CMP_Salvage_Amount__c,
					CaseNumber,
					Type,
					CSX_CMP_Project_Num__c,
					CSX_CMP_Total_Cost_of_Claim__c,
					(
						SELECT Id, Name, CSX_CMP_Claim__c, CSX_CMP_Invoice_Amount__c, CSX_CMP_Invoice_Payment_Status__c
						FROM AR_Settlement__r
						WHERE CSX_CMP_Invoice_Payment_Status__c != 'Cancelled'
					),
					(
						SELECT
							Id,
							CSX_CMP_Related_Claim__c,
							CSX_CMP_Related_Claim__r.CaseNumber,
							CSX_CMP_Related_Claim__r.parentId,
							CSX_CMP_Claim_Amount__c,
							Name,
							CSX_CMP_Claim_Status__c,
							CSX_CMP_Claim_Type__c
						FROM Related_Claims__r
						WHERE
							CSX_CMP_Claim_Status__c != 'Cancelled'
							AND CSX_CMP_Claim_Status__c != 'Re-Declined'
							AND CSX_CMP_Claim_Status__c != 'Declined'
							AND CSX_CMP_Related_Claim__r.Type IN ('FC RR Outbound Claim', 'Recharges Outbound Claim')
					)
				FROM Case
				WHERE id IN :targetClaimIds
				WITH SECURITY_ENFORCED
			];
			return casedata;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_TotalCostofClaimHelper', 'getCaseDetails', '', e);
			return null;
		}
	}
	/* 
	@description : Validation for updating related claim and total cost of claim called from Trigger Helper
	@param : Set<Id> childClaimIdsforTotalCostofClaim
	@return : parentClaimIds
	*/

	public static Set<Id> identifyParentClaimsforTotalCostCalc(Set<Id> childClaimIdsforTotalCostofClaim) {
		Set<Id> parentClaimIds = new Set<Id>();
		try {
			if (!childClaimIdsforTotalCostofClaim.isEmpty()) {
				List<CSX_CMP_Distribution__c> distributionList = [
					SELECT id, CSX_CMP_Equipment__r.CSX_CMP_Claim__c, CSX_CMP_Distribution_Claim__c
					FROM CSX_CMP_Distribution__c
					WHERE CSX_CMP_Distribution_Claim__c IN :childClaimIdsforTotalCostofClaim
					WITH SECURITY_ENFORCED
				];
				if (!distributionList.isEmpty()) {
					for (CSX_CMP_Distribution__c distribution : distributionList) {
						parentClaimIds.add(distribution.CSX_CMP_Equipment__r.CSX_CMP_Claim__c);
					}
				}
				//add logic to fetch parent claims of recharge claims.
				List<CSX_CMP_Related_Claim__c> relatedClaimList = [
					SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Related_Claim__c
					FROM CSX_CMP_Related_Claim__c
					WHERE
						CSX_CMP_Related_Claim__c IN :childClaimIdsforTotalCostofClaim
						AND CSX_CMP_Claim__r.Type IN ('FC RR Inbound Claim', 'Recharges Inbound Claim')
						AND CSX_CMP_Related_Claim__r.Type = 'Recharges Outbound Claim'
					WITH SECURITY_ENFORCED
				];
				if (!relatedClaimList.isEmpty()) {
					for (CSX_CMP_Related_Claim__c relClaim : relatedClaimList) {
						parentClaimIds.add(relClaim.CSX_CMP_Claim__c);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_TotalCostofClaimHelper',
				'identifyParentClaimsforTotalCostCalc',
				'',
				ex
			);
		}
		return parentClaimIds;
	}
	/* 
	@description : Method to claculate the total cost of claim after inserting AR record
	@param : List<FlowWrapper> flowWrapper
	*/
	@InvocableMethod(label='Update Total Cost of Claim' description='Update Total Cost of Claim')
	public static void invocableMethodForTotalCostofClaim(List<FlowWrapper> flowWrapper) {
		try {
			//List<Case> returnCaseList = getCaseDetails(new Set<Id>(flowWrapper[0].claimIds));
			if (!flowWrapper[0].claimIds.isEmpty()) {
				updateTotalCostofClaim(new Set<Id>(flowWrapper[0].claimIds));
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_TotalCostofClaimHelper',
				'invocableMethodForTotalCostofClaim',
				'',
				e
			);
		}
	}

	public class FlowWrapper {
		@InvocableVariable
		public List<Id> claimIds;
	}

	public class CostofClaimTransactionWrapper {
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String referrenceNum;
		@AuraEnabled
		public String referrenceRecordId;
		@AuraEnabled
		public Decimal amount;
	}
}