/**************************************************************************************
/*
@author             : Infosys
@description        : 

Apex Class Name     : CSX_CMP_SetClaimPriorityBatch_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_SetClaimPriorityBatch_Test {
    
     @TestSetup
    static void makeData() { 
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);       
        Case claim = [SELECT Id, Status,Type, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId];
        claim.Type = 'FC Customer Automobile Claim';
        claim.Status = 'Open';
        claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
        update claim;
 
    }
   
    @isTest
    static void testexecution(){
        List<Case> testCases = new List<Case>();
        set<Id> claims = new Set<Id>();
        case claim = [select Id, CaseNumber from Case where Type='FC Customer Automobile Claim'];     
        claims.add(claim.id);
        testCases.add(claim);

           
        CSX_CMP_BusinessRulesUtility.runClaimPriorityBusinessRules(claims,'CSX_CMP_Claim_Priority',null);
         
        Test.startTest();
        CSX_CMP_SetClaimPriorityBatch testBatch = new CSX_CMP_SetClaimPriorityBatch();
        database.executebatch(testBatch,1);
        Test.stopTest();        
        
        // Query the case after the batch job has run
        Case updatedCase = [SELECT Priority FROM Case WHERE Id = :claim.Id];

        System.assertEquals('Low', updatedCase.Priority, 'Priority should match the expected value');
    }

}