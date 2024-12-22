@isTest
public class CSX_CMP_FLDXOutboundWebHelper_Test {
    @testSetup
    static void makeData() {
        CSX_CMP_TestMasterDataUtility.createMasterData();
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
        requestMapAny.put('claimType', 'FC RR Inbound Claim');
        requestMapAny.put('source', 'Customer Service');
        requestJSON = JSON.serialize(requestMapAny);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/claims/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        CSX_CMP_ClaimCreateWebService.claimCreateService();
    }
    
    @isTest
    static void testFLDXOutboundService() {
        /*CSX_CMP_Equipment__c equipment = [
            SELECT
            Id,
            (
                SELECT
                id,
                name,
                CSX_CMP_Code__c,
                CSX_CMP_Miles__c,
                CSX_CMP_Equipment__c,
                CSX_CMP_Manual_Adj_Amt__c,
                CSX_CMP_Distribution_Claim__c,
                CSX_CMP_Calculated_Amount__c
                FROM Distributions__r
            )
            FROM CSX_CMP_Equipment__c
            LIMIT 1
        ];*/
        String sourceId = [SELECT Id FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1].Id;
        String data = '{"comment":"Test"}';
        CSX_CMP_RechargeClaimCreationController.createRechargeClaim(sourceId, data);
        
        Case claim = [
            SELECT Id, CSX_CMP_Claim_Amount__c, CSX_CMP_System_Action_Toggle__c, status,CSX_CMP_Service_Period__c
            FROM Case
            WHERE Type = 'Recharges Outbound Claim'
            LIMIT 1
        ];
        claim.CSX_CMP_Service_Period__c = 'PER-5-24';
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
        update claim;
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            request.requestURI = '/services/apexrest/v1/fldx-outbound-claims/fetch';
            request.httpMethod = 'GET';
            string servicePeriod = 'PER-5-24';
            request.addParameter('servicePeriod', servicePeriod);
            
            RestContext.request = request;
            RestContext.response = response;
            CSX_CMP_FLDXOutboundWebService.getOutboundClaimRecords();
            Test.stopTest();
            CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper responseWrapper = (CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(),
                CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper.class
            );
            system.assertNotEquals(null, responseWrapper, 'Response should not be null as claim is created above');
            system.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200 as data is returned');
        }
    }
}