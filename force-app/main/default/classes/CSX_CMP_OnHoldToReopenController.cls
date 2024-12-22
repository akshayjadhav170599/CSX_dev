/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldToReopenController
@Created Date - 5/24/2024
@Description  - This class is primarily responsible for fetching and preparing claim-related data for display
@RICEFW reference - CMP-E-0439
*/
public with sharing class CSX_CMP_OnHoldToReopenController {
    public CSX_CMP_claimWrapper claimWrapper {get;set;}
    public ClaimLineWrapper claimLineWrapper {get;set;}
    public Id caseId {
        get; 
        set{
            caseId = value;
            getclaimDetails();
        }
    }
    
    public CSX_CMP_claimWrapper getclaimDetails(){
        claimWrapper = new CSX_CMP_claimWrapper ();
        Case claimDetails =[SELECT Id,Owner.Name,CaseNumber,
                            (Select Id,CSX_CMP_Claim__c,CSX_CMP_Balance_Due__c,CSX_CMP_Claim_Amount__c,CSX_CMP_Freight_Bill_Num__c from ClaimLines__r)
                            FROM Case where Id =: caseId WITH SECURITY_ENFORCED LIMIT 1 ];           
        if(claimDetails != null){
            claimWrapper.claimNumber = claimDetails.CaseNumber;               
            claimWrapper.ownerName = claimDetails.Owner.Name;
            String baseUrl = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Case/';
            String caseId = claimDetails.id;
            claimWrapper.claimInformation = baseUrl + caseId +'/view'; 
            
            if (claimDetails.ClaimLines__r != null && !claimDetails.ClaimLines__r.isEmpty()) {
                claimWrapper.claimLines = new List<ClaimLineWrapper>();
                for (CSX_CMP_Claim_Line__c claimLine : claimDetails.ClaimLines__r) {
                    if(claimLine.CSX_CMP_Claim_Amount__c!=null && claimLine.CSX_CMP_Balance_Due__c!=null && (claimLine.CSX_CMP_Claim_Amount__c > claimLine.CSX_CMP_Balance_Due__c)){
                        claimLineWrapper  = new ClaimLineWrapper();
                        claimLineWrapper.freightBillNum = claimLine.CSX_CMP_Freight_Bill_Num__c;
                        claimLineWrapper.balanceDue = claimLine.CSX_CMP_Balance_Due__c;
                        claimLineWrapper.claimAmount = claimLine.CSX_CMP_Claim_Amount__c;
                        claimWrapper.claimLines.add(claimLineWrapper);  
                    }
                }
            }                                  
        }       
        return claimWrapper;
    }
            
    public class CSX_CMP_claimWrapper{       
        Public String claimNumber {get;set;}
        Public String ownerName {get;set;}
        Public String claimInformation {get;set;}
        public List<ClaimLineWrapper>   claimLines {get;set;} 
    }
    public class ClaimLineWrapper{        
        Public String freightBillNum {get;set;}  
        Public Decimal balanceDue {get;set;}
        Public Decimal claimAmount{get;set;}                
    }    
}