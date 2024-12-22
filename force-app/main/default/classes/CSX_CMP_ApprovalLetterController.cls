/**************************************************************************************

@Author       - Infosys
@Name         - CSX_CMP_ApprovalLetterController
@Created Date - 11/18/2023
@Description  - Class for Claim Approval Letter VF Page and related operations.
@RICEFW reference - MR-00500

*************************************************************************************/
public with sharing class CSX_CMP_ApprovalLetterController {
    public CSX_CMP_claimWrapper objClaimWrapper {get;set;}
    public  string csxLogo {get; set;}
    public Id caseId {
        get; 
        set{
            caseId = value;
            getclaimDetails();
        }
    }

    public CSX_CMP_ApprovalLetterController(){
        String caseIdParam = apexpages.currentpage().getparameters().get('id');
        if (caseIdParam != null) {
            this.caseId = String.escapeSingleQuotes(caseIdParam).escapeHtml4();
        }
    }

    public CSX_CMP_claimWrapper getclaimDetails(){
        csxLogo = CSX_CMP_Utility.logoUrl();

        objClaimWrapper = new CSX_CMP_claimWrapper ();
        Case claimDetails =[SELECT Id, CaseNumber, CSX_CMP_Claim_Date__c, CSX_CMP_Supplier_Claimant__r.Name, CSX_CMP_Customer__r.Name,
                            CSX_CMP_Supplier_Claimant_Num__c, Comments, CSX_CMP_Claim_Amount__c,CSX_CMP_Previous_Claim_Num__c,
                            (SELECT CreatedDate FROM Approval_Histories__r WHERE CSX_CMP_Approval_Process_Completed__c = true),
                            (SELECT CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'CSX Explanation')
                            FROM Case 
                            WHERE Id =: caseId WITH SECURITY_ENFORCED];

        if(claimDetails != null){
            objClaimWrapper.claimDate = CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Claim_Date__c);

            if(claimDetails.Approval_Histories__r != null && claimDetails.Approval_Histories__r.size() > 0)
            {
                objClaimWrapper.claimApprovalDate = CSX_CMP_Utility.formatDate(date.valueOf(claimDetails.Approval_Histories__r[0].CreatedDate));
            }else{
                objClaimWrapper.claimApprovalDate = CSX_CMP_Utility.formatDate(system.today());
            }
            
            objClaimWrapper.supplierName = claimDetails.CSX_CMP_Supplier_Claimant__r.Name;
            objClaimWrapper.customerName = claimDetails.CSX_CMP_Customer__r.Name;
            objClaimWrapper.claimentRefrenceNumber = claimDetails.CSX_CMP_Supplier_Claimant_Num__c;

            if(claimDetails.Notes__r != null && claimDetails.Notes__r.size() > 0){
                objClaimWrapper.comments = claimDetails.Notes__r[0].CSX_CMP_Notes__c;
            }            
            objClaimWrapper.claimAmount = claimDetails.CSX_CMP_Claim_Amount__c;
            objClaimWrapper.claimNo = claimDetails.CaseNumber;
            objClaimWrapper.previousClaimNumber = claimDetails.CSX_CMP_Previous_Claim_Num__c;
        }
        return objClaimWrapper;
    }

    public class CSX_CMP_claimWrapper{
        public string claimDate {get;set;}
        public string claimApprovalDate {get;set;}
        public String supplierName {get;set;}
        public String customerName {get;set;}
        public String claimentRefrenceNumber {get;set;}
        public String comments {get;set;}
        public Decimal claimAmount {get;set;}
        public String claimNo {get;set;}
        public String previousClaimNumber{get;set;} //[MR-00776]
    }
}