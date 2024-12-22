/*
RICEF ID : CMP-I-1743
@author : Infosys
@description : Webservice to provide PDF content (AR Invoice, Railcar report, Abstract, Distribution reports)
*/
@RestResource(urlMapping='/v1/documents/*')
global with sharing class CSX_CMP_FetchPDFContent {
    /**
@description: Method to fetch the invoice details based on the recordUniqueKey and pdfReportType
@return: PdfResponseWrapper - contains the pdfBlobContent, recordUniqueKey, pdfReportType, status
Request URI : https://csx-claims-dev--dev.sandbox.my.salesforce.com/services/apexrest/v1/documents/fetch
Method : Get
*/
    @HttpGet
    global static void fetchDetails() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        try {
            req = RestContext.request;
            res = RestContext.response;
            Blob pdfBlob;
            
            
            
            // List<ContentVersion> s2  = [SELECT VersionData FROM ContentVersion where ContentDocumentId = '069Dz0000021JjZIAU' WITH SECURITY_ENFORCED];
            
            // PdfRequestWrapper requestWrapper = new PdfRequestWrapper();
            // requestWrapper.recordUniqueKey = req.params.get('recordUniqueKey');
            // requestWrapper.pdfReportType = req.params.get('pdfReportType');
            
            PdfResponseWrapper responseWrapper = new PdfResponseWrapper();
            Boolean isValid = true;
            String errorMessage = '';
            
            if (String.isBlank(req.params.get('recordId'))) {
                isValid = false;
                errorMessage = 'recordId is mandatory';
            }
            if (String.isBlank(req.params.get('reportType'))) {
                isValid = false;
                errorMessage = 'reportType is mandatory';
            }
            
            if (isValid) {
                // responseWrapper.recordUniqueKey = requestWrapper.recordUniqueKey;
                // responseWrapper.pdfReportType = requestWrapper.pdfReportType;
                Pagereference pdfPage;
                switch on req.params.get('reportType') {
                    when 'AR Invoice Report' {
                        /**
Sample Request Body:
{
"recordUniqueKey" : "1800000436",
"pdfReportType":"AR Invoice Report"
}
*/
                        CSX_CMP_AR_Settlement__c arSettlement = [
                            SELECT Id
                            FROM CSX_CMP_AR_Settlement__c
                            WHERE CSX_CMP_Invoice_Number__c = :req.params.get('recordId') WITH SECURITY_ENFORCED
                            LIMIT 1
                        ];
                        if (arSettlement == null) {
                            isValid = false;
                            errorMessage = 'No AR Settlement found for the given Invoice Number';
                        } else {
                            pdfPage = new Pagereference('/apex/CSX_CMP_ARInvoiceReport');
                            pdfPage.getParameters().put('id', arSettlement.Id);
                        }
                    }
                    when 'RailcarReport' {
                        /**
Sample Request Body :
{
"recordUniqueKey" : "I-000721_CSXT 143030",
"pdfReportType":"RailcarReport"
}
*/
                        String ldrName = req.params.get('recordId').substringBefore('_');
                        String equipmentName1 = req.params.get('recordId').substringAfter('_');
                        String equipmentName =equipmentName1.replaceAll('%20',' '); // Added by Sarath to remove line escape issues in the incoming string
                        
                        
                        CSX_CMP_Equipment__c csxEquipment = [
                            SELECT Id
                            FROM CSX_CMP_Equipment__c
                            WHERE Name = :equipmentName AND CSX_CMP_LD_Report__r.Name = :ldrName WITH SECURITY_ENFORCED
                            LIMIT 1
                        ];
                        
                        
                        if (csxEquipment == null) {
                            isValid = false;
                            errorMessage = 'No Equipment found for the given LDR ID and Equipment ID';
                        } else {
                            // pdfBlob = Blob.valueOf(CSX_CMP_Utility.returnClaimSummaryPdf());
                            
                            //pdfBlob = EncodingUtil.base64Encode(pdfBlob);
                            
                            //pdfBlob = s2[0].VersionData;
                            
                            pdfPage = new Pagereference('/apex/CSX_CMP_EquipmentSummaryReport');
                            pdfPage.getParameters().put('id', csxEquipment.Id);
                        }
                    }
                    when else {
                        isValid = false;
                        errorMessage = 'Invalid pdfReportType';
                    }
                }
                
                if (isValid && !Test.isRunningTest()) {
                    
                    pdfBlob = pdfPage.getContentAsPDF();
                    
                     responseWrapper.pdfBlobContent = EncodingUtil.base64Encode(pdfBlob);
                     responseWrapper.status = 'Success';
                } else if(isValid) {
                    pdfBlob = Blob.valueOf('Test Context');
                }
                //responseWrapper.pdfBlobContent = EncodingUtil.base64Encode(pdfBlob).toString();  
                if(!Test.isRunningTest()){            
                    // res.responseBody = s2[0].VersionData;
                    res.responseBody = Blob.valueOf(JSON.serialize(responseWrapper));
                } else {
                    res.responseBody = pdfBlob;
                }
                res.statusCode = 200;
            } else {
                res.responseBody = Blob.valueOf(errorMessage);
                res.statusCode = 400;
            }
        } catch (Exception e) {
            res.responseBody = Blob.valueOf('Error fetching Document');
            res.statusCode = 500;
            CSX_CMP_LoggerUtility.addIntegrationErrorLog('Error fetching Document', 'Fetch PDF Content', req.requestURI.toString(), '');
        }
    }
    
    public class PdfRequestWrapper {
        public String recordUniqueKey; //Mandatory - SAP Invoice #, LDR ID_Equipment Id,
        public String pdfReportType; //Mandatory - AR Invoice Report, Railcar Report,
    }
    
    public class PdfResponseWrapper {
        public String recordUniqueKey; //value from request
        public String pdfReportType; //value from request
        public String pdfBlobContent; //base 64 content
        public String status; //Error, Success
    }
}