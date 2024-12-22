/**************************************************************************************
Apex Class Name     : CSX_CMP_InterfaceUtility
Function            : Class for Webservice to search L&D Reports. 
RICEFW #            : CMP-I-0537
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           15/2/2024       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/loss-damage-reports/search/*')
global with sharing class CSX_CMP_LDRSearchWebservice {
    @HttpPost
    global static void lDRSearchService(){
        
        
        CSX_CMP_LDRSearchController.ldrSearchResultWrapper  responseWrapperList= new CSX_CMP_LDRSearchController.ldrSearchResultWrapper();       
        RestResponse response = RestContext.response;
        RestRequest req;
        string request;
        try{
            req = RestContext.request;
            Map<String, object> reqpmap = (Map<String, object>) JSON.deserializeUntyped(req.requestBody.toString());
            request = JSON.serialize(reqpmap);
            responseWrapperList = CSX_CMP_LDRSearchController.getLdrRecords(request);
            if(responseWrapperList.status == '200'){
                if(responseWrapperList.errorMessage != system.label.CSX_CMP_Results_not_found){ 
                    response.responseBody =Blob.valueOf(JSON.serialize(responseWrapperList));
                }
                else{ 
                    response.responseBody =Blob.valueOf(system.label.CSX_CMP_Results_not_found);
                } 
            }
            else if (responseWrapperList.status == '400'){
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(responseWrapperList.errorMessage));
                CSX_CMP_LoggerUtility.addIntegrationErrorLog(JSON.serialize(responseWrapperList.errorMessage),'L&D Report Search',request,'');
            }
        // }catch(System.StringException ex){
        //     response.statusCode = 400;
        //     response.responseBody = Blob.valueOf('{"error" : '+ ex.getMessage() +'}');
        //     CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'L&D Report Search',request,'');
        // }catch(System.QueryException ex){
        //     response.statusCode = 404;
        //     response.responseBody = Blob.valueOf('{"error" : '+ ex.getMessage() +'}');
        //     CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'L&D Report Search',request,'');
        }catch(Exception ex){
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(ex.getMessage());
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'L&D Report Search',request,'');
        }   
    }
}