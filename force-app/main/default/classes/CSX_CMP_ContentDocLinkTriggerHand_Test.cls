@isTest
public class CSX_CMP_ContentDocLinkTriggerHand_Test {
    
    /* Description : Method to test get document type */
    
    @isTest
    static void testGetDocumentType() {
        String documentTitle = 'RechargeLetter';
        String result = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle);
        System.assertEquals('Recharge Letter', result, 'Test Case Failed');
        
        String documentTitle1 = 'ClaimSummary';
        String result1 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle1);
        System.assertEquals('Claim Summary', result1, 'Test Case 1 Failed');
        
        String documentTitle2 = 'DISTRIBUTION_STATEMENT';
        String result2 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle2);
        System.assertEquals('Distribution statement', result2, 'Test Case 2 Failed');
        
        String documentTitle3 = 'ABSTRACT_STATEMENT';
        String result3 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle3);
        System.assertEquals('Abstract statement', result3, 'Test Case 3 Failed');
        
        String documentTitle4 = 'Decline';
        String result4 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle4);
        System.assertEquals('Decline Letter', result4, 'Test Case 4 Failed');
        
        String documentTitle5 = 'LOA letter';
        String result5 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle5);
        System.assertEquals('LOA letter', result5, 'Test Case 5 Failed');
        
        String documentTitle6 = 'User Document';
        String result6 = CSX_CMP_ContentDocLinkTriggerHandler.getDocumentType(documentTitle6);
        System.assertEquals('User Document', result6, 'Test Case 6 Failed');
       
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content'),
            CSX_CMP_Email_Message_Id__c = 'someEmailMessageId'
        );
        insert contentVersion;

        ContentVersion contentDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'I'
        );
        insert contentDocumentLink;

        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>{contentDocumentLink};

        Test.startTest();
        CSX_CMP_ContentDocLinkTriggerHandler.handleAfterInsert(cdlList);
        Test.stopTest();

        List<CSX_CMP_Document_Ref__c> docs = [SELECT Id, CSX_CMP_File_Name__c, CSX_CMP_Document_Type__c, CSX_CMP_File_Extension__c, CSX_CMP_Content_Document_ID__c, CSX_CMP_ContentVersionID__c, CSX_CMP_Claim__c FROM CSX_CMP_Document_Ref__c];
        System.assertNotEquals(1, docs.size(), 'Number of documents created is incorrect');
        System.assertEquals('Test Document', docs[0].CSX_CMP_File_Name__c, 'Document file name is incorrect');
        System.assertEquals('pdf', docs[0].CSX_CMP_File_Extension__c, 'Document file extension is incorrect');
        System.assertEquals(contentDocument.ContentDocumentId, docs[0].CSX_CMP_Content_Document_ID__c, 'Content Document ID is incorrect');
        System.assertEquals(contentVersion.Id, docs[0].CSX_CMP_ContentVersionID__c, 'Content Version ID is incorrect');
        System.assertEquals(testCase.Id, docs[0].CSX_CMP_Claim__c, 'Claim ID is incorrect');
    }
}