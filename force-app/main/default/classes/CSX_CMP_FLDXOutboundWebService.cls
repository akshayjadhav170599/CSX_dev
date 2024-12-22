/**************************************************************************************
Apex Class Name     : CSX_CMP_FLDXOutboundWebservice
Function            : webservice class to prepare data for FLDX outbound file to be consumed by sterling to create final FLDX file.
RICEFW #            : CMP-I-0461
Modification Log    :
* Developer         : Date :03/27/2023       Description 
* ----------------------------------------------------------------------------                  
* @author         : Infosys                  First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/fldx-outbound-claims/*')
global with sharing class  CSX_CMP_FLDXOutboundWebService {
    
    @HttpGet
    global static void getOutboundClaimRecords(){ 
        RestResponse response = new RestResponse();
        response = RestContext.response;
        try{
            String servicePeriod = RestContext.request.params.get('servicePeriod');
            FLDXResponseWrapper objClaimWrap = new FLDXResponseWrapper();
            //String validServicePeriod = '';
            
          if(servicePeriod == null || String.isBlank(servicePeriod) )
            {
                servicePeriod  = 'PER-'+String.valueOf(System.now().month()-1)+'-'+String.valueOf(system.now().year()).right(2);
               // system.debug(servicePeriod);
            }
            
            if(servicePeriod != null && String.isNotBlank(servicePeriod)){
                objClaimWrap = CSX_CMP_FLDXOutboundWebServiceHelper.getFLDXOutboundWebServiceData(servicePeriod);
                
                if(objClaimWrap != null){ 
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(Json.serialize(objClaimWrap));
                }else{
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(system.label.CSX_CMP_Results_not_found);
                    
                }
             }else {
                response.statusCode = 400;
                response.responseBody = Blob.valueOf('Invalid Request');
                CSX_CMP_LoggerUtility.addIntegrationErrorLog('Service Period is Invalid','FLDX Outbound Process','Service Period is not passed','');
            }
        } catch (Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_FLDXOutboundWebService','getOutboundClaimRecords',RestContext.request.params.get('servicePeriod'),ex);
        }
    }

        //Wrapper
    public class FLDXResponseWrapper{
        public String servicePeriod;
        public String createdDate;
        public List<CSX_CMP_FLDXOutboundWebServiceHelper.ClaimWrapper> claims;
        public FLDXResponseWrapper(){
            claims = new list<CSX_CMP_FLDXOutboundWebServiceHelper.ClaimWrapper>();
        }  
    }
}