/*
@author       - Infosys
@name         - CSX_CMP_EmailMsgTriggerHandler_Test
@createdDate  - 06/04/2024
@description  - This class is used to test m,ethods of class CSX_CMP_EmailMsgTriggerHandler .
*/

@isTest
public class CSX_CMP_EmailMsgTriggerHandler_Test {
    
    /* Description : Method to test handle after insert */
    
 @isTest
    static void testHandleAfterInsert() {
        
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;

        EmailMessage emailMsg1 = new EmailMessage(
            Subject = 'Claim Confirmation: Your claim has been processed',
            ParentId = testCase.Id
        );
        EmailMessage emailMsg2 = new EmailMessage(
            Subject = 'Foreign Line Request: Please review',
            ParentId = testCase.Id
        );
        EmailMessage emailMsg3 = new EmailMessage(
            Subject = 'Decline Letter: Application declined',
            ParentId = testCase.Id
        );
        EmailMessage emailMsg4 = new EmailMessage(
            Subject = 'Meeting Schedule',
            ParentId = testCase.Id
        );

        List<EmailMessage> emailMsgList = new List<EmailMessage>{emailMsg1, emailMsg2, emailMsg3, emailMsg4};
        insert emailMsgList;

        // Call the method
        Test.startTest();
        CSX_CMP_EmailMsgTriggerHandler.handleAfterInsert(emailMsgList);
        Test.stopTest();

        // Verify the results
        List<CSX_CMP_Document_Ref__c> docs = [SELECT Id, CSX_CMP_File_Name__c, CSX_CMP_Document_Type__c, CSX_CMP_File_Extension__c, CSX_CMP_Email_Message_Id__c, CSX_CMP_Claim__c FROM CSX_CMP_Document_Ref__c];
        System.assertEquals(8, docs.size(), 'Number of documents created is incorrect');
        System.assertEquals('Claim Confirmation Email', docs[0].CSX_CMP_Document_Type__c, 'Document type for emailMsg1 is incorrect');
        System.assertEquals('FLR Email', docs[1].CSX_CMP_Document_Type__c, 'Document type for emailMsg2 is incorrect');
        System.assertEquals('Decline Email', docs[2].CSX_CMP_Document_Type__c, 'Document type for emailMsg3 is incorrect');
        System.assertEquals('User Email', docs[3].CSX_CMP_Document_Type__c, 'Document type for emailMsg4 is incorrect');
    }
    
    /* Description : Method to test get documment type 1 */
    
    @isTest
    static void testGetDocumentType1() {
        String emailSubject5 = 'Foreign Line Request';
        String result5 = CSX_CMP_EmailMsgTriggerHandler.getDocumentType(emailSubject5);
        System.assertEquals('FLR Email', result5, 'Test Case 4 Failed');
    }
}