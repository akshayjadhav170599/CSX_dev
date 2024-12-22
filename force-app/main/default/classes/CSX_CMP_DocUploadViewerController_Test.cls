@isTest
public class CSX_CMP_DocUploadViewerController_Test {
    
     @TestSetup
    static void setupTestData() {
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;
        
        // Create test data for Equipment (child of Case)
        CSX_CMP_Equipment__c testEquipment = new CSX_CMP_Equipment__c(
            Name = 'Equipment123',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = testCase.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420'
        );
        insert testEquipment;
        
        CSX_CMP_Notes__c testNote = new CSX_CMP_Notes__c(
        CSX_CMP_Note_Type__c = 'Comment',
        CSX_CMP_Notes__c = 'demo',
        CSX_CMP_Claim__c = testCase.Id
        );
        insert testNote;

        // Create test data for CSX_CMP_LD_Report__c
        CSX_CMP_LD_Report__c testLDReport = new CSX_CMP_LD_Report__c(
            Name = 'LD12345',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'CSX_CMP_LD_Report__c' LIMIT 1].Id,
            CSX_CMP_Incident_Comments__c = 'Test Incident Comments',
            CSX_CMP_LD_Type__c = 'In transit',
            CSX_CMP_Cause__c = 'AWAITING EMPTY',
            CSX_CMP_Incident_Action__c = 'Lading Recovery',
            CSX_CMP_Damage_Reason__c = 'Damage'
        );
        insert testLDReport;
        
        CSX_CMP_Equipment__c testEquipment2 = new CSX_CMP_Equipment__c(
            Name = 'Equipment321',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_LD_Report__c = testLDReport.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420'
        );
        insert testEquipment2;

