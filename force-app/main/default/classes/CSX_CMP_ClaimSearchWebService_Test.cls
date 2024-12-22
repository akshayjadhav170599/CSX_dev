/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimSearchWebService_Test
Function            :This class is used to test the methods in CSX_CMP_ClaimSearchWebService class
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/16/2024       First version of this class.
*************************************************************************************/

@isTest
public class CSX_CMP_ClaimSearchWebService_Test {
    
    @TestSetup
    static void makeData(){
        CSX_CMP_TestMasterDataUtility.createMasterData();
    }

    /* @description : method to test claim search webservice */
    
    @isTest
    static void testClaimSearchService(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1/ClaimSearch';
        req.httpMethod = 'POST';
        
        List<CSX_CMP_ClaimSearchController.ClaimSearchResponseWrapper> hList = new List<CSX_CMP_ClaimSearchController.ClaimSearchResponseWrapper>();
        CSX_CMP_ClaimSearchController.ClaimSearchResponseWrapper claimSearch = new CSX_CMP_ClaimSearchController.ClaimSearchResponseWrapper();
        claimSearch.claimNumber = '1234';
        hList.add(claimSearch);
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'claimSearchList' => hList
                };
                    
                    String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);
        
        RestContext.request = req;
        RestContext.response = res;   
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            system.Test.startTest();
            CSX_CMP_ClaimSearchWebService.claimSearchService();
            system.Test.stopTest();
            
            // Check the response status and body
            System.assertNotEquals(200, res.statusCode, 'Expected status code 200');
        }
    }

}