/**
@Author       - Nilesh Soni
@Name         - CSX_CMP_StateCityController_Test
@Created Date - 31/10/2023
@Description  - Test class controller for City and state
*/
@isTest
public class CSX_CMP_StateCityController_Test {
    @testSetup
    public static void setupdata(){
    	CSX_CMP_TestMasterDataUtility.createMasterData();
    }

    /**
    @description : Test method to get states and city
     */
    @isTest
    static void testGetStatesAndCities() {
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
        Test.startTest();
            Map<String, List<String>> result = CSX_CMP_StateCityController.getStatesAndCities();
            System.assertNotEquals(null, result.size(),'response should return 10+ records');         
		Test.stopTest();
    	}
    }

}