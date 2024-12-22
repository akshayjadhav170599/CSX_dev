/*
RICEF ID : 
@author : Infosys
@description : This class is used to keep creation helper methods
*/
public with sharing class CSX_CMP_ClaimCreationHelper {
	//common method for creating a staging record
	public static CSX_CMP_Creation_Request__c createStagingRecord(
		CSX_CMP_NewClaimWrapper payload,
		String duplicateList,
		Integer fileVersionEDI
	) {
		try {
			CSX_CMP_Creation_Request__c claimStagingRecord = new CSX_CMP_Creation_Request__c();
			if (JSON.serialize(payload).length() < 131072) {
				claimStagingRecord.CSX_CMP_Request_Payload__c = JSON.serialize(payload);
			}
			claimStagingRecord.CSX_CMP_Duplicate_Claim_List__c = duplicateList;
			claimStagingRecord.CSX_CMP_EDI_Refile_Version__c = fileVersionEDI;
			claimStagingRecord.CSX_CMP_Creation_Status__c = 'Not Started';
			claimStagingRecord.CSX_CMP_Queueable_One_Execution_Status__c = 'Pending';
			claimStagingRecord.CSX_CMP_Source__c = payload.source;
			claimStagingRecord.CSX_CMP_Object_Type__c = 'Claim';

			if (payload.claimRecordType == 'Freight') {
				claimStagingRecord.CSX_CMP_Service_Case_Fetch_Status__c = 'Pending';
				claimStagingRecord.CSX_CMP_Umler_Fetch_Status__c = 'Pending';
				claimStagingRecord.CSX_CMP_Mileage_Fetch_Status__c = 'Pending';
				claimStagingRecord.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Pending';
				claimStagingRecord.CSX_CMP_Waybill_Document_Fetch_Status__c = 'Pending';
				if (claimStagingRecord.CSX_CMP_Source__c == 'EDI' || claimStagingRecord.CSX_CMP_Source__c == 'SHIPCSX') {
					claimStagingRecord.CSX_CMP_Autopay_Decline_Execution_Status__c = 'Pending';
				}
			} else if (payload.claimRecordType == 'Revenue_Railroad') {
				claimStagingRecord.CSX_CMP_Umler_Fetch_Status__c = 'Pending';
				claimStagingRecord.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Pending';
			} else if (payload.claimRecordType == 'Revenue_Overcharge') {
				claimStagingRecord.CSX_CMP_Umler_Fetch_Status__c = 'Pending';
			}

			Database.SaveResult result = Database.Insert(claimStagingRecord);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createStagingRecord',
				result,
				'CSX_CMP_Request_Payload__c'
			);
			claimStagingRecord.Id = result.id;
			if (JSON.serialize(payload).length() > 131072) {
				ContentVersion objCntVersion = new ContentVersion();
				objCntVersion.PathOnClient = 'CSX_CMP_Request_Payload__c';
				objCntVersion.Title = 'CSX_CMP_Request_Payload__c';
				objCntVersion.VersionData = Blob.valueOf(JSON.serialize(payload));
				Database.SaveResult resultContent = Database.Insert(objCntVersion);

				objCntVersion = [
					SELECT Id, ContentDocumentId
					FROM ContentVersion
					WHERE Id = :resultContent.getId()
					WITH SECURITY_ENFORCED
				];
				contentdocumentlink condoc = new contentdocumentlink();
				condoc.ContentDocumentId = objCntVersion.ContentDocumentId;
				condoc.LinkedEntityId = claimStagingRecord.Id;
				condoc.ShareType = 'V';
				condoc.Visibility = 'AllUsers';
				Database.SaveResult resultContentLink = Database.Insert(condoc);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'createStagingRecord',
					resultContentLink,
					'contentdocumentlink'
				);
			}
			return claimStagingRecord;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createStagingRecord',
				string.valueOf(payload),
				ex
			);
			return null;
		}
	}

	//Common method to create claims from all different sources ( Salesforce,ShipCSX, EDI and FLDX).
	//SINGLE POINT OF ENTRY FOR ALL CLAIM CREATION
	public static Map<String, String> createNewClaim(CSX_CMP_Creation_Request__c stagingrecord) {
		Map<String, String> resWrapper = new Map<String, String>();
		CSX_CMP_NewClaimWrapper claimInput;
		Case newClaimRecord;
		string declineReason;
		try {
			if (stagingrecord.CSX_CMP_Request_Payload__c == null || stagingrecord.CSX_CMP_Request_Payload__c == '') {
				claimInput = getNewClaimWrapper(stagingrecord.Id);
			} else {
				claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
					stagingrecord.CSX_CMP_Request_Payload__c,
					CSX_CMP_NewClaimWrapper.class
				);
			}
			claimInput.stagingRecordId = stagingrecord.Id;
			List<String> duplicateClaimsList = new List<String>();

			if (
				stagingrecord.CSX_CMP_Duplicate_Claim_List__c != null &&
				stagingrecord.CSX_CMP_Duplicate_Claim_List__c != ''
			) {
				duplicateClaimsList = (List<String>) JSON.deserialize(
					stagingrecord.CSX_CMP_Duplicate_Claim_List__c,
					List<String>.class
				);
			}

			// List<String> duplicateClaimsList = (List<String>)JSON.deserialize(stagingrecord.CSX_CMP_Duplicate_Claim_List__c,List<String>.class);
			if (duplicateClaimsList == null) {
				duplicateClaimsList = new List<String>();
			}
			Integer refileVersion = Integer.valueOf(stagingrecord.CSX_CMP_EDI_Refile_Version__c);
			Map<Boolean, String> isValidMap = CSX_CMP_ClaimCreateWebServiceHelper.checkPicklistValues(claimInput);
			Map<String, String> claimResultMap = new Map<String, String>();
			if (isValidMap.keySet().contains(false) && stagingrecord.CSX_CMP_Source__c == 'FLDX') {
				stagingRecord.CSX_CMP_Error_Message__c = 'Error while Claim Creation : ' + isValidMap.get(false);
				stagingRecord.CSX_CMP_Creation_Status__c = 'Error';
				updateStagingRecord(stagingRecord);

				System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Enqueue New Claim Creation', stagingRecord));

				resWrapper.put('error', isValidMap.get(false));
				return resWrapper;
			}

			if (stagingrecord.CSX_CMP_Source__c == 'FLDX' && isValidMap.keySet().contains(true)) {
				claimResultMap = insertNewClaim(claimInput, duplicateClaimsList, refileVersion);
			} else if (stagingRecord.CSX_CMP_Source__c != 'FLDX') {
				claimResultMap = insertNewClaim(claimInput, duplicateClaimsList, refileVersion);
			}
			// Map<String, String> claimResultMap = insertNewClaim(claimInput, duplicateClaimsList, refileVersion);
			/*if (claimResultMap.get('error') != null) {
resWrapper.put('error', claimResultMap.get('error'));
stagingrecord.CSX_CMP_Error_Message__c = 'Error while Claim Creation : ' + claimResultMap.get('error');
stagingrecord.CSX_CMP_Creation_Status__c = 'Error';

updateStagingRecord(stagingrecord);
} else*/
			if (claimResultMap.get('success') != null) {
				Map<String, String> detailMapForSuccess = (Map<String, String>) JSON.deserialize(
					claimResultMap.get('success'),
					Map<String, String>.class
				);
				claimInput.claimId = detailMapForSuccess.get('claimId');

				//update staging record with new claim reference
				stagingrecord.CSX_CMP_Claim__c = claimInput.claimId;
				//stagingrecord.CSX_CMP_Creation_Status__c = 'Pending'; // need to check with Chetan
				updateStagingRecord(stagingrecord);

				newClaimRecord = [
					SELECT Id, CaseNumber, RecordType.DeveloperName, Type
					FROM Case
					WHERE id = :claimInput.claimId
					WITH SECURITY_ENFORCED
				];

				//create claim contacts
				createClaimContact(claimInput);

				//create note
				CSX_CMP_Utility.createNote(claimInput.claimId, null, null, 'Comment', claimInput.Notes);

				Id equipmentId;
				if (newClaimRecord.RecordType.DeveloperName == 'Freight') {
					Map<String, String> equipmentResultMap = createEquipment(claimInput);
					if (equipmentResultMap.get('error') != null) {
						resWrapper.put('error', equipmentResultMap.get('error'));
					} else if (equipmentResultMap.get('success') != null) {
						Map<String, String> detailMapForEquipment = (Map<String, String>) JSON.deserialize(
							equipmentResultMap.get('success'),
							Map<String, String>.class
						);
						equipmentId = detailMapForEquipment.get('EquipmentId');
						createProduct(claimInput, equipmentId);
						createDistributionRecords(claimInput, equipmentId);
					}
				} else if (newClaimRecord.RecordType.DeveloperName.contains('Revenue')) {
					createClaimLine(claimInput);

					if (newClaimRecord.RecordType.DeveloperName == 'Revenue_Railroad') {
						if (
							newClaimRecord.Type != 'Rev-RR - Receivable Claim' &&
							newClaimRecord.Type != 'Rev-RR - Receivable Rchg Claim'
						) {
							declineReason = runGeneralRuleNumberValidations(newClaimRecord.Id);
							if (declineReason != '') {
								newClaimRecord.CSX_CMP_Review__c = true;
								Database.SaveResult updateClaimRecord = Database.update(newClaimRecord, false);
								CSX_CMP_LoggerUtility.addApexDMLErrorLog(
									'CSX_CMP_ClaimCreationHelper',
									'createNewClaim',
									updateClaimRecord,
									'Case'
								);
							}
						}
					}
				}

				//calling queueable to handle post claim creation processes
				System.enqueueJob(new CSX_CMP_PostClaimCreationQueueable('PostClaimCreationActions', stagingrecord));
				Map<String, String> detailMap = new Map<String, String>();
				detailMap.put('CaseNumber', newClaimRecord.CaseNumber);
				detailMap.put('DeclineReason', declineReason);
				detailMap.put('ClaimId', newClaimRecord.Id);
				resWrapper.put('success', JSON.serialize(detailMap));
			} else {
				if (claimResultMap.get('error') != null) {
					stagingrecord.CSX_CMP_Error_Message__c = 'Error while Claim Creation : ' + claimResultMap.get('error');
				}
				stagingrecord.CSX_CMP_Creation_Status__c = 'Error';
				resWrapper.put('error', claimResultMap.get('error'));
				updateStagingRecord(stagingrecord);
				System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Enqueue New Claim Creation', stagingRecord));
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createNewClaim',
				string.valueOf(claimInput),
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
		return resWrapper;
	}

	//Method to insert Claim record
	public static Map<String, String> insertNewClaim(
		CSX_CMP_NewClaimWrapper claimInput,
		List<String> duplicateClaims,
		Integer ediRefileVersion
	) {
		Case claim = new Case();
		Map<String, String> resWrapper = new Map<String, String>();
		Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
		try {
			claim.RecordTypeId = recordTypeMap.get(claimInput.claimRecordType).getRecordTypeId();
			String vin = '';
			if (
				claimInput.equipment != null &&
				claimInput.equipment.size() > 0 &&
				claimInput.equipment[0].products != null &&
				claimInput.equipment[0].products.size() > 0
			) {
				for (CSX_CMP_NewClaimWrapper.Product prod : claimInput.equipment[0].products) {
					if (String.isNotBlank(prod.vin)) {
						vin = prod.vin;
					}
				}
			}

			if (claimInput.claimRecordType == 'Freight') {
				claim.CSX_CMP_LD_Report_Number__c = claimInput.ldReportNumber;
				claim.CSX_CMP_Claim_Reason__c = claimInput.claimReason;
				if (vin != null && vin != '') {
					claim.CSX_CMP_VIN__c = vin;
				}
				if (!(String.isBlank(claimInput.equipmentId))) {
					List<String> equipmentIdSplit = claimInput.equipmentId.split('(?<=\\D)(?=\\d)');
					if (equipmentIdSplit.size() >= 2) {
						claim.CSX_CMP_Equipment_Initial__c = equipmentIdSplit[0];
						claim.CSX_CMP_Equipment_Num__c = equipmentIdSplit[1];
					}

					// claim.CSX_CMP_Equipment_Initial__c = claimInput.equipmentId.substring(0, 4);
					// claim.CSX_CMP_Equipment_Num__c = claimInput.equipmentId.substring(4, 10);
				}
			} else if (claimInput.claimRecordType == 'Revenue_Contract_Refund') {
				claim.CSX_CMP_Claim_Reason__c = 'Customer Refund Request';
			} else if (claimInput.claimRecordType == 'Revenue_Railroad') {
				claim.CSX_CMP_Claim_Reason__c = claimInput.claimReason;
				/*if(string.isNotBlank(claimInput.relatedClaimNumber)){
					claim.CSX_CMP_Recharged_Original_Claim_Number__c = claimInput.relatedClaimNumber; //[MR-00776]
				}*/
				if (claimInput.generalRuleNumber != null) {
					claim.CSX_CMP_General_Rule_Number__r = new CSX_CMP_Business_Rule__c(
						CSX_CMP_External_ID__c = claimInput.generalRuleNumber
					);
				}
			} else {
				claim.CSX_CMP_Claim_Reason__c = claimInput.claimReason;
			}

			//populating backend fields needed for ECM document link navigation.
			if (!(String.isBlank(claimInput.vin))) {
				//if(claimInput.claimType=='FC Customer Claim' || claimInput.claimType=='FC Customer Automobile Claim'){
				claim.CSX_CMP_VIN__c = claimInput.vin;
				if (!(String.isBlank(claimInput.equipmentId))) {
					List<String> equipmentIdSplit = claimInput.equipmentId.split('(?<=\\D)(?=\\d)');
					if (equipmentIdSplit.size() >= 2) {
						claim.CSX_CMP_Equipment_Initial__c = equipmentIdSplit[0];
						claim.CSX_CMP_Equipment_Num__c = equipmentIdSplit[1];
					}

					// claim.CSX_CMP_Equipment_Initial__c = claimInput.equipmentId.substring(0, 4);
					// claim.CSX_CMP_Equipment_Num__c = claimInput.equipmentId.substring(4, 10);
				}
			}

			claim.Type = claimInput.claimType;
			claim.Origin = claimInput.source;
			claim.CSX_CMP_Derailment__c = claimInput.derailmentFlag != null
				? Boolean.valueOf(claimInput.derailmentFlag)
				: false;
			claim.CSX_CMP_Claim_Amount__c = claimInput.claimAmount;
			claim.CSX_CMP_Original_Amount__c = claimInput.claimAmount;
			claim.CSX_CMP_Customer_Claim_Date__c = claimInput.customerClaimDate;
			claim.CSX_CMP_Claimant_Ref_Num__c = claimInput.claimantReferenceNumber;
			claim.CSX_CMP_FCD_Cause_Code__c = claimInput.causeCode;
			claim.CSX_CMP_FCD_Rule_Code__c = claimInput.ruleCode;
			claim.CSX_CMP_Terminal__c = claimInput.terminal;
			claim.CSX_CMP_Contract_Num__c = claimInput.contractNumber;
			claim.CSX_CMP_Period_Begin__c = claimInput.periodBegin;
			claim.CSX_CMP_Period_End__c = claimInput.periodEnd;
			claim.CSX_CMP_Dealer_SPLC__c = claimInput.dealerSPLC;
			claim.CSX_CMP_RACF_ID__c = claimInput.shipCSXUserID;
			claim.CSX_CMP_Supplier_Claimant__c = String.isNotBlank(claimInput.supplierId) ? claimInput.supplierId : null;
			//fetching related customer
			claim.CSX_CMP_Customer__c = fetchCustomerId(claimInput);

			//Newly added fields
			claim.CSX_CMP_Previous_Claim_Num__c = claimInput.previousClaimNumber;
			claim.CSX_CMP_ShipCSX_User__c = claimInput.shipCSXUserName;
			claim.CSX_CMP_Company_Claim__c = claimInput.companyFilingClaim;
			claim.CSX_CMP_FCD_Rule_Secondary__c = claimInput.ruleSecondary;
			claim.CSX_CMP_GS_Control_Number__c = claimInput.gsControlNumber;
			claim.CSX_CMP_Message_DTTM__c = claimInput.messageDate;
			claim.CSX_CMP_GS_Message_DTTM__c = claimInput.gsMessageDTTM;
			claim.CSX_CMP_ST_Control_Number__c = claimInput.stControlNumber;
			claim.CSX_CMP_Interchange_Control_Number__c = claimInput.interchangeControlNumber;
			claim.CSX_CMP_Receiver_ID__c = claimInput.receiverSCAC;
			claim.CSX_CMP_Sender_ID__c = claimInput.senderSCAC;
			claim.CSX_CMP_Currency_Code__c = claimInput.currencyCode;
			claim.CSX_CMP_Exchange_Rate__c = claimInput.exchangeRate;
			claim.CSX_CMP_Dealer_Code__c = claimInput.dealerCode;
			claim.CSX_CMP_Dealer_Value__c = claimInput.dealerValue;
			claim.CSX_CMP_Dealer_Reference_Number__c = claimInput.dealerReferenceNumber;
			claim.CSX_CMP_Shipment_Date__c = claimInput.shipmentDate;
			claim.CSX_CMP_Contract_Carrier_Date__c = claimInput.contractCarrierDate;
			claim.CSX_CMP_FLDX_File_Received_Date__c = claimInput.fldxFileReceivedDate;
			claim.CSX_CMP_Local_Interline_Traffic__c = claimInput.localInterlineTraffic;
			claim.CSX_CMP_Transaction_Type__c = claimInput.transactionType;
			claim.CSX_CMP_Claimant_Code__c = claimInput.claimantCode;
			claim.CSX_CMP_Foreign_Customer_Claim_Num__c = claimInput.foreignCustomerClaimNumber;
			claim.CSX_CMP_Foreign_Customer_Claim_Amount__c = claimInput.foreignCustomerClaimAmount;
			claim.CSX_CMP_Remarks__c = claimInput.remarks;

			//updating service period
			if (claimInput.claimType == 'FC RR Inbound Claim' || claimInput.claimType == 'Recharges Inbound Claim') {
				Date today = Date.today();
				Integer dayOfMonth = today.day();
				String year = String.valueOf(today.year());
				Integer month;
				if (dayOfMonth <= 15) {
					month = today.month() - 1;
				} else {
					month = today.month();
				}
				String servicePeriod = 'PER-' + String.valueOf(month) + '-' + year.substring(year.length() - 2);
				//String servicePeriod = 'PER-'+String.valueOf(CreatedDate.month())+'-'+ year.substring(year.length() - 2);
				claim.CSX_CMP_Service_Period__c = servicePeriod;
			}

			// Salvage Fields
			claim.CSX_CMP_Carrier_Code__c = claimInput.scac;
			claim.CSX_CMP_Salvage_File_Num__c = claimInput.salvageFileNumber;
			claim.CSX_CMP_Package_Lost__c = claimInput.packageLostFlag != null ? claimInput.packageLostFlag : false;
			claim.CSX_CMP_Salvage_Amount__c = claimInput.amount;
			claim.CSX_CMP_Salvage_Code__c = claimInput.proceedsCode;

			//updating refile version
			if (ediRefileVersion != 0) {
				claim.CSX_CMP_Refiled_Version__c = ediRefileVersion;
				claim.CSX_CMP_Refiled__c = true;
			}
			//based on duplicate claim list update potential dup flag
			if (
				!duplicateClaims.isEmpty() &&
				duplicateClaims != null &&
				(claimInput.source == 'Manual' ||
				claimInput.source == 'FLDX')
			) {
				claim.CSX_CMP_Potential_Duplicate__c = true;
				claim.CSX_CMP_Potential_Duplicate_Claim_Nums__c = String.valueOf(duplicateClaims);
			}

			Database.SaveResult claimRecord = Database.Insert(claim);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_ClaimCreationHelper', 'insertNewClaim', claimRecord, 'Case');
			claim.Id = claimRecord.Id;

			// If claim creation is failed, then on staging record add the error message on error message field
			// Update the staging record creation status to error
			// If creation is failed, then below logic should not be executed and also do not proceed with the next steps on createNewClaim method
			// Below logc is to be executed only if claim creation is successful and if there is error send the response map as we are doing in catch block

			//To add duplicate claims in related claims
			Map<Id, List<String>> relatedClaimIds = new Map<Id, List<String>>();
			List<String> relatedClaims = new List<String>();
			//duplicateClaims.add(claimInput.relatedClaimNumber); //[MR -00776]
			if (claim.CSX_CMP_Potential_Duplicate__c == true) {
				List<Case> duplicateClaimRecords = [
					SELECT Id
					FROM case
					WHERE caseNumber IN :duplicateClaims
					WITH SECURITY_ENFORCED
				];

				for (Case duplicateClaim : duplicateClaimRecords) {
					relatedClaims.add(duplicateClaim.Id);
				}

				relatedClaimIds.put(claim.Id, relatedClaims);
				//CSX_CMP_ClaimCreationHelper.createRelatedDuplicateClaims(relatedClaimIds,relatedClaimDetails,new Set<Id>());
				//7 may changes | Start
				CSX_CMP_Utility.createRelatedClaim(relatedClaimIds);
				//7 may changes | End
			}

			//To get the claim priority, work in progress
			List<String> claimPriority = new List<String>();
			Map<Id, String> claimPriorityResults = CSX_CMP_BusinessRulesUtility.RunClaimPriorityBusinessRules(
				new Set<Id>{ claim.Id },
				'CSX_CMP_Claim_Priority',
				null
			);
			if (!claimPriorityResults.isEmpty()) {
				if (claimPriorityResults.containsKey(claim.Id)) {
					String returnedString = claimPriorityResults.get(claim.Id);
					claimPriority = returnedString.split('###');
					claim.Priority = claimPriority[0];
					claim.CSX_CMP_System_Action_Toggle__c = true;
				}
			}

			/*To get the owner & Desk Assignment
            List<String> deskAndOwner = new List<String>();
            Map<Id, String> deskAssignmentResults = CSX_CMP_BusinessRulesUtility.RunClaimDeskAssignmentBusinessRules(
                new Set<Id>{ claim.Id },
                'CSX_CMP_Claim_Desk_Assignment',
                null
            );
            
            if (!deskAssignmentResults.isEmpty()) {
                if (deskAssignmentResults.containsKey(claim.Id)) {
                    String returnedString = deskAssignmentResults.get(claim.Id);
                    
                    deskAndOwner = returnedString.split('###');
                    claim.CSX_CMP_Desk_Name__r = new CSX_CMP_Desk__c(Name = deskAndOwner[0]);
                    claim.OwnerId = deskAndOwner[1];
                }
            }
           
            Database.SaveResult updateClaimRecord = Database.update(claim, false);
           
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_ClaimCreationHelper',
                'insertNewClaim',
                updateClaimRecord,
                'Case'
            );*/

			Map<String, String> detailMap = new Map<String, String>();
			detailMap.put('claimId', claim.Id);
			resWrapper.put('success', JSON.serialize(detailMap));
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'insertNewClaim',
				'Staging RecordId ' +
				claimInput.stagingRecordId +
				JSON.serialize(claimInput),
				e
			);
			resWrapper.put('error', e.getMessage() + e.getStackTraceString());
		}
		return resWrapper;
	}

	//Method to insert CSX_CMP_Customer__c for claims
	public static Id fetchCustomerId(CSX_CMP_NewClaimWrapper claimInput) {
		Id customerId;
		try {
			if (claimInput.claimRecordType == 'Revenue_Overcharge') {
				if (claimInput.source == 'shipCSX') {
					String patronCode = '';
					if (!claimInput.equipment.isEmpty()) {
						for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
							if (String.isNotBlank(equipWrap.patronCode)) {
								patronCode = equipWrap.patronCode;
								break;
							}
						}
					}

					if (String.isNotBlank(patronCode)) {
						Account custAcc = [
							SELECT id
							FROM Account
							WHERE Patron_Code__c = :patronCode AND RecordType.DeveloperName = 'Location' AND Type = 'Customer'
							WITH SECURITY_ENFORCED
							LIMIT 1
						];
						if (custAcc != null) {
							customerId = custAcc.id;
						}
					}
				} else {
					customerId = claimInput.customerId;
				}
			} else if (claimInput.claimRecordType == 'Revenue_Contract_Refund') {
				if (claimInput.contractNumber != null) {
					Id contractId = claimInput.contractNumber;
					if (string.isNotBlank(contractId)) {
						CSX_CMP_Contract__c contract = [
							SELECT Id, Name, CSX_CMP_Customer_Name__c
							FROM CSX_CMP_Contract__c
							WHERE id = :contractId
							WITH SECURITY_ENFORCED
						];
						if (contract != null) {
							customerId = contract.CSX_CMP_Customer_Name__c;
						}
					}
				}
			} else if (claimInput.claimRecordType == 'Revenue_Railroad') {
				if (string.isNotBlank(claimInput.supplierId)) {
					Account custAcc = [
						SELECT id, CSX_CMP_Customer_Name__c
						FROM Account
						WHERE
							id = :claimInput.supplierId
							AND RecordType.DeveloperName = 'Location'
							AND Type = 'Supplier'
							AND Location_Type__c = 'Billing Address'
						WITH SECURITY_ENFORCED
						LIMIT 1
					];
					if (custAcc != null) {
						customerId = custAcc.CSX_CMP_Customer_Name__c;
					}
				}
			} else {
				//freight
				if (claimInput.claimType == 'FC RR Inbound Claim' || claimInput.claimType == 'Recharges Inbound Claim') {
					if (string.isNotBlank(claimInput.supplierId)) {
						Account custAcc = [
							SELECT id, CSX_CMP_Customer_Name__c
							FROM Account
							WHERE
								id = :claimInput.supplierId
								AND RecordType.DeveloperName = 'Location'
								AND Type = 'Supplier'
								AND Location_Type__c = 'Billing Address'
							WITH SECURITY_ENFORCED
							LIMIT 1
						];
						if (custAcc != null) {
							customerId = custAcc.CSX_CMP_Customer_Name__c;
						}
					}
				} else {
					Account custAcc = [
						SELECT id, CSX_CMP_Customer_Name__c, Name, Party_Id__c
						FROM Account
						WHERE
							Party_Id__c = :Label.CSX_CMP_defaultCsxCustomer
							AND RecordType.DeveloperName = 'Location'
							AND Type = 'Customer'
						WITH SECURITY_ENFORCED
						LIMIT 1
					];
					if (custAcc != null) {
						customerId = custAcc.id;
					}
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'fetchCustomerId',
				string.valueOf(claimInput),
				e
			);
		}
		return customerId;
	}

	//Method to insert CSX_CMP_Equipment__c record for freight claims
	public static Map<String, String> createEquipment(CSX_CMP_NewClaimWrapper claimInput) {
		Map<String, String> resWrapper = new Map<String, String>();
		List<CSX_CMP_Equipment__c> equipmentList = new List<CSX_CMP_Equipment__c>();

		try {
			if (claimInput != null && claimInput.equipment != null) {
				for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
					CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
					if (String.isNotBlank(equipWrap.equipmentInitial) && String.isNotBlank(equipWrap.equipmentNumber)) {
						equipment.CSX_CMP_Equipment_Initial__c = equipWrap.equipmentInitial;
						equipment.CSX_CMP_Equipment_Num__c = equipWrap.equipmentNumber;
					} else {
						//this is a default value when EquipmentId is not entered
						equipment.CSX_CMP_Equipment_Initial__c = System.Label.CSX_CMP_Default_Equipment_Initial;
						equipment.CSX_CMP_Equipment_Num__c = System.Label.CSX_CMP_Default_Equipment_Num;
					}
					equipment.CSX_CMP_Waybill_Num__c = equipWrap.waybillNumber;
					equipment.CSX_CMP_Waybill_Date__c = equipWrap.waybillDate;
					equipment.CSX_CMP_Waybill_Controls__c = equipWrap.waybillControls;
					equipment.CSX_CMP_STCC__c = equipWrap.stcc;
					equipment.CSX_CMP_STCC_Description__c = equipWrap.stccDescription;
					equipment.CSX_CMP_Origin_Road_Num__c = equipWrap.originRoadNumber;
					equipment.CSX_CMP_Origin_Audit_Num__c = equipWrap.originAuditNumber;
					equipment.CSX_CMP_Act_Origin_City__c = equipWrap.actualOriginCityName;
					equipment.CSX_CMP_Act_Origin_State__c = equipWrap.actualOriginStateCode;
					equipment.CSX_CMP_Act_Origin_Road__c = equipWrap.actualOriginSCAC;
					equipment.CSX_CMP_Act_Destination_State__c = equipWrap.actualDestinationStateCode;
					equipment.CSX_CMP_Act_Destination_City__c = equipWrap.actualDestinationCityName;
					equipment.CSX_CMP_Act_Destination_Road__c = equipWrap.actualDestinationSCAC;
					equipment.CSX_CMP_Destination_Road_Num__c = equipWrap.destinationRoadNumber;
					equipment.CSX_CMP_Destination_Audit__c = equipWrap.destinationAuditNumber;
					equipment.CSX_CMP_Shipper__c = equipWrap.shipperName;
					equipment.CSX_CMP_Consignee__c = equipWrap.consigneeName;
					equipment.CSX_CMP_Consignee_LE_code__c = equipWrap.consigneeLegalEntityId;
					equipment.CSX_CMP_Shipper_LE_code__c = equipWrap.shipperLegalEntityId;
					equipment.CSX_CMP_Shipper_As_Claimant__c = equipWrap.shipperAsClaimant;
					equipment.CSX_CMP_PPN__c = equipWrap.piggybackPlanNumber;
					equipment.CSX_CMP_MV_Manufacturer_Route_Code__c = equipWrap.mvManufacturingCode;
					equipment.CSX_CMP_Freight_Bill_Date__c = equipWrap.freightBillDate;
					equipment.CSX_CMP_Flat_Car__c = equipWrap.flatCarId != null ? equipWrap.flatCarId.trim() : null;

					if (equipwrap.waybillFoundFlag != null) {
						equipment.CSX_CMP_CSX_Waybill_Found__c = equipwrap.waybillFoundFlag;
					}
					equipment.CSX_CMP_Destination_Fsac__c = equipwrap.wayBillToFSAC;
					equipment.CSX_CMP_Origin_FSAC__c = equipwrap.wayBillFromFSAC;
					equipment.CSX_CMP_Multi_Car_Count__c = equipwrap.multiCarCount;
					equipment.CSX_CMP_Claim__c = claimInput.claimId;

					equipment.CSX_CMP_Shipper_Addr1__c = equipWrap.shipperAddressLine1;
					equipment.CSX_CMP_Shipper_Addr2__c = equipWrap.shipperAddressLine2;
					equipment.CSX_CMP_Shipper_City__c = equipWrap.shipperCityName;
					equipment.CSX_CMP_Shipper_State__c = equipWrap.shipperStateCode;
					equipment.CSX_CMP_Shipper_Zip__c = equipWrap.shipperPostalCode;
					equipment.CSX_CMP_Consignee_Addr1__c = equipWrap.consigneeAddressLine1;
					equipment.CSX_CMP_Consignee_Addr2__c = equipWrap.consigneeAddressLine2;
					equipment.CSX_CMP_Consignee_City__c = equipWrap.consigneeCityName;
					equipment.CSX_CMP_Consignee_State__c = equipWrap.consigneeStateCode;
					equipment.CSX_CMP_Consignee_Zip__c = equipWrap.consigneePostalCode;

					equipment.CSX_CMP_Oncoming_Road__c = equipWrap.oncomingSCAC;
					equipment.CSX_CMP_Oncoming_City__c = equipWrap.oncomingCityName;
					equipment.CSX_CMP_Oncoming_State__c = equipWrap.oncomingStateCode;
					equipment.CSX_CMP_Offgoing_Road__c = equipWrap.offgoingSCAC;
					equipment.CSX_CMP_Offgoing_City__c = equipWrap.offgoingCityName;
					equipment.CSX_CMP_Offgoing_State__c = equipWrap.offgoingStateCode;
					equipment.CSX_CMP_Destination_Switch_Road__c = equipWrap.destinationSwitchRoad;
					equipment.CSX_CMP_Origin_Switch_Road__c = equipWrap.originSwitchRoad;
					equipment.CSX_CMP_Full_Route__c = equipWrap.fullRoad;
					equipment.CSX_CMP_Car_Position__c = equipwrap.equipmentPosition;
                    system.debug('equipwrap.businessUnit' + equipwrap.businessUnit);
					equipment.CSX_CMP_BU__c = equipwrap.businessUnit;
					equipmentList.add(equipment);
				}
				// equipment.CSX_CMP_Claim__c = claimInput.claimId;
			}

			Database.SaveResult[] equipmentRec = Database.Insert(equipmentList, false);
			// equipment.id = equipmentRec[0].id;
			Map<String, String> detailMap = new Map<String, String>();

			detailMap.put('EquipmentId', equipmentRec[0].id);
			resWrapper.put('success', JSON.serialize(detailMap));

			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createEquipment',
				equipmentRec,
				'CSX_CMP_Equipment__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createEquipment',
				'string.valueOf(equipment)',
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
		return resWrapper;
	}

	//Method to insert CSX_CMP_Claim_Line__c record for RevenueRR and Contract and Overcharge claims
	public static List<Id> createClaimLine(CSX_CMP_NewClaimWrapper claimInput) {
		List<CSX_CMP_Claim_Line__c> claimLineList = new List<CSX_CMP_Claim_Line__c>();
		Map<String, String> resWrapper = new Map<String, String>();
		List<Id> listOfIds = new List<Id>();
		try {
			for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
				CSX_CMP_Claim_Line__c claimLine = new CSX_CMP_Claim_Line__c();
				claimLine.CSX_CMP_Equipment_Num__c = equipWrap.equipmentNumber;
				claimLine.CSX_CMP_Equipment_Initial__c = equipWrap.equipmentInitial;
				claimLine.CSX_CMP_Waybill_Date__c = Date.valueOf(equipWrap.waybillDate);
				claimLine.CSX_CMP_Waybill_Num__c = equipWrap.waybillNumber;
				claimLine.CSX_CMP_Waybill_Controls__c = equipWrap.waybillControls;
				claimLine.CSX_CMP_URRWIN_Num__c = equipWrap.urrwinNumber;
				claimLine.CSX_CMP_URRWIN_Date__c = Date.valueOf(equipWrap.urrwinDate);
				claimLine.CSX_CMP_STCC__c = equipWrap.stcc;
				claimLine.CSX_CMP_STCC_Description__c = equipWrap.stccDescription;
				claimLine.CSX_CMP_Act_Origin_State__c = equipWrap.actualOriginStateCode;
				claimLine.CSX_CMP_Act_Origin_City__c = equipWrap.actualOriginCityName;
				claimLine.CSX_CMP_Act_Destination_State__c = equipWrap.actualDestinationStateCode;
				claimLine.CSX_CMP_Act_Destination_City__c = equipWrap.actualDestinationCityName;
				claimLine.CSX_CMP_Correction_Date__c = equipWrap.adjustmentDate != null
					? Date.valueOf(equipWrap.adjustmentDate)
					: null;
				claimLine.CSX_CMP_ISS_Settlement_Date__c = equipWrap.isSettlementDate != null
					? Date.valueOf(equipWrap.isSettlementDate)
					: null;
				claimLine.CSX_CMP_Challenge_Date__c = equipWrap.challengeDate != null
					? Date.valueOf(equipWrap.challengeDate)
					: null;
				claimLine.CSX_CMP_BoL_Num__c = equipWrap.billofLadingNumber;
				claimLine.CSX_CMP_BoL_Date__c = equipWrap.billofLadingDate != null
					? Date.valueOf(equipWrap.billofLadingDate)
					: null;
				claimLine.CSX_CMP_Freight_Bill_Num__c = equipWrap.freightBillNumber;
				claimLine.CSX_CMP_Freight_Bill_Date__c = equipWrap.freightBillDate != null
					? Date.valueOf(equipWrap.freightBillDate)
					: null;
				claimLine.CSX_CMP_Received_Amount__c = equipWrap.receivedAmount;
				claimLine.CSX_CMP_Settled_Amount__c = equipWrap.settlementAmount;
				if (equipWrap.claimAmount != null) {
					claimLine.CSX_CMP_Claim_Amount__c = equipWrap.claimAmount;
				}

				claimLine.CSX_CMP_Original_Amount__c = (equipWrap.originalAmount == null ||
					String.isBlank(String.valueOf(equipWrap.originalAmount)))
					? equipWrap.claimAmount
					: equipWrap.originalAmount;

				// if(equipWrap.originalAmount == null || String.isBlank(String.valueOf(equipWrap.originalAmount))){
				// 	claimLine.CSX_CMP_Original_Amount__c    = claimLine.CSX_CMP_Claim_Amount__c;
				// } else {
				// 	claimLine.CSX_CMP_Original_Amount__c = equipWrap.originalAmount;
				// }
				/*else if(equipWrap.originalAmount!=null){
claimLine.CSX_CMP_Claim_Amount__c       = equipWrap.originalAmount;
claimLine.CSX_CMP_Original_Amount__c    = claimLine.CSX_CMP_Claim_Amount__c;
} */

				claimLine.CSX_CMP_Claim__c = claimInput.claimId;
				claimLine.CSX_CMP_Unit_Refund_Price__c = equipWrap.unitRefundPrice;
				claimLine.CSX_CMP_Unit_Type__c = equipWrap.unitType;
				claimLine.CSX_CMP_Patron_Code__c = equipWrap.patronCode;
				if (claimLine.CSX_CMP_Unit_Type__c == 'Weight(in Tons)') {
					claimLine.CSX_CMP_Weight_in_Tons__c = equipWrap.weight != null
						? (equipWrap.weight): 0;
				} else {
					claimLine.CSX_CMP_No_of_Cars__c = equipWrap.numberOfCars != null
						? Decimal.valueof(equipWrap.numberOfCars)
						: 0;
				}
				if (equipWrap.numberOfCars != null) {
					claimLine.CSX_CMP_No_of_Cars__c = Decimal.valueof(equipWrap.numberOfCars);
				}
				claimLineList.add(claimLine);
			}

			Database.SaveResult[] claimLineRecs = Database.Insert(claimLineList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createClaimLine',
				claimLineRecs,
				'CSX_CMP_Claim_Line__c'
			);
			for (Database.SaveResult sr : claimLineRecs) {
				if (sr.isSuccess()) {
					listOfIds.add(sr.getId());
				}
			}
			resWrapper.put('success', JSON.serialize(listOfIds));
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createClaimLine',
				string.valueOf(claimLineList),
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
		return listOfIds;
	}

	//Method to insert CSX_CMP_Claim_Contact__c record
	public static void createClaimContact(CSX_CMP_NewClaimWrapper claimInput) {
		List<CSX_CMP_Claim_Contact__c> contactList = new List<CSX_CMP_Claim_Contact__c>();

		try {
			CSX_CMP_Claim_Contact__c contact = new CSX_CMP_Claim_Contact__c();
			if(String.isNotBlank(claimInput.phoneNumber) || String.isNotBlank(claimInput.email) || String.isNotBlank(claimInput.contactName) || String.isNotBlank(claimInput.claimId) || String.isNotBlank(claimInput.adressLine1) || String.isNotBlank(claimInput.adressLine2) || String.isNotBlank(claimInput.cityName) || String.isNotBlank(claimInput.stateCode) || String.isNotBlank(claimInput.countryCode)){
				if (claimInput.phoneNumber != null) {
					contact.CSX_CMP_Telephone__c = String.valueOf(claimInput.phoneNumber);
				}
				contact.CSX_CMP_Emails__c = claimInput.email;
				contact.CSX_CMP_Person__c = claimInput.contactName;
				contact.CSX_CMP_Claim__c = claimInput.claimId;
				// contact.CSX_CMP_Fax__c = claimInput.fax;
				contact.CSX_CMP_Address1__c = claimInput.adressLine1;
				contact.CSX_CMP_Address2__c = claimInput.adressLine2;
				contact.CSX_CMP_City__c = claimInput.cityName;
				contact.CSX_CMP_State__c = claimInput.stateCode;
				contact.CSX_CMP_Country__c = claimInput.countryCode;
				contact.CSX_CMP_Type__c = claimInput.contactType != null ? claimInput.contactType : 'Reported By';
				contactList.add(contact);
			}

			if (claimInput.source == 'EDI') {
				Account accountForFLREmail = [
					SELECT Id, CSX_CMP_FC_Contact_Email__c
					FROM Account
					WHERE Id = :claimInput.supplierId
					WITH SECURITY_ENFORCED
				];
				if (accountForFLREmail != null && accountForFLREmail.CSX_CMP_FC_Contact_Email__c != null) {
					contact = new CSX_CMP_Claim_Contact__c();
					contact.CSX_CMP_Emails__c = accountForFLREmail.CSX_CMP_FC_Contact_Email__c;
					contact.CSX_CMP_Claim__c = claimInput.claimId;
					contactList.add(contact);
				}
			}

			Database.SaveResult[] contactRecord = Database.Insert(contactList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createClaimContact',
				contactRecord,
				'CSX_CMP_Claim_Contact__c'
			);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createClaimContact',
				string.valueOf(contactList),
				ex
			);
		}
	}

	//Method to insert CSX_CMP_Product__c record
	public static void createProduct(CSX_CMP_NewClaimWrapper claimInput, Id equipmentId) {
		Map<String, String> resWrapper = new Map<String, String>();
		List<CSX_CMP_Product__c> productList = new List<CSX_CMP_Product__c>();
		Map<String, List<CSX_CMP_NewClaimWrapper.CustomerDamage>> customerDamageMap = new Map<String, List<CSX_CMP_NewClaimWrapper.CustomerDamage>>();
		try {
			if (claimInput.equipment != null && !claimInput.equipment.isEmpty()) {
				for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
					if (equipWrap.products != null && !equipWrap.products.isEmpty()) {
						for (CSX_CMP_NewClaimWrapper.Product prod : equipWrap.products) {
							CSX_CMP_Product__c product = new CSX_CMP_Product__c();
							if (String.isNotBlank(prod.vin)) {
								product.CSX_CMP_VIN__c = prod.vin;
								product.CSX_CMP_External_ID__c = equipmentId + '_' + prod.vin;
								if (claimInput.claimType == 'FC Customer Automobile Claim') {
									product.CSX_CMP_Quantity__c = 1;
									product.CSX_CMP_Product_Description__c = prod.description;
								}
								if (prod.customerDamages != null && !prod.customerDamages.isEmpty()) {
									customerDamageMap.put(product.CSX_CMP_External_ID__c, prod.customerDamages);
								}
							} else {
								product.CSX_CMP_Quantity__c = prod.quantity;
								product.CSX_CMP_Product_Description__c = prod.description;
								product.CSX_CMP_UOM__c = prod.uom;
								product.CSX_CMP_External_ID__c = equipmentId + '_' + prod.description;
								if (prod.customerDamages != null && !prod.customerDamages.isEmpty()) {
									customerDamageMap.put(product.CSX_CMP_External_ID__c, prod.customerDamages);
								}
							}
							product.CSX_CMP_Equipment__c = equipmentId;
							productList.add(product);
						}
					}
				}
			}

			if (!productList.isEmpty()) {
				Database.SaveResult[] productRecs = Database.Insert(productList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'createProduct',
					productRecs,
					'CSX_CMP_Product__c'
				);
				resWrapper.put('success', JSON.serialize(productRecs));
				if (!customerDamageMap.isEmpty()) {
					createCustomerDamages(customerDamageMap);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createProduct',
				string.valueOf(productList),
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
	}

	public static void createCustomerDamages(
		Map<String, List<CSX_CMP_NewClaimWrapper.CustomerDamage>> customerDamageMap
	) {
		Map<String, String> resWrapper = new Map<String, String>();
		List<CSX_CMP_Customer_Damage__c> custDamageRecs = new List<CSX_CMP_Customer_Damage__c>();
		try {
			if (!customerDamageMap.isEmpty()) {
				for (String product : customerDamageMap.keySet()) {
					if (!customerDamageMap.get(product).isEmpty()) {
						for (CSX_CMP_NewClaimWrapper.CustomerDamage cd : customerDamageMap.get(product)) {
							CSX_CMP_Customer_Damage__c custDamage = new CSX_CMP_Customer_Damage__c();
							custDamage.CSX_CMP_Amount__c = cd.amount;
							custDamage.CSX_CMP_Area__c = cd.area;
							custDamage.CSX_CMP_Severity__c = cd.severity;
							custDamage.CSX_CMP_Type__c = cd.type;
							custDamage.CSX_CMP_Product__r = new CSX_CMP_Product__c(CSX_CMP_External_ID__c = product);
							custDamageRecs.add(custDamage);
						}
					}
				}
				if (!custDamageRecs.isEmpty()) {
					List<Database.SaveResult> customerDamageRecs = Database.Insert(custDamageRecs, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_ClaimCreationHelper',
						'createCustomerDamages',
						customerDamageRecs,
						'CSX_CMP_Customer_Damage__c'
					);
					resWrapper.put('success', JSON.serialize(customerDamageRecs));
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createCustomerDamages',
				string.valueOf(custDamageRecs),
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
	}

	//Method to insert CSX_CMP_Distribution__c record
	public static void createDistributionRecords(CSX_CMP_NewClaimWrapper claimInput, Id equimentId) {
		Map<String, String> resWrapper = new Map<String, String>();
		List<CSX_CMP_Distribution__c> distRecs = new List<CSX_CMP_Distribution__c>();
		try {
			set<String> rrCodeValues = new Set<String>();
			for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
				for (CSX_CMP_NewClaimWrapper.Distribution dist : equipWrap.distributions) {
					if (String.isNotBlank(dist.scac)) {
						rrCodeValues.add(dist.scac.trim());
					}
				}
			}
			Map<String, Id> rrCodeToAccountIdMap = new Map<String, Id>();

			for (Account acc : [
				SELECT Id, CSX_CMP_FC_SCAC__c, CSX_CMP_FC_Railroad_Road_Code__c
				FROM Account
				WHERE
					(CSX_CMP_FC_SCAC__c IN :rrCodeValues
					OR CSX_CMP_FC_Railroad_Road_Code__c IN :rrCodeValues)
					AND type = 'Supplier'
					AND RecordType.DeveloperName = 'Location'
					AND Location_Type__c = 'Billing Address'
				WITH SECURITY_ENFORCED
			]) {
				if (claimInput.source == 'FLDX') {
					rrCodeToAccountIdMap.put(acc.CSX_CMP_FC_Railroad_Road_Code__c, acc.Id);
				} else {
					rrCodeToAccountIdMap.put(acc.CSX_CMP_FC_SCAC__c, acc.Id);
				}
			}
			if (claimInput.equipment != null && !claimInput.equipment.isEmpty()) {
				for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipWrap : claimInput.equipment) {
					if (equipWrap.distributions != null && !equipWrap.distributions.isEmpty()) {
						for (CSX_CMP_NewClaimWrapper.Distribution dist : equipWrap.distributions) {
							if (dist.roadType != 'SW') {
								CSX_CMP_Distribution__c distribution = new CSX_CMP_Distribution__c();
								if (String.isNotBlank(dist.scac)) {
									distribution.CSX_CMP_Equipment__c = equimentId;
									if (rrCodeToAccountIdMap.containsKey(dist.scac.trim())) {
										Id accountId = rrCodeToAccountIdMap.get(dist.scac.trim());
										distribution.CSX_CMP_Account__c = accountId;
									}
									if (dist.scac.trim() == 'CSXT' || dist.scac.trim() == '0712' || dist.scac.trim() == '712') {
										distribution.CSX_CMP_Hold_RR_Distribution__c = true;
									}
									distribution.CSX_CMP_Junction__c = dist.junctionCode;
									//passing static value to bypass validation
									if (String.isNotBlank(String.valueOf(dist.miles)) && dist.scac.trim() != 'FXE') {
										distribution.CSX_CMP_Adj_Miles__c = Decimal.valueOf(dist.miles);
									} else {
										distribution.CSX_CMP_Adj_Miles__c = 0;
									}
									distribution.CSX_CMP_Miles__c = String.isNotBlank(String.valueOf(dist.miles))
										? Decimal.valueOf(dist.miles)
										: 0;
									// FLDX Fields
									distribution.CSX_CMP_Manual_Adj_Amt__c = dist.manualAdjustedAmount != null
										? dist.manualAdjustedAmount
										: 0.0;
									distribution.CSX_CMP_Road_Receive_Papers__c = dist.roadReceivePapers;
									distribution.CSX_CMP_Foreign_Billed_Amt__c = dist.foreignBilledAmount != null
										? dist.foreignBilledAmount
										: 0.0;
									if (dist.routeSequenceNumber != null) {
										distribution.CSX_CMP_Distribution_Sequence__c = dist.routeSequenceNumber;
									}
								}
								distRecs.add(distribution);
							}
						}
					}
				}
			}

			if (!distRecs.isEmpty()) {
				Database.SaveResult[] distributionRecords = Database.Insert(distRecs, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'createDistributionRecords',
					distributionRecords,
					'CSX_CMP_Distribution__c'
				);
				resWrapper.put('success', JSON.serialize(distributionRecords));
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createDistributionRecords',
				string.valueOf(distRecs),
				ex
			);
			resWrapper.put('error', ex.getMessage());
		}
	}

	//Method to insert CSX_CMP_Customer_Damage__c record

	//Method to insert Contact record
	public static Id createRelatedContacts(CSX_CMP_NewClaimWrapper claimInput) {
		Id relatedContactsId;
		// insert related contacts
		return relatedContactsId;
	}

	public static void sendClaimconfirmationEmail(Id claimId) {
		String str;
		try {
			Case claim = [
				SELECT id, CaseNumber, RecordTypeId, (SELECT CSX_CMP_Emails__c, Name FROM Claim_Contacts__r)
				FROM Case
				WHERE id = :claimId
				WITH SECURITY_ENFORCED
			];
			List<CSX_CMP_Claim_Contact__c> contacts = claim.Claim_Contacts__r;
			if (contacts.size() > 0) {
				str = String.valueof(contacts[0].CSX_CMP_Emails__c);
			}
			List<String> emails = str.split(';');

			Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
			String devName;
			for (String recTypeName : recordTypeMap.keySet()) {
				Schema.RecordTypeInfo recTypeInfo = recordTypeMap.get(recTypeName);
				if (claim.RecordTypeId == recTypeInfo.getRecordTypeId()) {
					if (recTypeName == 'Contract Refund') {
						devName = 'CSX_CMP_Claim_Contract_Ack_Email_Templat';
					} else if (recTypeName == 'Railroad Revenue') {
						devName = 'CSX_CMP_Claim_Rail_Ack_Email_Template';
					} else if (recTypeName == 'Freight') {
						devName = 'CSX_CMP_Claim_Freight_Ack_Email_Template';
					} else if (recTypeName == 'Overcharge') {
						devName = 'CSX_CMP_Claim_Over_Ack_Email_Template';
					}
				}
			}

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

			CSX_CMP_EmailUtility.EmailRequestWrapper emailReq = new CSX_CMP_EmailUtility.EmailRequestWrapper();

			emailReq.templateDeveloperName = devName;
			emailReq.sourceRecordId = claim.id;
			emailReq.toEmailIdList = emails;
			email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailReq);
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreationHelper', 'sendClaimconfirmationEmail', str, ex);
		}
	}

	//logic to identify refile scenario for EDI Auto claims.
	public static Integer identifyRefileVersionNum(CSX_CMP_NewClaimWrapper inputClaimWrap) {
		Decimal refileNum = 0;
		Map<Id, List<CSX_CMP_Customer_Damage__c>> targetClaimIdToCustDamagesMap = new Map<Id, List<CSX_CMP_Customer_Damage__c>>();
		Map<Id, Case> claimIdtoDetailsMap = new Map<Id, Case>();
		try {
			// getting the case records and related customer damage records which satisfies the criteria
			Decimal claimAmount = inputClaimWrap.claimAmount / 100;
			List<Case> matchingClaimRecords = [
				SELECT id, CSX_CMP_Refiled_Version__c, CaseNumber
				FROM Case
				WHERE
					CSX_CMP_Claim_Amount__c = :claimAmount
					AND CSX_CMP_VIN__c = :inputClaimWrap.equipment[0].products[0].vin
					AND Status IN ('Declined', 'Re-Declined')
				WITH SECURITY_ENFORCED
				ORDER BY CaseNumber, CSX_CMP_Refiled_Version__c DESC
			];
			if (!matchingClaimRecords.isEmpty()) {
				// creating damage records from input data
				List<CSX_CMP_Customer_Damage__c> newDamageRecords = new List<CSX_CMP_Customer_Damage__c>();
				for (CSX_CMP_NewClaimWrapper.CustomerDamage cd : inputClaimWrap.equipment[0].products[0].customerdamages) {
					CSX_CMP_Customer_Damage__c custDamage = new CSX_CMP_Customer_Damage__c();
					custDamage.CSX_CMP_Area__c = cd.area;
					custDamage.CSX_CMP_Severity__c = cd.severity;
					custDamage.CSX_CMP_Type__c = cd.type;
					newDamageRecords.add(custDamage);
				}
				for (Case caseRec : matchingClaimRecords) {
					claimIdtoDetailsMap.put(caseRec.Id, caseRec);
				}

				List<CSX_CMP_Customer_Damage__c> custDamageRecs = [
					SELECT
						Id,
						Name,
						CSX_CMP_Area__c,
						CSX_CMP_Type__c,
						CSX_CMP_Severity__c,
						CSX_CMP_Product__c,
						CSX_CMP_Product__r.CSX_CMP_Equipment__r.CSX_CMP_Claim__c
					FROM CSX_CMP_Customer_Damage__c
					WHERE CSX_CMP_Product__r.CSX_CMP_Equipment__r.CSX_CMP_Claim__c IN :claimIdtoDetailsMap.keySet()
					WITH SECURITY_ENFORCED
				];
				if (!custDamageRecs.isEmpty()) {
					for (CSX_CMP_Customer_Damage__c cdRec : custDamageRecs) {
						Id parentClaimId = cdRec.CSX_CMP_Product__r.CSX_CMP_Equipment__r.CSX_CMP_Claim__c;
						if (!targetClaimIdToCustDamagesMap.containsKey(parentClaimId)) {
							targetClaimIdToCustDamagesMap.put(parentClaimId, new List<CSX_CMP_Customer_Damage__c>{ cdRec });
						} else {
							targetClaimIdToCustDamagesMap.get(parentClaimId).add(cdRec);
						}
					}
				}
				//checking if there is a match in damage records
				if (!targetClaimIdToCustDamagesMap.isEmpty()) {
					for (Id caseId : targetClaimIdToCustDamagesMap.keyset()) {
						Integer matchingCount = 0;
						List<CSX_CMP_Customer_Damage__c> targetCustomerDamages = targetClaimIdToCustDamagesMap.get(caseId);
						if (targetCustomerDamages.size() == newDamageRecords.size()) {
							for (CSX_CMP_Customer_Damage__c cdRecord : targetCustomerDamages) {
								for (CSX_CMP_Customer_Damage__c newCdRecord : newDamageRecords) {
									if (
										cdRecord.CSX_CMP_Area__c == newCdRecord.CSX_CMP_Area__c &&
										cdRecord.CSX_CMP_Type__c == newCdRecord.CSX_CMP_Type__c &&
										cdRecord.CSX_CMP_Severity__c == newCdRecord.CSX_CMP_Severity__c
									) {
										matchingCount++;
										break;
									}
								}
							}
						}
						if (matchingCount == targetCustomerDamages.size()) {
							refileNum = (claimIdtoDetailsMap.get(caseId).CSX_CMP_Refiled_Version__c == null
								? 1
								: claimIdtoDetailsMap.get(caseId).CSX_CMP_Refiled_Version__c + 1);
							//break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'identifyRefileVersionNum',
				string.valueOf(inputClaimWrap),
				ex
			);
		}
		return Integer.valueOf(refileNum);
	}

	//invoke General Rule validation (only for Revenue RR Claims) - Invokable method called from LWC  (INDEPENDENT)
	//create Note with decline reason (if general rule satisfies)
	public static String runGeneralRuleNumberValidations(String claimId) {
		Case inputClaim = [
			SELECT
				Id,
				CaseNumber,
				CSX_CMP_Supplier_Claimant__c,
				Origin,
				RecordType.DeveloperName,
				CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_Railroad_Road_Code__c,
				CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_SCAC__c,
				CSX_CMP_Claim_Amount__c,
				CSX_CMP_Claim_Date__c,
				CSX_CMP_Customer_Claim_Date__c,
				CSX_CMP_Claim_Reason__c,
				(
					SELECT
						CSX_CMP_Claim__r.CaseNumber,
						CSX_CMP_Claim__r.Origin,
						CSX_CMP_Claim__c,
						CSX_CMP_Claim__r.CSX_CMP_Claim_Date__c,
						CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c,
						CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c,
						CSX_CMP_BoL_Date__c,
						CSX_CMP_ISS_Settlement_Date__c,
						CSX_CMP_Correction_Date__c,
						CSX_CMP_Waybill_Date__c,
						CSX_CMP_Challenge_Date__c
					FROM ClaimLines__r
				)
			FROM Case
			WHERE Id = :claimId
			WITH SECURITY_ENFORCED
		];

		Boolean errorFlg = false;
		String declineReason = '';
		Integer totalClaimLine = 0;
		String railroadCode = inputClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_SCAC__c;

		try {
			CSX_CMP_General_Rule_Configuration__c generalRuleValidationRule = new CSX_CMP_General_Rule_Configuration__c();
			List<CSX_CMP_General_Rule_Configuration__c> generalRuleList = [
				SELECT
					Id,
					Name,
					CSX_CMP_Adjustment_Flag__c,
					CSX_CMP_From_Time_Limit__c,
					CSX_CMP_To_Time_Limit__c,
					CSX_CMP_Enabled__c,
					CSX_CMP_Amount_Limit_Single__c,
					CSX_CMP_Amount_Limit_Multiple__c,
					CSX_CMP_Date_Type__c,
					CSX_CMP_Last_Day_Month_Flag__c,
					CSX_CMP_Business_Rule__c
				FROM CSX_CMP_General_Rule_Configuration__c
				WHERE
					CSX_CMP_Enabled__c = 'Y'
					AND CSX_CMP_Business_Rule__r.CSX_CMP_Rule_Name__c = :inputClaim.CSX_CMP_Claim_Reason__c
					AND CSX_CMP_Business_Rule__r.CSX_CMP_Status__c = 'Valid'
					AND CSX_CMP_Business_Rule__r.CSX_CMP_Start_Date__c <= Today
					AND (CSX_CMP_Business_Rule__r.CSX_CMP_End_Date__c >= Today
					OR CSX_CMP_Business_Rule__r.CSX_CMP_End_Date__c = NULL)
					AND (Name = :railroadCode
					OR Name = :'Default')
				WITH SECURITY_ENFORCED
			];
			if (!generalRuleList.isEmpty() && generalRuleList.size() > 0) {
				for (CSX_CMP_General_Rule_Configuration__c generalRule : generalRuleList) {
					if (generalRule.Name == railroadCode) {
						generalRuleValidationRule = generalRule;
						break;
					} else {
						generalRuleValidationRule = generalRule;
					}
				}
				totalClaimLine = inputClaim.ClaimLines__r.size();
				for (CSX_CMP_Claim_Line__c claimLine : inputClaim.ClaimLines__r) {
					Date compDate;
					Date adjustmentDate;
					Date fromClaimDate;
					Date toClaimDate;

					if (
						claimLine.CSX_CMP_ISS_Settlement_Date__c != null ||
						claimLine.CSX_CMP_BoL_Date__c != null ||
						claimLine.CSX_CMP_Waybill_Date__c != null ||
						claimLine.CSX_CMP_Challenge_Date__c != null
					) {
						if (
							generalRuleValidationRule.CSX_CMP_Date_Type__c == 'ISS Settlement' &&
							claimLine.CSX_CMP_ISS_Settlement_Date__c != null
						) {
							compDate = claimLine.CSX_CMP_ISS_Settlement_Date__c;
						} else if (
							generalRuleValidationRule.CSX_CMP_Date_Type__c == 'Waybill' &&
							claimLine.CSX_CMP_Waybill_Date__c != null
						) {
							compDate = claimLine.CSX_CMP_Waybill_Date__c;
						} else if (
							generalRuleValidationRule.CSX_CMP_Date_Type__c == 'Challenge' &&
							claimLine.CSX_CMP_Challenge_Date__c != null
						) {
							compDate = claimLine.CSX_CMP_Challenge_Date__c;
						} else if (
							generalRuleValidationRule.CSX_CMP_Date_Type__c == 'Bill of Lading' &&
							claimLine.CSX_CMP_BoL_Date__c != null
						) {
							compDate = claimLine.CSX_CMP_BoL_Date__c;
						} else {
							declineReason =
								'Please check the ' +
								generalRuleValidationRule.CSX_CMP_Date_Type__c +
								' date manually for claim number : ' +
								claimLine.CSX_CMP_Claim__r.CaseNumber +
								'.';
						}
					} else {
						declineReason =
							'Please check the ' +
							generalRuleValidationRule.CSX_CMP_Date_Type__c +
							' date manually for claim number : ' +
							claimLine.CSX_CMP_Claim__r.CaseNumber +
							'.';
					}
					if (declineReason == '') {
						if (claimLine.CSX_CMP_Correction_Date__c != null) {
							adjustmentDate = claimLine.CSX_CMP_Correction_Date__c;
						}
						if (compDate != null) {
							fromClaimDate = compDate.addMonths(Integer.valueOf(generalRuleValidationRule.CSX_CMP_From_Time_Limit__c));
							toClaimDate = compDate.addMonths(Integer.valueOf(generalRuleValidationRule.CSX_CMP_To_Time_Limit__c));

							if (generalRuleValidationRule.CSX_CMP_Last_Day_Month_Flag__c == 'Y') {
								Integer fromClaimNumberOfDays = Date.daysInMonth(fromClaimDate.year(), fromClaimDate.month());
								Date fromClaimLastDayOfMonth = Date.newInstance(
									fromClaimDate.year(),
									fromClaimDate.month(),
									fromClaimNumberOfDays
								);
								Integer toClaimNumberOfDays = Date.daysInMonth(toClaimDate.year(), toClaimDate.month());
								Date toClaimLastDayOfMonth = Date.newInstance(
									toClaimDate.year(),
									toClaimDate.month(),
									toClaimNumberOfDays
								);
								fromClaimDate = fromClaimLastDayOfMonth;
								toClaimDate = toClaimLastDayOfMonth;
							}
						}
						if (
							!(claimLine.CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c >= fromClaimDate &&
							claimLine.CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c <= toClaimDate)
						) {
							if (generalRuleValidationRule.CSX_CMP_Adjustment_Flag__c == 'Y') {
								if (adjustmentDate != null) {
									Date adjustmentDateAddZeroMonth = adjustmentDate.addMonths(0);
									Integer adjDateNumberOfDays = Date.daysInMonth(
										adjustmentDateAddZeroMonth.year(),
										adjustmentDateAddZeroMonth.month()
									);
									Date adjDateLastDayOfMonth = Date.newInstance(
										adjustmentDateAddZeroMonth.year(),
										adjustmentDateAddZeroMonth.month(),
										adjDateNumberOfDays
									);
									Date adjustmentDateAddthreeMonth = adjustmentDate.addMonths(3);
									Integer adjDatethreeNumberOfDays = Date.daysInMonth(
										adjustmentDateAddthreeMonth.year(),
										adjustmentDateAddthreeMonth.month()
									);
									Date adjDateThreeLastDayOfMonth = Date.newInstance(
										adjustmentDateAddthreeMonth.year(),
										adjustmentDateAddthreeMonth.month(),
										adjDatethreeNumberOfDays
									);
									if (
										!(claimLine.CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c >= adjDateLastDayOfMonth &&
										claimLine.CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c <= adjDateThreeLastDayOfMonth)
									) {
										errorFlg = true;
									}
								} else {
									errorFlg = true;
								}
							} else {
								errorFlg = true;
							}
						}
						if (errorFlg) {
							declineReason =
								' According to Railroad Accounting Rules, Claim should be submitted between ' +
								generalRuleValidationRule.CSX_CMP_From_Time_Limit__c +
								' and ' +
								generalRuleValidationRule.CSX_CMP_To_Time_Limit__c +
								' months from the ' +
								generalRuleValidationRule.CSX_CMP_Date_Type__c +
								' date. For the claim ' +
								claimLine.CSX_CMP_Claim__r.CaseNumber +
								' with ' +
								generalRuleValidationRule.CSX_CMP_Date_Type__c +
								' date ' +
								(compDate != null ? compDate.format() : '') +
								', Claim Submission date : ' +
								claimLine.CSX_CMP_Claim__r.CSX_CMP_Customer_Claim_Date__c.format() +
								' is not within time limits : ' +
								(fromClaimDate != null ? fromClaimDate.format() : '') +
								' and ' +
								(toClaimDate != null ? toClaimDate.format() : '') +
								'.';
						} else {
							if (totalClaimLine == 1) {
								if (
									claimLine.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c <
									generalRuleValidationRule.CSX_CMP_Amount_Limit_Single__c
								) {
									declineReason =
										' Claim amount does not satisfy minimum amount threshold :$ (' +
										generalRuleValidationRule.CSX_CMP_Amount_Limit_Single__c +
										'FM99999999.00)';
								}
							} else if (
								claimLine.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c <
								generalRuleValidationRule.CSX_CMP_Amount_Limit_Multiple__c
							) {
								declineReason =
									' Claim amount does not satisfy minimum amount threshold :$ (' +
									generalRuleValidationRule.CSX_CMP_Amount_Limit_Multiple__c +
									'FM99999999.00)';
							}
						}
					}
					if (declineReason != '') {
						break;
					}
				}

				if (declineReason != '') {
					CSX_CMP_Utility.createNote(inputClaim.Id, null, null, 'Decline Reason', declineReason);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'generalRuleValidation',
				String.valueOf(inputClaim),
				ex
			);
		}
		return declineReason;
	}

	@AuraEnabled
	public static void declineClaim(string claimId) {
		Case declineCase = new Case();
		declineCase.Id = claimId;
		declineCase.Status = 'Declined';
		declineCase.CSX_CMP_Review__c = false;
		declineCase.CSX_CMP_System_Action_Toggle__c = !declineCase.CSX_CMP_System_Action_Toggle__c;
		Database.SaveResult updateDeclineClaim = Database.update(declineCase, false);
		CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_ClaimCreationHelper', 'declineClaim', updateDeclineClaim, 'Case');
	}

	public static void createRelatedDuplicateClaims(
		Map<Id, List<String>> caseOldIDToNewIDMap,
		Map<String, Map<String, String>> relatedClaimAndProduct,
		Set<Id> claimIdsforTotalCostofClaim
	) {
		List<CSX_CMP_Related_Claim__c> relatedClaimList = new List<CSX_CMP_Related_Claim__c>();
		List<String> existingRelatedClaims = new List<String>();

		try {
			if (!caseOldIDToNewIDMap.isEmpty()) {
				List<case> caseList = [
					SELECT Id, caseNumber
					FROM case
					WHERE Id IN :caseOldIDToNewIDMap.keySet()
					WITH SECURITY_ENFORCED
				];
				List<CSX_CMP_Related_Claim__c> relatedClaims = [
					SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Related_Claim__c
					FROM CSX_CMP_Related_Claim__c
					WHERE CSX_CMP_Claim__c = :caseOldIDToNewIDMap.keySet()
					WITH SECURITY_ENFORCED
				];
				for (CSX_CMP_Related_Claim__c relatedClaim : relatedClaims) {
					existingRelatedClaims.add(relatedClaim.CSX_CMP_Related_Claim__c);
				}
				Map<Id, String> caseIdNumberMap = new Map<Id, String>();
				for (Case newClaimRecord : caseList) {
					caseIdNumberMap.put(newClaimRecord.Id, newClaimRecord.caseNumber);
				}
				for (Id caseId : caseOldIDToNewIDMap.keySet()) {
					List<String> relatedClaimIds = caseOldIDToNewIDMap.get(caseId);
					for (String relatedClaim : relatedClaimIds) {
						if (!existingRelatedClaims.contains(relatedClaim)) {
							CSX_CMP_Related_Claim__c relatedClaimObj = new CSX_CMP_Related_Claim__c();
							relatedClaimObj.CSX_CMP_Claim__c = caseId;
							relatedClaimObj.CSX_CMP_Related_Claim__c = relatedClaim;
							relatedClaimObj.CSX_CMP_External_ID__c = caseIdNumberMap.get(caseId) + '_' + relatedClaim;
							if (relatedClaimAndProduct != null) {
								relatedClaimObj.CSX_CMP_Equipment_ID__c = relatedClaimAndProduct.get(relatedClaim).get('equipmentId') !=
									null
									? relatedClaimAndProduct.get(relatedClaim).get('equipmentId')
									: '';
								relatedClaimObj.CSX_CMP_VIN__c = relatedClaimAndProduct.get(relatedClaim).get('vin') != null
									? relatedClaimAndProduct.get(relatedClaim).get('vin')
									: '';
								relatedClaimObj.CSX_CMP_Claim_Group__c = relatedClaimAndProduct.get(relatedClaim).get('claimGroup') !=
									null
									? relatedClaimAndProduct.get(relatedClaim).get('claimGroup')
									: '';
							}
							relatedClaimList.add(relatedClaimObj);
						}
					}
				}
				if (relatedClaimList.size() > 0) {
					Database.SaveResult[] relatedClaimsInsertResultList = Database.insert(relatedClaimList, false);
					CSX_CMP_LoggerUtility.addApexDMLErrorLog(
						'CSX_CMP_ClaimCreationHelper',
						'createRelatedDuplicateClaims',
						relatedClaimsInsertResultList,
						'CSX_CMP_Related_Claim__c'
					);
				}

				if (!claimIdsforTotalCostofClaim.isEmpty()) {
					CSX_CMP_TotalCostofClaimHelper.updateTotalCostOfClaim(claimIdsforTotalCostofClaim);
				}
			}
		} catch (Exception e) {
			String parameters = JSON.serialize(relatedClaimList);
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createRelatedDuplicateClaims',
				parameters,
				e
			);
		}
	}

	/*
@description : This method is used to create related claim for LD Report 
@param : relatedClaimCreationMap - Map of LDR Id to new claim Id
*/
	public static void createRelatedClaimForLDReport(Map<String, String> relatedClaimCreationMap) {
		List<CSX_CMP_Related_LD_Report__c> relatedClaimsList = new List<CSX_CMP_Related_LD_Report__c>();
		try {
			if (relatedClaimCreationMap != null && !relatedClaimCreationMap.isEmpty()) {
				Map<Id, Case> claimMap = new Map<Id, Case>(
					[
						SELECT Id, CaseNumber, CSX_CMP_Paid_Amount__c
						FROM Case
						WHERE Id IN :relatedClaimCreationMap.values()
						WITH SECURITY_ENFORCED
					]
				);
				for (String ldrId : relatedClaimCreationMap.keySet()) {
					CSX_CMP_Related_LD_Report__c newClaim = new CSX_CMP_Related_LD_Report__c();
					String relatedClaim = relatedClaimCreationMap.get(ldrId);
					if (relatedClaim.length() > 18) {
						// newClaim.CSX_CMP_Claim__r = (Case) JSON.deserialize(relatedClaimCreationMap.get(ldrId), Case.class);
						Case claim = (Case) JSON.deserialize(relatedClaimCreationMap.get(ldrId), Case.class);
						newClaim.CSX_CMP_Claim__r = new Case(CSX_CMP_External_ID__c = claim.CSX_CMP_External_ID__c);
					} else {
						newClaim.CSX_CMP_Claim__c = relatedClaimCreationMap.get(ldrId);
					}
					newClaim.CSX_CMP_LD_Report__c = ldrId;
					newClaim.CSX_CMP_Paid_Amount__c = claimMap.get(relatedClaim).CSX_CMP_Paid_Amount__c;
					relatedClaimsList.add(newClaim);
				}
			}

			if (!relatedClaimsList.isEmpty()) {
				Database.SaveResult[] relatedClaimInsertResultList = Database.insert(relatedClaimsList, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'createRelatedClaimForLDReport',
					relatedClaimInsertResultList,
					'CSX_CMP_Related_LD_Report__c'
				);
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'createRelatedClaimForLDReport',
				string.valueOf(relatedClaimCreationMap),
				e
			);
		}
	}

	@AuraEnabled(cacheable=true)
	public static String getRoleAccessConfiguration() {
		try {
			User currentUser = [
				SELECT Id, Name, UserRole.Name
				FROM User
				WHERE Id = :UserInfo.getUserId()
				WITH SECURITY_ENFORCED
			];
			List<CSX_CMP_Role_Access_Configuration__mdt> roleAccessConfigList = new List<CSX_CMP_Role_Access_Configuration__mdt>();
			roleAccessConfigList = [
				SELECT
					Id,
					MasterLabel,
					CSX_CMP_Eligible_Claim_Type_for_Creation__c,
					CSX_CMP_Search_Layout_Access__c,
					CSX_CMP_Create_L_D_Reports__c,
					CSX_CMP_Create_Claim__c
				FROM CSX_CMP_Role_Access_Configuration__mdt
				WHERE MasterLabel = :currentUser.UserRole.Name
				WITH SECURITY_ENFORCED
			];

			Map<String, String> recordTypeMap = new Map<String, String>();
			Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
			for (String rtName : recordTypeInfoMap.keySet()) {
				recordTypeMap.put(rtName, recordTypeInfoMap.get(rtName).getRecordTypeId());
			}
			Map<String, Object> responseMap = new Map<String, Object>();
			responseMap.put('roleAccessConfigList', roleAccessConfigList);
			responseMap.put('recordTypeMap', recordTypeMap);
			return JSON.serialize(responseMap);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreationHelper', 'getRoleAccessConfiguration', '', e);
			return '';
		}
	}

	/**
@Description : This method is used to check if the user has permission to create distribution / Recharge claim and also check if user has custom permission to go ahead
@param : permissionName - Name of the permission to check
@return : Boolean - True if user has permission else False
*/
	@AuraEnabled(cacheable=true)
	public static Boolean isClaimCreationAllowed(String permissionName) {
		Boolean isClaimCreationAllowed = false;
		try {
			isClaimCreationAllowed = FeatureManagement.checkPermission(permissionName);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreationHelper', 'isClaimCreationAllowed', permissionName, e);
		}
		return isClaimCreationAllowed;
	}

	/*
@description : This method is used to unwrap the claim input map to wrapper
@param : claimDetails - Map of claim details in String, String format and some also serialized which are deserialized in this method
*/
	//METHOD TO CONVERT CLAIM INPUT MAP FROM ALL SOURCES TO WRAPPER
	public static CSX_CMP_NewClaimWrapper newClaimInputMaptoWrapper(Map<String, String> claimDetails) {
		CSX_CMP_NewClaimWrapper claimWrapper = new CSX_CMP_NewClaimWrapper();
		try {
			try {
				// claimWrapper.relatedClaimNumber = claimDetails.get('relatedClaim'); //this is used for backend Rev-RR - Payable Rchg Claim && Rev-RR Receivable  Rchg Claim [MR -00776]
				claimWrapper.claimType = claimDetails.get('claimType');
				claimWrapper.claimRecordType = claimDetails.get('claimRecordType');
				claimWrapper.claimAmount = claimDetails.get('claimAmount') != null
					? Decimal.valueOf(claimDetails.get('claimAmount'))
					: 0;
				claimWrapper.source = claimDetails.get('source');
				claimWrapper.senderSCAC = claimDetails.get('senderSCAC');
				claimWrapper.claimReason = claimDetails.get('claimReason');
				claimWrapper.customerClaimDate = claimDetails.get('customerClaimDate') != null
					? Date.valueOf(claimDetails.get('customerClaimDate'))
					: null;
				claimWrapper.previousClaimNumber = claimDetails.get('previousClaimNumber');
				claimWrapper.caseNumber = claimDetails.get('caseNumber');
				claimWrapper.shipCSXUserName = claimDetails.get('shipCSXUserName');
				claimWrapper.shipCSXUserId = claimDetails.get('shipCSXUserId');
				claimWrapper.supplierId = claimDetails.get('supplierId');
				claimWrapper.supplierClaimantName = claimDetails.get('supplierClaimantName');
				claimWrapper.supplierClaimantNumber = claimDetails.get('supplierClaimantNumber');
				claimWrapper.supplierClaimantSite = claimDetails.get('supplierClaimantSite');
				claimWrapper.customerName = claimDetails.get('customerName');
				claimWrapper.customerNumber = claimDetails.get('customerNumber');
				claimWrapper.customerSite = claimDetails.get('customerSite');
				claimWrapper.claimantReferenceNumber = claimDetails.get('claimantReferenceNumber');
				claimWrapper.notes = claimDetails.get('notes');
				claimWrapper.contractNumber = claimDetails.get('contractNumber');
				claimWrapper.periodBegin = claimDetails.get('claimPeriodBeginDate') != null
					? Date.valueOf(claimDetails.get('claimPeriodBeginDate'))
					: null;
				claimWrapper.periodEnd = claimDetails.get('claimPeriodEndDate') != null
					? Date.valueOf(claimDetails.get('claimPeriodEndDate'))
					: null;
				claimWrapper.derailmentFlag = claimDetails.get('derailment') != null
					? Boolean.valueOf(claimDetails.get('derailment'))
					: false;
				claimWrapper.companyFilingClaim = claimDetails.get('companyFilingClaim');
				claimWrapper.terminal = claimDetails.get('terminal');
				claimWrapper.causeCode = claimDetails.get('causeCode');
				claimWrapper.ruleCode = claimDetails.get('ruleCode');
				claimWrapper.ruleSecondary = claimDetails.get('ruleSecondary');
				claimWrapper.generalRuleNumber = claimDetails.get('generalRuleNumber');
				//claimWrapper.noWaybill                  = claimDetails.get('noWaybill') != null ? Boolean.valueOf(claimDetails.get('noWaybill')) : false;
				claimWrapper.gsControlNumber = (claimDetails.get('gsControlNumber') != null &&
					String.isNotBlank(claimDetails.get('gsControlNumber')))
					? Integer.valueOf(claimDetails.get('gsControlNumber'))
					: null;
				claimWrapper.messageDate = claimDetails.get('messageDate') != null
					? Date.valueOf(claimDetails.get('messageDate'))
					: null;
				claimWrapper.gsMessageDTTM = claimDetails.get('gsMessageTimestamp');
				claimWrapper.stControlNumber = (claimDetails.get('stControlNumber') != null &&
					String.isNotBlank(claimDetails.get('stControlNumber')))
					? Integer.valueOf(String.valueOf(claimDetails.get('stControlNumber')))
					: null;
				claimWrapper.interchangeControlNumber = (claimDetails.get('interchangeControlNumber') != null &&
					String.isNotBlank(claimDetails.get('interchangeControlNumber')))
					? Integer.valueOf(String.valueOf(claimDetails.get('interchangeControlNumber')))
					: null;
				claimWrapper.receiverSCAC = claimDetails.get('receiverSCAC');

				claimWrapper.currencyCode = claimDetails.get('currencyCode');
				claimWrapper.exchangeRate = claimDetails.get('exchangeRate') != null
					? Decimal.valueOf(claimDetails.get('exchangeRate'))
					: 0;
				claimWrapper.dealerCode = claimDetails.get('dealerCode');
				claimWrapper.dealerValue = claimDetails.get('dealerValue');
				claimWrapper.dealerSplc = claimDetails.get('dealerSPLC');
				claimWrapper.dealerReferenceNumber = claimDetails.get('dealerReferenceNumber') != null
					? string.valueOf(claimDetails.get('dealerReferenceNumber'))
					: '';
				claimWrapper.shipmentDate = claimDetails.get('shipmentDate') != null
					? Date.valueOf(claimDetails.get('shipmentDate'))
					: null;
				claimWrapper.contractCarrierDate = claimDetails.get('contractCarrierDate') != null
					? Date.valueOf(claimDetails.get('contractCarrierDate'))
					: null;
				claimWrapper.fldxFileReceivedDate = claimDetails.get('fldxFileReceivedDate') != null
					? Date.valueOf(claimDetails.get('fldxFileReceivedDate'))
					: null;
				//claimWrapper.railroadClaimReferenceNumber = claimDetails.get('railroadClaimReferenceNumber');
				claimWrapper.localInterlineTraffic = claimDetails.get('localInterlineTraffic');
				claimWrapper.transactionType = claimDetails.get('transactionType');
				claimWrapper.foreignCustomerClaimNumber = claimDetails.get('foreignCustomerClaimNumber');
				claimWrapper.foreignCustomerClaimAmount = claimDetails.get('foreignCustomerClaimAmount') != null
					? Decimal.valueOf(claimDetails.get('foreignCustomerClaimAmount'))
					: 0;
				claimWrapper.contactName = claimDetails.get('contactName');
				claimWrapper.phoneNumber = claimDetails.get('phoneNumber');
				claimWrapper.email = claimDetails.get('email');
				claimWrapper.sendEmail = claimDetails.get('sendEmail');
				claimWrapper.fax = claimDetails.get('fax');
				claimWrapper.adressLine1 = claimDetails.get('adressLine1');
				claimWrapper.adressLine2 = claimDetails.get('adressLine2');
				claimWrapper.cityName = claimDetails.get('city');
				claimWrapper.stateCode = claimDetails.get('state');
				claimWrapper.countryCode = claimDetails.get('country');
				claimWrapper.contactType = claimDetails.get('contactType');
				claimWrapper.companyName = claimDetails.get('company'); // field not mapped
				claimWrapper.ldReportNumber = claimDetails.get('ldReportNumber');
				claimWrapper.remarks = claimDetails.get('remarks');
				//Salvage Fields
				claimWrapper.scac = claimDetails.get('carrierCode');
				claimWrapper.salvageFileNumber = (claimDetails.get('salvageFileNumber') != null &&
					String.isNotBlank(claimDetails.get('salvageFileNumber')))
					? Integer.valueOf(claimDetails.get('salvageFileNumber'))
					: 0;
				claimWrapper.packageLostFlag = claimDetails.get('packageLost') != null
					? Boolean.valueOf(claimDetails.get('packageLost'))
					: false;
				claimWrapper.amount = claimDetails.get('amount') != null ? Decimal.valueOf(claimDetails.get('amount')) : 0;
				claimWrapper.proceedsCode = claimDetails.get('code');
				claimWrapper.claimantCode = claimDetails.get('claimantCode');

				//Check with Priya might be only for UI
				// claimWrapper.vin = claimDetails.get('vin');
				// claimWrapper.equipmentId = claimDetails.get('equipmentId');
				// claimWrapper.claimId = claimDetails.get('id'); // need to check with Priya

				//Sarath needs to give confirmation on below field
			} catch (Exception e) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_ClaimCreationHelper',
					'newClaimInputMaptoWrapper',
					string.valueOf(claimDetails),
					e
				);
			}
			claimWrapper.equipment = new List<CSX_CMP_NewClaimWrapper.EquipmentORClaimLine>();

			if (claimDetails.get('equipment') != null) {
				List<CSX_CMP_InterfaceUtility.ShipmentResponseWrapper> equipments = (List<CSX_CMP_InterfaceUtility.ShipmentResponseWrapper>) JSON.deserialize(
					claimDetails.get('equipment'),
					List<CSX_CMP_InterfaceUtility.ShipmentResponseWrapper>.class
				);
				for (CSX_CMP_InterfaceUtility.ShipmentResponseWrapper equipment : equipments) {
					CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equip = new CSX_CMP_NewClaimWrapper.EquipmentORClaimLine();
					equip.equipmentInitial = equipment.equipmentInitial;
					equip.equipmentNumber = equipment.equipmentNumber;
					equip.waybillNumber = equipment.waybillNumber;
					equip.waybillDate = equipment.waybillDate != null ? Date.valueOf(equipment.waybillDate) : null;
					equip.waybillControls = equipment.waybillControls;
					equip.stcc = equipment.stcc;
					equip.stccDescription = equipment.stccDescription;
					equip.originRoadNumber = equipment.originRoadNumber;
					equip.originAuditNumber = equipment.originAuditNumber;
					equip.actualOriginCityName = equipment.actualOriginCityName;
					equip.actualOriginStateCode = equipment.actualOriginStateCode;
					equip.actualOriginSCAC = equipment.actualOriginSCAC;
					equip.actualDestinationStateCode = equipment.actualDestinationStateCode;
					equip.actualDestinationCityName = equipment.actualDestinationCityName;
					// if(String.isBlank(equip.actualDestinationCityName)){
					// 	equip.actualDestinationCityName = equipment.actualDestinationCityName;
					// }
					equip.actualDestinationSCAC = equipment.actualDestinationSCAC;
					equip.destinationRoadNumber = equipment.destinationRoadNumber;
					equip.destinationAuditNumber = equipment.destinationAuditNumber;
					// equip.shipperName = equipment.shipper;
					// equip.consigneeName = equipment.consignee;
					// equip.shipperCode = equipment.shipperCode;
					// equip.consigneeCode = equipment.consigneeCode;
					equip.urrwinNumber = equipment.urrwinNumber;
					equip.urrwinDate = equipment.urrwinDate != null ? Date.valueOf(equipment.urrwinDate) : null;
					equip.challengeDate = (equipment.challengeDate != null && String.isNotBlank(equipment.challengeDate))
						? equipment.challengeDate
						: null;
					equip.isSettlementDate = (equipment.isSettlementDate != null && String.isNotBlank(equipment.isSettlementDate))
						? equipment.isSettlementDate
						: null;
					equip.adjustmentDate = (equipment.adjustmentDate != null && String.isNotBlank(equipment.adjustmentDate))
						? equipment.adjustmentDate
						: null;
					equip.billofLadingDate = (equipment.billofLadingDate != null && String.isNotBlank(equipment.billofLadingDate))
						? equipment.billofLadingDate
						: null;
					equip.billofLadingNumber = equipment.billofLadingNumber;
					equip.numberOfCars = equipment.numberOfCars;
					equip.weight = equipment.weight != null ? Decimal.valueOf(equipment.weight) : null;
					equip.unitRefundPrice = equipment.unitRefundPrice;
					equip.originalAmount = equipment.originalAmount; //earlier this was assigned equipment.refundAmount;
					equip.claimAmount = equipment.claimAmount;
					equip.receivedAmount = equipment.receivedAmount;
					equip.settlementAmount = equipment.settlementAmount;
					equip.unitType = equipment.unitType;
					equip.shipperName = equipment.shipperName;
					equip.shipperAddressLine1 = equipment.shipperAddressLine1;
					equip.shipperAddressLine2 = equipment.shipperAddressLine2;
					equip.shipperCityName = equipment.shipperCityName;
					equip.shipperStateCode = equipment.shipperStateCode;
					equip.shipperPostalCode = equipment.shipperPostalCode;
					equip.consigneeName = equipment.consigneeName;
					equip.consigneeAddressLine1 = equipment.consigneeAddressLine1;
					equip.consigneeAddressLine2 = equipment.consigneeAddressLine2;
					equip.consigneeCityName = equipment.consigneeCityName;
					equip.consigneeStateCode = equipment.consigneeStateCode;
					equip.consigneePostalCode = equipment.consigneePostalCode;
					equip.originSwitchRoad = equipment.originSwitchRoad;
					equip.destinationSwitchRoad = equipment.destinationSwitchRoad;
					equip.fullRoad = equipment.fullRoad;
					equip.equipmentPosition = equipment.equipmentPosition;
					equip.oncomingSCAC = equipment.oncomingSCAC;
					equip.offgoingSCAC = equipment.offgoingSCAC;
					equip.oncomingCityName = equipment.oncomingCityName;
					equip.oncomingStateCode = equipment.oncomingStateCode;
					equip.offgoingCityName = equipment.offgoingCityName;
					equip.offgoingStateCode = equipment.offgoingStateCode;
					equip.shipperAsClaimant = equipment.shipperAsClaimant;
					equip.piggybackPlanNumber = equipment.piggybackPlanNumber;
					equip.mvManufacturingCode = equipment.mvManufacturingCode;
					equip.multiCarCount = equipment.multiCarCount != null ? Integer.valueOf(equipment.multiCarCount) : null;
					equip.waybillFoundFlag = equipment.waybillFoundFlag;
					// equip.remarks                   = equipment.remarks;
					equip.freightBillDate = equipment.freightBillDate;
					equip.freightBillAmount = equipment.freightBillAmount;
					equip.flatCarId = equipment.flatCarId;
					equip.shipperLegalEntityId = equipment.shipperLegalEntityId;
					equip.consigneeLegalEntityId = equipment.consigneeLegalEntityId;
					equip.settlementAmount = equipment.settlementAmount;
					equip.patronCode = equipment.patronCode;
					equip.businessUnit = equipment.businessUnit;
					//commented below line on 30/7/24
					//equip.numberOfCars = equipment.totalCars != null ? Integer.valueOf(equipment.totalCars) : null;
					//previous Fields need clarity on this
					// equip.vinNum = equipment.vinNum;
					// equip.carsOrWeight = equipment.carsOrWeight;
					// equip.refundUnitRate = equipment.refundUnitRate;
					// equip.equipId = equipment.equipId;
					// equip.refundAmount = equipment.refundAmount;
					// equip.vin = equipment.vin;
					// equip.totalCars = equipment.totalCars;
					// equip.description = equipment.description;
					// equip.commodityNumber = equipment.commodityNumber;
					//claimWrapper.equipment.add(equip);
					// BELOW EQUIP AND VIN ARE USED FOR INSERTION INTO CLAIM WITH CERTAIN CLAIM TYPE
					claimWrapper.equipmentId = equipment.equipmentInitial + equipment.equipmentNumber;

					equip.products = new List<CSX_CMP_NewClaimWrapper.Product>();
					if (equipment.products != null && !equipment.products.isEmpty()) {
						equip.products = (List<CSX_CMP_NewClaimWrapper.Product>) JSON.deserialize(
							JSON.serialize(equipment.products),
							List<CSX_CMP_NewClaimWrapper.Product>.class
						);
					} else {
						equip.products = new List<CSX_CMP_NewClaimWrapper.Product>();
					}
					equip.distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
					if (equipment.distributions != null) {
						equip.distributions = (List<CSX_CMP_NewClaimWrapper.Distribution>) JSON.deserialize(
							JSON.serialize(equipment.distributions),
							List<CSX_CMP_NewClaimWrapper.Distribution>.class
						);
					} else {
						equip.distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
					}
					claimWrapper.equipment.add(equip);
				}

				if (claimWrapper.equipment.size() > 0) {
					for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equip : claimWrapper.equipment) {
						if (equip.products.size() > 0) {
							for (CSX_CMP_NewClaimWrapper.Product product : equip.products) {
								if (String.isNotBlank(product.vin)) {
									claimWrapper.vin = product.vin;
									break;
								}
							}
						}
					}
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'newClaimInputMaptoWrapper',
				string.valueOf(claimWrapper),
				e
			);
		}
		return claimWrapper;
	}

	@AuraEnabled(cacheable=true)
	public static List<sObject> getClaimStatusHistory(String claimId) {
		try {
			List<Object> collectionObject = new List<Object>();
			List<CaseHistory> caseHistory = [
				SELECT Id, Field, OldValue, NewValue, CreatedDate
				FROM CaseHistory
				WHERE CaseId = :claimId AND Field = 'Status'
				WITH SECURITY_ENFORCED
				ORDER BY CreatedDate ASC
			];

			List<CSX_CMP_Claim_Status_History__c> claimStatusHistory = [
				SELECT Id, CSX_CMP_Status__c, CSX_CMP_Event_Date__c
				FROM CSX_CMP_Claim_Status_History__c
				WHERE CSX_CMP_Claim__c = :claimId AND CSX_CMP_Status__c != NULL
				WITH SECURITY_ENFORCED
				ORDER BY CSX_CMP_Event_Date__c ASC
			];

			Map<String, String> monthMap = new Map<String, String>();
			monthMap.put('JAN', '01');
			monthMap.put('FEB', '02');
			monthMap.put('MAR', '03');
			monthMap.put('APR', '04');
			monthMap.put('MAY', '05');
			monthMap.put('JUN', '06');
			monthMap.put('JUL', '07');
			monthMap.put('AUG', '08');
			monthMap.put('SEP', '09');
			monthMap.put('OCT', '10');
			monthMap.put('NOV', '11');
			monthMap.put('DEC', '12');

			if (!caseHistory.isEmpty()) {
				Map<String, Object> firstObj = new Map<String, Object>();
				firstObj.put('eventDate', caseHistory[0].CreatedDate);
				firstObj.put('status', caseHistory[0].OldValue);
				collectionObject.add(firstObj);
			}

			for (CaseHistory history : caseHistory) {
				Map<String, Object> obj = new Map<String, Object>();
				obj.put('eventDate', history.CreatedDate);
				obj.put('status', history.NewValue);
				collectionObject.add(obj);
			}

			for (CSX_CMP_Claim_Status_History__c history : claimStatusHistory) {
				String eventDate = history.CSX_CMP_Event_Date__c;
				if (eventDate != null) {
					String[] dateTimeArray = eventDate.split(' ');
					String[] dateArray = dateTimeArray[0].split('-');
					String month = monthMap.get(dateArray[1]);
					String formattedDate = dateArray[2] + '-' + month + '-' + dateArray[0];
					// history.CSX_CMP_Event_Date__c = formattedDate+'T'+dateTimeArray[1]+'Z';
					history.CSX_CMP_Event_Date__c = formattedDate + ' ' + dateTimeArray[1];
				}

				Map<String, Object> obj = new Map<String, Object>();

				obj.put('eventDate', history.CSX_CMP_Event_Date__c);
				obj.put('status', history.CSX_CMP_Status__c);
				collectionObject.add(obj);
			}
			//collectionObject.sort();

			if (!caseHistory.isEmpty()) {
				return caseHistory;
			} else if (!claimStatusHistory.isEmpty()) {
				return claimStatusHistory;
			} else {
				return new List<sObject>();
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreationHelper', 'getClaimStatusHistory', claimId, e);
			return new List<sObject>();
		}
	}

	public static CSX_CMP_NewClaimWrapper getNewClaimWrapper(Id stagingRecordId) {
		CSX_CMP_NewClaimWrapper claimWrapper = new CSX_CMP_NewClaimWrapper();
		try {
			contentdocumentlink cd = [
				SELECT ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :stagingRecordId
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			ContentVersion cv = [
				SELECT Id, VersionData
				FROM ContentVersion
				WHERE ContentDocumentId = :cd.ContentDocumentId
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			claimWrapper = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
				cv.VersionData.toString(),
				CSX_CMP_NewClaimWrapper.class
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'getNewClaimWrapper',
				string.valueOf(claimWrapper),
				e
			);
		}
		return claimWrapper;
	}

	public static void updateStagingRecord(CSX_CMP_Creation_Request__c stagingRecord) {
		try {
			Database.SaveResult updateStagingRecord = Database.update(stagingRecord, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'updateStagingRecord',
				updateStagingRecord,
				'CSX_CMP_Creation_Request__c'
			);
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationHelper',
				'updateStagingRecord',
				string.valueOf(stagingRecord),
				e
			);
		}
	}
}