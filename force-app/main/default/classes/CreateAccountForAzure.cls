/**
@description: This class is used to create account for Azure as POC
 */
@RestResource(urlMapping='/v1/accounts/*')
global with sharing class CreateAccountForAzure {
	@HttpPost
	global static void createAccount() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		Account account = new Account();
		try {
			req = RestContext.request;
			res = RestContext.response;
			Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
			account.Name = (String) requestMapAny.get('Name');
			insert account;
            res.addHeader('Content-Type', 'application/json');
			res.responseBody = Blob.valueOf('{"message" : "Account created successfully"}');
			res.statusCode = 201;
		} catch (System.DMLException e) {
			res.responseBody = Blob.valueOf(e.getMessage());
			res.statusCode = 500;
		} catch (System.NullPointerException e) {
			res.responseBody = Blob.valueOf(e.getMessage());
			res.statusCode = 500;
		} catch (Exception e) {
			res.responseBody = Blob.valueOf(e.getMessage());
			res.statusCode = 500;
		}
	}
}