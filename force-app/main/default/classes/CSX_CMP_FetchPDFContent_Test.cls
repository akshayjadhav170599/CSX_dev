/*
RICEF ID : CMP-I-1743
Apex Class Name : CSX_CMP_FetchPDFContent
@author : Infosys
@description : This class is used to test the methods in CSX_CMP_FetchPDFContent.
*/

@isTest
public class CSX_CMP_FetchPDFContent_Test {
    
    @testSetup
    static void setupTestData() {
        CSX_CMP_TestMasterDataUtility.createMasterData();
       
       // Creating Account record with specified external ID
        Account account = new Account();
        account.Name = 'Burlington Northern Santa Fe';
        account.CSX_CMP_External_ID__c = 'burlingtonnorthernsantafe';
        insert account;
        
        //Creating Freight Claim
        Map<String, String> freightRequestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper freightResponse = CSX_CMP_ClaimCreationController.createNewClaim(freightRequestJSON, null);
        
        //Creating CSX_CMP_AR_Settlement__c
        CSX_CMP_AR_Settlement__c arSettlement = CSX_CMP_TestUtility.generateARSettlement();
        arSettlement.CSX_CMP_Claim__c = freightResponse.claimId;
        insert arSettlement;
        
        Map<String, String> request = CSX_CMP_TestUtility.newLDReportCreationRequest('In transit');
        request.put('damageReason', 'I-Broken bands');
        request.put('cause', 'I-derail');
        CSX_CMP_LDRCreationController.createLDReport(request);
    }
    
    /* @description : method to test fetch details for AR Invoice Report */
    
    @isTest
    static void fetchDetailsARInvoiceReportTest() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = 'services/apexrest/v1/documents/fetch';
            req.httpMethod = 'GET';
            req.params.put('recordId', '1800000494');
            req.params.put('reportType', 'AR Invoice Report');
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_FetchPDFContent.fetchDetails();
            Test.stopTest();
            
            System.assertEquals(200, res.statusCode, 'Status code should be 500');
        }
    }
    
    /* @description : method to test fetch details for Railcar Report */
    
    @isTest
    static void fetchDetailsRailcarReportTest() {
        CSX_CMP_LD_Report__c ldr = [SELECT Id,Name,(SELECT Id, Name FROM Equipments__r) FROM CSX_CMP_LD_Report__c LIMIT 1];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = 'services/apexrest/v1/documents/fetch';
            req.httpMethod = 'GET';
            req.params.put('recordId', ldr.Name + '_' + ldr.Equipments__r[0].Name); 
            req.params.put('reportType', 'RailcarReport');
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_FetchPDFContent.fetchDetails();
            Test.stopTest();
            
            System.assertEquals(200, res.statusCode, 'Status code should be 500');
        }
    }
    
    /* @description : method to test fetch details negatively */
    
    @isTest
    static void fetchDetailsNegativeTest1() {
        CSX_CMP_LD_Report__c ldr = [SELECT Id,Name,(SELECT Id, Name FROM Equipments__r) FROM CSX_CMP_LD_Report__c LIMIT 1];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = 'services/apexrest/v1/documents/fetch';
            req.httpMethod = 'GET';
            req.params.put('reportType', 'RailcarReport');
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_FetchPDFContent.fetchDetails();
            Test.stopTest();
            
            System.assertEquals(400, res.statusCode, 'Status code should be 400');
        }
    }
    
    /* @description : method to test fetch details negatively */
    
    @isTest
    static void fetchDetailsNegativeTest2() {
        CSX_CMP_LD_Report__c ldr = [SELECT Id,Name,(SELECT Id, Name FROM Equipments__r) FROM CSX_CMP_LD_Report__c LIMIT 1];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {  
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = 'services/apexrest/v1/documents/fetch';
            req.httpMethod = 'GET';
            req.params.put('recordId', ldr.Name + '_' + ldr.Equipments__r[0].Name);
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_FetchPDFContent.fetchDetails();
            Test.stopTest();
            
            System.assertEquals(400, res.statusCode, 'Status code should be 400');
        }
    }
}