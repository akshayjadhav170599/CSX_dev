/**
@Author       - Infosys
@Name         - CSX_CMP_fetchInvoiceWebservice_Test
@Created Date - 5/21/2024
@Description  - These class is used to test the methods in CSX_CMP_FetchInvoiceWebservice class.
@RICEFW reference - CMP-I-0909
*/

@isTest
public class CSX_CMP_FetchInvoiceWebservice_Test {
    
    @TestSetup
    static void makeData(){
          // Creating Freight Claim
        CSX_CMP_TestMasterDataUtility.createMasterData();
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c =: response.claimId LIMIT 1];
        
        Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;
        
          // Inserting AR Settlement record
        CSX_CMP_AR_Settlement__c objSettlement = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement.CSX_CMP_Claim__c = response.claimId;
        Insert objSettlement;
        
         // Inserting 3rd party record
        CSX_CMP_3rd_Party__c thirdparty = new CSX_CMP_3rd_Party__c(
            CSX_CMP_Equipment__c = equipment.id,
            CSX_CMP_AR_Settlement__c = objSettlement.Id,
            CSX_CMP_Incident_Location__c = 'Incident Location',
            CSX_CMP_Amount__c = 50,
          //  CSX_CMP_Party_Name__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount'),
            CSX_CMP_3rd_Party_Site__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount')
        );
        insert thirdparty;
    }
    
    /* @description : method to test Webservice for ShipCSX to fetch 3rd party contractor invoices */
    
    @isTest
    static void testfetchInvoicewebservice(){
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        Map<string,Object> invoiceMap =new Map<string,Object>();
        invoiceMap.put('customerNumber',new list<string>{'1000020957'});
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/v1/automotive-contractor-invoices/search';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(Json.serialize(invoiceMap));
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_FetchInvoiceWebservice.fetchinvoiceDetails();
            Test.stopTest();
            System.assertNotEquals(null,res.responseBody.toString(), 'Response body should not be null');
        }
    }
}