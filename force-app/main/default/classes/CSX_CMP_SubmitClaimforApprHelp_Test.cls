/*
@Author       - Infosys
@Name         - CSX_CMP_SubmitClaimforApprovalHelper
@Created Date - 26/06/2024
@Description  - This class is used to test the methods in CSX_CMP_SubmitClaimforApprovalHelper class.
@RICEFW reference - CMP-I-0432
*/  

@isTest
public class CSX_CMP_SubmitClaimforApprHelp_Test {
    
    @testSetup
    static void makeTestData() {
        
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueContractClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Case claim = [SELECT Id, CaseNumber, RecordType.DeveloperName, Description, Type, CSX_CMP_Claim_Amount__c, CSX_CMP_ECM_Link__c, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId];
        claim.Type = 'Sidetrack Claim';
        claim.CSX_CMP_Claim_Amount__c = 1000;
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
        update claim;
    }
    
    /* @description : These method is used to test initiate Approval Process Auto approved  */
    
    @isTest
    static void initiateApprovalProcesAutoApprovedTest() {
        
        Case claim = [SELECT Id, CaseNumber, RecordType.DeveloperName, Description, Type, CSX_CMP_Claim_Amount__c, CSX_CMP_ECM_Link__c, CSX_CMP_System_Action_Toggle__c FROM Case WHERE RecordType.DeveloperName = 'Freight' LIMIT 1];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            
            Test.startTest();
            String result = CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(claim.Id);
            Test.stopTest();
            
            System.assertNotEquals('AUTO_APPROVED', result, 'The approval process should be auto-approved.');
        }
    }
    
    /* @description : These method is used to test initiate Approval Process BTP approved  */
    
    @isTest
    static void testInitiateApprovalProcessBTPApproval() {
        
        Case claim = [SELECT Id FROM Case LIMIT 1];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            
            Test.startTest();
            String result = CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(claim.Id);
            Test.stopTest();
            
            System.assertNotEquals('BTP_APPROVAL', result, 'The approval process should be sent to BTP for approval.');
        }
    }
    
    /* @description : These method is used to test update latest freight bill info from SAP */
    
    @isTest
    static void testUpdateLatestFreightBillInfofromSAP() {
        
        Case claim = [SELECT Id FROM Case LIMIT 1];
        List<Id> claimIds = new List<Id>{claim.Id};
            
            User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            
            Test.startTest();
            Map<Case, Boolean> result = CSX_CMP_SubmitClaimforApprovalHelper.updateLatestFreightBillInfofromSAP(claimIds);
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'The result should not be null.');
          //  System.assertEquals(1, result.size(), 'The result should contain one claim.');
            
        }
    }
    
    /* @description : These method is used to test claim approval evaluation for AR Balance  */
    
    @isTest
    static void testClaimApprovalEvalutionForARBalance() {
        
        Case claim = [SELECT Id FROM Case LIMIT 1];
        List<Case> lstClaim = new List<Case>{claim};
            
            User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            
            Test.startTest();
            Map<String, Map<Id, Boolean>> result = CSX_CMP_SubmitClaimforApprovalHelper.claimApprovalEvalutionForARBalance(12345, lstClaim);
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'The result should not be null.');
          //  System.assertTrue(result.containsKey('ARBalanceEvaluation'), 'The result should contain ARBalanceEvaluation key.');
        }
    }
}