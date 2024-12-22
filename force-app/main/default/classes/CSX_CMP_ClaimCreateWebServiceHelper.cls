/**************************************************************************************
/*
@author: Infosys
Apex Class Name     : CSX_CMP_ClaimCreateWebServiceHelper
@description        : Helper Class for Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           22/04/2023       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_ClaimCreateWebServiceHelper {
	/*
    @description : Method to validate input request for mandatory fields and data type
    @param : claimInputWrapper - Wrapper class object
    @return : responseMap - Map of validation status and message
    */
	public static map<Boolean, String> checkValidation(CSX_CMP_NewClaimWrapper claimInputWrapper) {
		Map<Boolean, String> responseMap = new Map<Boolean, String>();
		Boolean isValid = true;
		try {
			String supplierClaimantNumber;
			String supplierClaimantName;
			String senderSCAC;
			String accountRecordTypeName = 'Location';

			if (
				String.isBlank(claimInputWrapper.source) ||
				String.isBlank(claimInputWrapper.claimType) ||
				String.isBlank(String.valueOf(claimInputWrapper.claimAmount)) ||
				String.isBlank(String.valueOf(claimInputWrapper.customerClaimDate))
			) {
				isValid = false;
				responseMap.put(
					isValid,
					'One of the Mandatory fields are missing: Source/ClaimType/ClaimAmount/CustomerClaimDate'
				);
				return responseMap;
			}

			if (
				claimInputWrapper.source != 'Customer Service' &&
				(claimInputWrapper.equipment[0].products[0].vin == null ||
				claimInputWrapper.equipment[0].products[0].vin == '' ||
				claimInputWrapper.equipment[0].products[0].vin.length() != 17)
			) {
				isValid = false;
				responseMap.put(isValid, 'Invalid VIN number');
				return responseMap;
			}

			// if (claimInputWrapper.source == 'Customer Service') {
			// 	/*if (
			// 		String.isBlank(claimInputWrapper.supplierClaimantName) ||
			// 		String.isBlank(claimInputWrapper.supplierClaimantNumber)
			// 	) {
			// 		isValid = false;
			// 		responseMap.put(
			// 			isValid,
			// 			'One of the Mandatory fields are missing:supplierClaimantName/supplierClaimantNumber'
			// 		);
			// 		return responseMap;
			// 	}*/
			// } else if (claimInputWrapper.source == 'EDI') {
			// 	// if (String.isBlank(claimInputWrapper.senderSCAC)) {
			// 	// 	isValid = false;
			// 	// 	responseMap.put(isValid, 'senderSCAC Should be Mandatory');
			// 	// 	return responseMap;
			// 	// }
			// }

			String supplierId;
			String supplierQuery = 'SELECT Id FROM Account ';
			String whereClause = '';
			if (claimInputWrapper.source == 'Customer Service') {
				if (!(String.isBlank(claimInputWrapper.supplierClaimantNumber))) {
					supplierClaimantNumber = claimInputWrapper.supplierClaimantNumber;
					String condition = 'AccountNumber =: supplierClaimantNumber'; // '\''; // String.escapeSingleQuotes(claimInputWrapper.supplierClaimantNumber) + // '\'' + // 'AccountNumber = ' +
					if (whereClause != '') {
						whereClause +=
							' AND ' +
							condition +
							'AND RecordType.DeveloperName = "Location" AND Type = "Supplier" AND Location_Type__c= "Billing Address"';
					} else {
						whereClause += condition;
					}
				}
				if (!(String.isBlank(claimInputWrapper.supplierClaimantName))) {
					supplierClaimantName = claimInputWrapper.supplierClaimantName;
					String condition = 'Name =: supplierClaimantName'; // '\''; // String.escapeSingleQuotes(claimInputWrapper.supplierClaimantName) + // '\'' + // 'Name = ' +
					if (whereClause != '') {
						whereClause += ' AND ' + condition; //+ ' AND RecordType.DeveloperName = "Location"';
					} else {
						whereClause += condition;
					}
				}
			}

			if (claimInputWrapper.source == 'EDI') {
				if (String.isNotBlank(claimInputWrapper.senderSCAC)) {
					senderSCAC = claimInputWrapper.senderSCAC;
					String condition = 'CSX_CMP_FC_EDI_Sender_ID__c =: senderSCAC'; // '\''; // String.escapeSingleQuotes(claimInputWrapper.senderSCAC) + // '\'' + // 'CSX_CMP_FC_EDI_Sender_ID__c = ' +
					if (whereClause != '') {
						whereClause += ' AND ' + condition; // + ' AND RecordType.DeveloperName = "Location"';
					} else {
						whereClause += condition;
					}
				}
				if (claimInputWrapper.claimAmount != null) {
					claimInputWrapper.claimAmount = claimInputWrapper.claimAmount / 100;
				}
				if (!claimInputWrapper.equipment[0].products[0].customerdamages.isEmpty()) {
					for (CSX_CMP_NewClaimWrapper.CustomerDamage cd : claimInputWrapper.equipment[0].products[0].customerdamages) {
						if (cd.amount != null) {
							cd.amount = cd.amount / 100;
						}
					}
				}
			}

			if (whereClause != '') {
				supplierQuery += ' WHERE ' + whereClause + ' AND RecordType.DeveloperName =:accountRecordTypeName';
			}
			supplierQuery += ' LIMIT 1';
			List<Account> suppliers = new List<Account>();
			if (supplierQuery != 'SELECT Id FROM Account  LIMIT 1') {
				suppliers = Database.query(String.escapeSingleQuotes(supplierQuery));
			}
			if (!suppliers.isEmpty()) {
				claimInputWrapper.supplierId = suppliers[0].Id;
				isValid = true;
				responseMap.put(isValid, '');
			} 
			// else {
			// 	isValid = false;
			// 	responseMap.put(isValid, 'Invalid Supplier Details');
			// }
		} catch (Exception e) {
			// CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreateWebService','checkValidation',JSON.serialize(claimInputWrapper),e);
			isValid = false;

			responseMap.put(isValid, e.getMessage() + '  ' + e.getStackTraceString());
		}
		return responseMap;
	}

	/*
    @description : Method to check the number of active queueable jobs
    @return : createClaim - Boolean value to create claim
    */
	public static Boolean checkQueueableValidation() {
		Boolean createClaim = false;
		try {
			Integer activeQueueables = [
				SELECT COUNT()
				FROM AsyncApexJob
				WHERE
					JobType = 'Queueable'
					AND Status IN ('Queued', 'Processing', 'Preparing')
					AND ApexClass.Name IN (
						'CSX_CMP_ClaimCreationQueueable',
						'CSX_CMP_PostClaimCreationAPIQueueable',
						'CSX_CMP_PostClaimCreationQueueable'
					)
				// WITH SECURITY_ENFORCED
			];
			if (activeQueueables < 5) {
				createClaim = true;
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimCreateWebServiceHelper', 'checkQueueableValidation', '', e);
		}
		return createClaim;
	}

	/*
    @description : Method to update claim with new details in salesforce and submit for approval for Intermodal Service Claim
    @param : claimId - Claim Id
    @param : claimInputWrapper - Wrapper class object
    */
	public static Boolean updateClaimandSubmitforApproval(Case claim, CSX_CMP_NewClaimWrapper claimInputWrapper) {
		Boolean isValid = false;
		try {
			// Case claim = new Case(Id = claimId);
			claim.Status = 'Open';
			claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
			claim.CSX_CMP_Claim_Amount__c = claimInputWrapper.claimAmount;
			Database.SaveResult sr = Database.update(claim, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_ClaimCreateWebService',
				'updateClaimandSubmitforApproval',
				sr,
				'Case'
			);
			//update claim with new details in salesforce and submit for approval (Ref - CMP-E-0432)
			// CSX_CMP_SubmitClaimforApprovalHelper.initiateApprovalProcess(claim.Id);
			CSX_CMP_Creation_Request__c claimStagingRecord = [
				SELECT Id, CSX_CMP_Claim__c
				FROM CSX_CMP_Creation_Request__c
				WHERE CSX_CMP_Claim__c = :claim.Id
				WITH SECURITY_ENFORCED
			];
			system.enqueueJob(
				new CSX_CMP_PostClaimCreationQueueable('SubmitClaimforApprovalForIntermodal', claimStagingRecord)
			);
			isValid = true;
		} catch (Exception e) {
			isValid = false;
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreateWebService',
				'updateClaimandSubmitforApproval',
				JSON.serialize(claimInputWrapper),
				e
			);
		}
		return isValid;
	}

	public static Map<Boolean, String> checkPicklistValues(CSX_CMP_NewClaimWrapper claimInputWrapper) {
		String message = '';
		Boolean isValid = true;
		if (claimInputWrapper.claimType != null) {
			List<String> picklistValues = getPickList('Case', 'Type');
			if (!picklistValues.contains(claimInputWrapper.claimType)) {
				isValid = false;
				message += 'Invalid Claim Type ; ';
			}
		}

		if (claimInputWrapper.source != null) {
			List<String> picklistValues = getPickList('Case', 'Origin');
			if (!picklistValues.contains(claimInputWrapper.source)) {
				isValid = false;
				message += 'Invalid Claim Source ; ';
			}
		}

		if (claimInputWrapper.claimReason != null) {
			List<String> picklistValues = getPickList('Case', 'CSX_CMP_Claim_Reason__c');
			if (!picklistValues.contains(claimInputWrapper.claimReason)) {
				isValid = false;
				message += 'Invalid Claim Reason ; ';
			}
		}

		if (claimInputWrapper.causeCode != null) {
			List<String> picklistValues = getPickList('Case', 'CSX_CMP_FCD_Cause_Code__c');
			if (!picklistValues.contains(claimInputWrapper.causeCode)) {
				isValid = false;
				message += 'Invalid Cause Code ; ';
			}
		}

		if (claimInputWrapper.proceedsCode != null) {
			List<String> picklistValues = getPickList('Case', 'CSX_CMP_Salvage_Code__c');
			if (!picklistValues.contains(claimInputWrapper.proceedsCode)) {
				isValid = false;
				message += 'Invalid Salvage Code ; ';
			}
		}

		if (claimInputWrapper.ruleCode != null) {
			List<String> picklistValues = getPickList('Case', 'CSX_CMP_FCD_Rule_Code__c');
			if (!picklistValues.contains(claimInputWrapper.ruleCode)) {
				isValid = false;
				message += 'Invalid Rule Code ; ';
			}
		}

		if (claimInputWrapper.terminal != null) {
			List<String> picklistValues = getPickList('Case', 'CSX_CMP_Terminal__c');
			if (!picklistValues.contains(claimInputWrapper.terminal)) {
				isValid = false;
				message += 'Invalid Terminal ; ';
			}
		}

		List<CSX_CMP_NewClaimWrapper.Product> products = new List<CSX_CMP_NewClaimWrapper.Product>();
		if (claimInputWrapper.equipment != null && !claimInputWrapper.equipment.isEmpty()) {
			for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine eq : claimInputWrapper.equipment) {
				if (eq.products != null && !eq.products.isEmpty()) {
					products.addAll(eq.products);
				}
			}
		}

		List<CSX_CMP_NewClaimWrapper.CustomerDamage> customerDamages = new List<CSX_CMP_NewClaimWrapper.CustomerDamage>();
		if (products != null && !products.isEmpty()) {
			for (CSX_CMP_NewClaimWrapper.Product product : products) {
				if (product.uom != null) {
					List<String> picklistValues = getPickList('CSX_CMP_Product__c', 'CSX_CMP_UOM__c');
					if (!picklistValues.contains(product.uom)) {
						isValid = false;
						message += 'Invalid UOM on Product ; ';
					}
				}

				if (product.customerDamages != null) {
					customerDamages.addAll(product.customerDamages);
				}
			}
		}

		if (customerDamages != null && !customerDamages.isEmpty()) {
			for (CSX_CMP_NewClaimWrapper.CustomerDamage cd : customerDamages) {
				if (cd.type != null) {
					List<String> picklistValues = getPickList('CSX_CMP_Customer_Damage__c', 'CSX_CMP_Type__c');
					if (!picklistValues.contains(cd.type)) {
						isValid = false;
						message += 'Invalid Damage Type ; ';
					}
				}

				if (cd.area != null) {
					List<String> picklistValues = getPickList('CSX_CMP_Customer_Damage__c', 'CSX_CMP_Area__c');
					if (!picklistValues.contains(cd.area)) {
						isValid = false;
						message += 'Invalid Damage Area ; ';
					}
				}

				if (cd.severity != null) {
					List<String> picklistValues = getPickList('CSX_CMP_Customer_Damage__c', 'CSX_CMP_Severity__c');
					if (!picklistValues.contains(cd.severity)) {
						isValid = false;
						message += 'Invalid Damage Severity ; ';
					}
				}
			}
		}

		Map<Boolean, String> responseMap = new Map<Boolean, String>();
		responseMap.put(isValid, message);
		return responseMap;
	}

	private static List<String> getPickList(String objApi, String fieldApi) {
		List<string> picklistvalues = new List<string>();
		for (
			Schema.PicklistEntry pickListVal : Schema.getGlobalDescribe()
				.get(objApi)
				.getDescribe()
				.fields.getMap()
				.get(fieldApi)
				.getDescribe()
				.getPicklistValues()
		) {
			picklistvalues.add(pickListVal.getValue());
		}
		return picklistvalues;
	}
}