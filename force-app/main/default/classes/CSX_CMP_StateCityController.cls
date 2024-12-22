/**
@Author       - Akshay Jadhav
@Name         - CSX_CMP_StateCityController
@Created Date - 10/23/2023
@Description  - Apex class controller for City and state
*/
public with sharing class CSX_CMP_StateCityController {
	@AuraEnabled(cacheable=true)
	public static Map<String, List<String>> getStatesAndCities() {
		Map<String, List<String>> stateCityMap = new Map<String, List<String>>();
		try {
			List<CSX_CMP_City_State_Master__c> cityStateRecords = [
				SELECT CSX_CMP_State__c, Name, CSX_CMP_City__c
				FROM CSX_CMP_City_State_Master__c
				WITH SECURITY_ENFORCED
				ORDER BY CSX_CMP_State__c, CSX_CMP_City__c ASC
			];
			for (CSX_CMP_City_State_Master__c record : cityStateRecords) {
				String state = record.CSX_CMP_State__c;
				String city = record.CSX_CMP_City__c;
				if (!stateCityMap.containsKey(state)) {
					stateCityMap.put(state, new List<String>());
				}
				stateCityMap.get(state).add(city);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_StateCityController', 'getStatesAndCities ', '', ex);
		}
		return stateCityMap;
	}
}