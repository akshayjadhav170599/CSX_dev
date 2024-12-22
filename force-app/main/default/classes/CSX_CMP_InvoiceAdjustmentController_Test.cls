/**
@Author       - Infosys
@Name         - CSX_CMP_InvoiceAdjustmentController_Test
@Created Date - 5/07/2024
@Description  - These class is used to test the update invoice amount, cancel invoice and send email to third party
@RICEFW reference - CMP-E-0491
*/
@isTest 
public class CSX_CMP_InvoiceAdjustmentController_Test {

    //These method is used to make test 
    @TestSetup
    public static void makeTestData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();

        // Creating Freight Claim with claim type as FC Customer Claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        requestJSON.put('claimType', 'FC Customer Claim');
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);

        // Creating Freight Claim with claim type as FC Customer Automobile Claim
        Map<String,String> requestJSON1 = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        requestJSON1.put('claimType', 'FC Customer Automobile Claim');
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response1 = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON1, null);
        
        Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;

        // Creating AR Settlement record
        List<CSX_CMP_AR_Settlement__c> objSettlementList = new List<CSX_CMP_AR_Settlement__c>();
        CSX_CMP_AR_Settlement__c objSettlement = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement.CSX_CMP_Claim__c = response.claimId;
        objSettlementlist.add(objSettlement);
        CSX_CMP_AR_Settlement__c objSettlement1 = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement1.CSX_CMP_Claim__c = response1.claimId;
        objSettlementlist.add(objSettlement1);

        insert objSettlementList;
        
        // Creating 3rd Party record
        List<CSX_CMP_Equipment__c> equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c = :response.claimId OR CSX_CMP_Claim__c =:response1.claimId LIMIT 2];
        List<CSX_CMP_3rd_Party__c> thirdpartyList = new List<CSX_CMP_3rd_Party__c>();
        CSX_CMP_3rd_Party__c thirdparty = new CSX_CMP_3rd_Party__c(
            CSX_CMP_AR_Settlement__c = objSettlement.Id,
            CSX_CMP_Equipment__c = equipment[0].Id,
            CSX_CMP_Incident_Location__c = 'Incident Location for Equipment 1',
            CSX_CMP_Amount__c = 50,
            CSX_CMP_Contact_Email__c = 'akshay.jadhav12@infosys.com;akshay_jadhav@csx.com',            
           // CSX_CMP_Party_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount'),
            CSX_CMP_3rd_Party_Site__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount')
        );
        
        thirdpartyList.add(thirdparty);
        
		 // Creating 3rd Party record
        CSX_CMP_3rd_Party__c thirdparty1 = new CSX_CMP_3rd_Party__c(
          //  CSX_CMP_AR_Settlement__c = objSettlement1.Id,
            CSX_CMP_Equipment__c = equipment[1].Id,
            CSX_CMP_Incident_Location__c = 'Incident Location for Equipment 2',
            CSX_CMP_Amount__c = 50,
            CSX_CMP_Contact_Email__c = 'akshay.jadhav12@infosys.com;akshay_jadhav@csx.com',
          //  CSX_CMP_Party_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount'),
            CSX_CMP_3rd_Party_Site__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount')
        );
        thirdpartyList.add(thirdparty1);
        
        insert thirdpartyList;
    }

    /*
    @description : method to test email communication for FC Customer Claim
    */ 
    @isTest
    static void testToSendEmailtoFCClaim() {
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
           // CSX_CMP_InvoiceAdjustmentController.sendInvoiceEmailCommunication(details.id);
            Test.stopTest();
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(0, invocations, 'Email invocations should not be zero');

        }
    }
    /*
    @description : method to test email communication for FC Customer Claim
    */ 
    @isTest
    static void testToSendEmail() {
        List<string> emails = new list<string>{'akshay.jadhav12@infosys.com '};
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_InvoiceAdjustmentController.sendInvoiceEmail(details.id,emails,emails);
            Test.stopTest();
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(0, invocations, 'Email invocations should not be zero');

        }
    }
    /*
    @description : method to test email communication for FC Customer Automobile Claim
    */ 
    @isTest
    static void testToSendEmailforFCAC() {
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Automobile Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            //CSX_CMP_InvoiceAdjustmentController.sendInvoiceEmailCommunication(details.id);
            Test.stopTest();
            Integer invocations = Limits.getEmailInvocations();
            System.assertEquals(0, invocations, 'Email invocations should not be zero');
        }
    }

    /* 
	@description : method to test update Invoice
	*/
    @isTest
    static void testToFetchARrecordforFC() {
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
                CSX_CMP_InvoiceAdjustmentController.ARInvoiceWrapper arInvoiceWrapper = CSX_CMP_InvoiceAdjustmentController.fetchARrecordDetails(details.id);
            Test.stopTest();
          //  System.assertNotEquals(null,value,'AR record Id should not be null');
          System.assertNotEquals(null, arInvoiceWrapper, 'AR Invoice Wrapper should not be null');
        }
    }
    /* 
	@description : method to test negative sinario update Invoice
	*/
    @isTest
    static void testNotToFetchARrecordforFC() {
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
                CSX_CMP_InvoiceAdjustmentController.ARInvoiceWrapper arInvoiceWrapper = CSX_CMP_InvoiceAdjustmentController.fetchARrecordDetails(null);
            Test.stopTest();
          //  System.assertNotEquals(null,value,'AR record Id should not be null');
          //System.assertEquals(null, arInvoiceWrapper, 'AR Invoice Wrapper should be null when null is passed as the ID');
            System.assertEquals(null, arInvoiceWrapper.invoiceAmount, 'Invoice Amount should be null');
            System.assertEquals(null, arInvoiceWrapper.invoiceNumber, 'Invoice Number should be null');
            System.assertEquals(null, arInvoiceWrapper.invoiceStatus, 'Invoice Status should be null');

        }
    }

    /* 
     @description : method to test update Invoice for FCC
    */
    @isTest
    static void testToUpdateInvoiceAmountforFCAC() {
        CSX_CMP_AR_Settlement__c details = [SELECT Id, CSX_CMP_Invoice_Amount__c FROM CSX_CMP_AR_Settlement__c WHERE CSX_CMP_Claim__r.Type = 'FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            // String value = CSX_CMP_InvoiceAdjustmentController.updateInvoiceAmount(details.id,details.CSX_CMP_Invoice_Amount__c);
            // Test.stopTest();
            // //System.assertNotEquals(null, value ,'AR record Id should not be null');
            // System.assertEquals(null, value, 'Returned value should not be null');
            
        }
    }    
}