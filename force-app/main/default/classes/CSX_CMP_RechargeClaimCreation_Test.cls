/*
@Author       - Infosys
@Name         - CSX_CMP_RechargeClaimCreation_Test
@Created Date - 5/18/2024
@Description  - This is a test class for CSX_CMP_RechargeClaimCreationController
*/
@isTest
public class CSX_CMP_RechargeClaimCreation_Test {
	@TestSetup
	public static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

		// Creates a new freight claim creation request
		Map<String, String> request = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.createNewClaim(
			request,
			null
		);

	}

	/* This is a test method that tests the 'createRechargeClaim' method
	 of the 'CSX_CMP_RechargeClaimCreationController' class */
	@isTest
	public static void testRechargeClaimMethod() {
		String sourceId = [SELECT Id FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1].Id;
		String data = '{"comment":"Test"}';

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			CSX_CMP_RechargeClaimCreationController.createRechargeClaim(sourceId, data);
			Test.stopTest();
			List<Case> newClaims = [SELECT Id FROM Case WHERE Type = 'Recharges Outbound Claim'];
			System.assertEquals(1, newClaims.size(), 'expected number of claims created');
		}
	}

	/* This is a test method that tests the 'checkExistingRechargeClaims' method
	 of the 'CSX_CMP_RechargeClaimCreationController' class */
	@isTest
	static void testExistingClaimsMethod() {
		String sourceId = [SELECT Id FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1].Id;
		List<String> sourceIdList = new List<String>{ sourceId };

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			Map<String, String> resultMap = CSX_CMP_RechargeClaimCreationController.checkExistingRechargeClaims(sourceIdList);
			Test.stopTest();
			System.assertEquals(
				null,
				resultMap.get(sourceIdList[0]),
				'Unexpected value for createNewClaim with existing related recharge claim'
			);
		}
	}
}