/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRulesUtility
@Created Date - 10/18/2023
@Description  - Apex Class to simulate the business rules
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_SimulateBusinessRule {
	//This method is used in Simulate bussiness flow
	@InvocableMethod(label='Return Case & Business Rule RecordType')
	public static List<OutputValues> getCaseDetails(List<UserInput> input) {
		List<OutputValues> output = new List<OutputValues>();
		try {
			String strResponse = '';
			String claimId = input[0].strCaseId;
			String strRecordTypeName = input[0].strRecordTypeName;

			List<CSX_CMP_Business_Rule__c> lstBusinessRule = [
				SELECT Id, Name, RecordType.DeveloperName, RecordTypeId, CSX_CMP_Status__c
				FROM CSX_CMP_Business_Rule__c
				WHERE RecordType.DeveloperName = :strRecordTypeName
				WITH SECURITY_ENFORCED
			];

			strResponse = simulateRule(strRecordTypeName, null, claimId, lstBusinessRule);

			OutputValues outputValues = new OutputValues();
			outputValues.strResponse = strResponse;
			output.add(outputValues);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SimulateBusinessRule', 'getCaseDetails', String.valueOf(input), ex);
			OutputValues errorOutput = new OutputValues();
			output.add(errorOutput);
		}
		return output;
	}

	//This method is used in LWC component to get the claim
	@AuraEnabled(Cacheable=true)
	public static List<Case> getClaim() {
		List<Case> caseList = [SELECT Id, Subject FROM Case WITH SECURITY_ENFORCED];
		return caseList;
	}

	//This method is used in LWC component to get the business rule
	@AuraEnabled
	public static string getBusinessRule(Id businessId, Id claimId) {
		String strResult = '';
        
		if (String.isNotBlank(claimId) && string.isNotBlank(businessId)) {
			List<CSX_CMP_Business_Rule__c> lstBusinessRule = [
				SELECT Id, Name, RecordType.DeveloperName, RecordTypeId, CSX_CMP_Status__c
				FROM CSX_CMP_Business_Rule__c
				WHERE Id = :businessId AND CSX_CMP_Status__c = 'Valid' 
				WITH SECURITY_ENFORCED
			];
			if (lstBusinessRule.size() == 0) {
				strResult = System.label.CSX_CMP_Invalid_Status;
			} else {
				strResult = simulateRule(
					lstBusinessRule[0].RecordType.DeveloperName,
					businessId,
					claimId,
					lstBusinessRule
				);
			}
		}
		return strResult;
	}

	//This methid is used to simulate the business rule
	public static string simulateRule(
		String strRecordTypeName,
		String strBussinessRuleId,
		Id claimId,
		List<CSX_CMP_Business_Rule__c> lstBusinessRule
	) {
		string strResponse = '';
		try {
			set<Id> setOfclaimId = new Set<Id>();
			setOfclaimId.add(claimId);

			list<Case> lstCase = [SELECT id, CaseNumber FROM case WHERE id = :claimId WITH SECURITY_ENFORCED];
			if (lstBusinessRule != null && lstBusinessRule.size() > 0 && lstCase != null && lstCase.size() > 0) {
				if (strRecordTypeName == 'CSX_CMP_Auto_decline') {
					Map<Id, list<String>> mapOfClaimResult = CSX_CMP_BusinessRulesUtility.RunAutoDeclineBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);
					if (mapOfClaimResult != null && mapOfClaimResult.size() > 0) {
						List<String> lstAutoDeclineResult = mapOfClaimResult.get(claimId);

						for (String strAutoDeclineResult : lstAutoDeclineResult) {
							List<String> lstAutoDecline = strAutoDeclineResult.split('###');

							if(string.isempty(strResponse)){
								if(lstAutoDeclineResult.size() == 1){
									strResponse =  'This claim will get auto-decline for rule ' + '"' + lstAutoDecline[1]  + + '"' + ' and decline code ' +'"' + lstAutoDecline[0] + '"'; 
								}else{
									strResponse =  'This claim will get auto-decline for below rule and decline code.';
									strResponse += '\n' + '. ' + '"' + lstAutoDecline[1]  + '"' + ' - ' +'"' + lstAutoDecline[0] + '"';
								}
                            }else{
                                strResponse += '\n' + '. ' + '"' + lstAutoDecline[1] + '"' + ' - ' +'"' + lstAutoDecline[0] + '"';
                            }
						}
					}
				} else if (strRecordTypeName == 'CSX_CMP_Auto_pay_kickout') {
					Map<Id, list<String>> mapOfClaimAutoPay = CSX_CMP_BusinessRulesUtility.RunAutoPayKickoutBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);
					if (mapOfClaimAutoPay != null && mapOfClaimAutoPay.size() > 0) {
						List<String> lstAutoPayKickoutResult = mapOfClaimAutoPay.get(claimId);

						for (String strAutoPayKickoutResult : lstAutoPayKickoutResult) {
							List<String> lstAutoPayKickout = strAutoPayKickoutResult.split('###');
                            if(string.isempty(strResponse)){
								if(lstAutoPayKickoutResult.size() == 1){
									strResponse =  'This claim will get auto-pay kickout for rule ' + '"' + lstAutoPayKickout[1]  + + '"' + ' and kick code ' +'"' + lstAutoPayKickout[0] + '"'; 
								}else{
									strResponse =  'This claim will get auto-pay kickout for below rule and kick code.';
									strResponse += '\n' + '. ' + '"' + lstAutoPayKickout[1]  + '"' + ' - ' +'"' + lstAutoPayKickout[0] + '"';
								}
                            }else{
                                strResponse += '\n' + '. ' + '"' + lstAutoPayKickout[1]  + '"' + ' - ' +'"' + lstAutoPayKickout[0] + '"';
                            }
						}
					}
				} else if (strRecordTypeName == 'CSX_CMP_Claim_Desk_Assignment') {
					Map<Id, String> mapOfClaimAssignment = CSX_CMP_BusinessRulesUtility.RunClaimDeskAssignmentBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);

					if (mapOfClaimAssignment != null && mapOfClaimAssignment.size() > 0) {
						String strDeskAssignmentRule = mapOfClaimAssignment.get(claimId);
						List<String> lstDeskAssignmentResult = strDeskAssignmentRule.split('###');

                        if(string.isempty(strResponse)){
							if(mapOfClaimAssignment.size() == 1){
								strResponse =  'This claim will get auto-assignment for rule ' + '"' + lstDeskAssignmentResult[2]  + + '"' + ' and assignment desk ' +'"' + lstDeskAssignmentResult[0] + '"'; 
							}else{
								strResponse =  'This claim will get auto-assignment for below rule and asignment desk.';
								strResponse += '\n' + '. ' + '"' + lstDeskAssignmentResult[2]  + '"' + ' - ' +'"' + lstDeskAssignmentResult[2] + '"';
							}
                        }else{
                            strResponse += '\n' + '. ' + '"' + lstDeskAssignmentResult[2] + '"' + ' - ' +'"' + lstDeskAssignmentResult[0] + '"';
                        }
					}
				} else if (strRecordTypeName == 'CSX_CMP_Claim_Priority') {
					Map<Id, String> mapOfClaimPriority = CSX_CMP_BusinessRulesUtility.RunClaimPriorityBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);

					if (mapOfClaimPriority != null && mapOfClaimPriority.size() > 0) {
						String strClaimPriority = mapOfClaimPriority.get(claimId);
						List<String> lstClaimPriorityResult = strClaimPriority.split('###');
                        if(string.isempty(strResponse)){
							if(mapOfClaimPriority.size() == 1){
								strResponse =  'This claim will get identified priority ' + '"' + lstClaimPriorityResult[0]  + + '"' + ' Based on rule  ' +'"' + lstClaimPriorityResult[1] + '"'; 
							}else{
								strResponse =  'This claim will get identified for below priority Based on rule.';
								strResponse += '\n' + '. ' + '"' + lstClaimPriorityResult[0]  + '"' + ' - ' +'"' + lstClaimPriorityResult[1] + '"';
							}
                        }else{
                            strResponse += '\n' + '. ' + '"' + lstClaimPriorityResult[0] + '"' + ' - ' +'"' + lstClaimPriorityResult[1] + '"';
                        }
					}
				} else if (strRecordTypeName == 'CSX_CMP_FLR') {
					Map<String, String> mapofFLRKeytoEmailId = new Map<String, String>();
					List<CSX_CMP_FLR_Email_Master__c> flrEmails = [
						SELECT
							Id,
							Name,
							CSX_CMP_Railroad_Code__c,
							CSX_CMP_Desk_Name__c,CSX_CMP_Desk_Name__r.Name,
							CSX_CMP_Claim_Type__c,
							CSX_CMP_Email__c
						FROM CSX_CMP_FLR_Email_Master__c
						WITH SECURITY_ENFORCED
					];
					for (CSX_CMP_FLR_Email_Master__c flrEmail : flrEmails) {
						string keyCom =
							flrEmail.CSX_CMP_Claim_Type__c +
							'#' +
							flrEmail.CSX_CMP_Railroad_Code__c +
							'#' +flrEmail.CSX_CMP_Desk_Name__r.Name; // desk name field change
							//flrEmail.CSX_CMP_Desk__c;
						if (!mapofFLRKeytoEmailId.containsKey(keyCom)) {
							mapofFLRKeytoEmailId.put(keyCom, flrEmail.CSX_CMP_Email__c);
						} else {
							mapofFLRKeytoEmailId.put(keyCom, flrEmail.CSX_CMP_Email__c);
						}
					}

					List<CSX_CMP_BusinessRulesUtility.FLRClaimWrapper> lstClaimWrapper = CSX_CMP_BusinessRulesUtility.eligibleFLRClaims(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId,
						mapofFLRKeytoEmailId
					);

					if (lstClaimWrapper != null && lstClaimWrapper.size() > 0) {
						strResponse =
							'This claim satisfies FLR Rule "' +
							lstClaimWrapper[0].strBusinessRuleName +
							'"';
					}
				} else if (strRecordTypeName == 'CSX_CMP_AR_Threshold') {
					Map<Id, String> mapOfClaimResult = CSX_CMP_BusinessRulesUtility.RunARThresholdBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);

					if (mapOfClaimResult != null && mapOfClaimResult.size() > 0) {
						String strMapOfARThreshold = mapOfClaimResult.get(claimId);
						List<String> lstARThresholdResult = strMapOfARThreshold.split('###');
						strResponse =
							'This claim satisfies AR Threshold Rule "' +
							lstARThresholdResult[0] +
							'"';
					}
				} else if (strRecordTypeName == 'CSX_CMP_Approval') {
					Map<Id, list<CSX_CMP_Approval_Sequence__c>> mapOfApprovalClaims = CSX_CMP_BusinessRulesUtility.RunApprovalBusinessRules(
						setOfClaimId,
						strRecordTypeName,
						strBussinessRuleId
					);

					if (mapOfApprovalClaims != null && mapOfApprovalClaims.size() > 0) {
						list<CSX_CMP_Approval_Sequence__c> lstApproavlSequence = mapOfApprovalClaims.get(claimId);

						if (lstApproavlSequence != null && lstApproavlSequence.size() > 0) {
							for (CSX_CMP_Approval_Sequence__c objApproval : lstApproavlSequence) {
								strResponse +=
									'This claim satisfies Approval Rule with Sequence ' +
									objApproval.Name +
									' - ' +
									objApproval.CSX_CMP_Approver_Type__c +
									' - ' +
									objApproval.CSX_CMP_Approver__c +
									'';
							}
						}
					}
				} else if (strRecordTypeName == 'CSX_CMP_Duplicate') {
					Map<Id, String> mapOfDuplicateClaims = CSX_CMP_BusinessRulesUtility.runDuplicateBusinessRules(
						claimId,
						null,
						strBussinessRuleId
					);

					if (mapOfDuplicateClaims != null && mapOfDuplicateClaims.size() > 0) {
						strResponse =
							'This claim is duplicate with Claim Number ';
						string strDuplicate = '';
						for (Id targetClaimId : mapOfDuplicateClaims.keySet()) {
							if (string.isempty(strDuplicate)) {
								strDuplicate = mapOfDuplicateClaims.get(targetClaimId);
							} else {
								strDuplicate += ', ' + mapOfDuplicateClaims.get(targetClaimId);
							}
						}
						strResponse += strDuplicate;
					}
				}
			}

			if (string.isempty(strResponse)) {
				strResponse = System.label.CSX_CMP_Simulate_Default_Label;
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SimulateBusinessRule', 'SimulateRule', '', ex);
		}
		return strResponse;
	}

	//Below wrapper class used in simulate flow to get request
	public class UserInput {
		@InvocableVariable
		public String strCaseId;
		@InvocableVariable
		public String strRecordTypeName;
	}

	//Below wrapper class used in simulate flow to send response
	public class OutputValues {
		@InvocableVariable
		public String strResponse;
	}
}