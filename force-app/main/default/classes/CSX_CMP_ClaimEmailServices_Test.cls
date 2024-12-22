/**
@Author       - Infosys
@Name         - CSX_CMP_ClaimEmailServices_Test
@Created Date - 5/07/2024
@Description  - This class is used to test the CSX_CMP_ClaimEmailServices class
@RICEFW reference - CMP-I-0879
*/
@istest
public class CSX_CMP_ClaimEmailServices_Test {
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();

        Map<String,String> testFreightData = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(testFreightData,new List<String>()); 

        CSX_CMP_ClaimCreationHelper.sendClaimconfirmationEmail(response.claimId);

	}

	/* @description : Testing email inbound functionality*/
	@isTest
	static void emailServicesTest() {
        Id emailMessageId;
        case response = [SELECT Id,CSX_CMP_Claim_Amount__c FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1];
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		List<string> emails = new List<string>();
        emailMessageId = response.id;
		emails.add('akshay.jadhav12@infosys.com');
		email.subject = 'Freight Claim Confirmation';
		email.fromAddress = 'akshay.jadhav12@infosys.com';
		email.fromName = 'Kevin Richmond';
		email.headers = new List<Messaging.InboundEmail.Header>();
		//assigning the emails to toAddresses
		email.toAddresses = emails;
        email.htmlBody = '<p>This is a test email body.</p>';
		email.plainTextBody = 'email body';
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body = blob.valueOf('my attachment text');
		attachment.fileName = 'textfileone.pdf';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments = new List<Messaging.inboundEmail.BinaryAttachment>{ attachment };
            
		Messaging.InboundEmail.TextAttachment attachments = new Messaging.InboundEmail.TextAttachment();
		attachments.filename = 'textfileone.txt';
		attachments.body = 'Hello CodeLive Viewers two';
		email.textAttachments = new List<Messaging.inboundEmail.TextAttachment>{ attachments };

		

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_ClaimEmailServices testInbound = new CSX_CMP_ClaimEmailServices();
			testInbound.handleInboundEmail(email, env);
			Test.stopTest();
		}

        System.assertNotEquals(null, [SELECT count() FROM EmailMessage],'Email Message should be created');
	}
    @isTest
	static void uploadreplaytoEMCTest() {
        EmailMessage emailMessage = new EmailMessage(
            Subject = 'Test Subject',
            FromAddress = 'akshay.jadhav12@infosys.com',
            ToAddress = 'akshay.jadhav12@infosys.com',
            HtmlBody = '<p>This is a test email body.</p>',
            TextBody = 'This is a test email body.',
            Incoming = true
        );
        insert emailMessage;
        CSX_CMP_ClaimEmailServices emailHandler = new CSX_CMP_ClaimEmailServices();
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
			Test.startTest();
			emailHandler.uploadReplyEmailToECM(emailMessage.id);
			Test.stopTest();
            
            // Add assertion to verify the expected outcome
            EmailMessage processedEmail = [SELECT Id, Status FROM EmailMessage WHERE Id = :emailMessage.Id];
            System.assertEquals(null, processedEmail.Status, 'Email should be 5');
		}
    }
}