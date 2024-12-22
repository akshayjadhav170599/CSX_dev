/**
@Author       - Infosys
@Name         - CSX_CMP_AutoContractorEmailWrapper_Test
@Created Date - 5/07/2024
@Description  - VF page controller to get AR details and build VF page wrapper for Invoice email template 
@RICEFW reference - CMP-E-0491
*/
@isTest 
public class CSX_CMP_AutoContractorEmailWrapper_Test {
    
    /* @description : These method is used to make test*/
    @TestSetup
    public static void makeTestData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Creating Freight Claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);

        Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;
        
        // Creating AR Settlement record
        CSX_CMP_AR_Settlement__c objSettlement = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement.CSX_CMP_Claim__c = response.claimId;
        insert objSettlement;

        // Inserting 3rd party record
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c =: response.claimId LIMIT 1];
        CSX_CMP_3rd_Party__c thirdparty = new CSX_CMP_3rd_Party__c(
            CSX_CMP_Equipment__c = equipment.id,
            CSX_CMP_AR_Settlement__c = objSettlement.Id,
            CSX_CMP_Incident_Location__c = 'Incident Location',
            CSX_CMP_Amount__c = 50,
            CSX_CMP_3rd_Party_Site__r = new Account(CSX_CMP_External_ID__c = 'SAILAccount')
       
        );
        	
        insert thirdparty;
        
    }


    /* 
        @description : method to test to check email template for 3rd party Invoice 
    */
    @isTest
    static void testAutocontractorEmailSuccess() {
        CSX_CMP_3rd_Party__c party = [SELECT ID, CSX_CMP_Equipment__c,CSX_CMP_AR_Settlement__c,CSX_CMP_Incident_Location__c,CSX_CMP_Amount__c,CSX_CMP_Party_Name__r.name FROM CSX_CMP_3rd_Party__c WHERE CSX_CMP_Amount__c = 50];
        CSX_CMP_AR_Settlement__c details = [SELECT Id, Name, CSX_CMP_Invoice_Number__c, CSX_CMP_Invoice_Date__c, CSX_CMP_Customer_Number__c,CSX_CMP_Claim__c FROM CSX_CMP_AR_Settlement__c WHERE Id = :party.CSX_CMP_AR_Settlement__c LIMIT 1];
        CSX_CMP_AutoContractorEmailWrapper.CSX_CMP_ARWrapper arWrapper = new CSX_CMP_AutoContractorEmailWrapper.CSX_CMP_ARWrapper();
        
        // Freight Claim User or Freight Claim Manager can create 
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            
            Test.startTest();
        

            //String csxLogo = CSX_CMP_Utility.logoUrl();
           CSX_CMP_AutoContractorEmailWrapper arrecordId = new CSX_CMP_AutoContractorEmailWrapper();
            arrecordId.arSettlementId = details.Id;
            arWrapper = arrecordId.arWrapper;
            Test.stopTest();
            
            System.assertNotEquals(null, arWrapper,'arWrapper should not be null');
            System.assertEquals('Incident Location', arWrapper.incidentLocation,'Incident Location should be Incident Location');

        }
        
        
    }

    // 1. description.RICEFW and other details are not available for original class
    // 2. getARDetails - method description is not available
    // 3. remove commented code from original class
    // 4. remove commented code from original class

}