/**************************************************************************************
/*
@author             : Infosys
@description        : Class for FreightProject VF Component and related operations.
RICEFW #            : CMP-I-0491
Apex Class Name     : CSX_CMP_FreightProjectEmailController
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/

public without sharing class CSX_CMP_FreightProjectEmailController {
   public CSX_CMP_claimWrapper claimWrapper {get;set;}
   public  string csxLogo {get; set;}
    public Id caseId {
        get; 
        set{
            caseId = value;
            getClaimDetails();
        }
    }

    /*  @description - This method is used to get the claim details to send email after changing the project amount. */

    public CSX_CMP_claimWrapper getClaimDetails(){
        //csxLogo = CSX_CMP_Utility.logoUrl();
        Case casedetails = [SELECT ID,CSX_CMP_Project_Num__c,CaseNumber,CSX_CMP_Project_Amount__c,CSX_CMP_Case_Number_Formula__c FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED];
        if(casedetails != null){
            claimWrapper = new CSX_CMP_claimWrapper();
            //claimWrapper.claimNumber = casedetails.CaseNumber;
            claimWrapper.claimNumber = casedetails.CSX_CMP_Case_Number_Formula__c;
			claimWrapper.projectNumber = casedetails.CSX_CMP_Project_Num__c;
            claimWrapper.projectAmount = casedetails.CSX_CMP_Project_Amount__c;
            claimWrapper.claimant = 'CUR LOSS & DMG RES-CLAIMS CLEA (Natural Account 23332050)';
        }
        return claimWrapper;
    }
    public class CSX_CMP_claimWrapper {
        public String claimNumber {get;set;}
        public String projectNumber {get;set;}
		public Decimal projectAmount {get;set;}
		public String task {get;set;}
		public String expendType {get;set;}
		public String claimant {get;set;}

        public CSX_CMP_claimWrapper() {
            this.task = '215';
            this.expendType = 'JAX-TRAIN MOVEMENT CLAIM SERVICES (Budget Center 4815)';
            this.claimant = 'CUR LOSS & DMG RES-CLAIMS CLEA (Natural Account 23332050)';
            
            }
        
    }
    
}