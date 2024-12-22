/**************************************************************************************
/*
@author             : Infosys
@description        : This is a test class for CSX_CMP_ClaimSummaryEmailController class.
Apex Class Name     : CSX_CMP_ClaimSummaryEmailController_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_ClaimSummaryEmailController_Test {
    
    
    @TestSetup
    static void makeTestData() { 
        
        CSX_CMP_TestMasterDataUtility.createMasterData();   
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        
        // Inserting new Revenue RailRoad Claim
        Map<String,String> requestJSON1 = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response1 = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON1, null);
        
        // CSX_CMP_Claim_Line__c claimline = new CSX_CMP_Claim_Line__c();
        // claimline.CSX_CMP_Claim__c = response1.claimId;
        // claimline.CSX_CMP_Act_Destination_City__c = 'NY';
        // claimline.CSX_CMP_Act_Destination_State__c = 'Washington';
        // claimline.CSX_CMP_Original_Amount__c = 10000;
        // insert claimline;

        CSX_CMP_Product__c product = [SELECT Id FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__r.CSX_CMP_Claim__c =: response.claimId LIMIT 1];
        List<CSX_CMP_Customer_Damage__c> customerDamages = CSX_CMP_TestUtility.createCustomerDamageData(2);
        customerDamages[0].CSX_CMP_Product__c = product.Id;
        customerDamages[1].CSX_CMP_Product__c = product.Id;
        insert customerDamages;
        
        // Insert AP Settlement record
        CSX_CMP_AP_Settlement__c apRecord = CSX_CMP_TestUtility.generateAPSettlement();
        apRecord.CSX_CMP_Claim__c = response.claimId;
        apRecord.CSX_CMP_Amount_Paid__c = 8000;
        apRecord.CSX_CMP_Check_Amount__c = 5700; 
        apRecord.CSX_CMP_Document_Type__c = 'AZ'; 
        insert apRecord; 
        
        CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Adhoc Decline Reason';
        note.CSX_CMP_Claim__c = response.claimId;
        insert note;
        
        CSX_CMP_Notes__c note1 = new CSX_CMP_Notes__c();
        note1.CSX_CMP_Note_Type__c = 'Adhoc Decline Reason';
        note1.CSX_CMP_Claim__c = response1.claimId;
        insert note1;
        
    }
    
    /* @description : These method is used to test the claim email template */
    @isTest
    static void testClaimEmailtemplate() {
        // Query the AP Settlement record
        CSX_CMP_AP_Settlement__c newApRecord = [SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Check_Amount__c FROM CSX_CMP_AP_Settlement__c LIMIT 1];       
        // Query the user
        User user = [SELECT Id FROM User WHERE FirstName = 'Claims' AND LastName = 'Admin' LIMIT 1];       
        // Initialize the email controller and claim wrapper
        CSX_CMP_ClaimSummaryEmailController.ClaimWrapper claimWrapper = new CSX_CMP_ClaimSummaryEmailController.ClaimWrapper();
        
        System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
            Test.startTest();
            
            // Create an instance of the email controller
            CSX_CMP_ClaimSummaryEmailController emailCaseId = new CSX_CMP_ClaimSummaryEmailController();           
            // Assign the case ID from the new AP record
            emailCaseId.caseId = newApRecord.CSX_CMP_Claim__c;           
            // Retrieve the claim wrapper
            claimWrapper = emailCaseId.claimWrapper;
            
            Test.stopTest();
        }
        
        // Assertions
        System.assertNotEquals(null, claimWrapper, 'claimWrapper should not be null');
        System.assertEquals(newApRecord.CSX_CMP_Check_Amount__c, claimWrapper.checkAmount, 'Check Amount should be ' + newApRecord.CSX_CMP_Check_Amount__c);
    }
    
    
    /* @description : These method is used to test the claimLine Details */
    
    @isTest
    static void testClaimLineEmailtemplate() {
        // Query the Claim Line record
        CSX_CMP_Claim_Line__c newclaimLine = [SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Original_Amount__c FROM CSX_CMP_Claim_Line__c LIMIT 1];       
        // Query the user
        User user = [SELECT Id FROM User WHERE FirstName = 'Revenue Railroad' AND LastName = 'User' LIMIT 1];       
        // Initialize the email controller and claim line wrapper
        CSX_CMP_ClaimSummaryEmailController.ClaimLineWrapper claimLineWrapper;
        
        System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
            Test.startTest();
            
            // Create an instance of the email controller
            CSX_CMP_ClaimSummaryEmailController emailCaseId1 = new CSX_CMP_ClaimSummaryEmailController();           
            // Assign the case ID from the new Claim Line record
            emailCaseId1.caseId = newclaimLine.CSX_CMP_Claim__c;
            // Retrieve the claim line wrapper
            claimLineWrapper = emailCaseId1.ClaimLineWrapper;
            
            Test.stopTest();
        }
        
        System.assertNotEquals(null, claimLineWrapper, 'claimLineWrapper should not be null');
        System.assertEquals(newclaimLine.CSX_CMP_Original_Amount__c, claimLineWrapper.amountPaid, 'Original Amount should be ' + newclaimLine.CSX_CMP_Original_Amount__c);
    }
    
}