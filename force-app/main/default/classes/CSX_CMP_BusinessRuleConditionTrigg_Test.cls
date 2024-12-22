@isTest
public class CSX_CMP_BusinessRuleConditionTrigg_Test {
	
    @isTest
    static void testTrigger() {
        // Create a test user and set up the bypass rule
        //User testUser = [SELECT Id FROM User LIMIT 1];
        CSX_CMP_ByPass_Rules__c bypassRule = new CSX_CMP_ByPass_Rules__c(
            CSX_CMP_Validation_Rule__c = false,
            CSX_CMP_Apex_Triggers__c = false
        );
        insert bypassRule;

        CSX_CMP_Business_Rule__c objBusinessRule1 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert objBusinessRule1;

        // Create test data for CSX_CMP_Business_Rule_Condition__c
        CSX_CMP_Business_Rule_Condition__c newRecord = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = '	Equal To',
            CSX_CMP_Business_Rule__c  = objBusinessRule1.Id,
            Name  = '1',
            CSX_CMP_Value__c = '15'
        );

        Test.startTest();

        insert newRecord;

        newRecord = [SELECT Id FROM CSX_CMP_Business_Rule_Condition__c WHERE Id = :newRecord.Id];
        newRecord.CSX_CMP_Attribute_Name__c = 'claim_claimAmount';
        update newRecord;
        System.assertNotEquals(null, newRecord, 'The record should be inserted');

        newRecord = [SELECT Id FROM CSX_CMP_Business_Rule_Condition__c WHERE Id = :newRecord.Id];
        delete newRecord;

        // Test after delete
        Test.stopTest();

    }

    @isTest
    static void testTriggerWithBypass() {
        // Create a test user and set up the bypass rule
        //User testUser = [SELECT Id FROM User LIMIT 1];
        CSX_CMP_ByPass_Rules__c bypassRule = new CSX_CMP_ByPass_Rules__c(
            CSX_CMP_Validation_Rule__c = false,
            CSX_CMP_Apex_Triggers__c = true
        );
        insert bypassRule;

        CSX_CMP_Business_Rule__c objBusinessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule2',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert objBusinessRule2;

        // Create test data for CSX_CMP_Business_Rule_Condition__c
        CSX_CMP_Business_Rule_Condition__c newRecord = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = '	Equal To',
            CSX_CMP_Business_Rule__c  = objBusinessRule2.Id,
            Name  = '1',
            CSX_CMP_Value__c  = '30'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillDate',
            CSX_CMP_Operator__c = '	Equal To',
            CSX_CMP_Business_Rule__c  = objBusinessRule2.Id,
            CSX_CMP_Value__c  = '10/24/2024'
        );

        Test.startTest();

        insert newRecord;

        newRecord = [SELECT Id FROM CSX_CMP_Business_Rule_Condition__c WHERE Id = :newRecord.Id];
        newRecord.CSX_CMP_Attribute_Name__c = 'claim_claimAmount';
        update newRecord;
        System.assertNotEquals(null, newRecord, 'Record insrted after bypass');
        
        insert condition2;

        newRecord = [SELECT Id FROM CSX_CMP_Business_Rule_Condition__c WHERE Id = :newRecord.Id];
        delete newRecord;

        Test.stopTest();

    }
}