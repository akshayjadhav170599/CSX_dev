/**************************************************************************************
RICEF ID : CMP-E-0416
@author : Infosys
@description : This class is used to test the methods in CSX_CMP_PostClaimCreationQueueable class.
*************************************************************************************/

@isTest
public class CSX_CMP_PostClaimCreationQueueable_Test {
    
    @TestSetup
    static void makeData(){
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
        
        CSX_CMP_Creation_Request__c stagingRecord = new CSX_CMP_Creation_Request__c();
        stagingRecord.CSX_CMP_Source__c = 'EDI';
        stagingRecord.CSX_CMP_Claim__c = response.claimId;
        insert stagingRecord;
    }
    
    /* @Description : method to test post claim creation for staging record */
    
    @isTest
    static void postClaimCreateTestForStagingRecord(){
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1/claims/create';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(requestJSON);
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_ClaimCreateWebService.claimCreateService();
            Test.stopTest();
            CSX_CMP_Creation_Request__c request = [SELECT Id,CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
            System.assertNotEquals(null, request.CSX_CMP_Claim__c, 'The claim creation service should return a 201 Created status code.');
        }
    } 
    
    /* @Description : method to test post claim creation actions */
    
    @isTest
    static void testPostClaimCreationActions() {
        CSX_CMP_Creation_Request__c stagingRecord = [SELECT Id FROM CSX_CMP_Creation_Request__c LIMIT 1];
        Test.startTest();
        CSX_CMP_PostClaimCreationQueueable queueable = new CSX_CMP_PostClaimCreationQueueable('PostClaimCreationActions', stagingRecord);
        System.enqueueJob(queueable);
        Test.stopTest();
        stagingRecord = [SELECT Id,CSX_CMP_Queueable_One_Execution_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
       System.assertEquals('In Progress', stagingRecord.CSX_CMP_Queueable_One_Execution_Status__c,' Queueable Status should be In Progress');
        
    }
    
    /* @Description : method to test invoke business rules */
    
    @isTest
    static void testInvokeBusinessRule() {
        CSX_CMP_Creation_Request__c stagingRecord = [SELECT Id FROM CSX_CMP_Creation_Request__c LIMIT 1];
        Test.startTest();
        CSX_CMP_PostClaimCreationQueueable queueable = new CSX_CMP_PostClaimCreationQueueable('InvokeBusinessRule', stagingRecord);
        System.enqueueJob(queueable);
        Test.stopTest();
        stagingRecord = [SELECT Id,CSX_CMP_Autopay_Decline_Execution_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        System.assertEquals('Completed', stagingRecord.CSX_CMP_Autopay_Decline_Execution_Status__c,' Queueable Status should be Completed');
        
    }
    
    /* @Description : method to test submit claim for approval for intermodal */
    
    @isTest
    static void testSubmitClaimforApprovalForIntermodal() {
        
        CSX_CMP_Creation_Request__c stagingRecord = [SELECT Id FROM CSX_CMP_Creation_Request__c LIMIT 1];
        Test.startTest();
        CSX_CMP_PostClaimCreationQueueable queueable = new CSX_CMP_PostClaimCreationQueueable('SubmitClaimforApprovalForIntermodal', stagingRecord);
        System.enqueueJob(queueable);
        Test.stopTest();
        stagingRecord = [SELECT Id,CSX_CMP_Queueable_One_Execution_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        System.assertEquals('In Progress', stagingRecord.CSX_CMP_Queueable_One_Execution_Status__c,' Queueable Status should be In Progress');
        
    }
    
    /* @Description : method to test umler request for staging record */
    
    @isTest
    static void testUMLER() {
        
        CSX_CMP_Creation_Request__c stagingRecord = [SELECT Id,CSX_CMP_Umler_Fetch_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        Test.startTest();
        CSX_CMP_PostClaimCreationQueueable queueable = new CSX_CMP_PostClaimCreationQueueable('UMLER', stagingRecord);
        System.enqueueJob(queueable);
        Test.stopTest();
        stagingRecord = [SELECT Id,CSX_CMP_Umler_Fetch_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        System.assertEquals('Pending', stagingRecord.CSX_CMP_Umler_Fetch_Status__c,' Umler Fetch Status should be Completed');
        
    }
    
}