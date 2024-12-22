@isTest
public class CSX_CMP_RelatedCasesController_Test {
	@testSetup   
    static void setupTestData(){    
        
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);   
            
        Case responseCase = [SELECT Id, CSX_CMP_Supplier_Claimant__c,Type FROM Case WHERE Id = :response.claimId]; 
        responseCase.Type = 'FC Customer Claim';
        responseCase.CSX_CMP_Equipment_Initial__c = 'BNSF';
        responseCase.CSX_CMP_Equipment_Num__c = '123456';
        update responseCase;
      
    }
    
    @isTest
    public static void linkRelatedCasesTest(){
        List<Case> lstCase = [Select id,Type from Case WHERE Type='FC Customer Claim' LIMIT 1];
        string jsonString = '[{"caseAvailable":true,"caseDate":"2020-11-02T11:51:43.000Z","caseNumber":"00001045","caseUrl":"https://csx-claims-dev--dev.sandbox.my.salesforce.com/lightning/n/CSX_CMP_Case_Full_Details?c__caseRecordId=00001045","companyName":"INTERNATIONAL PAPER CO","createdBy":"William Olson","status":"Open"}]';
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];  
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_RelatedCasesController.linkRelatedCases(lstCase[0].id,jsonString);
            Test.stopTest();
        }
        system.assertEquals(lstCase[0].Type,'FC Customer Claim','');
    }
    
    @isTest
    public static void getEquipTest(){
        List<Case> lstCase = [Select id,CSX_CMP_Equipment_Initial__c,CSX_CMP_Equipment_Num__c from Case WHERE Type='FC Customer Claim' LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];  
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_RelatedCasesController.getEquipmentNumber(lstCase[0].id);
            Test.stopTest();
        }
        system.assertEquals(lstCase[0].CSX_CMP_Equipment_Initial__c,'BNSF','');
    }
}