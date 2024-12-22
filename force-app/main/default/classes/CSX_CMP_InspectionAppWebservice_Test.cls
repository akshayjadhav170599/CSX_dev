/**************************************************************************************
Apex Class Name     : CSX_CMP_InspectionAppWebservice_Test
Function            : This class is used to test the methods in CSX_CMP_InspectionAppWebservice class
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys             05/16/2024       First version of this class.
*************************************************************************************/
@isTest
public class CSX_CMP_InspectionAppWebservice_Test {

	@TestSetup
	static void makeData() {
		CSX_CMP_TestMasterDataUtility.createMasterData();
	}

	/**
    @description : method to test inspection create data  positive scenerio where records are created
     */ 
	@isTest
	static void inspectionCreateTest() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/v1/InspectionCreate';
		req.httpMethod = 'POST';
		RestContext.request = req;
		String requestBodyJson = JSON.serialize(getRequestBody());
		req.requestBody = Blob.valueOf(requestBodyJson);
		RestContext.request = req;
		RestContext.response = res;

		User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

		System.runAs(user) {
			Test.startTest();
			CSX_CMP_InspectionAppWebservice.inspectionCreate();
			Test.stopTest();

            List<CSX_CMP_Inspection_Header__c> inspectionHeaders = [SELECT Id FROM CSX_CMP_Inspection_Header__c];
            System.assertNotEquals(0, inspectionHeaders.size(), 'Inspection Header should be created');
		}
	}

    /**
    @description : method to test inspection create data  negative scenerio where exception is thrown
     */
    @isTest
    static void inspectionCreateTestNegativeScenerio(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/InspectionCreate';
        req.httpMethod = 'POST';
        RestContext.request = req;
        Map<String, Object> requestBody = getRequestBody();
        Object driver = requestBody.get('driver');
        requestBody.put('driver',JSON.serialize(driver));
        String requestBodyJson = JSON.serialize(requestBody);
        req.requestBody = Blob.valueOf(requestBodyJson);
        RestContext.request = req;
        RestContext.response = res;

        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];

        System.runAs(user) {
            Test.startTest();
            try{
                CSX_CMP_InspectionAppWebservice.inspectionCreate();
            } catch(Exception e){
                System.assertNotEquals(null,e.getMessage(),'Exception should be thrown');
            }
            Test.stopTest();
        }
    }


    private static Map<String, Object> getRequestBody(){
        Map<String, Object> requestBody = new Map<String, Object>();
		requestBody.put('source', 'HAULAWAY');
		requestBody.put('haulawayTransactionId', 'test1234');
		requestBody.put('rampId', 'test1234');
		requestBody.put('terminalName', 'New Boston');
		requestBody.put('inspectorId', 'test9598');
		requestBody.put('inspectionCity', 'Annapolis');
		requestBody.put('inspectionState', 'MD');
		requestBody.put('inspectionDateTime', '2020-12-23T12:00:00');
		Map<String, Object> driver = new Map<String, Object>();
		driver.put('companyScac', 'DRAY');
		driver.put('companyName', 'Truck Company Name');
		driver.put('driverLicenseid', 'MD183858K00032093');
		driver.put('driverName', 'John Doe');
		driver.put('emailAddress', UserInfo.getUserEmail());
		driver.put('phoneNumber', '1234567890');
		requestBody.put('driver', driver);
		List<Map<String, Object>> vehicles = new List<Map<String, Object>>();
		Map<String, Object> vehicle = new Map<String, Object>();
		vehicle.put('vin', '12362452467890');
		vehicle.put('vehicleType', '1234');
		Map<String, Object> railCar = new Map<String, Object>();
		railCar.put('equipmentInitial', 'CSXT');
		railCar.put('equipmentNumber', '123456');
		railCar.put('aarCarType', 'V123');
		railCar.put('sealStatus', 'aabc');
		vehicle.put('railCar', railCar);
		vehicle.put('originCarrier', 'CSXT');
		vehicle.put('destinationCarrier', 'BNSF');
		vehicle.put('shipDate', '2020-12-01');
		vehicle.put('dealerCode', '7JJDBC');
		vehicle.put('routeCode', 'ABCDDD');
		vehicle.put('bayLocate', 'A1');
		vehicle.put('mfrsCode', 'G');
		List<Map<String, Object>> damages = new List<Map<String, Object>>();
		Map<String, Object> damage = new Map<String, Object>();
		damage.put('damageItem', '01');
		damage.put('damageType', '01');
		damage.put('damageSeverity', '001');
		damage.put('damageExclusionIndicator', 'F');
		damages.add(damage);
		vehicle.put('damages', damages);
		vehicles.add(vehicle);
		requestBody.put('vehicles', vehicles);
        return requestBody;
    }
}