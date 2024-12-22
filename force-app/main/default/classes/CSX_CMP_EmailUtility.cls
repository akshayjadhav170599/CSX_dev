/**
@Author       - Infosys
@Name         - Email Utility
@Created Date - 12/17/2023
@Description  - This Apex class is used to send the emails
				- for bulk requests kindly pass emailTemplateId and setOrgWideEmailAddressId in parameter so we don't query again and reduce the number of queries run
@RICEFW reference - Reusable Apex Utility
*/
public with sharing class CSX_CMP_EmailUtility {
	public static Messaging.SingleEmailMessage sendVisualForceTemplateEmailWithPDF(EmailRequestWrapper emailRequest) {
		Messaging.SingleEmailMessage email;
		try {
			if (emailRequest.sourceRecordId == null || emailRequest.pdfVFPageName == null) {
				return null;
			}

			email = sendVisualForceTemplateEmail(emailRequest);

			String pageStr = '/apex/' + emailRequest.pdfVFpageName;           
			PageReference pdfPageRef = new PageReference(pageStr);        
			pdfPageRef.getParameters().put('id', emailRequest.sourceRecordId);        
			Blob pdfBlob = pdfPageRef.getContentAsPDF();           
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			string fileName = emailRequest.attachmentFileName;
			csvAttc.setFileName(fileName);
			csvAttc.setBody(pdfBlob);
			email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_EmailUtility',
				'sendVisualForceTemplateEmailWithPDF',
				JSON.serialize(emailRequest),
				e
			);
			return null;
		}
		return email;
	}

	public static Messaging.SingleEmailMessage sendVisualForceTemplateEmail(EmailRequestWrapper emailRequest) {
		try {
			Messaging.SingleEmailMessage objMessagingEmail;
			EmailTemplate emailTemplate = new EmailTemplate();
			if (String.isBlank(emailRequest.emailTemplateId) && String.isNotBlank(emailRequest.templateDeveloperName)) {
				emailTemplate = [
					SELECT Id, Name, Subject, DeveloperName, HtmlValue, Body, IsActive
					FROM EmailTemplate
					WHERE DeveloperName = :emailRequest.templateDeveloperName AND IsActive = TRUE WITH SECURITY_ENFORCED
				];
				emailRequest.emailTemplateId = emailTemplate.Id;
			}
              
			objMessagingEmail = Messaging.renderStoredEmailTemplate(
				emailRequest.emailTemplateId,
				emailRequest.whoId,
				emailRequest.sourceRecordId
			);

			if (String.isBlank(emailRequest.setOrgWideEmailAddressId)) {
				// https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_orgwideemailaddress.htm
				// Upon adding with security_enforced, the query is not returning any records as this is an setup object and user needs to have view setup and configuration access to view the records
				// reference url added above
				List<OrgWideEmailAddress> emails = [
					SELECT Id, Address, DisplayName
					FROM OrgWideEmailAddress
					WHERE DisplayName = :System.Label.CSX_CMP_CSX_Support
				];
				objMessagingEmail.setOrgWideEmailAddressId(emails[0].Id);
			} else {
				objMessagingEmail.setOrgWideEmailAddressId(emailRequest.setOrgWideEmailAddressId);
			}
			objMessagingEmail.setUseSignature(false);
			objMessagingEmail.setToAddresses(emailRequest.toEmailIdList);
			objMessagingEmail.saveAsActivity = true;

			list<String> ccEmail = new List<String>();
			CSX_CMP_Claim_Email_Service__c emailService = CSX_CMP_Claim_Email_Service__c.getInstance();
			ccEmail.add(emailService.CSX_CMP_Email_Id__c);
			
            if(emailRequest.templateDeveloperName!='CSX_CMP_OnHold_Overcharge_Reminder_Email' || emailRequest.templateDeveloperName!='CSX_CMP_OnHold_Incentive_Reminder_Email'){ 
                if (emailRequest.ccEmailIdList != null) {
                    ccEmail.addAll(emailRequest.ccEmailIdList);
                    objMessagingEmail.setCcAddresses(ccEmail);
                } else {
                    objMessagingEmail.setCcAddresses(ccEmail);
                }
            }

			if (String.isNotBlank(emailRequest.subject)) {
				objMessagingEmail.setSubject(emailRequest.subject);
			} /*else {
				objMessagingEmail.setSubject(emailTemplate.subject);
			}*/
			return objMessagingEmail;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_EmailUtility',
				'sendVisualForceTemplateEmail',
				JSON.serialize(emailRequest),
				e
			);
			return null;
		}
	}

	public class EmailRequestWrapper {
		public String sourceRecordId;
		public String templateDeveloperName;
		public List<String> toEmailIdList;
		public List<String> ccEmailIdList;
		public String subject;
		public String whoId;
		public String pdfVFPageName;
		public String attachmentFileName;
		public String emailTemplateId;
		public String setOrgWideEmailAddressId;
	}
}