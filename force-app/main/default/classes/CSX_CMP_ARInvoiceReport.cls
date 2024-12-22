/**
@Author       - Infosys
@Name         - CSX_CMP_ARInvoiceReport
RICEFW #      - CMP-I-0491
@Created Date - 03/06/2024
@Description  - VF page controller to get AR details and build VF page wrapper for Invoice Report PDF
*/
public with sharing class CSX_CMP_ARInvoiceReport {
    public CSX_CMP_ARWrapper arWrapper {get;set;}
    public String arSettlementId {get;set;}
  //  public  string csxLogo {get; set;}
    public CSX_CMP_ARInvoiceReport(ApexPages.StandardController controller) {
        arSettlementId = ApexPages.CurrentPage().getparameters().get('id');   
        if(String.isNotBlank(arSettlementId)){
            arWrapper = getARDetails();
        }       
    }

  /*  @description - This method is used to get the AR details and rendered the PDF. */

    public CSX_CMP_ARWrapper getARDetails() {     
        //csxLogo = CSX_CMP_Utility.logoUrl();  
        if(Schema.sObjectType.CSX_CMP_AR_Settlement__c.isAccessible()){
        CSX_CMP_AR_Settlement__c details = [SELECT Id, Name, CSX_CMP_Invoice_Number__c,CSX_CMP_Invoice_Amount__c,CSX_CMP_Invoice_Date__c, CSX_CMP_Customer_Number__c, CSX_CMP_Balance_Due__c,
                                            CSX_CMP_Customer_Name__r.Name, CSX_CMP_Customer_Name__r.BillingAddress, CSX_CMP_Customer_Name__r.BillingCity,
                                            CSX_CMP_Customer_Name__r.BillingStreet, CSX_CMP_Customer_Name__r.BillingState, CSX_CMP_Customer_Name__r.BillingPostalcode,
                                            CSX_CMP_Customer_Name__r.BillingCountry, CSX_CMP_Claim__r.CaseNumber, CSX_CMP_Claim__r.type,CSX_CMP_Claim__r.CSX_CMP_Service_Period__c, CSX_CMP_Claim__c
                                            FROM CSX_CMP_AR_Settlement__c WHERE Id = :arSettlementId WITH SECURITY_ENFORCED LIMIT 1 ];
        

        if(Schema.sObjectType.CSX_CMP_Equipment__c.isAccessible()){   
        if(details != null) {
            
            List<CSX_CMP_Equipment__c> relatedEquipment = [SELECT Id, Name, CSX_CMP_Waybill_Num__c, CSX_CMP_Waybill_Date__c,
                                                     CSX_CMP_Act_Origin_City__c, CSX_CMP_Act_Origin_State__c,CSX_CMP_Claim__c,
                                                     CSX_CMP_Act_Destination_City__c, CSX_CMP_Act_Destination_State__c,
                                                     (SELECT Id, CSX_CMP_VIN__c
                                                      FROM Products__r WHERE CSX_CMP_VIN__c != null),
                                                     (SELECT ID, CSX_CMP_Incident_Location__c,CSX_CMP_Amount__c FROM X3rd_Partys__r)
                                                     FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c = :details.CSX_CMP_Claim__c WITH SECURITY_ENFORCED LIMIT 1 ];
           
            String address = details.CSX_CMP_Customer_Name__r.BillingCity + ' , ' + details.CSX_CMP_Customer_Name__r.BillingStreet + ' , ' +
                details.CSX_CMP_Customer_Name__r.BillingState + ' , ' + details.CSX_CMP_Customer_Name__r.BillingPostalcode + ' , ' +
                details.CSX_CMP_Customer_Name__r.BillingCountry;
            
            System.debug('details.CSX_CMP_Invoice_Number__c::: ' +details.CSX_CMP_Invoice_Number__c);
            //System.debug('CSX_CMP_Incident_Location__c:::' +relatedEquipment[0].X3rd_Partys__r[0].CSX_CMP_Incident_Location__c );
            //System.debug('CSX_CMP_VIN__c:::: '+relatedEquipment[0].Products__r[0].CSX_CMP_VIN__c);

            CSX_CMP_ARWrapper wrapper = new CSX_CMP_ARWrapper();
            wrapper.itemQuantity = 1.00;
            wrapper.paymentTerms = '15 Days';
            wrapper.invoiceNumber = details.CSX_CMP_Invoice_Number__c;
            wrapper.claimNumber = details.CSX_CMP_Claim__r.CaseNumber;
            wrapper.billDate = details.CSX_CMP_Invoice_Date__c != null ? CSX_CMP_Utility.formatDate(details.CSX_CMP_Invoice_Date__c) : '';
            wrapper.customerNumber = details.CSX_CMP_Customer_Number__c;
            wrapper.claimType = details.CSX_CMP_Claim__r.type;
            wrapper.servicePeriod = details.CSX_CMP_Claim__r.CSX_CMP_Service_Period__c;
            wrapper.customerName = details.CSX_CMP_Customer_Name__r.Name != null ? details.CSX_CMP_Customer_Name__r.Name : '';
            wrapper.customerAddress = address != null ? address : '';
            wrapper.dueDate = calculateDueDate(details.CSX_CMP_Invoice_Date__c);
            
            if (!relatedEquipment.isEmpty() && relatedEquipment[0]!=null) {
                wrapper.equipment = relatedEquipment[0].Name;
                wrapper.wayBillNumber = relatedEquipment[0].CSX_CMP_Waybill_Num__c;
                wrapper.wayBillDate = relatedEquipment[0].CSX_CMP_Waybill_Date__c != null ? CSX_CMP_Utility.formatDate(relatedEquipment[0].CSX_CMP_Waybill_Date__c) : '';
                wrapper.originCity = relatedEquipment[0].CSX_CMP_Act_Origin_City__c;
                wrapper.originState = relatedEquipment[0].CSX_CMP_Act_Origin_State__c;
                wrapper.destinationCity = relatedEquipment[0].CSX_CMP_Act_Destination_City__c;
                wrapper.destinationState = relatedEquipment[0].CSX_CMP_Act_Destination_State__c;
                if(!relatedEquipment[0].Products__r.isEmpty() && relatedEquipment[0].Products__r[0] != null){
                    wrapper.vinNumber = relatedEquipment[0].Products__r[0].CSX_CMP_VIN__c ;
                }
            }
            
            if (!relatedEquipment.isEmpty() && !relatedEquipment[0].X3rd_Partys__r.isEmpty() && relatedEquipment[0].X3rd_Partys__r[0] != null) {
                wrapper.incidentLocation = relatedEquipment[0].X3rd_Partys__r[0].CSX_CMP_Incident_Location__c;              
            }
            wrapper.amount = details.CSX_CMP_Invoice_Amount__c;
            wrapper.itemPrice = details.CSX_CMP_Invoice_Amount__c;
            wrapper.invoiceTotal =details.CSX_CMP_Invoice_Amount__c;
            wrapper.amountDue = details.CSX_CMP_Balance_Due__c;
            
            return wrapper;
        }
        }
    }
        return null;
    }

   
     /*  @description - This method is used to calculate Due date. */
    public String calculateDueDate(Date billDate){
        if (billDate != null){
            Date dueDate = billDate.addDays(15);
            return CSX_CMP_Utility.formatDate(dueDate);
        }
        return '';
    }
    
    public class CSX_CMP_ARWrapper {
        public String fedralId {get;set;}
        public String invoiceNumber {get;set;}
        public String claimNumber {get;set;}
        public String billDate {get;set;}
        public String customerNumber {get;set;}
        public String claimType {get;set;}
        public String customerName {get;set;}
        public String customerAddress {get;set;}
        public String equipment {get;set;}
        public String wayBillNumber {get;set;}
        public String wayBillDate {get;set;}
        public String originCity {get;set;}
        public String originState {get;set;}
        public String destinationCity {get;set;}
        public String destinationState {get;set;}
        public String incidentLocation {get;set;}
        public String vinNumber {get;set;}
        public Decimal itemQuantity {get;set;}
        public Decimal itemPrice {get;set;}
        public Decimal amount {get;set;}
        public Decimal invoiceTotal {get;set;}
        public Decimal amountDue {get;set;}
        public String dueDate {get;set;}
        public String paymentTerms {get;set;}
        public String servicePeriod {get;set;}
    }
}