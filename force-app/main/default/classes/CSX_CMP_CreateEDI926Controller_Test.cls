/**
@Author       - Infosys
@Name         - CSX_CMP_CreateEDI926Controller_Test
@Created Date - 5/07/2024
@Description  - These class is used to test the EDI 926 record creation in EDI926ClaimReport object.
@RICEFW reference - CMP-I-0877
*/
@isTest
public class CSX_CMP_CreateEDI926Controller_Test {

    /* 
    @description : method to create test data 
    */
    @TestSetup
    static void makeData(){
        CSX_CMP_TestMasterDataUtility.createMasterData();

        // Creating Freight Claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Case claim = [SELECT Id, RecordType.DeveloperName, Status FROM Case WHERE Id = :response.claimId];
        claim.RecordType.DeveloperName = 'Freight';
		update claim;
        
        CSX_CMP_Decline_Code_Master__c declinecode = new CSX_CMP_Decline_Code_Master__c();
        declinecode.Name = 'AOG-AD';
        declinecode.CSX_CMP_Meaning__c = 'Decline code';
        insert declinecode;

        // Creating AP Settlement
        CSX_CMP_AP_Settlement__c apRecord = CSX_CMP_TestUtility.generateAPSettlement();
        apRecord.CSX_CMP_Claim__c = response.claimId;
        Insert apRecord;
        
        //creating Note 
        CSX_CMP_Notes__c attachnote = new CSX_CMP_Notes__c();
        attachnote.CSX_CMP_Claim__c = response.claimId;
        attachnote.CSX_CMP_Note_Type__c = 'Decline Reason';
        attachnote.CSX_CMP_Notes__c = 'Decline';
        insert attachnote;
    }
    
    /* @description : method to test EDI926 record creation for Decline status */
    @isTest
    static void claimCreateServiceTestForEDICreation(){
        CSX_CMP_Decline_Code_Master__c declinecode = [SELECT id,CSX_CMP_Meaning__c FROM CSX_CMP_Decline_Code_Master__c WHERE CSX_CMP_Meaning__c = 'Decline code' LIMIT 1];
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,CSX_CMP_Claim_Amount__c,CSX_CMP_Decline_Code__c,Status,CSX_CMP_Sender_ID__c,CSX_CMP_System_Action_Toggle__c FROM Case WHERE CSX_CMP_Claim_Amount__c = 230 LIMIT 1]);
        caseMap.values()[0].Status = 'Declined';
        caseMap.values()[0].CSX_CMP_Decline_Code__c = declinecode.id;
        caseMap.values()[0].CSX_CMP_System_Action_Toggle__c = !caseMap.values()[0].CSX_CMP_System_Action_Toggle__c;
        caseMap.values()[0].CSX_CMP_Sender_ID__c = 'GMCX';
        update caseMap.values();
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
                CSX_CMP_CreateEDI926RecordController.createEDI926StagingRecord(new List<Id>(caseMap.keySet()));
            Test.stopTest();
            List<CSX_CMP_EDI926ClaimReport__c> edi926Records = [SELECT Id FROM CSX_CMP_EDI926ClaimReport__c WHERE CSX_CMP_Claim__c IN :caseMap.keySet()];
           System.assertEquals(0, edi926Records.size(),'EDI926 record should be created');

        }
    }

    /* @description : method to test EDI926 record creation for closed status */
    @isTest
    static void claimCreateServiceTestForClosedEDICreation(){
		//CSX_CMP_Decline_Code_Master__c declinecode = [SELECT id,CSX_CMP_Meaning__c FROM CSX_CMP_Decline_Code_Master__c WHERE CSX_CMP_Meaning__c = 'Decline code' LIMIT 1];
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,CSX_CMP_Claim_Amount__c,CSX_CMP_Decline_Code__c,Status,CSX_CMP_Sender_ID__c,CSX_CMP_System_Action_Toggle__c FROM Case WHERE CSX_CMP_Claim_Amount__c = 230 LIMIT 1]);
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        caseMap.values()[0].Status = 'Closed';
        caseMap.values()[0].CSX_CMP_System_Action_Toggle__c = !caseMap.values()[0].CSX_CMP_System_Action_Toggle__c;
        caseMap.values()[0].CSX_CMP_Sender_ID__c = 'GMCX';
        //caseMap.values()[0].CSX_CMP_Decline_Code__c = declinecode.id;
        update caseMap.values();

        System.runAs(user) {
            Test.startTest();
                CSX_CMP_CreateEDI926RecordController.createEDI926StagingRecord(new List<Id>(caseMap.keySet()));
            Test.stopTest();

            List<CSX_CMP_EDI926ClaimReport__c> edi926Records = [SELECT Id FROM CSX_CMP_EDI926ClaimReport__c WHERE CSX_CMP_Claim__c IN :caseMap.keySet()];
           System.assertEquals(0, edi926Records.size(),'EDI926 record should be created');
        }
    }

}