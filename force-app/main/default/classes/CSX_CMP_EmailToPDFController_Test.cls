@isTest
public class CSX_CMP_EmailToPDFController_Test {
    
    @testSetup
    static void setup() {
        
        EmailMessage emailMsg = new EmailMessage(
            Subject = 'Test Subject',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            CcAddress = 'cc@example.com',
            TextBody = 'This is a test email.',
            HtmlBody = '<p>This is a test email.</p>'
        );
        insert emailMsg;
        
        // Create an attachment for the email
        Attachment attachment = new Attachment(
            Name = 'TestAttachment.txt',
            Body = Blob.valueOf('This is a test attachment.'),
            ParentId = emailMsg.Id
        );
        insert attachment;
    }
    
    /* Description : Method to test Email to PDF Controller */
    
    @isTest
    static void testEmailToPDFController() {
        // Retrieve the test email message
        EmailMessage testEmail = [SELECT Id FROM EmailMessage LIMIT 1];
        
        // Set the page parameters
        ApexPages.currentPage().getParameters().put('id', testEmail.Id);
        
        // Create an instance of the controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testEmail);
        CSX_CMP_EmailToPDFController controller = new CSX_CMP_EmailToPDFController(sc);
        
        // Verify the email message was retrieved correctly
        System.assertNotEquals(null, controller.email, 'The email list should not be null.');
        System.assertEquals(1, controller.email.size(), 'The email list should contain exactly one email.');
        System.assertEquals(testEmail.Id, controller.email[0].Id, 'The email Id should match the expected Id.');

    }
    
    /* Description : Method to test exception handling */
    
    @isTest
    static void testExceptionHandling() {
        // Set an invalid page parameter
        ApexPages.currentPage().getParameters().put('id', 'invalidId');
        
        // Create an instance of the controller
        ApexPages.StandardController sc = new ApexPages.StandardController(new EmailMessage());
        CSX_CMP_EmailToPDFController controller = new CSX_CMP_EmailToPDFController(sc);
        
        // Verify that the email list is null due to the exception
		System.assertEquals(0, controller.email.size(), 'The email list should be empty when an invalid Id is passed.');
   
    }
}