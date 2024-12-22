/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldIncentiveEmailController
@Created Date - 12/17/2023
@Description  - This Apex class retrieves and encapsulates claim details for on-hold incentive emails, providing access to claim information
@RICEFW reference - CMP-E-0439
**/
public with sharing class CSX_CMP_OnHoldIncentiveEmailController {
public CSX_CMP_claimWrapper claimWrapper {get;set;}
    public Id caseId {
        get; 
        set{
            caseId = value;
            getclaimDetails();
        }
    }
   
    public CSX_CMP_claimWrapper getclaimDetails(){
        claimWrapper = new CSX_CMP_claimWrapper ();
            Case claimDetails =[SELECT Id,CSX_CMP_Claim_Amount__c,CaseNumber,CSX_CMP_Case_Number_Formula__c                                    
                                FROM Case where Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];           
            if(claimDetails != null){
                //claimWrapper.claimNumber = claimDetails.CaseNumber; 
                claimWrapper.claimNumber = claimDetails.CSX_CMP_Case_Number_Formula__c;              
                claimWrapper.claimAmount = claimDetails.CSX_CMP_Claim_Amount__c;
                String baseUrl = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Case/';
                String caseId = claimDetails.id;
                claimWrapper.claimInformation = baseUrl + caseId +'/view';               
            }
        
        return claimWrapper;
     }

     

    public class CSX_CMP_claimWrapper{       
        public String  claimNumber {get;set;}
        public Decimal claimAmount {get;set;}
        public String  claimInformation { get; set; }      
    }    
}