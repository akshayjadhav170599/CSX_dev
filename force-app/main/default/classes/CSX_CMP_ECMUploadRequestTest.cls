@isTest
public class CSX_CMP_ECMUploadRequestTest {
    @isTest
    static void testGenerateECMRequest() {
        // Create a test instance of ECMRequestWrapper
        CSX_CMP_InterfaceUtility.ECMRequestWrapper reqWrap = new CSX_CMP_InterfaceUtility.ECMRequestWrapper();
        reqWrap.dDocName = 'TestDocName';
        reqWrap.dDocTitle = 'TestDocTitle';
        reqWrap.dDocType = 'TestDocType';
        reqWrap.dDocAuthor = 'TestDocAuthor';
        reqWrap.dSecurityGroup = 'TestSecurityGroup';
        reqWrap.dDocAccount = 'TestDocAccount';
        reqWrap.xRMProfileTrigger = 'TestRMProfileTrigger';
        reqWrap.xCategoryID = 'TestCategoryID';
        reqWrap.xEventNumber = 'TestEventNumber';
        reqWrap.xCarNumber = 'TestCarNumber';
        reqWrap.xCarInitial = 'TestCarInitial';
        reqWrap.xIronMtnBoxNum = 'TestIronMtnBoxNum';
        reqWrap.xCmisAttachment = 'TestCmisAttachment';
        reqWrap.xGroupFour = 'TestGroupFour';
        reqWrap.filePath = 'TestFilePath';

        // Call the method to test
        String jsonRequest = CSX_CMP_ECMUploadRequest.generateECMRequest(reqWrap);

        // Deserialize the JSON request to verify its contents
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRequest);
        List<Object> metadataList = (List<Object>) requestMap.get('metadata');

         // Verify the metadata
        System.assertEquals(14, metadataList.size(), 'Metadata size should be 14.');
        
        Map<String, Object> metadataItem = (Map<String, Object>) metadataList[0];
        System.assertEquals('dDocName', metadataItem.get('name'), 'The name of the first metadata item should be "dDocName".');
        System.assertEquals('TestDocName', metadataItem.get('value'), 'The value of the first metadata item should be "TestDocName".');
        
        metadataItem = (Map<String, Object>) metadataList[1];
        System.assertEquals('dDocTitle', metadataItem.get('name'), 'The name of the second metadata item should be "dDocTitle".');
        System.assertEquals('TestDocTitle', metadataItem.get('value'), 'The value of the second metadata item should be "TestDocTitle".');
        
        metadataItem = (Map<String, Object>) metadataList[2];
        System.assertEquals('dDocType', metadataItem.get('name'), 'The name of the third metadata item should be "dDocType".');
        System.assertEquals('TestDocType', metadataItem.get('value'), 'The value of the third metadata item should be "TestDocType".');
        
        metadataItem = (Map<String, Object>) metadataList[3];
        System.assertEquals('dDocAuthor', metadataItem.get('name'), 'The name of the fourth metadata item should be "dDocAuthor".');
        System.assertEquals('TestDocAuthor', metadataItem.get('value'), 'The value of the fourth metadata item should be "TestDocAuthor".');
        
        metadataItem = (Map<String, Object>) metadataList[4];
        System.assertEquals('dSecurityGroup', metadataItem.get('name'), 'The name of the fifth metadata item should be "dSecurityGroup".');
        System.assertEquals('TestSecurityGroup', metadataItem.get('value'), 'The value of the fifth metadata item should be "TestSecurityGroup".');
        
        metadataItem = (Map<String, Object>) metadataList[5];
        System.assertEquals('dDocAccount', metadataItem.get('name'), 'The name of the sixth metadata item should be "dDocAccount".');
        System.assertEquals('TestDocAccount', metadataItem.get('value'), 'The value of the sixth metadata item should be "TestDocAccount".');
        
        metadataItem = (Map<String, Object>) metadataList[6];
        System.assertEquals('xRMProfileTrigger', metadataItem.get('name'), 'The name of the seventh metadata item should be "xRMProfileTrigger".');
        System.assertEquals('TestRMProfileTrigger', metadataItem.get('value'), 'The value of the seventh metadata item should be "TestRMProfileTrigger".');
        
        metadataItem = (Map<String, Object>) metadataList[7];
        System.assertEquals('xCategoryID', metadataItem.get('name'), 'The name of the eighth metadata item should be "xCategoryID".');
        System.assertEquals('TestCategoryID', metadataItem.get('value'), 'The value of the eighth metadata item should be "TestCategoryID".');
        
        metadataItem = (Map<String, Object>) metadataList[8];
        System.assertEquals('xEventNumber', metadataItem.get('name'), 'The name of the ninth metadata item should be "xEventNumber".');
        System.assertEquals('TestEventNumber', metadataItem.get('value'), 'The value of the ninth metadata item should be "TestEventNumber".');
        
        metadataItem = (Map<String, Object>) metadataList[9];
        System.assertEquals('xCarNumber', metadataItem.get('name'), 'The name of the tenth metadata item should be "xCarNumber".');
        System.assertEquals('TestCarNumber', metadataItem.get('value'), 'The value of the tenth metadata item should be "TestCarNumber".');
        
        metadataItem = (Map<String, Object>) metadataList[10];
        System.assertEquals('xCarInitial', metadataItem.get('name'), 'The name of the eleventh metadata item should be "xCarInitial".');
        System.assertEquals('TestCarInitial', metadataItem.get('value'), 'The value of the eleventh metadata item should be "TestCarInitial".');
        
        metadataItem = (Map<String, Object>) metadataList[11];
        System.assertEquals('xIronMtnBoxNum', metadataItem.get('name'), 'The name of the twelfth metadata item should be "xIronMtnBoxNum".');
        System.assertEquals('TestIronMtnBoxNum', metadataItem.get('value'), 'The value of the twelfth metadata item should be "TestIronMtnBoxNum".');
        
        metadataItem = (Map<String, Object>) metadataList[12];
        System.assertEquals('xCmisAttachment', metadataItem.get('name'), 'The name of the thirteenth metadata item should be "xCmisAttachment".');
        System.assertEquals('TestCmisAttachment', metadataItem.get('value'), 'The value of the thirteenth metadata item should be "TestCmisAttachment".');
        
        metadataItem = (Map<String, Object>) metadataList[13];
        System.assertEquals('xGroupFour', metadataItem.get('name'), 'The name of the fourteenth metadata item should be "xGroupFour".');
        System.assertEquals('TestGroupFour', metadataItem.get('value'), 'The value of the fourteenth metadata item should be "TestGroupFour".');       
        System.assertEquals('TestFilePath', requestMap.get('filePath'), 'The filePath should be "TestFilePath".');
    }
}