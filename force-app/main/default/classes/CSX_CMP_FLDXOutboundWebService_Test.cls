@isTest
public class CSX_CMP_FLDXOutboundWebService_Test {
	// static String prevMonth = String.valueOf(Date.Today().month()-1);
	// public static String servicePeriod = 'PER-'+prevMonth+'-'+string.valueOf(prevYear).substring(2,4);
	@testSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

		String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
		Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
		requestMap.put('claimType', 'FC RR Inbound Claim');
		requestMap.put('source', 'Customer Service');
		requestJSON = JSON.serialize(requestMap);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/claims/create';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(requestJSON);
		RestContext.request = req;
		RestContext.response = res;
		CSX_CMP_ClaimCreateWebService.claimCreateService();

		String claimNumber = res.responseBody.toString();

		CSX_CMP_Equipment__c equipment = [
			SELECT Id
			FROM CSX_CMP_Equipment__c
			WHERE CSX_CMP_Claim__r.CaseNumber = :claimNumber
			LIMIT 1
		];
		CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
        //String response = CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipment.Id,'');
        
        

		Case claim = [
			SELECT Id, CaseNumber, CSX_CMP_System_Action_Toggle__c, Status
			FROM Case
			WHERE CaseNumber = :claimNumber
			LIMIT 1
		];
		claim.Status = 'Closed';
		claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		update claim;

        Case distClaim = [SELECT Id, CaseNumber,CSX_CMP_Service_Period__c FROM Case WHERE Type = 'FC RR Outbound Claim' LIMIT 1];
		System.assertNotEquals(null, distClaim, 'Distribution claim should not be null');
    	System.assertNotEquals(null, distClaim.Id, 'Distribution claim Id should not be null');
    }

	// @isTest
	// static void testFLDXOutboundService() {
	// 	User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

	// 	System.runAs(user) {
	// 		Test.startTest();
	// 		RestRequest request = new RestRequest();
	// 		RestResponse response = new RestResponse();
	// 		request.requestURI = '/services/apexrest/v1/fldx-outbound-claims/fetch';
	// 		request.httpMethod = 'GET';
	// 		String servicePeriod =
	// 			'PER-' +
	// 				String.valueOf(Date.today().month()) +
	// 				'-' +
	// 				String.valueOf(Date.today().year()).substring(2, 4);
	// 		request.addParameter('servicePeriod', servicePeriod);
	// 		RestContext.request = request;
	// 		RestContext.response = response;
	// 		CSX_CMP_FLDXOutboundWebService.getOutboundClaimRecords();
	// 		Test.stopTest();
	// 		CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper responseWrapper = (CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper) JSON.deserialize(
	// 			RestContext.response.responseBody.toString(),
	// 			CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper.class
	// 		);
	// 		system.assertNotEquals(null, responseWrapper, 'Response should not be null as claim is created above');
	// 		system.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200 as data is returned');
	// 	}
	// }

	// @isTest
	// static void testNoCaseScenerio(){
	//     User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	//     System.runAs(user){
	//         Test.startTest();
	//             RestRequest request = new RestRequest();
	//             RestResponse response = new RestResponse();
	//             request.requestURI = '/services/apexrest/v1/fldx-outbound-claims/fetch';
	//             request.httpMethod = 'GET';
	//             request.addParameter('servicePeriod', 'PER-3-24');
	//             RestContext.request = request;
	//             RestContext.response = response;
	//             CSX_CMP_FLDXOutboundWebService.getOutboundClaimRecords();
	//         Test.stopTest();
	//         CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper responseWrapper = (CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper) JSON.deserialize(RestContext.response.responseBody.toString(), CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper.class);
	//         System.assertEquals(200, RestContext.response.statusCode,'Status code should be 200 as no data is returned');
	//         System.assertEquals(system.label.CSX_CMP_Results_not_found, RestContext.response.responseBody.toString(),'Response should be No Data Found as no data is returned');
	//     }
	// }

	// @isTest
	// static void testNoServicePeriodScenerio(){
	//     User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	//     System.runAs(user){
	//         Test.startTest();
	//             RestRequest request = new RestRequest();
	//             RestResponse response = new RestResponse();
	//             request.requestURI = '/services/apexrest/v1/fldx-outbound-claims/fetch';
	//             request.httpMethod = 'GET';
	//             request.addParameter('servicePeriod', null);
	//             RestContext.request = request;
	//             RestContext.response = response;
	//             CSX_CMP_FLDXOutboundWebService.getOutboundClaimRecords();
	//         Test.stopTest();
	//         CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper responseWrapper = (CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper) JSON.deserialize(RestContext.response.responseBody.toString(), CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper.class);
	//         System.assertEquals(400, RestContext.response.statusCode,'Status code should be 400 as service period is not provided');
	//         System.assertEquals('Invalid Request', RestContext.response.responseBody.toString(),'Response should be Invalid Request as service period is not provided');
	//     }
	// }
}