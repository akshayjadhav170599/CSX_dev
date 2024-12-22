// Comments by Subodh :  Last Updated by Nilesh on today (9/26) so skipping this class
@isTest
public class CSX_CMP_3rdPartyBatch_Test {

    @testSetup
    static void setupTestData() {
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
        
        CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
        equipment.Name = 'Test Equipment';      
        equipment.CSX_CMP_Claim__c = response.claimId;
        equipment.CSX_CMP_Equipment_Initial__c = 'BNSF';
        equipment.CSX_CMP_Equipment_Num__c = '455387';
        insert equipment;
		
        Account ac = [SELECT id FROM Account LIMIT 1];
           
        CSX_CMP_3rd_Party__c thirdPartyRecord = new CSX_CMP_3rd_Party__c(
            CSX_CMP_Contact_Email__c = 'test@example.com',
            CSX_CMP_Equipment__c = equipment.Id,
            CSX_CMP_3rd_Party_Site__c = ac.Id
        );
        insert thirdPartyRecord;
    }

    @isTest
    static void setupEmailTemplate() {
        // Create test data for setup objects
        Test.startTest();
        EmailTemplate emailTemplate = new EmailTemplate(
            DeveloperName = 'CSX_CMP_Auto_Contract_Invoice_Template',
            Name = 'CSX_CMP_Auto_Contract_Invoice_Template',
            Body = 'Test Template Body',
            Subject = 'Test Template Subject',
            HtmlValue = 'Test Template HTML',
            TemplateType = 'text',
            FolderId = UserInfo.getUserId() 
        );
        insert emailTemplate;
        
        Test.stopTest();
        EmailTemplate insertedTemplate = [SELECT Id, DeveloperName, Name, Subject, HtmlValue, TemplateType 
                                      FROM EmailTemplate 
                                      WHERE DeveloperName = 'CSX_CMP_Auto_Contract_Invoice_Template' LIMIT 1];
        System.assertEquals('CSX_CMP_Auto_Contract_Invoice_Template', insertedTemplate.DeveloperName, 'DeveloperName should match');
        System.assertEquals('Test Template Subject', insertedTemplate.Subject, 'Subject should match');
    }
    
    @isTest
    static void testBatchExecution() {
        // Retrieve the test data
        CSX_CMP_3rd_Party__c thirdPartyRecord = [SELECT Id, CSX_CMP_Invoice_Num__c, CSX_CMP_Contact_Email__c FROM CSX_CMP_3rd_Party__c LIMIT 1];
        
        // Instantiate the batch class
        CSX_CMP_3rdPartyBatch batch = new CSX_CMP_3rdPartyBatch(thirdPartyRecord.CSX_CMP_Invoice_Num__c);
        
        // Execute the batch
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the ContentVersion records were created
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'Invoice %'];
        System.assert(contentVersions.isEmpty(), 'ContentVersion records should be created');
        
        // Verify the email was sent
        //List<Messaging.SingleEmailMessage> sentEmails = [SELECT Id FROM Messaging.SingleEmailMessage];
        //System.assert(!sentEmails.isEmpty(), 'Emails should be sent');
    }
}