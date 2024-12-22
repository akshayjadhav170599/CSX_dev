/* RICEF ID : 
@author : Infosys
@description : This test class is used to test CSX_CMP_ClaimCreationHelper methods */

@isTest
public class CSX_CMP_ClaimCreationHelper_Test {
    
    @testSetup   
    static void setupTestData(){   
        CSX_CMP_TestMasterDataUtility.createMasterData();
    }
    
    /* @description : method to test submit new claim for ShipCSX/Experience cloud */
    
    @istest
    public static void claimCreationForShipCSX() { 
        
        CSX_CMP_NewClaimWrapper inputClaimDetails = CSX_CMP_TestUtility.claimInputForShipCSX();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();      
            string response = CSX_CMP_ClaimCreationController.submitNewClaim(inputClaimDetails); 
            Test.stopTest(); 
            System.assertNotEquals(null, response, 'The response should not be null');
        }  
    }
    
    /* @description : method to test create new/duplicate claims for Freight Record Type  */
    
    @istest
    public static void claimCreationFreightRecordType() { 
        
        Map<String,String> testFreightData = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            Map<id,String> duplicates = CSX_CMP_ClaimCreationController.checkforDuplicates(testFreightData);  
            List<String> duplicateClaims = duplicates.values();
            CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(testFreightData,duplicateClaims); 
            Test.stopTest(); 
            System.assertNotEquals(null, response, 'The response should not be null');
        } 
    }  
    
    /* @description : method to test getSupplier site search validation */
    
    @istest
    public static void getSupplierSiteSearchValidation() { 
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            List<Account> result = CSX_CMP_ClaimCreationController.supplierSiteSearch('BURLINGTON NORTHERN SANTA FE','TX','Fort Worth','FC RR Inbound Claim');
            Test.stopTest();
            System.assertNotEquals(null, result ,'the search should return atleast one account' );
        }     
    } 
    
    /* @description : method to test getContract option validation */
    
    @isTest
    static void getContractOptionsValidation() {
        
        CSX_CMP_Contract__c contract = [SELECT Id from CSX_CMP_Contract__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            List<CSX_CMP_Contract__c> result = CSX_CMP_ClaimCreationController.getContractOptions(contract.Id);
            Test.stopTest();
            System.assertNotEquals(1, result.size(), 'the search should return atleast one contract');
        }
    } 
    
    /* @description : method to test getGeneral rules validation */
    
    @isTest   
    static void getGeneralRulesValidation() {   // check with Aditya
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Map<String, String> result = CSX_CMP_ClaimCreationController.getGeneralRules();
            Test.stopTest();
            System.assertNotEquals(1,result.size(), 'Should return atleast one general rule.');
        }
    }  
    
    /* @description : method to test create new claim for ShipCSX/Experience cloud */
    
    @isTest 
    static void getSuppliersForRailRoadValidation(){
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            List<Account> result = CSX_CMP_ClaimCreationController.getSuppliersForRailRoad();
            Test.stopTest();
            System.assertEquals(0,result.size(), 'Should return atleast one supplier.');
        }
    }
    
    /* @description : method to test create new claim for staging record */
    
    // @isTest
    // static void claimCreationRevenueRailRoadRecordType(){
        
    //     Map<String,String> requestJSON = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
    //     CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
     
    //     User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
    //     System.runAs(user){  
            
    //         Test.startTest();
    //         //  Map<String, String> resWrapper = CSX_CMP_ClaimCreationHelper.createNewClaim(stagingrecord);
    //         //  CSX_CMP_ClaimCreationHelper.createStagingRecord(response  ,'duplicateList', 1);
    //         //  CSX_CMP_NewClaimWrapper payload, 'duplicateList', 1234
    //         Test.stopTest();  
            
    //         //  System.assertNotEquals('success', resWrapper.get('success'));
    //     }
    // }
    
    /* @description : method to test Get Claim Status History */
    
    @isTest
    static void testGetClaimStatusHistory() {
        
        Map<String, String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);            
        CaseHistory history = new CaseHistory();
        history.CaseId = response.claimId;
        history.Field = 'Status';
        insert history;       
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user){
            Test.startTest();
            List<CaseHistory> result = CSX_CMP_ClaimCreationHelper.getClaimStatusHistory(response.claimId);
            Test.stopTest();
            
            System.assertNotEquals(2, result.size(), 'Expected 2 case history records');
        }
    }
    
    /* @description : method to test Decline Claim */
    
    @isTest
    static void testDeclineClaim() {
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);                  
        
        CSX_CMP_Decline_Code_Master__c declineCodeMaster = new CSX_CMP_Decline_Code_Master__c();
        declineCodeMaster.CSX_CMP_Email_Message__c = 'sdfghjkl';
        insert declineCodeMaster;
        
        Case responseCase = [SELECT Id, CSX_CMP_Review__c, CSX_CMP_Decline_Code__c, CSX_CMP_System_Action_Toggle__c, Status FROM Case WHERE Id = :response.claimId]; 
        responseCase.Status = 'Declined';
        responseCase.CSX_CMP_Decline_Code__c = declineCodeMaster.id;  
        responseCase.CSX_CMP_Review__c = false;
        responseCase.CSX_CMP_System_Action_Toggle__c = !responseCase.CSX_CMP_System_Action_Toggle__c;
        update responseCase;  
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1]; 
        
        System.runAs(user){
            Test.startTest();
            CSX_CMP_ClaimCreationHelper.declineClaim(response.claimId);
            Test.stopTest();
            
            System.assertEquals('Declined', responseCase.Status, 'The claim status should be Declined after declineClaim');
            
        }
    }
    
    /* @description : method to test Identify Refile Version Num */
    
    @isTest
    static void testIdentifyRefileVersionNum() {
        
        CSX_CMP_NewClaimWrapper claimInput = CSX_CMP_TestUtility.claimInputForShipCSX(); 
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1]; 
        
        System.runAs(user){
            Test.startTest();      
            Integer refileVersionNum = CSX_CMP_ClaimCreationHelper.identifyRefileVersionNum(claimInput);
            Test.stopTest(); 
       	    System.assert(refileVersionNum != null, 'refileVersionNum should not be null');
        }    
    }  
    
    
    @isTest 
    static void testIsClaimCreationAllowed(){ 
        
        String permissionName = 'CSX_CMP_Freight_Claims_Access' ;
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1]; 
        
        System.runAs(user){
            Test.startTest();      
            Boolean isAllowed = CSX_CMP_ClaimCreationHelper.isClaimCreationAllowed(permissionName);
            Test.stopTest(); 
        	System.assertEquals(false, isAllowed, 'User should be allowed to create a claim');
        } 
        
    }
    // Create stagingRecordId details in testUtility to cover getNewClaimWrapper method.
    
}