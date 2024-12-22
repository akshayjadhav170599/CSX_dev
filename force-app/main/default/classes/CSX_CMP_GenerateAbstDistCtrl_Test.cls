@isTest
public class CSX_CMP_GenerateAbstDistCtrl_Test {
	@testSetup
    public static void setupdata(){
        
        // Creates master data required for the tests.
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Creates a new freight claim for testing purposes.
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        
        Case claim = [SELECT Id, CSX_CMP_System_Action_Toggle__c, Status FROM Case WHERE Id = :response.claimId];
		claim.Status = 'Pending Monthly Settlement';
		claim.CSX_CMP_Service_Period__c = 'PER-4-24';
		claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		update claim;
    }
    
    @isTest
    static void testFetchClaimWithFreightRecordType(){
        Case claim = [SELECT Id from Case LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            	List<Case> resultCase = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Freight', 'PER-4-24', 'Class 1', null);
            	List<Case> resultCases = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Revenue_Railroad', 'PER-4-24', 'Non Class 1', null);
            Test.stopTest();
        }
        // Assert expected results
        //System.assertEquals(1, resultCase.size(), 'Expected one Freight case');    
        //System.assertEquals(1, resultCases.size(), 'Expected one Freight case'); 
    }
    
    
}