/**
@Author       - Infosys
@Name         - CSX_CMP_ARInvoiceReport_Test
@Created Date - 5/07/2024
@Description  - VF page controller to get AR details and build VF page wrapper for Invoice Report PDF
@RICEFW reference - CMP-E-0491
*/
@isTest
public class CSX_CMP_ARInvoiceReport_Test {
    /* @description : This method is used to make test data */
    @testSetup   
    static void makeTestData(){    
        CSX_CMP_TestMasterDataUtility.createMasterData();

        // Creating Freight Claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c =: response.claimId LIMIT 1];
        
         Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;
        
        // Inserting AR Settlement record
        CSX_CMP_AR_Settlement__c objSettlement = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement.CSX_CMP_Claim__c = response.claimId;
        Insert objSettlement;
        
        Account acc = [SELECT ID FROM Account WHERE Name = 'SAIL Account' AND RecordType.name = 'Location'];
        // Inserting 3rd party record
        CSX_CMP_3rd_Party__c thirdparty = new CSX_CMP_3rd_Party__c(
            CSX_CMP_Equipment__c = equipment.id,
            CSX_CMP_AR_Settlement__c = objSettlement.Id,
            CSX_CMP_Incident_Location__c = 'Incident Location',
            CSX_CMP_3rd_Party_Site__c = acc.Id,
            CSX_CMP_Amount__c = 50          
            //CSX_CMP_Party_Name__c = acc.Id
            );
        insert thirdparty;
        
    }

    /* @description : These method is used test the AR invoice report template */
    @isTest
    static void testARInvoiceReportDetails(){
        
        CSX_CMP_3rd_Party__c party = [SELECT ID, CSX_CMP_Equipment__c,CSX_CMP_AR_Settlement__c,CSX_CMP_Incident_Location__c,CSX_CMP_Amount__c,CSX_CMP_Party_Name__r.name FROM CSX_CMP_3rd_Party__c WHERE CSX_CMP_Amount__c = 50];
        CSX_CMP_AR_Settlement__c details = [SELECT Id, Name, CSX_CMP_Invoice_Number__c, CSX_CMP_Invoice_Date__c, CSX_CMP_Customer_Number__c,CSX_CMP_Claim__c FROM CSX_CMP_AR_Settlement__c WHERE Id = :party.CSX_CMP_AR_Settlement__c LIMIT 1];
        CSX_CMP_ARInvoiceReport.CSX_CMP_ARWrapper arWrapper = new CSX_CMP_ARInvoiceReport.CSX_CMP_ARWrapper();
        // Freight Claim User or Freight Claim Manager can create 
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            PageReference pageRef = Page.CSX_CMP_ARInvoiceReport;
            Test.setCurrentPage(pageRef);
            pageRef.getparameters().put('id',party.CSX_CMP_AR_Settlement__c);

            Test.startTest();
            
            ApexPages.StandardController standCon = new ApexPages.StandardController(details);
            CSX_CMP_ARInvoiceReport csxLogo = new CSX_CMP_ARInvoiceReport(standCon);
            CSX_CMP_ARInvoiceReport arrecordId = new CSX_CMP_ARInvoiceReport(standCon);
            arrecordId.arSettlementId = party.CSX_CMP_AR_Settlement__c;
            arWrapper = arrecordId.arWrapper;
            Test.stopTest();

            System.assertNotEquals(null, arWrapper,'arWrapper should not be null');
            System.assertEquals('FC RR Inbound Claim', arWrapper.claimType,'Claim Type should be FC RR Inbound Claim');
            System.assertEquals(1800.00,arWrapper.amount,'Amount should be 1800.00');
            
        }
    }

    // 1. getARDetails - this method doesn't contain any description in the original class
    // 2. Commented code needs to be removed in original class
    // 3. arWrapper - declare this variable a beginning of the class
    // 4. calculateDueDate - method description is missing in the original class
    // 5. debug logs needs to be removed in the original class
    // 6. RICEFW Number is missing on main class initial lines
}