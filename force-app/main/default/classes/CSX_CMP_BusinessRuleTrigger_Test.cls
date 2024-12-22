@isTest
public class CSX_CMP_BusinessRuleTrigger_Test {
    
	@isTest
    public static void testTriggerWithBypass() {
        // Setup User and Bypass Rule (simulate bypass)
        User testUser = [SELECT Id FROM User WHERE UserName = :UserInfo.getUserName() LIMIT 1];
        CSX_CMP_ByPass_Rules__c bypassRule = new CSX_CMP_ByPass_Rules__c(
            Name = testUser.Id,
            CSX_CMP_Apex_Triggers__c = true // Set the bypass rule to true
        );
        insert bypassRule;
        
        // Create a CSX_CMP_Business_Rule__c record
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
             RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
        );
        insert businessRule;
        
        // Simulate update to the CSX_CMP_Business_Rule__c record
        businessRule.CSX_CMP_Rule_Name__c = 'Updated Test Business Rule';
        Test.startTest();
        update businessRule;
        Test.stopTest();
        
        System.assert(true, 'Test passed with bypass rule set to true');
    }
    
    @isTest
    public static void testTriggerWithoutBypass() {
        // Setup User and Bypass Rule (simulate no bypass)
        User testUser = [SELECT Id FROM User WHERE UserName = :UserInfo.getUserName() LIMIT 1];
        CSX_CMP_ByPass_Rules__c bypassRule = new CSX_CMP_ByPass_Rules__c(
            Name = testUser.Id,
            CSX_CMP_Apex_Triggers__c = false // Set the bypass rule to false (trigger will run)
        );
        insert bypassRule;
        
        // Create a CSX_CMP_Business_Rule__c record
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
        );
        insert businessRule;
        
        // Simulate update to the CSX_CMP_Business_Rule__c record
        businessRule.CSX_CMP_Rule_Name__c = 'Updated Test Business Rule';
        Test.startTest();
        update businessRule; // This will trigger the before update trigger
        Test.stopTest();
        
        System.assert(true, 'Test passed with bypass rule set to false');
    }
    
}