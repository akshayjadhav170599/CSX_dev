@isTest
public class CSX_CMP_OnHoldClaimReminderEmail_Test {
    
    @testSetup
    public static void setupData(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);   
        
        CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Do not send On-Hold reminder';
        note.CSX_CMP_Claim__c = response.claimId;
        insert note;
        
        CSX_CMP_Claim_Contact__c test = new CSX_CMP_Claim_Contact__c();      
        test.CSX_CMP_Claim__c=response.claimId;
        test.CSX_CMP_Emails__c='abc@gmail.com';
        test.CSX_CMP_Telephone__c ='223223';
        test.CSX_CMP_Person__c = 'Nilesh';
        insert test;
    }
    
    @isTest
    static void generalTestMethod(){
        
        CSX_CMP_Last_Execution_Log__c lastExecutionLog = new CSX_CMP_Last_Execution_Log__c();
        lastExecutionLog.Name = 'CMP-I-0439_Send_onhold_email';
        lastExecutionLog.CSX_CMP_Execution_Time__c = system.now();
        insert lastExecutionLog;
        
        List<Case> claimCase = [SELECT Id,CSX_CMP_Claim_Reason__c,status FROM Case WHERE CSX_CMP_Claim_Amount__c = 230];
        Map<String,List<Case>> nationalAccMap  = new Map<String,List<Case>>();
        nationalAccMap.put('23456', claimCase);
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
          Test.startTest();
            CSX_CMP_OnHoldClaimReminderEmailBatch batch = new CSX_CMP_OnHoldClaimReminderEmailBatch();
            Database.executeBatch(batch);
          Test.stopTest();
        }
    }
}