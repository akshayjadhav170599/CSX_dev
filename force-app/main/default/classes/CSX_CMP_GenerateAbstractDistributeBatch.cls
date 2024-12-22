/**
@Author       - Infosys  
@Name         - CSX_CMP_GenerateAbstarctDistributeBatch
@Created Date - 04/08/2023
@Description  - This batch Apex is used to generate the abstract and distribution documents for claims
@RICEFW reference - CMP-E-0441
*/
public class CSX_CMP_GenerateAbstractDistributeBatch implements Database.Batchable<sObject>, Database.Stateful {

	//Variables
	public string strRecordType;
	public string strServicePeriod;
	public string strRunFor;
	public boolean isManualProcess;
	public Map<String, Blob> mapOfExternalIDWithAbstract = new Map<String, Blob>();
	public list<CSX_CMP_Property_Portal_Staging__c> lstPropertyPortal = new List<CSX_CMP_Property_Portal_Staging__c>();
	public map<String, String> mapOfExternalIdWithID = new Map<String, String>();
	public List<ContentVersion> lstContentVersion = new List<ContentVersion>();

	public CSX_CMP_GenerateAbstractDistributeBatch(List<Id> lstPortalids ){

		lstPropertyPortal = [SELECT Id, CSX_CMP_External_ID__c,CSX_CMP_Document_Name__c,CSX_CMP_Record_Type__c,
								CSX_CMP_Run_For__c,CSX_CMP_Manual_Process__c,CSX_CMP_Service_Period__c,CSX_CMP_Document_Type__c 
								FROM CSX_CMP_Property_Portal_Staging__c
								WHERE  Id IN : lstPortalids];
		
		if(lstPropertyPortal != null && lstPropertyPortal.size() > 0){
			strRecordType = lstPropertyPortal[0].CSX_CMP_Record_Type__c;
			strServicePeriod = lstPropertyPortal[0].CSX_CMP_Service_Period__c;
			strRunFor = lstPropertyPortal[0].CSX_CMP_Run_For__c;
			isManualProcess = lstPropertyPortal[0].CSX_CMP_Manual_Process__c;
		}
	}

	public Iterable<sObject> start(Database.BatchableContext context) {
		return lstPropertyPortal;
	}

