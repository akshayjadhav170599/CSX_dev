/*
RICEF ID : CMP-E-0416
@author : Infosys
@description : This class is used to handle post claim creation
*/
public class CSX_CMP_PostClaimCreationQueueable implements Queueable, Database.AllowsCallouts {
	public CSX_CMP_Creation_Request__c stagingRec;
	public String activityType;

	public CSX_CMP_PostClaimCreationQueueable(String activityType, CSX_CMP_Creation_Request__c stagingRecord) {
		String stagingFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Creation_Request__c');
		Id stgId = stagingrecord.Id;
		String query = 'SELECT ' + stagingFields + ' FROM CSX_CMP_Creation_Request__c WHERE Id = :stgId';
		List<CSX_CMP_Creation_Request__c> stagingRecords = Database.query(String.escapeSingleQuotes(query));
		this.stagingRec = stagingRecords[0];
		this.activityType = activityType;
	}
	

	public void execute(QueueableContext context) {
		try {
			switch on activityType {
				when 'PostClaimCreationActions' {
					postClaimCreationActions(stagingRec);
				}
				when 'InvokeBusinessRule' {
					invokeBusinessRules(stagingRec);
				}
				when 'submitClaimforApproval' {
					submitClaimforApproval(stagingRec);
				}
				when 'UMLER' {
					System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('UMLER', stagingRec));
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_PostClaimCreationQueueable',
				'execute',
				'activityType : ' +
				activityType +
				' ' +
				string.valueOf(stagingRec),
				e
			);
		}
	}

