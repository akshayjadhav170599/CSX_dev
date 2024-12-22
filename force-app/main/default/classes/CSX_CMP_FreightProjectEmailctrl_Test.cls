/**
    @author             - Infosys
    @name               - CSX_CMP_FreightProjectEmailctrl_Test
    @createdDate       - 5/07/2024
    @description        - Class for FreightProject VF Component and related operations
    @RICEFW reference   - CMP-E-0491
*/
@isTest
public class CSX_CMP_FreightProjectEmailctrl_Test {

    /* @description : These method is used to make test data */
    @TestSetup
    static void makeData() { 

        CSX_CMP_TestMasterDataUtility.createMasterData();

        // Creating Freight Claim
        Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null);
    }
    /* @description : These method is used to test the project email template */
   // @isTest
   // static void testLogoUrl(){
      //  Organization orgName = [SELECT Id,Name,IsSandbox FROM Organization];
    	//CSX_CMP_Utility.logoUrl();
      //  Document testDocument = [SELECT Id FROM Document WHERE DeveloperName = 'CSX_CMP_Logo'];
       // String expectedUrl = URL.getOrgDomainURL().toExternalForm()+'/servlet/servlet.ImageServer?id='+testDocument.Id+'&oid='+orgName.Id;
      //   System.assertNotEquals(null, expectedUrl,'expectedUrl should not be null');
   // }

    /* @description : These method is used to test the project email template */
    @isTest
    static void testProjectEmailtemplate() {
		case cases = [SELECT Id,CSX_CMP_Claim_Amount__c,CaseNumber FROM Case WHERE CSX_CMP_Claim_Amount__c = 230 LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_FreightProjectEmailController.CSX_CMP_claimWrapper claimWrapper = new CSX_CMP_FreightProjectEmailController.CSX_CMP_claimWrapper();
        System.runAs(user) {
            Test.startTest();
                CSX_CMP_FreightProjectEmailController projectCaseId = new CSX_CMP_FreightProjectEmailController();
                projectCaseId.caseId = cases.Id;
                claimWrapper = projectCaseId.claimWrapper;
            Test.stopTest();

            System.assertNotEquals(null, claimWrapper,'claimWrapper should not be null');
            System.assertEquals(cases.CaseNumber, claimWrapper.claimNumber,'Claim Number should be '+cases.CaseNumber);
        }
    }


    // 1. RICEFW number is missing on original class initial lines
    // 2. getClaimDetails - method doesn't have description
    // 3. remove commented code from original class

}