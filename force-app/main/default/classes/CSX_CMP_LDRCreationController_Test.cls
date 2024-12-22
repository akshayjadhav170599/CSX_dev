/**************************************************************************************
/*
@author             : Infosys
@description        : This is a test class for CSX_CMP_LDRCreationController

Apex Class Name     : CSX_CMP_LDRCreationController_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/

@isTest
public class CSX_CMP_LDRCreationController_Test {
	@TestSetup
	public static void setupTestData() {
		// Calling MasterDataLoader to load the data
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/**
	@description : method to test ldr creation for Customer
	 */
	@isTest
	public static void createLDReportTestForCustomer() {
		Map<String, String> request = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
		request.put('sendEmail', 'true');
		User user = [SELECT Id FROM User WHERE FirstName = 'Leads' AND LastName = 'User' LIMIT 1];
		System.runAs(user) {
			CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
			Test.startTest();
			CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(
				request
			);
			Test.stopTest();
			System.assertNotEquals(null, response.ldrName, 'LD Report name should not be null');
		}
	}

	/**
	@description : method to test ldr creation service for Derailment
	 */
	// @isTest
	// public static void createLDReportTestForDerailment() {
	// 	Map<String, String> request = CSX_CMP_TestUtility.newLDReportCreationRequest('Derailment');
	// 	request.put('damageReason', 'I-Derailment');
	// 	request.put('cause', 'I-derail');
	// 	User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	// 	System.runAs(user) {
	// 		Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
	// 		Test.startTest();
	// 		CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(
	// 			request
	// 		);
	// 		CSX_CMP_Creation_Request__c stagingRec = [
	// 			SELECT Id, CSX_CMP_Request_Payload__c
	// 			FROM CSX_CMP_Creation_Request__c
	// 			WHERE CSX_CMP_LD_Report__c = :response.ldrId
	// 			LIMIT 1
	// 		];
	// 		if (response != null) {
	// 			system.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(response.ldrId, 'RARS', stagingRec));
	// 		}
	// 		Test.stopTest();
	// 		System.assertNotEquals(null, response.ldrName, 'LD Report name should not be null');
	// 	}
	// }

	// /**
	// @description : method to test ldr creation service for Intransit
	//  */
	// @isTest
	// public static void createLDReportTestForIntransit() {
	// 	Map<String, String> request = CSX_CMP_TestUtility.newLDReportCreationRequest('In transit');
	// 	request.put('damageReason', 'I-Broken bands');
	// 	request.put('cause', 'I-derail');
	// 	User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	// 	System.runAs(user) {
	// 		Test.setMock(HttpCalloutMock.class, new CSX_CMP_MockResponseGenerator());
	// 		Test.startTest();
	// 		CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(
	// 			request
	// 		);
	// 		CSX_CMP_Creation_Request__c stagingRec = [
	// 			SELECT Id, CSX_CMP_Request_Payload__c
	// 			FROM CSX_CMP_Creation_Request__c
	// 			WHERE CSX_CMP_LD_Report__c = :response.ldrId
	// 			LIMIT 1
	// 		];
	// 		if (response != null) {
	// 			system.enqueueJob(new CSX_CMP_PostLDRcreationQueuable(response.ldrId, 'MTI', stagingRec));
	// 		}
	// 		Test.stopTest();
	// 		System.assertNotEquals(null, response.ldrName, 'LD Report name should not be null');
	// 	}
	// }
}