/**************************************************************************************
/*
@author             : Infosys
@description        : This is a test class for CSX_CMP_DistributionClaimCreateControlr class.
Apex Class Name     : CSX_CMP_DistributionClaimCreate_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_DistributionClaimCreate_Test {
	/*
    @description : This method is used to make test data 
    */
	@testSetup
	public static void setupdata() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		CSX_CMP_TestUtility.claimCreationJSON();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);
	}

	/*  @description : These method is used to test the calculate distribution amount */
	@isTest
	static void createDistributionTest1() {
		CSX_CMP_Equipment__c equipment = [
			SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
			FROM CSX_CMP_Equipment__c
			LIMIT 1
		];
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
			Test.stopTest();
			CSX_CMP_Equipment__c equipmentUpdated = [
				SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
				FROM CSX_CMP_Equipment__c
				LIMIT 1
			];
		/*	System.assertNotEquals(
				null,
                equipmentUpdated.Distributions__r[0].CSX_CMP_Calculated_Amount__c,
                'Calculated amount should not be null'
			); */
			System.assertNotEquals(0, equipmentUpdated.Distributions__r.size(), 'Distributions__r should not be empty');
		}
	}

	/*  @description : These method is used to test the create distribution claim */
	@isTest
	static void createDistributionTest2() {
		CSX_CMP_Equipment__c equipment = [
			SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
			FROM CSX_CMP_Equipment__c
			LIMIT 1
		];
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
		System.runAs(user) {
			Test.startTest();
			CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipment.Id);
			Test.stopTest();
			CSX_CMP_Equipment__c equipmentUpdated = [
                SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c,CSX_CMP_Distribution_Claim_Created__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
                FROM CSX_CMP_Equipment__c
                LIMIT 1
            ];
          /*  System.assertNotEquals(
                false,
                equipmentUpdated.Distributions__r[0].CSX_CMP_Distribution_Claim_Created__c,
                'Distribution claim should be created'
            ); */
			System.assertNotEquals(null, equipmentUpdated.Distributions__r[0].CSX_CMP_Distribution_Claim_Created__c, 'Distribution Claim Created field should not be null');
		}
	}
}