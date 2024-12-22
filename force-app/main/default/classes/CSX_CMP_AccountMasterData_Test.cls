/**
@Author       - Infosys
@Name         - CSX_CMP_AccountMasterData_Test
@Created Date - 12/07/2024
@Description  - This class is used to test the methods in CSX_CMP_AccountMasterData class.
@RICEFW reference - CMP-I-1739/CMP-I-1740
*/

@isTest
private class CSX_CMP_AccountMasterData_Test {

    /* @Description : method to create master data */
    
    @testSetup
        static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

    /* @Description : method to test DoPut Customer */
    
    @isTest
    static void testDoPutCustomer() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/v1/accounts';
        req.httpMethod = 'PUT';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"accountType":"Customer","customerName":"Test Customer","partyId":"P123","businessPartnerId":"BP123","status":"X","patronRoot":"PR123","nationalAccountNumber":"NA123","partyScore":100,"legalEntityId":"LE123","taxId":"TAX123","customerShortName":"TC"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CSX_CMP_AccountMasterData.doPut();
        Test.stopTest();

        // Verify the response
        System.assert(res.statusCode == 201, 'Expected status code 201 but got ' + res.statusCode);
        System.assert(res.responseBody.toString().contains('Successfully Processed Customer Creation/Update in Salesforce Claims.'), 'Response body did not contain the expected text');

        // Verify the account record
        Account acc = [SELECT Id, Name, RecordTypeId, Status__c, CSX_CMP_External_ID__c, party_Id__c, AccountNumber, Patron_Root__c, National_Account__c, Party_Score__c, LE1_Code__c, Tax_Id__c, Care_of_Name__c FROM Account WHERE CSX_CMP_External_ID__c = 'P123'];
        System.assertEquals('Test Customer', acc.Name, 'Expected customer name to be "Test Customer" but got ' + acc.Name);
        System.assertEquals('Inactive', acc.Status__c, 'Expected status to be "Inactive" but got ' + acc.Status__c);
        System.assertEquals('P123', acc.party_Id__c, 'Expected partyId to be "P123" but got ' + acc.party_Id__c);
        System.assertEquals('BP123', acc.AccountNumber, 'Expected AccountNumber to be "BP123" but got ' + acc.AccountNumber);
        System.assertEquals('PR123', acc.Patron_Root__c, 'Expected PatronRoot to be "PR123" but got ' + acc.Patron_Root__c);
        System.assertEquals('NA123', acc.National_Account__c, 'Expected NationalAccount to be "NA123" but got ' + acc.National_Account__c);
        System.assertEquals(100, acc.Party_Score__c, 'Expected PartyScore to be 100 but got ' + acc.Party_Score__c);
        System.assertEquals('LE123', acc.LE1_Code__c, 'Expected LE1Code to be "LE123" but got ' + acc.LE1_Code__c);
        System.assertEquals('TAX123', acc.Tax_Id__c, 'Expected TaxId to be "TAX123" but got ' + acc.Tax_Id__c);
        System.assertEquals('TC', acc.Care_of_Name__c, 'Expected CareOfName to be "TC" but got ' + acc.Care_of_Name__c);
    }
    
    /* @Description : method to test DoPut Supplier */

    @isTest
    static void testDoPutSupplier() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/v1/accounts';
        req.httpMethod = 'PUT';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"accountType":"Supplier","supplierName":"Test Supplier","partyId":"P124","businessPartnerId":"BP124","status":"A","patronRoot":"PR124","nationalAccountNumber":"NA124","partyScore":200,"legalEntityId":"LE124","taxId":"TAX124","customerShortName":"TS"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CSX_CMP_AccountMasterData.doPut();
        Test.stopTest();

        // Verify the response
        System.assert(res.statusCode == 201, 'Expected status code 201 but got ' + res.statusCode);
        System.assert(res.responseBody.toString().contains('Successfully Processed Supplier Creation/Update in Salesforce Claims.'), 'Response body did not contain the expected text');
        
        // Verify the account record
        Account acc = [SELECT Id, Name, RecordTypeId, Status__c, CSX_CMP_External_ID__c, party_Id__c, AccountNumber, Patron_Root__c, National_Account__c, Party_Score__c, LE1_Code__c, Tax_Id__c, Care_of_Name__c FROM Account WHERE CSX_CMP_External_ID__c = 'BP124'];
        System.assertEquals('Test Supplier', acc.Name, 'Expected supplier name to be "Test Supplier" but got ' + acc.Name);
        System.assertEquals('Active', acc.Status__c, 'Expected status to be "Active" but got ' + acc.Status__c);
        System.assertEquals('P124', acc.party_Id__c, 'Expected partyId to be "P124" but got ' + acc.party_Id__c);
        System.assertEquals('BP124', acc.AccountNumber, 'Expected AccountNumber to be "BP124" but got ' + acc.AccountNumber);
        System.assertEquals('PR124', acc.Patron_Root__c, 'Expected PatronRoot to be "PR124" but got ' + acc.Patron_Root__c);
        System.assertEquals('NA124', acc.National_Account__c, 'Expected NationalAccount to be "NA124" but got ' + acc.National_Account__c);
        System.assertEquals(200, acc.Party_Score__c, 'Expected PartyScore to be 200 but got ' + acc.Party_Score__c);
        System.assertEquals('LE124', acc.LE1_Code__c, 'Expected LE1Code to be "LE124" but got ' + acc.LE1_Code__c);
        System.assertEquals('TAX124', acc.Tax_Id__c, 'Expected TaxId to be "TAX124" but got ' + acc.Tax_Id__c);
        System.assertEquals('TS', acc.Care_of_Name__c, 'Expected CareOfName to be "TS" but got ' + acc.Care_of_Name__c);

    }
}