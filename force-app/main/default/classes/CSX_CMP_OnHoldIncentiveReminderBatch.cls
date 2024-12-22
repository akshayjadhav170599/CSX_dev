/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldIncentiveReminderBatch
@Created Date - 5/24/2024
@Description  - This batch Apex is used to send the onhold emails to the Incentive Rail Road
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_OnHoldIncentiveReminderBatch implements Database.Batchable<sObject> {
	public Map<Case, Set<String>> claimtoEmailIdsMap = new Map<Case, Set<String>>();
	public integer intFinalCount = 0;

	public Iterable<SObject> start(Database.BatchableContext context) {
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
			WHERE Type = 'Incentive Claim' AND Status = 'On Hold'
		];
		return onHoldClaims;
	}

	public void execute(Database.BatchableContext context, List<Case> lstCase) {
		list<Messaging.SingleEmailMessage> lstSingleEmailMessageIncentive = new List<Messaging.SingleEmailMessage>();
		try {
			for (Case claim : lstCase) {
				if (claim.Notes__r.isempty()) {
					CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
					emailWrap.templateDeveloperName = 'CSX_CMP_OnHold_Incentive_Reminder_Email';
					emailWrap.sourceRecordId = claim.Id;

					Set<String> allClaimEmailIds = new Set<String>();
					for (CSX_CMP_Claim_Contact__c clContact : claim.Claim_Contacts__r) {
						String emailsStr = clContact.CSX_CMP_Emails__c;
						List<String> emails = emailsStr.tolowerCase().split(';');
						allClaimEmailIds.addAll(emails);
					}
					List<String> allEmails = new List<String>();
					allEmails.addAll(allClaimEmailIds);
					emailWrap.toEmailIdList = allEmails;
					emailWrap.subject =
						'Reminder - Incentive Claim payment ' +
						/*claim.CaseNumber +*/
						claim.CSX_CMP_Case_Number_Formula__c +
						' On-Hold due to past terms AR Balance';
					lstSingleEmailMessageIncentive.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
					intFinalCount++;
				}
			}
			Messaging.SendEmailResult[] res = Messaging.sendEmail(lstSingleEmailMessageIncentive);
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_OnHoldIncentiveReminderBatch', 'execute', res);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_OnHoldIncentiveReminderBatch',
				'execute',
				JSON.serialize(lstCase),
				ex
			);
		}
	}
	public void finish(Database.BatchableContext context) {
		CSX_CMP_LoggerUtility.addExecutionLog(
			'CSX_CMP_OnHoldIncentiveReminderBatch',
			'Number of Onhold Incentive Reminder emails sent',
			'Case',
			intFinalCount
		);
        CSX_CMP_OnHoldOverchargeReminderBatch batchJob = new CSX_CMP_OnHoldOverchargeReminderBatch();
		id batchJobId = Database.executeBatch(batchJob,1);

		CSX_CMP_Last_Execution_Log__c lastExecutionLog = CSX_CMP_Last_Execution_Log__c.getValues(
			'CMP-I-0439_Send_onhold_email'
		);
		lastExecutionLog.CSX_CMP_Execution_Time__c = system.now();
		update lastExecutionLog;
	}
}