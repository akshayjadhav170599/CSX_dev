@isTest
public class CSX_CMP_BusinessRulesHelper_Test {

    @testSetup
    static void setupData() {
        // Create a test Claim
        Case claim1 = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Freight' LIMIT 1].Id,
            Status = 'New',
            Type = 'FC Customer Claim'
        );
        
        // Create a test Equipment
        CSX_CMP_Equipment__c objEquipment = new CSX_CMP_Equipment__c(
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '1234',
            CSX_CMP_Claim__c = claim1.id
            
        );
        insert objEquipment;
        
        // Create test data for Business Rule
        CSX_CMP_Business_Rule__c objBusinessRule1 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1'
        );
        insert objBusinessRule1;
        
        // Add business rule conditions
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition1 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition1;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition2 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'FC Salvage Claim'
        );
        insert objBusinessRulecondition2;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition3 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = 'FC Salvage Claim'
        );
        insert objBusinessRulecondition3;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition4 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'FC Salvage Claim, FC Customer Claim'
        );
        insert objBusinessRulecondition4;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition5 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = 'FC Salvage Claim, FC Customer Claim'
        );
        insert objBusinessRulecondition5;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition6 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'New'
        );
        insert objBusinessRulecondition6;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition7 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = 'New'
        );
        insert objBusinessRulecondition7;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition8 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'New, Open'
        );
        insert objBusinessRulecondition8;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition9 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = 'New, Open'
        );
        insert objBusinessRulecondition9;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition10 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition10;
        
        // Add business rule conditions
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition11 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'CSXT0000002'
        );
        insert objBusinessRulecondition11;
        
         CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition12 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = 'CSXT0000002'
        );
        insert objBusinessRulecondition12;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition13 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'CSXT0000002, CSXT0000008'
        );
        insert objBusinessRulecondition13;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition14 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = 'CSXT0000002, CSXT0000008'
        );
        insert objBusinessRulecondition14;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition15 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_contractName',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition15;
       
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition16 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '4T3LWRFVXPU102033'
        );
        insert objBusinessRulecondition16;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition17 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '4T3LWRFVXPU102033'
        );
        insert objBusinessRulecondition17;
        /*
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition18 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule4.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '4T3LWRFVXPU102033'
        );
        insert objBusinessRulecondition18;
		
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition19 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule4.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '4T3LWRFVXPU102033'
        );
        insert objBusinessRulecondition19;
        */
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition20 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimVin',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition20;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition21 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '887966'
        );
        insert objBusinessRulecondition21;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition22 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '887966'
        );
        insert objBusinessRulecondition22;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition23 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '167765,'
        );
        insert objBusinessRulecondition23;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition24 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '167765,'
        );
        insert objBusinessRulecondition24;
    	
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition25 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_waybillNum',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition25;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition26 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '95024343'
        );
        insert objBusinessRulecondition26;
		
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition27 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '95024343'
        );
        insert objBusinessRulecondition27;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition28 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '95024343,'
        );
        insert objBusinessRulecondition28;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition29 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '95024343,'
        );
        insert objBusinessRulecondition29;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition30 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_freightbillNum',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition30;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition31 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = '12345'
        );
        insert objBusinessRulecondition31;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition32 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = '12345'
        );
        insert objBusinessRulecondition32;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition33 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = '12345,'
        );
        insert objBusinessRulecondition33;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition34 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            CSX_CMP_Operator__c = 'Not In',
            CSX_CMP_Value__c = '12345,'
        );
        insert objBusinessRulecondition34;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRulecondition35 = new CSX_CMP_Business_Rule_Condition__c(
            CSX_CMP_Business_Rule__c = objBusinessRule1.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_urwinNum',
            CSX_CMP_Operator__c = 'Matches',
            CSX_CMP_Value__c = ''
        );
        insert objBusinessRulecondition35;

    
    }
    
    @isTest
    static void testIdentifyClaimsForMatchesComparisonFreight() {
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        CSX_CMP_BusinessRulesUtility.EquipmentWrapper equipWrapper = new CSX_CMP_BusinessRulesUtility.EquipmentWrapper();
        claimWrapper.RecordType = 'Freight';
        claimWrapper.claimType = 'FC Customer Claim';
        equipWrapper.equipInitial = 'TTGX';
        equipWrapper.equipNum = '4231';
        equipWrapper.waybillNum = '167765';
        

        // Get the business rule
        CSX_CMP_Business_Rule__c businessRule = [SELECT Id, RecordType.DeveloperName, CSX_CMP_Claim_Type__c, 
                                                  (SELECT CSX_CMP_Attribute_Name__c, CSX_CMP_Operator__c, CSX_CMP_Value__c 
                                                   FROM Business_Rule_Conditions__r)
                                                  FROM CSX_CMP_Business_Rule__c LIMIT 1];

        Test.startTest();
        Set<Id> result = CSX_CMP_BusinessRulesHelper.identifyClaimsforMatchesComparison(claimWrapper, businessRule);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result size should be 0 for no matching claims.');
    }
    
    @isTest
    static void testIdentifyClaimsForMatchesComparisonRevenue() {
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        CSX_CMP_BusinessRulesUtility.EquipmentWrapper equipWrapper = new CSX_CMP_BusinessRulesUtility.EquipmentWrapper();
        claimWrapper.RecordType = 'Revenue';
        claimWrapper.claimType = 'Rev-RR - Payable Claim';
        //equipWrapper.id = 'a09O2000005sLvpIAE';
        equipWrapper.equipInitial = 'TTGX';
        equipWrapper.equipNum = '4231';
        equipWrapper.waybillNum = '167765';
        
        // Get the business rule
        CSX_CMP_Business_Rule__c businessRule = [SELECT Id, RecordType.DeveloperName, CSX_CMP_Claim_Type__c, 
                                                  (SELECT CSX_CMP_Attribute_Name__c, CSX_CMP_Operator__c, CSX_CMP_Value__c 
                                                   FROM Business_Rule_Conditions__r)
                                                  FROM CSX_CMP_Business_Rule__c LIMIT 1];

        Test.startTest();
        Set<Id> result = CSX_CMP_BusinessRulesHelper.identifyClaimsforMatchesComparison(claimWrapper, businessRule);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result size should be 0 for no matching claims.');
    }
}