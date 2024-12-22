/*
@author       - Infosys
@name         - CSX_CMP_ContentDocLinkTriggerHandler
@createdDate  - 06/04/2024
@description  - Apex trigger handler on ContentDocumentLink object used to create record on staging 'CSX_CMP_Document_Ref__c' obj.
*/
public with sharing class CSX_CMP_ContentDocLinkTriggerHandler {
	public static void handleAfterInsert(List<ContentDocumentLink> cdlList) {
		try {
			List<CSX_CMP_Document_Ref__c> documentsToCreate = new List<CSX_CMP_Document_Ref__c>();
			List<CSX_CMP_Document_Ref__c> documentsToUpdate = new List<CSX_CMP_Document_Ref__c>();
			set<Id> contentDocIds = new Set<Id>();
			Map<String, ContentDocument> cdIdtoRecordMap = new Map<String, ContentDocument>();
			Map<String, ContentVersion> cdIdtoContentVersionMap = new Map<String, ContentVersion>();
			Map<String, CSX_CMP_Document_Ref__c> emailMsgIdToDocRefMap = new Map<String, CSX_CMP_Document_Ref__c>();
			set<String> setOfString = new set<String>(); 

			for (ContentDocumentLink cdlink : cdlList) {
				contentDocIds.add(cdlink.ContentDocumentId);
			}
			if (!contentDocIds.isEmpty()) {
				List<ContentDocument> contentDoumentList = [
					SELECT Id, Title, Description, FileExtension, LatestPublishedVersionId
					FROM ContentDocument
					WHERE id IN :contentDocIds
                    WITH SECURITY_ENFORCED 
				];

				for (ContentDocument cd : contentDoumentList) {
					cdIdtoRecordMap.put(cd.id, cd);
				}

				List<ContentVersion> contentVersionList = [
					SELECT Id, ContentDocumentId, CSX_CMP_Email_Message_Id__c, 
					CSX_CMP_Internal_Only__c, CSX_CMP_UploadToECM__c, CSX_CMP_Comments__c, CSX_CMP_isReUpload__c
					FROM ContentVersion
					WHERE ContentDocumentId IN :contentDocIds AND IsMajorVersion = TRUE
                    WITH SECURITY_ENFORCED
				];

				for (ContentVersion cv : contentVersionList) {
					if (cv.CSX_CMP_Email_Message_Id__c != null) {
						setOfString.add(cv.CSX_CMP_Email_Message_Id__c);
					}
					cdIdtoContentVersionMap.put(cv.ContentDocumentId, cv);
				}
				
				if (!cdIdtoContentVersionMap.isEmpty()) {
					List<CSX_CMP_Document_Ref__c> documentRefList = [
						SELECT id, CSX_CMP_Email_Message_Id__c
						FROM CSX_CMP_Document_Ref__c
						WHERE CSX_CMP_Email_Message_Id__c IN :setOfString
                        WITH SECURITY_ENFORCED
					];

					if (!documentRefList.isEmpty()) {
						for (CSX_CMP_Document_Ref__c docRef : documentRefList) {
							emailMsgIdToDocRefMap.put(docRef.CSX_CMP_Email_Message_Id__c, docRef);
						}
					}
				}
				Id docRefRecId = Schema.SObjectType.CSX_CMP_Document_Ref__c.getRecordTypeInfosByName()
					.get('ServiceCloud_Claims')
					.getRecordTypeId();

				for (ContentDocumentLink cdl : cdlList) {
					Schema.sObjectType entityType = cdl.LinkedEntityId.getSObjectType();
					if (
						entityType == Case.sObjectType ||
						entityType == CSX_CMP_Property_Portal_Staging__c.sObjectType ||
						entityType == CSX_CMP_LD_Report__c.sObjectType
					) {
						ContentDocument contentDoc = cdIdtoRecordMap.get(cdl.ContentDocumentId);
						Boolean createDocref = false;
						if (cdIdtoContentVersionMap.containsKey(cdl.ContentDocumentId)) {
							String emailMsgId = cdIdtoContentVersionMap.get(cdl.ContentDocumentId).CSX_CMP_Email_Message_Id__c;
							boolean isReupload = cdIdtoContentVersionMap.get(cdl.ContentDocumentId).CSX_CMP_isReUpload__c;
							if (emailMsgIdToDocRefMap.containsKey(emailMsgId)) {
								CSX_CMP_Document_Ref__c doc = emailMsgIdToDocRefMap.get(emailMsgId);
								doc.CSX_CMP_Content_Document_ID__c = contentDoc.Id;
								doc.CSX_CMP_ContentVersionID__c = contentDoc.LatestPublishedVersionId;
								documentsToUpdate.add(doc);
							} else if(isReupload){
								createDocref = false;
							} else {
								createDocref = true;
							}
						} else {
							createDocref = true;
						}

						if (createDocref) {
							CSX_CMP_Document_Ref__c doc = new CSX_CMP_Document_Ref__c();
							doc.CSX_CMP_Internal_Only__c = cdIdtoContentVersionMap.get(contentDoc.id).CSX_CMP_Internal_Only__c;
							doc.CSX_CMP_UploadToECM__c = cdIdtoContentVersionMap.get(contentDoc.id).CSX_CMP_UploadToECM__c;
							doc.CSX_CMP_File_Description__c = cdIdtoContentVersionMap.get(contentDoc.id).CSX_CMP_Comments__c;
							doc.RecordTypeId = docRefRecId;
							doc.CSX_CMP_File_Name__c = contentDoc.Title;
							doc.CSX_CMP_File_Extension__c = contentDoc.FileExtension;
							doc.CSX_CMP_Content_Document_ID__c = contentDoc.Id;
							doc.CSX_CMP_ContentVersionID__c = contentDoc.LatestPublishedVersionId;
							doc.CSX_CMP_Document_Type__c = getDocumentType(contentDoc.Title);
							if (entityType == Case.sObjectType) {
								doc.CSX_CMP_Claim__c = cdl.LinkedEntityId;
                            } else if(entityType == CSX_CMP_Property_Portal_Staging__c.sObjectType){
                                doc.CSX_CMP_Property_Portal_Staging__c = cdl.LinkedEntityId;
                            } else if(entityType == CSX_CMP_LD_Report__c.sObjectType){
                                 doc.CSX_CMP_LD_Report__c = cdl.LinkedEntityId;
                            }
							documentsToCreate.add(doc);
						}
					}
				}
			}
			//insert CSX_CMP_Document_Ref__c
			if (!documentsToCreate.isEmpty()) {
				Database.SaveResult[] docRef = Database.Insert(documentsToCreate, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ContentDocLinkTriggerHandler',
					'handleAfterInsert',
					docRef,
					'CSX_CMP_Document_Ref__c'
				);
			}

			//update CSX_CMP_Document_Ref__c
			if (!documentsToUpdate.isEmpty()) {
				Database.SaveResult[] docRef = Database.Update(documentsToUpdate, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ContentDocLinkTriggerHandler',
					'handleAfterInsert',
					docRef,
					'CSX_CMP_Document_Ref__c'
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ContentDocLinkTriggerHandler',
				'handleAfterInsert',
				JSON.serialize(cdlList),
				ex
			);
		}
	}

	public static String getDocumentType(String documentTitle) {
		String documentType;
		if (documentTitle.contains('RechargeLetter')) {
			documentType = 'Recharge Letter';
		} else if (documentTitle.contains('ClaimSummary')) {
			documentType = 'Claim Summary';
		} else if (documentTitle.contains('DISTRIBUTION_STATEMENT')) {
			documentType = 'Distribution statement';
		} else if (documentTitle.contains('ABSTRACT_STATEMENT')) {
			documentType = 'Abstract statement';
		} else if (documentTitle.contains('Decline')) {
			documentType = 'Decline Letter';
		} else if (documentTitle.contains('LOA letter')) {
			//placeholder for LOA letter,need to change later
			documentType = 'LOA letter';
		} else if (documentTitle.contains('Waybill')) {
			documentType = 'Waybill Image';
		} else {
			documentType = 'User Document';
		}
		return documentType;
	}
}