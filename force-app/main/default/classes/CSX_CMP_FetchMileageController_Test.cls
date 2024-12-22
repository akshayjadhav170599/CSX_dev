/**
@Author       - Infosys
@Name         - CSX_CMP_FetchMileageController_Test
@Created Date - 5/07/2024
@Description  - These class is used to test fetch mileage data.
@RICEFW reference - CMP-E-0430
*/

@isTest
public class CSX_CMP_FetchMileageController_Test {
	//method to create test data
	@TestSetup
	public static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

		// Creating new Revenue RailRoad Claim
		Map<String, String> revenuecase = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			revenuecase,
			null
		);
		CSX_CMP_Claim_Line__c claimline = [SELECT Id FROM CSX_CMP_Claim_Line__c WHERE CSX_CMP_Claim__c = :response.claimId];

		// Creating new Mileage Record
		CSX_CMP_Mileage__c testMileage = new CSX_CMP_Mileage__c();
		testMileage.CSX_CMP_Miles__c = 200;
		testMileage.CSX_CMP_Misroute__c = '1234';
		testMileage.CSX_CMP_Return_RR__c = 'CSD';
		testMileage.CSX_CMP_Amount_Miles__c = 20;
		testMileage.CSX_CMP_Claim_Line__c = claimline.Id;
		testMileage.CSX_CMP_Misroute_Location__r = new CSX_CMP_City_State_Master__c(
			CSX_CMP_External_ID__c = 'CLEVELAND988OH'
		);
		testMileage.CSX_CMP_Return_Location__r = new CSX_CMP_City_State_Master__c(
			CSX_CMP_External_ID__c = 'CLEVELAND988OH'
		);
		insert testMileage;
	}

	/* @description : method to check the fetch mileage data */
	@isTest
	static void testFetchMilege() {
		CSX_CMP_Mileage__c updatedMileage = [
			SELECT
				Id,
				CSX_CMP_Miles__c,
				CSX_CMP_Misroute__c,
				CSX_CMP_Return_RR__c,
				CSX_CMP_Misroute_Location__c,
				CSX_CMP_Return_Location__c,
				CSX_CMP_Misroute_Location__r.Name,
				CSX_CMP_Return_Location__r.Name
			FROM CSX_CMP_Mileage__c
			LIMIT 1
		];
		// Freight Claim User or Freight Claim Manager can create
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			CSX_CMP_FetchMileageController.fetchmilege(updatedMileage.Id);
			Test.stopTest();
			CSX_CMP_Mileage__c mileage = [SELECT Id, CSX_CMP_Miles__c FROM CSX_CMP_Mileage__c WHERE Id = :updatedMileage.Id];
			System.assertEquals(200, mileage.CSX_CMP_Miles__c, 'Mileage is being updated from a callout');
		}
	}
}