@isTest
public class CSX_CMP_TotalCostofClaimHelper_Test {
     @TestSetup
    public static void setupTestData() {
       //  Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();

        // Creating Freight Claim with claim type as FC RR Inbound
       Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
      //  requestJSON.put('claimAmount','240');
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,CSX_CMP_Project_Amount__c,CSX_CMP_Project_Num__c,CSX_CMP_Freight_Revenue_Amount__c,CSX_CMP_Salvage_Amount__c FROM Case WHERE CSX_CMP_Claim_Amount__c = 230 LIMIT 1]);
        caseMap.values()[0].CSX_CMP_Project_Amount__c = 200;
        caseMap.values()[0].CSX_CMP_Project_Num__c = '1234';
        caseMap.values()[0].CSX_CMP_Freight_Revenue_Amount__c = 300;
        caseMap.values()[0].CSX_CMP_Salvage_Amount__c = 300;
        update caseMap.values();

        
        // Creating Freight Claim with claim type as FC RR Outbound Claim
        Map<String,String> requestJSON1 = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        requestJSON1.put('claimType', 'FC RR Outbound Claim');
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response1 = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON1, null);
        Case claim = [SELECT id,parentId From case Where Type = 'FC RR Outbound Claim'];
		claim.ParentId =  response.claimId;
        update claim;
        
         //relating the claim
        CSX_CMP_Related_Claim__c related = new CSX_CMP_Related_Claim__c();
		related.CSX_CMP_Related_Claim__c = response1.claimId;
        related.CSX_CMP_Claim__c = claim.id;
        insert related;

        Account ac = new Account();
        ac.Name = 'BURLINGTON NORTHERN SANTA FE';
        ac.CSX_CMP_External_ID__c = 'BurlingtonNorthernSantaFe';
        insert ac;
        
        // Inserting AR Settlement record
        CSX_CMP_AR_Settlement__c objSettlement = CSX_CMP_TestUtility.generateARSettlement();
        objSettlement.CSX_CMP_Claim__c = response.claimId;
        Insert objSettlement;
        
   
    }
    @isTest
    static void testtotalcostofclaim() {
		case cases = [SELECT Id,CSX_CMP_Claim_Amount__c FROM Case WHERE Type = 'FC RR Inbound Claim' LIMIT 1];

        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest(); 
            list<CSX_CMP_TotalCostofClaimHelper.CostofClaimTransactionWrapper> message = CSX_CMP_TotalCostofClaimHelper.fetchCostofClaimTransactions(cases.Id);
            Test.stopTest(); 
            // case updatedCase = [SELECT Id,CSX_CMP_Claim_Amount__c FROM case WHERE Id = :sourceId];
            //  System.assertEquals('Success', message, 'Message should be "Success"');
            // System.assertNotEquals(null, updatedCase.CSX_CMP_Claim_Amount__c, 'Salvage Claim should be created');

            System.assertNotEquals(0, message.size(), 'Expected non-empty message list.');
        }
        
    }
    /* 
	@description : method to test update Invoice, Cancel Invoice and Send email
	*/
    @isTest
    static void testtoIdentifychildclaim() {
        Set<Id> childClaimIdsforTotalCostofClaim = new Set<Id>();
		case cases = [SELECT Id,CSX_CMP_Claim_Amount__c FROM Case WHERE Type = 'FC RR Outbound Claim'];
        childClaimIdsforTotalCostofClaim.add(cases.id);
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest(); 
            Set<Id> ids = CSX_CMP_TotalCostofClaimHelper.identifyParentClaimsforTotalCostCalc(childClaimIdsforTotalCostofClaim);
            Test.stopTest(); 
            // case updatedCase = [SELECT Id,CSX_CMP_Claim_Amount__c FROM case WHERE Id = :sourceId];
            //  System.assertEquals('Success', message, 'Message should be "Success"');
            // System.assertNotEquals(null, updatedCase.CSX_CMP_Claim_Amount__c, 'Salvage Claim should be created');
            System.assertNotEquals(1, ids.size(), 'Expected non-empty Ids set.');
        }
    }
    
}