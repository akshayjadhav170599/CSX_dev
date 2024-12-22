/**
@author       - Infosys
@name         - CSX_CMP_ClaimTriggerHelper
@Created Date - 10/20/2023
@description  - Apex trigger helper on Claim/Case object
*/
public with sharing class CSX_CMP_ClaimTriggerHelper {
	/*
    @description : This method is used to update the new claim id on the source distribution records.
    @param : Map<Id,Case> newClaimsMap - Map of new claim records.
    */
	public static void updateDistributionwithClaimId(Map<String, Id> distIdtoClaimIdMap) {
		try {
			List<CSX_CMP_Distribution__c> distributionListToUpdate = new List<CSX_CMP_Distribution__c>();
			for (String distId : distIdtoClaimIdMap.keySet()) {
				CSX_CMP_Distribution__c distRec = new CSX_CMP_Distribution__c();
				distRec.Id = distId;
				distRec.CSX_CMP_Distribution_Claim__c = distIdtoClaimIdMap.get(distId);
				distRec.CSX_CMP_Distribution_Claim_Created__c = true;
				distributionListToUpdate.add(distRec);
			}

			Database.SaveResult[] distributionUpdateResultList = Database.update(distributionListToUpdate);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updateDistributionwithClaimId',
				distributionUpdateResultList,
				'CSX_CMP_Distribution__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updateDistributionwithClaimId',
				JSON.serialize(distIdtoClaimIdMap),
				ex
			);
		}
	}
	//reset Settled Date when claim status gets changed to other than decline or closed
	/* public static void resetSettledDateOnClaim( List<Id> claimId){
            List<Case> resetClaims;
            try{
                if(claimId!=null){
                    resetClaims= [select Id,CSX_CMP_Settled_Date__c from Case where Id IN:claimId];
                    List<Case> resetSettledDate = new List<Case>();
                    for(Case cs:resetClaims){
                        cs.CSX_CMP_Settled_Date__c=date.parse('00/00/0000');
                        resetSettledDate.add(cs);
                    }
                    update(resetClaims);
                //    CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_ClaimTriggerHelper','resetSettledDate',resetSettledDate,'Case');
                }
            }catch(Exception ex){
                CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimTriggerHelper','resetDate',JSON.serialize(resetClaims),ex);
            }
        } */
	/*update close Date when claim status gets changed to pending close or closed
	public static void updateSettledDate(List<Id> claimId) {
		List<Case> settledClaims;
		try {
			if (claimId != null) {
				settledClaims = [SELECT Id, CSX_CMP_Settled_Date__c FROM Case WHERE Id IN :claimId];
				List<Case> updateCaseSettledDate = new List<Case>();
				for (Case cs : settledClaims) {
					cs.CSX_CMP_Settled_Date__c = Date.today();
					updateCaseSettledDate.add(cs);
				}
				Database.SaveResult[] updateSettledDate = Database.update(updateCaseSettledDate);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimTriggerHelper',
					'updateSettledDate',
					updateSettledDate,
					'Case'
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updateSettledDate',
				JSON.serialize(settledClaims),
				ex
			);
		}
	}*/
	@Future(callout=true)
	public static void emailDeclineLetter(List<Id> eligibleDeclineLetter) {
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<Messaging.SendEmailResult> emailResult = new List<Messaging.SendEmailResult>();
		// List<Case> claims;
		List<CSX_CMP_Claim_Contact__c> claimContacts;
		Map<Id, String> claimDetails = new Map<Id, String>();
		try {
			if (!eligibleDeclineLetter.isEmpty()) {
				claimContacts = [
					SELECT id, CSX_CMP_Emails__c
					FROM CSX_CMP_Claim_Contact__c
					WHERE CSX_CMP_Claim__c IN :eligibleDeclineLetter
					WITH SECURITY_ENFORCED
				];
			}
			Set<String> toEmailId = new Set<String>();
			if (!claimContacts.isEmpty()) {
				for (CSX_CMP_Claim_Contact__c clContact : claimContacts) {
					String emailsStr = String.valueof(clContact.CSX_CMP_Emails__c);
					List<String> emails = emailsStr.tolowerCase().split(';');
					toEmailId.addAll(emails);
				}
			}
			List<Case> claimDeclineDate = new List<Case>(
				[
					SELECT Id, CaseNumber, CSX_CMP_Case_Number_Formula__c, CSX_CMP_Decline_Email_Sent_Date__c
					FROM Case
					WHERE ID IN :eligibleDeclineLetter
					WITH SECURITY_ENFORCED
				]
			);
			List<Case> updateClaim = new List<Case>();
			if (!(claimDeclineDate.isEmpty())) {
				for (Case claim : claimDeclineDate) {
					claim.CSX_CMP_Decline_Email_Sent_Date__c = CSX_CMP_Utility.formatDate(Date.today());
					updateClaim.add(claim);
					claimDetails.put(claim.Id, claim.CSX_CMP_Case_Number_Formula__c);
				}
			}
			List<String> toEmail = new List<String>(toEmailId);

			for (String claimId : eligibleDeclineLetter) {
				CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
				emailWrap.sourceRecordId = claimId;
				if (!toEmailId.isEmpty()) {
					emailWrap.toEmailIdList = toEmail;
				}
				emailWrap.ccEmailIdList = null;
				emailWrap.templateDeveloperName = 'CSX_CMP_DeclineEmailNotification';
				emailWrap.attachmentFileName = 'OverChargeDeclineLetter.pdf';
				emailWrap.pdfVFPageName = 'CSX_CMP_OverchargeDeclineLetter';
				if (claimDetails.containsKey(claimId)) {
					emailWrap.subject = 'Decline Letter: ' + claimDetails.get(claimId);
				} else {
					emailWrap.subject = 'Decline Letter';
				}
				CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(emailWrap);
				Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(emailWrap);
				emailList.add(email);
			}

			if (!emailList.isEmpty()) {
				emailResult = Messaging.sendEmail(emailList);
				CSX_CMP_LoggerUtility.addApexEmailErrorLog('emailDeclineLetter', 'Trigger', emailResult);
			}
			Database.SaveResult[] declineClaimEmailSentList = Database.update(updateClaim, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'emailDeclineLetter',
				'declineClaimEmailSentList',
				declineClaimEmailSentList,
				'Case'
			);
			// calling batch class to upload to ECM
			System.enqueueJob(new CSX_CMP_OverchargeDeclineEmailQueueable(eligibleDeclineLetter));
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_ClaimTriggerHelper', 'emailDeclineLetter', emailResult);
		}
	}

	/*
    @description : This method is used to send the closure email to the claimant when the claim is closed.
    @param : Set<Id> claimIds - Set of claim Ids for which the closure email needs to be sent.
	Modification Log :
	Date			Author				Description
	17/5/2024		Aditya				Updated email utility wrapper method to send email.
    */
	public static void sendDetailsToClosureEmail(Set<Id> claimIds) {
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<Messaging.SendEmailResult> emailResult = new List<Messaging.SendEmailResult>();
		try {
			Map<Id, Case> claimList = new Map<Id, Case>(
				[
					SELECT Id, RecordTypeId, Origin, (SELECT Id, CSX_CMP_Emails__c FROM Claim_Contacts__r)
					FROM case
					WHERE Id IN :claimIds
				]
			);

			List<EmailTemplate> emailTemplateList = [
				SELECT Id, DeveloperName
				FROM EmailTemplate
				WHERE
					DeveloperName IN (
						'CSX_CMP_Freight_Closure_Email_Template',
						'CSX_CMP_Contract_Closure_Email_Template',
						'CSX_CMP_Overcharge_Closure_Email'
					)
				WITH SECURITY_ENFORCED
			];
			Map<String, String> emailTemplateMap = new Map<String, String>();
			for (EmailTemplate template : emailTemplateList) {
				emailTemplateMap.put(template.DeveloperName, template.Id);
			}
			Map<Id, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosById();
			List<Id> freightClaimIds = new List<Id>();
			List<Id> overChargeClaimIds = new List<Id>();
			List<Id> refundClaimIds = new List<Id>();
			for (case claim : claimList.values()) {
				if (recordTypeMap.get(claim.RecordTypeId).getDeveloperName() == 'Freight' && claim.Origin == 'SHIPCSX') {
					freightClaimIds.add(claim.Id);
				} else if (
					recordTypeMap.get(claim.RecordTypeId).getDeveloperName() == 'Revenue_Overcharge' &&
					claim.Origin == 'SHIPCSX'
				) {
					overChargeClaimIds.add(claim.Id);
				} else if (recordTypeMap.get(claim.RecordTypeId).getDeveloperName() == 'Revenue_Contract_Refund') {
					refundClaimIds.add(claim.Id);
				}
			}

			if (!freightClaimIds.isEmpty()) {
				Map<String, Object> detailMap = new Map<String, Object>();
				// detailMap.put('emailTemplateId', emailTemplateMap.get('CSX_CMP_Contract_Closure_Email_Template'));
				detailMap.put('emailTemplateDeveloperName', 'CSX_CMP_Freight_Closure_Email_Template');
				detailMap.put('ids', freightClaimIds);
				emailList.addAll(getEmailList(detailMap, claimList));
			}

			if (!overChargeClaimIds.isEmpty()) {
				Map<String, Object> detailMap = new Map<String, Object>();
				// detailMap.put('emailTemplateId', emailTemplateMap.get('CSX_CMP_Overcharge_Closure_Email'));
				detailMap.put('emailTemplateDeveloperName', 'CSX_CMP_Overcharge_Closure_Email');
				detailMap.put('ids', overChargeClaimIds);
				emailList.addAll(getEmailList(detailMap, claimList));
			}

			if (!refundClaimIds.isEmpty()) {
				Map<String, Object> detailMap = new Map<String, Object>();
				// detailMap.put('emailTemplateId', emailTemplateMap.get('CSX_CMP_Contract_Closure_Email_Template'));
				detailMap.put('emailTemplateDeveloperName', 'CSX_CMP_Contract_Closure_Email_Template');
				detailMap.put('ids', refundClaimIds);
				emailList.addAll(getEmailList(detailMap, claimList));
			}

			if (!emailList.isEmpty()) {
				emailResult = Messaging.sendEmail(emailList);
			}
			CSX_CMP_LoggerUtility.addApexEmailErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'sendDetailsToClosureEmail',
				emailResult
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_ClaimTriggerHelper', 'sendConfirmationEmail', emailResult);
		}
	}

	/*
    @description : This method is used to send the email to the claimant.
    @param : Map<String, Object> detailMap - Map of email template id and claim ids.
    @param : Map<Id,Case> caseMap - Map of claim records.
    @return : List<Messaging.SingleEmailMessage> - List of email messages.
    */
	private static List<Messaging.SingleEmailMessage> getEmailList(Map<String, Object> detailMap, Map<Id, Case> caseMap) {
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		try {
			List<Id> idList = (List<Id>) detailMap.get('ids');
			List<String> mailAddresses = new List<String>();
			for (Id claimId : idList) {
				Case claim = caseMap.get(claimId);
				if (!claim.Claim_Contacts__r.isEmpty()) {
					for (CSX_CMP_Claim_Contact__c contact : claim.Claim_Contacts__r) {
						if (contact.CSX_CMP_Emails__c.contains(';')) {
							mailAddresses.addAll(contact.CSX_CMP_Emails__c.split(';'));
						} else {
							mailAddresses.add(contact.CSX_CMP_Emails__c);
						}
					}
				}

				if (!mailAddresses.isEmpty()) {
					CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
					emailWrap.templateDeveloperName = (String) detailMap.get('emailTemplateDeveloperName');
					emailWrap.toEmailIdList = mailAddresses;
					emailWrap.sourceRecordId = claimId;
					// String subject= strSubject;
					// emailWrap.subject=subject;
					emailList.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));

					//emailList.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail((String) detailMap.get('emailTemplateId'),null,claimId,mailAddresses,null,null));
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimTriggerHelper', 'getEmailList', JSON.serialize(detailMap), e);
		}
		return emailList;
	}

	// Added on 21/05/2024 - Subodh
	/**
	@description : This method is used to send the claim status change update to the Customer Service system.
	@param : List<Id> claimIds - List of claim Ids for which the status change update needs to be sent.
	 */
	@future(callout=true)
	public static void sendStatusChangeUpdate(List<Id> claimIds) {
		try {
			Case claim = [
				SELECT Id, CaseNumber, CSX_CMP_Case_Number_Formula__c, Status
				FROM Case
				WHERE Id IN :claimIds
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			Map<String, String> claimMap = new Map<String, String>();
			claimMap.put('claimNumber', claim.CSX_CMP_Case_Number_Formula__c);
			claimMap.put('claimStatus', claim.Status);
			CSX_CMP_InterfaceUtility.sendClaimStatusUpdateToCustomerService(claimMap);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'sendStatusChangeUpdate',
				JSON.serialize(claimIds),
				ex
			);
		}
	}

	/**
	@description : This method is used to update salvage records when claim is cancelled
	@param : List<Id> salvageClaimIds - List of salvage claim Ids for which the salvage records needs to be updated.
	 */
	public static void clearSalvageClaimOnSalvage(List<Id> salvageClaimIds) {
		try {
			List<CSX_CMP_Salvage__c> salvageList = [
				SELECT Id, CSX_CMP_Salvage_Claim__c
				FROM CSX_CMP_Salvage__c
				WHERE CSX_CMP_Salvage_Claim__c IN :salvageClaimIds WITH SECURITY_ENFORCED
			];
			for (CSX_CMP_Salvage__c salvage : salvageList) {
				salvage.CSX_CMP_Salvage_Claim__c = null;
			}
			Database.SaveResult[] salvageUpdateResultList = Database.update(salvageList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'clearSalvageClaimOnSalvage',
				salvageUpdateResultList,
				'CSX_CMP_Salvage__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'clearSalvageClaimOnSalvage',
				JSON.serialize(salvageClaimIds),
				ex
			);
		}
	}

	/**
	@description : This method is used to update distribution records when claim is cancelled
	@param : List<Id> distributionClaimIds - List of distribution claim Ids for which the distribution records needs to be updated.
	 */
	public static void clearDistributionClaimOnDistribution(List<Id> distributionClaimIds) {
		try {
			List<CSX_CMP_Distribution__c> distributionList = [
				SELECT Id, CSX_CMP_Distribution_Claim__c,CSX_CMP_Distribution_Claim_Created__c
				FROM CSX_CMP_Distribution__c
				WHERE CSX_CMP_Distribution_Claim__c IN :distributionClaimIds WITH SECURITY_ENFORCED
			];
			for (CSX_CMP_Distribution__c distribution : distributionList) {
				distribution.CSX_CMP_Distribution_Claim__c = null;
				distribution.CSX_CMP_Distribution_Claim_Created__c = false;
			}
			Database.SaveResult[] distributionUpdateResultList = Database.update(distributionList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'clearDistributionClaimOnDistribution',
				distributionUpdateResultList,
				'CSX_CMP_Distribution__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'clearDistributionClaimOnDistribution',
				JSON.serialize(distributionClaimIds),
				ex
			);
		}
	}

	/**
	@description : This method is used to update Distribution claims with service period and respctive parent claim's service period' when parent claims are closed
	@param : List<Id> claimIds - List of claim Ids for which the service period needs to be updated.
	 */
	public static void updateServicePeriodOnDistributionClaims(List<Id> claimIds) {
		try {
			Set<Id> parentClaimIds = new Set<Id>();
			List<Case> claimList = [
				SELECT Id, CSX_CMP_Service_Period__c, ParentId
				FROM Case 
				WHERE (ParentId IN :claimIds OR Id IN :claimIds) 
				// AND Origin = 'Distribution' 
				WITH SECURITY_ENFORCED 
			];
			String servicePeriod =
				'PER-' +
				String.valueOf(Date.today().month()) +
				'-' +
				String.valueOf(Date.today().year()).substring(2, 4);
			Set<Case> updateClaimList = new Set<Case>();
			if (!claimList.isEmpty()) {
				for (Case claim : claimList) {
					claim.CSX_CMP_Service_Period__c = servicePeriod;
					updateClaimList.add(claim);
					parentClaimIds.add(claim.ParentId);
				}
			}

			if (!parentClaimIds.isEmpty()) {
				for (Id claimId : parentClaimIds) {
					Case newClaim = new Case(Id = claimId);
					newClaim.CSX_CMP_Service_Period__c = servicePeriod;
					updateClaimList.add(newClaim);
				}
			}
			Database.SaveResult[] updateResultList = Database.update( new List<Case>(updateClaimList), false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updateServicePeriodOnDistributionClaims',
				updateResultList,
				'Case'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updateServicePeriodOnDistributionClaims',
				JSON.serialize(claimIds),
				ex
			);
		}
	}

	/*
	@description: This method is used to check whether the change on record is a valid change or not based on user role and field sets which needs to be applicable to respective status and user role
	*/
	public static Boolean isAuthorizedChange(Case oldClaim, Case newClaim, String userRole) {
		try {
			if (userRole == null) {
				return false;
			}

			Map<String, Object> claim = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(newClaim));
			Map<String, Object> oldClaimMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(oldClaim));
			Boolean noDataChange = false;
			String fields = CSX_CMP_ClaimCloneHelper.getFields('Case');
			// for (String key : fields.split(',')) {
			for(String key : claim.keySet()) {
				key = key.trim();
				if(key == 'Comments'){
					system.debug('String.isNotBlank(String.valueOf(claim.get(key))'+String.isNotBlank(String.valueOf(claim.get(key))));
					system.debug('String.isBlank(String.valueOf(oldClaimMap.get(key))'+String.isBlank(String.valueOf(oldClaimMap.get(key))));
					system.debug('claim.get(key) == oldClaimMap.get(key)'+claim.get(key) == oldClaimMap.get(key));
					system.debug('claim.get(key)'+claim.get(key));
					system.debug('claim.get(Comments))'+claim.get('Comments'));
				}
				if((String.isNotBlank(String.valueOf(claim.get(key))) && String.isBlank(String.valueOf(oldClaimMap.get(key)))) || (String.isBlank(String.valueOf(claim.get(key))) && String.isNotBlank(String.valueOf(oldClaimMap.get(key))))){
					noDataChange = false;
					break;
				} else if (claim.get(key) == oldClaimMap.get(key) ) {
					noDataChange = true;
				}
			}
			if (noDataChange) {
				return true;
			}

			if (
				newClaim.Status == 'Pending Monthly Settlement' ||
				newClaim.Status == 'Pending Close' ||
				newClaim.Status == 'Pending Approval' ||
				newClaim.Status == 'Closed' ||
				newClaim.Status == 'Cancelled'
			) {
				if (newClaim.Status == 'Pending Monthly Settlement') {
					return isAuthorizedValidation('CSX_CMP_EditableFieldsForPendingMonthly', oldClaim, newClaim);
				} else if (newClaim.Status == 'Cancelled') {
					if (userRole.contains('Manager') || userRole.contains('Admin')) {
						return isAuthorizedValidation('CSX_CMP_CancelledEditableFields', oldClaim, newClaim);
					} else {
						return false;
					}
				} else {
					if (userRole.contains('Manager') || userRole.contains('Admin')) {
						return isAuthorizedValidation('CSX_CMP_EditableFieldsForAdminOrManager', oldClaim, newClaim);
					}
				}
			} else {
				return true;
			}
			return true;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'isAuthorizedChange',
				JSON.serialize(oldClaim),
				ex
			);
			return false;
		}
	}

	private static Boolean isAuthorizedValidation(String fieldSetName, Case oldClaim, Case newClaim) {
		Boolean isEditable = false;
		try {
			Map<String, String> fieldSetFields = new Map<String, String>();
			Schema.FieldSet editableFields = Schema.SObjectType.Case.fieldSets.getMap().get(fieldSetName);

			for (Schema.FieldSetMember field : editableFields.getFields()) {
				fieldSetFields.put(field.getFieldPath().tolowerCase(), field.getFieldPath().tolowerCase());
			}

			Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
			for (String fieldName : fieldMap.keySet()) {
				if (newClaim.get(fieldName) != oldClaim.get(fieldName)) {
					if (fieldSetFields.containsKey(fieldName.tolowerCase())) {
						isEditable = true;
					} else {
						isEditable = false;
						break;
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'isAuthorizedValidation',
				JSON.serialize(oldClaim),
				ex
			);
		}
		return isEditable;
	}

	/*
    @description : This method is used to send email with letter attached to claim contact email addresses 
	when status changed to “Pending Monthly settlement” on Claim approval
    */
	@Future(callout=true)
	public static void sendLOALetter(set<Id> setofEligibleClaimApprovalLetter) {
		List<Messaging.SingleEmailMessage> lstSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
		List<Messaging.SendEmailResult> lstSendEmailResult = new List<Messaging.SendEmailResult>();

		try {
			if (!setofEligibleClaimApprovalLetter.isEmpty()) {
				list<Case> lstClaim = [
					SELECT
						id,
						CaseNumber,
						CSX_CMP_Case_Number_Formula__c,
						CSX_CMP_Claim_Amount__c,
						(
							SELECT Id, CSX_CMP_Emails__c
							FROM Claim_Contacts__r
							//WHERE CSX_CMP_Type__c = 'Reported By'
						)
					FROM Case
					WHERE id IN :setofEligibleClaimApprovalLetter
					WITH SECURITY_ENFORCED
				];

				for (Case objCase : lstClaim) {
					if (objCase.Claim_Contacts__r != null && objCase.Claim_Contacts__r.size() > 0) {
						Set<String> setOfEmailId = new Set<String>();
						for (CSX_CMP_Claim_Contact__c objClaimContact : objCase.Claim_Contacts__r) {
							String strEmail = String.valueof(objClaimContact.CSX_CMP_Emails__c);
							List<String> lstEmails = strEmail.tolowerCase().split(';');
							setOfEmailId.addAll(lstEmails);
						}

						CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
						emailWrap.sourceRecordId = objCase.id;
						if (!setOfEmailId.isEmpty()) {
							emailWrap.toEmailIdList = new List<String>(setOfEmailId);
						}
						emailWrap.ccEmailIdList = null;
						emailWrap.templateDeveloperName = 'CSX_CMP_Claim_Approval_LOA_Letter';
						//emailWrap.attachmentFileName = 'OverChargeApprovalLetter.pdf';
						emailWrap.attachmentFileName = 'LOAApprovalLetter.pdf';
						emailWrap.pdfVFPageName = 'CSX_CMP_OverchargeApprovalLetter';
						emailWrap.subject = 'LOA letter generated';

						Messaging.SingleEmailMessage objSingleEmailMessage = CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(
							emailWrap
						);
						lstSingleEmailMessage.add(objSingleEmailMessage);
					}
				}
			}

			if (!lstSingleEmailMessage.isEmpty()) {
				lstSendEmailResult = Messaging.sendEmail(lstSingleEmailMessage);
				CSX_CMP_LoggerUtility.addApexEmailErrorLog('sendLOALetter', 'Trigger', lstSendEmailResult);
			}

			/*Database.SaveResult[] declineClaimEmailSentList = Database.update(updateClaim, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'emailDeclineLetter',
				'declineClaimEmailSentList',
				declineClaimEmailSentList,
				'Case'
			);*/
			//calling batch class to upload to ECM
			System.enqueueJob(new CSX_CMP_LOAEmailQueueable(setofEligibleClaimApprovalLetter));
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_ClaimTriggerHelper', 'sendLOALetter', lstSendEmailResult);
		}
	}

	/*
	@description : This method is used to update the paid amount field on related LDR records
	*/
	public static void updatePaidAmountOnRelatedLDR(Set<Id> claimIds) {
		try {
			List<CSX_CMP_Related_LD_Report__c> relatedLDRList = [
				SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Claim__r.CSX_CMP_Paid_Amount__c
				FROM CSX_CMP_Related_LD_Report__c
				WHERE CSX_CMP_Claim__c IN :claimIds
				WITH SECURITY_ENFORCED
			];
			List<CSX_CMP_Related_LD_Report__c> updateRelatedLDRList = new List<CSX_CMP_Related_LD_Report__c>();
			if(!relatedLDRList.isEmpty()) {
				for(CSX_CMP_Related_LD_Report__c relatedLDR : relatedLDRList) {
					relatedLDR.CSX_CMP_Paid_Amount__c = relatedLDR.CSX_CMP_Claim__r.CSX_CMP_Paid_Amount__c;
					updateRelatedLDRList.add(relatedLDR);
				}
			}

			Database.SaveResult[] updateResultList = Database.update(updateRelatedLDRList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updatePaidAmountOnRelatedLDR',
				updateResultList,
				'CSX_CMP_Related_LD_Report__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimTriggerHelper',
				'updatePaidAmountOnRelatedLDR',
				JSON.serialize(claimIds),
				ex
			);
		}
	}
}