/**************************************************************************************
Apex Class Name     : CSX_CMP_UploadEmailToECMBatch
Function            : Class for converting email to pdf and uploading to ECM.
RICEFW Id           : CMP-E-0442
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/13/2024       First version of this class.
*************************************************************************************/
public class CSX_CMP_UploadEmailToECMBatch implements Database.Batchable<sObject>, Database.Stateful {
	public List<EmailMessage> emailMessages;
	public List<Id> cvIds;
	public CSX_CMP_UploadEmailToECMBatch(List<EmailMessage> emailMsgs) {
		this.emailMessages = emailMsgs;
		cvIds = new List<Id>();
	}
	public Iterable<sObject> start(Database.BatchableContext context) {
		return emailMessages;
	}
	public void execute(Database.BatchableContext context, List<EmailMessage> emailMsgRecords) {
		List<ContentVersion> cvList = new List<ContentVersion>();
		List<Id> attachmentIds = new List<Id>();
		Map<String, String> emailMsgIdToParentId = new Map<String, String>();
		try {
			for (EmailMessage email : emailMsgRecords) {
				for (Attachment att : email.Attachments) {
					attachmentIds.add(att.Id);
				}
				emailMsgIdToParentId.put(email.Id, email.ParentId);
				ContentVersion cont = new ContentVersion();
				PageReference pdfPage = Page.CSX_CMP_EmailToPDF;
				pdfPage.getParameters().put('id', email.Id);
				Blob pdfBlob = pdfPage.getContentAsPDF();

				cont.Title = email.Subject;
				cont.PathOnClient = email.Subject + '.pdf';
				cont.VersionData = pdfBlob;
				cont.CSX_CMP_Email_Message_Id__c = email.Id;
				cont.CSX_CMP_Parent_Id__c = String.valueOf(email.ParentId);
				cont.Origin = 'H';
				cvlist.add(cont);
			}
			List<Attachment> attachmentList = [
				SELECT id, Name, body, ParentId
				FROM Attachment
				WHERE id IN :attachmentIds
			];
			if (attachmentList.size() > 0) {
				for (Attachment att : attachmentList) {
					ContentVersion cont = new ContentVersion();
					cont.Title = att.Name;
					cont.VersionData = att.body;
					cont.PathOnClient = att.Name;
					cont.CSX_CMP_Parent_Id__c = emailMsgIdToParentId.get(att.ParentId);
					cont.Origin = 'H';
					cvList.add(cont);
				}
			}

			Database.SaveResult[] contentVersionRecords = Database.Insert(cvlist, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_UploadEmailToECMBatch',
				'execute',
				contentVersionRecords,
				'ContentVersion'
			);
			for (Database.SaveResult sr : contentVersionRecords) {
				if (sr.isSuccess()) {
					cvIds.add(sr.getId());
				}
			}

			Database.SaveResult[] cdlRecords;
			List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
			List<ContentVersion> cvList1 = [
				SELECT id, ContentDocumentId, CSX_CMP_Parent_Id__c
				FROM ContentVersion
				WHERE id IN :cvIds
			];
			/*
			List<Id> cdIds = new List<id>();
			List<Id> linkedEntityIds = new List<id>();
			for (ContentVersion cv : cvList1) {
				cdIds.add(cv.ContentDocumentId);
				linkedEntityIds.add(cv.CSX_CMP_Parent_Id__c);
			}
			Map<Id, ContentDocumentLink> idtoCdlMap = new Map<ID, ContentDocumentLink>(
				[
					SELECT Id, ContentDocumentId, LinkedEntityId
					FROM ContentDocumentLink
					WHERE ContentDocumentId IN :cdIds AND LinkedEntityId IN :linkedEntityIds AND shareType = 'V'
				]
			);
			Map<String, String> cdToLinkedEntityMap = new Map<String, String>();
			for (ContentDocumentLink cdlink : idtoCdlMap.values()) {
				cdToLinkedEntityMap.put(cdlink.ContentDocumentId, cdlink.LinkedEntityId);
			}
			*/
			if (!cvList1.isEmpty()) {
				for (ContentVersion cv : cvList1) {
					ContentDocumentLink cd1 = new ContentDocumentLink();
					cd1.ContentDocumentId = cv.ContentDocumentId;
					cd1.LinkedEntityId = cv.CSX_CMP_Parent_Id__c;
					cd1.ShareType = 'V';
					cdList.add(cd1);
				}
				cdlRecords = Database.Insert(cdList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_UploadEmailToECMBatch',
					'execute',
					cdlRecords,
					'ContentDocumentLink'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_UploadEmailToECMBatch',
				'execute',
				JSON.serialize(emailMsgRecords),
				e
			);
		}
	}
	public void finish(Database.BatchableContext context) {
		CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, true, 'Claim',false);
		Database.executeBatch(uploadBatch, 1);
	}
}