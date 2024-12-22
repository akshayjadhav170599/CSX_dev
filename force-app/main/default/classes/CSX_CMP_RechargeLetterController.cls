/*
RICEFW Id : CMP-E-0433
@description : This class is used as controller class for VF page(CSX_CMP_RechargeLetterPage)
@author : Infosys
@name : CSX_CMP_RechargeLetterController
*/
public with sharing class CSX_CMP_RechargeLetterController {
	public CaseWrapper objCaseWrapper { get; set; }
	public String recordId { get; set; }
	public string csxLogo { get; set; }

	public CSX_CMP_RechargeLetterController() {
		csxLogo = CSX_CMP_Utility.logoUrl();
		recordId = ApexPages.currentPage().getParameters().get('recordId');
		if (recordId != null) {
			// String fileName = 'Recharge';
			fetchClaimDetails();
		} else {
			String record = ApexPages.currentPage().getParameters().get('case');
			Case caseRecords = (Case) JSON.deserialize(record, Case.class);
			objCaseWrapper = getClaimDetails(caseRecords);
		}
	}

	public CaseWrapper fetchClaimDetails() {
		List<Case> caseRecords = getCaseDetails(new List<String>{ recordId });
		CaseWrapper caseDetails = getClaimDetails(caseRecords[0]);
		return caseDetails;
	}

	public static List<Case> getCaseDetails(List<String> caseIds) {
		List<Case> objCaseDetails = [
			SELECT
				Id,
				CSX_CMP_Claim_Date__c,
				CSX_CMP_Claim_Amount__c,
				CSX_CMP_Case_Number_Formula__c,
				CSX_CMP_Supplier_Claimant__r.name,
				parent.CSX_CMP_Claimant_Ref_Num__c,
				(SELECT id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Recharge Reason') 
			FROM Case
			WHERE Id = :caseIds
			WITH SECURITY_ENFORCED
		];
		return objCaseDetails;
	}

	public CaseWrapper getClaimDetails(Case claim) {
		objCaseWrapper = new CaseWrapper();
		if (claim != null) {
			objCaseWrapper.claimDate = DateTime.newInstance(
					claim.CSX_CMP_Claim_Date__c.year(),
					claim.CSX_CMP_Claim_Date__c.month(),
					claim.CSX_CMP_Claim_Date__c.day()
				)
				.format('MM/dd/yyyy');
			objCaseWrapper.claimAmount = claim.CSX_CMP_Claim_Amount__c;
			objCaseWrapper.caseNumber = claim.CSX_CMP_Case_Number_Formula__c;
			objCaseWrapper.supplier = claim.CSX_CMP_Supplier_Claimant__r.name;
			objCaseWrapper.foreignCustClaimNo = claim.parent.CSX_CMP_Claimant_Ref_Num__c != null ? claim.parent.CSX_CMP_Claimant_Ref_Num__c : '';
			if (claim.Notes__r.size() > 0) {
				objCaseWrapper.reason = claim.Notes__r[0].CSX_CMP_Notes__c;
			}
		}
		return objCaseWrapper;
	}

	public class CaseWrapper {
		public String claimDate { get; set; }
		public Decimal claimAmount { get; set; }
		public String caseNumber { get; set; }
		public String supplier { get; set; }
		public String reason { get; set; }
		public String foreignCustClaimNo { get; set; }
	}
}