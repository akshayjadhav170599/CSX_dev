/*
@Author       - Infosys
@Name         - CSX_CMP_OnHoldOverchargeEmailController
@Created Date - 5/18/2024
@Description  - This Apex class is designed to retrieve and manage a list of on-hold overcharge claim details, formatted for email notifications.
@RICEFW reference - 
*/
public with sharing class CSX_CMP_OnHoldOverchargeEmailController {
	public list<CSX_CMP_claimWrapper> claimWrapperList { get; set; }
	public String customerName { get; set; }
	public Id caseId {
		get; //old class overchargeEmailControllerOnHold
		set {
			caseId = value;
			getClaimDetails();
		}
	}

	public List<CSX_CMP_claimWrapper> getclaimDetails() {
		List<Case> onHoldClaims;
		try {
			CSX_CMP_Last_Execution_Log__c executionLog = CSX_CMP_Last_Execution_Log__c.getValues(
				'CMP-I-0439_Send_onhold_email'
			);
		
			String emailString;
			if (Test.isRunningTest()) {
				emailString = '%nilesh.soni02@infosys.com%';
			} else {
				emailString = '%' + executionLog.CSX_CMP_For_System_Use_Only__c + '%';
			}

			claimWrapperList = new List<CSX_CMP_claimWrapper>();
			onHoldClaims = [
				SELECT
					Id,
					RecordType.developerName,
					CSX_CMP_Supplier_Claimant__c,
					CSX_CMP_Supplier_Claimant__r.Name,
					Status,
					Type,
					CaseNumber,CSX_CMP_Case_Number_Formula__c,
					CSX_CMP_Claim_Amount__c,
					(
						SELECT Id, Name, CSX_CMP_Emails__c
						FROM Claim_Contacts__r
						WHERE CSX_CMP_Emails__c != '' AND CSX_CMP_Emails__c LIKE :emailString
					),
					(SELECT Id FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Do not send On-Hold reminder')
				FROM Case
				WHERE RecordType.developerName = 'Revenue_Overcharge' AND Status = 'On Hold' WITH SECURITY_ENFORCED
			];

			String baseUrl = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Case/';

			for (Case claim : onHoldClaims) {
				if (claim.Notes__r.isempty() && !claim.Claim_Contacts__r.isEmpty()) {
					customerName = claim.CSX_CMP_Supplier_Claimant__r.Name;
					CSX_CMP_claimWrapper claimWrapper = new CSX_CMP_claimWrapper();
					//claimWrapper.claimNum = claim.CaseNumber;
					claimWrapper.claimNum = claim.CSX_CMP_Case_Number_Formula__c;
					claimWrapper.claimAmount = claim.CSX_CMP_Claim_Amount__c;
					claimWrapper.status = claim.Status;
					claimWrapper.claimInformation = baseUrl + claim.id + '/view';
					claimWrapperList.add(claimWrapper);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_OnHoldOverchargeReminderBatch',
				'execute',
				JSON.serialize(onHoldClaims),
				ex
			);
		}
		return claimWrapperList;
	}
	public class CSX_CMP_claimWrapper {
		public String claimNum { get; set; }
		public Decimal claimAmount { get; set; }
		public String status { get; set; }
		public String claimInformation { get; set; }
	}
}