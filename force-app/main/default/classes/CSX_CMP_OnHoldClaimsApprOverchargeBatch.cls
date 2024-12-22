/*
@Author       - Infosys
@Name         - CSX_CMP_OnHoldClaimsApprOverchargeBatch
@Created Date - 3/8/2024
@Description  - This batch Apex is used to reevaluate On Hold claims and submit for Approval when cliam line amounts are within balance due
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_OnHoldClaimsApprOverchargeBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {
	Set<Id> targetClaimIds = new Set<Id>();
	public integer numberofOverchargeClaimsEvaluated = 0;
	public integer numberofOverClaimsSubmittedforApproval = 0;
	public integer numOfemailsforOnholdToReOpen = 0;
	public Id onHoldReopenEmailTemplateId;
	String onHoldReopenEmailTemplateName = 'CSX_CMP_OnHoldToReopenNotification';
	List<Id> claimsIdsforApprInitOvercharge = new List<Id>();
	List<Id> claimIdsGoodforApproval = new List<Id>();
    
	public CSX_CMP_OnHoldClaimsApprOverchargeBatch(Set<Id> claimIds) {
		this.targetClaimIds = claimIds;
        numberofOverchargeClaimsEvaluated = claimIds.size();
	}

	public Iterable<String> start(Database.BatchableContext context) {
		return targetClaimIds;
	}

	public void execute(Database.BatchableContext context, List<Id> lstClaimId) {
		try 
        {
            list<Case> lstClaim = new list<Case>();
            list<Messaging.SingleEmailMessage> lstSingleEmailMessage = new List<Messaging.SingleEmailMessage>();

			if (lstClaimId != null && lstClaimId.size() > 0) {
				map<Case,Boolean> claimIdtoGoodforApprStatusMap = CSX_CMP_SubmitClaimforApprovalHelper.updateLatestFreightBillInfofromSAP(
					lstClaimId
				);
				
                if(claimIdtoGoodforApprStatusMap != null && claimIdtoGoodforApprStatusMap.size() > 0){
                    for(Case objCase : claimIdtoGoodforApprStatusMap.keySet()){
                        if (claimIdtoGoodforApprStatusMap.get(objCase) == true) {
                            claimIdsGoodforApproval.add(objCase.id);
                            numberofOverClaimsSubmittedforApproval += 1;
                        }else {
                            CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
                            emailWrap.templateDeveloperName = 'CSX_CMP_OnHold_Reopen_Notification_Email';
                            emailWrap.toEmailIdList = new List<String>{ objCase.Owner.Email };
                            emailWrap.sourceRecordId = objCase.Id;
                            String subject = 'Notification - objClaim # ' + objCase.CaseNumber + ' reopened';
                            emailWrap.subject = subject;
                            objCase.status = 'Re-Opened';
                            objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                            lstClaim.add(objCase);
                            lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
                            numOfemailsforOnholdToReOpen++;
                        }
                    }
                    
                
                    if (!lstSingleEmailMessage.isEmpty()) {
                        Messaging.sendEmail(lstSingleEmailMessage);
                    }

                    if (!lstClaim.isempty()) {
                        Database.SaveResult[] updateResults = Database.update(lstClaim, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_OnHoldClaimsApprEvaluationBatch',
                            'execute',
                            updateResults,
                            'Case'
                        );
                    }
                }
            }
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_OnHoldClaimsApprOverchargeBatch',
				'execute',
				json.serialize(lstClaimId),
				ex
			);
		}
	}

	public void finish(Database.BatchableContext context) {
		try {
			//execution log summary
			CSX_CMP_LoggerUtility.addExecutionLog(
				'CSX_CMP_OnHoldClaimsApprOverchargeBatch',
				'Number of On Hold to open emails send ',
				'Case',
				numOfemailsforOnholdToReOpen
			);
			CSX_CMP_LoggerUtility.addExecutionLog(
				'CSX_CMP_OnHoldClaimsApprOverchargeBatch',
				'Number of On Hold Overcharge Claims evaluated ',
				'Case',
				numberofOverchargeClaimsEvaluated
			);
			CSX_CMP_LoggerUtility.addExecutionLog(
				'CSX_CMP_OnHoldClaimsApprOverchargeBatch',
				'Number of On Hold Overcharge Claims submitted for Approval ',
				'Case',
				numberofOverClaimsSubmittedforApproval
			);

			if (!claimsIdsforApprInitOvercharge.isEmpty()) {
				//invoke batch job submit for approval with batch size 1
				CSX_CMP_SubmitClaimsforApprovalBatch batchJob = new CSX_CMP_SubmitClaimsforApprovalBatch(
					claimIdsGoodforApproval
				);
				id batchJobId = Database.executeBatch(batchJob, 1);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_OnHoldClaimsApprOverchargeBatch', 'finish', JSON.serialize(context), ex);
		}
	}
}