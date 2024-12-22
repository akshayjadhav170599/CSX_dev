/**
@Author       - Infosys
@Name         - CSX_CMP_ExternalEndPointController_Test
@Created Date - 06/13/2024
@Description  - This test class covers CSX_CMP_ExternalEndPointController class
*/

@isTest
public class CSX_CMP_ExternalEndPointController_Test {

  @isTest
  static void testEndPointLinkExists() {
    // Set up a test custom setting record with the 'ECM' endpoint
      CSX_CMP_External_Page_Endpoints__c testSetting = new CSX_CMP_External_Page_Endpoints__c();
      testSetting.CSX_CMP_ECM_Endpoint__c = 'https://example.com/ecm';
      testSetting.CSX_CMP_MTI_Endpoint__c = 'https://example.com/mit';
      testSetting.CSX_CMP_SEAL_Endpoint__c = 'https://example.com/seal';
      testSetting.CSX_CMP_SIMS_Endpoint__c = 'https://example.com/sims';
      testSetting.CSX_CMP_UMLER_Endpoint__c = 'https://example.com/umler'; 
      insert testSetting;

    // Call the getEndPointLink method
    String endPointLink = CSX_CMP_ExternalEndPointController.getEndPointLink('ECM');

    // Assert the retrieved link matches the expected value
    System.assertEquals(endPointLink, 'https://example.com/ecm', 'The endpoint link for ECM should be https://example.com/ecm');
  }

  @isTest
  static void testEndPointLinkNotFound() {
    // Call the getEndPointLink method with a non-existent endpoint
    String endPointLink = CSX_CMP_ExternalEndPointController.getEndPointLink('NON_EXISTENT');

    // Assert the returned value is null (or empty string depending on implementation)
    System.assertEquals(endPointLink, null, 'The endpoint link for a non-existent endpoint should return null.');
  }
}


/*@isTest
private class CSX_CMP_ExternalEndPointController_Test {
    
    //This test method calls the getEndPointLink() method of the CSX_CMP_ExternalEndPointController class with 'ECM' 
	  //as the endpoint name, and asserts that the returned endpoint link matches the expected value ('TestValue')
    @isTest
    static void TestGetEndPointLink() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            String endPointLink = CSX_CMP_ExternalEndPointController.getEndPointLink('ECM');
            Test.stopTest();
    
            System.assertEquals('TestValue', endPointLink, 'Endpoint link does not match expected value');
        }
    }
     
    //This test method calls the getEndPointLink() method of the CSX_CMP_ExternalEndPointController class with a 
   // non-existent endpoint name and asserts that the returned endpoint link is null
    @isTest
    static void TestGetEndPointLink_NullSetting() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            String endPointLink = CSX_CMP_ExternalEndPointController.getEndPointLink('NonExistentEndpoint');
            Test.stopTest();
    
            System.assertEquals(null, endPointLink, 'Endpoint link should be null for non-existent endpoint');
        }
    } 
    
    //These tests ensure that the getEndPointLink() method of the CSX_CMP_ExternalEndPointController class 
	//correctly retrieves endpoint links from the custom setting and handles non-existent endpoints*/