	private static void postClaimCreationActions(CSX_CMP_Creation_Request__c stagingRec) {
		String claimRecordType;
		String claimType;
		try {
			Case caseRecord = [
				SELECT Id, CaseNumber, RecordType.DeveloperName, Type
				FROM Case
				WHERE id = :stagingRec.CSX_CMP_Claim__c
			];
			CSX_CMP_NewClaimWrapper claimInput;
			if (stagingRec.CSX_CMP_Request_Payload__c == null || stagingRec.CSX_CMP_Request_Payload__c == '') {
				claimInput = CSX_CMP_ClaimCreationHelper.getNewClaimWrapper(stagingRec.Id);
			} else {
				claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
					stagingRec.CSX_CMP_Request_Payload__c,
					CSX_CMP_NewClaimWrapper.class
				);
			}

			claimRecordType = caseRecord.RecordType.DeveloperName;
			claimType = caseRecord.Type;

			//Insert Related Claim
			// Shifting this logic to claimTriggerHandler
			if (
				stagingRec.CSX_CMP_Queueable_One_Execution_Status__c != 'Completed' ||
				stagingRec.CSX_CMP_Queueable_One_Execution_Status__c != 'Not Applicable'
			) {
				CSX_CMP_PostClaimCreationHelper.linkRelatedClaims(stagingRec);

				//Insert Checklist tasks
				CSX_CMP_PostClaimCreationHelper.createChecklistTasks(stagingRec);

				//ONLY FOR FREIGHT CLAIMS
				if (caseRecord.RecordType.DeveloperName == 'Freight') {
					//trigger total cost of claim calculation for freight
					Set<Id> totalCostCalculationIds = new Set<Id>();
					totalCostCalculationIds.add(stagingRec.CSX_CMP_Claim__c);
					CSX_CMP_TotalCostofClaimHelper.updateTotalCostOfClaim(totalCostCalculationIds);

					//insert Related L&D Reports
					CSX_CMP_PostClaimCreationHelper.linkRelatedLDReports(stagingRec);

					if (caseRecord.Type != 'Intermodal Service Claim') {
						//link inspections
						CSX_CMP_PostClaimCreationHelper.linkRelatedInspections(stagingRec);
					}
				}

				List<String> deskAndOwner = new List<String>();
				Map<Id, String> deskAssignmentResults = CSX_CMP_BusinessRulesUtility.RunClaimDeskAssignmentBusinessRules(
					new Set<Id>{ stagingRec.CSX_CMP_Claim__c },
					'CSX_CMP_Claim_Desk_Assignment',
					null
				);

				if (!deskAssignmentResults.isEmpty()) {
					if (deskAssignmentResults.containsKey(stagingRec.CSX_CMP_Claim__c)) {
						String returnedString = deskAssignmentResults.get(stagingRec.CSX_CMP_Claim__c);

						deskAndOwner = returnedString.split('###');
						caseRecord.CSX_CMP_Desk_Name__r = new CSX_CMP_Desk__c(Name = deskAndOwner[0]);
						caseRecord.OwnerId = deskAndOwner[1];
					}
				}

				Database.SaveResult updateClaimRecord = Database.update(caseRecord, false);

				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'insertNewClaim',
					updateClaimRecord,
					'Case'
				);

				// send claim creation confirmation email
				if (claimInput.sendEmail == 'true') {
					CSX_CMP_ClaimCreationHelper.sendClaimconfirmationEmail(caseRecord.Id);
					stagingRec.CSX_CMP_Confirmation_Email_Upload_Status__c = 'Pending';
				}

				stagingRec.CSX_CMP_Queueable_One_Execution_Status__c = 'Completed';
				CSX_CMP_ClaimCreationHelper.updateStagingRecord(stagingRec);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_PostClaimCreationQueueable',
				'execute',
				'activityType : PostClaimCreationActions ' + string.valueOf(stagingRec),
				e
			);
		} finally {
			if (
				claimRecordType == 'Freight' &&
				claimType != 'Intermodal Service Claim' &&
				stagingRec.CSX_CMP_Source__c != 'Manual' &&
				stagingRec.CSX_CMP_Source__c != 'FLDX'
			) {
				//invoke business rules
				enqueueJob('InvokeBusinessRule', stagingRec);
			}else if (
				claimType == 'Intermodal Service Claim' ||
				claimType == 'FC RR Inbound Claim' ||
				claimType == 'Recharges Inbound claim' || 
				claimType == 'Rev-RR - Receivable Claim' || 
				claimType == 'Rev-RR - Receivable Rchg Claim'
			) {
				// submit claim for approval
				enqueueJob('submitClaimforApproval', stagingRec);
			} else {
				//calling queueable to get details from different API calls starting with Umler
				enqueueJob('UMLER', stagingRec);
			}
		}
	}

	private static void invokeBusinessRules(CSX_CMP_Creation_Request__c stagingRec) {
		try {
			if (
				stagingRec.CSX_CMP_Autopay_Decline_Execution_Status__c != 'Completed' ||
				stagingRec.CSX_CMP_Autopay_Decline_Execution_Status__c != 'Not Applicable'
			) {
				CSX_CMP_PostClaimCreationHelper.invokeBusinessRules(stagingRec);
			}

			//calling queueable to get details from different API calls starting with Umler
			//enqueueJob('UMLER', stagingRec);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_PostClaimCreationQueueable',
				'execute',
				'activityType : InvokeBusinessRule ' + string.valueOf(stagingRec),
				e
			);
		}

		Case claim = [SELECT Id, Type FROM Case WHERE Id = :stagingRec.CSX_CMP_Claim__c WITH SECURITY_ENFORCED LIMIT 1];

		if (claim.Type == 'FC RR Inbound Claim' || claim.Type == 'Recharges Inbound claim') {
			enqueueJob('submitClaimforApproval', stagingRec);
		} else {
			enqueueJob('UMLER', stagingRec);
		}
	}

	private static void submitClaimforApproval(CSX_CMP_Creation_Request__c stagingRec) {
		try {
			CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(stagingRec.CSX_CMP_Claim__c);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_PostClaimCreationQueueable',
				'execute',
				'activityType : submitClaimforApproval ' + string.valueOf(stagingRec),
				e
			);
		} finally{
			Case claimRecordType = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :stagingRec.CSX_CMP_Claim__c WITH SECURITY_ENFORCED LIMIT 1];
			String claimId = stagingRec.CSX_CMP_Claim__c;
			String query = 'SELECT Id, Type, RecordType.DeveloperName';

			if(claimRecordType.RecordType.DeveloperName == 'Freight'){
				query += ', (SELECT Id FROM Equipments__r)';
			} else {
				query += ', (SELECT Id FROM ClaimLines__r)';
			}

			query += ' FROM Case WHERE Id = :claimId WITH SECURITY_ENFORCED LIMIT 1';

			//calling queueable to get details from different API calls starting with Umler based on child records
			Case newClaim = Database.query(String.escapeSingleQuotes(query));

			if ((newClaim.RecordType.DeveloperName == 'Freight' && !newClaim.Equipments__r.isEmpty()) || (newClaim.RecordType.DeveloperName != 'Freight' && !newClaim.ClaimLines__r.isEmpty())) {
				//calling queueable to get details from different API calls starting with Umler
				enqueueJob('UMLER', stagingRec);
			}
		}
	}

	private static void enqueueJob(String activityType, CSX_CMP_Creation_Request__c stagingRecord) {
		System.enqueueJob(new CSX_CMP_PostClaimCreationQueueable(activityType, stagingRecord));
	}
}