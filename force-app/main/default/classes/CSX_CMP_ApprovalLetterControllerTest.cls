@isTest
public class CSX_CMP_ApprovalLetterControllerTest {
    
   @testSetup
    static void setupData() {
        
       Document testDocument = new Document(
            Name = 'Test Document',
            DeveloperName = 'CSX_CMP_Logo',
            FolderId = UserInfo.getUserId(),
            Type = 'jpg'
        );
        insert testDocument;
       
        Case objClaim = new Case(
        	RecordTypeId = [Select Id From RecordType Where DeveloperName = 'Freight'].Id,
            Type = 'FC Customer Claim',
            CSX_CMP_Claim_Amount__c = 50,
            Status = 'Open'
        );
        insert objClaim;

       // Create test data
       CSX_CMP_TestMasterDataUtility.createMasterData();
	   
 		Map<String,String> requestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(requestJSON, null); 

        CSX_CMP_Approval_History__c approvalHistory = new CSX_CMP_Approval_History__c();
            approvalHistory.CSX_CMP_Claim__c = response.claimId;
            approvalHistory.CSX_CMP_Date__c = Date.today().addDays(-1);
        insert approvalHistory;
    }

    @isTest
    static void testController() {
        
        Case claim = [SELECT Id FROM Case LIMIT 1];
        Test.setCurrentPageReference(new PageReference('/apex/CSX_CMP_ApprovalLetterPage'));
        ApexPages.currentPage().getParameters().put('id', claim.ID); 

        // Instantiate the controller
        CSX_CMP_ApprovalLetterController.CSX_CMP_claimWrapper wrp = new CSX_CMP_ApprovalLetterController.CSX_CMP_claimWrapper();
        CSX_CMP_ApprovalLetterController controller = new CSX_CMP_ApprovalLetterController();
        wrp = controller.getclaimDetails();
		
        controller.objClaimWrapper.supplierName = '1123';
        // Verify the claim details
        System.assertNotEquals(null, controller.objClaimWrapper, 'The claim wrapper should not be null');
    }
    
}