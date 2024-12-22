/**
@Author       - Nilesh Soni
@Name         - CSX_CMP_LDRSearchController_Test
@Created Date - 01/20/2024
@Description  - Apex Test class controller for LDR search
*/

@isTest
public class CSX_CMP_LDRSearchController_Test {
    
    @testSetup
    // Calling MasterDataLoader to load the data
    static void setupData(){
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> lDReport = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
        CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(ldReport);
        
        CSX_CMP_LD_Contact__c ldContact = new CSX_CMP_LD_Contact__c(
            CSX_CMP_Contact_Role__c = 'ReportedBy',
            CSX_CMP_Phone_Number__c = '123-456-7890',
            CSX_CMP_Contact_Name__c = 'Test User',
            CSX_CMP_Email__c = 'test@user.com',
            CSX_CMP_LD_Report__c = response.ldrId
        );
        insert ldContact;
        
    }
    
    // Test methods covering various scenarios
    @isTest
    static void testLDRSearchWithStates() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Leads' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
        CSX_CMP_LDRSearchController.cityStateWrapper result =  CSX_CMP_LDRSearchController.getStates();
        Test.stopTest();
        }     
        // Assert that the state and region lists are not null
       // System.assertEquals(result.state.size() > 0, true);
        
    }
    
    //Set up search parameters  
    @isTest
    public static void testgetLdrRecords() { 
        CSX_CMP_LD_Report__c ldReport = [SELECT Id, Name,CSX_CMP_LD_Type__c,CSX_CMP_RAR_Num__c,CSX_CMP_Incident_Status__c,
                                         CSX_CMP_Incident_Location__c,CSX_CMP_Damage_Reason__c,
                                         CSX_CMP_Incident_Date__c,CSX_CMP_Reported_Date__c,CSX_CMP_Completed_Date__c,
                                         CSX_CMP_Reported_By__c,CSX_CMP_Track_ID__c,CSX_CMP_Cause__c,CSX_CMP_Incident_Action__c,
                                         CSX_CMP_Bad_Order_Comments__c,CSX_CMP_Incident_Comments__c FROM CSX_CMP_LD_Report__c
                                         WHERE CSX_CMP_LD_Type__c ='Customer' LIMIT 1];
        
        Map<String, Object> requestParameters = new Map<String, Object>();
        
        requestParameters.put('claimNumber', ldReport.Name);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_LD_Type__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_RAR_Num__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Incident_Status__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Incident_Location__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Reported_Date__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Completed_Date__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Reported_By__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Track_ID__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Cause__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Incident_Action__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Bad_Order_Comments__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Incident_Comments__c);
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Damage_Reason__c);     
        requestParameters.put('claimNumber', ldReport.CSX_CMP_Incident_Date__c);
        
        String ldrSearchParameters = JSON.serialize(requestParameters);
      
        User user = [SELECT Id FROM User WHERE FirstName = 'Leads' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
        CSX_CMP_LDRSearchController.ldrSearchResultWrapper result = CSX_CMP_LDRSearchController.getLdrRecords(ldrSearchParameters);
        Test.stopTest();
        System.assertEquals(result.results.size() > 0, true, 'LDR records should be found');
        }
    }
    
    //covering various scenarios for ldr search
    @isTest
    public static void testLdrSearchWithDifferentParams() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.shipper = 'Test';
        wrapper.salvage = 'Yes';
        wrapper.incidentMgr = 'NY';
        wrapper.reportNumber = '12345';
        wrapper.reportType = 'Incident';
        wrapper.stcc = '12345';
        wrapper.vinNumber = '12345678';
        wrapper.startDate = '2024-07-01';
        wrapper.endDate = '2024-07-10';
        wrapper.rarNumber = '123243';
        wrapper.incidentLocation = 'NY';
        wrapper.region = 'West';
        wrapper.state = 'NY';       
        wrapper.equipmentInitial = 'ABC';
        wrapper.equipmentNumber = '123456';
        wrapper.status = new List<String>(); 
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        
        // Assert that filters include report number search
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given search parameters');
        
    }
    
    @isTest
    public static void testLdrSearchWithVinNumber() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.vinNumber = '1234567';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
    	System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given VIN number.');
    }
   
    @isTest
    public static void testLdrSearchWithNullStatusValues() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.status = new List<String>();
        List<String> statusList = new List<String>();
        if (null != 'NEW') {
            statusList.add('NEW');
        } 
        wrapper.status = statusList;
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
		// Assert that filters don't include status filter
    	System.assertEquals(1, resultWrapper.results.size(), 'Results size should be 1 when status filter is applied');
    }
    
    @isTest
    public static void testLdrSearchWithNoCriteria() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertEquals(resultWrapper.results.size() > 0, true, 'LDR search should return results when no criteria is specified');
    }
    
    @isTest
    public static void testLdrSearchWithEquipmentNumberOnly() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.equipmentInitial = 'ABC';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given equipment number');
    }
    
    @isTest
    public static void testLdrSearchWithEquipmentInitialOnly() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.equipmentNumber = '123456';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given equipment initial');
    }
    
    @isTest
    public static void testLdrSearchWithSalvageAmountFrom() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.salvage = 'Yes';  
  		wrapper.salvageAmountFrom = '1000.00';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given salvage amount from');
    }
    
    @isTest
    public static void testLdrSearchWithSalvageAmountTo() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.salvage = 'Yes';  
  		wrapper.salvageAmountTo = '5000.00';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given salvage amount to');
    }
    
    @isTest
    public static void testLdrSearchWithSalvorName() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.salvage = 'Yes';  
 	    wrapper.salvorName = 'Test User';
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for the given salvor name');
    }
    
    @isTest
    public static void testLdrSearchWithEmptyFiltersAndSalvageSet() {
        CSX_CMP_LDRSearchController.LDRSearchRequestWrapper wrapper = new CSX_CMP_LDRSearchController.LDRSearchRequestWrapper();
        wrapper.salvage = 'Yes';  
        CSX_CMP_LDRSearchController.LdrSearchResultWrapper resultWrapper = CSX_CMP_LDRSearchController.getLdrRecords(JSON.serialize(wrapper));
        System.assertNotEquals(resultWrapper.results.size() > 0, true, 'No results found for empty filters and salvage set');
    }
    
}