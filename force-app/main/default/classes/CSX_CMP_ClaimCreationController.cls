/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimCreationController
Function            : Class to keep all reusuable methods
Modification Log    :
@RICEFW reference   : CMP-E-0411
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
*************************************************************************************/
public with sharing class CSX_CMP_ClaimCreationController {
	//method to submit a new from ShipCSX/Experiance cloud
	public static string submitNewClaim(CSX_CMP_NewClaimWrapper inputClaimDetails) {
		string returnResponse;
		CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper = CSX_CMP_BusinessRulesUtility.newClaimWrapperToClaimWrapper(
			inputClaimDetails
		);
		Map<Id, String> duplicateClaimMap = CSX_CMP_BusinessRulesUtility.runDuplicateBusinessRules(
			null,
			claimWrapper,
			null
		);
		List<String> duplicateClaimList = duplicateClaimMap.values();
		try {
			if (duplicateClaimList.isEmpty()) {
				//Create Record in Staging Table
				CSX_CMP_Creation_Request__c claimStagingRecord = CSX_CMP_ClaimCreationHelper.createStagingRecord(
					inputClaimDetails,
					JSON.serialize(duplicateClaimList),
					0
				);

				//start claim creation process
				Map<String, String> responseMap = CSX_CMP_ClaimCreationHelper.createNewClaim(claimStagingRecord);
				if (responseMap.get('success') != null) {
					string successResponse = responseMap.get('success');
					Map<string, object> successMap = (Map<string, object>) JSON.deserializeUntyped(successResponse);
					returnResponse = string.valueof(successMap.get('CaseNumber'));
				}
			} else {
				//add logic to send the error message with existing Claim details
				returnResponse = 'duplicates found :' + String.valueof(duplicateClaimList);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'submitNewClaim',
				string.valueOf(inputClaimDetails),
				ex
			);
		}

		return returnResponse;
	}

	//METHOD TO CREATE NEW CLAIM FROM CUSTOM SALESFORCE SCREEN
	@AuraEnabled
	public static ClaimResponseWrapper createNewClaim(
		Map<String, String> inputClaimDetails,
		List<String> duplicateClaims
	) {
		Case caseRec = new Case();
		ClaimResponseWrapper response = new ClaimResponseWrapper();
		try {
			CSX_CMP_NewClaimWrapper inputClaimWrapper = CSX_CMP_ClaimCreationHelper.newClaimInputMaptoWrapper(
				inputClaimDetails
			);
			//Create Record in Staging Table
			CSX_CMP_Creation_Request__c claimStagingRecord = CSX_CMP_ClaimCreationHelper.createStagingRecord(
				inputClaimWrapper,
				JSON.serialize(duplicateClaims),
				0
			);

			Map<String, String> responseFromNewClaim = CSX_CMP_ClaimCreationHelper.createNewClaim(claimStagingRecord);

			if (responseFromNewClaim.get('success') != null) {
				Map<String, String> detailMap = (Map<String, String>) JSON.deserialize(
					responseFromNewClaim.get('success'),
					Map<String, String>.class
				);
				caseRec = [
					SELECT Id, CaseNumber, CSX_CMP_ECM_Link__c, Origin, RecordType.DeveloperName
					FROM Case
					WHERE CaseNumber = :detailMap.get('CaseNumber')
					WITH SECURITY_ENFORCED
				];
				response.claimNum = caseRec.CaseNumber;
				response.claimId = caseRec.Id;
				response.ecmLink = caseRec.CSX_CMP_ECM_Link__c;
				response.declineReason = detailMap.get('DeclineReason');
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'CreateNewClaim',
				string.valueOf(inputClaimDetails),
				ex
			);
		}
		return response;
	}

	//METHOD TO CHECK FOR DUPLICATE CLAIMS.
	@AuraEnabled
	public static Map<Id, String> checkforDuplicates(Map<String, String> inputClaimDetails) {
		CSX_CMP_NewClaimWrapper inputClaimWrap = CSX_CMP_ClaimCreationHelper.newClaimInputMaptoWrapper(inputClaimDetails);
		CSX_CMP_BusinessRulesUtility.ClaimWrapper claimWrapper = CSX_CMP_BusinessRulesUtility.newClaimWrapperToClaimWrapper(
			inputClaimWrap
		);
		Map<Id, String> duplicateClaimMap = new Map<Id, String>();
		try {
			//to check for potential duplicates and display warning on screen, shipCSX, Customer Service screen
			duplicateClaimMap = CSX_CMP_BusinessRulesUtility.runDuplicateBusinessRules(null, claimWrapper, null);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'checkforDuplicates',
				string.valueOf(inputClaimWrap),
				ex
			);
		}
		return duplicateClaimMap;
	}

	@AuraEnabled(cacheable=true)
	public static List<Account> supplierSiteSearch(String name, String state, String city, String claimType) {
		List<Account> accountRecords = new List<Account>();
		try {
			String nameWithLike1;
			String nameWithLike2;
			String nameWithLike3;
			String stateWithLike;
			String cityWithLike;
			List<String> filters = new List<String>();

			if (String.isBlank(name) && String.isBlank(state) && String.isBlank(city)) {
				return accountRecords;
			}

			if (String.isNotBlank(name)) {
				if(name.contains(' ')){
					name = name.replaceAll(' ', '%');
				}
				nameWithLike1 = '%' + String.escapeSingleQuotes(name) + '%';
				nameWithLike2 = String.escapeSingleQuotes(name) + '%';
				nameWithLike3 = '%' + String.escapeSingleQuotes(name);
				filters.add(
					'(Name like :nameWithLike1 OR Name like :nameWithLike2 OR Name like :nameWithLike3 OR Name = :name)'
				);
			}

			if (String.isNotBlank(state)) {
				stateWithLike = '%' + String.escapeSingleQuotes(state) + '%';
				filters.add('BillingState like :stateWithLike');
			}

			if (String.isNotBlank(city)) {
				cityWithLike = '%' + String.escapeSingleQuotes(city) + '%';
				filters.add('BillingCity like :cityWithLike');
			}
			String query = 'SELECT Name, AccountNumber,  Site, Payment_Method__c, BillingAddress, National_Account__c, Status__c, Patron_Code__c, Le_Code__c, Tax_Id__c,Bank_Name__c,Bank_Account_Number__c FROM Account ';
			String type = 'Supplier';
			String status = 'Active';
			String recordType = 'Location';
			String locationType = 'Billing Address';

			query += ' WHERE type = :type AND Status__c = :status AND RecordType.DeveloperName = :recordType AND Location_Type__c = :locationType';

			if (claimType == 'FC RR Inbound Claim' || claimType == 'Recharges Inbound Claim') {
				query += ' AND CSX_CMP_FC_Railroad_Road_Code__c != null';
			}

			if (filters.size() > 0) {
				query += ' AND (';
				query += String.join(filters, ' AND ');
				query += ')';
			}
			accountRecords = Database.query(String.escapeSingleQuotes(query));
		} catch (exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'searchSupplierAccounts',
				string.valueOf(accountRecords),
				ex
			);
		}

		return accountRecords;
	}

	@AuraEnabled(cacheable=true)
	public static List<CSX_CMP_Contract__c> getContractOptions(String claimantId) {
		List<CSX_CMP_Contract__c> contractRecords = new List<CSX_CMP_Contract__c>();
		try {
			contractRecords = [
				SELECT
					Id,
					Name,
					CSX_CMP_Status__c,
					CSX_CMP_Customer_Name__c,
					CSX_CMP_Remaining_Budget__c,
					CSX_CMP_Claim_Type__c,
					(SELECT Id, CSX_CMP_Case_Number_Formula__c, CSX_CMP_Period_Begin__c, CSX_CMP_Period_End__c FROM Claims__r)
				FROM CSX_CMP_Contract__c
				WHERE CSX_CMP_Customer_Name__c = :claimantId AND CSX_CMP_Status__c = 'Active'
				WITH SECURITY_ENFORCED
			];
		} catch (exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'getContractOptions',
				string.valueOf(contractRecords),
				ex
			);
		}

		return contractRecords;
	}

	@AuraEnabled(cacheable=true)
	public static List<Account> getSuppliersForRailRoad() {
		List<Account> railroadSuppliers = new List<Account>();
		try {
			railroadSuppliers = [
				SELECT Id, Name
				FROM Account
				WHERE
					Type = 'Supplier'
					AND CSX_CMP_Rev_Railroad_Road_Code__c != NULL
					AND RecordType.DeveloperName = 'Location'
					AND Location_Type__c = 'Billing Address'
				WITH SECURITY_ENFORCED
				ORDER BY Name
			];
		} catch (exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'getSuppliersForRailRoad',
				string.valueOf(railroadSuppliers),
				ex
			);
		}

		return railroadSuppliers;
	}

	@AuraEnabled(cacheable=true)
	public static Map<string, string> getGeneralRules() {
		//List<String> generalRules = new List<String>();
		Map<String, string> generalRules = new Map<String, string>();
		Id businessRuleRecTypeId = Schema.SObjectType.CSX_CMP_Business_Rule__c.getRecordTypeInfosByName()
			.get('RR General Rule')
			.getRecordTypeId();
		try {
			for (CSX_CMP_Business_Rule__c businessRules : [
				SELECT Name, CSX_CMP_Rule_Name__c, CSX_CMP_Status__c, CSX_CMP_Comments__c
				FROM CSX_CMP_Business_Rule__c
				WHERE
					recordTypeId = :businessRuleRecTypeId
					AND CSX_CMP_Status__c = 'Valid'
					AND CSX_CMP_Start_Date__c <= Today
					AND (CSX_CMP_End_Date__c = NULL
					OR CSX_CMP_End_Date__c >= Today)
				WITH SECURITY_ENFORCED
			]) {
				//generalRules.add(businessRules.CSX_CMP_Rule_Name__c);
				generalRules.put(businessRules.CSX_CMP_Rule_Name__c, businessRules.CSX_CMP_Comments__c);
			}
		} catch (exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'getGeneralRules',
				string.valueOf(generalRules),
				ex
			);
		}
		return generalRules;
	}

	@AuraEnabled
	public static String checkRelatedClaim(string relatedClaimNumber, string claimType) {
		string isStatus = '';
		try {
			Map<String, String> claimTypeMap = new Map<String, String>();
			String type;
			claimTypeMap.put('Rev-RR - Payable Rchg Claim', 'Rev-RR - Receivable Claim');
			claimTypeMap.put('Rev-RR - Receivable Rchg Claim', 'Rev-RR - Payable Claim');
			String query = 'Select id ,CaseNumber,Status,Type from Case where CaseNumber =: relatedClaimNumber '; //and Status = \'Closed\'
			// if(claimType == 'Rev-RR - Payable Rchg Claim'){
			//     query += 'AND Type = \'Rev-RR - Receivable Claim\'';
			// }else if(claimType == 'Rev-RR - Receivable Rchg Claim'){
			//     query += 'AND Type = \'Rev-RR - Payable Claim\'';
			// }
			if (claimTypeMap.containsKey(claimType)) {
				type = claimTypeMap.get(claimType);
				query += 'AND Type = :type';
			}
			List<Case> lstClaims = Database.query(String.escapeSingleQuotes(query));
			if (lstClaims.size() > 0 && lstClaims[0].Status == 'Closed') {
				isStatus = lstClaims[0].Status;
			} else if (lstClaims.size() > 0) {
				isStatus = lstClaims[0].Status;
			}
		} catch (exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimCreationController',
				'checkRelatedClaim',
				string.valueOf(relatedClaimNumber),
				ex
			);
		}
		return isStatus;
	}

	// wrapper to form the response format
	public class ClaimResponseWrapper {
		@AuraEnabled
		public String claimNum { get; set; }
		@AuraEnabled
		public String claimId { get; set; }
		@AuraEnabled
		public String ecmLink { get; set; }
		@AuraEnabled
		public String declineReason { get; set; }
	}
}