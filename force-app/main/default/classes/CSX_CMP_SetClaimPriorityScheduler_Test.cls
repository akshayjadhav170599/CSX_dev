@isTest
public class CSX_CMP_SetClaimPriorityScheduler_Test {
	@testSetup
	public static void setupData() {
		// Calling MasterDataLoader to load the data
		CSX_CMP_TestMasterDataUtility.createMasterData();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		requestJSON.put('claimAmount', '60000');
		requestJSON.put('claimType', 'FC Customer Automobile Claim');
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);
		Case claim = [
			SELECT Id, Priority, CSX_CMP_System_Action_Toggle__c, Status, Type
			FROM Case
			WHERE Id = :response.claimId
		];
		claim.Status = 'Open';
		claim.Priority = 'Medium';
		claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;		
		update claim;

		// Case claimUpdated = [SELECT id, status, type, CSX_CMP_Claim_Amount__c FROM case WHERE Id = :response.claimId];
		

		List<CSX_CMP_Business_Rule__c> bsr = [
			SELECT
				Id,
				Name,
				(SELECT id, Name, CSX_CMP_Attribute_Name__c, CSX_CMP_Value__c FROM Business_Rule_Conditions__r LIMIT 50)
			FROM CSX_CMP_Business_Rule__c
			WHERE CSX_CMP_Rule_Name__c = 'FC Auto Priority - High'
			LIMIT 10
		];
		
	/*	List<CSX_CMP_Business_Rule_Condition__c> bsrRules = [
			SELECT id, name, CSX_CMP_Attribute_Name__c, CSX_CMP_Value__c
			FROM CSX_CMP_Business_Rule_Condition__c
			WHERE CSX_CMP_Business_Rule__c = :bsr[0].Id
		];*/

		
	}

	// @description :
	@isTest
	public static void testSchedule() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			CSX_CMP_SetClaimPriorityBatchScheduler testsche = new CSX_CMP_SetClaimPriorityBatchScheduler();
			system.schedule('Schedule Batch', '0 0 0 15 3 ?', testsche);
			Test.stopTest();
			System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'ScheduledApex'], 'Job scheduled');
		}
	}
}