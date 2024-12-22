@isTest
public class CSX_CMP_InterfaceUtility_Test {
    
//     @testSetup    
//     static void setupData(){ 
//         CSX_CMP_Equipment__c equ = new CSX_CMP_Equipment__c(); 
//         equ.CSX_CMP_Act_Origin_City__c ='ngp';
//         equ.CSX_CMP_Act_Destination_State__c='Mh';
//         equ.CSX_CMP_Act_Origin_State__c='mh';  
//         equ.CSX_CMP_Act_Destination_City__c='hyd';
//         equ.CSX_CMP_Waybill_Num__c='122';
//         equ.CSX_CMP_Waybill_Date__c = Date.parse('12/01/1999');
//         equ.CSX_CMP_STCC__c='hhh';
//         equ.CSX_CMP_Shipper__c='123';
//         equ.CSX_CMP_Consignee__c='wqe';
//         equ.CSX_CMP_Equipment_Initial__c = 'test';
//         equ.CSX_CMP_Equipment_Num__c = '123445';
//         insert equ;
//     }
    
//     @isTest
//     static void TestfetchRARSDetail(){ 
//         CSX_CMP_Axway_Connection_Detail__c obj = new CSX_CMP_Axway_Connection_Detail__c();
//         obj.CSX_CMP_APIKey__c = 'W6Au5N7PNjJIkfb2Ql8J6yVzLuZfdJs5';
//         obj.CSX_CMP_APISecret__c = 'XaA4mqJuOzGGItQg';
//         obj.CSX_CMP_End_Point__c = 'https://logon-dev.csx.com/oauth2/aus1j3sfjmaIVNNit0h8/v1/token';
//         Insert obj;
//         Test.setMock(HttpCalloutMock.class, new CSX_CMP_InterfaceUtilityMock());
//        /* Map<string, string> reeqMap = new Map<String,string>();
//         reeqMap.put('Identifier','Axway');
//         reeqMap.put('Method','POST');
//         reeqMap.put('Content-Type','application/json');
//         reeqMap.put('EndpointURL',obj.CSX_CMP_End_Point__c);
//         reeqMap.put('Body','{"access_token":"mockAccessToken","token_type":"Bearer","expires_in":3600}');*/
        
//         //CSX_CMP_HTTPUtility.getHttpResponse(reeqMap);
        
//         CSX_CMP_Equipment__c eqipList = [select id from CSX_CMP_Equipment__c LIMIT 1]; 
//         CSX_CMP_External_Interface_Endpoint__c endPoint = new CSX_CMP_External_Interface_Endpoint__c();
//         endPoint.Name = 'RARS';
//         endPoint.CSX_CMP_End_Point__c='https://apistaging.csx.com/safety-rar/v1/freight-claims';
//         insert endPoint;
        
//         CSX_CMP_InterfaceUtility.RARSRequestWrapper wrapData = new CSX_CMP_InterfaceUtility.RARSRequestWrapper();
//         wrapData.equipmentId = eqipList.id;
//         wrapData.fromReportedDate = string.valueof(system.today()+10);
//         wrapData.incidentState = 'AL';
//         system.Test.startTest();
//         Test.setMock(HttpCalloutMock.class, new CSX_CMP_HTTPUtilityMock());
//         CSX_CMP_InterfaceUtility.fetchRARSDetail(wrapData);
//         system.Test.stopTest();
//     }
    
//    /* @isTest 
//     public static void TestfetchUmlerdetails() {
        
//         List<CSX_CMP_Equipment__c> eqipList = [select id from CSX_CMP_Equipment__c]; 
//         List<string> strEqip = new List<string>();
//         for(CSX_CMP_Equipment__c eq : eqipList){
//            strEqip.add(eq.id);
            
//         }
        
//         CSX_CMP_External_Interface_Endpoint__c Endpoint = new CSX_CMP_External_Interface_Endpoint__c(Name ='External Interface Endpoint', CSX_CMP_End_Point__c='UMLER');
//         insert Endpoint;
        
//         CSX_CMP_InterfaceUtility.MTIRequestWrapper wrapDataMTI = new CSX_CMP_InterfaceUtility.MTIRequestWrapper();
        
//         wrapDataMTI.equipmentId = eqipList[0].id;
//         wrapDataMTI.reportedDate = string.valueof(system.today()+10);
//         wrapDataMTI.incidentState = 'maharashtra';
        
//         system.Test.startTest();
//         system.Test.setMock(httpCalloutMock.class, new CSX_CMP_InterfaceUtilityMock());
//         CSX_CMP_InterfaceUtility.fetchUmlerdetails(strEqip);
//         system.Test.stopTest();  
//     }*/
}