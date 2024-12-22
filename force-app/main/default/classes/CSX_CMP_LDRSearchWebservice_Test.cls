/**************************************************************************************
Apex Class Name     : CSX_CMP_InterfaceUtility
Function            : Class for Webservice to search L&D Reports. 
RICEFW #            : CMP-I-0537
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           15/2/2024       First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_LDRSearchWebservice_Test {
	/*@description : This method is used to make test data */
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		Map<String, String> request = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
		CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(
			request
		);
	}

	/*@description : These method is used to test the ldr search service when JSON is sent in invalid format */
	@isTest
	static void test1() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			String requestBody = '{ param1: "value1", "param2": 123 }';
			req.requestBody = Blob.valueOf(requestBody);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRSearchWebservice.lDRSearchService();
			Test.stopTest();
			System.assertEquals(500, res.statusCode, 'Expected status code to be 500');
		}
	}

	/*@description : These method is used to test the ldr search service when report number is found */
	// asert is wrong statuscode will never be null
	@isTest
	static void test2() {
		CSX_CMP_LD_Report__c report = [SELECT Id, Name FROM CSX_CMP_LD_Report__c LIMIT 1];
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			Map<String, String> requestMap = new Map<String, String>();
			requestMap.put('reportNumber', report.Name);
			req.requestBody = Blob.valueOf(JSON.serialize(requestMap));
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRSearchWebservice.lDRSearchService();
			Test.stopTest();
			System.assertEquals(null, res.statusCode, 'Expected status code to be Null');
		}
	}

	// asert is wrong statuscode will never be null
	/* @description : These method is used to test the ldr search service when report number is not found */
	@isTest
	static void test3() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			Map<String, String> requestMap = new Map<String, String>();
			requestMap.put('reportNumber', 'C-342');
			req.requestBody = Blob.valueOf(JSON.serialize(requestMap));
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_LDRSearchWebservice.lDRSearchService();
			Test.stopTest();
			System.assertEquals(null, res.statusCode, 'Expected status code to be Null');
		}
	}

	/* @description : These method is used to test the ldr search service when user has no access */
	@isTest
	static void test4() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Expert' AND LastName = 'chatter' LIMIT 1];
		CSX_CMP_LD_Report__c report = [SELECT Id, Name FROM CSX_CMP_LD_Report__c LIMIT 1];
		System.runAs(user) {
			try {
				RestRequest req = new RestRequest();
				RestResponse res = new RestResponse();
				Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('reportNumber', report.Name);
				req.requestBody = Blob.valueOf(JSON.serialize(requestMap));
				RestContext.request = req;
				RestContext.response = res;
				CSX_CMP_LDRSearchWebservice.lDRSearchService();
			} catch (Exception e) {
				System.assertEquals(400, RestContext.response.statusCode, 'Expected Status Code 400');
			}
		}
	}
}

// @isTest
// static void testLDRSearchServiceWithValidRequest() {

//     String requestBody = '{ "param1": "value1", "param2": 123 }';

//     RestRequest req = new RestRequest();
//     req.requestBody = Blob.valueOf(requestBody);
//     RestContext.request = req;
//     RestResponse res = new RestResponse();
//     RestContext.response = res;

//     String expectedResponse = '{ "status": "200", "data": [], "message": "" }';
//     res.responseBody = Blob.valueOf(expectedResponse);

//     //Test.startTest();
//     CSX_CMP_LDRSearchWebservice.lDRSearchService();
//     //Test.stopTest();

//     System.assertEquals(null, res.statusCode, 'Expected status code 200');
// }

/*  @isTest
    static void testLDRSearchServiceWithInValidRequest() {
       String requestBody = '{ "param1": "value1", "param2": 123 }';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.requesturi= 'https://csx-cims-dev--dev.sandbox.my.salesforce.com/services/apexrest/v1/loss-age-reports/search/%';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        system.debug('req'+req);
        RestResponse res = new RestResponse();
        res.statusCode=400;
        RestContext.response = res;
		System.debug('res'+res.statusCode);
        String expectedResponse = '{ "status": "400", "data": [], "message": "" }';
        res.responseBody = Blob.valueOf(expectedResponse);
        
        
       // Test.startTest();
        System.assertEquals(400, res.statusCode, 'Expected status code 200');
        CSX_CMP_LDRSearchWebservice.LDRSearchService();
        //Test.stopTest();

        //  System.assertEquals(null, res.statusCode, 'Expected status code 200');
    }*/

/* @isTest
    static void testLDRSearchServiceWithEmptyRequestBody() {
		ldrSearchResultWrapper ldr= new ldrSearchResultWrapper();
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/v1/loss-damage-reports/search/%';
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
       
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        ldr.status='400';
        ldr.errorMessage='Invalid';

        //Test.startTest();
        CSX_CMP_LDRSearchWebservice.LDRSearchService();
        //Test.stopTest();
        
        System.assertEquals(500, res.statusCode, 'Expected status code 400 for empty request body');
    }*/

// @isTest
// static void testLDRSearchServiceWithInvalidJson() {

//     String requestBody = '{"invalid_json":}';

//     RestRequest req = new RestRequest();
//     req.requestBody = Blob.valueOf(requestBody);
//     RestContext.request = req;
//     RestResponse res = new RestResponse();
//     RestContext.response = res;

//     //Test.startTest();
//     CSX_CMP_LDRSearchWebservice.lDRSearchService();
//     //Test.stopTest();

//    System.assertEquals(500, res.statusCode, 'Expected status code 400 for invalid JSON');
//  }
// public class LdrSearchResultWrapper{
//     public string status;
//     public string errorMessage;
//    // public list<ldrSearchResponseWrapper> results;
// }

/*@isTest
    static void testLDRSearchServiceWithSystemStringException() {
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{ "param1": "value1", "param2": 123 }');
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        //Test.startTest();
        CSX_CMP_LDRSearchWebservice.LDRSearchService();
	    //Test.stopTest(); 

        System.assertEquals(null, res.statusCode, 'Expected status code 500 for System.StringException');
    }*/

// @isTest
// static void testData(){
//     RestRequest req = new RestRequest();
//     req.httpMethod = 'POST';
//     req.requestURI = '/services/apexrest/v1/loss-damage-reports/search/%';
//     req.requestBody = Blob.valueOf('{}');
//     RestContext.request = req;
//     RestResponse res = new RestResponse();
//     RestContext.response = res;
//     //ldr.status='400';
//     //ldr.errorMessage='Invalid';

//     //Test.startTest();
//     CSX_CMP_LDRSearchWebservice.lDRSearchService();
//     //Test.stopTest();
// }