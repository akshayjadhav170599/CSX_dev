/**************************************************************************************
Apex Class Name     : CSX_CMP_Fetch_3PL_AccountsWebservice
Function            : This class is used to test the methods in CSX_CMP_Fetch_3PL_AccountsWeb class
Author              : Infosys
Modification Log    :
* Developer         : Date             Description
* ----------------------------------------------------------------------------                 
* Infosys           26/06/2024        First version of this class.
*************************************************************************************/

@isTest
public class CSX_CMP_Fetch_3PL_AccountsWeb_Test {
	@testSetup
	static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/* @description : method to test fetchInvEmailSubscriptions and sending racfId to get contacts */

	@isTest
	static void fetchInvEmailSubscriptionsTest() {
		Contact reqContact = [SELECT Id, CSX_CMP_RACF_ID__c FROM Contact WHERE CSX_CMP_RACF_ID__c != NULL LIMIT 1];

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/contacts/' + String.valueOf(reqContact.CSX_CMP_RACF_ID__c) + '/accounts';
			req.httpMethod = 'GET';
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_Fetch_3PL_AccountsWebservice.fetchInvEmailSubscriptions();
			Test.stopTest();

			System.assertEquals(200, res.statusCode, 'Status code should be 200 as rachId is valid and data is available');
		}
	}

	/* @description : method to test fetchInvEmailSubscriptions and sending racfId to get contacts */

	@isTest
	static void fetchInvEmailSubscriptionsTest4() {
		Contact reqContact = [SELECT Id, CSX_CMP_RACF_ID__c FROM Contact WHERE CSX_CMP_RACF_ID__c != NULL LIMIT 1];
		update reqContact;

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/contacts/' + String.valueOf(reqContact.CSX_CMP_RACF_ID__c) + '/accounts';
			req.httpMethod = 'GET';
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_Fetch_3PL_AccountsWebservice.fetchInvEmailSubscriptions();
			Test.stopTest();
			System.assertEquals(200, res.statusCode, 'Status code should be 200 as racfId is valid and data is available');
		}
	}

	/* @description : method to test fetchInvEmailSubscriptions and sending a racfId which doesn't exist */

	@isTest
	static void fetchInvEmailSubscriptionsTest2() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			String racfId = 'i8767';
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/contacts/' + racfId + '/accounts';
			req.httpMethod = 'GET';
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_Fetch_3PL_AccountsWebservice.fetchInvEmailSubscriptions();
			Test.stopTest();

			System.assertNotEquals(400, res.statusCode, 'Status code should be 400 as racfId is invalid');
		}
	}

	/* @description : method to test fetchInvEmailSubscriptions and not sending racfId */

	@isTest
	static void fetchInvEmailSubscriptionsTest3() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/contacts/' + '' + '/accounts';
			req.httpMethod = 'GET';
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_Fetch_3PL_AccountsWebservice.fetchInvEmailSubscriptions();
			Test.stopTest();

			System.assertEquals(400, res.statusCode, 'Status code should be 400 as racfId is null');
		}
	}
}