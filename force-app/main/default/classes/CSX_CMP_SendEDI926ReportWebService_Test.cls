/**
@Author       - Infosys
@Name         - CSX_CMP_SendEDI926ReportWebService_Test
@Created Date - 5/21/2024
@Description  - These class is used to test Web respone for EDI Claims.
@RICEFW reference - CMP-I-0877
*/
@isTest
public class CSX_CMP_SendEDI926ReportWebService_Test {
   /*  @TestSetup
    static void makeData(){
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        CSX_CMP_TestMasterDataUtility.createMasterData();
        CSX_CMP_EDI926ClaimReport__c EDIReport = new CSX_CMP_EDI926ClaimReport__c();
		EDIReport.CSX_CMP_Segment1__c = '';
        EDIReport.CSX_CMP_Segment2__c = '';
        EDIReport.CSX_CMP_Segment3__c = '';
        EDIReport.CSX_CMP_Segment4__c = '';
        EDIReport.CSX_CMP_Sender_ID__c = '';
        EDIReport.CSX_CMP_Claim__c = response.claimId;
        Insert EDIReport;
        
    }
     /* @description : method to test to get the EDI claim data from EDI 926 claim Report object */
   /* @isTest
    static void testClaimCreateServiceTestForEDICreation(){
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
                RestRequest request = new RestRequest();
                RestResponse response = new RestResponse();
                request.requestURI = '/services/apexrest/v1/claims-status/fetch';
                request.httpMethod = 'GET';
                request.addParameter('fromDate', '');
                RestContext.request = request;
                RestContext.response = response;
                CSX_CMP_SendEDI926ReportWebService.getEDI926Records();
            Test.stopTest();
          //  CSX_CMP_SendEDI926ReportWebService.EDIResponseWrapper responseWrapper = (CSX_CMP_SendEDI926ReportWebService.EDIResponseWrapper) JSON.deserialize(RestContext.response.responseBody.toString(), CSX_CMP_SendEDI926ReportWebService.EDIResponseWrapper.class);
          //  system.assertNotEquals(null, responseWrapper,'Response should not be null as claim is created above');
            system.assertEquals(200, RestContext.response.statusCode,'Status code should be 200 as data is returned');
        }
    
    }*/
    
}