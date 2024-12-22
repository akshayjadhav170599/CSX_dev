/**
@Author       - Infosys
@Name         - CSX_CMP_ExternalEndPointController
@Created Date - 10/27/2023
@Description  - Apex class on Custom setting on External Page Endpoints object
*/
public with sharing class CSX_CMP_ExternalEndPointController {
    
    //this method retrieves the endpoint link from a custom setting based on a given endpoint name
    @AuraEnabled(cacheable=true)
    public static String getEndPointLink(String endPointName) {
        string customSettingValue;
        try{
        // Map to associate endpoint names with their corresponding API field names
        Map<String,String> endPointNametoAPIMap = new Map<String,String>{'ECM' => 'CSX_CMP_ECM_Endpoint__c'};
		// Retrieve the field name associated with the 'ECM' endpoint from the map
        String fieldName = endPointNametoAPIMap.get('ECM');
        CSX_CMP_External_Page_Endpoints__c customSetting = CSX_CMP_External_Page_Endpoints__c.getInstance();
        // If the custom setting instance exists, retrieve the value of the field specified by the field name
        customSettingValue = customSetting != null ? customSetting.get(fieldName).toString() : null;
        
        }catch(Exception ex){
          // Log the error using the CSX_CMP_LoggerUtility if an exception occurs
          CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ExternalEndPointController','getEndPointLink',endPointName,ex);
            ex.getMessage();  
        }
        return customSettingValue;
    }
}