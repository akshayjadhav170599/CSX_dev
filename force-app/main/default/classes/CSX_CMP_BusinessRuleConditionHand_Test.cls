@isTest
public class CSX_CMP_BusinessRuleConditionHand_Test {
	
    @isTest
    static void testHandleAfterInsert() {
        // Create mock Business Rule and Conditions records
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'claim_claimAmount',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '10'
        );
        insert condition1;
        
        CSX_CMP_Business_Rule__c businessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule2',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = ''
        );
        insert businessRule2;
        
        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule2.Id, 
            CSX_CMP_Attribute_Name__c = 'claim_claimAmount',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '10'
        );
        insert condition2;
        

        // Call handleAfterInsert to test the after insert functionality
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.handleAfterInsert(new List<CSX_CMP_Business_Rule_Condition__c>{condition1});
        CSX_CMP_BusinessRuleConditionHandler.handleAfterInsert(new List<CSX_CMP_Business_Rule_Condition__c>{condition2});
        Test.stopTest();
        
        businessRule = [SELECT CSX_CMP_Where_Clause__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertNotEquals(null, businessRule.CSX_CMP_Where_Clause__c, 'Where clause should be populated.');
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        // Create mock Business Rule and Conditions records
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition1;
        
        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Less Than',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition2;
        
        CSX_CMP_Business_Rule_Condition__c condition3 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Less Than or Equal To',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition3;
        
        CSX_CMP_Business_Rule_Condition__c condition4 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition4;
        
        // Update the condition
       // condition1.CSX_CMP_Value__c = '10/22/2025';
        //update condition1;
        
        // Call handleAfterUpdate to test after update functionality
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.handleAfterUpdate(new List<CSX_CMP_Business_Rule_Condition__c>{condition1});
        Test.stopTest();
        
        // Verify the where clause is updated correctly
        businessRule = [SELECT CSX_CMP_Where_Clause__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        System.assertNotEquals(null, businessRule.CSX_CMP_Where_Clause__c, 'Where clause should be updated.');
    }
    
    @isTest
    static void testHandleAfterDelete() {
        // Create mock Business Rule and Conditions records
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition1;
        
        delete condition1;
        
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.handleAfterDelete(new List<CSX_CMP_Business_Rule_Condition__c>{condition1});
        Test.stopTest();
        
        businessRule = [SELECT CSX_CMP_Where_Clause__c, CSX_CMP_Status__c FROM CSX_CMP_Business_Rule__c WHERE Id = :businessRule.Id];
        //System.assertEquals('Invalid', businessRule.CSX_CMP_Status__c, 'Status should be Invalid after deletion.');
    }
    
    @isTest
    static void testHandleBeforeInsert() {
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '10'
        );
        
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.handleBeforeInsert(new List<CSX_CMP_Business_Rule_Condition__c>{condition1});
        Test.stopTest();
    }
    
    @isTest
    static void testHandleBeforeUpdate() {
        // Create mock Business Rule and Conditions records
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition1;
        
        condition1.CSX_CMP_Value__c = '20';
        
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.handleBeforeupdate(new List<CSX_CMP_Business_Rule_Condition__c>{condition1});
        Test.stopTest();
        
    }

    @isTest
    static void testValidateSequence() {
        // Create mock Business Rule and Conditions records with same sequence number
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '9/18/2024'
        );
        insert condition1;

        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Less Than',
            CSX_CMP_Value__c = '20'
        );

        // Check for sequence number validation
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.validateSequence(new List<CSX_CMP_Business_Rule_Condition__c>{condition1, condition2});
        Test.stopTest();

        System.assert(condition2.hasErrors(), 'Sequence validation should add an error.');
    }
    
    @isTest
    static void testValidateCondition() {
        // Create mock Business Rule and Conditions records with invalid conditions
        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
        	CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert businessRule;
        
        CSX_CMP_Business_Rule_Condition__c condition = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than',
            CSX_CMP_Value__c = '10/10/2024'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Less Than',
            CSX_CMP_Value__c = '10/10/2024'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition3 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '10/10/2024'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition4 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDate',
            CSX_CMP_Operator__c = 'Greater Than or Equal To',
            CSX_CMP_Value__c = '10/10/2024'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition5 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Age',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition6 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Amount',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition7 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillDateAging',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition8 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_CarNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition9 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdArea',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition10 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdSeverity',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition11 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition12 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdArea',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition13 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition14 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdSeverity',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition15 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdReportType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition16 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdSeverity',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition17 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_NationalAccount',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition18 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition19 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_NumberofRelatedClaim',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition20 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_FreightbillNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition21 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_UrwinNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition22 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Distribution_NonCSXMexicanRR',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition23 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_AutoSettleReturnStatus',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition24 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_DerailmentFlag',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition25 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_custDamageMatchInspRep1278',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition26 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_allCustDamagematchInspRep04',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition27 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_ClaimAmountwithinthreshold',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition28 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_No04InspectionCount',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = ''
        );
        
        CSX_CMP_Business_Rule_Condition__c condition29 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_CarNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition30 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdArea',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition31 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdSeverity',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition32 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition33 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdArea',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition34 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition35 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdSeverity',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition36 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdReportType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition37 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_NationalAccount',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition38 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_WaybillNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition39 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_CarNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition40 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_FreightbillNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition41 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_UrwinNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition42 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_CarNumInitial',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition43 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_ClaimantName',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition44 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_RecordType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition45 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Status',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '312'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition46 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Type',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '312'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition47 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Contract_CType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '312,2313'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition48 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Distribution_FCContactEmail',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition49 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdArea',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition50 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdSeverity',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition51 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_CustomerDamage_CdType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition52 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdArea',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition53 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition54 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdSeverity',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition55 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Product_InspectionDamage_IdReportType',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '321,231'
        );
        
        CSX_CMP_Business_Rule_Condition__c condition56 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = businessRule.Id, 
            CSX_CMP_Attribute_Name__c = 'Claim_Equipment_Distribution_FCContactEmail',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'test@testEmail.com'
        );
        
        Test.startTest();
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition2});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition3});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition4});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition5});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition6});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition7});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition8});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition9});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition10});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition11});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition12});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition13});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition14});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition15});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition16});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition17});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition18});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition19});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition20});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition21});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition22});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition23});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition24});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition25});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition26});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition27});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition28});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition29});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition30});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition31});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition32});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition33});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition34});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition35});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition36});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition37});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition38});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition39});
		CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition40});
		CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition41});
		CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition42});
		CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition43});
		CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition44});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition45});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition46});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition47});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition48});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition49});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition50});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition51});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition52});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition53});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition54});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition55});
        CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition56});
        //CSX_CMP_BusinessRuleConditionHandler.validateCondition(new List<CSX_CMP_Business_Rule_Condition__c>{condition57});
        Test.stopTest();
        
        System.assert(condition.hasErrors(), 'Validation should add errors for invalid date format.');
    }
}