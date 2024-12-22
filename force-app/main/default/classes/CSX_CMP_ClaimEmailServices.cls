/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimEmailServices
Function            : Class to attach new email to respective parent claim.
RICEFW #            : CMP-I-0789
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           01/10/2024       First version of this class.
*************************************************************************************/
public without sharing class CSX_CMP_ClaimEmailServices implements Messaging.InboundEmailHandler {
	/*
        @description : method to attch new email to related claim
        @param : Messaging.InboundEmail email, Messaging.InboundEnvelope envelope
        @return : Messaging.InboundEmailResult
    */
	public Messaging.InboundEmailResult handleInboundEmail(
		Messaging.InboundEmail email,
		Messaging.InboundEnvelope envelope
	) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		try {
			EmailMessage newEmailMessage = new EmailMessage();
			String toAddresses;
			if (email.toAddresses != null) {
				toAddresses = String.join(email.toAddresses, '; ');
			}

			newEmailMessage.Incoming = true; // [CMP-E-879]
			Id caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
			// If we haven't found the Case ID, try finding it using headers.
			if (caseId == null) {
				caseId = Cases.getCaseIdFromEmailHeaders(email.headers);
			}
			newEmailMessage.ToAddress = toAddresses;
			newEmailMessage.HtmlBody = email.htmlBody;
			newEmailMessage.Subject = email.subject;
			newEmailMessage.TextBody = email.plainTextBody;
			newEmailMessage.FromAddress = email.fromAddress;
			newEmailMessage.FromName = email.fromName;
			newEmailMessage.ParentId = caseId;


			List<OrgWideEmailAddress> orgWideEmailAddressList = [Select Id,Address from OrgWideEmailAddress WITH SECURITY_ENFORCED]; 
			Map<string,Object> mapOrgAddress = new Map<string,object>();
			for(OrgWideEmailAddress objEmailAddress : orgWideEmailAddressList){
				mapOrgAddress.put(objEmailAddress.Address,objEmailAddress);
			}
			Boolean isOrgAddress = false;
			if(mapOrgAddress.containsKey(email.fromAddress)){
				isOrgAddress = true;
			}
			Id emailMessageId;
			/*string emailSubject = newEmailMessage.Subject.replace('RE:', '');
			emailSubject = emailSubject.replace('Sandbox:', '');
			if (emailSubject.startsWith(' ')) {
				emailSubject = emailSubject.substring(1);
			}
			system.debug('email subject ::'+emailSubject);*/
			string subjectValue = '%'+newEmailMessage.Subject;
			List<EmailMessage> newEmailMessageList = new List<EmailMessage>();
			newEmailMessageList = [
									SELECT Id, ParentId, Subject, CreatedDate,Incoming 
									FROM EmailMessage 
									WHERE ParentId != null AND ParentId = :caseId 
									AND Subject LIKE :subjectValue WITH SECURITY_ENFORCED
									ORDER BY CreatedDate DESC ];
			Boolean isFounds = false;
				
			if(!newEmailMessageList.isEmpty()){	
				for(EmailMessage objEmailMsg : newEmailMessageList){
					//DateTime objDateTime = newEmailMessage.CreatedDate != null ? newEmailMessage.CreatedDate : system.now();
					if(newEmailMessage.CreatedDate != null){
						Long timeDifference = objEmailMsg.CreatedDate.getTime() - newEmailMessage.CreatedDate.getTime();
						if (timeDifference < 60000) {
							isFounds = true;
						}
					}
				}
			}
			
			List<User> usersList = [Select id,CSX_CMP_User_License__c,  Email FROM User WHERE CSX_CMP_User_License__c = 'Salesforce' AND Email != null WITH SECURITY_ENFORCED];
			String emailToCheck = newEmailMessage.FromAddress;
			Boolean isUserEmail = false;
			
			for (User user : usersList) {
				if (user.Email == emailToCheck) {
					isUserEmail = true;
					break;
				}
			}
			//if (newEmailMessage.Incoming == true) {
			if(!mapOrgAddress.containsKey(newEmailMessage.FromAddress) && isFounds){
				Database.SaveResult saveResult;
				saveResult = Database.insert(newEmailMessage, false);
				emailMessageId = saveResult.getId();
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimEmailServices',
					'Claim Email Service',
					saveResult,
					'EmailMessage'
				);
			}else if(newEmailMessageList.isEmpty() && !isFounds && (newEmailMessage.Subject.contains('Re:') || newEmailMessage.Subject.contains('RE:')) && !isOrgAddress && (!isUserEmail || newEmailMessage.Incoming)){//
				Database.SaveResult saveResult;
				saveResult = Database.insert(newEmailMessage, false);
				emailMessageId = saveResult.getId();
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimEmailServices',
					'Claim Email Service',
					saveResult,
					'EmailMessage'
				);
			}
			/*else if(!newEmailMessageList.isEmpty() && !isFounds){
				Database.SaveResult saveResult;
				saveResult = Database.insert(newEmailMessage, false);
				emailMessageId = saveResult.getId();
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimEmailServices',
					'Claim Email Service',
					saveResult,
					'EmailMessage'
				);
			}*/
			//}

			list<attachment> attachmentlist = new List<attachment>();
			if (email.textAttachments != null) {
				for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) {
					Attachment attachment = new Attachment();
					attachment.Name = tAttachment.fileName;
					attachment.Body = Blob.valueOf(tAttachment.body);
					attachment.ParentId = emailMessageId;
					attachmentlist.add(attachment);
				}
				if (!attachmentlist.isEmpty()) {
					Database.SaveResult[] insertattchmentlists = Database.insert(attachmentlist);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_ClaimEmailServices',
						'Claim Email Service',
						insertattchmentlists,
						'EmailMessage'
					);
				}
			}
			if (email.binaryAttachments != null && emailMessageId !=null) {
				for (Messaging.InboundEmail.BinaryAttachment bAttachment : email.binaryAttachments) {
					Attachment attachment = new Attachment();
					attachment.Name = bAttachment.fileName;
					attachment.Body = bAttachment.body;
					attachment.ParentId = emailMessageId;
					attachmentlist.add(attachment);
				}
				if (!attachmentlist.isEmpty()) {
					Database.SaveResult[] insertattchmentlist = Database.insert(attachmentlist);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_ClaimEmailServices',
						'Claim Email Service',
						insertattchmentlist,
						'Case'
					);
				}
			}
			result.success = true;
			if (email.subject.contains('Foreign Line Request') || email.subject.contains('Claimant Ref #')) {
				uploadReplyEmailToECM(emailMessageId); //or get the above condition from doc ref object based on type
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimEmailServices',
				'Claim Email Service',
				String.valueOf(ex),
				ex
			);
		}
		return result;
	}
	public void uploadReplyEmailToECM(Id emailMsgId) {
		if(Schema.sObjectType.EmailMessage.isAccessible()){
			List<EmailMessage> replyEmails = [
				SELECT Id, TextBody, HtmlBody, Subject, FromAddress, ToAddress, CcAddress, CreatedDate, ParentId
				FROM EmailMessage
				WHERE Id = :emailMsgId
			];
			CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(replyEmails);
			Database.executeBatch(uploadEmailBatch);
		}
	}
}