/*
@Author       - Infosys 
@Name         - CSX_CMP_ClaimCreationController_Test
@Created Date - 05/07/2024
@Description  - This class is used to test the methods in CSX_CMP_ClaimCreationController class.
*/      
  
@isTest   
public class CSX_CMP_ClaimCreationController_Test{
    
    /*@description : method to create master data for test */
    
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
    static void getGeneralRulesValidation() {
       	   
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
            System.assertNotEquals(1,result.size(), 'Should return atleast one supplier.');
        }
        
    }

    /* @description : method to test claim creation for Revenue Railroad */
    
    @istest
    public static void claimCreationRevenueRailRoad() { 
        
        Map<String,String> testFreightData = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
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
    
    /* @description : method to test claim status history */
    
    @isTest
    static void testGetClaimStatusHistory() {
       
        Case testCase = new Case(); 
        testCase.Subject = 'Test Case';
        testCase.Status = 'New';
        insert testCase;  
        
        CaseHistory history = new CaseHistory();
        history.CaseId = testCase.Id;
        history.Field = 'Status';
        insert history;
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user){
            Test.startTest();
            List<CaseHistory> result = CSX_CMP_ClaimCreationHelper.getClaimStatusHistory(testCase.Id);
            Test.stopTest();
            
            System.assertNotEquals(2, result.size(), 'Expected 2 case history records');
        }
    }
    
    /* @description : method to test Check Related Claims */
    
    @isTest
    static void testCheckRelatedClaim(){
       
         Map<String, String> requestMap = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
         requestMap.put('claimType', 'Rev-RR - Receivable Claim');
            CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
                requestMap,
                null
            );
            Case claim = [
                SELECT Id, CaseNumber, Status, Type, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId LIMIT 1
            ];
            claim.Status = 'Closed';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            update claim;
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Revenue Railroad' AND LastName = 'User' LIMIT 1]; 
        System.runAs(user){
            Test.startTest();  
            String response1 = CSX_CMP_ClaimCreationController.checkRelatedClaim(claim.CaseNumber, 'Rev-RR - Payable Rchg Claim');
            System.assertEquals('Closed', response1, 'Expected closed receivable claim');
            Test.stopTest();
        }
    }

    // @isTest
    // static void testCheckRelatedClaimCatch(){
        
    //     User user = [SELECT Id FROM User WHERE FirstName = 'Expert' AND LastName = 'chatter' LIMIT 1];
    //     system.debug('User: ' + user);

    //     Profile p = [SELECT Id FROM Profile WHERE Name='Minimum Access - Salesforce']; 
    //     User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
    //         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    //         LocaleSidKey='en_US', ProfileId = p.Id, 
    //         TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com' + String.valueOf(System.currentTimeMillis()));

    //     System.runAs(u) {
    //         Test.startTest();
    //             String response1 = CSX_CMP_ClaimCreationController.checkRelatedClaim('CLA00987', 'Rev-RR - Payable Rchg Claim');
    //             System.assertNotEquals(0,[SELECT Id FROM CSX_CMP_Error_Log__c].size(), 'Expected error log record');
    //         Test.stopTest();
    //     }
    // }
    
}