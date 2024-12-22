/**
@author       - Infosys
@name         - CSX_CMP_SendFLDXRDIFilesWebService
@createdDate - 4/20/2024
@RICEFW reference - CMP-I-0456
@description  - REST webservice to send FLDX abstract and distribution metadata to property portal when called
*/
@RestResource(urlmapping='/v1/railinc-metadata-files/*')
global with sharing class CSX_CMP_SendFLDXRDIFilesWebService {
    /*
        @description : method to send the details of property portal object to CPI
        @param : servicePeriod,documentType,partnerCarrierCode
        @return : RestContext.response 
    */
    @httpGet
    global static void getFLDXRDIRecords(){
        List<FLDXRDIResponseWrapper> responseWrapperList= new List<FLDXRDIResponseWrapper>();
        RestResponse response = RestContext.response;
        RestRequest req;
        string servicePeriod;
        string documentType;
        string partnerCarrierCode;
        try{
            req = RestContext.request ;
            servicePeriod = RestContext.request.params.get('servicePeriod');
            
            String newPartnerCarrierCode = RestContext.request.params.get('partnerCarrierCode');
            String newDocumentType = RestContext.request.params.get('documentType');
            String reqData='ServicePeriod:'+servicePeriod+','+'partnerCarrierCode:'+newPartnerCarrierCode+','+'partnerCarrierCode:'+newDocumentType;
            if(String.isNotBlank(servicePeriod)){
                
                if(String.isNotBlank(newDocumentType)){
                    documentType= string.valueOf(newDocumentType);
                }
                if(String.isNotBlank(newPartnerCarrierCode)){
                    partnerCarrierCode= string.valueOf(newPartnerCarrierCode);
                }

                responseWrapperList = queryEligibleRecords(servicePeriod,documentType,partnerCarrierCode);
                

                if(!responseWrapperList.isEmpty()){               
                    response.responseBody =Blob.valueOf(JSON.serialize(responseWrapperList));
                    response.addHeader('Content-Type', 'application/json');
                }else{ 
                    response.responseBody =Blob.valueOf(JSON.serialize(responseWrapperList));
                    //response.responseBody =Blob.valueOf('Results not found for the given Service Period');
                    response.addHeader('Content-Type', 'application/json');
                }
            }else{
                response.statusCode = 400;
                response.responseBody = Blob.valueOf('Invalid Input');   
                response.addHeader('Content-Type', 'application/json');
                CSX_CMP_LoggerUtility.addIntegrationErrorLog('Invalid Input','FLDX File process',json.Serialize(reqData),'');
            }   
        }catch(Exception ex){
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('{"error" : '+ ex.getMessage() +'}');
            response.addHeader('Content-Type', 'application/json');
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(ex.getMessage(),'FLDX File process',req.requestBody.toString(),'');
        }
    }
    
    /*
        @description : method to send the details of property portal object to CPI
        @param : servicePeriod,documentType,partnerCarrierCode
        @return : List<FLDXRDIResponseWrapper>
    */
			/* @description : method to fetch the details from property portal object */
    public static List<FLDXRDIResponseWrapper> queryEligibleRecords(string servicePeriod, string documentType, string partnerCarrierCode){
        List<FLDXRDIResponseWrapper> fldxRDIfileWrapperResponse= new List<FLDXRDIResponseWrapper>();
        string filename;
        String generatedby = 'Batch Job';
        String strQuery;
        List<Account> classoneRRcodes = new List<Account>();
        if(Schema.sObjectType.Account.isAccessible()){
            strQuery = 'SELECT Id,CSX_CMP_Document_Type__c,CSX_CMP_Path__c,CSX_CMP_Foreign_RR_Code__c,CSX_CMP_Foreign_RR_Name__c,CSX_CMP_Service_Period__c,CSX_CMP_Currency__c,CSX_CMP_Count_of_Claims__c,CSX_CMP_Total_Claim_Amount__c,CSX_CMP_ECM_Doc_ID__c,'+ 
                                'CSX_CMP_Claim_Number__c,CSX_CMP_Equipment_Initial__c,CSX_CMP_Equipment_Number__c,CSX_CMP_VIN__c,CSX_CMP_Waybill_Number__c,CSX_CMP_Document_Name__c,CSX_CMP_Waybill_Date__c, CSX_CMP_Email_List__c,CSX_CMP_Document_Created_Date__c '+
                                'FROM CSX_CMP_Property_Portal_Staging__c WHERE CSX_CMP_Service_Period__c =: servicePeriod AND CSX_CMP_Generated_By__c =: generatedby';
                                /*strQuery+= ' AND CSX_CMP_External_ID__c like '+'\'%'+recordType+'%\'';*/
            if(documentType !=null){
                strQuery+= ' AND CSX_CMP_Document_Type__c =: documentType';
            }
            if(partnerCarrierCode !=null){
                classoneRRcodes = [SELECT Id,CSX_CMP_FC_SCAC__c FROM Account WHERE CSX_CMP_FC_SCAC__c =: partnerCarrierCode AND CSX_CMP_Class_1_Railroad__c = True AND RecordType.DeveloperName = 'Location' AND Type = 'Supplier'];
            }
            if(!classoneRRcodes.isEmpty()){  
                strQuery+= ' AND CSX_CMP_Foreign_RR_Code__c =: partnerCarrierCode';    
            }
        }
        List<CSX_CMP_Property_Portal_Staging__c> propertyPortalRecords = Database.query(String.escapeSingleQuotes(strQuery));
        
        if(!propertyPortalRecords.isEmpty()){
            
            for(CSX_CMP_Property_Portal_Staging__c pp :propertyPortalRecords){
                FLDXRDIResponseWrapper ppResponseWrapper = new FLDXRDIResponseWrapper();
                ppResponseWrapper.documentType = pp.CSX_CMP_Document_Type__c;
                ppResponseWrapper.documentCreatedDate = pp.CSX_CMP_Document_Created_Date__c;
                ppResponseWrapper.path = pp.CSX_CMP_Path__c;
                //ppResponseWrapper.filename = string.valueOf(pp.CSX_CMP_Document_Name__c).removeEnd('.PDF');
                ppResponseWrapper.filename = string.valueOf(pp.CSX_CMP_Document_Name__c);
                ppResponseWrapper.partnerSCAC = pp.CSX_CMP_Foreign_RR_Code__c != null ? pp.CSX_CMP_Foreign_RR_Code__c : '';
                ppResponseWrapper.partnerCarrierName = pp.CSX_CMP_Foreign_RR_Name__c != null ? pp.CSX_CMP_Foreign_RR_Name__c : '';
                ppResponseWrapper.servicePeriod = pp.CSX_CMP_Service_Period__c != null ? pp.CSX_CMP_Service_Period__c : '';
                ppResponseWrapper.currencyCode = pp.CSX_CMP_Currency__c != null ? pp.CSX_CMP_Currency__c : '';
                ppResponseWrapper.claimCount = pp.CSX_CMP_Count_of_Claims__c != null ? pp.CSX_CMP_Count_of_Claims__c : 0;
                ppResponseWrapper.totalClaimAmount = pp.CSX_CMP_Total_Claim_Amount__c != null ? pp.CSX_CMP_Total_Claim_Amount__c : 0;

                if(ppResponseWrapper.documentType == 'Distribution'){
                    ppResponseWrapper.claimNumber = pp.CSX_CMP_Claim_Number__c != null ? pp.CSX_CMP_Claim_Number__c : '';
                }else{
                    ppResponseWrapper.claimNumber = '';
                }
                
                ppResponseWrapper.equipmentInitial = pp.CSX_CMP_Equipment_Initial__c != null ? pp.CSX_CMP_Equipment_Initial__c : '';
                ppResponseWrapper.vin = pp.CSX_CMP_VIN__c != null ? pp.CSX_CMP_VIN__c : '';
                ppResponseWrapper.waybillNumber = pp.CSX_CMP_Waybill_Number__c != null ? pp.CSX_CMP_Waybill_Number__c : '';
                ppResponseWrapper.waybillDate = pp.CSX_CMP_Waybill_Date__c;
                ppResponseWrapper.email = pp.CSX_CMP_Email_List__c != null ? pp.CSX_CMP_Email_List__c : '';
                ppResponseWrapper.ecmDocumentId = pp.CSX_CMP_ECM_Doc_ID__c != null ? pp.CSX_CMP_ECM_Doc_ID__c : '';
                ppResponseWrapper.equipmentnum = pp.CSX_CMP_Equipment_Number__c != null ? pp.CSX_CMP_Equipment_Number__c : '';
                fldxRDIfileWrapperResponse.add(ppResponseWrapper);
            }
        }
        
        return fldxRDIfileWrapperResponse;
    }

    public class FLDXRDIResponseWrapper{
        public String documentType;
        public String path;
        public String filename;
        public String partnerSCAC;
        public String partnerCarrierName;
        public String servicePeriod;
        public String currencyCode;
        public Decimal claimCount;
        public Decimal totalClaimAmount;
        public String claimNumber;
        public String equipmentInitial;
        public String vin;
        public String waybillNumber;
        public Date waybillDate;
        public String email;
        public String ecmDocumentId;
        public String equipmentnum;
        public Date documentCreatedDate;
    }
}