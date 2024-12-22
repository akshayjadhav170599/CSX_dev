/*
RICEF ID : 430 - Distubution Claim Creation
@author : Akshay
@description : This class is used to fetch milege
Modification Log:
Ver   Date : 28/5/24        Author                               Modification
1.0                Infosys                               Initial Version
*/

public with sharing class CSX_CMP_FetchMileageController {
    /*
        @description : method to fetch mileage details
        @param : string recordId
    */
    @AuraEnabled
    public static string fetchmilege(string recordId) {
        try{
            string stateOrigin = '';
            string cityOrigin = '';
            string stateDes = '';
            string cityDes = '';
            CSX_CMP_Mileage__c mileageObj = [SELECT Id,CSX_CMP_Miles__c,CSX_CMP_Misroute__c,CSX_CMP_Return_RR__c,CSX_CMP_Misroute_Location__c,CSX_CMP_Return_Location__c,CSX_CMP_Misroute_Location__r.Name,CSX_CMP_Return_Location__r.Name 
                                               FROM CSX_CMP_Mileage__c WHERE Id =:recordId WITH SECURITY_ENFORCED];//inputId[0]
            List<CSX_CMP_InterfaceUtility.TotalMilesReqWrapper> reqMilWrapList = new List<CSX_CMP_InterfaceUtility.TotalMilesReqWrapper>();
            CSX_CMP_InterfaceUtility.TotalMilesReqWrapper objTotalMilesReqWrapper = new CSX_CMP_InterfaceUtility.TotalMilesReqWrapper();
            if(mileageObj  != null){
                List<string> cityStateOrigin = mileageObj.CSX_CMP_Misroute_Location__r.Name.trim().split('\\|');
                
                if(!cityStateOrigin.isEmpty()){
                    cityOrigin = cityStateOrigin[0];
                    stateOrigin = cityStateOrigin[1];
                }
                
                List<string> cityStateDes = mileageObj.CSX_CMP_Return_Location__r.Name.trim().split('\\|');
                if(!cityStateDes.isEmpty()){
                    cityDes = cityStateDes[0].trim();
                    stateDes = cityStateDes[1].trim();
                }
                objTotalMilesReqWrapper.originCarrier = mileageObj.CSX_CMP_Misroute__c.trim();//'CSXT';
                objTotalMilesReqWrapper.destinationCarrier = mileageObj.CSX_CMP_Return_RR__c.trim();//'BNSF';
            }
            
            CSX_CMP_InterfaceUtility.OriginMiles objOriginMiles = new CSX_CMP_InterfaceUtility.OriginMiles();
            objOriginMiles.state = stateOrigin.trim();//'FL';
            objOriginMiles.city = cityOrigin.trim();//'JACKSONVILLE';
            objTotalMilesReqWrapper.origin = objOriginMiles;
            
            CSX_CMP_InterfaceUtility.DestinationMiles objDestMiles = new CSX_CMP_InterfaceUtility.DestinationMiles();
            objDestMiles.state = stateDes.trim();//'FL';
            objDestMiles.city = cityDes.trim();//'TAMPA';
            objTotalMilesReqWrapper.destination = objDestMiles;
            reqMilWrapList.add(objTotalMilesReqWrapper);
            
            CSX_CMP_InterfaceUtility.MileageResWrapper response = CSX_CMP_InterfaceUtility.fetchTotalMiles(reqMilWrapList);
            
            if(response.totalMiles != '-1' && response.totalMiles != null){
                mileageObj.CSX_CMP_Miles__c = Decimal.valueOf(response.totalMiles);
                if(mileageObj.Id != null){
                    Database.SaveResult mileageRecord = Database.UPDATE(mileageObj);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_FetchMileageController', 'fetchmilege', mileageRecord,'mileageRecord');
                }
                return response.status;
            }else{
                return 'Error';
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_FetchMileageController','fetchmilege',recordId,ex);
            return ex.getMessage();
        }
    } 
}