/**************************************************************************************
Apex Class Name     : CSX_CMP_UploadEmailToECMController
Function            : Class for converting email to pdf and uploading to ECM
RICEFW Id           : CMP-E-0442
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/13/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_UploadEmailToECMController {
    public static void createEmailContent(EmailMessage email) {
        ContentVersion cont = new ContentVersion();
        Map<Id, String> cvIdToLinkedId = new Map<Id, String>();
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        try {
            PageReference pdfPage = Page.CSX_CMP_EmailToPDF;
            pdfPage.getParameters().put('id', email.Id);
            Blob pdfBlob = pdfPage.getContentAsPDF();
            
            cont.Title = email.Subject;
            cont.PathOnClient = email.Subject + '.pdf';
            cont.VersionData = pdfBlob;
            cont.CSX_CMP_Email_Message_Id__c = email.Id;
            cont.CSX_CMP_Parent_Id__c = email.ParentId;
            cont.Origin = 'H';
            Database.SaveResult contentVersionRecord = Database.Insert(cont);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_UploadEmailToECMController',
                'createEmailContent',
                contentVersionRecord,
                'ContentVersion'
            );
            cvIdToLinkedId.put(contentVersionRecord.id, email.ParentId);
            List<Id> cvIds = new List<Id>{ contentVersionRecord.id };
                
            //List<Attachment> attList = email.Attachments;
            //List<Id> attachmentIds = new List<Id>();
            //Database.SaveResult[] cVRecords;
            Database.SaveResult[] cdlRecords;
            //List<ContentVersion> cvList1 = new List<ContentVersion>();
            
            List<ContentVersion> cvList = [
                SELECT id, ContentDocumentId, CSX_CMP_Parent_Id__c
                FROM ContentVersion
                WHERE id IN :cvIds
                WITH SECURITY_ENFORCED
            ];
            if (!cvList.isEmpty()) {
                for (ContentVersion cv : cvList) {
                    ContentDocumentLink cd1 = new ContentDocumentLink();
                    cd1.ContentDocumentId = cv.ContentDocumentId;
                    cd1.LinkedEntityId = cv.CSX_CMP_Parent_Id__c;
                    cd1.ShareType = 'V';
                    cdList.add(cd1);
                }
                cdlRecords = Database.Insert(cdList, false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'CSX_CMP_UploadEmailToECMController',
                    'createEmailContent',
                    cdlRecords,
                    'ContentDocumentLink'
                );
            }
            //ID jobID = System.enqueueJob(new CSX_CMP_ECMQueueable(cvIds, false, 'Claim'));
            CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, true, 'Claim',true);
            Database.executeBatch(uploadBatch, 1);
        } catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_UploadEmailToECMController',
                'createEmailContent',
                String.valueOf(cont),
                e
            );
        }
    }
    
    @AuraEnabled
    public static String manualEmailUpload(Id emailMessageId) {
        List<EmailMessage> emailsRelated = new List<EmailMessage>();
        String response;
        try{
            List<CSX_CMP_Document_Ref__c> docRef = [SELECT Id, CSX_CMP_Email_Message_Id__c, CSX_CMP_Claim__c,
                                                    CSX_CMP_Document_Type__c 
                                                    FROM CSX_CMP_Document_Ref__c where CSX_CMP_Email_Message_Id__c =:emailMessageId 
                                                    AND CSX_CMP_ECM_Document_ID__c != null
                                                    WITH SECURITY_ENFORCED 
                                                ];

            if(docRef.isEmpty()){
            emailsRelated = [
                SELECT Id, TextBody, HtmlBody, Subject, FromAddress, ToAddress, CcAddress, CreatedDate, ParentId
                FROM EmailMessage
                WHERE Id = :emailMessageId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            createEmailContent(emailsRelated[0]);
                response = 'Your Request has been submitted.ECM id is populated in Document Reference on successful upload ';
            }
            else{
                response = 'Email is already Uploaded';
            }
        }catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_UploadEmailToECMController',
                'manualEmailUpload',
                String.valueOf(emailsRelated),
                e
            );
        }
        return response;
    }
    
    @AuraEnabled
    public static void manualDocumentUpload(Id contentDocId) {
        List<Id> cvIds = new List<Id>();
        try{
            Map<ID, ContentVersion> idToCvRecMap = new Map<ID, ContentVersion>([SELECT id,ContentDocumentId, CSX_CMP_Parent_Id__c
                                                                                FROM ContentVersion
                                                                                WHERE ContentDocumentId = :contentDocId 
                                                                                and IsLatest=true
                                                                                WITH SECURITY_ENFORCED
                                                                                LIMIT 1]);
            
            cvIds = new List<Id>(idToCvRecMap.keySet());
            CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, false, 'Claim',true);
            Database.executeBatch(uploadBatch, 1);
        }catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_UploadEmailToECMController',
                'manualDocumentUpload',
                String.valueOf(cvIds),
                e
            );
        }
        
    }
}