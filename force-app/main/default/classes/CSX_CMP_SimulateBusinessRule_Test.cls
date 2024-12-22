@isTest
public class CSX_CMP_SimulateBusinessRule_Test {
    
    @testSetup
    static void testData(){
        
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
        
        CSX_CMP_Approval_Sequence__c objApprovalSequence = new CSX_CMP_Approval_Sequence__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = BusinessRuleApprovalForCustomerClaim.Id,
            CSX_CMP_Approver__c = 'CLAIM_AUTO_APPROVE',
            CSX_CMP_Approver_Type__c = 'Function'
        );
        insert objApprovalSequence;
        
        CSX_CMP_Business_Rule__c autoDeclineRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For Decline',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_Auto_decline'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert autoDeclineRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition3 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = autoDeclineRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'In List',
            CSX_CMP_Value__c = 'New, Autopay Kickout'
        );
        insert testBusinessRuleCondition3;
        
        CSX_CMP_Business_Rule__c autoPayKickoutRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For AutoPay Kickout',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_Auto_pay_kickout'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert autoPayKickoutRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition4 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = autoPayKickoutRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimSource',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'EDI'
        );
        insert testBusinessRuleCondition4;
        
        CSX_CMP_Business_Rule__c deskAssignmentRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For Claim Desk Assignment',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_Claim_Desk_Assignment'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert deskAssignmentRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition5 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = deskAssignmentRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'Incentive Claim'
        );
        insert testBusinessRuleCondition5;
        
        CSX_CMP_Business_Rule__c priorityClaimRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For Claim Priority',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_Claim_Priority'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert priorityClaimRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition6 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = priorityClaimRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_recordType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'Freight'
        );
        insert testBusinessRuleCondition6;
        
		CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c(
        	Name = 'Test Desk'
        );
        insert objDesk;
        
        CSX_CMP_FLR_Email_Master__c objFLRemail = new CSX_CMP_FLR_Email_Master__c(
        	CSX_CMP_Railroad_Code__c = '111',
        	CSX_CMP_Desk_Name__c = objDesk.Id
        );
        insert objFLRemail;

        CSX_CMP_Business_Rule__c flrRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For FLR ',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_FLR'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert flrRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition7 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = flrRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'FC Customer Claim'
        );
        insert testBusinessRuleCondition7;
        
        CSX_CMP_Business_Rule__c ARthreshold = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For AR Threshold ',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_AR_Threshold'].Id,
            CSX_CMP_Status__c = 'Valid',
            CSX_CMP_AR_Threshold_Amount__c = 10000,
            CSX_CMP_Finance_Charge_Threshold__c = 15000
        );
        insert ARthreshold;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition8 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = ARthreshold.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimType',
            CSX_CMP_Operator__c = 'Equal To',
            CSX_CMP_Value__c = 'Incentive Claim'
        );
        insert testBusinessRuleCondition8;
        
        CSX_CMP_Business_Rule__c duplicateRule = new CSX_CMP_Business_Rule__c(
            CSX_CMP_Rule_Name__c = 'Test Business Rule For Duplicate ',
            CSX_CMP_Start_Date__c = Date.newInstance(2024, 9, 18),
            RecordTypeId = [Select Id, DeveloperName From RecordType Where DeveloperName = 'CSX_CMP_Duplicate'].Id,
            CSX_CMP_Status__c = 'Valid'
        );
        insert duplicateRule;
        
        CSX_CMP_Business_Rule_Condition__c testBusinessRuleCondition9 = new CSX_CMP_Business_Rule_Condition__c(
        	Name = '1',
            CSX_CMP_Business_Rule__c = duplicateRule.id,
            CSX_CMP_Attribute_Name__c = 'claim_claimStatus',
            CSX_CMP_Operator__c = 'Not Equal To',
            CSX_CMP_Value__c = 'Declined, Re-Declined, Cancelled, Rejected'
        );
        insert testBusinessRuleCondition9;
        
        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            Status = 'New'
        );
        insert testCase1;
        
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
            CSX_CMP_Supplier_Claimant__c = FreightClaimAccount.Id,
            CSX_CMP_Original_Amount__c = 10500,
            Origin = 'EDI'
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
        
        
        Case FreightClaim2 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 10000,
            CSX_CMP_Original_Amount__c = 10500,
            Status = 'Open'
        );
		insert FreightClaim2;
        
        Case FreightClaim3 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 100,
            CSX_CMP_Original_Amount__c = 10500,
            Status = 'Autopay Kickout'
        );
		insert FreightClaim3;
        
        CSX_CMP_Equipment__c equipment1 = new CSX_CMP_Equipment__c(
            Name = 'Equipment123',
            CSX_CMP_Waybill_Date__c = System.today(),
            CSX_CMP_Claim__c = FreightClaim3.Id,
            CSX_CMP_Equipment_Initial__c = 'TTGX',
            CSX_CMP_Equipment_Num__c = '952420',
			CSX_CMP_STCC__c = '12345'
        );
        insert equipment1;
        
        Case FreightClaim4 = new Case(
        	RecordTypeId = [Select Id from RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'Incentive Claim'
        );
		insert FreightClaim4;
        
    }
    
    @isTest
    static void getCaseDetails(){
        Case freightClaim = [SELECT Id From Case WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c > 5000 LIMIT 1];
        Case freightClaim2 = [SELECT Id From Case WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c < 5000 LIMIT 1];
        
        Test.startTest();
            CSX_CMP_SimulateBusinessRule.UserInput input = new CSX_CMP_SimulateBusinessRule.UserInput();
            input.strCaseId = freightClaim.Id;
            input.strRecordTypeName = 'CSX_CMP_Approval';
            
            CSX_CMP_SimulateBusinessRule.UserInput input2 = new CSX_CMP_SimulateBusinessRule.UserInput();
            input2.strCaseId = freightClaim2.Id;
            input2.strRecordTypeName = 'CSX_CMP_Approval';
            List<CSX_CMP_SimulateBusinessRule.OutputValues> result = CSX_CMP_SimulateBusinessRule.getCaseDetails(
                new List<CSX_CMP_SimulateBusinessRule.UserInput>{input, input2});
        Test.stopTest();
    }
    
    @isTest
    static void testGetClaim() {
        Case objClaim = [SELECT Id From Case limit 1];

        Test.startTest();
        List<Case> result = CSX_CMP_SimulateBusinessRule.getClaim();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        
    }
    
    @isTest
    static void testgetBusinessRule() {
        CSX_CMP_FLR_Email_Master__c flrEmailMaster = [SELECT id, CSX_CMP_Railroad_Code__c FROM CSX_CMP_FLR_Email_Master__c LIMIT 1];
        Case approvalClaim = [SELECT Id, Type, CSX_CMP_Claim_Amount__c From Case WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c != null AND CSX_CMP_Claim_Amount__c < 5000 LIMIT 1];
        
        Case autoDeclineClaim = [SELECT Id From Case WHERE Type = 'FC Customer Claim' AND CSX_CMP_Claim_Amount__c > 250
                                 AND (Status = 'New' OR Status = 'Autopay Kickout')
                                 LIMIT 1];
        Case autoPayKickoutClaim = [SELECT Id From Case WHERE Type = 'FC Customer Claim' AND Origin != null LIMIT 1];
        Case deskAssignmentClaim = [SELECT Id From Case WHERE Type = 'Incentive Claim' LIMIT 1];
        Case priorityClaim = [SELECT Id From Case WHERE RecordType.DeveloperName = 'Freight' LIMIT 1];
        Case flrClaim = [SELECT Id From Case WHERE Type = 'FC Customer Claim' LIMIT 1];
        Case arThresholdClaim = [SELECT Id From Case WHERE Type = 'Incentive Claim' LIMIT 1];
        Case duplicateClaim = [SELECT Id From Case WHERE Status != 'Declined' OR Status != 'Re-Declined' OR Status != 'Cancelled' OR Status != 'Rejected' LIMIT 1];
        
        CSX_CMP_Business_Rule__c approvalRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Approval' LIMIT 1];
        CSX_CMP_Business_Rule__c autoDeclineRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Auto_decline' LIMIT 1];
        CSX_CMP_Business_Rule__c autoPayKickoutRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Auto_pay_kickout' LIMIT 1];
        CSX_CMP_Business_Rule__c deskAssignmentRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Claim_Desk_Assignment' LIMIT 1];
        CSX_CMP_Business_Rule__c priorityClaimRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Claim_Priority' LIMIT 1];
        CSX_CMP_Business_Rule__c flrRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_FLR' LIMIT 1];
        CSX_CMP_Business_Rule__c arThresholdRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_AR_Threshold' LIMIT 1];
        CSX_CMP_Business_Rule__c duplicateRule = [Select Id From CSX_CMP_Business_Rule__c WHERE RecordType.DeveloperName = 'CSX_CMP_Duplicate' LIMIT 1];
       
        Test.startTest();
        	String result1 = CSX_CMP_SimulateBusinessRule.getBusinessRule(approvalRule.Id, approvalClaim.Id);
        	String result2 = CSX_CMP_SimulateBusinessRule.getBusinessRule(autoDeclineRule.Id, autoDeclineClaim.Id);
        	String result3 = CSX_CMP_SimulateBusinessRule.getBusinessRule(autoPayKickoutRule.Id, autoPayKickoutClaim.Id);
        	String result4 = CSX_CMP_SimulateBusinessRule.getBusinessRule(deskAssignmentRule.Id, deskAssignmentClaim.Id);
        	String result5 = CSX_CMP_SimulateBusinessRule.getBusinessRule(priorityClaimRule.Id, priorityClaim.Id);
        	String result6 = CSX_CMP_SimulateBusinessRule.getBusinessRule(flrRule.Id, flrClaim.Id);
        	String result7 = CSX_CMP_SimulateBusinessRule.getBusinessRule(arThresholdRule.Id, arThresholdClaim.Id);
        	String result8 = CSX_CMP_SimulateBusinessRule.getBusinessRule(duplicateRule.Id, duplicateClaim.Id);
        
        Test.stoptest();
        System.assertNotEquals(null, result1, 'Result should not be null');
        
    }
    
}