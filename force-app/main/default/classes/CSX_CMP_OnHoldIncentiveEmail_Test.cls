/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldIncentiveEmail_Test
@Created Date - 05/17/2024
@Description  - This test class covers the CSX_CMP_OnHoldIncentiveEmailController class
@RICEFW reference - CMP-E-0439       
**/
@isTest
public class CSX_CMP_OnHoldIncentiveEmail_Test {
    
    @testSetup
    public static void setupdata(){
        
        // Creates master data required for the tests.
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Creates a new freight claim for testing purposes.
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
  		CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
    }
    
    // testGetClaimDetails method tests the retrieval and display of claim details in the OnHoldIncentiveEmail controller.
    @isTest
    static void testGetClaimDetails() {
        case claim = [SELECT Id,CaseNumber,CSX_CMP_Claim_Amount__c from case LIMIT 1];   
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        // Initializes a wrapper object for the claim details.
        CSX_CMP_OnHoldIncentiveEmailController.CSX_CMP_claimWrapper claimWrapper = new CSX_CMP_OnHoldIncentiveEmailController.CSX_CMP_claimWrapper();

        System.runAs(user) {
            Test.startTest();
            	// Initializes the controller with the test claim id and retrieves claim details
                CSX_CMP_OnHoldIncentiveEmailController controller = new CSX_CMP_OnHoldIncentiveEmailController();
                controller.caseId = claim.Id;
                claimWrapper = controller.claimWrapper;
            Test.stopTest();
            
            // Initializes the controller with the test claim id and retrieves claim details
            System.assertEquals(claim.CaseNumber, claimWrapper.claimNumber, 'Claim numbers do not match between the claim record and the wrapper.');
            
            // Asserts that the claim amount matches between the claim record and wrapper object
            System.assertEquals(claim.CSX_CMP_Claim_Amount__c, claimWrapper.claimAmount, 'Claim amounts do not match between the claim record and the wrapper.');
            
        }
    }
}