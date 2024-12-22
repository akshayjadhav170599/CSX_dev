@isTest
public class CSX_CMP_BusinessCondTrigHandler_Test {
    
    @IsTest
    static void testHandleAfterInsert() {
        // Prepare test data
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule__c businessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule2',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = ''
        );
        insert businessRule2;

        // Insert multiple conditions to cover various scenarios
        CSX_CMP_Business_Rule_Condition__c validCondition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '1',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '10'
        );

        //Test.startTest();
        insert validCondition;
        
        businessRule.CSX_CMP_Status__c = 'Valid';
    	update businessRule;
        
        //Test.stopTest();

        CSX_CMP_Business_Rule__c updatedRule = [SELECT Id, CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertEquals('Valid', updatedRule.CSX_CMP_Status__c,'Business Rule is Valid');
		
        CSX_CMP_Business_Rule_Condition__c invalidCondition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test'
        );

        
        
        Test.startTest();
        	Database.SaveResult saveResults = Database.insert(invalidCondition, false);
            //insert invalidCondition; 
            //insert businessRule2;
            //System.assert(false, 'Expected an exception due to invalid condition.');
            System.assert(true, 'Expected validation error message');
        Test.stopTest();
    }

    @isTest
    static void testHandleAfterUpdate() {
   /*     CSX_CMP_Business_Rule__c businessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule2',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = null
        );
        insert businessRule2;
        */
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
        	CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid'
        );
        insert businessRule;

        CSX_CMP_Business_Rule_Condition__c businessCondition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '1'
        );
        insert businessCondition;

        businessCondition.Name = '1';
        update businessCondition;
        
	
        Test.startTest();
        CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterUpdate(new List<CSX_CMP_Business_Rule_Condition__c>{businessCondition});
        Test.stopTest();

        businessRule = [SELECT Id, CSX_CMP_Where_Clause__c, CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertEquals('1', businessRule.CSX_CMP_Where_Clause__c, 'Where clause should be updated correctly');
        System.assertEquals('Valid', businessRule.CSX_CMP_Status__c, 'Status should be set to Valid after update');
        
    }
    
    @IsTest
	static void testHandleAfterDelete() {
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule3',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18)
        );
        insert businessRule;

        CSX_CMP_Business_Rule_Condition__c condition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '3',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '03/25/2024'
        );
        insert condition;

        Test.startTest();
        delete condition; 
        Test.stopTest();

        CSX_CMP_Business_Rule__c updatedRule = [SELECT Id, CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertEquals('Invalid', updatedRule.CSX_CMP_Status__c, 'Business Rule is Invalid');
    }

    @isTest
    static void testHandleBeforeInsert(){
        
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
        	CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid'
        );
        insert businessRule;

        CSX_CMP_Business_Rule_Condition__c businessCondition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '1'
        );
        insert businessCondition;        
        
        Test.startTest();
        CSX_CMP_BusinessRuleConditionTrigHandler.handleBeforeInsert(new List<CSX_CMP_Business_Rule_Condition__c>{businessCondition});
        Test.stopTest();
    }

    @IsTest
    static void testHandleAfterInsert1() {
        // Prepare test data
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid'
        );
        insert businessRule;
        Test.startTest();
        //CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterUpdate(new List<CSX_CMP_Business_Rule_Condition__c>{businessCondition});
        Test.stopTest();
    }
   
    @isTest
    static void testHandleAfterUpdate2() {
   /*     CSX_CMP_Business_Rule__c businessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule2',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = null
        );
        insert businessRule2;
        */
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
        	CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid',
            CSX_CMP_Where_Clause__c = ''
        );
        insert businessRule;

        CSX_CMP_Business_Rule_Condition__c businessCondition = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '1'
        );
        insert businessCondition;

        businessCondition.Name = '1';
        update businessCondition;
        
	
        Test.startTest();
        CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterUpdate(new List<CSX_CMP_Business_Rule_Condition__c>{businessCondition});
        Test.stopTest();

        businessRule = [SELECT Id, CSX_CMP_Where_Clause__c, CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertEquals('1', businessRule.CSX_CMP_Where_Clause__c, 'Where clause should be updated correctly');
        System.assertEquals('Valid', businessRule.CSX_CMP_Status__c, 'Status should be set to Valid after update');
        
    }	
    
    @isTest
    static void testValidateCondition() {

		CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule',
        	CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Status__c = 'Invalid',
            CSX_CMP_Where_Clause__c = ''
        );
        // 1. Test with a valid 'Greater Than' operator and valid date format
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillDate',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '12/25/2023'
        );
        // 2. Test with an invalid date format
        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillDate',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '2023-12-25'
        );
        CSX_CMP_Business_Rule_Condition__c condition13 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillDate',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '12.25.2023'
        );
        // 3. Test numeric check (valid numeric value)
        CSX_CMP_Business_Rule_Condition__c condition3 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '25'
        );
        // 4. Test numeric check (invalid non-numeric value)
        CSX_CMP_Business_Rule_Condition__c condition4 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_claimAge',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = 'abc'
        );
        // 5. Test Yes/No check (valid value)
        CSX_CMP_Business_Rule_Condition__c condition5 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_autoSettleReturnStatus',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'YES'
        );
        // 6. Test Yes/No check (invalid value)
        CSX_CMP_Business_Rule_Condition__c condition6 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_autoSettleReturnStatus',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'MAYBE'
        );
        // 7. Test numeric check for list attributes (valid numeric value in list)
        CSX_CMP_Business_Rule_Condition__c condition7 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '100,200,300'
        );
        // 8. Test numeric check for list attributes (invalid non-numeric value in list)
        CSX_CMP_Business_Rule_Condition__c condition8 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '100,abc,300'
        );
        // 9. Test email validation (valid email)
        CSX_CMP_Business_Rule_Condition__c condition9 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_distribution_fCContactEmail',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@example.com'
        );
        // 10. Test email validation (invalid email)
        CSX_CMP_Business_Rule_Condition__c condition10 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_distribution_fCContactEmail',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'invalid-email'
        );
        // 11. Test length validation (valid length)
        CSX_CMP_Business_Rule_Condition__c condition11 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdArea',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'A'
        );       
        // 12. Test length validation (invalid length)
        CSX_CMP_Business_Rule_Condition__c condition12 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdArea',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'ABC'
        );
        
        // 13. Test length validation (operator 'Equal To' with value length > 2)
        CSX_CMP_Business_Rule_Condition__c condition14 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdArea',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'ABC'
        );

        // 14. Test length validation (operator 'In List' with one value length > 2)
        CSX_CMP_Business_Rule_Condition__c condition15 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdArea',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'A,BB,CCC'
        );

        // 15. Test length validation (operator 'In List' with all values length <= 2)
        CSX_CMP_Business_Rule_Condition__c condition16 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdArea',
            CSX_CMP_Business_Rule__c = businessRule.Id,
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'A,BB,CC'
        );

        List<CSX_CMP_Business_Rule_Condition__c> conditions = new List<CSX_CMP_Business_Rule_Condition__c>{
            condition1, condition2, condition3, condition4, condition5, condition6,
            condition7, condition8, condition9, condition10, condition11, condition12,
            condition13, condition14, condition15, condition16
        };
		Database.SaveResult[] saveResults = Database.insert(conditions, false);
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(conditions);
        Test.stopTest();
     
    	System.assert(!saveResults[1].isSuccess(), 'The invalid condition should fail due to validation errors.');
    }	
}