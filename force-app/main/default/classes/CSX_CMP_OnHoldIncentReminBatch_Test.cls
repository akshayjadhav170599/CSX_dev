/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldIncentiveReminderBatch
@Created Date - 7/2/2024
@Description  - This test class is used to cover the CSX_CMP_OnHoldIncentiveReminderBatch Class
@RICEFW reference - CMP-I-0439
*/
@isTest
private class CSX_CMP_OnHoldIncentReminBatch_Test {
    @TestSetup
    static void makeData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Create a new claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueContractClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Case claim = [SELECT Id, Status, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId];
		claim.Status = 'On Hold';
		claim.Type = 'Incentive Claim';
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		update claim;
    }
    
    @isTest
    static void testOnHoldIncentiveReminderBatch() {
        List<Case> claimList = new List<Case>();
        Case claim = [SELECT Id, Status FROM Case WHERE Type = 'Incentive Claim'];
        
        //Create a claim contact with email
        CSX_CMP_Claim_Contact__c claimContact = new CSX_CMP_Claim_Contact__c(
        CSX_CMP_Claim__c = claim.id,
        CSX_CMP_Emails__c = 'test@example.com'
        );
        insert claimContact;
		claimList.add(claim);
        
        // Run batch job as a specific user
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
            //CSX_CMP_OnHoldIncentiveReminderBatch testBatch = new CSX_CMP_OnHoldIncentiveReminderBatch();
            //Id batchId = database.executebatch(testBatch);
            Id batchJobId = Database.executeBatch(new CSX_CMP_OnHoldIncentiveReminderBatch(), claimList.size());           
        Test.stopTest();
		
        //Assert that at least one email was sent during batch execution
        //Integer expectedEmailCount = 1;
        //Integer actualEmailCount = [SELECT COUNT() FROM EmailMessage WHERE Parent.Type = 'Incentive Claim' AND Parent.Status = 'On Hold'];
        //System.assertNotEquals(1, actualEmailCount, 'Incorrect number of emails sent');
   		}
    }
    /*
    @isTest
    static void testOnHoldOverchargeWithoutEmail() {
        List<Case> claimList = new List<Case>();
        Case claim = [SELECT Id, Status FROM Case WHERE Type = 'Incentive Claim'];
        
        //Create a claim contact without email
        CSX_CMP_Claim_Contact__c claimContact = new CSX_CMP_Claim_Contact__c(
        CSX_CMP_Claim__c = claim.id
        );
        insert claimContact;
		claimList.add(claim);
        
        String cronExpression = '0 0 12 1/1 * ? *'; 
        System.schedule('On-Hold Email Reminder Scheduler', cronExpression, new CSX_CMP_OnHoldEmailReminderScheduler());
       
        // Run batch job as a specific user
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
            //CSX_CMP_OnHoldIncentiveReminderBatch testBatch = new CSX_CMP_OnHoldIncentiveReminderBatch();
            //Id batchId = database.executebatch(testBatch);
            Id batchJobId = Database.executeBatch(new CSX_CMP_OnHoldOverchargeReminderBatch(), claimList.size());           
        Test.stopTest();
        }
    }
    
    @isTest
    static void testOnHoldOverchargeWithNotes() {
        List<Case> claimList = new List<Case>();
        Case claim = [SELECT Id, Status FROM Case WHERE Type = 'Incentive Claim'];
        
        CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Do not send On-Hold reminder';
        note.CSX_CMP_Claim__c = claim.id;
        insert note;
		claimList.add(claim);
        
        // Run batch job as a specific user
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
            //CSX_CMP_OnHoldIncentiveReminderBatch testBatch = new CSX_CMP_OnHoldIncentiveReminderBatch();
            //Id batchId = database.executebatch(testBatch);
            Id batchJobId = Database.executeBatch(new CSX_CMP_OnHoldOverchargeReminderBatch(), claimList.size());           
        Test.stopTest();
        }
    }
    
     @isTest
    static void testOnHoldOverchargeWithClosedStatus() {
        List<Case> claimList = new List<Case>();
        Case claim = [SELECT Id, Status, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Type = 'Incentive Claim'];
        claim.Status = 'Closed';
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		update claim;
		claimList.add(claim);
        
        // Run batch job as a specific user
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
            //CSX_CMP_OnHoldIncentiveReminderBatch testBatch = new CSX_CMP_OnHoldIncentiveReminderBatch();
            //Id batchId = database.executebatch(testBatch);
            Id batchJobId = Database.executeBatch(new CSX_CMP_OnHoldOverchargeReminderBatch(), claimList.size());           
        Test.stopTest();
        }
    }*/
}