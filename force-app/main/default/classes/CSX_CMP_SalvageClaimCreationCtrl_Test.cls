/**************************************************************************************
/*
@author             : Infosys
@description        : Test Class for CSX_CMP_SalvageClaimCreationController
Apex Class Name     : CSX_CMP_SalvageClaimCreationController
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest 
public class CSX_CMP_SalvageClaimCreationCtrl_Test {
    
    @TestSetup
    public static void setupTestData() { 

        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();

        Map<String,String> lDReport = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
        CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(ldReport);

        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_LD_Report__c =: response.ldrId LIMIT 1];
        
        CSX_CMP_Salvage__c salvage = new CSX_CMP_Salvage__c(
            CSX_CMP_Salvage_Amount__c = 132.86,
            CSX_CMP_Parent_Equipment__c = equipment.Id,
            CSX_CMP_Product__c = 'Test Product',
            CSX_CMP_Salvor_Name__r = new Account(CSX_CMP_External_Id__c = 'SAILAccount')
            // CSX_CMP_Salvor_Name__c = [SELECT Id FROM Account WHERE Name = 'SAIL Account' LIMIT 1].Id
        );
        insert salvage;

    }
    
    @isTest
    static void testCreateSalvageClaimSuccess() {
        CSX_CMP_Salvage__c salvage = [SELECT Id,CSX_CMP_Product__c FROM CSX_CMP_Salvage__c WHERE CSX_CMP_Salvage_Amount__c = 132.86 LIMIT 1];
        CSX_CMP_LD_Report__c ldr = [SELECT Id,(SELECT Id FROM Equipments__r) FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'Customer' LIMIT 1];
        // CSX_CMP_Product__c product = [SELECT Id FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__c =: ldr.Equipments__r[0].Id LIMIT 1];
        Map<String,String> data = new Map<String,String>();
        data.put('equipmentId', ldr.Equipments__r[0].Id);
        data.put('productDescription', salvage.CSX_CMP_Product__c);
        // data.put('productId', product.Id);
        data.put('ldrId', ldr.Id);

        // Freight Claim User or Freight Claim Manager can create 
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

        System.runAs(user) {
            Test.startTest();
            String message = CSX_CMP_SalvageClaimCreationController.createSalvageClaim(salvage.Id, JSON.serialize(data));
            Test.stopTest();

            CSX_CMP_Salvage__c updatedSalvage = [SELECT Id, CSX_CMP_Salvage_Claim__c FROM CSX_CMP_Salvage__c WHERE Id = :salvage.Id];
            System.assertEquals('Success', message, 'Message should be "Success"');
            System.assertNotEquals(null, updatedSalvage.CSX_CMP_Salvage_Claim__c, 'Salvage Claim should be created');
        }
    }
    
    @isTest
    static void testCreateSalvageClaimExistingClaim() {
        CSX_CMP_Salvage__c salvage = [SELECT Id,CSX_CMP_Product__c FROM CSX_CMP_Salvage__c WHERE CSX_CMP_Salvage_Amount__c = 132.86 LIMIT 1];
        CSX_CMP_LD_Report__c ldr = [SELECT Id,(SELECT Id FROM Equipments__r) FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'Customer' LIMIT 1];
        // CSX_CMP_Product__c product = [SELECT Id FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__c =: ldr.Equipments__r[0].Id LIMIT 1];
        Map<String,String> data = new Map<String,String>();
        data.put('equipmentId', ldr.Equipments__r[0].Id);
        data.put('productDescription', salvage.CSX_CMP_Product__c);
        // data.put('productId', product.Id);
        data.put('ldrId', ldr.Id);

        // Create a new Salvage Claim and then try to create another claim
        CSX_CMP_SalvageClaimCreationController.createSalvageClaim(salvage.Id, JSON.serialize(data));

        // Freight Claim User or Freight Claim Manager can create 
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            String message = CSX_CMP_SalvageClaimCreationController.createSalvageClaim(salvage.Id, JSON.serialize(data));
            Test.stopTest();
            System.assertNotEquals('Success', message, 'Message should not be "Success"');
        }
    }    
}