/*
@Author       - Infosys
@Name         - CSX_CMP_GenerateDeclineLetterBatch
@Created Date - 5/7/2024
@Description  - This batch Apex is used to send emails to the claims which status gets changed to Declined
@RICEFW reference - CMP-E-0458
*/
public class CSX_CMP_GenerateDeclineLetterBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	public Map<Case, Set<String>> claimtoEmailIdsMap = new Map<Case, Set<String>>();
	public integer intFinalCount = 0;
	public List<Case> updateClaim = new List<Case>();
    Public List<Id> claimId= new List<Id>();
    Public Map<Id,Boolean> mapOfClaimToClaimContactPresent;
    Map<Id, Boolean> mapofClaimIdtoClaimContact = new Map<Id,Boolean>();
    Map<Id, CSX_CMP_Decline_Code_Master__c> declineCodeMap = new Map<Id, CSX_CMP_Decline_Code_Master__c>(
				[SELECT Id,Name, CSX_CMP_Email_Message__c FROM CSX_CMP_Decline_Code_Master__c]
			);

	public CSX_CMP_GenerateDeclineLetterBatch() {
		List<Case> declinedClaims = [
			SELECT
				Id,
				CSX_CMP_VIN__c,CSX_CMP_Decline_Code__c,
				RecordType.developerName,
				CSX_CMP_Claimant_Ref_Num__c,
				CaseNumber,CSX_CMP_Case_Number_Formula__c,
				CSX_CMP_Decline_Email_Sent_Date__c,
				(SELECT Id, CSX_CMP_Emails__c FROM Claim_Contacts__r WHERE CSX_CMP_Emails__c != ''),
				(SELECT Id FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Do not send Decline Letter'),
				(
					SELECT Id, CSX_CMP_Waybill_Date__c, CSX_CMP_Equipment_Num__c, CSX_CMP_Waybill_Num__c
					FROM Equipments__r
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM Case
			WHERE
				Type IN (
					'FC Customer Automobile Claim',
					'FC Customer Claim',
					'Transflo Claim',
					'Service Claim',
					'Incentive Claim',
					'Rev-RR - Payable Claim',
					'Rev-RR - Payable Rchg Claim'
				)
				AND Status IN ('Declined', 'Re-Declined')
				AND CSX_CMP_Decline_Email_Sent_Date__c = NULL
		];
		for (Case claim : declinedClaims) {
			//make sure do not send decline letter is not present.
			if (claim.Notes__r.isempty()) {
     
				Set<String> allClaimEmailIds = new Set<String>();  
                 if (!claim.Claim_Contacts__r.isEmpty()) {
                     mapofClaimIdtoClaimContact.put(claim.Id, true);
                     for (CSX_CMP_Claim_Contact__c clContact : claim.Claim_Contacts__r) {
                         String emailsStr = String.valueof(clContact.CSX_CMP_Emails__c);
                         List<String> emails = emailsStr.tolowerCase().split(';');
                         allClaimEmailIds.addAll(emails);
                     }
                     claimtoEmailIdsMap.put(claim, allClaimEmailIds);
                 }
                else{
                	mapofClaimIdtoClaimContact.put(claim.Id, false);
                }
			}
		}
        
         for(Case claim:declinedClaims){
            claimId.add(claim.Id);
        }
		mapOfClaimToClaimContactPresent=CSX_CMP_Utility.checkClaimContactAvailability(claimId);
        
	}

	public Iterable<SObject> start(Database.BatchableContext context) {
        
		return claimtoEmailIdsMap.keySet();
	}
	
	public void execute(Database.BatchableContext context, List<Case> lstCase) {
         
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<Messaging.SendEmailResult> emailResult = new List<Messaging.SendEmailResult>();
     
        Set<Id> casesToRemove = new Set<Id>();
       
		string claimantRef = '';
		//Date equipDate;
		String equipNum = '';
		String wayBillNum = '';
		String waybillDate;
		String vinNum = '';
		try {
			EmailTemplate emailTemplate = [
				SELECT Id, DeveloperName
				FROM EmailTemplate
				WHERE DeveloperName = 'CSX_CMP_DeclineEmailNotification' AND IsActive = TRUE
			];

			List<OrgWideEmailAddress> emails = [
				SELECT Id
				FROM OrgWideEmailAddress
				WHERE DisplayName = :System.Label.CSX_CMP_CSX_Support
			];
            //Claim is auto decline and claim contact is not present then system will not send decline email itself for those claims. 
            for (Case claim : lstCase) {
                if(declineCodeMap.containsKey(claim.CSX_CMP_Decline_Code__c) && declineCodeMap.get(claim.CSX_CMP_Decline_Code__c).Name.contains('-AD') && mapOfClaimToClaimContactPresent.get(claim.Id)==False && claim.CSX_CMP_Claim_Group__c == 'Freight'){
                       casesToRemove.add(claim.Id);
                    }
                if(mapOfClaimToClaimContactPresent.get(claim.Id)==False && claim.CSX_CMP_Claim_Group__c !='Freight'){
                       casesToRemove.add(claim.Id);
                    
                    }
            }
            List<Case> filteredCases  = new List<Case>();
            for (Case claim : lstCase) {
                    if (!casesToRemove.contains(claim.Id)) {
                        filteredCases.add(claim);
                    }
				}
            
            if(!filteredCases.isEmpty()){
                lstCase = filteredCases;
                
            }
			
			for (Case claim : lstCase) {
				CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
				List<String> toEmail = new List<String>(claimtoEmailIdsMap.get(claim));
				emailWrap.sourceRecordId = claim.Id;
				emailWrap.templateDeveloperName = 'CSX_CMP_DeclineEmailNotification';
				emailWrap.emailTemplateId = emailTemplate.Id;
				emailWrap.setOrgWideEmailAddressId = emails[0].Id;
				if (!toEmail.isEmpty()) {
					emailWrap.toEmailIdList = toEmail;
				}
				emailWrap.ccEmailIdList = null;
				emailWrap.attachmentFileName = 'Decline Letter.pdf';

				if (claim.RecordType.developerName == 'Freight') {
					emailWrap.pdfVFPageName = 'CSX_CMP_FreightDeclineLetter';
					if (String.isNotblank(claim.CSX_CMP_Claimant_Ref_Num__c)) {
						claimantRef = claim.CSX_CMP_Claimant_Ref_Num__c;
					}

					if (String.isNotBlank(claim.CSX_CMP_VIN__c)) {
						vinNum = claim.CSX_CMP_VIN__c;
					}

					CSX_CMP_Equipment__c eqipment;
					if (!claim.Equipments__r.isEmpty()) {
						eqipment = claim.Equipments__r;
						if ((String.isNotblank(eqipment.CSX_CMP_Equipment_Num__c))) {
							equipNum = eqipment.CSX_CMP_Equipment_Num__c;
						}
						if (String.isNotblank(eqipment.CSX_CMP_Waybill_Num__c)) {
							wayBillNum = eqipment.CSX_CMP_Waybill_Num__c;
						}
						if (eqipment.CSX_CMP_Waybill_Date__c != null) {
							waybillDate = CSX_CMP_Utility.formatDate(eqipment.CSX_CMP_Waybill_Date__c);
						}
					}

					emailWrap.subject =
                        'Decline Letter: ' +
						//claim.CaseNumber +
						claim.CSX_CMP_Case_Number_Formula__c +
						'- Claimant Ref #:' +
						claimantRef +
						' Car#:' +
						equipNum +
						' -Waybill#:' +
						wayBillNum +
						' -Date: ' +
						waybillDate +
						' -VIN#: ' +
						vinNum;
				} else if (claim.RecordType.developerName == 'Revenue_Contract_Refund') {
					emailWrap.pdfVFPageName = 'CSX_CMP_ContractRefundDeclineLetter';
					//emailWrap.subject = 'Decline Letter: ' +claim.CaseNumber;
					emailWrap.subject = 'Decline Letter: ' +claim.CSX_CMP_Case_Number_Formula__c;
				} else if (claim.RecordType.developerName == 'Revenue_Railroad') {
					emailWrap.pdfVFPageName = 'CSX_CMP_RevenueRailroadDeclineLetter';
					if (String.isNotblank(claim.CSX_CMP_Claimant_Ref_Num__c)) {
						claimantRef = claim.CSX_CMP_Claimant_Ref_Num__c;
					}
					emailWrap.subject = 'Decline Letter: ' +claim.CSX_CMP_Case_Number_Formula__c /*claim.CaseNumber*/ + '- Claimant Ref #:' + claimantRef;
				}
				claim.CSX_CMP_Decline_Email_Sent_Date__c = CSX_CMP_Utility.formatDate(Date.today());
				updateClaim.add(claim);

				Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(
					emailWrap
				);
				emailList.add(email);
				intFinalCount++;
			}

			if (!emailList.isEmpty()) {
				emailResult = Messaging.sendEmail(emailList);
				CSX_CMP_LoggerUtility.addApexEmailErrorLog(
					'CSX_CMP_GenerateDeclineLetterBatch',
					'execute',
					emailResult
				);
			}
			Database.SaveResult[] declineClaimEmailSentList = Database.update(updateClaim, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_GenerateDeclineLetterBatch',
				'declineClaimEmailSentList',
				declineClaimEmailSentList,
				'Case'
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_GenerateDeclineLetterBatch',
				'execute',
				JSON.serialize(lstCase),
				e
			);
		}
	}

	public void finish(Database.BatchableContext context) {
		CSX_CMP_LoggerUtility.addExecutionLog(
			'CSX_CMP_GenerateDeclineLetterBatch',
			'Number of decline/re-declined Emails sent ',
			'Case',
			intFinalCount
		);
		
		if (!updateClaim.isEmpty()) {
			
			List<Id> claimIds = new List<Id>();
			//List<Id> contentVersionIds = new List<Id>();
			for (Case claim : updateClaim) {
				claimIds.add(claim.Id);
			}
			List<EmailMessage> declineEmails = [
				SELECT
					Id,
					TextBody,
					HtmlBody,
					Subject,
					FromAddress,
					ToAddress,
					CcAddress,
					CreatedDate,
					ParentId,
					(SELECT Id, name FROM Attachments WHERE Name LIKE '%decline%')
				FROM EmailMessage
				WHERE ParentId = :claimIds AND Subject LIKE '%Decline Letter%'
			];

			CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(declineEmails);
			Database.executeBatch(uploadEmailBatch, 1);
		}
	}
}