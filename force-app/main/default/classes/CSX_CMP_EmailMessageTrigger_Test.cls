/*
@author       - Infosys
@name         - CSX_CMP_EmailMessageTrigger
@createdDate  - 06/04/2024
@description  - This class is used to test methods of class CSX_CMP_EmailMessageTrigger.
*/

@isTest
public class CSX_CMP_EmailMessageTrigger_Test {

    /*Description : Method to test email message insert */
    
    @isTest
    static void testEmailMessageInsert() {
        
        // Create data for InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        //Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		//List<string> emails = new List<string>();
        email.subject = 'Freight Claim Confirmation';
		email.fromAddress = 'akshay.jadhav12@infosys.com';
		email.fromName = 'Kevin Richmond';
        email.htmlBody = '<p>This is a test email body.</p>';
		email.plainTextBody = 'email body';
        
        // Insert the email message
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = email.subject;
        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.TextBody = email.plainTextBody;
        insert emailMessage;
        
        // Assertions to verify the email message was inserted correctly
        EmailMessage insertedEmailMessage = [SELECT Subject, FromAddress, FromName, HtmlBody, TextBody FROM EmailMessage WHERE Id = :emailMessage.Id];
        System.assertEquals('Freight Claim Confirmation', insertedEmailMessage.Subject, 'The subject of the inserted email message does not match.');
        System.assertEquals('akshay.jadhav12@infosys.com', insertedEmailMessage.FromAddress, 'The from address of the inserted email message does not match.');
        System.assertEquals('Kevin Richmond', insertedEmailMessage.FromName, 'The from name of the inserted email message does not match.');
        System.assertEquals('<p>This is a test email body.</p>', insertedEmailMessage.HtmlBody, 'The HTML body of the inserted email message does not match.');
        System.assertEquals('email body', insertedEmailMessage.TextBody, 'The text body of the inserted email message does not match.');
      }
}