/*RICEF ID : MR-00501
@author : Infosys
@description : This test class is used to cover CSX_CMP_LOAEmailQueueable class*/

@isTest
public class CSX_CMP_LOAEmailQueueable_Test {
    @testSetup
    static void setup() {
        // Create test data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
        Case claim = [SELECT Id FROM Case WHERE Id = :response.claimId];
        List<EmailMessage> testEmails = new List<EmailMessage>();
        EmailMessage email = new EmailMessage(
            Subject = 'LOA letter',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            TextBody = 'This is a test email body.',
            HtmlBody = '<p>This is a test email body.</p>',
            ParentId = claim.Id
        );
        testEmails.add(email);
        insert testEmails;
    }
    
    @isTest
    static void testExecute() {
        Set<Id> loaClaimIds = new Set<Id>();
        for (EmailMessage email : [SELECT ParentId FROM EmailMessage WHERE Subject LIKE '%LOA letter%' LIMIT 200]) {
            loaClaimIds.add(email.ParentId);
        }
        
        CSX_CMP_LOAEmailQueueable queueable = new CSX_CMP_LOAEmailQueueable(loaClaimIds);
        
        // Execute the Queueable class
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Completed'];
        System.assert(jobs.size() > 0, 'Queueable job should have been executed.');
    }
}