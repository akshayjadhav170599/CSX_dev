/**************************************************************************************
/*
@author             : Infosys
@description        : This is test class for CSX_CMP_LDREmailController

Apex Class Name     : CSX_CMP_LDREmailController_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
public with sharing class CSX_CMP_LDREmailController_Test {
    @TestSetup
    public static void setupTestData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        Map<String,String> lDReport = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
        CSX_CMP_LDRCreationController.createLDReport(ldReport);      
    }
    /* @description : method to get LDR details*/
     @isTest
      static void testldrdetails(){ 
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c  LIMIT 1];
          system.debug('==== '+equipment.id);
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_LDREmailController.CSX_CMP_ldrWrapper response = new CSX_CMP_LDREmailController.CSX_CMP_ldrWrapper();
        System.runAs(user) {            
            Test.startTest();
            CSX_CMP_LDREmailController details = new CSX_CMP_LDREmailController();
            details.caseId = equipment.Id;
        Test.stopTest();
        response = details.ldrWrapper;       
            System.assertNotEquals(null, details, 'The details object should not be null');
        
        }
        
      }
    
    @isTest
    static void testLogoUrl(){
        Organization orgName = [SELECT Id,Name,IsSandbox FROM Organization];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
            Test.startTest();
            String result = CSX_CMP_Utility.logoUrl();
            Document testDocument = [SELECT Id FROM Document WHERE DeveloperName = 'CSX_CMP_Logo'];
            String expectedUrl = URL.getOrgDomainURL().toExternalForm()+'/servlet/servlet.ImageServer?id='+testDocument.Id+'&oid='+orgName.Id;
            Test.stopTest();
            
            //assert
            System.assertEquals(expectedUrl, result, 'The result should match the expected URL');
        }
        
    }
    
}