@isTest
public class CSX_CMP_OnHoldClaimsApprEvaluation_Test {
    
    @testSetup
    static void setupTestData(){
        
         Id strRecordDevName = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Revenue_Overcharge').getRecordTypeId();

        Account custAcc = new Account();
        custAcc.Name = 'ABc';
        custAcc.Type='Customer';
        custAcc.Supplier_type__c='xyx';
        custAcc.CSX_CMP_FC_SCAC__c='354';
        custAcc.National_Account__c='67587';
        
        insert custAcc;
        
        Account acct = new Account();
        acct.Name='acc';
        acct.Type='Supplier';
        acct.Supplier_type__c='xyx';
        acct.CSX_CMP_FC_SCAC__c='354';
        acct.National_Account__c='67587';
        acct.Site='trt';
        insert acct;
        
        CSX_CMP_Decline_Code_Master__c dec= new CSX_CMP_Decline_Code_Master__c();
        dec.Name = 'decN';
        insert dec;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u= new User(Alias = 'test', Email='test@org.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = p.Id, 
                         TimeZoneSidKey='America/Los_Angeles', UserName='test87@t.com');
        insert u;
        
        Contract con = new Contract();
        con.Name = 'test';
        con.AccountId=acct.id;
        insert con;
        
        CSX_CMP_Desk__c deskName = new CSX_CMP_Desk__c();
        deskName.Name = 'Desk';
        insert deskName;
        
        List<Case> testCaseLst = new List<Case>();
        Case testCase = new Case();
        testCase.Status='On Hold';
        testCase.Type = 'Incentive Claim';
        testCase.CSX_CMP_Desk_Name__c=deskName.id;
        testCase.CSX_CMP_Desk_Name__c = deskName.id;
        testCase.CSX_CMP_Customer__c=custAcc.id;
        //testCase.CSX_CMP_Assigned_To__c=u.id;
        testCase.CSX_CMP_Supplier_Claimant__c=acct.id;
        testCase.CSX_CMP_Claim_Amount__c=88;
        testCase.CSX_CMP_Service_Period__c='1233';
        testCase.CSX_CMP_Netting_Claim_Ref_Number__c = testCase.id;
        testCase.CSX_CMP_Decline_Code__c = dec.id;
        testCase.AccountId = acct.id;
        testCase.RecordTypeId = strRecordDevName;
        insert testCase;
        testCaseLst.add(testCase);
       
    }
    
    @isTest
    static void testMethod1() {
        
        List<Case> testCaseList = [SELECT Id, Type FROM Case LIMIT 1];
        
        Map<String,List<Case>> nationalAccMap  = new Map<String,List<Case>>();
        nationalAccMap.put('23456', testCaseList);
        
        
        system.Test.startTest();
        CSX_CMP_OnHoldClaimsApprEvaluationBatch claimData = new CSX_CMP_OnHoldClaimsApprEvaluationBatch();
        claimData.nationalAccNumtoClaimsMap = nationalAccMap;
        Database.executeBatch(claimData);
        system.Test.StopTest();
        
    }
    
    @isTest
    static void testMethod2(){
        
        Case testCase = [SELECT Id, Type FROM Case LIMIT 1];
        testCase.Type = 'Revenue_Overcharge';
        update testCase;
        set<id> setCaseId = new set<id>();
        setCaseId.add(testCase.id);
        Map<Id, String> overchargeClaimIdARThresholdMap = new Map<Id, String>();
        overchargeClaimIdARThresholdMap.put(testCase.Id, 'test###20');
        
        Map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper> freightBillInvoiceDataMap = new Map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper>();
        CSX_CMP_InterfaceUtility.FreightbillResponseWrapper freightResponse = new CSX_CMP_InterfaceUtility.FreightbillResponseWrapper();
        
        system.Test.startTest();
        CSX_CMP_BusinessRulesUtility.runARThresholdBusinessRules(setCaseId,'CSX_CMP_AR_Threshold',null);
        CSX_CMP_OnHoldClaimsApprEvaluationBatch claimData = new CSX_CMP_OnHoldClaimsApprEvaluationBatch();
        Database.executeBatch(claimData);
        system.Test.StopTest();
    }
}