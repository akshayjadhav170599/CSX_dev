/**************************************************************************************
/*
@author             : Infosys
@description        : This is a test class for CSX_CMP_PostLDRcreationQueuable

Apex Class Name     : CSX_CMP_PostLDRcreationQueuable_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
private class CSX_CMP_PostLDRcreationQueuable_Test {
	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		// Map<String, CSX_CMP_External_Interface_Endpoint__c> listAll = CSX_CMP_External_Interface_Endpoint__c.getAll();		
	}
	/* @description : method to test ldr creation for Customer */
	@isTest
	static void ldrCreateServiceTest() {
		CSX_CMP_LDRCreationController_Test.createLDReportTestForCustomer();
		CSX_CMP_LD_Report__c ldr = [SELECT Id, Name FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'Customer' LIMIT 1];
		System.assertNotEquals(null, ldr, 'LD Report should not be null');
	}

	/**
	@description : method to test ldr creation service for Derailment
	 */
	@isTest
	static void createLDReportTestForDerailment(){
		CSX_CMP_LDRCreationController_Test.createLDReportTestForDerailment();
		CSX_CMP_LD_Report__c ldr = [SELECT Id, Name FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'Derailment' LIMIT 1];
		System.assertNotEquals(null, ldr, 'LD Report should not be null');
	}

	/**
	@description : method to test ldr creation service for Intransit
	 */
	@isTest
	static void createLDReportTestForIntransit(){
		CSX_CMP_LDRCreationController_Test.createLDReportTestForIntransit();
		CSX_CMP_LD_Report__c ldr = [SELECT Id, Name FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'In transit' LIMIT 1];
		System.assertNotEquals(null, ldr, 'LD Report should not be null');
	}
}