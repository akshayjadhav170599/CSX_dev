/**
@Author       - Infosys
@Name         - CSX_CMP_AbstractPDFController_Test
@Created Date - 5/07/2024
@Description  - This is a test class for CSX_CMP_AbstractPDFController class.
@RICEFW reference - 
*/
@isTest
public class CSX_CMP_AbstractPDFController_Test {
	@testSetup
	/* 
    @Description : This method is used to make test data 
    */
	public static void setupdata() {
		// Calling MasterDataLoader to load the data
		CSX_CMP_TestMasterDataUtility.createMasterData();

		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);

		CSX_CMP_Property_Portal_Staging__c propertyPortal = new CSX_CMP_Property_Portal_Staging__c(
			CSX_CMP_Claim_Number__c = response.claimNum
		);
		insert propertyPortal;
	}
	/* @description : These method is used test the abstract pdf details*/
	@isTest
	public static void testGetAbstractDetails() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'Manager' LIMIT 1];
		CSX_CMP_Property_Portal_Staging__c propertyPortal = [
			SELECT Id, CSX_CMP_Record_Type__c, CSX_CMP_Service_Period__c
			FROM CSX_CMP_Property_Portal_Staging__c
			LIMIT 1
		];
		System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
			List<CSX_CMP_AbstractPDFController.ClaimInputWrapper> claimWrapperList = new List<CSX_CMP_AbstractPDFController.ClaimInputWrapper>();
			Test.startTest();
			PageReference pageRef = Page.CSX_CMP_AbstractPDFReport;
			Test.setCurrentPage(pageRef);
			ApexPages.currentPage().getParameters().put('PPId', propertyPortal.Id);
			CSX_CMP_AbstractPDFController controller = new CSX_CMP_AbstractPDFController();
			controller.strPropertyPortalId = propertyPortal.Id;
			claimWrapperList = controller.claimWrapperList;
			Test.stopTest();
			System.assertNotEquals(null, claimWrapperList.size(), 'Claim Wrapper List should be not null');
		}
	}
}