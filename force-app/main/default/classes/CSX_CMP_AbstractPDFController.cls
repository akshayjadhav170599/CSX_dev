/**************************************************************************************
Apex Class Name     : CSX_CMP_AbstractPDFController
Function            : 
RICEFW #            : 
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           04/10/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_AbstractPDFController {
	public List<ClaimInputWrapper> claimWrapperList { get; set; }
	public Decimal totalAmountSum { get; set; }
	public Integer totalCaseCount { get; set; }
	public string strPropertyPortalId { get; set; }
	public string servicePeriod { get; set; }
	public string type { get; set; }
	public  string csxLogo {get; set;}

	public CSX_CMP_AbstractPDFController() {
		csxLogo = CSX_CMP_Utility.logoUrl(); 
		claimWrapperList = new List<ClaimInputWrapper>();
		set<String> setOfClaimNumber = new Set<String>();
		totalAmountSum = 0;
		totalCaseCount = 0;

		strPropertyPortalId = ApexPages.currentPage().getParameters().get('PPId');

		if (!string.isempty(strPropertyPortalId)) {
			List<CSX_CMP_Property_Portal_Staging__c> lstPropertyPortal = [
				SELECT id, CSX_CMP_Claim_Number__c, CSX_CMP_Service_Period__c, CSX_CMP_Record_Type__c
				FROM CSX_CMP_Property_Portal_Staging__c
				WHERE id = :strPropertyPortalId
				WITH SECURITY_ENFORCED
			];

			if (lstPropertyPortal != null && lstPropertyPortal.size() > 0) {
				if (!string.isempty(lstPropertyPortal[0].CSX_CMP_Claim_Number__c) && lstPropertyPortal[0].CSX_CMP_Claim_Number__c.contains(',')) {
					list<String> lstClaimNumber = lstPropertyPortal[0].CSX_CMP_Claim_Number__c.split(',');
					for (String strClaimNumber : lstClaimNumber) {
						setOfClaimNumber.add(strClaimNumber);
					}
				} else {
					setOfClaimNumber.add(lstPropertyPortal[0].CSX_CMP_Claim_Number__c); 
				}

				servicePeriod = lstPropertyPortal[0].CSX_CMP_Service_Period__c;
				type = lstPropertyPortal[0].CSX_CMP_Record_Type__c;
			}

			List<Case> caseList = [
				SELECT
					CSX_CMP_Supplier_Claimant__r.Name,
					CaseNumber, CSX_CMP_Supplier_Claimant_City_State_Zip__c,
					CSX_CMP_Supplier_Claimant_Street__c,
					CSX_CMP_Customer_Claim_Date__c,
					CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c,
                    CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_Railroad_Road_Code__c,
					CSX_CMP_Claim_Date__c,
					CSX_CMP_Claim_Amount__c,CSX_CMP_Previous_Claim_Num__c,CSX_CMP_Case_Number_Formula__c
				FROM Case
				//WHERE CaseNumber IN :setOfClaimNumber
				WHERE CSX_CMP_Case_Number_Formula__c IN :setOfClaimNumber
				WITH SECURITY_ENFORCED
			];

			if (!caseList.isEmpty()) {
				for (Case objCase : caseList) {
					ClaimInputWrapper caseWrapper = new ClaimInputWrapper();
					caseWrapper.companyName = objCase.CSX_CMP_Supplier_Claimant__r.Name;
					//caseWrapper.rrClaimRefrence = objCase.CaseNumber;
					caseWrapper.rrClaimRefrence = objCase.CSX_CMP_Case_Number_Formula__c;
					caseWrapper.amountPaid = objCase.CSX_CMP_Claim_Amount__c;
					caseWrapper.customerClaimDate = CSX_CMP_Utility.formatDate(objCase.CSX_CMP_Customer_Claim_Date__c);
					caseWrapper.claimDate = CSX_CMP_Utility.formatDate(objCase.CSX_CMP_Claim_Date__c);
					caseWrapper.supplierAddress = objCase.CSX_CMP_Supplier_Claimant_Street__c;
					// caseWrapper.supplierCity = objCase.CSX_CMP_Supplier_Claimant_City__c;
					if(type == 'Freight'){
						caseWrapper.railCode = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c;
					}
					else{
						caseWrapper.railCode = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_Railroad_Road_Code__c;
					}
					caseWrapper.previousClaimNumber = objCase.CSX_CMP_Previous_Claim_Num__c;//[MR-00776]
					claimWrapperList.add(caseWrapper);

					totalAmountSum += objCase.CSX_CMP_Claim_Amount__c;
					totalCaseCount++;
				}
			} else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No records found.'));
			}
		}
	}

	public class ClaimInputWrapper {
		public String companyName { get; set; }
		public String rrClaimRefrence { get; set; }
		public Decimal amountPaid { get; set; }
		public String customerClaimDate { get; set; }
		public String claimDate { get; set; }
		public String supplierAddress { get; set; }
		public String supplierCity { get; set; }
		public String railRoadCode { get; set; }
		public String railCode { get; set; }
		public Decimal totalAmount { get; set; }
		public Integer caseCount { get; set; }
		public String previousClaimNumber{get;set;} //[MR-00776]
	}
}