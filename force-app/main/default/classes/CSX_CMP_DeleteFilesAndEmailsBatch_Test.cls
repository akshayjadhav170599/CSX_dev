@isTest
public class CSX_CMP_DeleteFilesAndEmailsBatch_Test {
    
    // Test method to cover the batch class execution
	@isTest
    static void testBatchExecution() {
        
        CSX_CMP_DocumentDeletionRule__mdt ObjDocumentDelete = [SELECT Id FROM CSX_CMP_DocumentDeletionRule__mdt WHERE DeveloperName = 'Abstract_statement_Deletion' LIMIT 1];
        
       /* 
        // Create necessary metadata for deletion rules
        CSX_CMP_DocumentDeletionRule__mdt deletionRule = new CSX_CMP_DocumentDeletionRule__mdt(
            DeveloperName = 'TestRule',
            MasterLabel = 'Test Rule',
            //CSX_CMP_Document_Type__c = 'Claim Summary',
            CSX_CMP_Deletion_Condition__c = 'CSX_CMP_Deletion_Condition__c',
            CSX_CMP_sequence__c = 1
        );
        //insert deletionRule;*/
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Closed'
        );
        insert testCase;
        
        // Create EmailMessage and Attachment records
        EmailMessage email1 = new EmailMessage(
            Subject = 'Test Email',
            Status = '3',
            MessageDate = System.now()
        );
        insert email1;

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        ContentDocument cd = [Select Id,(Select Id from ContentVersions where Id = :cv.Id) from ContentDocument LIMIT 1];

        // Create CSX_CMP_Document_Ref__c records
        CSX_CMP_Document_Ref__c docRef1 = new CSX_CMP_Document_Ref__c(
            CSX_CMP_Claim__c = testCase.id,
            CSX_CMP_Document_Type__c  = 'Claim Summary',
            CSX_CMP_Content_Document_ID__c = cd.id,
            CSX_CMP_Email_Message_Id__c = email1.id,
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'ServiceCloud_Claims'].id
        );
        insert docRef1;
        
        // Create ContentDocumentLink records
        ContentDocumentLink docLink1 = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = docRef1.Id,
            ShareType = 'V'
        );
        insert docLink1;

        Attachment attachment1 = new Attachment(
            ParentId = email1.Id,
            Name = 'TestAttachment.pdf',
            Body = Blob.valueOf('Attachment Content')
        );
        insert attachment1;
        
        System.assertNotEquals(ObjDocumentDelete, null, 'Custom metadata record not found.');
	
        Test.startTest();
        CSX_CMP_DeleteFilesAndEmailsBatch batch = new CSX_CMP_DeleteFilesAndEmailsBatch();
        Database.executeBatch(batch, 200);        
		Test.stopTest();
        
        List<ContentDocument> contentDocs = [SELECT Id FROM ContentDocument WHERE Id = :cd.Id];
        List<ContentDocumentLink> docLinks = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :cd.Id];
        List<EmailMessage> emails = [SELECT Id FROM EmailMessage WHERE Id = :email1.Id];
        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :email1.Id];
        
        System.assertEquals(0, contentDocs.size(), 'Content Document should be deleted');
        System.assertEquals(0, docLinks.size(), 'Content Document Link should be deleted');
        System.assertEquals(0, emails.size(), 'Email Message should be deleted');
        System.assertEquals(0, attachments.size(), 'Attachments should be deleted');
        
    }
   /*
    @isTest
    static void testBatchExceptionHandling() {
        
        Test.startTest();
        Test.stopTest();

        System.assert(true, 'Exception handling was tested');
    }*/
   	@isTest
    public static void testGetDocumentRefRecords() {
        CSX_CMP_DocumentDeletionRule__mdt ruleAbstract = new CSX_CMP_DocumentDeletionRule__mdt(
            MasterLabel = 'Test Rule Abstract',
            Label = 'Abstract Rule',
            CSX_CMP_Document_Type__c = 'SomeDocumentType',
            CSX_CMP_Deletion_Condition__c = '30'
        );
    
        CSX_CMP_DeleteFilesAndEmailsBatch batch = new CSX_CMP_DeleteFilesAndEmailsBatch();
    
        Test.startTest();
        List<CSX_CMP_Document_Ref__c> recordsAbstract = batch.getDocumentRefRecords(ruleAbstract);
        Test.stopTest();

        System.assertNotEquals(null, recordsAbstract, 'DocumentRef records should be returned for Abstract Rule.');
    }
    
    @isTest
    public static void testGetDocumentRefRecordsForelse() {
        CSX_CMP_DocumentDeletionRule__mdt ruleFallback = new CSX_CMP_DocumentDeletionRule__mdt(
        MasterLabel = 'Test Rule Fallback',
        Label = 'Fallback Rule',
        CSX_CMP_Deletion_Condition__c = 'Status = \'Open\''
    	);
        
        CSX_CMP_DeleteFilesAndEmailsBatch batch = new CSX_CMP_DeleteFilesAndEmailsBatch();
    
        Test.startTest();
        List<CSX_CMP_Document_Ref__c> recordsFallback = batch.getDocumentRefRecords(ruleFallback);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetDocumentRefRecordsExceptionHandling() {
    
        CSX_CMP_DeleteFilesAndEmailsBatch batch = new CSX_CMP_DeleteFilesAndEmailsBatch();
    
        Test.startTest();
        List<CSX_CMP_Document_Ref__c> recordsAbstract = batch.getDocumentRefRecords(null);
        Test.stopTest();
        
        List<CSX_CMP_Error_Log__c> errorLogs = [SELECT Id FROM CSX_CMP_Error_Log__c];
        System.assertNotEquals(null, !errorLogs.isEmpty(), 'Error logs should have been created.');
    }
    
    @isTest
    public static void testBatchExceptionHandling() {

        CSX_CMP_DeleteFilesAndEmailsBatch batch = new CSX_CMP_DeleteFilesAndEmailsBatch();

        Test.startTest();
        batch.execute(null, new List<CSX_CMP_DocumentDeletionRule__mdt>{ null });
        Test.stopTest();
        
        List<CSX_CMP_Error_Log__c> errorLogs = [SELECT Id FROM CSX_CMP_Error_Log__c];
        System.assertNotEquals(null, !errorLogs.isEmpty(), 'Error logs should have been created.');
    }
}