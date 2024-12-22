/**
@Class Name   - CSX_CMP_InspectionSearchController_Test
@Created Date - 10/16/2024
@Description  - This class is used to test the methods in CSX_CMP_InspectionSearchController class.
*/

@isTest
public class CSX_CMP_InspectionSearchController_Test {
    
	/* @Description : method to create master data */
	
    @testSetup
	static void setupTestData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/* @Description : method to test search Inspection Header List */
    
	@isTest
	public static void searchInspectionHeaderListTest() {
		List<CSX_CMP_Inspection_Header__c> inspectionHeaderList = new List<CSX_CMP_Inspection_Header__c>();

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_InspectionSearchController.InspectionSearchRequestWrapper requestWrapper = new CSX_CMP_InspectionSearchController.InspectionSearchRequestWrapper();
			requestWrapper.source = 'HAULAWAY';
			requestWrapper.inspectionRoad = 'ACOM';
            requestWrapper.inspectionType = 'ACOM';
            requestWrapper.rampId = 'ACOM';
            requestWrapper.equipmentInitial = 'ACOM';
            requestWrapper.equipmentNumber = 'ACOM';
            requestWrapper.vinNumber = '85673458';
			requestWrapper.damageType = '00';
			requestWrapper.damageSeverity = '00';
            requestWrapper.damageArea = '00';
			requestWrapper.startDate = '2024-04-13';
			requestWrapper.endDate = '2024-05-15';
			inspectionHeaderList = CSX_CMP_InspectionSearchController.searchInspectionHeaderList(
				JSON.serialize(requestWrapper),false
			); 
			Test.stopTest();
			System.assertNotEquals(null, inspectionHeaderList.size(), 'Inspection Header List should not be empty');
		}
	}
    
    /* @Description : method to test search Inspection Header List with else value */
    
   @isTest
	public static void searchInspectionHeaderListTestWithElseValue() {
		List<CSX_CMP_Inspection_Header__c> inspectionHeaderList = new List<CSX_CMP_Inspection_Header__c>();

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_InspectionSearchController.InspectionSearchRequestWrapper requestWrapper = new CSX_CMP_InspectionSearchController.InspectionSearchRequestWrapper();
            requestWrapper.vinNumber = '8567458';
			requestWrapper.damageType = '01';
			requestWrapper.damageSeverity = '03';
            requestWrapper.damageArea = '05';
			inspectionHeaderList = CSX_CMP_InspectionSearchController.searchInspectionHeaderList(
				JSON.serialize(requestWrapper),false
			);
			Test.stopTest();
			System.assertNotEquals(null, inspectionHeaderList.size(), 'Inspection Header List should not be empty');
		}
	}
    
	/* @Description : method to test fetch Inspection Details */
    
	@isTest
	static void testFetchInspectionDetails() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		List<CSX_CMP_Inspection_Header__c> inspectionHeaderList = [SELECT Id FROM CSX_CMP_Inspection_Header__c LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			List<ID> inspectionHeaderIds = new List<ID>{ inspectionHeaderList[0].Id };
			Boolean exCleanException = false;
			List<CSX_CMP_InspectionSearchController.inspectionDetailWrapper> inspectionSearchControllerList = CSX_CMP_InspectionSearchController.fetchInspectionDetails(
				inspectionHeaderIds,
				exCleanException
			);
			Test.stopTest();
			System.assertNotEquals(null, inspectionSearchControllerList, 'Inspection Details should not be null');
		}
	}
}