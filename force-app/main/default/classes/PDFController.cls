public with sharing class PDFController {
    @AuraEnabled(cacheable=true)
    public static String getPDF() {
        Http http = new Http();  
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setHeader('Content-Type', 'multipart/form-data');
		req.setHeader('Accept','application/octet-stream');
		string authAccessToken = CSX_CMP_HTTPUtility.getAccessToken('Axway');
		req.setHeader('Authorization', 'Bearer '+authAccessToken);
		//req.setEndpoint('callout:' + 'CSX_CMP_ECM_Document_APISTAGE' + '/ecm-FreightClaims/documents/ET1078088');
		req.setEndpoint('https://apistaging.csx.com/enterprise-documents/v1/repositories/ecm-FreightClaims/documents/ET1083216');
        
        HttpResponse response = http.send(req);
        System.debug('response: '+response);
		System.debug('responseBody: '+response.getBody());
        if (response.getStatusCode() == 200) {
            Blob pdfBlob = response.getBodyAsBlob();
            // Convert Blob to base64 String to send to LWC
            String base64PDF = EncodingUtil.base64Encode(pdfBlob);
            return base64PDF;
        } else {
            throw new AuraHandledException('Error fetching PDF: ' + response.getStatus());
        }
    }
}