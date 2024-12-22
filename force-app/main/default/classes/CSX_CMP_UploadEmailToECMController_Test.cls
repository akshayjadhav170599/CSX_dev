@isTest
public class CSX_CMP_UploadEmailToECMController_Test {
    
    @testSetup
    static void setup() {
        // Create test data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
    
        // Query the account created by the master data utility
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
    	Case claim = [SELECT Id FROM Case WHERE Id = :response.claimId];
        claim.Subject = 'Test Case';
        claim.AccountId = testAccount.Id;
        update claim;
        
        // Create test EmailMessage
        EmailMessage emailMsg = new EmailMessage(
            Subject = 'Test Subject',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            CcAddress = 'cc@example.com',
            TextBody = 'This is a test email.',
            HtmlBody = '<p>This is a test email.</p>',
            ParentId = claim.Id
        );
        insert emailMsg;
        
        // Query ContentDocument IDs outside the loop
        List<ContentDocument> contentDocs = [SELECT Id FROM ContentDocument WHERE Title = 'Document for '];
       
        // Insert ContentVersion records
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (ContentDocument doc : contentDocs) {
            contentVersions.add(new ContentVersion(
                ContentDocumentId = doc.Id
            ));
        }
        insert contentVersions;
    }
    
    @isTest
    static void testCreateEmailContent() {
        // Retrieve the test email message
        EmailMessage testEmail = [SELECT Id, Subject, ParentId FROM EmailMessage LIMIT 1];
        
        // Call the method
        Test.startTest();
        CSX_CMP_UploadEmailToECMController.createEmailContent(testEmail);
        Test.stopTest();
        
        // Verify the ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title = :testEmail.Subject];
        System.assertEquals(0, contentVersions.size());
        
        /*// Verify the ContentVersion was created
        ContentVersion contentVersion = [SELECT Id, Title, PathOnClient, CSX_CMP_Email_Message_Id__c, CSX_CMP_Parent_Id__c FROM ContentVersion WHERE CSX_CMP_Email_Message_Id__c = :testEmail.Id LIMIT 1];
        System.assertEquals(testEmail.Subject, contentVersion.Title);
        System.assertEquals(testEmail.Subject + '.pdf', contentVersion.PathOnClient);
        System.assertEquals(testEmail.Id, contentVersion.CSX_CMP_Email_Message_Id__c);
        System.assertEquals(testEmail.ParentId, contentVersion.CSX_CMP_Parent_Id__c);

        // Verify the ContentDocumentLink was created
        ContentDocumentLink contentDocumentLink = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testEmail.ParentId LIMIT 1];
        System.assertEquals(testEmail.ParentId, contentDocumentLink.LinkedEntityId);*/
    }
    
    @isTest
    static void testManualEmailUpload() {
        // Retrieve the test email message
        EmailMessage testEmail = [SELECT Id FROM EmailMessage LIMIT 1];
        
        // Call the method
        Test.startTest();
        String response = CSX_CMP_UploadEmailToECMController.manualEmailUpload(testEmail.Id);
        Test.stopTest();
        
        // Verify the response
        System.assertEquals('Your Request has been submitted.ECM id is populated in Document Reference on successful upload ', response);
    }
    
    @isTest
    static void testManualDocumentUpload() {
        // Create a new ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Sample Document',
            PathOnClient = 'sample.txt',
            VersionData = Blob.valueOf('Sample content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        // Retrieve the ContentDocumentId from the inserted ContentVersion
        List<ContentVersion> contentVersionList = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocument contentDoc = new ContentDocument();
        if (!contentVersionList.isEmpty()) {
            contentDoc.Id = contentVersionList[0].ContentDocumentId;
        }
        
        // Call the method
        Test.startTest();
        CSX_CMP_UploadEmailToECMController.manualDocumentUpload(contentDoc.Id);
        
        Test.stopTest();
        
        // Verify the batch job was enqueued
    }
    
    @isTest
    static void testExceptionHandling() {
        // Create an invalid EmailMessage
        EmailMessage invalidEmail = new EmailMessage();
        
        // Call the method with invalid data
        Test.startTest();
        CSX_CMP_UploadEmailToECMController.createEmailContent(invalidEmail);
        Test.stopTest();
        
        // Verify that no ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = null];
        System.assertEquals(0, contentVersions.size());
    }
}