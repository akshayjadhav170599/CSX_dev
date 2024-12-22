/**************************************************************************************
@author: Infosys
@description  : Class to test  Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.

Apex Class Name     : CSX_CMP_ClaimCreateWebService_Test
Function            : Class to test Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/07/2024       First version of this class.
*************************************************************************************/

@isTest
public with sharing class CSX_CMP_ClaimCreateWebService_Test {
	
    /*@description : method to create master data */
    
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
 		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Case claim = [SELECT Id, CSX_CMP_System_Action_Toggle__c, Status FROM Case WHERE Id = :response.claimId];
        claim.Type = 'Intermodal Service Claim';
        claim.Origin = 'Customer Service';
        update claim;
	}

	/* @description : method to test claim creation service for EDI creation */
    
	@isTest
	public static void claimCreateServiceTestForEDICreation() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/claims/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_ClaimCreateWebService.claimCreateService();
			Test.stopTest();
			CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
			System.assertNotEquals(
				null,
				request.CSX_CMP_Claim__c,
				'The claim creation service should return a 201 Created status code for EDI creation.'
			);
		}
	}

	/* @description : method to test claim create service for customer service creation */
    
	@isTest
	public static void claimCreateServiceTestForCustomerServiceCreation() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', 'Customer Service');
		requestMapAny.put('claimType', 'Intermodal Service Claim');
		requestMapAny.put('caseNumber', null);
		requestJSON = JSON.serialize(requestMapAny);

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/claims/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_ClaimCreateWebService.claimCreateService();

			Test.stopTest();
			System.assertNotEquals(
				null,
				res.responseBody,
				'The claim creation service should return a 201 Created status code for Customer Service creation.'
			);
		}
	}

	/* @description : method to test claim create service for customer service duplicates */

	@isTest
	public static void claimCreateServiceTestForCustomerServiceDuplicates() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', 'Customer Service');
		requestMapAny.put('claimType', 'Intermodal Service Claim');
		requestJSON = JSON.serialize(requestMapAny);

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/claims/create';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(requestJSON);
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_ClaimCreateWebService.claimCreateService();
		Case claimNew = [
			SELECT Id, CaseNumber
			FROM Case
			WHERE Type = 'Intermodal Service Claim' AND Origin = 'Customer Service'
			LIMIT 1
		];
		requestMapAny.put('caseNumber', claimNew.CaseNumber);
		requestMapAny.put('status', 'Rejected');
		req.requestBody = Blob.valueOf(JSON.serialize(requestMapAny));

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ClaimCreateWebService.claimCreateService();
			Test.stopTest();
			System.assertEquals(
				200,
				res.statusCode,
				'The claim creation service should return a 200 status code for Customer Service duplicates.'
			);
		}
	}

	/* description : method to test claim creation service for customer service approval */

	@isTest
	public static void claimCreateServiceTestForCustomerServiceApproval() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', 'Customer Service');
		requestMapAny.put('claimType', 'Intermodal Service Claim');
		requestJSON = JSON.serialize(requestMapAny);

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/claims/create';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(requestJSON);
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_ClaimCreateWebService.claimCreateService();
		Case claimNew = [
			SELECT Id, Status, CaseNumber, CSX_CMP_System_Action_Toggle__c
			FROM Case
			WHERE Type = 'Intermodal Service Claim' AND Origin = 'Customer Service'
			LIMIT 1
		];
		claimNew.Status = 'Rejected';
		claimNew.CSX_CMP_System_Action_Toggle__c = !claimNew.CSX_CMP_System_Action_Toggle__c;
		update claimNew;

		requestMapAny.put('caseNumber', claimNew.CaseNumber);
		requestMapAny.put('status', 'Rejected');
		req.requestBody = Blob.valueOf(JSON.serialize(requestMapAny));

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ClaimCreateWebService.claimCreateService();
			Test.stopTest();
			System.assertEquals(
				200,
				res.statusCode,
				'The claim creation service should return a 200 status code for Customer Service approval.'
			);
		}
	}

	/* @description : method to test claim creation service for validation of mandatory fields in Intermodal Service Claim type */

	@isTest
	public static void claimCreateServiceTestForValidation1() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', '');
		requestMapAny.put('claimType', 'Intermodal Service Claim');
		requestJSON = JSON.serialize(requestMapAny);
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			requestJSON = JSON.serialize(requestMapAny);
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/claims/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_ClaimCreateWebService.claimCreateService();
			Test.stopTest();
			System.assertEquals(
				400,
				res.statusCode,
				'The claim creation service should return a 400 status code for validation of mandatory fields in Intermodal Service Claim type.'
			);
		}
	}

	/* @description : Method to test the claim creation service for validation of  Mandatory Fields in Customer Service Claim Type */

	@isTest
	public static void claimCreateServiceTestForValidation2() {
		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', 'Customer Service');
		requestMapAny.put('claimType', null);
		requestJSON = JSON.serialize(requestMapAny);

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			requestJSON = JSON.serialize(requestMapAny);
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/claims/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_ClaimCreateWebService.claimCreateService();
			Test.stopTest();
			System.assertEquals(
				400,
				res.statusCode,
				'The claim creation service should return a 400 status code for validation of mandatory fields in Customer Service Claim Type.'
			);
		}
	}

	// /* @description : Method to test the claim creation service for validation of SenderId */

	// @isTest
	// public static void claimCreateServiceTestForValidation3() {
	// 	String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
	// 	Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
	// 	requestMapAny.put('senderSCAC', null);
	// 	requestJSON = JSON.serialize(requestMapAny);

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
	// 		System.assertNotEquals(
	// 			201,
	// 			res.statusCode,
	// 			'The claim creation service should return a 201 status code for validation of SenderId.'
	// 		);
	// 	}
	// }
}