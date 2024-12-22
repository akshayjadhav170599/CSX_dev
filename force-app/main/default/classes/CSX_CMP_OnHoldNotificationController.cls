/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldNotificationController
@Created Date - 05/01/2024
@Description  - This Apex Class is used to construct the email for customer notification to notify them once
claim is updated on hold
@RICEFW reference - CMP-E-0432
*/
public with sharing class CSX_CMP_OnHoldNotificationController {
	public static String caseId {
		get;
		set {
			caseId = value;
			getClaimDetails();
		}
	}
	public static Integer noOfDays { get; set; }
	public static Decimal totalFinanceCharge { get; set; }
	public static Decimal amount { get; set; }
	public static Integer percentage { get; set; }
	public static Case objCase { get; set; }
	public string csxLogo { get; set; }

	public CSX_CMP_OnHoldNotificationController() {
		csxLogo = CSX_CMP_Utility.logoUrl();
	}
	//Below method is used to fetch the claim and related obejct details based on claim id
	public static void getClaimDetails() {
		if (!string.isempty(caseId)) {
			list<Case> lstCase = [
				SELECT
					Id,
					CaseNumber,CSX_CMP_Case_Number_Formula__c,
					CSX_CMP_Supplier_Claimant_Num__c,
					CSX_CMP_Claim_Amount__c,
					CSX_CMP_Claim_Date__c,
					CSX_CMP_Period_Begin__c,
					CSX_CMP_Period_End__c,
					CSX_CMP_Customer__r.Name,
					CSX_CMP_Contract_Num__r.Name,
					CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c,
					CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c,
					RecordType.developerName,
					Type
				FROM Case
				WHERE Id = :caseId
				WITH SECURITY_ENFORCED
			];

			if (lstCase != null && lstCase.size() > 0) {
				objCase = lstCase[0];

				Set<Id> setOfClaim = new Set<Id>();
				Map<Id, String> mapOfClaimWithTH = new Map<Id, String>();

				setOfClaim.add(lstCase[0].Id);

				mapOfClaimWithTH = CSX_CMP_BusinessRulesUtility.runARThresholdBusinessRules(
					setOfClaim,
					'CSX_CMP_AR_Threshold',
					null
				);

				String strThreshold = mapOfClaimWithTH.get(lstCase[0].Id);
				List<String> lstThreshold = strThreshold.split('###');
				amount = Decimal.valueOf(lstThreshold[1]);
				percentage = Integer.valueOf(lstThreshold[2]);
				totalFinanceCharge = Decimal.valueOf(lstThreshold[3]);
			}
		}
	}
}