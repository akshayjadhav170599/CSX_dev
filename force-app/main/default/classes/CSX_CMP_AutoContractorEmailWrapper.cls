/**
 
**/
public with sharing class CSX_CMP_AutoContractorEmailWrapper {
    public CSX_CMP_ARWrapper arWrapper {get;set;}
    public  string csxLogo {get; set;}
    public Id arSettlementId {
        get;
        set{
            arSettlementId = value;
            getARDetails();
        }
    }
		    
    public CSX_CMP_ARWrapper getARDetails() {
       // csxLogo = CSX_CMP_Utility.logoUrl();
        CSX_CMP_ARWrapper wrapper = new CSX_CMP_ARWrapper();
        try{
            if(Schema.sObjectType.CSX_CMP_AR_Settlement__c.isAccessible()){
                CSX_CMP_AR_Settlement__c details = [SELECT Id, Name, CSX_CMP_Invoice_Number__c, CSX_CMP_Invoice_Date__c, CSX_CMP_Customer_Number__c,
                                                    CSX_CMP_Customer_Name__r.Name,CSX_CMP_Claim__r.CaseNumber,CSX_CMP_Claim__r.Status,CSX_CMP_Claim__r.type,CSX_CMP_Claim__c
                                                    //  (SELECT ID, CSX_CMP_Incident_Location__c,CSX_CMP_Amount__c FROM X3rd_Partys__r)
                                                    FROM CSX_CMP_AR_Settlement__c WHERE Id = :arSettlementId WITH SECURITY_ENFORCED LIMIT 1];
                if(Schema.sObjectType.CSX_CMP_Equipment__c.isAccessible()){
                    CSX_CMP_Equipment__c relatedEquipment = [SELECT Id,(SELECT Id, CSX_CMP_VIN__c  FROM Products__r WHERE CSX_CMP_VIN__c != null),
                                                            (SELECT ID, CSX_CMP_Incident_Location__c,CSX_CMP_Amount__c,CSX_CMP_Party_Name__r.name FROM X3rd_Partys__r Order by CreatedDate DESC)
                                                            FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c = :details.CSX_CMP_Claim__c WITH SECURITY_ENFORCED  LIMIT 1];     
                    if (details != null) {
                        wrapper.invoiceNumber = details.CSX_CMP_Invoice_Number__c;
                        wrapper.claimNumber = details.CSX_CMP_Claim__r.CaseNumber;
                        wrapper.status = details.CSX_CMP_Claim__r.Status;
                        wrapper.billDate = details.CSX_CMP_Invoice_Date__c != null ? CSX_CMP_Utility.formatDate(details.CSX_CMP_Invoice_Date__c) : '';
                        wrapper.customerNumber = details.CSX_CMP_Customer_Number__c;
                        wrapper.dueDate = details.CSX_CMP_Invoice_Date__c != null ? CSX_CMP_Utility.formatDate(details.CSX_CMP_Invoice_Date__c) : '';
                        
                        if (relatedEquipment.Id != null && details.CSX_CMP_Claim__r.type=='FC Customer Automobile Claim') {
                            wrapper.vinNumber = relatedEquipment.Products__r[0].CSX_CMP_VIN__c ;
                        }
                        
                        if (!relatedEquipment.X3rd_Partys__r.isEmpty()) {
                            wrapper.incidentLocation = relatedEquipment.X3rd_Partys__r[0].CSX_CMP_Incident_Location__c;
                            wrapper.customerName = relatedEquipment.X3rd_Partys__r[0].CSX_CMP_Party_Name__r.name; 
                            wrapper.origBillAmount = relatedEquipment.X3rd_Partys__r[0].CSX_CMP_Amount__c;                               
                        }              
                        arWrapper = wrapper;
                        
                    }
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_AutoContractorEmailWrapper', 'getARDetails','', ex);  
        }
        return arWrapper;
    }
    
   
    
    /*   public CSX_CMP_AutoContractorEmailWrapper() {
String arSettlementId = ApexPages.currentPage().getParameters().get('id');
if (arSettlementId != null) {
this.arSettlementId = arSettlementId;
}
} */
    
    public class CSX_CMP_ARWrapper {  
        public String customerName {get;set;}
        public String customerNumber {get;set;}  
        public String invoiceNumber {get;set;}
        public String claimNumber {get;set;}
        public String status {get;set;}
        public String incidentLocation {get;set;}
        public String vinNumber {get;set;}
        public String billDate {get;set;}
        public String dueDate {get;set;}
        public Decimal origBillAmount {get;set;}        
        
    }
}