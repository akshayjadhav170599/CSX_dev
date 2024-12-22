/*
@Author       - Infosys
@Name         - CSX_CMP_DeclineLetterController_Test
@Created Date - 5/18/2024
@Description  - This test class covers the CSX_CMP_DeclineLetterController class.
@RICEFW reference - CMP-E-0458 and CMP-E-0493
*/
@isTest
public class CSX_CMP_DeclineLetterController_Test {
    // This method sets up the test data for the test methods in this class.
	@TestSetup
    static void setupdata(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
        
		CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Adhoc Decline Reason';
        note.CSX_CMP_Claim__c = response.claimId;
        insert note;
    }
    
    /*The testGetClaimDetails test method validates the CSX_CMP_DeclineLetterController’s ability to 
      retrieve and wrap claim details, ensuring the claim amount and wrapper are correctly populated and not null*/
    @isTest
    public static void testGetClaimDetails(){        
        // Retrieve a specific user from the database.
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
                CSX_CMP_DeclineLetterController controller = new CSX_CMP_DeclineLetterController();
                String claim = [SELECT Id FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1].Id;
                controller.caseId = claim;
                CSX_CMP_DeclineLetterController.CSX_CMP_claimWrapper claimWrapper = controller.claimWrapper;
            Test.stopTest();
            
            // Assert that the claim amount is as expected.
            System.assertEquals(230, claimWrapper.claimAmount,'claim amount should not be null');
            
            // Assert that the claim wrapper is not null.
            System.assertNotEquals(null, claimWrapper,'claimwrapper should not be null');
        }  
    }
}