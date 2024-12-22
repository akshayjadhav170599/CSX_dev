/**
@description : This is a test class for CSX_CMP_3rdPartyWebService
@author : Infosys
Apex Class Name  : CSX_CMP_3rdPartyWebService_Test
 */
@isTest
public class CSX_CMP_3rdPartyWebService_Test {
	@testSetup
	static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/**
    @description : method to test fetchInvEmailSubscriptions and sending racfId to get contacts
     */
	@isTest
	static void fetchInvoiceEmailSubscriptionsTest() {
		Contact reqContact = [SELECT Id, CSX_CMP_RACF_ID__c FROM Contact WHERE CSX_CMP_RACF_ID__c != NULL LIMIT 1];

		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI =
			'/services/apexrest/v1/contacts/' +
			String.valueOf(reqContact.CSX_CMP_RACF_ID__c) +
			'/email-subscription';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_3rdPartyWebService.fetchInvEmailSubscriptions();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

		System.assertEquals(200, res.statusCode, 'Status code should be 200');
		System.assertNotEquals(
			null,
			responseMap.get('invoiceNotificationPDF'),
			'invoiceNotificationPDF should not be null'
		);
	}

	/**
    @description : method to test fetchInvEmailSubscriptions and sending a racfId which doesn't exist
     */
	@isTest
	static void fetchInvoiceEmailSubscriptionsTest2() {
		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/contacts/' + 'emptyS' + '/email-subscription';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_3rdPartyWebService.fetchInvEmailSubscriptions();
		Test.stopTest();

		System.assertEquals(404, res.statusCode, 'Status code should be 404');
	}

	/**
    @description : method to test fetchInvEmailSubscriptions and not sending racfId
     */
	@isTest
	static void fetchInvoiceEmailSubscriptionsTest3() {
		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/contacts/' + '' + '/email-subscription';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_3rdPartyWebService.fetchInvEmailSubscriptions();
		Test.stopTest();

		System.assertEquals(400, res.statusCode, 'Status code should be 400 as racfId is null');
	}

	/**
    @description : method to test updateInvEmailSubscriptions and sending racfId to get contacts
     */
	@isTest
	static void updateInvoiceDetailsTest() {
		Contact reqContact = [SELECT Id, CSX_CMP_RACF_ID__c FROM Contact WHERE CSX_CMP_RACF_ID__c != NULL LIMIT 1];

		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI =
			'/services/apexrest/v1/contacts/' +
			String.valueOf(reqContact.CSX_CMP_RACF_ID__c) +
			'/email-subscription';
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;
		Map<String, Object> requestBodyMap = new Map<String, Object>();
		requestBodyMap.put('invoiceNotificationPDF', true);
		requestBodyMap.put('invoiceNotificationsOtherEmails', 'subodh.deshpande@infosys.com');

		req.requestBody = Blob.valueOf(JSON.serialize(requestBodyMap));
		CSX_CMP_3rdPartyWebService.updateInvEmailSubscriptions();
		Test.stopTest();

		System.assertEquals(201, res.statusCode, 'Status code should be 201');
	}

	/**
    @description : method to test updateInvEmailSubscriptions and sending a racfId which doesn't exist
     */
	@isTest
	static void updateInvoiceDetailsTest2() {
		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/contacts/' + 'emptyS' + '/email-subscription';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		Map<String, Object> requestBodyMap = new Map<String, Object>();
		requestBodyMap.put('invoiceNotificationPDF', true);
		requestBodyMap.put('invoiceNotificationsOtherEmails', 'subodh.deshpande@infosys.com');

		req.requestBody = Blob.valueOf(JSON.serialize(requestBodyMap));

		CSX_CMP_3rdPartyWebService.updateInvEmailSubscriptions();
		Test.stopTest();

		System.assertEquals(404, res.statusCode, 'Status code should be 404 as racfId is null');
	}

	/**
    @description : method to test updateInvEmailSubscriptions and not sending racfId
     */
	@isTest
	static void updateInvoiceDetailsTest3() {
		Test.startTest();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/contacts/' + '' + '/email-subscription';
		req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		Map<String, Object> requestBodyMap = new Map<String, Object>();
		requestBodyMap.put('invoiceNotificationPDF', true);
		requestBodyMap.put('invoiceNotificationsOtherEmails', 'subodh.deshpande@infosys.com');
		req.requestBody = Blob.valueOf(JSON.serialize(requestBodyMap));

		CSX_CMP_3rdPartyWebService.updateInvEmailSubscriptions();
		Test.stopTest();

		System.assertEquals(400, res.statusCode, 'Status code should be 400 as racfId is null');
	}
}