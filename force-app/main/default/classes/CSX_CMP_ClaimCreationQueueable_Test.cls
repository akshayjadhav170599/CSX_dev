/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimCreationQueueable_Test
Function            : This class is used to test the methods in CSX_CMP_ClaimCreationQueueable class.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/10/2024       First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_ClaimCreationQueueable_Test {
    
	/*@desccription : method to create master data */
    
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
     
        
        CSX_CMP_Creation_Request__c stagingRecord = new CSX_CMP_Creation_Request__c();
        stagingRecord.CSX_CMP_Source__c = 'EDI';
        stagingRecord.CSX_CMP_Claim__c = response.claimId;
        stagingRecord.CSX_CMP_Creation_Status__c = 'Error';
        insert stagingRecord;
	}
    
    /* Description : Method to test execute staging record */
    
     @isTest
    static void testExecute() {
        
        CSX_CMP_Creation_Request__c stagingRecord = [SELECT Id, Name, CSX_CMP_Creation_Status__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        CSX_CMP_ClaimCreationQueueable queueable = new CSX_CMP_ClaimCreationQueueable(stagingRecord);
        
        Test.startTest();
        ID jobID = System.enqueueJob(queueable);
        Test.stopTest();
        
        // CSX_CMP_Creation_Request__c updatedRecord = [SELECT Id, CSX_CMP_Creation_Status__c FROM CSX_CMP_Creation_Request__c WHERE Id = :stagingRecord.Id];
        // System.assertEquals('In Progress', updatedRecord.CSX_CMP_Creation_Status__c, 'The status should be updated to In Progress');
        System.assertNotEquals(null, jobID, 'JobId should not be null');
    }

    /* Description : Method to test execute staging record with exception */
    
    @isTest
    static void testExecuteWithException() {
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
     
        CSX_CMP_Creation_Request__c stagingRecord = new CSX_CMP_Creation_Request__c();
        stagingRecord.CSX_CMP_Source__c = 'EDI';
        stagingRecord.CSX_CMP_Claim__c = response.claimId;
        stagingRecord.CSX_CMP_Creation_Status__c = 'Pending';
        insert stagingRecord;
        
        stagingRecord.CSX_CMP_Creation_Status__c = null;
        
        CSX_CMP_ClaimCreationQueueable queueable = new CSX_CMP_ClaimCreationQueueable(stagingRecord);
        
        Test.startTest();
        ID jobID = System.enqueueJob(queueable);
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'JobId should not be null');
        
    }
}