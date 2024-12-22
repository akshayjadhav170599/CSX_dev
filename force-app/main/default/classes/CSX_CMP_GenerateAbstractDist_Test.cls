@isTest
public class CSX_CMP_GenerateAbstractDist_Test {  //CSX_CMP_Role_Access_Configuration__mdt
    
	@testSetup
    public static void setupdata(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);      
    	
    	Case claim = [SELECT Id, CSX_CMP_System_Action_Toggle__c, Status FROM Case WHERE Id = :response.claimId];
		claim.Status = 'Pending Monthly Settlement';
		claim.CSX_CMP_Service_Period__c = 'PER-4-24';
		claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
		update claim;
    }
    
	@isTest
    public static void testCheckProfileNameAdmin(){
        User user = [SELECT Id FROM User WHERE name = 'Freight Claim Manager' LIMIT 1];
     CSX_CMP_Role_Access_Configuration__mdt metaTest = [Select id, Label from CSX_CMP_Role_Access_Configuration__mdt where label = 'Freight Claim Manager'];
        System.runAs(user) {
        Test.startTest();
            List<Case> resultCase = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Freight', 'PER-4-24', 'Class 1', '');

           List<String> result = CSX_CMP_GenerateAbstractDistributionCtrl.searchCarrierAlphaCode('Freight','','Non Class 1');
           CSX_CMP_GenerateAbstractDistributionCtrl.calculateServicePeriod();
           CSX_CMP_GenerateAbstractDistributionCtrl.checkProfileName();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned list should not be null');   
        }
    }
    
    @isTest
    public static void  testAlphaCode(){
       // Retrieve a specific user from the database
       User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
     
        System.runAs(user) {
        Test.startTest();
            List<Case> resultCase = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Freight', 'PER-4-24', 'Class 1', '');

           List<String> result = CSX_CMP_GenerateAbstractDistributionCtrl.searchCarrierAlphaCode('Freight','','Non Class 1');
           CSX_CMP_GenerateAbstractDistributionCtrl.calculateServicePeriod();
           CSX_CMP_GenerateAbstractDistributionCtrl.checkProfileName();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned list should not be null');   
        }
   }

	 @isTest
    public static void  testAlphaCode1(){
       // Retrieve a specific user from the database
       User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
     
        System.runAs(user) {
        Test.startTest();
           List<String> result = CSX_CMP_GenerateAbstractDistributionCtrl.searchCarrierAlphaCode('Freight','PER-4-24','Class 1');
           CSX_CMP_GenerateAbstractDistributionCtrl.calculateServicePeriod();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned list should not be null');   
        }
   }
    
    @isTest
    static void testFetchClaimWithFreightRecordType(){
        Case claim = [SELECT Id from Case LIMIT 1];
        List<Case> resultCase = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Freight', 'PER-4-24', 'Class 1', null);
        List<Case> resultCases = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim('Revenue_Railroad', 'PER-4-24', 'Non Class 1', null);
    }
    
     @isTest
    public static void  testScheduleBatchJob(){
        // Retrieve a specific user from the database
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        //Exception exc;
        System.runAs(user) {
            Test.startTest();
            String result = CSX_CMP_GenerateAbstractDistributionCtrl.scheduleBatchJob('Freight','PER-4-24','Non Class 1','Overcharge',true);
            Test.stopTest();
            System.assertNotEquals(null, result, 'The returned list should not be null');  
            
            try {  
                Integer i = 1 / 0; 
            } catch (Exception ex) {
                CSX_CMP_LoggerUtility.addApexErrorLog('TestClass', 'testAddApexErrorLog','Freight,PER-4-24,Non Class 1,Overcharge', ex);
            }
        }
    }
}

    /*@isTest
    public static void testCheckProfileName_Freight(){
   	    User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'Manager' LIMIT 1];
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Freight Claim Manager' LIMIT 1];
        user.ProfileId = testProfile.Id;
        
        System.runAs(user) {
            Test.startTest();
            String category = CSX_CMP_GenerateAbstractDistributionCtrl.checkProfileName();
            Test.stopTest();
		//System.assertEquals('Freight', category, 'Expected Freight for Freight user');
        }
    }
    
    @isTest
    public static void testCheckProfileName_Revenue(){
   	    User user = [SELECT Id FROM User WHERE FirstName = 'Revenue Overcharge' AND LastName = 'Manager' LIMIT 1];
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Revenue Overcharge Manager' LIMIT 1];
        user.ProfileId = testProfile.Id;
        
        System.runAs(user) {
            Test.startTest();
            String category = CSX_CMP_GenerateAbstractDistributionCtrl.checkProfileName();
            Test.stopTest();
		//System.assertEquals('Freight', category, 'Expected Freight for Freight user');
        }
    }*/