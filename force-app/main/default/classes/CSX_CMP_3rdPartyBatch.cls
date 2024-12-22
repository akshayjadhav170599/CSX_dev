public with sharing class CSX_CMP_3rdPartyBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	Blob pdfBase64Content;
	string arInvoiceNumber;
	List<String> emailAddresses = new List<String>();
	public CSX_CMP_3rdPartyBatch(string invoiceNumber) {
		this.arInvoiceNumber = invoiceNumber;
		//this.pdfBase64Content = CSX_CMP_InterfaceUtility.fetchInvoicePDF(invoiceNumber);
	}
	public Database.QueryLocator start(Database.BatchableContext context) {
		string query =
			'select Id,CSX_CMP_Invoice_Num__c,CSX_CMP_Claim_Link__c,CSX_CMP_Equipment__r.CSX_CMP_Claim__c,CSX_CMP_Contact_Email__c  from CSX_CMP_3rd_Party__c  where CSX_CMP_Invoice_Num__c = \'' +
			arInvoiceNumber +
			'\'';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext context, List<CSX_CMP_3rd_Party__c> thirdPartyList) {
		List<ContentVersion> contentVersions = new List<ContentVersion>();
		for (CSX_CMP_3rd_Party__c thirdParty : thirdPartyList) {
			try {
				if (thirdParty.CSX_CMP_Contact_Email__c != null) {
					emailAddresses.addAll(thirdParty.CSX_CMP_Contact_Email__c.split(';'));
				}

				ContentVersion contentVersion = new ContentVersion();
				contentVersion.Title = 'Invoice ' + thirdParty.CSX_CMP_Invoice_Num__c;
				contentVersion.PathOnClient = 'Invoice_' + thirdParty.CSX_CMP_Invoice_Num__c + '.pdf';
				contentVersion.VersionData = pdfBase64Content;
				contentVersion.FirstPublishLocationId = thirdParty.CSX_CMP_Equipment__r.CSX_CMP_Claim__c;
				contentVersions.add(contentVersion);
			} catch (Exception e) {
                CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_3rdPartyBatch','execute',JSON.serialize(arInvoiceNumber),e);

			}
		}

		if (!contentVersions.isEmpty()) {
			try {
				insert contentVersions;

				List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
				Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
					[SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]
				);
				for (ContentVersion cv : contentVersions) {
					ContentDocumentLink cdl = new ContentDocumentLink();
					cdl.ContentDocumentId = contentVersionMap.get(cv.Id).ContentDocumentId;
					cdl.LinkedEntityId = cv.FirstPublishLocationId;
					cdl.ShareType = 'V'; // Viewer permission
					contentDocumentLinks.add(cdl);
				}

				if (!contentDocumentLinks.isEmpty()) {
					insert contentDocumentLinks;
				}
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_3rdPartyBatch','execute',JSON.serialize(arInvoiceNumber),e);
			}
		}
	}
	public void finish(Database.BatchableContext context) {
		if (!emailAddresses.isEmpty()) {
			try {
				// Create email message using template
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				email.setToAddresses(emailAddresses);
				EmailTemplate emailTempalte = [
					SELECT id
					FROM EmailTemplate
					WHERE DeveloperName = 'CSX_CMP_Auto_Contract_Invoice_Template'
				];
				email.setTemplateId(emailTempalte.Id);
				email.setTargetObjectId(UserInfo.getUserId());
				email.setSaveAsActivity(false);

				// Add attachment
				Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
				attachment.setFileName('Invoice_Report.pdf');
				attachment.setBody(pdfBase64Content);
				email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });

				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_3rdPartyBatch','finish',JSON.serialize(arInvoiceNumber),e);
			}
		}
	}
}