@isTest
global class CSX_CMP_MockResponseGenerator implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {  
		if (req.getEndpoint().contains('https://apistaging.csx.com/umler/v1/cars/search')) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(CSX_CMP_TestMasterDataUtility.umlerMockResponse()); 
			res.setStatusCode(200);
			return res;
		} else if (req.getEndpoint().contains('http://apidev.csx.com/mechanical-events/api/v1/bad-orders')) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(CSX_CMP_TestMasterDataUtility.mtiMockResponse());

			res.setStatusCode(200);
			return res;
		} else if (req.getEndpoint().contains('https://logon-dev.csx.com/oauth2/aus1j3sfjmaIVNNit0h8/v1/token')) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"access_token":"123456"}');
			res.setStatusCode(200);
			return res;
		} else if (req.getEndpoint().contains('https://apistaging.csx.com/safety-rar/v1/freight-claims')) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(CSX_CMP_TestMasterDataUtility.rarsMockResponse());
			res.setStatusCode(200);
			return res;
		} else if (
			req.getEndpoint()
				.contains(
					'https://integration-dev-zs11iare.it-cpi013-rt.cfapps.us21.hana.ondemand.com/http/v1/ar-balance-details'
				)
		) {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(CSX_CMP_TestMasterDataUtility.arBalanceMockResponse());
			res.setStatusCode(200);
			return res;
		} else {
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{"Success":[{"equipmentNumber":"CSXT123456","aaaCarType":"A","equipmentGroup":"G","insideLength":"10","insideWidth":"10","actualOwner":"CSX","lessee":"CSX"}]}'
			);
			res.setStatusCode(200);
			return res;
		}
	}
}