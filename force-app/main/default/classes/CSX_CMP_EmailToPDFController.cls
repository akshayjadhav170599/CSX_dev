public with sharing class CSX_CMP_EmailToPDFController {
    public List<EmailMessage> email{get;set;}
    public String emailMsgId {get;set;}
    public CSX_CMP_EmailToPDFController(ApexPages.StandardController emailCont){
        try{
        emailMsgId=ApexPages.currentPage().getParameters().get('id').escapeHtml4();
        email = [SELECT Id, TextBody, HtmlBody,Subject, FromAddress, ToAddress, CcAddress, CreatedDate,  (select Id,name from Attachments)
                      FROM EmailMessage where Id =:emailMsgId 
                      WITH SECURITY_ENFORCED];
        }catch(Exception e){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EmailToPDFController','CSX_CMP_EmailToPDFController',emailMsgId,e);
        }
    }
}