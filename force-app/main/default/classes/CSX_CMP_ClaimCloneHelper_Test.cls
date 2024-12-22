/**************************************************************************************
/*
@author: Infosys
Apex Class Name     : CSX_CMP_ClaimCloneHelper_Test
@description        : This class is used to test the CSX_CMP_ClaimCloneHelper class
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys            15/03/2024        First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_ClaimCloneHelper_Test {
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		CSX_CMP_Creation_Request__c stagingRecord = [
			SELECT Id, CSX_CMP_Request_Payload__c
			FROM CSX_CMP_Creation_Request__c
			WHERE CSX_CMP_Claim__c = :response.claimId
		];

		CSX_CMP_PostClaimCreationHelper.linkRelatedInspections(stagingRecord);
	}
	/**
	@description : Testing the clone claim functionality of cloning Equipment, Product, Customer Damages and Inspection damage records
	 */
	@isTest
	static void test1() {
		CSX_CMP_RechargeClaimCreation_Test.testRechargeClaimMethod();

		List<Case> newClaims = [SELECT Id FROM Case WHERE Type = 'Recharges Outbound Claim'];
		System.assertEquals(1, newClaims.size(), 'Number of claims created should be 1');
	}
}