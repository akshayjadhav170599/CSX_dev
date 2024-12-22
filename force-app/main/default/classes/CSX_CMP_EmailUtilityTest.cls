/**
@Author       - Infosys
@Name         - CSX_CMP_EmailUtility_Test
@Created Date - 5/21/2024
@Description  - These class is used to test the send the emails.
@RICEFW reference - Reusable Apex Utility
*/
@isTest
public class CSX_CMP_EmailUtilityTest {
    @TestSetup
    static void setupdata(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
    }
    
    @isTest
    static void testSendVisualForceTemplateEmailWithPDF() {
        // Create test data
        case claim = [SELECT Id from case LIMIT 1];  
        CSX_CMP_EmailUtility.EmailRequestWrapper emailRequest = new CSX_CMP_EmailUtility.EmailRequestWrapper();
        emailRequest.sourceRecordId = claim.id;
        emailRequest.templateDeveloperName = 'Test_Template';
        emailRequest.pdfVFPageName = 'TestVFPage';
        emailRequest.attachmentFileName = 'TestAttachment.pdf';
        emailRequest.emailTemplateId = claim.id;
        emailRequest.toEmailIdList = new List<String>{'test@example.com'};
        emailRequest.ccEmailIdList = new List<String>{'cc@example.com'};
        emailRequest.subject = 'Test Subject';


        Test.startTest();
        Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(emailRequest);
        Test.stopTest();
        
            }
    @isTest
    static void testSendVisualForceTemplateEmail() {
        // Create test data
        case claim = [SELECT Id from case LIMIT 1];  
        CSX_CMP_EmailUtility.EmailRequestWrapper emailRequest = new CSX_CMP_EmailUtility.EmailRequestWrapper();
        emailRequest.sourceRecordId = claim.id;
        emailRequest.pdfVFPageName = 'TestVFPage';
        emailRequest.emailTemplateId = null;
        emailRequest.toEmailIdList = new List<String>{'test@example.com'};
        emailRequest.ccEmailIdList = new List<String>{'cc@example.com'};
        emailRequest.whoId = claim.id;
        emailRequest.toEmailIdList = new List<String>{'test@example.com'};
        emailRequest.subject = 'Test Subject';
        emailRequest.templateDeveloperName = 'Akshay Jadhav';
        emailRequest.setOrgWideEmailAddressId = '';
        
        
        Test.startTest();
        Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailRequest);
        Test.stopTest();
        
            }

}