        // Create CSX_CMP_Document_Ref__c mock record
        CSX_CMP_Document_Ref__c docRef = new CSX_CMP_Document_Ref__c(
            CSX_CMP_File_Name__c = 'Test Document',
            CSX_CMP_File_Extension__c = 'pdf',
            CSX_CMP_Content_Document_ID__c = null,
            CSX_CMP_ContentVersionID__c = null
        );
        insert docRef;
    }
    
    @isTest
    static void testFetchDataWithCase() {
        // Fetch test Case record
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        CSX_CMP_DocumentUploadViewerController.ScreenData result = CSX_CMP_DocumentUploadViewerController.fetchData(testCase.Id);
        Test.stopTest();

        // Assert that the result is populated
        System.assertNotEquals(null, result,'Fetch the data of case record');
        // System.assertEquals(testCase.Id, result.strID);
        // System.assertEquals('Claim', result.strClaimType);
    }
    
    @isTest
    static void testFetchDataWithLDReport() {
        // Fetch test CSX_CMP_LD_Report__c record
        CSX_CMP_LD_Report__c testLDReport = [SELECT Id FROM CSX_CMP_LD_Report__c LIMIT 1];

        Test.startTest();
        CSX_CMP_DocumentUploadViewerController.ScreenData result = CSX_CMP_DocumentUploadViewerController.fetchData(testLDReport.Id);
        Test.stopTest();

        // Assert that the result is populated
        System.assertNotEquals(null, result,'Fetch the data of LD Report record');
        // System.assertEquals(testLDReport.Id, result.strID);
        // System.assertEquals('Test Incident Comments', result.strComments);
    }
    
    @IsTest
    static void testFileUpload() {
        // Fetch the setup data
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        CSX_CMP_Document_Ref__c docRef = [SELECT Id FROM CSX_CMP_Document_Ref__c LIMIT 1];

        // Prepare mock data for the file upload
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('VGhpcyBpcyBhIHRlc3QgdXBsb2FkIGZpbGU='));
        String filename = 'TestDocument.pdf';
        Boolean isInternalOnly = true;
        Boolean isUploadToECM = false;
        Boolean isReupload = false;
        Boolean isUpload = true;
        String newComments = 'Test comments';
        String contentDocumentId = null;
        String docId = docRef.Id;

        Test.startTest();
        // Call the method to test
        Boolean result = CSX_CMP_DocumentUploadViewerController.fileUpload(
            base64,
            filename,
            testCase.Id,
            isInternalOnly,
            isUploadToECM,
            newComments,
            isReupload,
            isUpload,
            contentDocumentId,
            docId
        );
        Test.stopTest();

        // Assert results
        System.assertEquals(true, result, 'fileUpload should return true');
        
        // Verify the ContentVersion and ContentDocumentLink were created correctly
        ContentVersion cv = [SELECT Id, Title, PathOnClient FROM ContentVersion WHERE Title = :filename LIMIT 1];
        System.assertEquals(filename, cv.Title, 'ContentVersion title should match the filename');
        System.assertEquals(filename, cv.PathOnClient, 'ContentVersion PathOnClient should match the filename');

        // Optionally, verify ContentDocumentLink creation
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testCase.Id LIMIT 1];
        System.assertNotEquals(null, cdl, 'ContentDocumentLink should be created');
        System.assertEquals(testCase.Id, cdl.LinkedEntityId, 'LinkedEntityId should match the parentId');
    }

    @IsTest
    static void testFileUploadWithReupload() {
        // Fetch the setup data
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        CSX_CMP_Document_Ref__c docRef = [SELECT Id FROM CSX_CMP_Document_Ref__c LIMIT 1];

        // Prepare mock data for the file upload
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('Test file content for reupload'));
        String filename = 'TestDocument.pdf';
        Boolean isInternalOnly = true;
        Boolean isUploadToECM = true;
        Boolean isReupload = true;
        Boolean isUpload = true;
        String newComments = 'Test comments for reupload';
        String contentDocumentId = '069O2000003LAsIIAW';
        String docId = docRef.Id;

        Test.startTest();
        // Call the method to test
        Boolean result = CSX_CMP_DocumentUploadViewerController.fileUpload(
            base64,
            filename,
            testCase.Id,
            isInternalOnly,
            isUploadToECM,
            newComments,
            isReupload,
            isUpload,
            contentDocumentId,
            docId
        );
        Test.stopTest();

        // Assert results
        System.assertEquals(true, result, 'fileUpload should return true for reupload');
        
    }

   @IsTest
    static void testDeleteDocument() {
        // Setup test data
         CSX_CMP_Document_Ref__c objDocument = [SELECT Id,CSX_CMP_Content_Document_ID__c FROM CSX_CMP_Document_Ref__c LIMIT 1];
        
        // Setup test data for ContentDocument
        ContentDocument contentDocument = new ContentDocument(
            Id = objDocument.CSX_CMP_Content_Document_ID__c
        );
        //insert contentDocument;
        
        // Call the method
        Test.startTest();
        Boolean result = CSX_CMP_DocumentUploadViewerController.deleteDocument(objDocument.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(true, result,'Record deleted successfully');
        //System.assertEquals(true, contentDocument.size(),'Record deleted successfully');

        List<ContentDocument> deletedContentDocs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocument.Id];  //objDocument.CSX_CMP_Content_Document_ID__c];
        System.assertEquals(0, deletedContentDocs.size(),'Content Document should be deleted');
    }
    
    @IsTest
    static void testDeleteDocumentWithNoContentDocuments() {
        // Setup test data with no ContentDocuments
        CSX_CMP_Document_Ref__c objDocumentRef = new CSX_CMP_Document_Ref__c(
            CSX_CMP_File_Name__c = 'Test Document',
            CSX_CMP_File_Extension__c = 'pdf',
            CSX_CMP_Content_Document_ID__c = 'fkasgidgias', 
            CSX_CMP_ContentVersionID__c = 'dummyConVerId'
        );
        insert objDocumentRef;
        
        // Call the method
        Test.startTest();
        Boolean result = CSX_CMP_DocumentUploadViewerController.deleteDocument(objDocumentRef.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(true, result,'Record deleted successfully');
        
        // Verify the custom document record is deleted
        CSX_CMP_Document_Ref__c[] deletedDocRefs = [SELECT Id FROM CSX_CMP_Document_Ref__c WHERE Id = :objDocumentRef.Id];
        System.assertEquals(0, deletedDocRefs.size(), 'Document reference should be deleted.');
        
        List<ContentDocument> deletedContentDocs = [SELECT Id FROM ContentDocument WHERE Id = :objDocumentRef.CSX_CMP_Content_Document_ID__c];
        System.assertEquals(0, deletedContentDocs.size(), 'Content Document should be deleted');
    }
    
    @isTest
    static void testGetDocuments() {
        // Fetch test Case record
        Case testCase = [SELECT id FROM Case LIMIT 1];
        CSX_CMP_LD_Report__c testLDReport = [SELECT Id FROM CSX_CMP_LD_Report__c LIMIT 1];

        Test.startTest();
        List<CSX_CMP_Document_Ref__c> result1 = CSX_CMP_DocumentUploadViewerController.getDocuments(testCase.Id);
        List<CSX_CMP_Document_Ref__c> result2 = CSX_CMP_DocumentUploadViewerController.getDocuments(testLDReport.Id);
        Test.stopTest();

        // Assert that the documents are retrieved
        System.assertNotEquals(null, result1,'Fetches the case related document');
        System.assertNotEquals(null, result2,'Fetches the LD report related document');
        
    }

}