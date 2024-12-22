@isTest
public class CSX_CMP_UploadEmailToECMBatch_Test {

@isTest
public static void testUploadEmailToECMBatch() {
		List<EmailMessage> emailMessages = [SELECT Id, Subject, TextBody, CreatedDate, Incoming FROM EmailMessage];
		CSX_CMP_UploadEmailToECMBatch batch = new CSX_CMP_UploadEmailToECMBatch(emailMessages);
		Test.startTest();
		Database.executeBatch(batch);
		Test.stopTest();
		System.assertEquals(0, batch.cvIds.size(), 'Expected 0 CV Ids');
	}   }