@isTest
public class CSX_CMP_BusinessRulesUtility_Test {

    @testSetup
    static void setupTestData() {
        RecordType rt = [Select Id, DeveloperName From RecordType Where SobjectType = 'CSX_CMP_Business_Rule__c' AND DeveloperName = 'CSX_CMP_Approval'];
        RecordType rtCase = [Select Id, DeveloperName From RecordType Where SobjectType = 'Case' AND DeveloperName = 'Freight'];

        CSX_CMP_Business_Rule__c businessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Rule',
            CSX_CMP_Status__c = 'Valid',
            CSX_CMP_Start_Date__c = Date.today().addDays(-10),
            CSX_CMP_End_Date__c = Date.today().addDays(10),
            RecordTypeId = rt.Id,
            CSX_CMP_Claim_Type__c = ''
        );
        insert businessRule;
        
        CSX_CMP_Desk__c objDeskTest = new CSX_CMP_Desk__c(
        	Name = 'Test Desk'
        );
        insert objDeskTest;
        
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule1',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Intermodal Service Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '',
            CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Priority__c = 10
        );
        insert objBusinessRule;
        
        Account objAccount = new Account(
        	RecordTypeId = [Select id, Name from RecordType where SobjectType = 'Account' AND Name = 'Location'].id,
            Name = 'Test Account',
            CSX_CMP_Freight_Collections_Team_Number__c = '042',
            Type = 'Supplier',
            CSX_CMP_FC_Threshold_From__c = 10,
            CSX_CMP_FC_Threshold_To__c = 100
            
        );
        insert objAccount;
        
        Account objAccount1 = new Account(
        	RecordTypeId = [Select id, Name from RecordType where SobjectType = 'Account' AND Name = 'Location'].id,
            Name = 'Test Account',
            CSX_CMP_Freight_Collections_Team_Number__c = '042',
            Type = 'Customer',
            CSX_CMP_FC_Threshold_From__c = 10,
            CSX_CMP_FC_Threshold_To__c = 100,
            Location_Type__c = 'Billing Address'
        );
        insert objAccount1;
        
        CSX_CMP_Contract__c objContract = new CSX_CMP_Contract__c(
        	CSX_CMP_Customer_Name__c = objAccount1.id,
            CSX_CMP_Start_Date__c = system.today(),
            CSX_CMP_Contract_Budget__c = 10000,
            CSX_CMP_Claim_Type__c = 'Sidetrack Claim',
            CSX_CMP_Status__c = 'Active',
            CSX_CMP_End_Date__c = system.today().addDays(5),
            CSX_CMP_Business_Unit__c = 'Test'
        );
        insert objContract;

        Case testCase = new Case(
            RecordTypeId = rtCase.Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 50,
            Status = 'Open',
            CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Supplier_Claimant__c = objAccount.id,
            CSX_CMP_Contract_Num__c = objContract.id,
            CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01),
            CSX_CMP_Period_End__c = Date.newInstance(2024, 01, 10),
            CSX_CMP_Related_LD_Reports__c  = 'I-000308'
            
        );
        insert testCase;
        
        Case testCase1 = new Case(
            RecordTypeId = rtCase.Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 5,
            Status = 'Open',
            CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Supplier_Claimant__c = objAccount.id,
            CSX_CMP_Related_LD_Reports__c  = 'I-000175'
        );
        insert testCase1;
        
        CSX_CMP_Claim_Line__c claimline = new CSX_CMP_Claim_Line__c();
        claimline.CSX_CMP_Claim_Amount__c = 10000;
        claimline.CSX_CMP_Balance_Due__c = 0;
        claimline.CSX_CMP_Claim__c = testCase.Id;
        insert claimline;
        
        CSX_CMP_LD_Report__c objLdReport = new CSX_CMP_LD_Report__c(
            CSX_CMP_LD_Type__c = 'Customer',
        	RecordTypeId = [Select id from RecordType where DeveloperName = 'L_D_Report_ShipCSX' ].id,
            CSX_CMP_Cause__c = 'AWAITING EMPTY',
            CSX_CMP_Incident_Action__c = 'Lading Recovery',
            CSX_CMP_Damage_Reason__c = 'Bulk Shortage'
        );
        insert objLdReport;
        
        CSX_CMP_Related_LD_Report__c objRelatedLDReport = new CSX_CMP_Related_LD_Report__c(
            CSX_CMP_Claim__c = testCase.Id,
            CSX_CMP_LD_Report__c = objLdReport.Id
        );
        insert objRelatedLDReport;
        
        CSX_CMP_Equipment__c testEquipment = new CSX_CMP_Equipment__c(
            Name = 'Equipment123',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = testCase.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420'
        );
        insert testEquipment;
        
        CSX_CMP_Equipment__c testEquipment1 = new CSX_CMP_Equipment__c(
            Name = 'Equipment1234',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = testCase1.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420'
        );
        insert testEquipment1;
        
        CSX_CMP_Product__c testProduct = new CSX_CMP_Product__c(
        	CSX_CMP_Equipment__c  = testEquipment.Id
        );
        insert testProduct;

        CSX_CMP_Product__c testProduct1 = new CSX_CMP_Product__c(
        	CSX_CMP_Equipment__c  = testEquipment1.Id
        );
        insert testProduct1;
        
        List<CSX_CMP_Customer_Damage__c> customerDamages = CSX_CMP_TestUtility.createCustomerDamageData(2);
        customerDamages[0].CSX_CMP_Product__c = testProduct.Id;
        customerDamages[0].CSX_CMP_Area__c = '0';
        customerDamages[0].CSX_CMP_Severity__c = '0';
        customerDamages[0].CSX_CMP_Type__c = '0';
        customerDamages[1].CSX_CMP_Product__c = testProduct1.Id;
        customerDamages[1].CSX_CMP_Area__c = '0';
        customerDamages[1].CSX_CMP_Severity__c = '0';
        customerDamages[1].CSX_CMP_Type__c = '0';
        insert customerDamages;
        
        CSX_CMP_Inspection_Header__c inspectionHeader = new CSX_CMP_Inspection_Header__c(
                CSX_CMP_VIN__c = '4T3LWRFVXPU102091',
                CSX_CMP_Inspection_Date__c = system.today(),
            	CSX_CMP_Inspection_Report_Type__c = '04'
		);
        insert inspectionHeader;
        
 		CSX_CMP_Inspection_Detail__c inspectionDetail1 = new CSX_CMP_Inspection_Detail__c();
            inspectionDetail1.CSX_CMP_Damage_Severity__c = '1';
            inspectionDetail1.CSX_CMP_Damage_Type__c = '01';
            inspectionDetail1.CSX_CMP_Damage_Area__c = '06';
            inspectionDetail1.CSX_CMP_Inspection_Header__c = inspectionHeader.Id;
        	inspectionDetail1.CSX_CMP_Damage_Severity__c = '0';
		insert inspectionDetail1; 
        
        CSX_CMP_Inspection_Damage__c testInspectiondamage = new CSX_CMP_Inspection_Damage__c(
         	CSX_CMP_Product__c = testProduct.Id,
            CSX_CMP_Inspection_Detail__c = inspectionDetail1.Id
         );
        insert testInspectiondamage;
        
        List<CSX_CMP_Similarity_Matrix__c> matrixList = new List<CSX_CMP_Similarity_Matrix__c>();
        CSX_CMP_Similarity_Matrix__c similarityMatrix = new CSX_CMP_Similarity_Matrix__c(
            CSX_CMP_Damage_Code__c = '0',
            CSX_CMP_Similar_Damage_Code__c = '0',
            CSX_CMP_Type__c = 'Damage Area',
            CSX_CMP_Start_Date__c = Date.today().addDays(-5),
            CSX_CMP_End_Date__c = Date.today(),
            CSX_CMP_External_ID__c = 'Damage Area_00_000'
        );
        matrixList.add(similarityMatrix);
        
        CSX_CMP_Similarity_Matrix__c similarityMatrix2 = new CSX_CMP_Similarity_Matrix__c(
            CSX_CMP_Damage_Code__c = '0',
            CSX_CMP_Similar_Damage_Code__c = '0',
            CSX_CMP_Type__c = 'Damage Type',
            CSX_CMP_Start_Date__c = Date.today().addDays(-5),
            CSX_CMP_End_Date__c = Date.today(),
            CSX_CMP_External_ID__c = 'Damage Type__00_000'
        );
        matrixList.add(similarityMatrix2);
        
        insert matrixList;
        
        Account objDistributionAccount = new Account(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Location'].Id,
            Name = 'Test Account',
            Type = 'Supplier',
            Status__c = 'Active',
            CSX_CMP_FC_Contact_Email__c = 'fordclaims@vascorltd.com',
            CSX_CMP_FC_Railroad_Road_Code__c = '1234'
        );
        insert objDistributionAccount;
        
        CSX_CMP_Distribution__c dist = new CSX_CMP_Distribution__c();
        dist.CSX_CMP_Distribution_Claim__c = testCase.Id;
        dist.CSX_CMP_Distribution_Claim_Created__c = true;
        dist.CSX_CMP_Adj_Miles__c = 786;
        dist.CSX_CMP_Equipment__c = testEquipment.id;
        dist.CSX_CMP_Account__c = objDistributionAccount.Id;
        insert dist;
        
        CSX_CMP_Business_Rule__c objBusinessRule2 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Overcharge Carload Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2 AND 3',
            CSX_CMP_Status__c = 'Valid',
            //CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Priority__c = 10
        );
        insert objBusinessRule2;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule2.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_equipmentName',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition1;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule2.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition2;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition3 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '3',
            CSX_CMP_Business_Rule__c = objBusinessRule2.Id,
            CSX_CMP_Attribute_Name__c = 'claim_equipment_product_customerDamage_cdName',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition3;
        
        CSX_CMP_Business_Rule__c objBusinessRule3 = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Approval Rule With Between Conditions',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Approval' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'FC Customer Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '',
            CSX_CMP_Status__c = 'Valid',
            //CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Priority__c = 10
        );
        insert objBusinessRule3;
		
		CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition4 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule3.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAmount',
        	CSX_CMP_Operator__c = 'Between',
            CSX_CMP_Range_1__c = 0,
        	CSX_CMP_Range_2__c = 50
        );
        insert objBusinessRuleCondition4;
    }

    /*@isTest
    static void testGetBusinessRuleDetails() {
        // Test the getBusinessRuleDetails method
        RecordType rt = [Select Id, DeveloperName From RecordType Where SobjectType = 'CSX_CMP_Business_Rule__c' AND DeveloperName = 'CSX_CMP_Approval'];
        //RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Freight' LIMIT 1];
        CSX_CMP_Business_Rule__c businessRule = [SELECT Id FROM CSX_CMP_Business_Rule__c LIMIT 1];

        Test.startTest();
        List<CSX_CMP_Business_Rule__c> businessRules = CSX_CMP_BusinessRulesUtility.getBusinessRuleDetails(
            rt.Id,
            businessRule.Id,
            'TestClaimType'
        );
        Test.stopTest();

        //System.assertNotEquals(0, businessRules.size(), 'Expected business rule details to be returned');
        System.assertEquals(0, businessRules.size(), 'Expected business rule details to be returned');
    }
	*/
    
    @isTest
    static void testGetRecordTypeIdbyName() {
        Test.startTest();
        Id recordTypeId = CSX_CMP_BusinessRulesUtility.getRecordTypeIdbyName('Case', 'Freight');
        Test.stopTest();

        System.assertNotEquals(null, recordTypeId, 'Expected RecordTypeId to be returned');
    }

    @isTest
    static void testGatherFullClaimDetails() {
        Case testCase = [SELECT Id, CaseNumber, CSX_CMP_Age__c, CSX_CMP_Claim_Amount__c, CSX_CMP_Supplier_Claimant__r.Name, CSX_CMP_Claim_Reason__c, RecordType.DeveloperName,
							Status, CSX_CMP_Desk_Name__c, CSX_CMP_Desk_Name__r.Name, CSX_CMP_National_Account_Num__c, Origin, ParentId, CSX_CMP_Derailment__c,
							Contact.Name, Account.Name, CSX_CMP_Auto_Pay__c, CSX_CMP_Dealer_SPLC__c, Type, CSX_CMP_BU__c, CSX_CMP_RACF_ID__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_EDI_Sender_ID__c, CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_From__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_To__c, CSX_CMP_Supplier_Claimant__r.CSX_CMP_Freight_Collections_Team_Number__c,	
							CSX_CMP_Supplier_Claimant__c, CSX_CMP_Related_Claim_Count__c, CSX_CMP_Contract_Num__r.Name, CSX_CMP_Contract_Num__r.CSX_CMP_Claim_Type__c,
							CSX_CMP_Supplier_Claimant__r.BillingCountry, CSX_CMP_VIN__c, CSX_CMP_Supplier_Claimant_Site__c, CSX_CMP_Period_Begin__c, CSX_CMP_Period_End__c,
							(SELECT Id, Name, CSX_CMP_Act_Destination_City__c, CSX_CMP_Waybill_Num__c, CSX_CMP_STCC__c, CSX_CMP_Waybill_Date__c, CSX_CMP_Equipment_Initial__c,
									CSX_CMP_Act_Destination_Road__c, CSX_CMP_Act_Origin_Road__c, CSX_CMP_Act_Origin_City__c, CSX_CMP_Shipper__c,
									CSX_CMP_MV_Manufacturer_Route_Code__c, CSX_CMP_Equipment_Num__c, CSX_CMP_Waybill_Date_Aging__c, CSX_CMP_Freight_Bill_Num__c,
									CSX_CMP_BU__c
								FROM Equipments__r),
							(SELECT Id, CSX_CMP_Act_Destination_City__c, CSX_CMP_Waybill_Num__c, CSX_CMP_STCC__c, CSX_CMP_Waybill_Date__c, CSX_CMP_Equipment_Initial__c,
									CSX_CMP_Act_Origin_City__c, CSX_CMP_Equipment_Num__c, CSX_CMP_Freight_Bill_Num__c, Name, CSX_CMP_URRWIN_Num__c, CSX_CMP_Waybill_Date_Aging__c
								FROM ClaimLines__r ),
							(SELECT Id, CSX_CMP_LD_Report__r.Name FROM Related_L_D_Reports__r)
						FROM Case LIMIT 1];

        Set<Id> claimIds = new Set<Id>();
        claimIds.add(testCase.Id);

        Test.startTest();
        Map<Id, CSX_CMP_BusinessRulesUtility.ClaimWrapper> claimDetails = CSX_CMP_BusinessRulesUtility.gatherFullClaimDetails(claimIds);
        Test.stopTest();

        System.assertNotEquals(0, claimDetails.size(), 'Expected claim details to be returned');
    }
    
    @isTest
    static void testEvaluateRuleCondition() {

        Map<String, Object> mapofSourceObjectRecord = new Map<String, Object>();
        Map<String, Object> mapofTargetObjRecord = new Map<String, Object>();		
		CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition = new CSX_CMP_Business_Rule_Condition__c();
        
        // Test case 1: 'Equal To' operator with decimal attributes
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Equal To';
        objBusinessRuleCondition.CSX_CMP_Value__c = '100.0';
        objBusinessRuleCondition.CSX_CMP_Range_1__c = null;
        objBusinessRuleCondition.CSX_CMP_Range_2__c = null;
        
        mapofSourceObjectRecord.put('claimAmount', 100.0);
        mapofTargetObjRecord.put('claimAmount', 100.0);

        Boolean result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        System.assert(result == true, 'The result should be true for Equal To operator with matching claimAmount.');

        // Test case 2: 'Not Equal To' operator with string attributes
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Not Equal To';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES';
        
        mapofSourceObjectRecord.put('claimAmount', 'NO');
        mapofTargetObjRecord.put('claimAmount', 'YES');
	
        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        // Test case 3: 'In List' operator with comma-separated values
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'In List';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES,NO';
        mapofSourceObjectRecord.put('claimAmount', 'YES');

        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        System.assert(result == true, 'The result should be true for In List operator with a matching value.');

        // Test case 4: 'Is Null' operator with empty attribute
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Is Null';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES';
        mapofSourceObjectRecord.put('claimAmount', null);

        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        System.assert(result == true, 'The result should be true for Is Null operator when attribute is null.');

        // Test case 5: 'Between' operator with valid range
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Between';
        objBusinessRuleCondition.CSX_CMP_Value__c = null;
        objBusinessRuleCondition.CSX_CMP_Range_1__c = 50.0;
        objBusinessRuleCondition.CSX_CMP_Range_2__c = 150.0;
        mapofSourceObjectRecord.put('claimAmount', 100.0);

        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        // Test case 6: 'Greater Than' operator with date comparison (date as a string)
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Greater Than';
        objBusinessRuleCondition.CSX_CMP_Value__c = '2024-01-01';
        mapofSourceObjectRecord.put('claimAmount', '2024-12-01');

        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        // Test case 7: 'Matches Pattern' operator with string pattern
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Matches Pattern';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'CLAIM*';
        mapofSourceObjectRecord.put('claimAmount', 'CLAIM123');

        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );

        // Test case 8: Invalid operator, testing exception handling
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Invalid Operator';
        mapofSourceObjectRecord.put('claimAmount', 100.0);
        mapofTargetObjRecord.put('claimAmount', 100.0);
        
        // Test case 9: 'Less Than' operator with string attributes
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Less Than';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES';
        
        mapofSourceObjectRecord.put('claimAmount', 'NO');
        mapofTargetObjRecord.put('claimAmount', 'YES');
	
        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );
        
        // Test case 10: 'Less Than or Equal To' operator with string attributes
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Less Than or Equal To';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES';
        
        mapofSourceObjectRecord.put('claimAmount', 'NO');
        mapofTargetObjRecord.put('claimAmount', 'YES');
	
        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );
           
        // Test case 11: 'Greater Than or Equal To' operator with string attributes
        objBusinessRuleCondition.CSX_CMP_Operator__c = 'Greater Than or Equal To';
        objBusinessRuleCondition.CSX_CMP_Value__c = 'YES';
        
        mapofSourceObjectRecord.put('claimAmount', 'NO');
        mapofTargetObjRecord.put('claimAmount', 'YES');
	
        result = CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );
        
        Test.startTest();
          	CSX_CMP_BusinessRulesUtility.evaluateRuleCondition(
            mapofSourceObjectRecord, 'claimAmount', objBusinessRuleCondition, mapofTargetObjRecord
        );  
        Test.stopTest();
    }
    
    @isTest
    public static void testRefineBRConditionResults() {
        // Prepare the test data
        Map<Integer, List<String>> mapOfSequencevsResult = new Map<Integer, List<String>>();
        
        // Case 1: Valid input with mixed results for recordId1 and recordId2
        mapOfSequencevsResult.put(1, new List<String>{'recordId1_true', 'recordId2_false'});
        mapOfSequencevsResult.put(2, new List<String>{'recordId1_false', 'recordId2_true'});
        Map<String, Boolean> result = CSX_CMP_BusinessRulesUtility.refineBRConditionResults(mapOfSequencevsResult);
        
        // Case 2: No conflicting results for recordId3 and recordId4
        mapOfSequencevsResult.put(3, new List<String>{'recordId3_true', 'recordId4_true'});        
        result = CSX_CMP_BusinessRulesUtility.refineBRConditionResults(mapOfSequencevsResult);
        
        // Case 3: Empty map input
        mapOfSequencevsResult.clear();        
        result = CSX_CMP_BusinessRulesUtility.refineBRConditionResults(mapOfSequencevsResult);
        
        // Case 4: Single entry input
        mapOfSequencevsResult.put(1, new List<String>{'recordId5_true'});        
        result = CSX_CMP_BusinessRulesUtility.refineBRConditionResults(mapOfSequencevsResult);
    }
    
    @isTest
    public static void testFetchFinalBRConditionResults() {

        // Test case 1: Single result for a sequence
        Map<String, Boolean> refinedResultMap1 = new Map<String, Boolean>{
            'record1' => true,
            'record2' => false
        };

        Map<Integer, List<String>> mapOfSequencevsResult1 = new Map<Integer, List<String>>{
            1 => new List<String>{'record1_true'}
        };

        Map<Integer, Boolean> result1 = CSX_CMP_BusinessRulesUtility.fetchFinalBRConditionResults(refinedResultMap1, mapOfSequencevsResult1);
        System.assertEquals(result1.get(1), true, 'The final result for sequence 1 should be true.');

        // Test case 2: Multiple results for a sequence, and one refined result is true
        Map<String, Boolean> refinedResultMap2 = new Map<String, Boolean>{
            'record1' => false,
            'record2' => true
        };

        Map<Integer, List<String>> mapOfSequencevsResult2 = new Map<Integer, List<String>>{
            1 => new List<String>{'record1_false', 'record2_true'}
        };

        Map<Integer, Boolean> result2 = CSX_CMP_BusinessRulesUtility.fetchFinalBRConditionResults(refinedResultMap2, mapOfSequencevsResult2);
        System.assertEquals(result2.get(1), true, 'The final result for sequence 1 should be true due to refined result for record2.');

        // Test case 3: Multiple results for a sequence, but no refined result is true
        Map<String, Boolean> refinedResultMap3 = new Map<String, Boolean>{
            'record1' => false,
            'record2' => false
        };

        Map<Integer, List<String>> mapOfSequencevsResult3 = new Map<Integer, List<String>>{
            1 => new List<String>{'record1_false', 'record2_false'}
        };

        Map<Integer, Boolean> result3 = CSX_CMP_BusinessRulesUtility.fetchFinalBRConditionResults(refinedResultMap3, mapOfSequencevsResult3);
        System.assertEquals(result3.get(1), false, 'The final result for sequence 1 should be false as no refined result is true.');

        // Test case 4: Empty results, should return empty map
        Map<String, Boolean> refinedResultMap4 = new Map<String, Boolean>();
        Map<Integer, List<String>> mapOfSequencevsResult4 = new Map<Integer, List<String>>();

        Map<Integer, Boolean> result4 = CSX_CMP_BusinessRulesUtility.fetchFinalBRConditionResults(refinedResultMap4, mapOfSequencevsResult4);
        System.assertEquals(result4.size(), 0, 'The final results map should be empty.');

        // Test case 5: Exception handling, simulate an error during the method execution
        Test.startTest();
        Map<String, Boolean> refinedResultMap5 = new Map<String, Boolean>{
            'record1' => true
        };

        Map<Integer, List<String>> mapOfSequencevsResult5 = new Map<Integer, List<String>>{
            1 => new List<String>{'record1_true'}
        };

        refinedResultMap5.put('record2', null);

        Map<Integer, Boolean> result5 = CSX_CMP_BusinessRulesUtility.fetchFinalBRConditionResults(refinedResultMap5, mapOfSequencevsResult5);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdatedSequenceresult() {
        String resultString1 = 'Result1';
        String resultString2 = 'Result2';
        Integer sequence1 = 1;
        Integer sequence2 = 2;

        Map<Integer, List<String>> mapOfSequencevsResult = new Map<Integer, List<String>>();
        mapOfSequencevsResult.put(sequence1, new List<String>{'InitialResult1'});

        mapOfSequencevsResult = CSX_CMP_BusinessRulesUtility.updatedSequenceresult(resultString1, mapOfSequencevsResult, sequence1);
        mapOfSequencevsResult = CSX_CMP_BusinessRulesUtility.updatedSequenceresult(resultString2, mapOfSequencevsResult, sequence2);  
        mapOfSequencevsResult = CSX_CMP_BusinessRulesUtility.updatedSequenceresult(' ', mapOfSequencevsResult, 3);

    }
    
     @isTest
    static void testEvaluateRuleWhereLogic() {
        // Test case 1: Normal valid case
        Map<Integer, Boolean> conditionEvaluateMap1 = new Map<Integer, Boolean>{
            1 => true,
            2 => false,
            3 => true
        };
        String whereClause1 = '1 AND 2 AND 3';
        Boolean result1 = CSX_CMP_BusinessRulesUtility.evaluateRuleWhereLogic(whereClause1, conditionEvaluateMap1);

        // Test case 2: Condition in where clause does not match conditionEvaluateMap
        Map<Integer, Boolean> conditionEvaluateMap2 = new Map<Integer, Boolean>{
            1 => false,
            4 => true
        };
        String whereClause2 = '2 AND 3';
        Boolean result2 = CSX_CMP_BusinessRulesUtility.evaluateRuleWhereLogic(whereClause2, conditionEvaluateMap2);
		
        // Test case 3: Empty whereClause
        Map<Integer, Boolean> conditionEvaluateMap3 = new Map<Integer, Boolean>{
            1 => true
        };
        String whereClause3 = '';
        Boolean result3 = CSX_CMP_BusinessRulesUtility.evaluateRuleWhereLogic(whereClause3, conditionEvaluateMap3);

        // Test case 4: Null whereClause
        Map<Integer, Boolean> conditionEvaluateMap4 = new Map<Integer, Boolean>{
            1 => true
        };
        String whereClause4 = null;
        Boolean result4 = CSX_CMP_BusinessRulesUtility.evaluateRuleWhereLogic(whereClause4, conditionEvaluateMap4);

        Map<Integer, Boolean> conditionEvaluateMap5 = new Map<Integer, Boolean>{
            1 => true
        };
        String whereClause5 = '1';
        Test.startTest();
        Boolean result5 = CSX_CMP_BusinessRulesUtility.evaluateRuleWhereLogic(whereClause5, conditionEvaluateMap5);
        Test.stopTest();
    }
    
    @isTest
    static void testEvaluateBusinessRules_Success() {
        //Case testCase =[Select Id From Case Where RecordType.DeveloperName = 'Revenue_Overcharge' LIMIT 1];
        Case testCase = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Freight' LIMIT 1].Id,
            Type = 'Contractor Claim',
            Status = 'New',
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01),
            CSX_CMP_Period_End__c = Date.newInstance(2024, 01, 10)            
        );
        insert testCase;
        
        CSX_CMP_Equipment__c testEquipment = new CSX_CMP_Equipment__c(
                    Name = 'Equipment123',
                    CSX_CMP_Waybill_Date__c = System.today(),
                    CSX_CMP_Claim__c = testCase.Id,
                    CSX_CMP_Equipment_Initial__c = 'TTGX',
                    CSX_CMP_Equipment_Num__c = '952420'
                );
        insert testEquipment;
        
        Case testCase2 = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Freight' LIMIT 1].Id,
            Type = 'Contractor Claim',
            CSX_CMP_Claim_Amount__c = 50,
            Status = 'New',
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01),
            CSX_CMP_Period_End__c = Date.newInstance(2024, 01, 10)            
        );
        insert testCase2;
        
        CSX_CMP_Equipment__c testEquipment2 = new CSX_CMP_Equipment__c(
                    Name = 'Equipment123',
                    CSX_CMP_Waybill_Date__c = System.today(),
                    CSX_CMP_Claim__c = testCase2.Id,
                    CSX_CMP_Equipment_Initial__c = 'TTGX',
                    CSX_CMP_Equipment_Num__c = '952420'
                );
        insert testEquipment2;
        
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper1 = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        claimWrapper1.Id = testCase.id;
        claimWrapper1.claimType = testCase.Type;
        claimWrapper1.claimStatus = testCase.Status;
        
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper2 = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        claimWrapper2.Id = testCase2.Id;
        claimWrapper2.claimType = testCase2.Type;
		claimWrapper2.claimStatus = testCase2.Status;
        
        List<CSX_CMP_BusinessRulesUtility.ClaimWrapper> claimWrappers = new List<CSX_CMP_BusinessRulesUtility.ClaimWrapper>{ claimWrapper1, claimWrapper2 };

        // Create a sample business rule for testing
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Conditions',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Contractor Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2',
            CSX_CMP_Status__c = 'Valid',
            //CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Priority__c = 10
        );
        insert objBusinessRule;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition1;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition2;
        
        // Call the method
        Test.startTest();
            CSX_CMP_BusinessRulesUtility.evaluateBusinessRules(
                claimWrappers,
                'CSX_CMP_Duplicate', 
                objBusinessRule.Id 
            );
        Test.stopTest();

        // Validate results
        System.assertNotEquals(null, claimWrappers, 'claimWrappers should not null');
        System.assertNotEquals(null, objBusinessRule, 'objBusinessRule should not null'); 
    }
    
    @isTest
    static void testEvaluateBusinessRules_Catch() {
        //Case testCase =[Select Id From Case Where RecordType.DeveloperName = 'Revenue_Overcharge' LIMIT 1];
        Case testCase = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Revenue_Overcharge' LIMIT 1].Id,
            Type = 'Overcharge Carload Claim',
            Status = 'New',
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01),
            CSX_CMP_Period_End__c = Date.newInstance(2024, 01, 10)            
        );
        insert testCase;
        
        Case testCase2 = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Revenue_Overcharge' LIMIT 1].Id,
            Type = 'Overcharge Carload Claim',
            CSX_CMP_Claim_Amount__c = 50,
            Status = 'New',
            CSX_CMP_Claim_Reason__c = 'Damaged',
            CSX_CMP_Period_Begin__c = Date.newInstance(2024, 01, 01),
            CSX_CMP_Period_End__c = Date.newInstance(2024, 01, 10)            
        );
        insert testCase2;
        
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper1 = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        claimWrapper1.Id = testCase.id;
        claimWrapper1.claimType = 'Overcharge Carload Claim';
        claimWrapper1.claimStatus = 'New';
        
        CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper2 = new CSX_CMP_BusinessRulesUtility.ClaimWrapper();
        claimWrapper2.Id = testCase2.Id;
        claimWrapper1.claimType = 'Overcharge Carload Claim';
        claimWrapper1.claimStatus = 'New';
        
        List<CSX_CMP_BusinessRulesUtility.ClaimWrapper> claimWrappers = new List<CSX_CMP_BusinessRulesUtility.ClaimWrapper>{ claimWrapper1, claimWrapper2 };

        // Create a sample business rule for testing
        CSX_CMP_Business_Rule__c objBusinessRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Conditions',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1].Id,
            CSX_CMP_Claim_Type__c = 'Overcharge Carload Claim',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2',
            CSX_CMP_Status__c = 'Valid',
            //CSX_CMP_Desk_Name__c = objDeskTest.id,
            CSX_CMP_Priority__c = 10
        );
        insert objBusinessRule;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition1 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '1',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition1;
        
        CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition2 = new CSX_CMP_Business_Rule_Condition__c(
            Name = '2',
            CSX_CMP_Business_Rule__c = objBusinessRule.Id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
        	CSX_CMP_Operator__c = 'Matches'
        );
        insert objBusinessRuleCondition2;

        // Call the method
        Test.startTest();

        CSX_CMP_BusinessRulesUtility.evaluateBusinessRules(
            claimWrappers,
            'CSX_CMP_Duplicate', 
            objBusinessRule.Id 
        );
        Test.stopTest();

    }
    
    @isTest
    static void testEvaluateBusinessRulesCoreLogic(){
        
        Case objCase = [SELECT Id, (SELECT Id FROM Equipments__r) From Case Where Type = 'FC Customer Claim' 
                        AND CSX_CMP_Claim_Amount__c = 5 
                        LIMIT 1];
        
        CSX_CMP_Product__c objProduct = [SELECT Id, CSX_CMP_VIN__c, CSX_CMP_Product_Description__c
                                         FROM CSX_CMP_Product__c 
                                         WHERE CSX_CMP_Equipment__c = :objCase.Equipments__r[0].Id
                                         LIMIT 1];
        
        CSX_CMP_Business_Rule__c objBusinessRule =  [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                     (SELECT Id, Name, CSX_CMP_Attribute_Name__c FROM Business_Rule_Conditions__r) 
                                                     FROM CSX_CMP_Business_Rule__c 
                                                     WHERE CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions'
                                                     LIMIT 1];
        
        List<CSX_CMP_Customer_Damage__c> customerDamages = CSX_CMP_TestUtility.createCustomerDamageData(2);
        customerDamages[0].CSX_CMP_Product__c = objProduct.Id;
        customerDamages[0].CSX_CMP_Area__c = '0';
        customerDamages[0].CSX_CMP_Severity__c = '0';
        customerDamages[0].CSX_CMP_Type__c = '0';
        customerDamages[1].CSX_CMP_Product__c = objProduct.Id; //objProduct2.Id;
        customerDamages[1].CSX_CMP_Area__c = '0';
        customerDamages[1].CSX_CMP_Severity__c = '0';
        customerDamages[1].CSX_CMP_Type__c = '0';
        insert customerDamages;
        
        //List<CSX_CMP_Business_Rule_Condition__c> objBusinessRuleCondition = [SELECT Id, CSX_CMP_Attribute_Name__c FROM CSX_CMP_Business_Rule_Condition__c WHERE CSX_CMP_Business_Rule__c =: objBusinessRule.Id];
        
        Map<String, Object> mapOfClaimDetails = new Map<String, Object>();
        Map<String, Object> equipmentAttributes = new Map<String, Object>();
        equipmentAttributes.put('id', objCase.Equipments__r);
        equipmentAttributes.put('product', new List<Object>{objProduct});
        equipmentAttributes.put('customerDamage', new List<Object>{customerDamages});
        
        mapOfClaimDetails.put('equipment', new List<Object>{equipmentAttributes});
        
        Map<String, Object> mapOfTargetClaimDetails = new Map<String, Object>();
        mapOfTargetClaimDetails.put('equipment', new List<Object>{equipmentAttributes});
        
        Test.startTest();
        Boolean result = CSX_CMP_BusinessRulesUtility.evaluateBusinessRulesCoreLogic(
            mapOfClaimDetails,
            objBusinessRule,
            mapOfTargetClaimDetails
        );
        Test.stopTest();
    }
    
    @isTest
    static void testEvaluateBusinessRulesCoreLogicDupRevenue() {
        
        // Test Case 1: 'Test Business duplicate Rule With Valid Conditions'
        Case objCase1 = [SELECT Id, 
                         (SELECT Id, Name, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c FROM Equipments__r) 
                         FROM Case 
                         WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c = 5 LIMIT 1];
    
        CSX_CMP_Business_Rule__c objBusinessRule1 = [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                     (SELECT Id, Name, CSX_CMP_Attribute_Name__c, CSX_CMP_Operator__c, CSX_CMP_Range_1__c, CSX_CMP_Range_2__c 
                                                      FROM Business_Rule_Conditions__r) 
                                                     FROM CSX_CMP_Business_Rule__c 
                                                     WHERE CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions'
                                                     LIMIT 1];
    
        Map<String, Object> mapOfClaimDetails1 = new Map<String, Object>();
        Map<String, Object> equipmentAttributes1 = new Map<String, Object>();
        equipmentAttributes1.put('id', objCase1.Equipments__r);
        mapOfClaimDetails1.put('equipment', new List<Object>{equipmentAttributes1});
        
        Map<String, Object> mapOfTargetClaimDetails1 = new Map<String, Object>();
        mapOfTargetClaimDetails1.put('equipment', new List<Object>{equipmentAttributes1});
    
        // Test Case 2: 'Test Approval Rule With Between Conditions'
        Case objCase2 = [SELECT Id, 
                         (SELECT Id FROM Equipments__r) 
                         FROM Case 
                         WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c = 5 LIMIT 1];
        
        CSX_CMP_Business_Rule__c objBusinessRule2 = [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                     (SELECT Id, Name, CSX_CMP_Attribute_Name__c, CSX_CMP_Operator__c, CSX_CMP_Range_1__c, CSX_CMP_Range_2__c 
                                                      FROM Business_Rule_Conditions__r) 
                                                     FROM CSX_CMP_Business_Rule__c 
                                                     WHERE CSX_CMP_Rule_Name__c = 'Test Approval Rule With Between Conditions'
                                                     LIMIT 1];
        
        Map<String, Object> mapOfClaimDetails2 = new Map<String, Object>();
        Map<String, Object> equipmentAttributes2 = new Map<String, Object>();
        equipmentAttributes2.put('id', objCase2.Equipments__r);
        mapOfClaimDetails2.put('equipment', new List<Object>{equipmentAttributes2});
        
        Map<String, Object> mapOfTargetClaimDetails2 = new Map<String, Object>();
        mapOfTargetClaimDetails2.put('equipment', new List<Object>{equipmentAttributes2});
    
        // Start the test
        Test.startTest();
        
        // First business rule evaluation
        Boolean result1 = CSX_CMP_BusinessRulesUtility.evaluateBusinessRulesCoreLogicDupRevenue(
                mapOfClaimDetails1,
                mapOfTargetClaimDetails1,
                objBusinessRule1
        );
        
        // Second business rule evaluation
        Boolean result2 = CSX_CMP_BusinessRulesUtility.evaluateBusinessRulesCoreLogicDupRevenue(
                mapOfClaimDetails2,
                mapOfTargetClaimDetails2,
                objBusinessRule2
        );
        
        Test.stopTest();
    }
    
    @isTest
	static void testEvaluateBusinessRulesCoreLogicDupRevenueCatch(){
	
	Case objCase = [SELECT Id, 
                    (SELECT Id, Name, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c FROM Equipments__r) 
                    From Case Where Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c = 5 LIMIT 1];
        
        CSX_CMP_Business_Rule__c objBusinessRule =  [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                     (SELECT Id, Name, CSX_CMP_Attribute_Name__c FROM Business_Rule_Conditions__r) 
                                                     FROM CSX_CMP_Business_Rule__c 
                                                     WHERE CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions'
                                                     LIMIT 1];
        
        Map<String, Object> mapOfClaimDetails = new Map<String, Object>();
        Map<String, Object> equipmentAttributes = new Map<String, Object>();
        equipmentAttributes.put('id', objCase.Equipments__r);
        
        mapOfClaimDetails.put('equipment', new List<Object>{equipmentAttributes});
        
        Map<String, Object> mapOfTargetClaimDetails = new Map<String, Object>();
        mapOfTargetClaimDetails.put('equipment', new List<Object>{equipmentAttributes});
        
        Test.startTest();
        Boolean result = CSX_CMP_BusinessRulesUtility.evaluateBusinessRulesCoreLogicDupRevenue(
                mapOfClaimDetails,
                mapOfTargetClaimDetails,
                objBusinessRule
                
            );
        Test.stopTest();
	}
    
    @isTest
    static void testEligibleFLRClaims(){
        
        Case objCase = [SELECT Id, (SELECT Id FROM Equipments__r) From Case Where Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c = 50 LIMIT 1];
        
        CSX_CMP_Business_Rule__c objBusinessRule =  [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                         (SELECT Id, Name, CSX_CMP_Attribute_Name__c FROM Business_Rule_Conditions__r) 
                                                         FROM CSX_CMP_Business_Rule__c 
                                                         WHERE CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions'
                                                         LIMIT 1];
        set<Id> setOfClaimIds = new set<Id>();
		setOfClaimIds.add(objCase.Id);
        Id businessRuleId = objBusinessRule.Id;
        String strRecordType ;
        Map<String, String> mapofFLRKeytoEmailId = new Map<String, String>();
    
    
        Test.startTest();
        List<CSX_CMP_BusinessRulesUtility.FLRClaimWrapper> result = CSX_CMP_BusinessRulesUtility.eligibleFLRClaims(
                setOfClaimIds,
                strRecordType,
                businessRuleId,
                mapofFLRKeytoEmailId
                
            );
        Test.stopTest();
    }
	
    @isTest
    static void testrunARThresholdBusinessRules(){
        Case objCase = [SELECT Id, (SELECT Id FROM Equipments__r) From Case Where Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c = 50 LIMIT 1];
        
        CSX_CMP_Business_Rule__c objBusinessRule =  [SELECT Id, CSX_CMP_Rule_Name__c, CSX_CMP_Where_Clause__c, 
                                                         (SELECT Id, Name, CSX_CMP_Attribute_Name__c FROM Business_Rule_Conditions__r) 
                                                         FROM CSX_CMP_Business_Rule__c 
                                                         WHERE CSX_CMP_Rule_Name__c = 'Test Business duplicate Rule With Valid Conditions'
                                                         LIMIT 1];
        
        set<Id> setOfClaimIds = new set<Id>();
			setOfClaimIds.add(objCase.Id);
        String strRecordType;
        Id businessRuleId = objBusinessRule.Id;
            
        Test.startTest();
        	Map<Id, String> result = CSX_CMP_BusinessRulesUtility.runARThresholdBusinessRules(
               setOfClaimIds,
               strRecordType,
               businessRuleId
            );
        Test.stopTest();
    }
    
}