	public void execute(
		Database.BatchableContext context,
		List<CSX_CMP_Property_Portal_Staging__c> lstPropertyPortalStage
	) {
		try {
			if (lstPropertyPortalStage != null && lstPropertyPortalStage.size() > 0) {
				
				Map<String, String> contentDocLinkMap = new Map<String, String>();
				List<ContentVersion> lstContentVersionList = new List<ContentVersion>();
				List<Id> lstContentVersionId = new List<Id>();
				List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();

				//store all the external id in set
				for (CSX_CMP_Property_Portal_Staging__c objPropertyPortal : lstPropertyPortalStage) {
					mapOfExternalIdWithID.put(objPropertyPortal.CSX_CMP_External_ID__c, objPropertyPortal.id);
				}

				//get the content document link of the exisitng property portal record
				List<ContentDocumentLink> contentDocLinks = [
					SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :mapOfExternalIdWithID.values()
				];

				if (!contentDocLinks.isEmpty()) {
					for (ContentDocumentLink contentDoc : contentDocLinks) {
						contentDocLinkMap.put(contentDoc.LinkedEntityId, contentDoc.ContentDocumentId);
					}
				}

				//Loop on property portaL staging records
				for (CSX_CMP_Property_Portal_Staging__c objPropertyPortal : lstPropertyPortalStage) {
					blob objBlob;
					if (strRecordType == 'Freight' && strRunFor == 'Class 1' && isManualProcess == false 
						&& objPropertyPortal.CSX_CMP_Document_Type__c == 'Distribution') {
						//Distribution
						objBlob = new PageReference(
								Site.getBaseUrl() +
								'/apex/CSX_CMP_DistributionPDFReport?PPId=' +
								objPropertyPortal.Id
							)
							.getContent();							
					} else {
						//Abstract
						if (
							(strRecordType == 'Freight' && strRunFor != 'Class 1') ||
							strRecordType == 'Freight' && strRunFor == 'Class 1' && isManualProcess == true
						) {
							objBlob = new PageReference(
									Site.getBaseUrl() +
									'/apex/CSX_CMP_AbstractDistributionPDF?PPId=' +
									objPropertyPortal.Id
								)
								.getContent();
						} else if (strRecordType == 'Freight' && strRunFor == 'Class 1') {
							objBlob = new PageReference(
									Site.getBaseUrl() +
									'/apex/CSX_CMP_AbstractPDFReport?PPId=' +
									objPropertyPortal.Id
								)
								.getContent();
						} else {
							objBlob = new PageReference(
									Site.getBaseUrl() +
									'/apex/CSX_CMP_AbstractPDFReport?PPId=' +
									objPropertyPortal.Id
								)
								.getContent();
						}
						mapOfExternalIDWithAbstract.put(objPropertyPortal.CSX_CMP_External_ID__c, objBlob);
					}

					if (!system.Test.isRunningTest()) {
						ContentVersion cont = new ContentVersion();
						cont.Title = objPropertyPortal.CSX_CMP_Document_Name__c.replace('.PDF', '');
						cont.PathOnClient = objPropertyPortal.CSX_CMP_Document_Name__c;
						cont.VersionData = objBlob;
						if (contentDocLinkMap.containsKey(objPropertyPortal.Id)) {
							cont.ContentDocumentId = contentDocLinkMap.get(objPropertyPortal.Id);
						}
						lstContentVersionList.add(cont);
					}
				}

				//Insert the ContentVersion List
				Database.SaveResult[] contentVersionResult = Database.Insert(lstContentVersionList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_GenerateAbstarctDistributeBatch',
					'Execute',
					contentVersionResult,
					'ContentVersion'
				);

				lstContentVersion.addAll(lstContentVersionList);

				for (Database.SaveResult sr : contentVersionResult) {
					if (sr.isSuccess()) {
						lstContentVersionId.add(sr.getId());
					}
				}

				if (lstContentVersionId.size() > 0) {
					List<ContentVersion> contentVersionList = [
						SELECT Id, ContentDocumentId, Title
						FROM ContentVersion
						WHERE Id IN :lstContentVersionId
					];
					Map<String, Id> mapOfTitletoContentDocId = new Map<String, Id>();
					Map<String, Id> mapOfLinkedEntityIdWithDocId = new Map<String, Id>();

					for (ContentVersion objContenVersion : contentVersionList) {
						mapOfTitletoContentDocId.put(objContenVersion.Title, objContenVersion.ContentDocumentId);
					}

					list<ContentDocumentLink> lstContentDocLink = [
						SELECT Id, LinkedEntityId, ContentDocumentId
						FROM ContentDocumentLink
						WHERE
							ContentDocumentId IN :mapOfTitletoContentDocId.values()
							AND LinkedEntityId IN :mapOfExternalIdWithID.values()
					];

					for (ContentDocumentLink objContentDoc : lstContentDocLink) {
						mapOfLinkedEntityIdWithDocId.put(objContentDoc.LinkedEntityId, objContentDoc.ContentDocumentId);
					}

					for (CSX_CMP_Property_Portal_Staging__c objPortal : lstPropertyPortalStage) {
						if (
							mapOfLinkedEntityIdWithDocId != null &&
							!mapOfLinkedEntityIdWithDocId.containsKey(objPortal.id)
						) {
							Id docId = mapOfTitletoContentDocId.get(
								objPortal.CSX_CMP_Document_Name__c.replace('.PDF', '')
							);
							ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
							objContentDocumentLink.ContentDocumentId = docId;
							objContentDocumentLink.LinkedEntityId = objPortal.Id;
							objContentDocumentLink.ShareType = 'V';
							lstContentDocumentLink.add(objContentDocumentLink);
						}
					}

					if (lstContentDocumentLink.size() > 0) {
						Database.SaveResult[] contentDocumentResult = Database.Insert(lstContentDocumentLink, false);
						CSX_CMP_LoggerUtility.addApexDMLErrorLog(
							'CSX_CMP_GenerateAbstarctDistributeBatch',
							'execute',
							contentDocumentResult,
							'ContentDocumentLink'
						);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_GenerateAbstarctDistributeBatch',
				'execute',
				String.valueOf(lstPropertyPortal),
				ex
			);
		}
	}

	public void finish(Database.BatchableContext context) 
	{
		try 
		{
			List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
			List<OrgWideEmailAddress> lstOrgwideEmail = [
				SELECT Id, Address, DisplayName
				FROM OrgWideEmailAddress
				WHERE DisplayName = :System.Label.CSX_CMP_CSX_Support
			];

			List<String> contactEmailList = new List<String>();

			//Below method needs to uncomment while actual process
			if(strRecordType == 'Freight'){
                if(!string.isempty(system.Label.CSX_CMP_FLDX_Emails)){
					list<String> lstEmails = new list<String>();
					if(system.Label.CSX_CMP_FLDX_Emails.contains(',')){
						lstEmails = system.Label.CSX_CMP_FLDX_Emails.split(',');
					}else{
						lstEmails.add(system.Label.CSX_CMP_FLDX_Emails);
					}
					contactEmailList.addAll(lstEmails);
                }
			}else{
				if(!string.isempty(system.Label.CSX_CMP_Abstract_Distribution_Email)){
					list<String> lstEmails = new list<String>();
					if(system.Label.CSX_CMP_Abstract_Distribution_Email.contains(',')){
						lstEmails = system.Label.CSX_CMP_Abstract_Distribution_Email.split(',');
					}else{
						lstEmails.add(system.Label.CSX_CMP_Abstract_Distribution_Email);
					}
					contactEmailList.addAll(lstEmails);
				}
			}
			
			/*else{
					contactEmailList.add(UserInfo.getUserEmail());
				}*/
			

			if (strRecordType == 'Freight' && strRunFor == 'Class 1' && !isManualProcess) {
				Messaging.SingleEmailMessage emailMesgObject = new Messaging.SingleEmailMessage();
				emailMesgObject.toAddresses = contactEmailList;
				emailMesgObject.subject = 'Abstract and Distribution Statement Generated';
				emailMesgObject.htmlBody =
					'<H> Hi ' +
					// UserInfo.getFirstName() +
					// ' ' +
					// UserInfo.getLastName() +
					'</H></BR></BR> Abstract and Distribution statements generated for all the eligible claims based on your selected filters. Please check the generated abstract and distribution statements in Property Portal Details tab.</BR></BR>';
				emailMesgObject.htmlBody += 'Below are the parameters on which abstract and distribution statements are generated.</BR></BR>';
				emailMesgObject.htmlBody +=
					'<B>Claim Type:</B> ' +
					strRecordType +
					' and <B>Period:</B> ' +
					strServicePeriod +
					' and <B>Runfor:</B> ' +
					strRunFor;
				emailMesgObject.setOrgWideEmailAddressId(lstOrgwideEmail[0].Id);
				emailList.add(emailMesgObject);
			} else {
				//system.debug('mapOfExternalIDWithAbstract??' + mapOfExternalIDWithAbstract);
				//send 1 email for each RR with abstract attachment
				for (string strExtId : mapOfExternalIDWithAbstract.keySet()) {
					Messaging.SingleEmailMessage emailMesgObject = new Messaging.SingleEmailMessage();
					emailMesgObject.toAddresses = contactEmailList;
					String fullRecordURL =
						URL.getOrgDomainURL().toExternalForm() +
						'/' +
						mapOfExternalIdWithID.get(strExtId);

					if (strRecordType == 'Freight') {
						emailMesgObject.subject = 'Abstract and Distribution Statement Generated';
						emailMesgObject.htmlBody =
							'<H> Dear ' +
							UserInfo.getFirstName() +
							' ' +
							UserInfo.getLastName() +
							'</H></BR></BR> Abstract and Distribution statements generated for all the eligible claims based on your selected filters. Please check the attached abstract and distribution statements.</BR></BR>';
						emailMesgObject.htmlBody += 'Below are the parameters on which abstract and distribution statements are generated.</BR></BR>';
						emailMesgObject.htmlBody +=
							'<B>Claim Type:</B> ' +
							strRecordType +
							' and <B>Period:</B> ' +
							strServicePeriod +
							' and <B>Runfor:</B> ' +
							strRunFor +
							'</BR>';
					} else {
						emailMesgObject.subject = 'Abstract Statement Generated';
						emailMesgObject.htmlBody =
							'<H> Dear ' +
							UserInfo.getFirstName() +
							' ' +
							UserInfo.getLastName() +
							'</H></BR></BR> Abstract statement generated for all the eligible claims based on your selected filters. Please check the attached abstract statements.</BR></BR>';
						emailMesgObject.htmlBody += 'Below are the parameters on which abstract statements are generated.</BR></BR>';
						emailMesgObject.htmlBody +=
							'<B>Claim Type:</B> ' +
							strRecordType +
							' and <B>Period:</B> ' +
							strServicePeriod +
							' and <B>Runfor:</B> ' +
							strRunFor;
					}

					emailMesgObject.htmlBody +=
						'</BR>' +
						'<a href = ' +
						fullRecordURL +
						'>Click here to navigate to property portal staging record.</a>';

					emailMesgObject.setOrgWideEmailAddressId(lstOrgwideEmail[0].Id);
					Messaging.Emailfileattachment objMessagingFile = new Messaging.Emailfileattachment();
					objMessagingFile.setBody(mapOfExternalIDWithAbstract.get(strExtId));
					objMessagingFile.setFileName(strExtId + '.pdf');
					emailMesgObject.setFileAttachments(new List<Messaging.EmailFileAttachment>{ objMessagingFile });
					emailList.add(emailMesgObject);
				}
			}

			if(emailList.size() > 0){
				Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList,false);
				CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_GenerateAbstarctDistributeBatch','sendAbstract&DistributionPDFClaim',results);
			}
			
			CSX_CMP_LoggerUtility.addExecutionLog(
				'CSX_CMP_GenerateAbstarctDistributeBatch',
				'Abstract and Distribution PDF Generation for Claim Type' +
				strRecordType +
				' And Period-' +
				strServicePeriod +
				' And Runfor -' +
				strRunFor,
				'CSX_CMP_Property_Portal_Staging__c',
				lstPropertyPortal.size()
			);

			//statement upload to ECM
			if (strRecordType == 'Freight' && strRunFor == 'Class 1' && !isManualProcess) {
				List<Id> contentVersionIds = new List<Id>();
				if (!lstContentVersion.isEmpty()) {
					for (ContentVersion cv : lstContentVersion) {
						contentVersionIds.add(cv.Id);
					}
					CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(
						contentVersionIds,
						false,
						'Property Portal',
                        false
					);
					Database.executeBatch(uploadBatch, 1);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_GenerateAbstarctDistributeBatch',
				'Finish',
				String.valueOf(lstPropertyPortal),
				ex
			);
		}
	}			
}