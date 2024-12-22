/**************************************************************************************
/*
@author             : Infosys
@description        : Test class for CSX_CMP_DistributionPDFController

Apex Class Name     : CSX_CMP_DistributionPDFController_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/

@isTest
public class CSX_CMP_DistributionPDFController_Test {
	/*@description : This method is used to make test data */
	@testSetup
	public static void setupdata() {
		// Calling MasterDataLoader to load the data
		CSX_CMP_TestMasterDataUtility.createMasterData();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		// Inserting AP Settlement record
		CSX_CMP_AP_Settlement__c apRecord = CSX_CMP_TestUtility.generateAPSettlement();
		apRecord.CSX_CMP_Claim__c = response.claimId;
		insert apRecord;

		CSX_CMP_Equipment__c equipment = [
			SELECT Id
			FROM CSX_CMP_Equipment__c
			WHERE CSX_CMP_Claim__c = :response.claimId
			LIMIT 1
		];
		CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
		note.CSX_CMP_Note_Type__c = 'Comment';
		note.CSX_CMP_Claim__c = response.claimId;
		insert note;

		CSX_CMP_Salvage__c salvage = new CSX_CMP_Salvage__c(
			CSX_CMP_Salvage_Amount__c = 132.86,
			CSX_CMP_Parent_Equipment__c = equipment.Id,
			CSX_CMP_Salvage_Claim__c = response.claimId,
			CSX_CMP_Salvor_Name__c = [SELECT Id FROM Account WHERE Name = 'SAIL Account' LIMIT 1]
			.Id
		);
		insert salvage;

		CSX_CMP_Property_Portal_Staging__c propertyPortal = new CSX_CMP_Property_Portal_Staging__c(
			CSX_CMP_Claim_Number__c = response.claimNum
		);
		insert propertyPortal;
	}

	/* @description : These method is used to test the distribution pdf */
	@isTest
	public static void testGetClaimDetails() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		CSX_CMP_Property_Portal_Staging__c propertyPortal = [SELECT Id FROM CSX_CMP_Property_Portal_Staging__c LIMIT 1];
		System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
			Test.startTest();
			CSX_CMP_DistributionPDFController controller = new CSX_CMP_DistributionPDFController();
			controller.strPropertyPortalId = propertyPortal.Id;
			Test.stopTest();
			System.assertNotEquals(null, controller.strPropertyPortalId, 'Property portal ID should not be null.');
		}

	}
}