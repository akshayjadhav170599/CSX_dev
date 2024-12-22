@isTest
private class CSX_CMP_SendCSXClaimNumWebService_Test {
    
    @TestSetup
    static void makeData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueOverchargeClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Case claim = [SELECT Id, Status FROM Case WHERE Id = :response.claimId];	
		claim.Reason='Damaged';
        claim.Type = 'FC RR Inbound Claim';
        claim.CSX_CMP_Claimant_Ref_Num__c = '123';
        claim.CSX_CMP_VIN__c = 'ABC123';
		update claim;
    }
    
    @isTest
    static void testClaimSearchService(){ 
        // Case claim = [SELECT Id FROM Case WHERE Reason = 'Damaged'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1/claim-numbers';
        req.httpMethod = 'GET';
        req.params.put('startDate', '2024-07-01');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // System.StringException ex = new System.StringException('Test String Exception');
        // CSX_CMP_SendCSXClaimNumWebService.ClaimNumResponseWrapper inspectionRecord = new CSX_CMP_SendCSXClaimNumWebService.ClaimNumResponseWrapper();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        //Call the method and simulate a StringException
        
        Test.startTest();
            CSX_CMP_SendCSXClaimNumWebService.searchCSXClaimNumbers();
        Test.stopTest();
		}
        

        // Assert the response properties
        System.assertEquals(500, res.statusCode , 'Expected status code 500'); 
        
        /*List<CSX_CMP_SendCSXClaimNumWebService.ClaimNumResponseWrapper> responseWrapperList = 
            (List<CSX_CMP_SendCSXClaimNumWebService.ClaimNumResponseWrapper>)JSON.deserialize(
                res.responseBody.toString(),
                List<CSX_CMP_SendCSXClaimNumWebService.ClaimNumResponseWrapper>.class
            );*/
       
        //System.assertEquals(null, responseWrapperList, 'Response list should not be null');
    }
    
    @isTest
    static void testClaimSearchServiceWithNoResults(){  // expecting empty response
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
         
        req.requestURI = '/services/apexrest/v1/claim-numbers';
        req.httpMethod = 'GET';
        req.params.put('endDate', '2024-07-02');
        
        RestContext.request = req;
        RestContext.response = res;
         
        system.Test.startTest();
        CSX_CMP_SendCSXClaimNumWebService.searchCSXClaimNumbers();
        system.Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Expected status code 500');
       // System.assertEquals('{"error" : "Results not found"}', res.responseBody.toString(), 'Expected response for no results');
    }
    
    @isTest
    static void testClaimSearchServiceWithInvalidNumberOfDays(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
         
        req.requestURI = '/services/apexrest/v1/claim-numbers';
        req.httpMethod = 'GET';
        req.params.put('numberOfDays','invalid');
        
        RestContext.request = req;
        RestContext.response = res;     
            
        system.Test.startTest();
        CSX_CMP_SendCSXClaimNumWebService.searchCSXClaimNumbers();  
        system.Test.stopTest(); 
        
        System.assertNotEquals(500, res.statusCode, 'Expected status code 400 for invalid input');   
       
    }
}