/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldToReopen_Test
@Created Date - 5/24/2024
@Description  - This test class is used tocover CSX_CMP_OnHoldToReopenController class.
@RICEFW reference - CMP-E-0439
*/
@isTest
public class CSX_CMP_OnHoldToReopen_Test {
     @testSetup
    public static void setupdata(){

    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Claim Creation Revenue Railroad
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueContractClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
        
        CSX_CMP_Claim_Line__c claimline = new CSX_CMP_Claim_Line__c();
        claimline.CSX_CMP_Claim_Amount__c = 10000;
        claimline.CSX_CMP_Balance_Due__c = 0;
        claimline.CSX_CMP_Claim__c = response.claimId;
        insert claimline;
    }
	
    //Test method for the getclaimDetails() method in the CSX_CMP_OnHoldToReopenController class
    @isTest
    static void testGetClaimDetails() {
        //Fetches a Case (Claim) record and a User record from the database
        Case claim = [SELECT Id, CaseNumber, OwnerId,(Select Id from ClaimLines__r) from Case LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        //Creates an instance of the CSX_CMP_claimWrapper inner class
        CSX_CMP_OnHoldToReopenController.CSX_CMP_claimWrapper wrapper =new CSX_CMP_OnHoldToReopenController.CSX_CMP_claimWrapper();
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_OnHoldToReopenController controller = new CSX_CMP_OnHoldToReopenController();
            controller.caseId = claim.Id;
            wrapper = controller.claimWrapper;
            Test.stopTest();
            
            //assert
            System.assertEquals(claim.CaseNumber, wrapper.claimNumber,'Claim Number should be same');
        }
    }
}