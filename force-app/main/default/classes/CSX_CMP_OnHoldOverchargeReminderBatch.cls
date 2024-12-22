/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldOverchargeReminderBatch
@Created Date - 5/24/2024
@Description  - This batch Apex is used to send the onhold emails to the Overcharge Rail Road
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_OnHoldOverchargeReminderBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {
	public Map<String, List<Id>> emailIdToClaimsMap = new Map<String, List<Id>>();
	public integer intFinalCount = 0;
	
	public CSX_CMP_OnHoldOverchargeReminderBatch() {
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
			WHERE RecordType.developerName = 'Revenue_Overcharge' AND Status = 'On Hold'
		];

		for (Case claim : onHoldClaims) {
			if (claim.Notes__r.isempty()) {
				for (CSX_CMP_Claim_Contact__c clContact : claim.Claim_Contacts__r) {
					String emailsStr = clContact.CSX_CMP_Emails__c;
					List<String> emails = emailsStr.tolowerCase().split(';');

					for (String email : emails) {
						if (!emailIdToClaimsMap.containsKey(email)) {
							emailIdToClaimsMap.put(email, new List<Id>{ claim.Id });
						} else {
							emailIdToClaimsMap.get(email).add(claim.Id);
						}
					}
				}
			}
		}
	}

	// batch will be run with batch size as 1 only
	public Iterable<String> start(Database.BatchableContext context) {
		return emailIdToClaimsMap.keySet();
	}

	public void execute(Database.BatchableContext context, List<String> targetEmailIds) {
		try {
			List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

			CSX_CMP_Last_Execution_Log__c lastExecutionInfo = CSX_CMP_Last_Execution_Log__c.getValues(
				'CMP-I-0439_Send_onhold_email'
			);

			//update custom setting with email id which batch needs to focus on for sending the email. This will be used in email controller to pull remaining claims to be included in summary.
			lastExecutionInfo.CSX_CMP_For_System_Use_Only__c = targetEmailIds[0];
			lastExecutionInfo.CSX_CMP_Execution_Time__c = system.now();
			update lastExecutionInfo;

			CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
			emailWrap.templateDeveloperName = 'CSX_CMP_OnHold_Overcharge_Reminder_Email';
			emailWrap.toEmailIdList = new List<String>{ targetEmailIds[0] };
			//take only 1st claim and remaining claims would be identified in email controller
			emailWrap.sourceRecordId = emailIdToClaimsMap.get(targetEmailIds[0])[0];
			emailWrap.subject = 'Reminder - Overcharge claim payments on hold due to past terms AR Balance';
			Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap);
			emailList.add(email);
			intFinalCount++;
			List<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(emailList);
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_GenerateDeclineLetterBatch', 'execute', emailResult);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_OnHoldOverchargeReminderBatch',
				'execute',
				JSON.serialize(targetEmailIds),
				ex
			);
		}
	}

	public void finish(Database.BatchableContext context) {
		CSX_CMP_LoggerUtility.addExecutionLog(
			'CSX_CMP_OnHoldOverchargeReminderBatch',
			'Number of Overcharge Onhold Reminder emails sent',
			'Case',
			intFinalCount
		);
	}
}