@isTest
public class CSX_CMP_SubmitClaimsforApproval_Test {
    
    @isTest
    static void approvalBatchMethod(){
        
        CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c();
        objDesk.Name = 'Desk 3';
        Insert objDesk;
        
        List<id> testCaseLst = new List<Id>();
        Case testCase = new Case();
        testCase.Status='On Hold';
        testCase.Type = 'Incentive Claim';
        testCase.CSX_CMP_Desk_Name__c = objDesk.Id;
        testCase.CSX_CMP_Claim_Amount__c=88;
        testCase.CSX_CMP_Service_Period__c='1233';
        insert testCase;
        testCaseLst.add(testCase.id);
        
        CSX_CMP_SubmitClaimsforApprovalBatch batch = new CSX_CMP_SubmitClaimsforApprovalBatch(testCaseLst);

        // Start the test, execute the batch, and stop the test
        system.Test.startTest();
        Database.executeBatch(batch);
        system.Test.stopTest();

        // Query the claim after the batch job
        Case updatedClaim = [SELECT Id, Status, Type, CSX_CMP_Desk_Name__c, CSX_CMP_Claim_Amount__c FROM Case WHERE Id = :testCase.Id];
        
        System.assertEquals('On Hold', updatedClaim.Status, 'The status of the case after the batch job did match the expected status.');
    }
}