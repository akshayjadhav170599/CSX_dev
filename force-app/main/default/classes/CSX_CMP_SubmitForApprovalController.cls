/**
@Author       - Infosys
@Name         - CSX_CMP_SubmitForApprovalController
@Created Date - 05/01/2024
@Description  - Apex Class to Submit the Case for Approval
@RICEFW reference - CMP-E-0432
*/
public with sharing class CSX_CMP_SubmitForApprovalController {
	public static boolean isValidated = true;

	//This method is used to validate all the checks and balances and submit the claim for approval
	@AuraEnabled
	public static list<OutputValues> submitForApproval(String caseId) {
		list <OutputValues> lstOutputValues = new List<OutputValues>();

		try {
			if (!string.isempty(caseId)) {
				Case objCase = [
					SELECT
						Id,
						Type,
						Status,
						CaseNumber,
						CSX_CMP_FCD_Cause_Code__c,
						CSX_CMP_FCD_Rule_Code__c,
						CSX_CMP_Remarks__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Original_Amount__c,
						CSX_CMP_Derailment__c,
						CSX_CMP_Total_Cost_of_Claim__c,
						CSX_CMP_National_Account_Num__c,
						RecordType.DeveloperName,
						CSX_CMP_Supplier_Claimant__r.Status__c,
						OwnerId,
						(SELECT Id FROM Tasks WHERE Status != 'Completed'),
						(SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Claim Amount Change Explanation')
					FROM Case
					WHERE Id = :caseId
					WITH SECURITY_ENFORCED
				];

				if (!System.isBatch()) {                    
					if(objCase.RecordType.DeveloperName == 'Freight' && objCase.OwnerId != UserInfo.getUserId()){
						OutputValues objOutputValues = new OutputValues();
						objOutputValues.strKey = 'OID';
						objOutputValues.strValue = 'Only claim owner is allowed to submit for approval.';
						objOutputValues.strValueColor = 'Red';
						objOutputValues.strErrorMessage = 'Please contact with your system admin to change the claim owner.';
						lstOutputValues.add(objOutputValues);
					}
					else{
						lstOutputValues = checkPreConditions(objCase);
						if (isValidated && objCase.RecordType.DeveloperName == 'Revenue_Overcharge') {
							//Call Fetch Latest Freight Bill Invoice Details
							map<Case, Boolean> mapofCasewithResult = CSX_CMP_SubmitClaimforApprovalHelper.updateLatestFreightBillInfofromSAP(
								new List<id>{ objCase.id }
							);
							List<Boolean> values = new List<Boolean>(mapofCasewithResult.values());
							if (values.contains(false)) {
								OutputValues objOutputValues = new OutputValues();
								objOutputValues.strKey = 'FB';
								objOutputValues.strValue = 'Claim Line amount check failed.';
								objOutputValues.strValueColor = 'Red';
								objOutputValues.strErrorMessage = System.label.CSX_CMP_Claim_Line_Amount;
								lstOutputValues.add(objOutputValues);
							} else {
								OutputValues objOutputValues = new OutputValues();
								objOutputValues.strKey = 'FB';
								objOutputValues.strValue = 'Claim Line amount check validated.';
								objOutputValues.strValueColor = 'Green';
								objOutputValues.strErrorMessage = '';
								lstOutputValues.add(objOutputValues);
							}
						}
					} 
				} else {
					//if batch execution or webservice execution
					CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(caseId);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SubmitForApprovalController',
				'submitForApproval',
				caseId,
				ex
			);
			return null;
		}
		return lstOutputValues;
	}

	//This method is used to call the AR balance api and get the result
	@AuraEnabled
	public static list<OutputValues> claimApprovalEvalutionForARBalance(string caseId) {
		list<OutputValues> lstOutputValues = new List<OutputValues>();

		try {
			if (!string.isempty(caseId)) {
				Case objCase = [
					SELECT
						Id,
						RecordType.developerName,
						CaseNumber,
						CreatedDate,
						Owner.Email,
						CSX_CMP_National_Account_Num__c,
						Status,
						Type,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_System_Action_Toggle__c
					FROM Case
					WHERE Id = :caseId
					WITH SECURITY_ENFORCED
				];

				if (objCase.RecordType.developerName == 'Revenue_Overcharge' || objCase.Type == 'Incentive Claim') {
					//Call claim approval for AR balance check
					map<string, map<Id, Boolean>> mapOfClaimWithARBalanceCheck = CSX_CMP_SubmitClaimforApprovalHelper.claimApprovalEvalutionForARBalance(
						Integer.valueof(objCase.CSX_CMP_National_Account_Num__c),
						new List<Case>{ objCase }
					);
                    
					map<Id, Boolean> mapOfClaimWithStatus = new Map<Id, Boolean>();
					if (
						mapOfClaimWithARBalanceCheck.get('Incentive') != null &&
						mapOfClaimWithARBalanceCheck.get('Incentive').size() > 0
					) {
						mapOfClaimWithStatus.putAll(mapOfClaimWithARBalanceCheck.get('Incentive'));
					} else if (
						mapOfClaimWithARBalanceCheck.get('Overcharge') != null &&
						mapOfClaimWithARBalanceCheck.get('Overcharge').size() > 0
					) {
						mapOfClaimWithStatus.putAll(mapOfClaimWithARBalanceCheck.get('Overcharge'));
					}
					if (mapOfClaimWithStatus.get(objCase.id) == false) {
						//need to change this to false mapOfClaimWithStatus.get(objCase.id) == false
						OutputValues objOutput = new OutputValues();
						objOutput.strKey = 'AR';
						objOutput.strValue = 'AR Balance above threshold.';
						objOutput.strValueColor = 'Red';
						objOutput.strErrorMessage = System.label.CSX_CMP_AR_Balance_Above_Threshold;
						lstOutputValues.add(objOutput);
					} else {
						OutputValues objOutput = new OutputValues();
						objOutput.strKey = 'AR';
						objOutput.strValue = 'AR Balance below threshold.';
						objOutput.strValueColor = 'Green';
						objOutput.strErrorMessage = '';
						lstOutputValues.add(objOutput);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SubmitForApprovalController',
				'claimApprovalEvalutionForARBalance',
				caseId,
				ex
			);
			return null;
		}
		return lstOutputValues;
	}

	//This method is used to call the business rules to get the approval conditions
	@AuraEnabled
	public static list<OutputValues> callApprovalBusinessRules(string caseId) {
		list<OutputValues> lstOutputValues = new List<OutputValues>();

		try {
			if (!string.isempty(caseId)) {
				String strResult = CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(caseId);
                system.debug('strResult::: '+strResult);
				if (strResult == 'AUTO_APPROVED') {
					OutputValues objOutput = new OutputValues();
					objOutput.strKey = 'APP';
					objOutput.strValue = 'Claim has been Auto Approved.';
					objOutput.strValueColor = 'Green';
					objOutput.strErrorMessage = '';
					lstOutputValues.add(objOutput);
				} else if (strResult == 'BTP_APPROVAL') {
					OutputValues objOutput = new OutputValues();
					objOutput.strKey = 'BTPA';
					objOutput.strValue = 'Claim successfully submitted for Approval.';
					objOutput.strValueColor = 'Green';
					objOutput.strErrorMessage = '';
					lstOutputValues.add(objOutput);
				} else if(strResult == 'Entity already exists'){
					OutputValues objOutput = new OutputValues();
					objOutput.strKey = 'EAE';
					objOutput.strValue = 'Approval Initiation Failed.';
					objOutput.strValueColor = 'Red';
					objOutput.strErrorMessage = 'Entity already exists.';
					lstOutputValues.add(objOutput);
				}else{
					OutputValues objOutput = new OutputValues();
					objOutput.strKey = 'BTPF';
					objOutput.strValue = 'Approval Initiation Failed.';
					objOutput.strValueColor = 'Red';
					objOutput.strErrorMessage = 'Error occured while sending approval initiation request to SAP BTP. Kindly contact Application support.';
					lstOutputValues.add(objOutput);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SubmitForApprovalController',
				'callApprovalBusinessRules',
				caseId,
				ex
			);
		}
		return lstOutputValues;
	}

	//This method is used to udpate the case status on hold and send the email notification to customer
	@AuraEnabled
	public static boolean updateClaimOnHold(string caseId) {
		try {
			if (!string.isempty(caseId)) {
				//CSX_CMP_Customer__r. Need to add customer email
				Case objcase = [
					SELECT
						id,
						CSX_CMP_System_Action_Toggle__c,
						CSX_CMP_AR_Balance_Check_Failed__c,
						RecordType.DeveloperName,
						(
							SELECT Id, CSX_CMP_Type__c, CSX_CMP_Emails__c
							FROM Claim_Contacts__r
							WHERE CSX_CMP_Type__c = 'Reported By'
						)
					FROM Case
					WHERE Id = :caseId
					WITH SECURITY_ENFORCED
				];

				objcase.Status = 'On Hold';
				objcase.CSX_CMP_System_Action_Toggle__c = !objcase.CSX_CMP_System_Action_Toggle__c;
				objcase.CSX_CMP_AR_Balance_Check_Failed__c = true;

				Database.SaveResult[] updateClaim = Database.update(new List<Case>{ objCase }, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_SubmitForApprovalController',
					'updateClaimOnHoldAndSendNotification',
					updateClaim,
					'caseId'
				);

				//Send the email notification to customer
				list<Messaging.SingleEmailMessage> lstSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
				CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();

				if (objcase.RecordType.DeveloperName == 'Revenue_Overcharge') {
					emailWrap.templateDeveloperName = 'CSX_CMP_OnHoldNotificationOC';
				} else {
					emailWrap.templateDeveloperName = 'CSX_CMP_OnHoldNotificationCR';
				}

				//Need to remove this UserInfo.getUserEmail() post testing
				List<String> emailList = new List<String>();

				if (objcase.Claim_Contacts__r != null && objcase.Claim_Contacts__r.size() > 0) {
					for (CSX_CMP_Claim_Contact__c objClaimCOntact : objcase.Claim_Contacts__r) {
						emailList.add(objClaimCOntact.CSX_CMP_Emails__c);
					}
				}
				
				emailWrap.toEmailIdList = emailList;
				emailWrap.sourceRecordId = caseId;
				lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
                If(!Test.isRunningTest()) {
                    if (lstSingleEmailMessage != null) {
						Messaging.sendEmail(lstSingleEmailMessage);
					}
                } else {
                    throw new DMLException();
                }
				return true;
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SubmitForApprovalController',
				'updateClaimOnHold',
				caseId,
				ex
			);
			return false;
		}
		return true;
	}

	//This method is used to evaluate the pre-condition of the claim
	public static list<OutputValues> checkPreConditions(Case objCase) {
		list<CSX_CMP_Distribution__c> lstDistribution = new List<CSX_CMP_Distribution__c>();
		list<CSX_CMP_Product__c> lstProduct = new list<CSX_CMP_Product__c>();
		list<OutputValues> lstOutputValues = new List<OutputValues>();

		//Check for Vin and Description
		boolean lstSupplierActive = false;
		if (
			objCase.CSX_CMP_Supplier_Claimant__r.Status__c == 'Active'
		) {
			lstSupplierActive = true;
		}

		//Check Product's VIN/Discription is not empty
		if (objCase.RecordType.DeveloperName == 'Freight' && system.label.CSX_CMP_Claim_Types.contains(objCase.Type)){
			list<CSX_CMP_Equipment__c> lstEquipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_Claim__c =: objCase.id
														WITH SECURITY_ENFORCED];
			if (lstEquipment != null && lstEquipment.size() > 0) {
				lstDistribution = [SELECT id
									FROM CSX_CMP_Distribution__c
									WHERE CSX_CMP_Equipment__c IN : lstEquipment
									WITH SECURITY_ENFORCED];
			}

			if (lstEquipment != null && lstEquipment.size() > 0) {
				lstProduct = [SELECT Id, CSX_CMP_VIN__c, CSX_CMP_Product_Description__c
								FROM CSX_CMP_Product__c
								WHERE CSX_CMP_Equipment__c IN : lstEquipment
								WITH SECURITY_ENFORCED
				];
			}

			// Check on derailment claim if checked
			if (objCase.CSX_CMP_Derailment__c == true) {
				list<CSX_CMP_Related_LD_Report__c> lstRelatedLDReport = [SELECT id FROM CSX_CMP_Related_LD_Report__c 
																			WHERE CSX_CMP_Claim__c =: objCase.id
																			WITH SECURITY_ENFORCED];

				if (lstRelatedLDReport != null && lstRelatedLDReport.size() > 0) {
					OutputValues objOutputValues = new OutputValues();
					objOutputValues.strKey = 'LR';
					objOutputValues.strValue = 'L&D Report check validated.';
					objOutputValues.strValueColor = 'Green';
					objOutputValues.strErrorMessage = '';
					lstOutputValues.add(objOutputValues);
				} else {
					OutputValues objOutputValues = new OutputValues();
					objOutputValues.strKey = 'LR';
					objOutputValues.strValue = 'L&D Report check failed.';
					objOutputValues.strValueColor = 'Red';
					objOutputValues.strErrorMessage = System.label.CSX_CMP_LD_Report_Should_Present;
					lstOutputValues.add(objOutputValues);
					isValidated = false;
				}
			}

			//Check FCD Rule and Clause code
			if (string.isempty(objCase.CSX_CMP_FCD_Cause_Code__c) || string.isempty(objCase.CSX_CMP_FCD_Rule_Code__c)) {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'FCDRule';
				objOutputValues.strValue = 'FCD Rule Code & Clause Code check failed.';
				objOutputValues.strValueColor = 'Red';
				objOutputValues.strErrorMessage = System.label.CSX_CMP_FCD_Rule_Code;
				lstOutputValues.add(objOutputValues);
				isValidated = false;
			} else {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'FCDRule';
				objOutputValues.strValue = 'FCD Rule Code & Clause Code check validated.';
				objOutputValues.strValueColor = 'Green';
				objOutputValues.strErrorMessage = '';
				lstOutputValues.add(objOutputValues);
			}
			
			if (!lstProduct.isEmpty()) {
				boolean isDescriptionOrVinEmpty = false;

				for (CSX_CMP_Product__c objProduct : lstProduct) 
				{
					if((objCase.Type == 'FC Customer Automobile Claim' || objCase.Type == 'FC Customer Claim') && string.isempty(objCase.CSX_CMP_Remarks__c)){
						isDescriptionOrVinEmpty = true;
						break;
					}
					else if(objCase.Type == 'FC Customer Claim' && !string.isempty(objCase.CSX_CMP_Remarks__c) && string.isempty(objProduct.CSX_CMP_Product_Description__c)) {
						isDescriptionOrVinEmpty = true;
						break;
					} 
					else if(objCase.Type == 'FC Customer Automobile Claim' && !string.isempty(objCase.CSX_CMP_Remarks__c) && string.isempty(objProduct.CSX_CMP_VIN__c)){
						isDescriptionOrVinEmpty = true;
						break;
					}
				}

				if(!isDescriptionOrVinEmpty){
					OutputValues objOutputValues = new OutputValues();
					objOutputValues.strKey = 'PIV';
					objOutputValues.strValue = 'Product Identifier & Remarks check validated.';
					objOutputValues.strValueColor = 'Green';
					objOutputValues.strErrorMessage = '';
					lstOutputValues.add(objOutputValues);
				}else{
					OutputValues objOutputValues = new OutputValues();
					objOutputValues.strKey = 'PIV';
					objOutputValues.strValue = 'Product Identifier & Remarks check failed.';
					objOutputValues.strValueColor = 'Red';
					objOutputValues.strErrorMessage = System.label.CSX_CMP_Product_Identifier_And_Remarks_Available;
					lstOutputValues.add(objOutputValues);
					isValidated = false;
				}
			}
				

			// Check for distribution record is present
			if (lstDistribution != null && lstDistribution.size() > 0) {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'DR';
				objOutputValues.strValue = 'Distribution check validated.';
				objOutputValues.strValueColor = 'Green';
				objOutputValues.strErrorMessage = '';
				lstOutputValues.add(objOutputValues);
			} else {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'DR';
				objOutputValues.strValue = 'Distribution check failed.';
				objOutputValues.strValueColor = 'Red';
				objOutputValues.strErrorMessage = System.label.CSX_CMP_Distribution_Should_Be_Present;
				lstOutputValues.add(objOutputValues);
				isValidated = false;
			}


		}

		if(objCase.RecordType.DeveloperName == 'Freight' && system.label.CSX_CMP_Claim_Type_for_Total_Cost.contains(objCase.Type)){
			//Total Cost is Valid
			if (objCase.CSX_CMP_Total_Cost_of_Claim__c != null && objCase.CSX_CMP_Total_Cost_of_Claim__c < 0) {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'TC';
				objOutputValues.strValue = 'Total cost of claim check failed.';
				objOutputValues.strValueColor = 'Red';
				objOutputValues.strErrorMessage = System.label.CSX_CMP_Total_Cost_of_Claim_Amount;
				lstOutputValues.add(objOutputValues);
				isValidated = false;
			} else {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'TC';
				objOutputValues.strValue = 'Total cost of claim check validated.';
				objOutputValues.strValueColor = 'Green';
				objOutputValues.strErrorMessage = '';
				lstOutputValues.add(objOutputValues);
			}
		}
        
		//Check for Tasks not in completed stage
		if (objCase.Tasks != null && objCase.Tasks.size() > 0) {
			OutputValues objOutputValues = new OutputValues();
			objOutputValues.strKey = 'CT';
			objOutputValues.strValue = 'Checklist Task Completion failed.';
			objOutputValues.strValueColor = 'Red';
			objOutputValues.strErrorMessage = System.label.CSX_CMP_All_Check_List_Task_Completed;
			lstOutputValues.add(objOutputValues);
			isValidated = false;
		} else {
			OutputValues objOutputValues = new OutputValues();
			objOutputValues.strKey = 'CT';
			objOutputValues.strValue = 'Checklist Task Completion validated.';
			objOutputValues.strValueColor = 'Green';
			objOutputValues.strErrorMessage = '';
			lstOutputValues.add(objOutputValues);
		}

		//Check for Claim status
		if (!string.isempty(objCase.Status) && (objCase.Status == 'Open' || objCase.Status == 'Re-Opened')) {
			OutputValues objOutputValues = new OutputValues();
			objOutputValues.strKey = 'CS';
			objOutputValues.strValue = 'Claim Status Check validated.';
			objOutputValues.strValueColor = 'Green';
			objOutputValues.strErrorMessage = '';
			lstOutputValues.add(objOutputValues);
		} else {
			OutputValues objOutputValues = new OutputValues();
			objOutputValues.strKey = 'CS';
			objOutputValues.strValue = 'Claim Status Check failed.';
			objOutputValues.strValueColor = 'Red';
			objOutputValues.strErrorMessage = System.label.CSX_CMP_Claim_Status_Open_Re_Opened;
			lstOutputValues.add(objOutputValues);
			isValidated = false;
		}
		
		//Check for Claim Amount is equal to Original Amount
		if (
			objCase.CSX_CMP_Claim_Amount__c != null &&
			objCase.CSX_CMP_Original_Amount__c != null &&
			objCase.CSX_CMP_Claim_Amount__c != objCase.CSX_CMP_Original_Amount__c
		) {
			if (objCase.Notes__r != null && objCase.Notes__r.size() > 0) {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'CA';
				objOutputValues.strValue = 'Payment Amount check validated.';
				objOutputValues.strValueColor = 'Green';
				objOutputValues.strErrorMessage = '';
				lstOutputValues.add(objOutputValues);
			} else {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'CA';
				objOutputValues.strValue = 'Payment Amount check failed.';
				objOutputValues.strValueColor = 'Red';
				objOutputValues.strErrorMessage = System.label.CSX_CMP_Payment_Amount_Approval;
				lstOutputValues.add(objOutputValues);
				isValidated = false;
			}
		} else {
			OutputValues objOutputValues = new OutputValues();
			objOutputValues.strKey = 'CA';
			objOutputValues.strValue = 'Payment Amount check validated.';
			objOutputValues.strValueColor = 'Green';
			objOutputValues.strErrorMessage = '';
			lstOutputValues.add(objOutputValues);
		}

		//Check Supplier site is Active
		if(objCase.Type != 'FC Salvage Claim'){
			if (lstSupplierActive) {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'SS';
				objOutputValues.strValue = 'Active supplier site check is validated.';
				objOutputValues.strValueColor = 'Green';
				objOutputValues.strErrorMessage = '';
				lstOutputValues.add(objOutputValues);
			} else {
				OutputValues objOutputValues = new OutputValues();
				objOutputValues.strKey = 'SS';
				objOutputValues.strValue = 'Kindly associate active supplier site to proceed.';
				objOutputValues.strValueColor = 'Red';
				objOutputValues.strErrorMessage = System.label.CSX_CMP_Supplier_Site_Active;
				lstOutputValues.add(objOutputValues);
				isValidated = false;
			}
		}
		return lstOutputValues;
	}

	//This method is used to check the Product VIN and Descrition
	// public static boolean checkVinAndDiscription(Case objCase) {
	// 	if (objCase.Equipments__r != null && objCase.Equipments__r.size() > 0) {
	// 		list<CSX_CMP_Product__c> lstProduct = [
	// 			SELECT Id, CSX_CMP_VIN__c, CSX_CMP_Product_Description__c
	// 			FROM CSX_CMP_Product__c
	// 			WHERE CSX_CMP_Equipment__c = :objCase.Equipments__r[0].Id
	// 			WITH SECURITY_ENFORCED
	// 		];

	// 		if (lstProduct != null && lstProduct.size() > 0) {
	// 			if (lstProduct[0].CSX_CMP_VIN__c == null && lstProduct[0].CSX_CMP_Product_Description__c == null) {
	// 				return true;
	// 			}
	// 		}
	// 	}
	// 	return false;
	// }

	//Below wrapper class used in simulate flow to send response
	public class OutputValues {
		@AuraEnabled
		public String strKey;
		@AuraEnabled
		public String strValue;
		@AuraEnabled
		public String strValueColor;
		@AuraEnabled
		public String strErrorMessage;
	}
}