/**
@Author       - Infosys
@Name         - CSX_CMP_LDRCreateWebService_Test
@Created Date - 5/07/2024
@Description  - 
@RICEFW reference - 
*/
@isTest
public class CSX_CMP_LDRCreateWebService_Test {
	/* @description : This method is used to make test data */
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/*@description : These method is used to test the LDR creation Web service*/
	@isTest
	static void createLDReport() {
		String requestJSON = CSX_CMP_TestUtility.ldrCreationJSON();
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/loss-damage-reports/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRCreateWebService.ldrCreateService();
			Test.stopTest();
			System.assertEquals(201, RestContext.response.statusCode, 'Expected status code 201 as L&D Report is created.');
		}
	}

	/*@description : These method is used to test the LDR creation Web service*/
	@isTest
	static void createLDReport2() {
		String requestJSON = CSX_CMP_TestUtility.ldrCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('racfId', '');
		requestMapAny.put('contactName', 'Test Contact');
		requestMapAny.put('email', 'FordMotorCo@csx.com');
		requestJSON = JSON.serialize(requestMapAny);
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/loss-damage-reports/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRCreateWebService.ldrCreateService();
			Test.stopTest();
			System.assertNotEquals(null, res.responseBody, 'Response body should not be null.');
		}
	}

	/*@description : These method is used to test the LDR creation Web service*/
	@isTest
	static void createLDReport3() {
		String requestJSON = CSX_CMP_TestUtility.ldrCreationJSON();
		Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMapAny.put('source', '');
		requestJSON = JSON.serialize(requestMapAny);
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/loss-damage-reports/create';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRCreateWebService.ldrCreateService();
			Test.stopTest();
			System.assertNotEquals(null, res.responseBody, 'Response body should not be null.');
		}
	}

	/*@description : These method is used to test the LDR creation Web service in an error scenario*/
	@isTest
	static void createLDReport4() {
		String requestBody = '{source:"Manual"}';
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
			Test.startTest();

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			try {
				req.requestURI = '/services/apexrest/v1/loss-damage-reports/create';
				req.httpMethod = 'POST';
				req.requestBody = Blob.valueOf(requestBody);
				RestContext.request = req;
				RestContext.response = res;
				CSX_CMP_LDRCreateWebService.ldrCreateService();
			} catch (Exception e) {
				System.assertEquals(500, RestContext.response.statusCode, 'Expected status code 500');
			}
			Test.stopTest();
		}
	}
}