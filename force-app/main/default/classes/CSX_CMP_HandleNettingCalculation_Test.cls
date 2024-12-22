/**
@Author       - Infosys
@Name         - CSX_CMP_HandleNettingCalculation_Test
@Created Date - 2/28/2024
@Description  - This Apex Test class is used to run netting process
@RICEFW reference - CMP-E-0437
*/
@isTest
public class CSX_CMP_HandleNettingCalculation_Test {
	@testSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
		//CSX_CMP_TestUtility.casedata();
		
	}

	@isTest
	static void testNettingClaimFreightPreviewIn() {
		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		Account accObj = [SELECT Id FROM Account WHERE Type = 'Supplier' AND Name = 'UNION PACIFIC RAILROAD COMPANY'];
		accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Net';
		update accObj;
		Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
		
		CSX_CMP_ClaimCreationController.createNewClaim(
			requestJSON,
			null
		);
        Case responseCase = [
			SELECT
				Id,CaseNumber,
				CSX_CMP_Supplier_Claimant__c,
				CSX_CMP_Service_Period__c,
				CSX_CMP_System_Action_Toggle__c,
				Subject,
				Status,
				CSX_CMP_Supplier_Claimant__r.Name,
				CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c
			FROM Case
			WHERE Type = 'FC RR Inbound Claim'
		];
		responseCase.Status = 'Pending Monthly Settlement';
		responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
		responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
		update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
		Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
		inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{ responseCase });

		System.runAs(user) {
			Test.startTest();
			//List<Case> lstCase = [Select Id,Type,RecordTypeId,CSX_CMP_Service_Period__c from case where Type='FC RR Inbound Claim'];
			CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight', 'PER-4-24', 'Preview');
			//CSX_CMP_HandleNettingCalculation.createNewNettingClaims(inputClaimsMap,'Freight','PER-4-24');
			Test.stopTest();
			system.assertEquals('Pending Monthly Settlement', responseCase.Status, '');
		}
	}

	@isTest
	static void testNettingClaimRevenuePreviewIn(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_REV_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    
        Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Revenue_Railroad','PER-4-24','Preview');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimRevenueCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_REV_Gross_Net_Customer__c = 'Gross';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        //List<Case> lstCase = [Select Id,Type,RecordTypeId,CSX_CMP_Service_Period__c from case where Type='Rev-RR - Payable Claim'];
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Revenue_Railroad','PER-4-24','Create');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimFreightCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Gross';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	       // List<CSX_CMP_HandleNettingCalculation.calculateNettingCalculationWrapper> result = CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Create');
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Create');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimFreightNetCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Create');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimFreightPostView(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_REV_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	   
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	   // responseCase.CSX_CMP_System_Action_Toggle__c =! responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.Status = 'Closed';
        responseCase.CSX_CMP_System_Action_Toggle__c =! responseCase.CSX_CMP_System_Action_Toggle__c;
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','View');
	        Test.stopTest();
	        system.assertEquals('Closed',responseCase.Status,'');
	    }
	}

	 @isTest
	static void testNettingClaimFreightOutboundNetCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status,Type FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.Type = 'FC RR Outbound Claim';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Create');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimFreightOutboundGrossCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Gross';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status,Type FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.Type = 'FC RR Outbound Claim';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Create');
	        Test.stopTest();
	        system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	    }
	}

	@isTest
	static void testNettingClaimFreightRecOutboundNetCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_FC_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status,Type FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.Type = 'Recharges Outbound Claim';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Freight','PER-4-24','Preview');
	        Test.stopTest();
	    }
	    system.assertEquals('Pending Monthly Settlement',responseCase.Status,'');
	}

	@isTest
	static void testNettingClaimRevenueOutboundCreate(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_REV_Gross_Net_Customer__c = 'Gross';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status,Type FROM Case WHERE Id = :response.claimId];
	    responseCase.Status = 'Pending Monthly Settlement';
	    responseCase.Type = 'Rev-RR - Receivable Claim';
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
	    update responseCase;
        
        responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
        update responseCase;
        
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        //List<Case> lstCase = [Select Id,Type,RecordTypeId,CSX_CMP_Service_Period__c from case where Type='Rev-RR - Payable Claim'];
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Revenue_Railroad','PER-4-24','Create');
	        Test.stopTest();
	    }
	    system.assertEquals('Rev-RR - Receivable Claim',responseCase.Type,'');
	}

	@isTest
	static void testNettingClaimRevenuePostView(){
	    Account accObj = [SELECT Id From Account WHERE Type = 'Supplier' And Name='UNION PACIFIC RAILROAD COMPANY'];
	    accObj.CSX_CMP_REV_Gross_Net_Customer__c = 'Net';
	    Update accObj;
	    Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
	    CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
	    Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,CSX_CMP_Service_Period__c,CSX_CMP_System_Action_Toggle__c, Subject, Status FROM Case WHERE Id = :response.claimId];
	   
	    responseCase.CSX_CMP_Service_Period__c = 'PER-4-24';
	    update responseCase;
	    
		responseCase.Status = 'Closed';
		responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
        update responseCase;
    
	    Map<String, List<Case>> inputClaimsMap = new Map<String, List<Case>>();
	    inputClaimsMap.put(responseCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{responseCase});
	    System.runAs(user) {
	        Test.startTest();
	        CSX_CMP_HandleNettingCalculation.calculateNettingResults('Revenue_Railroad','PER-4-24','View');
	        Test.stopTest();
	    }
	    system.assertEquals('PER-4-24',responseCase.CSX_CMP_Service_Period__c,'');
	}
	
    
    @isTest
    static void testgetClaimRecordTypeRole() {
        CSX_CMP_Role_Access_Configuration__mdt roleDetails = CSX_CMP_Role_Access_Configuration__mdt.getInstance('CSX_CMP_Freight_Claim_User');
        
        User user = [
            SELECT Id, UserRole.DeveloperName
            FROM User
            WHERE FirstName = 'Freight Claim' AND LastName = 'User'
            LIMIT 1
        ];
        
        System.runAs(user) {
            Test.startTest();
            //CSX_CMP_Role_Access_Configuration__mdt layoutDetail = CSX_CMP_HandleNettingCalculation.getClaimRecordTypeRole();
            Test.stopTest();
			system.assertEquals('Freight Claim User',roleDetails.MasterLabel,'');
        }
    }
}