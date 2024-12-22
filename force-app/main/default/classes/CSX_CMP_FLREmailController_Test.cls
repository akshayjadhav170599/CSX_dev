/**
@Author       - Infosys
@Name         - CSX_CMP_FLREmailController_Test
@Created Date - 01/11/2024
@Description  - This is test class for CSX_CMP_FLREmailController
@RICEFW reference - CMP-E-0422
*/

@isTest
private class CSX_CMP_FLREmailController_Test {
    
    @testSetup
    public static void setupdata(){
        // Calling MasterDataLoader to load the data
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
 		CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null); 
    }
    
    /* Method to check FLR Email */
    @isTest
    static void testgetClaimDetails() {      
        case claim = [SELECT Id,CaseNumber,CSX_CMP_Claim_Amount__c,CSX_CMP_FLR_Questions__c from case LIMIT 1];
        List<CSX_CMP_FLR_Question__c> questionList = new List<CSX_CMP_FLR_Question__c>{
            new CSX_CMP_FLR_Question__c(CSX_CMP_Question_To__c = 'OriginRoad', CSX_CMP_Question__c = 'Question 1'),
                new CSX_CMP_FLR_Question__c(CSX_CMP_Question_To__c = 'DestinationRoad', CSX_CMP_Question__c = 'Question 2'),
                new CSX_CMP_FLR_Question__c(CSX_CMP_Question_To__c = 'OtherRoad', CSX_CMP_Question__c = 'Question 3')
                
                };
                    claim.CSX_CMP_FLR_Questions__c =JSON.serialize(questionList);
        update claim;
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            CSX_CMP_FLREmailController controller = new CSX_CMP_FLREmailController();
            controller.originRoad = 'OriginRoad';
            controller.destinationRoad = 'DestinationRoad';
            controller.otherRoadValue ='OtherRoad';
            controller.caseId = claim.id;
            Test.stopTest();
            System.assertEquals(claim.CSX_CMP_Claim_Amount__c, controller.objCaseWrapper.claimAmount,'Check Amount should be');
        }
    }

    // 1. Remove unused variables from wrapper on original class
    // 2. Remove commented code from original class    
    
}