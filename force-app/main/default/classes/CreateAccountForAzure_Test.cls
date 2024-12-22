@isTest
public class CreateAccountForAzure_Test {

    @testSetup
    static void setupData() {
        CSX_CMP_TestMasterDataUtility.createMasterData();
    }

    @isTest
    static void testCreateAccountSuccess() {
        // Create a mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body
        req.requestURI = '/services/apexrest/v1/accounts/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name" : "Test Account"}');
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        CreateAccountForAzure.createAccount();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(201, res.statusCode);
        System.assertEquals('{"message" : "Account created successfully"}', res.responseBody.toString());
        
        // Verify the account was created
        Account createdAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        System.assertNotEquals(null, createdAccount, 'Account should be created');
    }

    @isTest
    static void testCreateAccountDMLException() {
        // Create a mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body with invalid data to cause a DML exception
        req.requestURI = '/services/apexrest/v1/accounts/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name" : null}');
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        CreateAccountForAzure.createAccount();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(500, res.statusCode);
        System.assert(res.responseBody.toString().contains('Required fields are missing'), 'Response should contain error message');
    }

    @isTest
    static void testCreateAccountNullPointerException() {
        // Create a mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body to null to cause a NullPointerException
        req.requestURI = '/services/apexrest/v1/accounts/';
        req.httpMethod = 'POST';
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        CreateAccountForAzure.createAccount();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(500, res.statusCode);
    }
}