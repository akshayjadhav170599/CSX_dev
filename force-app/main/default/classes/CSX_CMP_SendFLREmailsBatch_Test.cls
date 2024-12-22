/**
@Author       - Infosys
@Name         - CSX_CMP_SendFLREmailsBatch_Test
@Created Date - 05/19/2024  
@Description  - This batch Apex is used to send the FLR emails to the Rail Road
@RICEFW reference - CMP-E-0422
*/

@isTest
public class CSX_CMP_SendFLREmailsBatch_Test {
	@testSetup
	public static void setupdata() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

		CSX_CMP_Desk__c desk = new CSX_CMP_Desk__c();
		desk.Name = 'Desk 16';
		insert desk;

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();

		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		Case claim = [
			SELECT Id, CSX_CMP_Claim_Amount__c, Type, Status, CSX_CMP_Supplier_Claimant__c
			FROM Case
			WHERE Id = :response.claimId
		];
		claim.Type = 'FC Customer Claim';
		claim.CSX_CMP_Claim_Amount__c = 1700;
		update claim;
	}

	@isTest
	static void testgetClaimDetails() {
		Set<Id> claimIds = new Set<Id>();
		Case claim = [SELECT Id, CSX_CMP_Claim_Amount__c, Type, Status, CSX_CMP_Supplier_Claimant__c FROM Case];
		claimIds.add(claim.id);
		
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			String objName = 'Case';
			Map<String, Schema.SObjectField> objectFields = new Map<String, Schema.SObjectField>();

			//Map to get all fields

			objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
            for(String fieldName : objectFields.keySet()){
                if (objectFields.keySet().contains(fieldName) && objectFields.get(fieldName).getDescribe().isAccessible()) {
                    // Field is Accessible
                } else {
                    // Field is not Accessible
                }
            }

			objName = 'Account';
			
			objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
			for (String fieldName : objectFields.keySet()) {
				if (objectFields.keySet().contains(fieldName) && objectFields.get(fieldName).getDescribe().isAccessible()) {
					// Field is Accessible
				} else {
					// Field is not Accessible
				}
			}

			objName = 'CSX_CMP_Equipment__c';
			
			objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
			for(String fieldName : objectFields.keySet()){
				if (objectFields.keySet().contains(fieldName) && objectFields.get(fieldName).getDescribe().isAccessible()) {
					// Field is Accessible
				} else {
					// Field is not Accessible
				}
			}

			objName = 'CSX_CMP_LD_Report__c';
			
			objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
			for(String fieldName : objectFields.keySet()){
				if (objectFields.keySet().contains(fieldName) && objectFields.get(fieldName).getDescribe().isAccessible()) {
					// Field is Accessible
				} else {
					// Field is not Accessible
				}
			} 

			Test.startTest();
			CSX_CMP_SendFLREmailsBatch testBatch = new CSX_CMP_SendFLREmailsBatch();
			database.executebatch(testBatch, 10);
			Map<Id, CSX_CMP_BusinessRulesUtility.ClaimWrapper> claimDetails = CSX_CMP_BusinessRulesUtility.gatherFullClaimDetails(
				claimIds
			);
			Test.stopTest();
            
             // Assertions to verify the batch executed correctly
            System.assertNotEquals(null, claimDetails, 'Expected claimDetails to be not null');
            System.assertEquals(1, claimDetails.size(), 'Expected one claim detail to be gathered');
            System.assert(claimDetails.containsKey(claim.Id), 'Expected claimDetails to contain the claim ID');
            System.assertEquals(1700, claimDetails.get(claim.Id).claimAmount, 'Expected claim amount to be 1700');
		}

	}
}