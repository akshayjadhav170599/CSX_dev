/**************************************************************************************
Apex class Name     : CSX_CMP_ARSettlementTriggerHandler
Function            : Update 3rd Party Invoice number and generate PDF
RICEFW				: CMP-I-1975
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           09/6/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_ARSettlementTriggerHandler {
    public static void handleAfterUpdate(List<CSX_CMP_AR_Settlement__c> newSettlements, Map<Id, CSX_CMP_AR_Settlement__c> oldSettlementsMap) {//
        try {
            Set<Id> settlementIds = new Set<Id>();
            for (CSX_CMP_AR_Settlement__c newSettlement : newSettlements) {
                CSX_CMP_AR_Settlement__c oldSettlement = oldSettlementsMap.get(newSettlement.Id);
                if (oldSettlement.CSX_CMP_Integration_Status__c == 'Sent' && newSettlement.CSX_CMP_Integration_Status__c == 'Processed') {//
                    settlementIds.add(newSettlement.Id);
                }
            }

            if (!settlementIds.isEmpty()) {
                List<CSX_CMP_3rd_Party__c> thirdPartyList = [SELECT Id, CSX_CMP_Invoice_Num__c, CSX_CMP_AR_Settlement__c 
                                                             FROM CSX_CMP_3rd_Party__c 
                                                             WHERE CSX_CMP_AR_Settlement__c IN :settlementIds 
                                                             WITH SECURITY_ENFORCED];
                if(!thirdPartyList.isEmpty()){
                    handleThirdPartyUpdate(thirdPartyList);
                }
            }
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_ARSettlementTriggerHandler',
                'handleAfterUpdate',
                JSON.serialize(newSettlements),
                ex
            );
        }
    }
    
    private static void handleThirdPartyUpdate(List<CSX_CMP_3rd_Party__c> thirdPartyList) {
        try {
            String invoiceNumber;
            for (CSX_CMP_3rd_Party__c thirdParty : thirdPartyList) {
                if (String.isNotBlank(thirdParty.CSX_CMP_Invoice_Num__c)) {
                    invoiceNumber = thirdParty.CSX_CMP_Invoice_Num__c;
                    break;
                }
            }

            if (String.isNotBlank(invoiceNumber)) {
                getInvoicePDFContent(invoiceNumber);
            }
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_ARSettlementTriggerHandler',
                'handleThirdPartyUpdate',
                JSON.serialize(thirdPartyList),
                ex
            );
        }
    }
    
    @future(callout = true)
    public static void getInvoicePDFContent(String invoiceNumber) {
        List<CSX_CMP_3rd_Party__c> newthirdPartyList = [SELECT Id, CSX_CMP_Invoice_Num__c,CSX_CMP_AR_Settlement__c, CSX_CMP_Contact_Email__c, CSX_CMP_Equipment__r.CSX_CMP_Claim__c ,CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.type,CSX_CMP_AR_Settlement__r.CSX_CMP_Customer_Name__c
                                                         FROM CSX_CMP_3rd_Party__c WHERE CSX_CMP_Invoice_Num__c =: invoiceNumber WITH SECURITY_ENFORCED];
        String arSettlementId;
        String thirdpartyClaim;
        List<String> emailAddresses = new List<String>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        List<String> ccEmailList = new List<String>();

        for (CSX_CMP_3rd_Party__c thirdParty : newthirdPartyList) {
            if (thirdParty.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.type == 'FC Customer Automobile Claim') {
                accountIds.add(thirdParty.CSX_CMP_AR_Settlement__r.CSX_CMP_Customer_Name__c);
            }
        }

        List<Contact> listContact = new List<Contact>();
        if (!accountIds.isEmpty()) {
            listContact = [
                SELECT Id, Email, CSX_CMP_Inv_Notif_Other_Emails__c, AccountId
                FROM Contact 
                WHERE AccountId IN :accountIds
                AND CSX_CMP_Status__c != 'Suspended'
                AND CSX_CMP_Inv_Notif_PDF_Attach__c = TRUE 
                WITH SECURITY_ENFORCED
            ];
        }

        for (Contact contact : listContact) {
            if (!contactsByAccountId.containsKey(contact.AccountId)) {
                contactsByAccountId.put(contact.AccountId, new List<Contact>());
            }
            contactsByAccountId.get(contact.AccountId).add(contact);
        }



        for (CSX_CMP_3rd_Party__c thirdParty : newthirdPartyList) {
            /*if (String.isNotBlank(thirdParty.CSX_CMP_Invoice_Num__c)) {
                invoiceNumber = thirdParty.CSX_CMP_Invoice_Num__c;
            }*/
            if (String.isNotBlank(thirdParty.CSX_CMP_AR_Settlement__c)) {
                arSettlementId = thirdParty.CSX_CMP_AR_Settlement__c;
            }
            if (thirdParty.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.type == 'FC Customer Claim') {
                if (thirdParty.CSX_CMP_Contact_Email__c != null) {
                    emailAddresses.addAll(thirdParty.CSX_CMP_Contact_Email__c.split(';'));
                }
            }else if(thirdParty.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.type == 'FC Customer Automobile Claim'){
                List<Contact> relatedContacts = contactsByAccountId.get(thirdParty.CSX_CMP_AR_Settlement__r.CSX_CMP_Customer_Name__c);
                if (relatedContacts != null) {
                    for (Contact emailContact : relatedContacts) {
                        if (string.isNotBlank(emailContact.Email)) {
                            emailAddresses.add(emailContact.Email);
                        }
                        if (emailContact.CSX_CMP_Inv_Notif_Other_Emails__c != null) {
                            ccEmailList.addAll(emailContact.CSX_CMP_Inv_Notif_Other_Emails__c.split(','));
                        }
                    }
                }
			}
            if (thirdParty.CSX_CMP_Equipment__r.CSX_CMP_Claim__c != null) {
                thirdpartyClaim = thirdParty.CSX_CMP_Equipment__r.CSX_CMP_Claim__c;
            }
        }
        
        Blob pdfBase64Content = CSX_CMP_InterfaceUtility.fetchinvoicePDFFromSAP(invoiceNumber);
        
        if(pdfBase64Content != null){
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Invoice ' + invoiceNumber;
            contentVersion.PathOnClient = 'Invoice_' + invoiceNumber + '.pdf';
            contentVersion.VersionData = pdfBase64Content;
            contentVersion.FirstPublishLocationId = thirdpartyClaim;
            contentVersions.add(contentVersion);
        }
        if (!contentVersions.isEmpty()) {
            try {
                Database.SaveResult[] insertContentVersion = Database.Insert(contentVersions,false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'CSX_CMP_ARSettlementTriggerHandler',
                    'getInvoicePDFContent',
                    insertContentVersion,
                    'ContentVersion'
                );
                List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
                Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions WITH SECURITY_ENFORCED LIMIT 1]);

                if (contentVersionMap != null) {
                    Set<Id> contentDocumentIds = new Set<Id>();
                    for (ContentVersion contentVersion : contentVersions) {
                        contentDocumentIds.add(contentVersionMap.get(contentVersion.Id).ContentDocumentId);
                    }
    
                    Map<Id, List<ContentDocumentLink>> existingLinksMap = new Map<Id, List<ContentDocumentLink>>();
                    for (ContentDocumentLink contentDocLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds WITH SECURITY_ENFORCED]) {
                        if (!existingLinksMap.containsKey(contentDocLink.ContentDocumentId)) {
                            existingLinksMap.put(contentDocLink.ContentDocumentId, new List<ContentDocumentLink>());
                        }
                        existingLinksMap.get(contentDocLink.ContentDocumentId).add(contentDocLink);
                    }
    
                    for (ContentVersion contentVersion : contentVersions) {
                        Boolean linkExists = false;
                        Id contentDocumentId = contentVersionMap.get(contentVersion.Id).ContentDocumentId;
                        if(existingLinksMap.containsKey(contentDocumentId)) {
                            for (ContentDocumentLink existingLink : existingLinksMap.get(contentDocumentId)) {
                                if(existingLink.LinkedEntityId == contentVersion.FirstPublishLocationId) {
                                    linkExists = true;
                                    break;
                                }
                            }
                        }
                        if(!linkExists) {
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = contentDocumentId;
                            cdl.LinkedEntityId = contentVersion.FirstPublishLocationId;
                            cdl.ShareType = 'V'; // Viewer permission
                            contentDocumentLinks.add(cdl);
                        }
                    }
                }
        
                if (!contentDocumentLinks.isEmpty()) {
                    Database.SaveResult[] insertContentDocLink = Database.Insert(contentDocumentLinks, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_ARSettlementTriggerHandler',
                        'getInvoicePDFContent',
                        insertContentDocLink,
                        'ContentVersion'
                    );
                }

                if (!emailAddresses.isEmpty()) {
                    CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
                    emailWrap.sourceRecordId = arSettlementId;
                    emailWrap.toEmailIdList = emailAddresses;
                    emailWrap.templateDeveloperName = 'CSX_CMP_Auto_Contract_Invoice_Template';
                    emailWrap.ccEmailIdList = ccEmailList;
                    Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap);

                    //Add attachment
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('Invoice_Report.pdf');
                    attachment.setBody(pdfBase64Content);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                    List<Messaging.SendEmailResult> lstSendEmailResult = new List<Messaging.SendEmailResult>();
                    lstSendEmailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    if(!lstSendEmailResult.isEmpty()){
                        CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_ARSettlementTriggerHandler', 'getInvoicePDFContent', lstSendEmailResult);
                    }
                }
			} catch (Exception e) {
                CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ARSettlementTriggerHandler', 'getInvoicePDFContent', invoiceNumber, e);
            }
        }
    }
}