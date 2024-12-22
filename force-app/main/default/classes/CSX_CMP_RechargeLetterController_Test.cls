/*
@Author       - Infosys
@Name         - CSX_CMP_RechargeLetterController_Test
@Created Date - 5/18/2024
@Description  - This class is used to cover CSX_CMP_RechargeLetterController class
@RICEFW reference - CMP-E-0433
*/
@isTest
public class CSX_CMP_RechargeLetterController_Test {
	@testSetup
	public static void setupdata() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
		note.CSX_CMP_Note_Type__c = 'Recharge Reason';
		note.CSX_CMP_Claim__c = response.claimId;
		insert note;

		String data = '{"comment":"Test"}';
		CSX_CMP_RechargeClaimCreationController.createRechargeClaim(response.claimId, data);
	}

	/**
    @description : This method is used to test the case wrapper with record id
     */
	@isTest
	static void testWithRecordId() {
		case claim = [SELECT Id FROM Case WHERE Type = 'FC RR Inbound Claim'];

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		CSX_CMP_RechargeLetterController.CaseWrapper claimWrapper = new CSX_CMP_RechargeLetterController.CaseWrapper();
		System.runAs(user) {
			CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
			Test.startTest();
			PageReference pageRef = Page.CSX_CMP_RechargeLetterPage;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('recordId', claim.Id);
			CSX_CMP_RechargeLetterController controller = new CSX_CMP_RechargeLetterController();
			Test.stopTest();

			//Assert statements
			claimWrapper = controller.objCaseWrapper;
			System.assertNotEquals(null, claimWrapper, 'CaseWrapper should not be null');
		}
	}

	/**
    @description : This method is used to test the case wrapper with claim record
     */
	@isTest
	static void testWithoutRecordId() {
		case claim = [SELECT Id FROM Case WHERE type = 'FC RR Inbound Claim'];
		List<Case> claimDetails = CSX_CMP_RechargeLetterController.getCaseDetails(new List<Id>{ claim.Id });

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		CSX_CMP_RechargeLetterController.CaseWrapper claimWrapper = new CSX_CMP_RechargeLetterController.CaseWrapper();
		System.runAs(user) {
			CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
			Test.startTest();
			PageReference pageRef = Page.CSX_CMP_RechargeLetterPage;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('case', JSON.serialize(claimDetails[0]));
			CSX_CMP_RechargeLetterController controller = new CSX_CMP_RechargeLetterController();
			Test.stopTest();

			//Assert statements
			claimWrapper = controller.objCaseWrapper;
			System.assertNotEquals(null, claimWrapper.claimDate, 'Claim date should not be null');
			System.assertNotEquals(null, claimWrapper.claimAmount, 'Claim amount should not be null');
		}
	}
}