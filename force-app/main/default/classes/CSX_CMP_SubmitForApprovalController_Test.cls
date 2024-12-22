@IsTest
public class CSX_CMP_SubmitForApprovalController_Test {
    
    @testSetup
    public static void setupdata() {
        
        // Created a Profile for the user (if required, it can be an existing profile).
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create a test user
        User testUser = new User(
            Username = 'testClaimUser@test.com',
            Email = 'testClaimUser@test.com',
            Alias = 'tcuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FirstName = 'Test Claim',
            LastName = 'User',
            IsActive = true
        );
        insert testUser;
        
        CSX_CMP_Business_Rule__c BusinessRuleApprovalForCustomerClaim = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule for Approval',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Approval' LIMIT 1].Id,
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2'
        );
        insert BusinessRuleApprovalForCustomerClaim;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition1 =  new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = BusinessRuleApprovalForCustomerClaim.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'FC Customer Claim'
        );
        insert testBusinessRuleCondition1;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition2 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '2',
            CSX_CMP_Business_Rule__c = BusinessRuleApprovalForCustomerClaim.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAmount',
            CSX_CMP_Operator__c = 'Between',
            CSX_CMP_Range_1__c = 0,
            CSX_CMP_Range_2__c = 5000
        );
        insert testBusinessRuleCondition2;
        
        CSX_CMP_Approval_Sequence__c testApprovalSequence = new CSX_CMP_Approval_Sequence__c(
        	CSX_CMP_Business_Rule__c = BusinessRuleApprovalForCustomerClaim.Id,
            CSX_CMP_Approver__c = 'CLAIM_AUTO_APPROVE',
            CSX_CMP_Approver_Type__c = 'Function'
        );
        insert testApprovalSequence;
        
        CSX_CMP_Business_Rule__c BusinessRuleBTPForCustomerClaim = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule for BTP Approval',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'CSX_CMP_Approval' LIMIT 1].Id,
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            CSX_CMP_Where_Clause__c = '1 AND 2'
        );
        insert BusinessRuleBTPForCustomerClaim;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition3 =  new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = BusinessRuleBTPForCustomerClaim.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'FC Customer Claim'
        );
        insert testBusinessRuleCondition3;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition4 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '2',
            CSX_CMP_Business_Rule__c = BusinessRuleBTPForCustomerClaim.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimAmount',
            CSX_CMP_Operator__c = 'Between',
            CSX_CMP_Range_1__c = 5001,
            CSX_CMP_Range_2__c = 9999999
        );
        insert testBusinessRuleCondition4;
        
        CSX_CMP_Approval_Sequence__c testBTPApprovalSequence = new CSX_CMP_Approval_Sequence__c(
        	CSX_CMP_Business_Rule__c = BusinessRuleBTPForCustomerClaim.Id,
            CSX_CMP_Approver__c = 'COA_PROCESS',
            CSX_CMP_Approver_Type__c = 'Function'
        );
        insert testBTPApprovalSequence;
        
        Account FreightClaimAccount = new Account(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Location'].Id,
            Name = 'Test Account',
            Type = 'Supplier',
            Status__c = 'Active',
            National_Account__c = '12345'
        );
        insert FreightClaimAccount;
        
        Case FreightClaim = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 4000,
            CSX_CMP_Original_Amount__c = 10500,
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'Open',
            CSX_CMP_FCD_Cause_Code__c = '01',
        	CSX_CMP_FCD_Rule_Code__c = '040',
            OwnerId = UserInfo.getUserId()
        );
		insert FreightClaim;
        
        CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c(
            Name = 'Equipment123',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = FreightClaim.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420',
            CSX_CMP_Waybill_Controls__c = '1000'
        );
        insert equipment;
        
        CSX_CMP_Notes__c objNotes = new CSX_CMP_Notes__c(
        	CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation',
            CSX_CMP_Notes__c = 'Test data',
            CSX_CMP_Claim__c = FreightClaim.Id
        ); 
        insert objNotes;
        
        CSX_CMP_LD_Report__c objLdReport = new CSX_CMP_LD_Report__c(
            CSX_CMP_LD_Type__c = 'Customer',
        	RecordTypeId = [Select id from RecordType where DeveloperName = 'L_D_Report_ShipCSX' ].id,
            CSX_CMP_Cause__c = 'AWAITING EMPTY',
            CSX_CMP_Incident_Action__c = 'Lading Recovery',
            CSX_CMP_Damage_Reason__c = 'Bulk Shortage'
        );
        insert objLdReport;
        
        CSX_CMP_Related_LD_Report__c objRelatedLDReport = new CSX_CMP_Related_LD_Report__c(
        	CSX_CMP_Claim__c = FreightClaim.Id,
            CSX_CMP_LD_Report__c = objLdReport.Id
        );
        insert objRelatedLDReport;
        
        CSX_CMP_Product__c FreightClaimProduct = new CSX_CMP_Product__c(
        	CSX_CMP_Equipment__c = equipment.Id,
            CSX_CMP_Product_Description__c = 'DemoClaim3'
        );
        insert FreightClaimProduct;
        
        CSX_CMP_Distribution__c FreightClaimDistribution = new CSX_CMP_Distribution__c(
        	CSX_CMP_Miles__c = 600,
            CSX_CMP_Equipment__c = equipment.Id,
            CSX_CMP_Account__c = FreightClaimAccount.Id
        );
        insert FreightClaimDistribution;
        
        Case FreightClaim2 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Automobile Claim',
            CSX_CMP_Claim_Amount__c = -10000,
            CSX_CMP_Original_Amount__c = 12500,
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            //CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = '',
            CSX_CMP_VIN__c = 'Test',
            Status = 'New',
            CSX_CMP_FCD_Cause_Code__c = '',
        	CSX_CMP_FCD_Rule_Code__c = '',
            OwnerId = UserInfo.getUserId()
        );
		insert FreightClaim2;
        
        Task objTask = new Task(
            Subject = 'Call',
        	Priority = 'Normal',
            Status = 'Open',
            WhatId = FreightClaim2.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert objTask;
        
        Case FreightClaim3 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 4000,
            CSX_CMP_Original_Amount__c = 10500,
            //CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'New',
            //CSX_CMP_FCD_Cause_Code__c = '01',
        	//CSX_CMP_FCD_Rule_Code__c = '040',
            OwnerId = UserInfo.getUserId()
        );
		insert FreightClaim3;
        
        Case FreightClaim4 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'Contractor Claim',
            CSX_CMP_Claim_Amount__c = 4000,
            CSX_CMP_Original_Amount__c = 10500,
            //CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'New',
            //CSX_CMP_FCD_Cause_Code__c = '01',
        	//CSX_CMP_FCD_Rule_Code__c = '040',
            OwnerId = testUser.id
        );
		insert FreightClaim4;
       
		Account FreightClaimAccount2 = new Account(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Location'].Id,
            Name = 'Test Account',
            Type = 'Supplier',
            Status__c = 'Inactive',
            National_Account__c = '12345'
        );
        insert FreightClaimAccount2;
        
        Case OverchargeClaim6 = new Case(  					
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Revenue_Overcharge'].Id,
            Type = 'Overcharge Carload INCD Claim',
            //CSX_CMP_Claim_Amount__c = 4000,
            //CSX_CMP_Original_Amount__c = 10500,
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount2.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            //CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'Open'
        );
		insert OverchargeClaim6;
        
        Case OverchargeClaim8 = new Case(  					
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Revenue_Overcharge'].Id,
            Type = 'Overcharge Carload Claim',
            CSX_CMP_Claim_Amount__c = 4000,
            CSX_CMP_Original_Amount__c = 10500,
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'Open'
        );
		insert OverchargeClaim8;
        
        CSX_CMP_Notes__c objNotes3 = new CSX_CMP_Notes__c(
        	CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation',
            CSX_CMP_Notes__c = 'Test data',
            CSX_CMP_Claim__c = OverchargeClaim8.Id
        ); 
        insert objNotes3;
        
        
        Task objTask2 = new Task(
            Subject = 'Call',
        	Priority = 'Normal',
            Status = 'Completed',
            WhatId = OverchargeClaim6.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert objTask2;
        
        CSX_CMP_Notes__c objNotes2 = new CSX_CMP_Notes__c(
        	CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation',
            CSX_CMP_Notes__c = 'Test data',
            CSX_CMP_Claim__c = OverchargeClaim6.Id
        ); 
        insert objNotes2;
        
        Case OverchargeClaim7 = new Case(  					
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Revenue_Overcharge'].Id,
            Type = 'Incentive Claim',
            CSX_CMP_Derailment__c = true,
            Status = 'New'
        );
		insert OverchargeClaim7;
        
        Case FreightClaim8 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 8000,
            CSX_CMP_Original_Amount__c = 10500,
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Total_Cost_of_Claim__c = 1000,
            CSX_CMP_Derailment__c = true,
            CSX_CMP_Remarks__c = 'Test',
            CSX_CMP_VIN__c = 'Test',
            Status = 'Open',
            CSX_CMP_FCD_Cause_Code__c = '01',
        	CSX_CMP_FCD_Rule_Code__c = '040',
            OwnerId = UserInfo.getUserId()
        );
		insert FreightClaim8;
        
    }
       
    @IsTest
    static void testSubmitForApproval(){
        
        User testClaimUser = [SELECT Id FROM User Limit 1];        
        
        case ValidatedfreightClaim = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        (SELECT Id FROM Tasks WHERE Status != 'Completed'),
                        (SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation'),        
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight'
                        AND Type = 'FC Customer Claim' AND Status = 'Open'
                        AND CSX_CMP_Remarks__c != null
                      	LIMIT 1];
        
        case invalidFreightClaim2 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        (SELECT Id FROM Tasks WHERE Status != 'Completed'),
                        (SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation'), 
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight'
                        AND Type = 'FC Customer Automobile Claim' AND Status = 'New'
                        AND CSX_CMP_Remarks__c = null AND CSX_CMP_FCD_Cause_Code__c = null AND CSX_CMP_FCD_Rule_Code__c = null
                      	LIMIT 1];
        
        case InvalidOverchargeClaim4 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Revenue_Overcharge'
						AND Status = 'Open'
                        AND Type = 'Overcharge Carload INCD Claim'
                      	LIMIT 1];   
        if (InvalidOverchargeClaim4.CSX_CMP_Claim_Amount__c != null &&
            InvalidOverchargeClaim4.CSX_CMP_Original_Amount__c != null &&
            InvalidOverchargeClaim4.CSX_CMP_Claim_Amount__c != InvalidOverchargeClaim4.CSX_CMP_Original_Amount__c) 
        	{
                InvalidOverchargeClaim4.CSX_CMP_Claim_Amount__c = InvalidOverchargeClaim4.CSX_CMP_Original_Amount__c;
                update InvalidOverchargeClaim4;
             }
       
        Test.startTest();
	      	List<CSX_CMP_SubmitForApprovalController.OutputValues> result = CSX_CMP_SubmitForApprovalController.submitForApproval(ValidatedfreightClaim.Id);
        	List<CSX_CMP_SubmitForApprovalController.OutputValues> result2 = CSX_CMP_SubmitForApprovalController.submitForApproval(invalidFreightClaim2.Id);
        	List<CSX_CMP_SubmitForApprovalController.OutputValues> result5 = CSX_CMP_SubmitForApprovalController.submitForApproval(InvalidOverchargeClaim4.Id);
        	
        Test.stopTest();
        system.assertNotEquals(null, result, 'result should not be null');
        system.assertNotEquals(null, result2, 'result2 should not be null');
        system.assertNotEquals(null, result5, 'result5 should not be null');
    }
    
    @isTest
    static void testOverchargeSubmitForApproval() {
        User testClaimUser = [SELECT Id FROM User Limit 1];
        
        case validOverchargeClaim4 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Revenue_Overcharge'
						AND Status = 'Open'
                        AND Type = 'Overcharge Carload Claim' AND CSX_CMP_Claim_Amount__c != null AND CSX_CMP_Original_Amount__c != null
                      	LIMIT 1];        	
        
         case invalidFreightClaim2 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
						OwnerId,
                        (SELECT Id FROM Tasks WHERE Status != 'Completed'),
                        (SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation'), 
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight'
                        AND Type = 'FC Customer Automobile Claim' AND Status = 'New'
                      	LIMIT 1];
        if(invalidFreightClaim2.OwnerId == UserInfo.getUserId()) {
            invalidFreightClaim2.OwnerId = testClaimUser.Id;
        	update invalidFreightClaim2;
        }
        
        
        Test.startTest();
        List<CSX_CMP_SubmitForApprovalController.OutputValues> result5 = CSX_CMP_SubmitForApprovalController.submitForApproval(validOverchargeClaim4.Id);
        List<CSX_CMP_SubmitForApprovalController.OutputValues> result3 = CSX_CMP_SubmitForApprovalController.submitForApproval(invalidFreightClaim2.Id);
        Test.stopTest();
         system.assertNotEquals(null, result5, 'result5 should not be null');
         system.assertNotEquals(null, result3, 'result3 should not be null');
        
    }
    
    @isTest
    static void testClaimApprovalEvalutionForARBalance(){
        
        Case OverchargeClaim = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        CSX_CMP_National_Account_Num__c,
                        RecordType.DeveloperName FROM case 
						WHERE RecordType.DeveloperName = 'Revenue_Overcharge' AND CSX_CMP_Supplier_Claimant__c != null
                        LIMIT 1];
        if(OverchargeClaim.Type != 'Incentive Claim') {
            OverchargeClaim.Type = 'Incentive Claim';
            update OverchargeClaim;
        }
        
        Case OverchargeClaim2 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        CSX_CMP_National_Account_Num__c,
                        RecordType.DeveloperName FROM case 
						WHERE RecordType.DeveloperName = 'Revenue_Overcharge' AND Status = 'New'
                        LIMIT 1];
        
        Test.startTest();
            Map<String, Map<Id, Boolean>> mockMap = new Map<String, Map<Id, Boolean>>{
                'Incentive' => new Map<Id, Boolean>{ OverchargeClaim.Id => true }
            };
        	List<CSX_CMP_SubmitForApprovalController.OutputValues> result = CSX_CMP_SubmitForApprovalController.claimApprovalEvalutionForARBalance(OverchargeClaim.Id);
        	List<CSX_CMP_SubmitForApprovalController.OutputValues> result2 = CSX_CMP_SubmitForApprovalController.claimApprovalEvalutionForARBalance(OverchargeClaim2.Id);
        Test.stopTest();
        system.assertNotEquals(null, result, 'result should not be null');
        //system.assertNotEquals(null, result2, 'result2 should not be null');
    }
    
    @IsTest
    static void testCallApprovalBusinessRules() {
        
        CSX_CMP_Business_Rule__c businessRule1 = [SELECT Id, CSX_CMP_Rule_Name__c FROM CSX_CMP_Business_Rule__c 
                                                 WHERE RecordType.DeveloperName = 'CSX_CMP_Approval' 
                                                 AND CSX_CMP_Rule_Name__c = 'Test Business Rule for Approval'
                                                 LIMIT 1];
        CSX_CMP_Business_Rule__c businessRule2 = [SELECT Id, CSX_CMP_Rule_Name__c FROM CSX_CMP_Business_Rule__c 
                                                 WHERE RecordType.DeveloperName = 'CSX_CMP_Approval' 
                                                 AND CSX_CMP_Rule_Name__c = 'Test Business Rule for BTP Approval'
                                                 LIMIT 1];
        
        Case FreightClaim = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight' AND Type = 'FC Customer Claim'
                        AND CSX_CMP_Claim_Amount__c < 5000 
                        LIMIT 1];
        FreightClaim.Status = 'Open';
        //FreightClaim.CSX_CMP_Claim_Amount__c = 4000;
        FreightClaim.CSX_CMP_System_Action_Toggle__c = !FreightClaim.CSX_CMP_System_Action_Toggle__c;
        update FreightClaim;
        
        Case FreightClaim2 = [SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight' AND Type = 'FC Customer Claim'
                        AND CSX_CMP_Claim_Amount__c > 5000 
                        LIMIT 1];
        FreightClaim2.Status = 'Open';
        FreightClaim2.CSX_CMP_System_Action_Toggle__c = !FreightClaim2.CSX_CMP_System_Action_Toggle__c;
        update FreightClaim2;
        
        
        
        Test.startTest();
        	List<CSX_CMP_SubmitForApprovalController.OutputValues> result = CSX_CMP_SubmitForApprovalController.callApprovalBusinessRules(string.ValueOf(FreightClaim.Id));
			List<CSX_CMP_SubmitForApprovalController.OutputValues> result2 = CSX_CMP_SubmitForApprovalController.callApprovalBusinessRules(string.ValueOf(FreightClaim2.Id));
        	
        Test.stopTest();
        system.assertNotEquals(null, result, 'result should not be null');
        system.assertNotEquals(null, result2, 'result2 should not be null');
    }
    
    @IsTest
    static void testUpdateClaimOnHold(){
        
        Case freightClaim =[SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        (SELECT Id, CSX_CMP_Type__c, CSX_CMP_Emails__c FROM Claim_Contacts__r WHERE CSX_CMP_Type__c = 'Reported By'),
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Freight' LIMIT 1];
        
         CSX_CMP_Claim_Contact__c objClaimContact = new CSX_CMP_Claim_Contact__c(
        	CSX_CMP_Emails__c = 'test@gmail.com',
            CSX_CMP_Person__c = 'Test',
            CSX_CMP_Claim__c = freightClaim.Id,
             CSX_CMP_Type__c = 'Reported By'
        );
        insert objClaimContact;
        
        Case overchargeClaim =[SELECT Id,
                        Type,
	                    Status,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Original_Amount__c,
	                	CSX_CMP_Derailment__c,
                        CSX_CMP_Supplier_Claimant__r.Status__c,
						CSX_CMP_Total_Cost_of_Claim__c,
                        CSX_CMP_System_Action_Toggle__c,
                        (SELECT Id, CSX_CMP_Type__c, CSX_CMP_Emails__c FROM Claim_Contacts__r WHERE CSX_CMP_Type__c = 'Reported By'),
                        RecordType.DeveloperName FROM case WHERE RecordType.DeveloperName = 'Revenue_Overcharge' LIMIT 1];
        
         CSX_CMP_Claim_Contact__c objClaimContact2 = new CSX_CMP_Claim_Contact__c(
        	CSX_CMP_Emails__c = 'test@gmail.com',
            CSX_CMP_Person__c = 'Test',
            CSX_CMP_Claim__c = overchargeClaim.Id,
             CSX_CMP_Type__c = 'Reported By'
        );
        insert objClaimContact2;
        
        Test.startTest();
            boolean result = CSX_CMP_SubmitForApprovalController.updateClaimOnHold(freightClaim.Id);
        	boolean result2 = CSX_CMP_SubmitForApprovalController.updateClaimOnHold(overchargeClaim.Id);
        Test.stopTest();
        system.assertNotEquals(null, freightClaim, 'freightClaim should not be null');
        system.assertNotEquals(null, overchargeClaim, 'overchargeClaim should not be null');
        
    }
}