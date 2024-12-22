/**************************************************************************************
Apex Class Name     : CSX_CMP_LoggerUtility_Test
Function            : Test Class used for testing the CSX_CMP_LoggerUtility
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Chetan           31/10/2023       First version of this class.
*************************************************************************************/
@isTest
public with sharing class CSX_CMP_LoggerUtility_Test {
//     @TestSetup
//     static void setup(){
        
//     }
    
//     static testmethod void AddApexErrorLog_Test(){
//         try{
//             Integer i = 1/0;
//         }Catch(Exception e){
//             system.Test.startTest();            
//             CSX_CMP_LoggerUtility.addApexErrorLog('ClassName','MethodName','Parameters',e);
//             system.Test.stopTest();
//             Integer eLogCount = [Select Count() from CSX_CMP_Error_Log__c];
//             system.assertEquals(eLogCount,0);
//         }
//     }
    
//     static testmethod void addIntegrationErrorLogTest(){
//         try{
//             Integer i = 1/0;
//         }Catch(Exception e){
//             system.Test.startTest();            
//             CSX_CMP_LoggerUtility.addIntegrationErrorLog('ProcessName', 'Message', 'Parameters','');
//             system.Test.stopTest();
//             Integer iLogCount = [Select Count() from CSX_CMP_Integration_Log__c];
//             system.assertEquals(iLogCount,1);
//         }
//     }
    
    
//     static testmethod void addApexEmailErrorLogTest2(){
        
//         List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>(); 
//         messaging.SingleEmailMessage email=new messaging.SingleEmailMessage();  
//         singleEmailMessageList.add(email);
        
//         Messaging.SendEmailResult[] results = Messaging.sendEmail(singleEmailMessageList,false);
        
//         system.Test.startTest(); 
//         CSX_CMP_LoggerUtility.addApexEmailErrorLog('ClassName','MethodName', results[0]);
//         system.Test.stopTest();
//         List<CSX_CMP_Error_Log__c> errorLogList = [select id from CSX_CMP_Error_Log__c]; //where CSX_CMP_Method_Name__c='MethodName' and CSX_CMP_Class_Name__c='ClassName'
//         system.assertEquals(results.size(),1);
        
//     }
    
//     static testmethod void addApexEmailErrorLogListTest(){
        
//         List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>(); 
//         messaging.SingleEmailMessage email=new messaging.SingleEmailMessage();  
//         singleEmailMessageList.add(email);
        
//         List<Messaging.SendEmailResult> results = Messaging.sendEmail(singleEmailMessageList,false);
        
//         system.Test.startTest(); 
//         CSX_CMP_LoggerUtility.addApexEmailErrorLog('ClassName','MethodName', results);
//         system.Test.stopTest();
//         List<CSX_CMP_Error_Log__c> errorLogList = [select id from CSX_CMP_Error_Log__c where CSX_CMP_Method_Name__c='MethodName' and CSX_CMP_Class_Name__c='ClassName'];
//         system.assertEquals(results.size(),1);
        
//     }
    
//     static testmethod void addApexDMLErrorLogTest(){ 
        
//         List<Case> compList = new List<Case>();
//         Case newAutoClaim = new Case();
//         //newAutoClaim.CSX_CMP_Status__c = 'Submitted';
//         compList.add(newAutoClaim);
        
//         List<CSX_CMP_Error_Log__c> errorList = new List<CSX_CMP_Error_Log__c>();
//         CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
//         errorRec.CSX_CMP_Message__c = 'test error';
//         errorRec.CSX_CMP_Execution_Time__c = System.now();
//         errorRec.CSX_CMP_User__c = UserInfo.getUserId();
//         errorList.add(errorRec);
        
//         List<Database.SaveResult> results = Database.insert(errorList,false);
//         Integer successcount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', Results ,'CSX_CMP_Error_Log__c');
//         system.assertEquals(results.size(),1);
        
//         List<Database.SaveResult> compResults = Database.insert(compList,false);
//         Integer compsuccesscount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', compResults ,'Case');
//         system.assertEquals(compsuccesscount,1);
        
//         List<Case> cases = [Select Id FROM Case LIMIT 1];
//         System.assertNotEquals(0, cases.size(),'No cases found for testing');
//         List<Database.SaveResult> compResults1 = Database.insert(cases,false);
//         Integer compsuccesscount1 = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', compResults1,'Case');
        
//     }
    
//     static testmethod void addApexDMLErrorLogTest1(){ 
        
//         CSX_CMP_Claim_Email_Service__c objEmail = new CSX_CMP_Claim_Email_Service__c();
//         objEmail.CSX_CMP_Email_Id__c = 'test@gmail.com';
//         insert objEmail;
//         Map<String,String> testFreightData = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        
//         system.Test.startTest();
        
//         //system.debug ('Result should be null');
//         //List<String> duplicates=CSX_CMP_ClaimCreationController.checkforDuplicates(testFreightData);
//         // CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(testFreightData, new List<String>(duplicates)); 
//         //system.debug('response:' +response); 
//         Case objCse = CSX_CMP_TestUtility.createAutoClaim();
//         //CSX_CMP_ClaimCreationController.generalRuleValidation(objCse);
//         CSX_CMP_ClaimCreationController.supplierSiteSearch('Test','testState','testCity');
        
//         system.Test.stopTest();
        
//         //  System.assertEquals('CLA002187', duplicates[0],'equal');
//         //  System.assertNotEquals(null, response, 'Response should not be null');
        
//         List<Case> cases = [Select Id FROM Case LIMIT 1];
//         System.assertNotEquals(0, cases.size(),'No cases found for testing');
//         List<Database.SaveResult> compResults1 = Database.insert(cases,false);
//         Integer compsuccesscount1 = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', compResults1[0],'Case');
//     }
    
//     static testmethod void addApexDMLErrorLogTest6(){ 
//         List<Case> compList = new List<Case>();
//         Case newAutoClaim = new Case();
//         //newAutoClaim.CSX_CMP_Status__c = 'Submitted';
//         compList.add(newAutoClaim);
        
//         List<CSX_CMP_Error_Log__c> errorList = new List<CSX_CMP_Error_Log__c>();
//         CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
//         errorRec.CSX_CMP_Message__c = 'test error';
//         errorRec.CSX_CMP_Execution_Time__c = System.now();
//         errorRec.CSX_CMP_User__c = UserInfo.getUserId();
//         errorList.add(errorRec); 
        
//         List<Database.SaveResult> results = Database.insert(errorList,false);
//         Integer successcount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', Results ,'CSX_CMP_Error_Log__c');
//         system.assertEquals(results.size(),1);
//     }
    
//     static testmethod void addApexDMLErrorLogTest2(){ 
//         List<Case> compList = new List<Case>();
//         Case newAutoClaim = new Case();
//         //newAutoClaim.CSX_CMP_Status__c = 'Submitted';
//         compList.add(newAutoClaim);
        
//         List<CSX_CMP_Error_Log__c> errorList = new List<CSX_CMP_Error_Log__c>();
//         CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
//         errorRec.CSX_CMP_Message__c = 'test error';
//         errorRec.CSX_CMP_Execution_Time__c = System.now();
//         errorRec.CSX_CMP_User__c = UserInfo.getUserId();
//         errorList.add(errorRec); 
        
//         /*List<Database.UpsertResult> compResults = Database.Upsert(errorList,false);
// Integer compsuccesscount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', compResults,'Case');
// system.assertEquals(compsuccesscount,1);*/
        
//         List<Database.UpsertResult> deleteResults = Database.upsert(compList, false);
//         Integer successcount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', deleteResults,'CSX_CMP_Error_Log__c');
//         system.assertEquals(successcount,1);
//     }
    
//     @isTest
//     public static void testPartialSuccessWithErrors() {
//         // Mock some successful and some failed upsert results
        
//         List<CSX_CMP_Error_Log__c> errorList = new List<CSX_CMP_Error_Log__c>();
//         // Create mock error log object
//         CSX_CMP_Error_Log__c expectedErrorLog = new CSX_CMP_Error_Log__c(
//             CSX_CMP_Object_Name__c = 'TestObject',
//             CSX_CMP_Class_Name__c = 'TestClassName',
//             CSX_CMP_Method_Name__c = 'testMethod',
//             CSX_CMP_Message__c = 'Test error message'
//         );
//         errorList.add(expectedErrorLog); 
//         List<Database.UpsertResult> deleteResults = Database.upsert(errorList, false);
//         // Call the method with mock data
//         Integer successCount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('TestClassName', 'testMethod', deleteResults, 'case');
        
//         // Assertions
//         system.assertEquals(deleteResults.size(),1);
//     }

//    /* static testmethod void addApexDMLErrorLogTest3(){ 
//         List<Id> compList = new List<Id>();
//         CSX_CMP_TestUtility.createAutoClaim();
//         Case testClaim = [SELECT id from Case LIMIT 1];
//         compList.add(testClaim.Id);
        
//         List<Id> errorList = new List<Id>();
//         CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
//         errorRec.CSX_CMP_Message__c = 'test error';
//         errorRec.CSX_CMP_Execution_Time__c = System.now();
//         errorRec.CSX_CMP_User__c = UserInfo.getUserId();
//         insert errorRec;
//         errorList.add(errorRec.Id); 
        
//         Database.DeleteResult[] deleteResults = Database.delete(errorList, false);
//         Integer successcount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', deleteResults,'CSX_CMP_Error_Log__c');
//         system.assertEquals(successcount,1);
        
//         List<Database.DeleteResult> compResults = Database.delete(errorList, false);
//         Integer compsuccesscount = CSX_CMP_LoggerUtility.addApexDMLErrorLog('ProcessName', 'Message', compResults,'Case');
//         system.assertNotEquals(compsuccesscount,1);
        
//     }
//     */
//     static testmethod void AddClientErrorLog_Test(){
//         try{
//             Integer i = 1/0;
//         }Catch(Exception e){
//             system.Test.startTest();            
//             CSX_CMP_LoggerUtility.addClientErrorLog('ClassName','MethodName','{"body" : {"message":"abc","errorType":"Math Exception"}}','Math Exception');
//             system.Test.stopTest();
//             Integer eLogCount = [Select Count() from CSX_CMP_Error_Log__c];
//             system.assertEquals(eLogCount,0);
//         }
//     }
    
//     @isTest 
//     static void AddExecutionLog_test(){
//         String className = 'Test Class';
//         String processName = 'Test Process';
//         String objectName = 'Test Object';
//         Integer count = 5;
//         system.Test.startTest();
//         CSX_CMP_LoggerUtility.addExecutionLog(className, processName, objectName, count);
//         List<CSX_CMP_Batch_Execution_Log__c> getBatch = [SELECT Id FROM CSX_CMP_Batch_Execution_Log__c];
//         system.Test.stopTest();       
//         system.assertEquals(1, getBatch.size());
//     }
    
    /*static testmethod void addApexEmailErrorLogTest(){
        
        CSX_CMP_TestUtility.createAutoClaim();
        Case testClaim = [SELECT id, CaseNumber,ContactId from Case LIMIT 1];
        List<EmailTemplate> compTemplateId = [Select id,DeveloperName from EmailTemplate where DeveloperName = 'CSX_CMP_FreightAutoClaim_Acknowledgement_Email_Templ'];
        list<OrgWideEmailAddress> oweAddress = [select id, Address, DisplayName from OrgWideEmailAddress  Where Address =: 'test@gmail.com' limit 1];
        
        List<Messaging.SingleEmailMessage> singleEmailMessageList = new List<Messaging.SingleEmailMessage>(); 
        messaging.SingleEmailMessage email=new messaging.SingleEmailMessage();  
        singleEmailMessageList.add(email);
        
        messaging.SingleEmailMessage email2=new messaging.SingleEmailMessage();  
        email2.setOrgWideEmailAddressId(oweAddress[0].Id);
        email2.setTemplateId(compTemplateId[0].Id); 
        email2.setTargetObjectId(testClaim.ContactId);                               
        email2.setWhatid(testClaim.Id);
        email2.setSaveAsActivity(false);
        singleEmailMessageList.add(email2);
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(singleEmailMessageList,false);
        
        system.Test.startTest(); 
        Integer successcount = CSX_CMP_LoggerUtility.addApexEmailErrorLog('ClassName','MethodName', results);
        system.Test.stopTest();
        system.assertEquals(successcount,1);  
    } */
}