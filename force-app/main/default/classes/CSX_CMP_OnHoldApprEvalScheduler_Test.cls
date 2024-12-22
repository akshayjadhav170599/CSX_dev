@isTest
public class CSX_CMP_OnHoldApprEvalScheduler_Test {
	@testSetup
	public static void setupdata() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		Map<String, CSX_CMP_External_Interface_Endpoint__c> listAll = CSX_CMP_External_Interface_Endpoint__c.getAll();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newRevenueContractClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		Map<String, String> request1 = CSX_CMP_TestUtility.newRevenueOverchargeClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response1 = CSX_CMP_ClaimCreationController.createNewClaim(
			request1,
			null
		);

		List<Case> claims = [
			SELECT Id, Type, CSX_CMP_System_Action_Toggle__c, RecordType.developerName
			FROM Case
			WHERE Id IN :new List<Id>{ response.claimId, response1.claimId }
		];
		for (Case claim : claims) {
			claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
			if (claim.RecordType.developerName == 'Revenue_Overcharge') {
				claim.CSX_CMP_Customer__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount');
				claim.Type = 'Incentive Claim';
			} else {
				claim.CSX_CMP_Customer__r = new Account(CSX_CMP_External_ID__c = 'KansasCitySouthernRailwayCompany');
			}
			claim.Status = 'On Hold';
		}

		update claims;
		// case claim = new case();
		// claim.Id = response.claimId;
		// claim.Type = 'Incentive Claim';
		// claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		// claim.CSX_CMP_Customer__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount');
		// update claim;

		// case claim1 = new case();
		// claim1.Id = response1.claimId;
		// claim1.Status = 'On Hold';
		// claim1.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		// claim1.CSX_CMP_Customer__r = new Account(CSX_CMP_External_ID__c = 'KansasCitySouthernRailwayCompany');
		// update claim1;
	}

	@isTest
	public static void apprEval() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
			Test.startTest();
			// Schedule the batch job
			String cronExp = '0 0 0 15 3 ?';
			String jobName = 'ScheduledTestJob';
			CSX_CMP_OnHoldApprEvalScheduler schedule = new CSX_CMP_OnHoldApprEvalScheduler();
			System.schedule(jobName, cronExp, schedule);
			Test.stopTest();
		}
	}
}