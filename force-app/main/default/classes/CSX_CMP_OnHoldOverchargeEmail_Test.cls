/*
@Author       - Infosys
@Name         - CSX_CMP_OnHoldOverchargeEmail_Test
@Created Date - 5/18/2024
@Description  - This test class tests the getClaimDetails method to ensure it correctly retrieves and wraps claim details.
@RICEFW reference - 
*/
@isTest
    public class CSX_CMP_OnHoldOverchargeEmail_Test {
    @testSetup
    public static void setupdata(){
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueOverchargeClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null); 
		
        Case claim = [SELECT Id, Status,CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId LIMIT 1];       
        claim.Status = 'On Hold';
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
        update claim;
		
        CSX_CMP_Claim_Contact__c cc = new CSX_CMP_Claim_Contact__c();
        cc.CSX_CMP_Emails__c = 'nilesh.soni02@infosys.com';
        cc.CSX_CMP_Claim__c = response.claimId;
        insert cc;
        
    }
        
    //This method validates the retrieval and processing of ‘On Hold’ overcharge claims by the controller.
    @isTest
    static void testGetClaimDetails(){
        case claim = [SELECT Id from case WHERE CSX_CMP_Claim_Amount__c = 600];   
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            
            CSX_CMP_OnHoldOverchargeEmailController controller = new CSX_CMP_OnHoldOverchargeEmailController();
            controller.caseId = claim.Id;
            // Retrieves the list of claim wrappers after setting the case ID.
            List <CSX_CMP_OnHoldOverchargeEmailController.CSX_CMP_claimWrapper> claimWrapper = controller.claimWrapperList;
            Test.stopTest();
            
            // Asserts that the claimWrapperList is not empty after the test execution.
            System.assertNotEquals(0, controller.claimWrapperList.size(), 'The claimWrapperList should not be empty');
	    }
	}
}