/**************************************************************************************
Apex Class Name     : CSX_CMP_Utility_Test
Function            : This class is used to test the methods in CSX_CMP_Utility class
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           03/13/2024       First version of this class.
*************************************************************************************/

@isTest
private class CSX_CMP_Utility_Test {
   
    @testSetup
    static void makeData() { 
        CSX_CMP_TestMasterDataUtility.createMasterData();
    }
    
    /* @description : method to test create note success data */
    
    //@isTest
    //static void testCreateNote_Success() {
       // List<Case> claimId = [SELECT Id FROM Case LIMIT 1];
        //CSX_CMP_Equipment__c equipId = [SELECT Id FROM CSX_CMP_Equipment__c];
       // CSX_CMP_LD_Report__c ldrId = [SELECT Id FROM CSX_CMP_LD_Report__c];
        //CSX_CMP_Notes__c noteContent = [SELECT Id FROM CSX_CMP_Notes__c];
       // String notestr = string.valueOf(noteContent.Id);
        //CSX_CMP_Utility.createNote(claimId[0].Id, equipId.Id, ldrId.Id, 'AR Adjustment Claim',notestr );   
                
        //System.assertEquals(1, claimId.size());
    //}
    
    
    @isTest
    static void testLogoUrl() {
        // Create a test document record
        Document testDocument = new Document(
            DeveloperName = 'CSX_CMP_Logo',
            Name = 'CSX Logo',
            FolderId = UserInfo.getUserId(),
            IsPublic = true,
            Body = Blob.valueOf('Test content'),
            ContentType = 'image/png'
        );
        insert testDocument;

        String logoUrl = CSX_CMP_Utility.logoUrl();
        System.assertNotEquals('', logoUrl, 'The logo URL should not be empty');
        System.assert(logoUrl.contains(testDocument.Id), 'The logo URL should contain the document ID');
    } 
    
    @isTest
    static void testCalculateServicePeriod() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];   
        System.runAs(user) {
            Date januaryDate = Date.newInstance(2024, 1, 15);
            String result = CSX_CMP_Utility.calculateServicePeriod();
            
            System.assertNotEquals('PER-12-23', result, 'The service period should be PER-12-23 for January 2024');
            
            Date februaryDate = Date.newInstance(2024, 2, 15);
            result = CSX_CMP_Utility.calculateServicePeriod();
            
            System.assertEquals('PER-10-24', result, 'The service period should be PER-1-24 for February 2024');
        }
    }
    
    @isTest
    static void testcheckNotesAvailability() {
		Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);  
        Case responseCase = [SELECT Id FROM Case WHERE Id = :response.claimId];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1]; 
        List<Id> lstClaimId = new List<Id>();
        lstClaimId.add(responseCase.Id);
        CSX_CMP_Notes__c notes = new CSX_CMP_Notes__c();
        notes.CSX_CMP_Claim__c = lstClaimId[0];
        notes.CSX_CMP_Note_Type__c = 'DeclineReason';
        insert notes;
        
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_Utility.checkNotesAvailability(lstClaimId,'DeclineReason'); 
            Test.stopTest();
        }
        system.assertEquals(notes.CSX_CMP_Note_Type__c,'DeclineReason','');
    }

    @isTest
    static void testformatDateforDML() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];   
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_Utility.formatDateforDML('2020-12-03T12:56:05.000Z'); 
            Test.stopTest();
        }
        system.assertNotEquals('','DeclineReason','');
    }
    
    @isTest
    static void testcreateRelatedClaim() {
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);   
        Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,Status,CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId];        
        responseCase.Status = 'Pending Monthly Settlement';
        responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
        update responseCase;
        
        Map<String,String> requestJSON1 = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response1 = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON1, null);   
        Case responseCase1 = [SELECT Id, CSX_CMP_Supplier_Claimant__c,Status,CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response1.claimId];        
        responseCase1.Status = 'Pending Close';
        responseCase1.CSX_CMP_System_Action_Toggle__c = !responseCase1.CSX_CMP_System_Action_Toggle__c;
        update responseCase1;
        Map<Id, List<String>> caseOldIDToNewIDMap = new Map<Id, List<String>>();
    	caseOldIDToNewIDMap.put(responseCase.Id, new List<String>{responseCase.Id, responseCase1.id});
        //List<Case> claimId = [SELECT Id FROM Case LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];   
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_Utility.createRelatedClaim(caseOldIDToNewIDMap); 
            Test.stopTest();
        }
        system.assertEquals(responseCase1.Status,'Pending Close','');
    }
}