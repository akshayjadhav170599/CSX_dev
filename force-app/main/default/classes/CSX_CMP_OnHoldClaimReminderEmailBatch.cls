/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldClaimReminderEmailBatch
@Created Date - 3/10/2024
@Description  - This batch Apex is used to send the onhold emails to the Rail Road
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_OnHoldClaimReminderEmailBatch implements Database.Batchable<sObject>,Database.Stateful {
	public Map<Case, Set<String>> claimtoEmailIdsMap = new Map<Case, Set<String>>();
	public integer intFinalCount = 0;
	public Id incentiveEmailTemplateId;
	public Id overchargeEmailTemplateId;

	public CSX_CMP_OnHoldClaimReminderEmailBatch() {
		String incentiveEmailTemplateName = 'CSX_CMP_OnHold_Incentive_Reminder_Email';
		String overchargeEmailTemplateName = 'CSX_CMP_OnHold_Overcharge_Reminder_Email';
		List<Case> onHoldClaims = [
			SELECT
				Id,
				RecordType.developerName,
				CSX_CMP_Supplier_Claimant__c,
				Type,
				CaseNumber,CSX_CMP_Case_Number_Formula__c,
				CSX_CMP_Claim_Amount__c,
				(SELECT Id, Name, CSX_CMP_Emails__c FROM Claim_Contacts__r WHERE CSX_CMP_Emails__c != ''),
				(SELECT Id FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Do not send On-Hold reminder')
			FROM Case
			WHERE (RecordType.developerName = 'Revenue_Overcharge' OR Type = 'Incentive Claim') AND Status = 'On Hold'
		];

		for (Case claim : onHoldClaims) {
			if (claim.Notes__r.isempty()) {
				Set<String> allClaimEmailIds = new Set<String>();
				for (CSX_CMP_Claim_Contact__c clContact : claim.Claim_Contacts__r) {
					String emailsStr = String.valueof(clContact.CSX_CMP_Emails__c);
					List<String> emails = emailsStr.tolowerCase().split(';');
					allClaimEmailIds.addAll(emails);
				}
				claimtoEmailIdsMap.put(claim, allClaimEmailIds);
			}
		}

		incentiveEmailTemplateId = [
			SELECT Id
			FROM EmailTemplate
			WHERE DeveloperName = :incentiveEmailTemplateName
			LIMIT 1
		]
		.Id;

		overchargeEmailTemplateId = [
			SELECT Id
			FROM EmailTemplate
			WHERE DeveloperName = :overchargeEmailTemplateName
			LIMIT 1
		]
		.Id;
	}

	public Iterable<SObject> start(Database.BatchableContext context) {
		return claimtoEmailIdsMap.keySet();
	}

	public void execute(Database.BatchableContext context, List<Case> lstCase) {
		Map<Id, List<String>> incentiveClaimIdtoEmailsMap = new Map<Id, List<String>>();
		Map<Id, String> claimToClaimNumberMap = new Map<Id, String>();
		list<Messaging.SingleEmailMessage> lstSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
		list<Messaging.SingleEmailMessage> lstSingleEmailMessageIncentive = new List<Messaging.SingleEmailMessage>();
		Map<String, List<String>> overchargeEmailIdstoClaimsMap = new Map<String, List<String>>();
		String strSubjectOvercharge = 'Reminder - Overcharge claim payments on hold due to past terms AR Balance';
		try {
			for (Case claim : lstCase) {
				List<String> emailsSorted = new List<String>();
				emailsSorted.addAll(claimtoEmailIdsMap.get(claim));
				emailsSorted.sort();
				if (claim.RecordType.developerName == 'Revenue_Overcharge') {
					String emailIdString = String.join(emailsSorted, ';');
					String key = emailIdString;
					if (!overchargeEmailIdstoClaimsMap.containsKey(emailIdString)) {
						overchargeEmailIdstoClaimsMap.put(key, new List<String>{ claim.Id });
					} else {
						overchargeEmailIdstoClaimsMap.get(key).add(claim.Id);
					}
				} else if (claim.Type == 'Incentive Claim') {
					incentiveClaimIdtoEmailsMap.put(claim.Id, emailsSorted);
					claimToClaimNumberMap.put(claim.Id, claim.CaseNumber);
				}
			}
			//email for overcharge claims
			if (!overchargeEmailIdstoClaimsMap.isempty()) {
				for (String emailString : overchargeEmailIdstoClaimsMap.keySet()) {
					CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
					emailWrap.templateDeveloperName = 'CSX_CMP_OnHold_Overcharge_Reminder_Email';
					List<String> emailList = emailString.split(';');
					emailWrap.toEmailIdList = emailList;
					//take only 1st claim and remaining claims would be identified in email controller
					String claimId = overchargeEmailIdstoClaimsMap.get(emailString)[0];
					emailWrap.sourceRecordId = claimId;
					emailWrap.subject = strSubjectOvercharge;
					lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));

					intFinalCount++;
				}
				if (lstSingleEmailMessage != null) {
					Messaging.sendEmail(lstSingleEmailMessage);
				}
			}

			//email for incentive claims
			if (!incentiveClaimIdtoEmailsMap.isEmpty()) {
				for (String claimId : incentiveClaimIdtoEmailsMap.keySet()) {
					CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
					emailWrap.templateDeveloperName = 'CSX_CMP_OnHold_Incentive_Reminder_Email';
					emailWrap.sourceRecordId = claimId;
					emailWrap.toEmailIdList = incentiveClaimIdtoEmailsMap.get(claimId);
					String subjectIncentive =
						'Reminder - Incentive Claim payment ' +
						claimToClaimNumberMap.get(claimId) +
						' On-Hold due to past terms AR Balance';
					emailWrap.subject = subjectIncentive;
					lstSingleEmailMessageIncentive.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
					intFinalCount++;
				}
				Messaging.sendEmail(lstSingleEmailMessageIncentive);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_OnHoldClaimReminderEmailBatch',
				'execute',
				JSON.serialize(overchargeEmailIdstoClaimsMap.values()),
				ex
			);
		}
	}

	public void finish(Database.BatchableContext context) {
		CSX_CMP_LoggerUtility.addExecutionLog(
			'CSX_CMP_SendEmailsBatch',
			'Number of Onhold Reminder emails sent',
			'Case',
			intFinalCount
		);

		CSX_CMP_Last_Execution_Log__c lastExecutionLog = CSX_CMP_Last_Execution_Log__c.getValues(
			'CMP-I-0439_Send_onhold_email'
		);
		lastExecutionLog.CSX_CMP_Execution_Time__c = system.now();
		update lastExecutionLog;
	}
}