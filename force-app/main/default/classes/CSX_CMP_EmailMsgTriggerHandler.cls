/*
@author       - Infosys
@name         - CSX_CMP_EmailMsgTriggerHandler
@createdDate  - 06/04/2024
@description  - Apex trigger handler on EmailMessage object used to create record on staging 'CSX_CMP_Document_Ref__c' obj.
*/
public with sharing class CSX_CMP_EmailMsgTriggerHandler {
	public static void handleAfterInsert(List<EmailMessage> emailMsgList) {
		List<CSX_CMP_Document_Ref__c> documentsToCreate = new List<CSX_CMP_Document_Ref__c>();
		set<Id> contentDocIds = new Set<id>();
		Id docRecTypeId = Schema.SObjectType.CSX_CMP_Document_Ref__c.getRecordTypeInfosByName()
			.get('ServiceCloud_Claims')
			.getRecordTypeId();
		try {
			for (EmailMessage emailMsg : emailMsgList) {
				if (emailMsg.ParentId != null) {
					Schema.sObjectType entityType = emailMsg.ParentId.getSObjectType();
					if (entityType == Case.sObjectType || entityType == CSX_CMP_LD_Report__c.sObjectType) {
						CSX_CMP_Document_Ref__c doc = new CSX_CMP_Document_Ref__c();
						doc.RecordTypeId = docRecTypeId;
						doc.CSX_CMP_File_Name__c = emailMsg.Subject;
						doc.CSX_CMP_Document_Type__c = getDocumentType(emailMsg.Subject);
						doc.CSX_CMP_File_Extension__c = 'pdf';
						doc.CSX_CMP_Email_Message_Id__c = emailMsg.Id;
						if (entityType == Case.sObjectType) {
							doc.CSX_CMP_Claim__c = emailMsg.ParentId;
						}
						documentsToCreate.add(doc);
					}
				}
			}
			//insert CSX_CMP_Document_Ref__c
			if (!documentsToCreate.isEmpty()) {
				Database.SaveResult[] docRef = Database.Insert(documentsToCreate, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_EmailMsgTriggerHandler',
					'handleAfterInsert',
					docRef,
					'CSX_CMP_Document_Ref__c'
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_EmailMsgTriggerHandler',
				'handleAfterInsert',
				JSON.serialize(emailMsgList),
				ex
			);
		}
	}

	public static String getDocumentType(String emailSubject) {
		String documentType;
		if (emailSubject.contains('Claim Confirmation')) {
			documentType = 'Claim Confirmation Email';
		} else if (emailSubject.contains('Foreign Line Request')) {
			documentType = 'FLR Email';
		} else if (emailSubject.contains('Decline Letter')) {
			documentType = 'Decline Email';
		} else {
			documentType = 'User Email';
		}
		return documentType;
	}
}