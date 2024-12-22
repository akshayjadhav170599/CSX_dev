/**
@author       - Infosys
@name         - CSX_CMP_ClaimTriggerHandler
@createdDate - 10/20/2023
@description  - Apex trigger handle on Claim/Case object
*/
public with sharing class CSX_CMP_ClaimTriggerHandler {
	public static Boolean settlementCreated = false;
	/*
    @description - Method to take care of before insert logic
    @param newClaimList - List of new claims
    */
	// public static void handleBeforeInsert(List<Case> newClaimList) {
	// 	try {
	// 	} catch (Exception ex) {
	// 		CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimTriggerHandler','handleBeforeInsert',JSON.serialize(newClaimList),ex);
	// 	}
	// }
	/*
    @description - Method to take care of after insert logic
    @param newClaimsMap - Map of new claims
    */
	public static void handleAfterInsert(Map<Id, Case> newClaimsMap) {
		try {
			List<Case> claimsforAPSettlement = new List<Case>();
			List<Case> claimsforARSettlement = new List<Case>();
			Map<String, Id> distIdtoClaimIdMap = new Map<String, Id>(); //Map used to update distribution records with updated claim #
			//Map<Id, String> caseOldIDToNewIDMap = new Map<Id, String>(); //Map used to create related claims
			Map<Id, List<String>> caseOldIDToNewIDMap = new Map<Id, List<String>>(); //Map used to create related claims
			Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();
			Set<Id> claimIdsforTotalCostofClaim = new Set<Id>(); // claim ids for which total cost of claim needs to be updated
			Set<Id> childClaimIdsforTotalCostofClaim = new Set<Id>(); //child claim ids to later fetch parent claim ids for total cost of claim recalculation
			List<Id> claimsforEDI926Creation = new List<Id>();
			List<Case> claimMapToCreateRelatedClaimsPostCreation = new List<Case>();

			for (Case claim : newClaimsMap.values()) {
				String recordTyName = rtMap.get(claim.RecordTypeId).getName();
				//to identify claim for EDI process
				if (claim.Origin == 'EDI' && claim.Status == 'New') {
					claimsforEDI926Creation.add(claim.id);
				}
				//to identify claims for total cost of claim calculation
				if (recordTyName == 'Freight') {
					// 6-June Changes | Start - for total cost of claim calculation
					List<String> claimTypes = System.Label.CSX_CMP_Total_Cost_Calculation_Claim_Types.split(',');
					if (claimTypes.contains(claim.Type)) {
						claimIdsforTotalCostofClaim.add(claim.Id);
					}

					if (claim.Type == 'FC RR Outbound Claim' || claim.Type == 'Recharges Outbound Claim') {
						childClaimIdsforTotalCostofClaim.add(claim.Id);
					}
					// 6-June Changes | End - for total cost of claim calculation
				}

				if (
					claim.Status == 'Pending Close' &&
					claim.CSX_CMP_Claim_Amount__c != null &&
					claim.CSX_CMP_Claim_Amount__c != 0
				) {
					if (claim.CSX_CMP_Claim_Amount__c > 0) {
						claimsforAPSettlement.add(claim);
					} else {
						claimsforARSettlement.add(claim);
					}
				}
				//to identify distrubutions records to link to Parent claim and create related claim records
				if (
					(claim.Type == 'FC RR Outbound Claim' && claim.CSX_CMP_Distribution_Id__c != null) ||
					(claim.Type == 'Recharges Outbound Claim')
				) {
					String parentId = claim.CSX_CMP_External_Id__c != null
						? claim.CSX_CMP_External_Id__c.substringBefore('_')
						: null;
					//10 May changes | Start
					// caseOldIDToNewIDMap.put(claim.Id, parentId);
					// caseOldIDToNewIDMap.put(parentId, claim.Id);

					//List<String> parentIdList = new List<String>();
					//parentIdList.add(parentId);
					if (!caseOldIDToNewIDMap.containsKey(claim.Id)) {
						caseOldIDToNewIDMap.put(claim.Id, new List<String>{ parentId });
					} else {
						caseOldIDToNewIDMap.get(claim.Id).add(parentId);
					}
					//caseOldIDToNewIDMap.put(claim.Id,parentIdList);
					//10 May changes | End
					if (claim.Type == 'FC RR Outbound Claim' && claim.CSX_CMP_Distribution_Id__c != null) {
						distIdtoClaimIdMap.put(claim.CSX_CMP_Distribution_Id__c, claim.Id);
					}
				} else {
					claimMapToCreateRelatedClaimsPostCreation.add(claim);
				}
			}

			// if(!claimMapToCreateRelatedClaimsPostCreation.isEmpty() && claimMapToCreateRelatedClaimsPostCreation.size() == 0){
			//     //create related claim records for distribution claim and recharge claims
			//     CSX_CMP_ClaimTriggerHelper.createRelatedClaimPostCreation(claimMapToCreateRelatedClaimsPostCreation);
			// }

			if (!claimsforEDI926Creation.isEmpty()) {
				CSX_CMP_CreateEDI926RecordController.createEDI926StagingRecord(claimsforEDI926Creation);
			}

			if (!claimsforAPSettlement.isEmpty()) {
				CSX_CMP_SettlementUtility.createAPSettlements(claimsforAPSettlement);
			}

			if (!claimsforARSettlement.isEmpty()) {
				CSX_CMP_SettlementUtility.createARSettlements(claimsforARSettlement);
			}

			if (!caseOldIDToNewIDMap.isEmpty()) {
				//create related claim records for distribution claim and recharge claims
				CSX_CMP_Utility.createRelatedClaim(caseOldIDToNewIDMap); //10 May changes
			}

			if (!distIdtoClaimIdMap.isEmpty()) {
				// invoke logic to update new Claim Id on source distribution records.
				CSX_CMP_ClaimTriggerHelper.updateDistributionwithClaimId(distIdtoClaimIdMap);
			}

			//fetch parent claims ids for total cost of claim recalc
			if (!childClaimIdsforTotalCostofClaim.isEmpty()) {
				Set<Id> parentClaimIds = CSX_CMP_TotalCostofClaimHelper.identifyParentClaimsforTotalCostCalc(
					childClaimIdsforTotalCostofClaim
				);
				if (!parentClaimIds.isEmpty()) {
					claimIdsforTotalCostofClaim.addAll(parentClaimIds);
				}
			}

			if (!claimIdsforTotalCostofClaim.isEmpty()) {
				CSX_CMP_TotalCostofClaimHelper.updateTotalCostOfClaim(claimIdsforTotalCostofClaim);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimTriggerHandler','handleAfterInsert',JSON.serialize(newClaimsMap),ex);
		}
	}

	/*
    @description - Method to take care of before update logic
    @param newClaimsMap - Map of new claims
    @param oldClaimsMap - Map of old claims
    */
	public static void handleBeforeUpdate(Map<Id, Case> newClaimsMap, Map<Id, Case> oldClaimsMap) {
		try {
			List<Id> cancelledClaims = new List<Id>();
			List<Id> declinedClaims = new List<Id>(); 
			List<Id> unAuthorizedChanges = new List<Id>();

			User currentUser = [SELECT Id, Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
			String userRole = currentUser.UserRole.Name;
			Map<Id, CSX_CMP_Decline_Code_Master__c> declineCodeMap = new Map<Id, CSX_CMP_Decline_Code_Master__c>(
				[SELECT Id,Name, CSX_CMP_Email_Message__c FROM CSX_CMP_Decline_Code_Master__c]
			);

			for (Case claim : newClaimsMap.values()) {
				Case oldClaim = oldClaimsMap.get(claim.Id);
				if (claim.CSX_CMP_Unread_Email__c == true && oldClaim.CSX_CMP_Unread_Email__c == true) {
					claim.CSX_CMP_Unread_Email__c = false;
				}
				if (claim.CSX_CMP_Unread_Documents__c == true && oldClaim.CSX_CMP_Unread_Documents__c == true) {
					claim.CSX_CMP_Unread_Documents__c = false;
				}
				if (oldClaim.status == 'On Hold' && oldClaim.status != claim.status) {
					claim.CSX_CMP_AR_Balance_Check_Failed__c = false;
				}

				if (claim.Status == 'Cancelled' && oldClaim.Status != 'Cancelled') {
					if(userRole.contains('Freight') && !userRole.contains('Manager') && claim.Origin == 'Distribution'){
						claim.addError('Freight claim user can not cancel the distribution claim.');
					}else{
						cancelledClaims.add(claim.Id);
					}
				}

				if (
					(claim.Status == 'Declined' && oldClaim.Status != 'Declined') ||
					(claim.Status == 'Re-Declined' &&
					oldClaim.Status != 'Re-Declined')
				) {
					declinedClaims.add(claim.Id);
				}

				if (
					(oldClaim.Status == 'Declined' ||
					oldClaim.Status == 'Re-Declined' || oldClaim.Status == 'Pending Close') &&
					oldClaim.Status != claim.Status &&
					claim.Status == 'Re-Opened'
				) {
					claim.CSX_CMP_Settled_Date__c = null;
				}
				// if (((claim.Status != 'Declined') && (claim.Status != 'Re-Declined'))) {
				// 	claim.CSX_CMP_Decline_Email_Sent_Date__c = null;
				// }
				if (
					(claim.Status == 'Declined' || claim.Status == 'Re-Declined' || claim.Status == 'Pending Close') &&
					oldClaim.Status != claim.Status
				) {
					claim.CSX_CMP_Settled_Date__c = Date.today();
					//updateSettledDate.add(claim.id);
				}
				if (
					(oldClaim.Status == 'Declined' ||
					oldClaim.Status == 'Re-Declined') &&
					claim.Status == 'Re-Opened' &&
					oldClaim.Status != claim.Status
				) {
					claim.CSX_CMP_Resubmission_Date__c = Date.today();
					claim.CSX_CMP_Decline_Email_Sent_Date__c = null;
					//updateSettledDate.add(claim.id);
				}

				Boolean isAuthorized = CSX_CMP_ClaimTriggerHelper.isAuthorizedChange(oldClaim, claim, userRole);
				system.debug('isAuthorized: ' + isAuthorized);
				if (!isAuthorized && oldClaim.CSX_CMP_System_Action_Toggle__c == claim.CSX_CMP_System_Action_Toggle__c) {
					unAuthorizedChanges.add(claim.Id);
				}
				system.debug('comments in before : '+claim.Comments);
			}

			if (!cancelledClaims.isEmpty()) {
				Map<Id, DateTime> mapofClaimIdtoNotesCreatedDate = CSX_CMP_Utility.checkNotesAvailability(
					cancelledClaims,
					'Cancellation Reason'
				);
				for (Id claimId : cancelledClaims) {
					if (!mapofClaimIdtoNotesCreatedDate.containsKey(claimId)) {
						newClaimsMap.get(claimId)
							.addError('Please add a cancellation reason in Notes section to proceed with Cancellation.');
					}
				}
			}
			// CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
			// boolean check = objByPassRule.CSX_CMP_Apex_Triggers__c;
			// Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

			// if (!unAuthorizedChanges.isEmpty() && !check && UserInfo.getProfileId() != sysAdmin.Id) {
			if (!unAuthorizedChanges.isEmpty()) {
				for (Id claimId : unAuthorizedChanges) {
					newClaimsMap.get(claimId).addError('Unauthorized changes detected. Please contact your administrator.');
				}
			}

			if (!declinedClaims.isEmpty()) {
				Map<Id, DateTime> mapofClaimIdtoNotesCreatedDate = CSX_CMP_Utility.checkNotesAvailability(
					declinedClaims,
					'Decline Reason'
				);
                Map<Id,Boolean> mapOfClaimToClaimContactPresent= CSX_CMP_Utility.checkClaimContactAvailability(declinedClaims);
                
				for (Id claimId : declinedClaims) {
					Case newClaim = newClaimsMap.get(claimId);   							 
					String errorMessage = '';
                    if ((!mapofClaimIdtoNotesCreatedDate.containsKey(claimId)) && newClaim.CSX_CMP_Claim_Group__c != 'Freight') {
						errorMessage = 'Please add a decline reason in Notes section to proceed with declination.';
					}
					if ((!mapofClaimIdtoNotesCreatedDate.containsKey(claimId)) && newClaim.CSX_CMP_Claim_Group__c != 'Freight' && ((declineCodeMap.containsKey(newClaim.CSX_CMP_Decline_Code__c)) && (!declineCodeMap.get(newClaim.CSX_CMP_Decline_Code__c).Name.contains('-AD')))) {
						errorMessage = 'Please add a decline reason in Notes section to proceed with declination.';
					}

					if ( newClaim.CSX_CMP_Claim_Group__c =='Freight' &&
						(!declineCodeMap.get(newClaim.CSX_CMP_Decline_Code__c).Name.contains('-AD'))   && 
						String.isBlank(declineCodeMap.get(newClaim.CSX_CMP_Decline_Code__c).CSX_CMP_Email_Message__c) &&
						String.isBlank(errorMessage) 
                    )  {
                        if (!mapofClaimIdtoNotesCreatedDate.containsKey(claimId)) {
						errorMessage = 'Please add a decline reason in Notes section to proceed with declination.';
					}
                    }
                    if(mapOfClaimToClaimContactPresent.get(claimId)==False){
                        errorMessage=+ 'Please add a Claim Contact in Claim Contact section to proceed with declination.';
                    }

					if (
                        
						newClaimsMap.get(claimId).Status == 'Re-Declined' &&
						mapofClaimIdtoNotesCreatedDate.get(claimId) > newClaim.CSX_CMP_Resubmission_Date__c &&
						String.isBlank(errorMessage)
					) {
						errorMessage = 'Please add a decline reason in Notes section to proceed with declination.';
					}					
					if (String.isNotBlank(errorMessage)) {
						newClaim.addError(errorMessage);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('ex.getStackTraceString() '+ ex.getStackTraceString(),'ex.getMessage() '+ex.getLineNumber()+'ex.getMessage() '+ex.getMessage()+' ex.getTypeName()'+ex.getTypeName(),JSON.serialize(newClaimsMap),ex);			
		}
	}

	/*
    @description - Method to take care of after update logic
    @param newClaimsMap - Map of new claims
    @param oldClaimsMap - Map of old claims
    Modification Log:
    Date        Name        Description
    21/05/2024  Subodh      Added logic to handle status change for Intermodal Service Claim and send update to Customer Service
    */
	public static void handleAfterUpdate(Map<Id, Case> newClaimsMap, Map<Id, Case> oldClaimsMap) {
		try {
			List<Id> generateEmailForDeclineLetter = new List<Id>();
			List<Id> generateEmailForDecLetter = new List<Id>();
			//List<Id> updateSettledDate = new List<Id>();
			// List<Id> resetSettledDate = new List<Id>();
			List<Case> claimsforAPSettlement = new List<Case>();
			List<Case> claimsforARSettlement = new List<Case>();
			List<Case> claimsforContractBudget = new List<Case>();
			List<Case> claimsforBudgetCheck = new List<Case>();
			Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();
			Set<Id> claimIdsforTotalCostofClaim = new Set<Id>(); // claim ids for which total cost of claim needs to be updated
			Set<Id> childClaimIdsforTotalCostofClaim = new Set<Id>(); //child claim ids to later fetch parent claim ids for total cost of claim recalculation
			List<Id> claimsforEDI926Creation = new List<Id>(); //collect ids for EDI Process
			List<Id> cancelledDistributionIds = new List<Id>(); //collect ids for Distribution
			List<Id> closedClaimsForServicePeriodUpdate = new List<Id>(); //collect ids for service period update on distribution claims
			List<Id> cancelledSalvageClaimIds = new List<Id>(); //collect ids for Salvage Claim which are cancelled
			List<Id> collectStatusChangeClaimIds = new List<Id>(); //collect ids for status change of Intermodal Service Claim
			set<Id> setofPMSClaimID = new Set<Id>();
			Set<Id> closureEmailIds = new Set<Id>();
			Set<Id> updatePaidAmountOnRelatedLDR = new Set<Id>();

			for (Case claim : newClaimsMap.values()) {
				String recordTyName = rtMap.get(claim.RecordTypeId).getName();
				Case oldClaim = oldClaimsMap.get(claim.Id);
				List<String> claimTypes = System.Label.CSX_CMP_Total_Cost_Calculation_Claim_Types.split(',');
				Boolean isTotalCostCalculation = false;
				for (String claimType : claimTypes) {
					if (claim.Type == claimType) {
						isTotalCostCalculation = true;
						// break;
					}
				}

				if (
					(claim.Type == 'Rev-RR - Payable Claim' ||
					claim.Type == 'Rev-RR - Payable Rchg Claim') &&
					oldClaim.status != claim.status &&
					claim.status == 'Pending Monthly Settlement'
				) {
					setofPMSClaimID.add(claim.Id);
				}

				//to identify claims for total cost of claim calculation
				if (recordTyName == 'Freight') {
					// List<String> claimTypes = System.Label.CSX_CMP_Total_Cost_Calculation_Claim_Types.split(',');
					// 6-June Changes | Start - for total cost of claim calculation
					if (
						(oldClaim.CSX_CMP_Claim_Amount__c != claim.CSX_CMP_Claim_Amount__c ||
						oldClaim.Status != claim.Status ||
						oldClaim.CSX_CMP_Project_Amount__c != claim.CSX_CMP_Project_Amount__c ||
						oldClaim.CSX_CMP_Salvage_Amount__c != claim.CSX_CMP_Salvage_Amount__c ||
						oldClaim.CSX_CMP_Freight_Revenue_Amount__c != claim.CSX_CMP_Freight_Revenue_Amount__c) &&
						isTotalCostCalculation
					) {
						claimIdsforTotalCostofClaim.add(claim.Id);
						// 6-June Changes | End - for total cost of claim calculation
					}
					if (claim.Type == 'FC RR Outbound Claim' || claim.Type == 'Recharges Outbound Claim') {
						childClaimIdsforTotalCostofClaim.add(claim.Id);
					}

					if (
						claim.Origin == 'Customer Service' &&
						claim.Type == 'Intermodal Service Claim' &&
						oldClaim.Status != claim.Status &&
						(claim.Status == 'Closed' ||
						claim.Status == 'Pending Close' ||
						claim.Status == 'Rejected' ||
						claim.Status == 'Pending Approval')
					) {
						collectStatusChangeClaimIds.add(claim.Id);
					}
					//collect ids for EDI Process
					if (
						claim.Origin == 'EDI' &&
						oldClaim.Status != claim.Status &&
						(Claim.Status == 'New' ||
						Claim.Status == 'Declined' ||
						Claim.Status == 'Closed' ||
						Claim.Status == 'Re-Declined' ||
						Claim.Status == 'Cancelled')
					) {
						claimsforEDI926Creation.add(claim.id);
					}

					if (
						claim.Status == 'Cancelled' &&
						oldClaim.Status != 'Cancelled' &&
						claim.Type == System.Label.CSX_CMP_Type_For_Salvage_Claim
					) {
						cancelledSalvageClaimIds.add(claim.Id);
					}

					//collect ids to populate service period on distribution claims
					List<String> claimTypesForServicePeriodUpdate = System.Label.CSX_CMP_Applicable_Claim_Types_For_Distribution_Claim.split(',');
					if (claim.Status != oldClaim.Status && claim.Status == 'Closed' && claimTypesForServicePeriodUpdate.contains(claim.Type)) {
						closedClaimsForServicePeriodUpdate.add(claim.Id);
					}

					// collect ids for related LDR to update paid amount
					if(
						(claim.Status == 'Pending Close' && oldClaim.Status != 'Pending Close') ||
						(claim.Status == 'Closed' && oldClaim.Status != 'Closed')
					){
						updatePaidAmountOnRelatedLDR.add(claim.Id);
					}
				}

				/*if((claim.Status == 'Closed' && oldClaim.Status!='Closed') || (claim.Status == 'Pending Close' && oldClaim.Status!='Pending Close')  ){
                        updateCloseDate.add(claim.id);
                    }*/

				if (recordTyName == 'Overcharge') {
					if (
						(claim.Status == 'Declined' && oldClaim.Status != 'Declined') ||
						(claim.Status == 'Re-Declined' &&
						oldClaim.Status != 'Re-Declined')
					) {
						generateEmailForDeclineLetter.add(claim.id);
					}
				}

				if (recordTyName == 'Contract Refund') {
					if (
						(claim.CSX_CMP_Contract_Num__c != null) &&
						((claim.Status == 'Pending Close') || (claim.Status == 'Closed' && oldClaim.Status != 'Pending Close'))
					) {
						//CSX_CMP_ContractBudgetHandler.updateConsumedBudget
						claimsforContractBudget.add(claim);
					}

					if (
						(claim.CSX_CMP_Contract_Num__c != null) &&
						(claim.CSX_CMP_Claim_Amount__c > oldClaim.CSX_CMP_Claim_Amount__c)
					) {
						//CSX_CMP_ContractBudgetHandler.updateConsumedBudget
						claimsforBudgetCheck.add(claim);
					}
				}

				if (oldClaim.Status != claim.Status && claim.Status == 'Closed') {
					closureEmailIds.add(claim.id);
				}

				if (recordTyName == 'Freight') {
					if (claim.Origin == 'Distribution' && oldClaim.Status != claim.Status && Claim.Status == 'Cancelled') {
						cancelledDistributionIds.add(claim.id);
					}
				}

				if (
					claim.Status == 'Pending Close' &&
					oldClaimsMap.get(claim.Id).Status != 'Pending Close' &&
					claim.CSX_CMP_Claim_Amount__c != null &&
					claim.CSX_CMP_Claim_Amount__c != 0 &&
					!settlementCreated
				) {
					settlementCreated = true;
					if (claim.CSX_CMP_Claim_Amount__c > 0) {
						claimsforAPSettlement.add(claim);
					} else {
						claimsforARSettlement.add(claim);
					}
				}
				system.debug('comments : '+claim.Comments);
			}

			if (!setofPMSClaimID.isEmpty() && setofPMSClaimID.size() > 0) {
				CSX_CMP_ClaimTriggerHelper.sendLOALetter(setofPMSClaimID);
			}

			if (!generateEmailForDeclineLetter.isEmpty()) {
				List<Case> declineLetterClaim = [
					SELECT Id, (SELECT Id FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Do not send Decline Letter')
					FROM Case
					WHERE ID IN :generateEmailForDeclineLetter
					WITH SECURITY_ENFORCED
				];

				for (Case cc : declineLetterClaim) {
					if (cc.Notes__r.isempty()) {
						generateEmailForDecLetter.add(cc.Id);
					}
				}
				//ID jobID = System.enqueueJob(new CSX_CMP_OverchargeDeclineEmailQueueable(generateEmailForDecLetter));
				CSX_CMP_ClaimTriggerHelper.emailDeclineLetter(generateEmailForDecLetter);
			}
			/*if (!updateSettledDate.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.updateSettledDate(updateSettledDate);
			}*/

			if (!claimsforAPSettlement.isEmpty()) {
				CSX_CMP_SettlementUtility.createAPSettlements(claimsforAPSettlement);
			}

			if (!claimsforARSettlement.isEmpty()) {
				CSX_CMP_SettlementUtility.createARSettlements(claimsforARSettlement);
			}

			//fetch parent claims ids for total cost of claim recalc
			if (!childClaimIdsforTotalCostofClaim.isEmpty()) {
				Set<Id> parentClaimIds = CSX_CMP_TotalCostofClaimHelper.identifyParentClaimsforTotalCostCalc(
					childClaimIdsforTotalCostofClaim
				);
				if (!parentClaimIds.isEmpty()) {
					claimIdsforTotalCostofClaim.addAll(parentClaimIds);
				}
			}

			if (!claimIdsforTotalCostofClaim.isEmpty()) {
				CSX_CMP_TotalCostofClaimHelper.updateTotalCostOfClaim(claimIdsforTotalCostofClaim);
			}

			if (!claimsforEDI926Creation.isEmpty()) {
				CSX_CMP_CreateEDI926RecordController.createEDI926StagingRecord(claimsforEDI926Creation);
			}
			if (!closureEmailIds.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.sendDetailsToClosureEmail(closureEmailIds);
			}
			if (!claimsforContractBudget.isEmpty()) {
				CSX_CMP_ContractBudgetHandler.updateConsumedBudget(claimsforContractBudget);
			}
			if (!claimsforBudgetCheck.isEmpty()) {
				CSX_CMP_ContractBudgetHandler.availableBudgetCheck(claimsforBudgetCheck);
			}

			if (!cancelledSalvageClaimIds.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.clearSalvageClaimOnSalvage(cancelledSalvageClaimIds);
			}

			if (!collectStatusChangeClaimIds.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.sendStatusChangeUpdate(collectStatusChangeClaimIds);
			}

			if (!cancelledDistributionIds.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.clearDistributionClaimOnDistribution(cancelledDistributionIds);
			}

			if (!closedClaimsForServicePeriodUpdate.isEmpty()) {
				CSX_CMP_ClaimTriggerHelper.updateServicePeriodOnDistributionClaims(closedClaimsForServicePeriodUpdate);
			}

			if(!updatePaidAmountOnRelatedLDR.isEmpty()){
				CSX_CMP_ClaimTriggerHelper.updatePaidAmountOnRelatedLDR(updatePaidAmountOnRelatedLDR);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimTriggerHandler','handleAfterUpdate',JSON.serialize(newClaimsMap),ex);
		} finally{
			List<Case> newCLaimValues = [SELECT Id, Comments FROM Case WHERE Id IN :newClaimsMap.keySet()];
			if(!newCLaimValues.isEmpty()){
				for(Case claim : newCLaimValues){
					system.debug('Comments: '+claim.Comments);
				}
			}
		}
	}
}