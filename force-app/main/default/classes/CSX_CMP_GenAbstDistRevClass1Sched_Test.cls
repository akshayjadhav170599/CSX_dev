@isTest
public class CSX_CMP_GenAbstDistRevClass1Sched_Test {
    
    @isTest
    public static void testExecute() {
        
        Account customerAccount = new Account(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Location'].Id,
            Name = 'Test Account',
            Type = 'Customer',
            Status__c = 'Active',
            Location_Type__c = 'Billing Address',
            CSX_CMP_Class_1_Railroad__c = true
        );
        insert customerAccount;
        
        Account supplierClaimantAccount = new Account(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Location'].Id,
            Name = 'Test Account',
            Type = 'Supplier',
            Status__c = 'Active',
            Location_Type__c = 'Billing Address',
            CSX_CMP_FC_SCAC__c = 'BNSF',
            CSX_CMP_REV_SCAC__c = 'MRPL'
        );
        insert supplierClaimantAccount;
        
       Case FreightClaim1 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Revenue_Railroad'].Id,
            Type = 'Rev-RR - Receivable Claim',
            CSX_CMP_Claim_Amount__c = 10000,
            CSX_CMP_Original_Amount__c = 10500,
            CSX_CMP_Supplier_Claimant__c = supplierClaimantAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = '',
            CSX_CMP_VIN__c = 'Test',
            Status = 'Pending Monthly Settlement',
            CSX_CMP_FCD_Cause_Code__c = '01',
        	CSX_CMP_FCD_Rule_Code__c = '040',
           	CSX_CMP_Service_Period__c = 'PER-11-24',  // need to update as per current month
          	CSX_CMP_Customer__c = customerAccount.Id
        );
		insert FreightClaim1;
        
        CSX_CMP_Equipment__c FreightClaim1Equipment = new CSX_CMP_Equipment__c(
            Name = 'Equipment123',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = FreightClaim1.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420',
            CSX_CMP_Waybill_Controls__c = '1000'
        );
        insert FreightClaim1Equipment;
        
       
        Test.startTest();
        
        CSX_CMP_GenAbstDistRevClass1Schedular scheduler = new CSX_CMP_GenAbstDistRevClass1Schedular();
        
        scheduler.execute(null);
        List<CSX_CMP_Property_Portal_Staging__c> propertyPortalRecords = [SELECT Id, CSX_CMP_Claim_Number__c FROM CSX_CMP_Property_Portal_Staging__c];
        
        Test.stopTest();
        
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE ApexClass.Name = 'CSX_CMP_GeneratePropertyPortalBatch'];
        
        System.assert(!jobs.isEmpty(), 'Expected batch job to be enqueued.');
        System.assertEquals('Completed', jobs[0].Status, 'Expected batch job to be in Completed status.');
       
        //List<CSX_CMP_Error_Log__c> logs = [SELECT Id, CSX_CMP_Message__c FROM CSX_CMP_Error_Log__c WHERE CSX_CMP_Message__c LIKE '%Revenue_Railroad%'];
        
        //System.assert(!logs.isEmpty(), 'Expected error log to be created.');
    }

}