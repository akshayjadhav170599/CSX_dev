@isTest
public class CSX_CMP_Settlement_Utility_Test {
     
    @testsetup  
    static void setupTestData() {
        
        Account objAcc = new Account(); 
        objAcc.Name = 'test';
        objAcc.Type= 'Customer';
        objAcc.CSX_CMP_FC_Railroad_Road_Code__c = 'BNSF';
        objAcc.Status__c = 'Active';
        objAcc.AccountNumber = '1212';
        // objAcc.CSX_CMP_Active_From__c = Date.newInstance(2016, 12, 9);
        // objAcc.CSX_CMP_Active_To__c = Date.newInstance(2025, 12, 9);
        Insert objAcc;
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Freight').getRecordTypeId();
        List<Case> testCases = new List<Case> ();
        
        testCases.add(new Case ( 
        CSX_CMP_Claim_Amount__c = 10000,Type='Recharges Inbound Claim',RecordtypeId = caseRecordTypeId, CSX_CMP_Customer__c = objAcc.Id));        
        insert testCases;
    }

    @isTest 
    static void testCreateAPSettlement() {
        
        CSX_CMP_SAP_Accounting_Detail__c finaSettle = new CSX_CMP_SAP_Accounting_Detail__c();
        finaSettle.Name = 'Recharges Inbound Claim_NA';
        finaSettle.CSX_CMP_Claim_Type__c = 'Recharges Inbound Claim';
        finaSettle.CSX_CMP_AP_GL_Account__c='20110050';
        finaSettle.CSX_CMP_AP_Company_Code__c = '754';
        finaSettle.CSX_CMP_AP_Cost_Center__c = 'ksbn';
        insert finaSettle;
        
        List<Case> cases = [Select Id,CSX_CMP_Claim_Amount__c,recordType.Name ,CSX_CMP_Customer__c,CSX_CMP_Terminal__c, Type FROM Case LIMIT 1];
        
        CSX_CMP_AP_Settlement__c apSett = new CSX_CMP_AP_Settlement__c();
        apSett.CSX_CMP_Document_Type__c = 'AZ';
        apSett.CSX_CMP_Claim__c = cases[0].Id;
        apSett.CSX_CMP_Currency__c = '67';
        apSett.CSX_CMP_GL_Account__c = 'abc';
        apSett.CSX_CMP_Cost_Center__c = 'hshk';
        apSett.CSX_CMP_Company_Code__c = 'jhws';
        insert apSett;
        
        System.assertNotEquals(0, cases.size(),'No cases found for testing');
        
        system.Test.startTest();
        // CSX_CMP_Settlement_Utility.createAPSettlements(cases);
        system.Test.stopTest();
        
        System.assertNotEquals(null, apSett);
        
    }
    
    @isTest
    static void testCreateARSettlement() {
        
        CSX_CMP_SAP_Accounting_Detail__c finaSettle = new CSX_CMP_SAP_Accounting_Detail__c();
        finaSettle.Name = 'Recharges Inbound Claim_NA';
        finaSettle.CSX_CMP_Claim_Type__c = 'Recharges Inbound Claim';
        finaSettle.CSX_CMP_AR_GL_Account__c = 'kjdsx';
        finaSettle.CSX_CMP_AR_Company_Code__c = 'kasq';
        finaSettle.CSX_CMP_AR_Cost_Center__c = 'kjdsx';
        insert finaSettle;
   
        List<Case> cases = [Select Id, CSX_CMP_Claim_Amount__c,recordType.Name , CSX_CMP_Customer__c,CSX_CMP_Terminal__c, Type FROM Case LIMIT 1];
        
        CSX_CMP_AR_Settlement__c arSett = new CSX_CMP_AR_Settlement__c();
        arSett.CSX_CMP_Document_Type__c = 'AC';
        arSett.CSX_CMP_Claim__c = cases[0].Id;
        arSett.CSX_CMP_Currency_Type__c = 'gfj';
        arSett.CSX_CMP_GL_Account__c = 'jkjgb';
        arSett.CSX_CMP_Company_Code__c = 'hvj';
        arSett.CSx_CMP_Cost_Center__c = 'dsz';
        insert arSett;
        
        System.assertNotEquals(0, cases.size(),'No cases found for testing'); 
        
        Decimal invoiceAmount = 500;     
        Id customerId = UserInfo.getUserId(); 
         
        system.Test.startTest();
        // CSX_CMP_Settlement_Utility.createARSettlements(cases);
        system.Test.stopTest();   
         
        System.assertNotEquals(cases[0].Id , null ); 
        
    }
     
}