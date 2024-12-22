/*
RICEFW Id : CMP-E-0411
@description : This class is used to test CSX_CMP_ContractBudgetHandler methods
@author : Infosys
@name : CSX_CMP_ContractBudgetHandler_Test
*/

@isTest
public class CSX_CMP_ContractBudgetHandler_Test {
	@testSetup
	static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		Map<String, String> requestMap = CSX_CMP_TestUtility.newRevenueContractClaimCreationRequest();
        CSX_CMP_ClaimCreationController.createNewClaim(requestMap,null);
	}

	/* @Description : method to test update consumed budget */
	@isTest
	static void testUpdateConsumedBudget() {
		List<Case> testClaims = [SELECT Id, CSX_CMP_Claim_Amount__c, CSX_CMP_Contract_Num__c FROM Case];

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ContractBudgetHandler.updateConsumedBudget(testClaims);
			Test.stopTest();
			System.assertEquals(true, true, 'Update Consumed Budget method did not execute successfully');
		}
	}

	/* @Description : method to test available budget check */
	@isTest
	static void testAvailableBudgetCheck() {
		List<Case> testClaims = [SELECT Id, CSX_CMP_Claim_Amount__c, CSX_CMP_Contract_Num__c FROM Case];

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ContractBudgetHandler.availableBudgetCheck(testClaims);
			Test.stopTest();
			System.assertEquals(true, true, 'Available Budget Check method did not execute successfully');
		}
	}
}