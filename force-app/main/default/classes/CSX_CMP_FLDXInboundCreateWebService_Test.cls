@isTest
public class CSX_CMP_FLDXInboundCreateWebService_Test {
    @TestSetup
    static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}
    
    @isTest
	public static void claimCreateServiceTestForFLDXCreation() {
		String requestJSON = CSX_CMP_TestUtility.fldxClaimCreationJSON();
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
		system.debug('requestJSON ::'+requestJSON);
		System.runAs(user) {
			Test.startTest();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			req.requestURI = '/services/apexrest/v1/validate-fldx-claims-summary';
			req.httpMethod = 'POST';
			req.requestBody = Blob.valueOf(requestJSON);
			RestContext.request = req;
			RestContext.response = res;
			CSX_CMP_FLDXInboundCreateWebService.fldxCreateService();
			Test.stopTest();
			/*CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
        
			System.assertNotEquals(
				null,
				request.CSX_CMP_Claim__c,
				'The claim creation service should return a non-null claim number for FLDX creation.'
			);*/
		}
    }
}