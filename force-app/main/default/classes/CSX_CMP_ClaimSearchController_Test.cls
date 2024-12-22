/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimSearchController
Function            : This class is used to test the methods in CSX_CMP_ClaimSearchController class
Author              : Infosys
Modification Log    :
* Developer         : Date             Description  -> working 
* ----------------------------------------------------------------------------                 
* Infosys           5/15/2024      Second version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_ClaimSearchController_Test {
    
	/*@description : method to create master data */
	
    @testSetup
	static void makeTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
        Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;

		//Creating Freight Claim
		Map<String, String> freightRequestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper freightResponse = CSX_CMP_ClaimCreationController.createNewClaim(
			freightRequestJSON,
			null
		);

		//Creating CSX_CMP_AP_Settlement__c and CSX_CMP_AR_Settlement__c
		CSX_CMP_AP_Settlement__c aPSettlement = CSX_CMP_TestUtility.generateAPSettlement();
		aPSettlement.CSX_CMP_Claim__c = freightResponse.claimId;
		insert aPSettlement;

		CSX_CMP_AR_Settlement__c arSettlement = CSX_CMP_TestUtility.generateARSettlement();
		arSettlement.CSX_CMP_Claim__c = freightResponse.claimId;
		insert arSettlement;

		//Creating Notes
		CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
		note.CSX_CMP_Claim__c = freightResponse.claimId;
		note.CSX_CMP_Note_Type__c = 'Work Note';
		note.CSX_CMP_Notes__c = 'comments for testclass';
		insert note;
	}

	/* @description : method to test Get Claim records for Freight claims */
    
	@isTest
	static void testgetClaimRecordsForFreight() {
		Case claim = [
			SELECT
				Id,
				caseNumber,
				RecordType.DeveloperName,
				Type,
				CSX_CMP_Claim_Date__c,
				CSX_CMP_Supplier_Claimant__c,
				CSX_CMP_Desk_Name__c,
				CSX_CMP_Customer__c,
				CSX_CMP_Age__c,
				CSX_CMP_Original_Amount__c,
				CSX_CMP_Service_Period__c,
				CSX_CMP_Claimant_Ref_Num__c,
				Priority,
				CSX_CMP_National_Account_Num__c,
				CSX_CMP_RR_SCAC__c,
				Reason,
				CSX_CMP_Supplier_Claimant_Site__c,
				CSX_CMP_Potential_Duplicate__c,
				CSX_CMP_Unread_Email__c,
				CSX_CMP_VIN__c,
				(SELECT Id, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c FROM Equipments__r LIMIT 1)
			FROM Case
			WHERE RecordType.DeveloperName = 'Freight'
			LIMIT 1
		];

		Map<String, Object> requestParameters = new Map<String, Object>();

		requestParameters.put('claimNumber', claim.caseNumber);
		requestParameters.put('claimType', claim.Type);
		requestParameters.put('claimGroup', 'Freight');
		requestParameters.put('claimAmountFrom', 220);
		requestParameters.put('claimAmountTo', 250);
		requestParameters.put('claimFromDate', claim.CSX_CMP_Claim_Date__c.addDays(-1));
		requestParameters.put('claimToDate', claim.CSX_CMP_Claim_Date__c.addDays(1));
		requestParameters.put('supplierClaimantName', claim.CSX_CMP_Supplier_Claimant__c);
		requestParameters.put('deskName', claim.CSX_CMP_Desk_Name__c);
		requestParameters.put('customerName', claim.CSX_CMP_Customer__c);
		requestParameters.put('ageTo', claim.CSX_CMP_Age__c + 5);
		requestParameters.put('ageFrom', claim.CSX_CMP_Age__c - 5);
		requestParameters.put('claimantAmountFrom', claim.CSX_CMP_Original_Amount__c - 10);
		requestParameters.put('claimantAmountTo', claim.CSX_CMP_Original_Amount__c + 10);
		requestParameters.put('servicePeriod', claim.CSX_CMP_Service_Period__c);
		requestParameters.put('claimantRefererence', claim.CSX_CMP_Claimant_Ref_Num__c);
		requestParameters.put('claimPriority', claim.Priority);
		requestParameters.put('nationalAccNum', claim.CSX_CMP_National_Account_Num__c);
		requestParameters.put('rrSCAC', claim.CSX_CMP_RR_SCAC__c);
		requestParameters.put('claimReason', claim.Reason);
		requestParameters.put('supplierClaimantSite', claim.CSX_CMP_Supplier_Claimant_Site__c);
		requestParameters.put('customerSite', claim.CSX_CMP_Customer__c);		
		requestParameters.put('unreadEmail', claim.CSX_CMP_Unread_Email__c);
		requestParameters.put('equipmentInitial', claim.Equipments__r[0].CSX_CMP_Equipment_Initial__c);
		requestParameters.put('equipmentNumber', claim.Equipments__r[0].CSX_CMP_Equipment_Num__c);
		requestParameters.put('vinNumber', claim.CSX_CMP_VIN__c);
        //requestParameters.put('contractNumber', claim.CSX_CMP_Contract_Num__c);
        //requestParameters.put('claimantReferenceNumber', claim.CSX_CMP_Claimant_Ref_Num__c); 
        requestParameters.put('potentialDuplicate', claim.CSX_CMP_Potential_Duplicate__c);
		String claimSearchParameters = JSON.serialize(requestParameters);

		User user = [
			SELECT Id, profile.Name, Userrole.Name
			FROM User
			WHERE FirstName = 'Freight Claim' AND LastName = 'User'
			LIMIT 1
		];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ClaimSearchController.ClaimSearchResultWrapper result = CSX_CMP_ClaimSearchController.getClaimRecords(
				claimSearchParameters
			);
			Test.stopTest();

			System.assertNotEquals(1, result.results.size(), 'Atleast one claim record found!');
		}
	}

	/* @description : method to test Fetch full claim details */
    
	@isTest
	static void testfetchFullClaimDetails() {
		List<Case> caseList = [
			SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
			FROM Case
			WHERE RecordType.DeveloperName = 'Freight'
			LIMIT 1
		];

		Set<Id> claimIds = new Set<Id>();
		for (Case claim : caseList) {
			claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
			claim.Status = 'Closed';
			claimIds.add(claim.Id);
		}
		update caseList;

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			List<CSX_CMP_ClaimSearchController.ClaimSearchResponseWrapper> response = CSX_CMP_ClaimSearchController.fetchFullClaimDetails(
				claimIds
			);
			Test.stopTest();

			System.assertEquals(1, response.size(), 'One claim record found should be found');
		}
	}

	/* @description : method to test Get Claim search based on role */
    
	@isTest
	static void testgetClaimSearchBasedOnRole() {
		CSX_CMP_Role_Access_Configuration__mdt roleDetails = CSX_CMP_Role_Access_Configuration__mdt.getInstance(
			'CSX_CMP_Freight_Claim_User'
		);

		User user = [
			SELECT Id, UserRole.DeveloperName
			FROM User
			WHERE FirstName = 'Freight Claim' AND LastName = 'User'
			LIMIT 1 
		];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_Role_Access_Configuration__mdt layoutDetail = CSX_CMP_ClaimSearchController.getClaimSearchBasedOnRole();
			Test.stopTest();
 
            System.assertEquals(roleDetails.Id, layoutDetail.Id, 'The layout detail should match the role details');
		}
	}
}