@IsTest
public class CSX_CMP_ValidateRule_Test {
   
    @IsTest
    static void testEvaluateWhereClauseValidRule() {
        // Setup test data
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_RR_General_Rule' LIMIT 1].Id,
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2',
            CSX_CMP_Status__c = 'Valid'
        );
        insert objBusinessRule;
        
        // Setup test data for Business Rule Conditions
        CSX_CMP_Business_Rule_Condition__c objCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'Overcharge Carload INCD Claim'
        );
        insert objCondition1;
        
        CSX_CMP_Business_Rule_Condition__c objCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'New'
        );
        insert objCondition2;
        
        
        // Call the method
        Test.startTest();
        Integer result = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule.Id);
        Test.stopTest();
        
        System.assertEquals(3, result, 'Business rule should be valid.');

        // Verify status is updated
        objBusinessRule = [SELECT CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :objBusinessRule.Id];
        System.assertEquals('Valid', objBusinessRule.CSX_CMP_Status__c, 'Status should be Valid.');
    }

    @IsTest
    static void testEvaluateWhereClauseInvalidRuleDuplicate() {
        // Setup test data
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7'
        );
        insert objBusinessRule;
        
        CSX_CMP_Business_Rule_Condition__c objCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition1;
        
        CSX_CMP_Business_Rule_Condition__c objCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition2;
        
        CSX_CMP_Business_Rule_Condition__c objCondition3 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            Name = '3',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition3;
        
        CSX_CMP_Business_Rule_Condition__c objCondition4 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            Name = '4',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition4;
        
        CSX_CMP_Business_Rule_Condition__c objCondition5 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            Name = '5',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition5;
        
        CSX_CMP_Business_Rule_Condition__c objCondition6 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            Name = '6',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition6;
        
        CSX_CMP_Business_Rule_Condition__c objCondition7 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            Name = '7',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition7;
        
        CSX_CMP_Business_Rule__c objBusinessRule2 = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Rule_Name__c = 'Test Business Rule 2',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2'
        );
        insert objBusinessRule2;
        
        CSX_CMP_Business_Rule_Condition__c objCondition8 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule2.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition8;
        
         CSX_CMP_Business_Rule_Condition__c objCondition9 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule2.Id,
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objCondition9;
        
        // Call the method
        Test.startTest();
        Integer result = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule.Id);
        Integer result2 = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule2.Id);
        Test.stopTest();
        
        System.assertEquals(3, result, 'Business rule should be invalid for Duplicate.');
        System.assertEquals(1, result2, 'Business rule should be invalid for Duplicate.');
    }

    @IsTest
    static void testEvaluateWhereClauseValidWithConditions() {
        // Setup test data
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_RR_General_Rule' LIMIT 1].Id,
            CSX_CMP_Where_Clause__c = '1 AND 2',
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
        );
        insert objBusinessRule;
        
        // Setup test data for Business Rule Conditions
        CSX_CMP_Business_Rule_Condition__c objCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'Overcharge Carload INCD Claim'
        );
        insert objCondition1;

        CSX_CMP_Business_Rule_Condition__c objCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'New'
        );
        insert objCondition2;
        
        Test.startTest();
        Integer result = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule.Id);
        Test.stopTest();
        
        System.assertEquals(3, result, 'Business rule should be valid.');

        // Verify status is updated
        objBusinessRule = [SELECT CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :objBusinessRule.Id];
        System.assertEquals('Valid', objBusinessRule.CSX_CMP_Status__c, 'Status should be Valid.');
    }

    @IsTest
    static void testEvaluateWhereClauseInvalidWithConditions() {
        // Setup test data
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_RR_General_Rule' LIMIT 1].Id,
            CSX_CMP_Where_Clause__c = '1',
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)            
        );
        insert objBusinessRule;
        
        // Setup test data for Business Rule Conditions
        CSX_CMP_Business_Rule_Condition__c objCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'New'
        );
        insert objCondition1;
        
        Test.startTest();
        Integer result = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule.Id);
        Test.stopTest();
        
        System.assertEquals(3, result, 'Business rule should be invalid due to mismatched condition.');
    }

    @IsTest
    static void testEvaluateWhereClauseNoConditions() {
        // Setup test data
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_RR_General_Rule' LIMIT 1].Id,
            CSX_CMP_Where_Clause__c = '',
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
        );
        insert objBusinessRule;

        Test.startTest();
        Integer result = CSX_CMP_ValidateRule.evaluateWhereClause(objBusinessRule.Id);
        Test.stopTest();
        
        System.assertEquals(4, result, 'Business rule should return 4 when no conditions are present.');
    }
    
}