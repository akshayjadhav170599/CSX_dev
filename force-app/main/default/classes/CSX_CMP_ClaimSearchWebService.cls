/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimSearchWebService
Function            : Class for Webservice to search claims and settlements.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           02/11/2023       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/claims/search/*')
global with sharing class CSX_CMP_ClaimSearchWebService {
    @HttpPost
    global static void claimSearchService (){ 
        CSX_CMP_ClaimSearchController.ClaimSearchResultWrapper responsewrapper = new CSX_CMP_ClaimSearchController.ClaimSearchResultWrapper();
        RestResponse response = RestContext.response;
        RestRequest req;
        string request ;
        try{
            req = RestContext.request ;
            Map<String, object> reqpmap = (Map<String, object>) JSON.deserializeUntyped(req.requestBody.toString());
            request = JSON.serialize(reqpmap);
            responsewrapper= CSX_CMP_ClaimSearchController.GetClaimRecords(request);
            if(responsewrapper.status == '200'  ){
                if(responsewrapper.errorMessage != system.label.CSX_CMP_Results_not_found){ 
                    response.responseBody =Blob.valueOf(JSON.serialize(responsewrapper));
                }
                else{ 
                    response.responseBody =Blob.valueOf(system.label.CSX_CMP_Results_not_found);
                } 
            }
            else if (responsewrapper.status == '400'){
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(responsewrapper.errorMessage));
            }
        }
        catch(System.StringException ex){
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('{"error" : '+ ex.getMessage() +'}');
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'Claim Search',req.requestBody.toString(),'');
        }catch(System.QueryException ex){
            response.statusCode = 404;
            response.responseBody = Blob.valueOf('{"error" : '+ ex.getMessage() +'}');
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'Claim Search',req.requestBody.toString(),'');
        }catch(Exception ex){
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(ex.getMessage());
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'Claim Search',req.requestBody.toString(),'');
        }
    } 
}