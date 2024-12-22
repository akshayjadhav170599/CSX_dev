@isTest
public class CSX_CMP_NewClaimWrapper_Test {

    /*@description : method to create master data for test */
   /* @testSetup   
    static void setupTestData(){
        CSX_CMP_TestMasterDataUtility.createMasterData();
        
    }*/
 
    @isTest
    static void checkAccess(){
        String username = 'freighttestuser@csx.com.dev';
        User user = [SELECT Id FROM User WHERE userName =: username LIMIT 1];
        System.runAs(user){
            // List<OrgWideEmailAddress> emails = [
			// 		SELECT Id, Address, DisplayName
			// 		FROM OrgWideEmailAddress
			// 		WHERE DisplayName = :System.Label.CSX_CMP_CSX_Support WITH SECURITY_ENFORCED 
			// 	];
            // system.debug('emails : '+ emails);
            String objName = 'OrgWideEmailAddress';
            Map<String, Schema.SObjectField> objectFields = new Map<String, Schema.SObjectField>();
            //Map to get all fields
            objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
            for(String fieldName : objectFields.keySet()){
                if (objectFields.keySet().contains(fieldName) && objectFields.get(fieldName).getDescribe().isAccessible() ) {
                    // Field is accessible
                    
                } else {
                    // Field is not accessible
                    system.debug('Field is not accessible : '+ fieldName);
                }
            }
        }
    }

    /*@isTest
    static void claimCreationFreightRecordType(){
        CSX_CMP_ClaimCreationController_Test.claimCreationFreightRecordType();
        CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c LIMIT 1];
		System.assertNotEquals(
			null,
			request.CSX_CMP_Claim__c,
			'The claim creation service should return a 201 Created status code for EDI creation.'
		);
    }*/
}