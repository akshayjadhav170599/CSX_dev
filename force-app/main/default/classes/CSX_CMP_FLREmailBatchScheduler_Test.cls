@isTest
public class CSX_CMP_FLREmailBatchScheduler_Test {

    @testSetup
    public static void setupData(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);   
    }

    // @description : 
    @isTest
    public static void testSchedule() {
        CSX_CMP_Last_Execution_Log__c lastExecutionLog = new CSX_CMP_Last_Execution_Log__c(
            Name = 'CMP-E-0425_FLR_Email_Batch',
            CSX_CMP_Execution_Time__c = system.now()
        );
        insert lastExecutionLog ;
              
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
          Test.startTest();
            CSX_CMP_FLREmailBatchScheduler testsche = new CSX_CMP_FLREmailBatchScheduler();
            system.schedule('Schedule Batch','0 0 0 15 3 ?',testsche);
          Test.stopTest(); 
          System.assertEquals(1, [SELECT count() FROM AsyncApexJob WHERE JobType = 'ScheduledApex'], 'Job scheduled');
        }
    }   
}