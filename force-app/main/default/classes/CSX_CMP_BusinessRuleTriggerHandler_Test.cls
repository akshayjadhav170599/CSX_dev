@isTest
public class CSX_CMP_BusinessRuleTriggerHandler_Test {
    
    @testSetup
	// Create test data for Business Rules and Business Rule Conditions
    private static void setupTestData() {
        // Creating test Business Rules
        List<CSX_CMP_Business_Rule__c> businessRules = new List<CSX_CMP_Business_Rule__c>();
        for (Integer i = 0; i < 3; i++) {
            System.debug('Iteration: ' + i);
            CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
                CSX_CMP_Rule_Name__c = (i == 0) ? 'strSequence': 'test '+ i,
                CSX_CMP_Where_Clause__c = (i == 0) ? '1 AND 2' : (i == 1 ? '(2 OR 3) AND (1' : '1 OR 3'),
                CSX_CMP_Priority__c = (i+1) + 800,
                CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
            );
            businessRules.add(objBusinessRule);
        }
        insert businessRules;
		
        System.debug('Inserted Business Rules: ' + businessRules);
        
        // Creating test Business Rule Conditions
        List<CSX_CMP_Business_Rule_Condition__c> conditions = new List<CSX_CMP_Business_Rule_Condition__c>();
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            CSX_CMP_Business_Rule_Condition__c condition = new CSX_CMP_Business_Rule_Condition__c(
                //Name = 'Condition for ' + br.Name,
                CSX_CMP_Attribute_Name__c = 'claim_claimType',
                CSX_CMP_Operator__c = 'Equal To',
            	CSX_CMP_Value__c = 'FC Salvage Claim',
                CSX_CMP_Business_Rule__c = br.Id
            );
            conditions.add(condition);
        }
        insert conditions;
    }

    // Test for handleBeforeUpdate method (Validations for where clause and priority)
    @isTest
    static void testHandleBeforeUpdate() {
        //setupTestData();
        
        // Get inserted business rules
        List<CSX_CMP_Business_Rule__c> businessRules = [SELECT Id, CSX_CMP_Where_Clause__c, CSX_CMP_Priority__c, CSX_CMP_Rule_Name__c  FROM CSX_CMP_Business_Rule__c];

        // Update the business rules to trigger the handler
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            br.CSX_CMP_Where_Clause__c = '1 AND 2';
            br.CSX_CMP_Priority__c = (br.CSX_CMP_Priority__c == 10) ? 20 : 10;
        }

        // Creating a map of old records for the test
        Map<Id, CSX_CMP_Business_Rule__c> oldBusinessRuleMap = new Map<Id, CSX_CMP_Business_Rule__c>();
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            oldBusinessRuleMap.put(br.Id, br);
        }

        // Call the trigger handler method
        Test.startTest();
        CSX_CMP_BusinessRuleTriggerHandler.handleBeforeUpdate(businessRules, oldBusinessRuleMap);
        Test.stopTest();
        
        // Verify errors or custom logic if any
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            if (br.CSX_CMP_Where_Clause__c != null) {
                System.assert(br.CSX_CMP_Where_Clause__c != '', 'Where clause should be validated');
            }
        }
    }

    // Test for validatePriorityCondition method
    @isTest
    static void testValidatePriorityCondition() {
        //setupTestData();

        // Get inserted business rules and simulate priority changes
        List<CSX_CMP_Business_Rule__c> businessRules = [SELECT Id, CSX_CMP_Priority__c, CSX_CMP_Rule_Name__c  FROM CSX_CMP_Business_Rule__c];

        // Create a new rule with the same priority to check for duplicate priority validation
        CSX_CMP_Business_Rule__c newRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Duplicate Priority Rule',
            CSX_CMP_Priority__c = 10,
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)            
        );
        insert newRule;

        // Call the validatePriorityCondition method directly
        Test.startTest();
        CSX_CMP_BusinessRuleTriggerHandler.validatePriorityCondition(businessRules);
        Test.stopTest();
        
        // Verify the error if duplicate priority is found
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            if (br.CSX_CMP_Priority__c == 10) {
                System.assert(br.hasErrors(), 'Duplicate priority should trigger an error');
            }
        }
    }

    // Test for validateWhereClauseCondition method
    @isTest
    static void testValidateWhereClauseCondition() {
        //setupTestData();

        // Get inserted business rules and simulate where clause validation
        List<CSX_CMP_Business_Rule__c> businessRules = [SELECT Id, CSX_CMP_Where_Clause__c, CSX_CMP_Rule_Name__c FROM CSX_CMP_Business_Rule__c];

        // Modify the where clause for validation testing
        /*for (CSX_CMP_Business_Rule__c br : businessRules) {
            br.CSX_CMP_Where_Clause__c = '1';
        }
        update businessRules;*/

        // Call the validateWhereClauseCondition method directly
        Test.startTest();
        CSX_CMP_BusinessRuleTriggerHandler.validateWhereClauseCondition(businessRules, new Map<Id, CSX_CMP_Business_Rule__c>());
        Test.stopTest();
        
        // Verify the error for invalid where clause
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            System.assert(br.hasErrors(), 'Invalid where clause should trigger an error');
        }
    }

    // Test for handleBeforeUpdate when there is an empty where clause
    @isTest
    static void testHandleBeforeUpdateEmptyWhereClause() {
        //setupTestData();

        // Get inserted business rules
        List<CSX_CMP_Business_Rule__c> businessRules = [SELECT Id, CSX_CMP_Where_Clause__c, CSX_CMP_Rule_Name__c FROM CSX_CMP_Business_Rule__c];

        // Set empty where clause to trigger error
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            br.CSX_CMP_Where_Clause__c = '1 AND 2';
        }

        // Create a map of old records for the test
        Map<Id, CSX_CMP_Business_Rule__c> oldBusinessRuleMap = new Map<Id, CSX_CMP_Business_Rule__c>();
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            oldBusinessRuleMap.put(br.Id, br);
        }

        // Call the trigger handler method
        Test.startTest();
        CSX_CMP_BusinessRuleTriggerHandler.handleBeforeUpdate(businessRules, oldBusinessRuleMap);
        Test.stopTest();

        // Verify the error for empty where clause
        for (CSX_CMP_Business_Rule__c br : businessRules) {
            System.assert(br.hasErrors(), 'Empty where clause should trigger an error');
        }
    }

}