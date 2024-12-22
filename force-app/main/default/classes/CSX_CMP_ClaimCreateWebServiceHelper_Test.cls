/**************************************************************************************
@author: Infosys
Apex Class Name     : CSX_CMP_ClaimCreateWebServiceHelper_Test
@description        : Helper Class for Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           22/04/2023       First version of this class.
*************************************************************************************/

@isTest
public with sharing class CSX_CMP_ClaimCreateWebServiceHelper_Test {
	/*description : method to create master data */

	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);
		Case claim = [SELECT Id, CSX_CMP_System_Action_Toggle__c, Status FROM Case WHERE Id = :response.claimId];
		claim.Type = 'Intermodal Service Claim';
		claim.Origin = 'Customer Service';
		update claim;
		//CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c];
		//update request;
	}

	/* @description : method to test claim creation service for EDI creation */

	@isTest
	static void claimCreateServiceTestForEDICreation() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForEDICreation();
		CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
		System.assertNotEquals(
			null,
			request.CSX_CMP_Claim__c,
			'The claim creation service should return a 201 Created status code for EDI creation.'
		);
	}

	/* @description : method to test claim create service for customer service creation */

	@isTest
	static void claimCreateServiceTestForCustomerServiceCreation() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForCustomerServiceCreation();
		Case claimNew = [
			SELECT Id, CaseNumber
			FROM Case
			WHERE Type = 'Intermodal Service Claim' AND Origin = 'Customer Service'
			LIMIT 1
		];
		System.assertNotEquals(null, claimNew.CaseNumber, 'New claim should be created for Customer Service.');
	}

	/* @description : method to test claim create service for customer service duplicates */

	@isTest
	static void claimCreateServiceTestForCustomerServiceDuplicates() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForCustomerServiceDuplicates();
		Case claimNew = [
			SELECT Id, CaseNumber
			FROM Case
			WHERE Type = 'Intermodal Service Claim' AND Origin = 'Customer Service'
			LIMIT 1
		];
		System.assertNotEquals(null, claimNew.CaseNumber, 'New claim should be created for Customer Service.');
	}

	/* description : method to test claim creation service for customer service approval */

	@isTest
	static void claimCreateServiceTestForCustomerServiceApproval() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForCustomerServiceApproval();
		Case claimNew = [
			SELECT Id, CaseNumber, Status
			FROM Case
			WHERE Type = 'Intermodal Service Claim' AND Origin = 'Customer Service'
			LIMIT 1
		];
		System.assertNotEquals('Approved', claimNew.Status, 'New claim should not be approved for Customer Service.');
	}

	/* @description : method to test claim creation service for validation of mandatory fields in Intermodal Service Claim type */

	@isTest
	static void claimCreateServiceTestForValidation1() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForValidation1();
		System.assertEquals(
			400,
			RestContext.response.statusCode,
			'The claim creation service should return a 400 status code for validation of mandatory fields in Intermodal Service Claim Type.'
		);
	}

	/* @description : Method to test the claim creation service for validation of  Mandatory Fields in Customr Service Claim Type */

	@isTest
	static void claimCreateServiceTestForValidation2() {
		CSX_CMP_ClaimCreateWebService_Test.claimCreateServiceTestForValidation2();
		System.assertEquals(
			400,
			RestContext.response.statusCode,
			'The claim creation service should return a 400 status code for validation of mandatory fields in Customer Service Claim Type.'
		);
	}

	/* @description : Method to test the claim creation service for validation of SenderId */

	// @isTest
	// static void claimCreateServiceTestForValidation3() {
	// 	String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
	// 	Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
	// 	requestMapAny.put('senderId', null);

	// 	User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

	// 	System.runAs(user) {
	// 		Test.startTest();
	// 		RestRequest req = new RestRequest();
	// 		RestResponse res = new RestResponse();
	// 		req.requestURI = '/services/apexrest/v1/claims/create';
	// 		req.httpMethod = 'POST';
	// 		req.requestBody = Blob.valueOf(requestJSON);
	// 		RestContext.request = req;
	// 		RestContext.response = res;
	// 		CSX_CMP_ClaimCreateWebService.claimCreateService();
	// 		Test.stopTest();

	// 		System.assertEquals(
	// 			201,
	// 			res.statusCode,
	// 			'The claim creation service should return a 400 status code for validation of SenderId.'
	// 		);
	// 	}
	// }
}