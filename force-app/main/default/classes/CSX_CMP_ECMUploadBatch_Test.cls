@isTest
public class CSX_CMP_ECMUploadBatch_Test {
    @isTest
    static void testBatchExecution() {
        Case testCase = new Case(Subject = 'Test Case',type = 'Recharges Outbound Claim');
        insert testCase;
        
       List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 5; i++) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test Document ' + i,
                PathOnClient = 'TestDocument' + i + '.pdf',
                VersionData = Blob.valueOf('Test content ' + i)
            );
            contentVersions.add(cv);
        }
        insert contentVersions;
        
        ContentVersion contentDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions[0].Id];
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'I'
        );
        insert contentDocumentLink;
        
        //List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>{contentDocumentLink};
            List<Id> contentVersionsId = new List<Id>();
        for(ContentVersion cdl :contentVersions ){
            contentVersionsId.add(cdl.id);
        }
        // Execute the batch
        Test.startTest();
            CSX_CMP_ECMUploadBatch batch = new CSX_CMP_ECMUploadBatch(contentVersionsId, false, 'Claim', true);
            Database.executeBatch(batch);
            CSX_CMP_ECMUploadBatch batch1 = new CSX_CMP_ECMUploadBatch(contentVersionsId, True, 'Property Portal', true);
            Database.executeBatch(batch1);
            CSX_CMP_ECMUploadBatch batch2 = new CSX_CMP_ECMUploadBatch(contentVersionsId, True, 'ContentDocument', true);
            Database.executeBatch(batch2);       
        Test.stopTest();
        
        List<ContentVersion> processedContentVersions = [SELECT Id, Title FROM ContentVersion WHERE Id IN :contentVersionsId];
        System.assertEquals(4, processedContentVersions.size(), 'All content versions should be processed.');
        
        
    } 
}