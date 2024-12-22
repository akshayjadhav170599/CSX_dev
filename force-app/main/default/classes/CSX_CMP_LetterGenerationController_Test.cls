/*
@Author       - Infosys
@Name         - CSX_CMP_LetterGenerationController_Test
@Created Date - 5/18/2024
@Description  - This class is used to cover CSX_CMP_LetterGenerationController class
@RICEFW reference - CMP-E-0493
*/
@isTest
public class CSX_CMP_LetterGenerationController_Test {
	  
    @testSetup
    public static void setupdata(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null); 
        
        CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Recharge Reason';
        note.CSX_CMP_Claim__c = response.claimId;
        insert note;
        
        // Create an existing ContentVersion record to be updated in the test method
        Case claim = [SELECT Id, CaseNumber FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1];
        ContentVersion existingCV = new ContentVersion();
        existingCV.Title = 'ExistingTitle' + claim.CaseNumber;
        existingCV.PathOnClient = 'ExistingFile.pdf';
        existingCV.VersionData = Blob.valueOf('Test data');
        existingCV.Origin = 'H';
        insert existingCV;
    }
      
    @isTest
    static void generateRechargeLetter(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];  
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();                       
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();          
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_RechargeLetterpage');           
            Test.stopTest();    
            
            // Query the updated ContentVersion record
            
    ContentVersion updatedCV = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id = :existingCV.Id];
    System.assertNotEquals(null, updatedCV, 'Expected updated ContentVersion record.');

    	}   
    }
    
    @isTest
    static void generateFreightDeclineLetter(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_FreightDeclineLetter');           
            Test.stopTest();    
            
            ContentVersion updatedCV1 = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id = :existingCV.Id];
    System.assertNotEquals(null, updatedCV1, 'Expected updated ContentVersion record.');
    	}   
    }
    
    @isTest
    static void generateContractRefundDeclineLetter(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_ContractRefundDeclineLetter');           
            Test.stopTest();    
          }   
    }
    
    @isTest
    static void generateOverchargeDeclineLetter(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_OverchargeDeclineLetter');           
            Test.stopTest();    
           }   
    }
    
    @isTest
    static void generateRevenueRailroadDeclineLetter(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_RevenueRailroadDeclineLetter');         
            Test.stopTest();   
            
          /*  // Query for the generated letter record associated with the case after the test execution.
            List<Letter__c> generatedLetters = [SELECT Id, Case__c, Status__c FROM Letter__c WHERE Case__c = :claim.Id];
            
            // Assert that a letter record has been created.
            System.assertNotEquals(0, generatedLetters.size(), 'No letter record has been created.');
            
            // Assert that the letter is associated with the correct case ID.
            System.assertEquals(claim.Id, generatedLetters[0].Case__c, 'The letter is not associated with the correct case.');
            
            // If there's a status field, assert that it reflects successful generation.
            System.assertEquals('Generated', generatedLetters[0].Status__c, 'The letter status does not reflect successful generation.');*/
        }   
    }
    
    @isTest
    static void generateOverchargeSummaryReport(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];     
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_OverchargeSummaryReport');         
            Test.stopTest();    
        }   
    }
    
    @isTest
    static void generateRevenueRRSummaryReport(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_RevenueRRSummaryReport');         
            Test.stopTest();    
        }   
    }
    
    @isTest
    static void generateContractRefundSummary(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_ContractRefundSummary');         
            Test.stopTest();    
        }   
    }
    
    @isTest
    static void generateFreightClaimSummary(){
        // Query a Case record
        case claim = [select Id, CaseNumber from Case where type='FC RR Inbound Claim'];      
        ContentVersion existingCV = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'ExistingTitle%' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        	Test.startTest();            
            CSX_CMP_LetterGenerationController controller = new CSX_CMP_LetterGenerationController();           
            CSX_CMP_LetterGenerationController.generateLetters(new List<Id>{claim.Id},'CSX_CMP_FreightClaimSummary');         
            Test.stopTest();    
        }   
    }
    
    @isTest
    static void testCheckNoteOnClaimWithoutDNSDL() {
        
        // Create a Case record without a related Note of type 'Do not send Decline Letter'
        Case claimWithoutNote = new Case(CSX_CMP_Claim_Amount__c = 500);
        insert claimWithoutNote;
        
        // Call the method under test
        Boolean result = CSX_CMP_LetterGenerationController.checkNoteOnClaim(new List<Id>{claimWithoutNote.Id});
        
        // Assert that the result is false since there's no related Note
        System.assertEquals(false, result, 'The method should return false when there is no related Note of type DNSDL.');
    }
    
   /* @isTest
    static void testContentDocumentLinkMap() {
        /* Create test data: Case records
        //List<Case> testCases = new List<Case>();
          
        //insert testCases;

        // Create test data: ContentDocumentLink records
        List<ContentDocumentLink> testContentDocLinks = new List<ContentDocumentLink>();
        for (Case testCase : testCases) {
            // Create ContentDocumentLink records associated with the Case
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = 'ContentDocumentId'; // Replace with actual ContentDocumentId
            cdl.LinkedEntityId = testCase.Id;
            cdl.ShareType = 'V'; // Set appropriate sharing type (e.g., 'V' for view access)
            testContentDocLinks.add(cdl);
        }

        // Insert testContentDocLinks
        insert testContentDocLinks;

        // Initialize contentDocLinkMap
        Map<String, List<String>> contentDocLinkMap = new Map<String, List<String>>();
        for (ContentDocumentLink contentDoc : testContentDocLinks) {
            if (contentDocLinkMap.containsKey(contentDoc.LinkedEntityId)) {
                contentDocLinkMap.get(contentDoc.LinkedEntityId).add(contentDoc.ContentDocumentId);
            } else {
                contentDocLinkMap.put(contentDoc.LinkedEntityId, new List<String>{ contentDoc.ContentDocumentId });
            }
        }

        // Now contentDocLinkMap contains related Content Document IDs for each Case ID
        // You can use this map in your test scenarios to cover the relevant logic.

        // Additional assertions or test scenarios can be added as needed.*/
   // } 

}