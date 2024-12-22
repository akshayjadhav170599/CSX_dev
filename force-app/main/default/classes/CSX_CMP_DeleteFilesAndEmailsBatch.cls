/**
@Author       - Infosys
@Name         - CSX_CMP_DeleteFilesAndEmailsBatch
@Created Date - 03/14/2024
@Description  - This class is used to delete files and emails from Salesforce (backup will be in ECM where needed).
*/
public with sharing class CSX_CMP_DeleteFilesAndEmailsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Integer count = 0;
    
    public Iterable<sObject> start(Database.BatchableContext context) {
        return [SELECT CSX_CMP_Document_Type__c, CSX_CMP_Deletion_Condition__c, Label, CSX_CMP_sequence__c FROM CSX_CMP_DocumentDeletionRule__mdt order by CSX_CMP_sequence__c];
    }
    
    public void execute(Database.BatchableContext context, List<CSX_CMP_DocumentDeletionRule__mdt> deletionRules) {
        
        List<ContentDocument> cdsToDelete = new List<ContentDocument>();
        List<ContentDocumentLink> cdlsToDelete = new List<ContentDocumentLink>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<EmailMessage> emailsToDelete = new List<EmailMessage>();
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        List<Id> contentDocumentIds = new List<Id>();
        List<Id> emailMessageIds = new List<Id>();
        List<CSX_CMP_Document_Ref__c> documentRefList = new List<CSX_CMP_Document_Ref__c>();
        try {
            if(!deletionRules.isEmpty()){
                //String documentType = deletionRules[0].CSX_CMP_Document_Type__c;
                documentRefList = getDocumentRefRecords(deletionRules[0]);
                
                if (!documentRefList.isEmpty()) {
                    for (CSX_CMP_Document_Ref__c doc : documentRefList) {
                        if(doc.CSX_CMP_Content_Document_ID__c!=null){
                           contentDocumentIds.add(doc.CSX_CMP_Content_Document_ID__c); 
                        }
                        if(doc.CSX_CMP_Email_Message_Id__c!=null){
                           emailMessageIds.add(doc.CSX_CMP_Email_Message_Id__c);
                        }
                    }
                    if (!contentDocumentIds.isEmpty()) {
                        cdsToDelete = [SELECT Id, Title, ParentId FROM ContentDocument WHERE Id IN :contentDocumentIds];
                        contentDocumentLinks = [
                            SELECT Id, ContentDocumentId, ShareType
                            FROM ContentDocumentLink
                            WHERE ContentDocumentId IN :contentDocumentIds
                        ];
                        for(ContentDocumentLink link:contentDocumentLinks){
                            if(link.shareType == 'V'){
                                cdlsToDelete.add(link);
                            }
                        }
                    }
                    if (!emailMessageIds.isEmpty()) {
                        emailsToDelete = [SELECT Id, subject FROM EmailMessage WHERE Id IN :emailMessageIds];
                        attachmentsToDelete = [SELECT Id, ParentId FROM Attachment WHERE ParentId IN :emailMessageIds];
                    }
                    
                    if (!attachmentsToDelete.isEmpty()) {
                        Database.DeleteResult[] deleteAttachments = Database.delete(attachmentsToDelete, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_DeleteFilesAndEmailsBatch',
                            'execute',
                            deleteAttachments,
                            'Attachment'
                        );
                    }
                    if (!emailsToDelete.isEmpty()) {
                        Database.DeleteResult[] deleteEmails = Database.delete(emailsToDelete, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_DeleteFilesAndEmailsBatch',
                            'execute',
                            deleteEmails,
                            'EmailMessage'
                        );
                    }
                    if (!cdlsToDelete.isEmpty()) {
                        Database.DeleteResult[] deleteContentDocLinks = Database.delete(cdlsToDelete, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_DeleteFilesAndEmailsBatch',
                            'execute',
                            deleteContentDocLinks,
                            'ContentDocumentLink'
                        );
                    }
                    if (!cdsToDelete.isEmpty()) {
                        Database.DeleteResult[] deleteContentDocs = Database.delete(cdsToDelete, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_DeleteFilesAndEmailsBatch',
                            'execute',
                            deleteContentDocs,
                            'ContentDocument'
                        );
                    }
                    Database.DeleteResult[] deletedocumentRefs = Database.delete(documentRefList, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_DeleteFilesAndEmailsBatch',
                        'execute',
                        deletedocumentRefs,
                        'CSX_CMP_Document_Ref__c'
                    );
                }
            }
        } catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_DeleteFilesAndEmailsBatch',
                'execute',
                JSON.serialize(documentRefList),
                e
            );
        }
    }
    
    public void finish(Database.BatchableContext context) {
        CSX_CMP_LoggerUtility.addExecutionLog(
            'CSX_CMP_DeleteFilesAndEmailsBatch',
            'Number of Files, Emails and Document ref records deleted',
            'File/Attachment/Email/CSX_CMP_Document_Ref__c',
            count
        );
    }
    
    public List<CSX_CMP_Document_Ref__c> getDocumentRefRecords(CSX_CMP_DocumentDeletionRule__mdt delRule) {
        List<CSX_CMP_Document_Ref__c> documentRefRecords;
        String strQuery;
        try {
            Id recTypeId = Schema.SObjectType.CSX_CMP_Document_Ref__c.getRecordTypeInfosByName()
                .get('ServiceCloud_Claims')
                .getRecordTypeId();
            strQuery =
                'SELECT Id, CSX_CMP_Claim__r.status, CSX_CMP_Claim__r.CreatedDate, CSX_CMP_Claim__r.CSX_CMP_Settled_Date__c, CSX_CMP_Claim__r.CSX_CMP_Service_Period__c, CSX_CMP_File_Name__c, ' +
                'CSX_CMP_Content_Document_ID__c, CSX_CMP_Email_Message_Id__c, CSX_CMP_Document_Type__c ' +
                'FROM CSX_CMP_Document_Ref__c where RecordTypeId = \'' +
                recTypeId +'\' and ';
            
            if(delRule.Label.contains('Abstract') || delRule.Label.contains('Distribution')){
               Date servicePeriodDate = Date.today().addDays(-Integer.valueOf(delRule.CSX_CMP_Deletion_Condition__c));
                String year=String.valueOf(servicePeriodDate.year());
                String servicePeriod = 'PER-'+String.valueOf(servicePeriodDate.month())+'-'+ year.substring(year.length() - 2);
                strQuery =
                    'SELECT Id, CSX_CMP_Property_Portal_Staging__r.CSX_CMP_Service_Period__c, CSX_CMP_File_Name__c, ' +
                    'CSX_CMP_Content_Document_ID__c, CSX_CMP_Email_Message_Id__c, CSX_CMP_Document_Type__c ' +
                    'FROM CSX_CMP_Document_Ref__c where RecordTypeId = \'' +
                     recTypeId +'\' and ';
                strQuery += 'CSX_CMP_Document_Type__c = \''+
                    delRule.CSX_CMP_Document_Type__c +
                    '\' and CSX_CMP_Property_Portal_Staging__r.CSX_CMP_Service_Period__c = \'' + servicePeriod +'\' LIMIT 10000';
            }else if (delRule.CSX_CMP_Document_Type__c != null && (!(delRule.Label.contains('Abstract') || delRule.Label.contains('Distribution')))){
                strQuery += 'CSX_CMP_Document_Type__c = \''+
                    delRule.CSX_CMP_Document_Type__c +
                    '\' and ' +
                    delRule.CSX_CMP_Deletion_Condition__c +
                    ' LIMIT 10000';
               
            }else{
                strQuery += delRule.CSX_CMP_Deletion_Condition__c +
                    ' LIMIT 10000';
            }
            //system.debug('strQuery' +strQuery);
            documentRefRecords = Database.query(strQuery);
        } catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_DeleteFilesAndEmailsBatch',
                'getDocumentRefRecords',
                JSON.serialize(strQuery),
                e
            );
            return null;
        }
        return documentRefRecords;
    }
}