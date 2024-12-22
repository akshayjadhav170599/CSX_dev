/**
@Author       - Infosys
@Name         - CSX_CMP_HandleNettingCalculation
@Created Date - 12/17/2023
@Description  - This Apex class is used to run netting process
@RICEFW reference - CMP-E-0437
*/
public with sharing class CSX_CMP_HandleNettingCalculation {
	@AuraEnabled(cacheable=true)
	public static CSX_CMP_Role_Access_Configuration__mdt getClaimRecordTypeRole() {
		String roleDetails;
		CSX_CMP_Role_Access_Configuration__mdt roleMdt;
		try {

			User usr = [SELECT Id, UserRole.DeveloperName FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];

			if (String.isNotBlank(usr.UserRole.DeveloperName)) {
				roleMdt = CSX_CMP_Role_Access_Configuration__mdt.getInstance(usr.UserRole.DeveloperName);
			}

			// if (String.isNotblank(roleMdt.MasterLabel)) {
			// 	roleDetails = roleMdt.MasterLabel;
			// }
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_ClaimSearchController',
				'getClaimSearchBasedOnRole',
				JSON.serialize(roleDetails),
				ex
			);
		}
		return roleMdt;
	}

	@AuraEnabled
	public static List<CalculateNettingCalculationWrapper> calculateNettingResults(
		string claimCategory,
		string servicePeriod,
		string runType
	) {
		List<CalculateNettingCalculationWrapper> nettingResults = new List<CalculateNettingCalculationWrapper>();
		try {
			List<Case> lstClaims = new List<Case>();
			String claimQuery = '';
			claimQuery = 'SELECT Id,CaseNumber,Type, Status,CSX_CMP_Supplier_Claimant__r.Status__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_Operating_Unit__c,RecordType.DeveloperName,CSX_CMP_Supplier_Claimant_Site__c,CSX_CMP_Customer__r.Name,CSX_CMP_Customer__c,CSX_CMP_Customer_Site__c,CSX_CMP_Supplier_Claimant__c,CSX_CMP_Claimant_Ref_Num__c,CSX_CMP_Supplier_Claimant__r.Name,CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c,CSX_CMP_Netting_Claim_Ref_Number__c,CSX_CMP_Netting_Claim_Ref_Number__r.CaseNumber,CSX_CMP_System_Action_Toggle__c, CSX_CMP_Service_Period__c,CSX_CMP_Case_Number_Formula__c, CSX_CMP_Claim_Amount__c,CreatedDate,CSX_CMP_Claim_Date__c FROM Case WHERE CSX_CMP_Supplier_Claimant__c != null ';
			string whereClause = ' AND CSX_CMP_Service_Period__c =\'' + servicePeriod + '\'';

			//Date todayDate = date.TODAY();
			if (claimCategory == 'Freight') {
				whereClause +=
					' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c != null AND RecordType.DeveloperName =\'' +
					claimCategory +
					'\' AND Type IN (\'FC RR Inbound Claim\',\'FC RR Outbound Claim\',\'Recharges Inbound Claim\',\'Recharges Outbound Claim\')';
				if (runType == 'View') {
					// Updated by Subodh on 12th July as active from and active to fields are deleted
					// whereClause += ' AND status = \'Closed\' AND CSX_CMP_Netting_Claim_Ref_Number__c != null AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_From__c <=:todayDate AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_To__c >=:todayDate ';
					whereClause += ' AND CSX_CMP_Netting_Claim_Ref_Number__c != null  AND status = \'Closed\' AND CSX_CMP_Supplier_Claimant__r.Status__c = \'Active\'';
				} else {
					whereClause += ' AND status = \'Pending Monthly Settlement\'';
				}
			} else if (claimCategory == 'Revenue_Railroad') {
				whereClause +=
					' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c != null AND RecordType.DeveloperName =\'' +
					claimCategory +
					'\' AND Type IN (\'Rev-RR - Payable Claim\',\'Rev-RR - Receivable Claim\',\'Rev-RR - Payable Rchg Claim\',\'Rev-RR - Receivable Rchg Claim\')';
				if (runType == 'View') {
					// whereClause += ' AND CSX_CMP_Netting_Claim_Ref_Number__c != null  AND status = \'Closed\' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_From__c <=:todayDate AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_To__c >=:todayDate';
					whereClause += ' AND CSX_CMP_Netting_Claim_Ref_Number__c != null  AND status = \'Closed\' AND CSX_CMP_Supplier_Claimant__r.Status__c = \'Active\'';
				} else {
					whereClause += ' AND status = \'Pending Monthly Settlement\'';
				}
			}
			/*
if (runType == 'View') {
//24 April Changes
Date todayDate = date.TODAY();
if (claimCategory == 'Freight') {
whereClause +=
' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c != null AND CSX_CMP_Netting_Claim_Ref_Number__c != null AND RecordType.DeveloperName =\'' +
claimCategory +
'\' AND status = \'Closed\' AND Type IN (\'FC RR Inbound Claim\',\'FC RR Outbound Claim\',\'Recharges Inbound Claim\',\'Recharges Outbound Claim\') AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_From__c <=:todayDate AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_To__c >=:todayDate ';
} else if (claimCategory == 'Revenue_Railroad') {
whereClause +=
' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c !=null AND CSX_CMP_Netting_Claim_Ref_Number__c != null AND RecordType.DeveloperName =\'' +
claimCategory +
'\'  AND status = \'Closed\' AND Type IN (\'Rev-RR - Payable Claim\',\'Rev-RR - Receivable Claim\',\'Rev-RR Payable Rchg Claim\',\'Rev-RR Receivable  Rchg Claim\') AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_From__c <=:todayDate AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_Active_To__c >=:todayDate';
}
} else {
if (claimCategory == 'Freight') {
whereClause +=
' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c != null AND RecordType.DeveloperName =\'' +
claimCategory +
'\' AND status = \'Pending Monthly Settlement\' AND Type IN (\'FC RR Inbound Claim\',\'FC RR Outbound Claim\',\'Recharges Inbound Claim\',\'Recharges Outbound Claim\')';
} else if (claimCategory == 'Revenue_Railroad') {
whereClause +=
' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c !=null AND RecordType.DeveloperName =\'' +
claimCategory +
'\' AND status = \'Pending Monthly Settlement\' AND Type IN (\'Rev-RR - Payable Claim\',\'Rev-RR - Receivable Claim\',\'Rev-RR Payable Rchg Claim\',\'Rev-RR Receivable  Rchg Claim\')';
}
}*/

			claimQuery += whereClause + ' ORDER BY CSX_CMP_Supplier_Claimant__r.Name ASC'; //
			lstClaims = Database.query(claimQuery);
			if (lstClaims != null && lstClaims.size() > 0) {
				if (runType == 'Preview') {
					sendMail(lstClaims, servicePeriod, claimCategory);
				}
			}

			Map<string, List<Case>> suppliertoClaimsActiveMap = new Map<string, List<Case>>();
			Map<string, List<Case>> suppliertoClaimsMap = new Map<string, List<Case>>();
			if (lstClaims != null && lstClaims.size() > 0) {
				for (Case objCase : lstClaims) {
					if (!suppliertoClaimsMap.containsKey(objCase.CSX_CMP_Supplier_Claimant__c)) {
						suppliertoClaimsMap.put(objCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{ objCase });
						//23 April Changes
						if (
							// changes done by Subodh on July 12th as we removed active from and active to fields and this field is a display field not to use in query : CSX_CMP_Account_Site_Status__c
							objCase.CSX_CMP_Supplier_Claimant__r.Status__c == 'Active'
							// objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c != null &&
							// objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c.contains('green')
						) {
							suppliertoClaimsActiveMap.put(objCase.CSX_CMP_Supplier_Claimant__c, new List<Case>{ objCase });
						}
					} else {
						suppliertoClaimsMap.get(objCase.CSX_CMP_Supplier_Claimant__c).add(objCase);
						if (
							objCase.CSX_CMP_Supplier_Claimant__r.Status__c == 'Active'
							// objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c != null &&
							// objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c.contains('green')
						) {
							suppliertoClaimsActiveMap.get(objCase.CSX_CMP_Supplier_Claimant__c).add(objCase);
						}
					}
				}
			}

			Map<String, String> mapStr = new Map<string, string>();

			if (runType == 'Create') {
				//Start Active Suppler claimaint
				Map<String, List<Case>> response = new Map<String, List<Case>>();
				if (!suppliertoClaimsActiveMap.isEmpty()) {
					response = createNewNettingClaims(suppliertoClaimsActiveMap, claimCategory, servicePeriod);
				}
				if (!response.isEmpty()) {
					for (String key : response.keySet()) {
						suppliertoClaimsMap.put(key, response.get(key));
					}
				}

				//End Active Suppler claimaint
				/* suppliertoClaimsMap = createNewNettingClaims(suppliertoClaimsMap,claimCategory,servicePeriod);
for(string supplierId : suppliertoClaimsMap.keyset()){
for(Case objClaim : suppliertoClaimsMap.get(supplierId)){
if(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c != null){
mapStr.put(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c,'');
}
}
}*/
			}
			//24 April | Start
			if (!suppliertoClaimsMap.isEmpty()) {
				for (string supplierId : suppliertoClaimsMap.keyset()) {
					for (Case objClaim : suppliertoClaimsMap.get(supplierId)) {
						if (objClaim.CSX_CMP_Netting_Claim_Ref_Number__c != null) {
							mapStr.put(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c, '');
						}
					}
				}
			}
			if (!mapStr.isEmpty()) {
				List<Case> lstNettingClaim = [
					SELECT Id, CaseNumber
					FROM Case
					WHERE Id IN :mapStr.keyset()
					WITH SECURITY_ENFORCED
				];
				if (!lstNettingClaim.isEmpty()) {
					for (Case objCase : lstNettingClaim) {
						mapStr.put(objCase.Id, objCase.CaseNumber);
					}
				}
			}
			if (!suppliertoClaimsMap.keyset().isEmpty()) {
				//24 April | End
				for (string supplierId : suppliertoClaimsMap.keyset()) {
					//CalculateNettingCalculationWrapper nettingData = new CalculateNettingCalculationWrapper();
					Decimal sumOfAmount = 0;
					Decimal sumOfInboundClaimAmount = 0;
					Decimal sumOfOutboundClaimAmount = 0;
					Integer totalClaims = 0;
					String railRoadName;
					string supplierSiteStatus = 'false';
					String railRdName;
					string railRdNameId;
					string railRodInbId;
					string railRodOutId;
					String railRodInb;
					String railRodOut;
					List<Case> lstInboundClaims = new List<Case>();
					List<Case> lstOutboundClaims = new List<Case>();
					List<Case> lstCase = suppliertoClaimsMap.get(supplierId);
					totalClaims = lstCase.size();
					if (!suppliertoClaimsMap.get(supplierId).isEmpty()) {
						for (Case objClaim : suppliertoClaimsMap.get(supplierId)) {
							railRoadName = objClaim.CSX_CMP_Supplier_Claimant__r.Name;
							//supplierSiteStatus = objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c;
							if (
								objClaim.CSX_CMP_Supplier_Claimant__r.Status__c == 'Active'
								// objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c != null &&
								// objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Account_Site_Status__c.contains('green')
							) {
								supplierSiteStatus = 'true';
							} else {
								supplierSiteStatus = 'false';
							}
							// nettingData.railRoadName = objClaim.CSX_CMP_Supplier_Claimant__r.Name;
							if (
								objClaim.CSX_CMP_Netting_Claim_Ref_Number__c != null &&
								(objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c != 'Gross' &&
								objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c != 'Gross')
							) {
								railRdName = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
								railRdNameId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;
								// nettingData.nettingClaim = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
							} else if (
								objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c != 'Gross' &&
								objClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c != 'Gross'
							) {
								railRdName = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c) != null
									? mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c)
									: ' ';
								if (objClaim.CSX_CMP_Netting_Claim_Ref_Number__c != null) {
									railRdNameId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;
								}
							}

							if (objClaim.RecordType.DeveloperName == 'Freight' && claimCategory == 'Freight') {
								if (objClaim.Type == 'FC RR Inbound Claim' || objClaim.Type == 'Recharges Inbound Claim') {
									railRodInb = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
									railRodInbId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;

									lstInboundClaims.add(objClaim);
									if (objClaim.CSX_CMP_Claim_Amount__c != null) {
										sumOfInboundClaimAmount += objClaim.CSX_CMP_Claim_Amount__c;
									}
								}
								if (objClaim.Type == 'Recharges Outbound Claim' || objClaim.Type == 'FC RR Outbound Claim') {
									railRodOut = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
									railRodOutId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;
									lstOutboundClaims.add(objClaim);
									if (objClaim.CSX_CMP_Claim_Amount__c != null) {
										sumOfOutboundClaimAmount += objClaim.CSX_CMP_Claim_Amount__c;
									}
								}
							} else if (
								objClaim.RecordType.DeveloperName == 'Revenue_Railroad' &&
								claimCategory == 'Revenue_Railroad'
							) {
								if (objClaim.Type == 'Rev-RR - Payable Claim' || objClaim.Type == 'Rev-RR - Payable Rchg Claim') {
									railRodInb = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
									railRodInbId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;
									lstInboundClaims.add(objClaim);
									if (objClaim.CSX_CMP_Claim_Amount__c != null) {
										sumOfInboundClaimAmount += objClaim.CSX_CMP_Claim_Amount__c;
									}
								}
								if (objClaim.Type == 'Rev-RR - Receivable Rchg Claim' || objClaim.Type == 'Rev-RR - Receivable Claim') {
									railRodOut = mapStr.get(objClaim.CSX_CMP_Netting_Claim_Ref_Number__c);
									railRodOutId = objClaim.CSX_CMP_Netting_Claim_Ref_Number__c;
									lstOutboundClaims.add(objClaim);
									if (objClaim.CSX_CMP_Claim_Amount__c != null) {
										sumOfOutboundClaimAmount += objClaim.CSX_CMP_Claim_Amount__c;
									}
								}
							}
							if (objClaim.CSX_CMP_Claim_Amount__c != null) {
								sumOfAmount += objClaim.CSX_CMP_Claim_Amount__c;
							}
						}
					}

					if (lstInboundClaims != null && !lstInboundClaims.isEmpty() && string.isEmpty(railRdName)) {
						CalculateNettingCalculationWrapper nettingData = new CalculateNettingCalculationWrapper();
						nettingData.countOfClaims = lstInboundClaims.size();
						//nettingData.RailroadId = supplierId;
						nettingData.railRoadName = railRoadName;
						nettingData.supplierSiteStatus = supplierSiteStatus;
						nettingData.nettingClaim = railRodInb;
						nettingData.nettingClaimId = railRodInbId;
						nettingData.railRoadUniqueId = supplierId + 'Inbound';
						nettingData.inboundClaimsList = lstInboundClaims;
						nettingData.inboundClaimCount = lstInboundClaims.size();
						nettingData.outboundClaimCount = 0;
						nettingData.inboundClaimSumCount = sumOfInboundClaimAmount;
						nettingData.outboundClaimSumCount = 0;
						nettingData.sumOfAmount = sumOfInboundClaimAmount;

						if (sumOfInboundClaimAmount > 0) {
							nettingData.isColor = false;
						} else {
							nettingData.isColor = true;
						}
						nettingResults.add(nettingData);
					}

					if (lstOutboundClaims != null && !lstOutboundClaims.isEmpty() && string.isEmpty(railRdName)) {
						CalculateNettingCalculationWrapper nettingData = new CalculateNettingCalculationWrapper();
						nettingData.countOfClaims = lstOutboundClaims.size();
						//nettingData.RailroadId= supplierId;
						nettingData.railRoadName = railRoadName;
						nettingData.supplierSiteStatus = supplierSiteStatus;
						nettingData.nettingClaim = railRodOut;
						nettingData.nettingClaimId = railRodOutId;
						nettingData.railRoadUniqueId = supplierId + 'Outbound';
						nettingData.outboundClaimsList = lstOutboundClaims;
						nettingData.inboundClaimCount = 0;
						nettingData.outboundClaimCount = lstOutboundClaims.size();
						nettingData.inboundClaimSumCount = 0;
						nettingData.outboundClaimSumCount = sumOfOutboundClaimAmount;
						nettingData.sumOfAmount = sumOfOutboundClaimAmount;

						if (sumOfOutboundClaimAmount < 0) {
							nettingData.isColor = true;
						} else {
							nettingData.isColor = false;
						}
						nettingResults.add(nettingData);
					}
					if (string.isNotEmpty(railRdName)) {
						CalculateNettingCalculationWrapper nettingData = new CalculateNettingCalculationWrapper();
						nettingData.countOfClaims = totalClaims;
						nettingData.railRoadName = railRoadName;
						nettingData.supplierSiteStatus = supplierSiteStatus;
						nettingData.nettingClaim = railRdName;
						nettingData.nettingClaimId = railRdNameId;
						nettingData.railRoadUniqueId = supplierId;
						nettingData.inboundClaimsList = lstInboundClaims;
						nettingData.outboundClaimsList = lstOutboundClaims;
						nettingData.inboundClaimCount = lstInboundClaims.size();
						nettingData.outboundClaimCount = lstOutboundClaims.size();
						nettingData.inboundClaimSumCount = sumOfInboundClaimAmount;
						nettingData.outboundClaimSumCount = sumOfOutboundClaimAmount;
						nettingData.sumOfAmount = sumOfAmount;
						if (sumOfAmount < 0) {
							nettingData.isColor = true;
						} else {
							nettingData.isColor = false;
						}
						nettingResults.add(nettingData);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_HandleNettingCalculation', 'calculateNettingClaim', 'caseRec', ex);
		}
		if (nettingResults != null) {
			return nettingResults;
		} else {
			return null;
		}
	}

	public static Map<String, List<Case>> createNewNettingClaims(
		Map<string, List<Case>> inputClaimsMap,
		String categoryType,
		String serPeriod
	) {
		Map<String, List<Case>> supIdtoNewNetClaimsMap = new Map<String, List<Case>>();
		try {
			List<Case> newNettingClaimList = new List<Case>();
			Set<Id> inputClaimIds = new Set<Id>();

			for (string supplierId : inputClaimsMap.keyset()) {
				Decimal totalInbound = 0;
				Decimal totaloutbound = 0;
				Decimal totalAmount = 0;
				string customerId;
				for (Case inpClaim : inputClaimsMap.get(supplierId)) {
					inputClaimIds.add(inpClaim.Id);
					String nettingType = '';
					if (string.isNotBlank(inpClaim.CSX_CMP_Customer__c)) {
						customerId = inpClaim.CSX_CMP_Customer__c;
					}
					if (categoryType == 'Freight') {
						nettingType = inpClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c;
					} else {
						nettingType = inpClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c;
					}

					if (nettingType == 'Gross') {
						if (categoryType == 'Freight') {
							if (inpClaim.Type == 'FC RR Inbound Claim' || inpClaim.Type == 'Recharges Inbound Claim') {
								totalInbound += inpClaim.CSX_CMP_Claim_Amount__c;
							} else if (inpClaim.Type == 'Recharges Outbound Claim' || inpClaim.Type == 'FC RR Outbound Claim') {
								totaloutbound += inpClaim.CSX_CMP_Claim_Amount__c;
							}
						} else {
							if (inpClaim.Type == 'Rev-RR - Payable Rchg Claim' || inpClaim.Type == 'Rev-RR - Payable Claim') {
								totalInbound += inpClaim.CSX_CMP_Claim_Amount__c;
							} else if (
								inpClaim.Type == 'Rev-RR - Receivable Rchg Claim' ||
								inpClaim.Type == 'Rev-RR - Receivable Claim'
							) {
								totaloutbound += inpClaim.CSX_CMP_Claim_Amount__c;
							}
						}
					} else {
						if (categoryType == 'Freight') {
							totalAmount += inpClaim.CSX_CMP_Claim_Amount__c;
						} else {
							totalAmount += inpClaim.CSX_CMP_Claim_Amount__c;
						}
					}
				}

				if (totalInbound != 0) {
					Case newNetClaim = initializeNettingClaimObject(categoryType, serPeriod, supplierId);
					newNetClaim.CSX_CMP_Claim_Amount__c = totalInbound;
					if (string.isNotBlank(customerId)) {
						newNetClaim.CSX_CMP_Customer__c = customerId;
					}
					newNettingClaimList.add(newNetClaim);
				}
				if (totaloutbound != 0) {
					Case newNetClaim = initializeNettingClaimObject(categoryType, serPeriod, supplierId);
					newNetClaim.CSX_CMP_Claim_Amount__c = totaloutbound;
					if (string.isNotBlank(customerId)) {
						newNetClaim.CSX_CMP_Customer__c = customerId;
					}
					newNettingClaimList.add(newNetClaim);
				}
				if (totalAmount != 0) {
					Case newNetClaim = initializeNettingClaimObject(categoryType, serPeriod, supplierId);
					newNetClaim.CSX_CMP_Claim_Amount__c = totalAmount;
					if (string.isNotBlank(customerId)) {
						newNetClaim.CSX_CMP_Customer__c = customerId;
					}
					newNettingClaimList.add(newNetClaim);
				}
			}
			Database.SaveResult[] insertNettingResultList = Database.insert(newNettingClaimList, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_HandleNettingCalculation',
				'createNewNettingClaims',
				insertNettingResultList,
				'Case'
			);

			//Map<String,List<Case>> supIdtoNewNetClaimsMap = new Map<String,List<Case>>();
			for (Case objClm : newNettingClaimList) {
				if (!supIdtoNewNetClaimsMap.containsKey(objClm.CSX_CMP_Supplier_Claimant__c)) {
					supIdtoNewNetClaimsMap.put(objClm.CSX_CMP_Supplier_Claimant__c, new List<Case>{ objClm });
				} else {
					supIdtoNewNetClaimsMap.get(objClm.CSX_CMP_Supplier_Claimant__c).add(objClm);
				}
			}

			//logic to update status and new Netting Claim # on existing claims
			List<Case> existingClaimsforUpd = new List<Case>();
			Map<string, object> mapOfInputClaim = new Map<string, object>();
			for (Case inputClaim : [
				SELECT
					Id,
					CaseNumber,
					Type,
					Status,
					RecordType.DeveloperName,
					CSX_CMP_Customer_Site__c,
					CSX_CMP_Supplier_Claimant__c,
					CSX_CMP_Claimant_Ref_Num__c,
					CSX_CMP_Supplier_Claimant__r.Name,
					CSX_CMP_Supplier_Claimant_Site__c,
					CSX_CMP_Supplier_Claimant__r.Status__c,
					CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c,
					CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c,
					CSX_CMP_Netting_Claim_Ref_Number__c,
					CSX_CMP_Netting_Claim_Ref_Number__r.CaseNumber,
					CSX_CMP_Customer__r.Name,
					CSX_CMP_Customer__c,
					CSX_CMP_Service_Period__c,
					CSX_CMP_System_Action_Toggle__c,
					CSX_CMP_Claim_Amount__c,
					CreatedDate,
					CSX_CMP_Claim_Date__c
				FROM Case
				WHERE CSX_CMP_Supplier_Claimant__c IN :supIdtoNewNetClaimsMap.keySet() AND Id IN :inputClaimIds
				WITH SECURITY_ENFORCED
			]) {
				List<Case> newNetClaims = supIdtoNewNetClaimsMap.get(inputClaim.CSX_CMP_Supplier_Claimant__c);
				for (Case netClaim : newNetClaims) {
					String nettingType = '';
					if (categoryType == 'Freight') {
						nettingType = inputClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Gross_Net_Customer__c;
					} else {
						nettingType = inputClaim.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Gross_Net_Customer__c;
					}

					if (nettingType == 'Gross') {
						//logic to tag input claim to respective inbound or outbound netting claim
						if (
							(inputClaim.CSX_CMP_Claim_Amount__c > 0 && netClaim.CSX_CMP_Claim_Amount__c > 0) ||
							(inputClaim.CSX_CMP_Claim_Amount__c < 0 &&
							netClaim.CSX_CMP_Claim_Amount__c < 0)
						) {
							inputClaim.CSX_CMP_Netting_Claim_Ref_Number__c = netClaim.Id;
							inputClaim.CSX_CMP_System_Action_Toggle__c = !inputClaim.CSX_CMP_System_Action_Toggle__c;
						}
					} else {
						inputClaim.CSX_CMP_System_Action_Toggle__c = !inputClaim.CSX_CMP_System_Action_Toggle__c;
						inputClaim.CSX_CMP_Netting_Claim_Ref_Number__c = netClaim.Id;
					}
					inputClaim.Status = 'Closed';

					if (!mapOfInputClaim.containsKey(inputClaim.Id)) {
						mapOfInputClaim.put(inputClaim.Id, inputClaim);
						existingClaimsforUpd.add(inputClaim);
					}
					// existingClaimsforUpd.add(inputClaim);
				}
			}

			Database.SaveResult[] updateResults = Database.Update(existingClaimsforUpd, false);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_HandleNettingCalculation',
				'createNewNettingClaims',
				updateResults,
				'Case'
			);

			Map<Id, List<String>> netClaimtoInitialClaimsMap = new Map<Id, List<String>>();
			supIdtoNewNetClaimsMap.clear();
			for (Case initialClaim : existingClaimsforUpd) {
				//prepare map of supplier id to corresponding initial claims which will now have Netting Claim # reference as well
				if (!supIdtoNewNetClaimsMap.containsKey(initialClaim.CSX_CMP_Supplier_Claimant__c)) {
					supIdtoNewNetClaimsMap.put(initialClaim.CSX_CMP_Supplier_Claimant__c, new List<Case>{ initialClaim });
				} else {
					supIdtoNewNetClaimsMap.get(initialClaim.CSX_CMP_Supplier_Claimant__c).add(initialClaim);
				}

				//prepare netting claims to corresponding initial claims for creating Related Claim records
				if (initialClaim.CSX_CMP_Netting_Claim_Ref_Number__c != null) {
					if (!netClaimtoInitialClaimsMap.containsKey(initialClaim.CSX_CMP_Netting_Claim_Ref_Number__c)) {
						netClaimtoInitialClaimsMap.put(
							initialClaim.CSX_CMP_Netting_Claim_Ref_Number__c,
							new List<String>{ initialClaim.Id }
						);
					} else {
						netClaimtoInitialClaimsMap.get(initialClaim.CSX_CMP_Netting_Claim_Ref_Number__c).add(initialClaim.Id);
					}
				}
			}

			//create Related Claims
			CSX_CMP_Utility.createRelatedClaim(netClaimtoInitialClaimsMap);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_HandleNettingCalculation',
				'createNewNettingClaims',
				'supIdtoNewNetClaimsMap',
				ex
			);
		}
		return supIdtoNewNetClaimsMap;
	}

	private static Case initializeNettingClaimObject(String catType, String servicePeriod, string claimaintId) {
		Case objNewNettingCase = new Case();
		try {
			objNewNettingCase.Status = 'Pending Close';
			objNewNettingCase.Origin = 'Netting';
			objNewNettingCase.CSX_CMP_Service_Period__c = servicePeriod;
			objNewNettingCase.CSX_CMP_Supplier_Claimant__c = claimaintId;
			//objNewNettingCase.CSX_CMP_Customer__c = customerId;
			Id caseRecordTypeId;
			if (catType == 'Freight') {
				caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Freight').getRecordTypeId();
				objNewNettingCase.Type = 'Railroad Netting FC Claim';
			} else if (catType == 'Revenue_Railroad') {
				caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
					.get('Revenue_Railroad')
					.getRecordTypeId();
				objNewNettingCase.Type = 'Railroad Netting REV Claim';
			}
			objNewNettingCase.RecordTypeId = caseRecordTypeId;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_HandleNettingCalculation',
				'initializeNettingClaimObject',
				'objNewNettingCase',
				ex
			);
		}
		return objNewNettingCase;
	}

	public static void sendMail(List<Case> lstCse, string servPeriod, String claimCat) {
		try {
			String userEmail = UserInfo.getUserEmail();
			Blob xslBlobFile = createExcel(lstCse, claimCat);
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			string fileName = 'Eligible Netting Claims.csv';
			csvAttc.setFileName(fileName);
			csvAttc.setBody(xslBlobFile);

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			String[] toAddresses = new List<string>{ userEmail };
			email.setToAddresses(toAddresses);

			OrgWideEmailAddress[] owea = [
				SELECT Id
				FROM OrgWideEmailAddress
				WHERE DisplayName = :System.Label.CSX_CMP_CSX_Support
				//WITH SECURITY_ENFORCED
			];

			if (owea != null) {
				email.setOrgWideEmailAddressId(owea.get(0).Id);
			}

			EmailTemplate objTmp = [
				SELECT Id, Name, Subject, DeveloperName, HtmlValue, Body, IsActive
				FROM EmailTemplate
				WHERE DeveloperName = 'CSX_CMP_Netting_Eligible_Claims_Report'
				WITH SECURITY_ENFORCED
			];
			if (objTmp != null) {
				email.setTemplateId(objTmp.Id);
				if (servPeriod != null) {
					objTmp.subject = objTmp.subject.replace('{!Case.CSX_CMP_Service_Period__c}', servPeriod);
					objTmp.body = objTmp.body.replace('{!Case.CSX_CMP_Service_Period__c}', servPeriod);
					objTmp.HtmlValue = objTmp.HtmlValue.replace('{!Case.CSX_CMP_Service_Period__c}', servPeriod);
				}
				email.setSubject(objTmp.Subject);
				objTmp.body = objTmp.body.replace('{User.FirstName}', UserInfo.getFirstName());
				// objTmp.body = objTmp.body.replace('{CSX_CMP_Netting_URL}', system.label.CSX_CMP_Netting_URL);
				// objTmp.HtmlValue = objTmp.HtmlValue.replace('{CSX_CMP_Netting_URL}', system.label.CSX_CMP_Netting_URL);
				objTmp.body = objTmp.body.replace('{CSX_CMP_Netting_URL}', URL.getOrgDomainURL().toExternalForm()+'/lightning/n/CSX_CMP_Netting_Submission');
				objTmp.HtmlValue = objTmp.HtmlValue.replace('{CSX_CMP_Netting_URL}', URL.getOrgDomainURL().toExternalForm()+'/lightning/n/CSX_CMP_Netting_Submission');
				objTmp.HtmlValue = objTmp.HtmlValue.replace('{User.FirstName}', UserInfo.getFirstName());

				email.saveAsActivity = false;
				email.setHtmlBody(objTmp.HtmlValue);
			}
			email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
			Messaging.SendEmailResult[] r = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_HandleNettingCalculation', 'sendMail', r);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_HandleNettingCalculation', 'sendMail', 'r', ex);
		}
	}

	public static blob createExcel(List<Case> lstClims, String claimCatgory) {
		blob csvBlob;
		try {
			string header = 'Supplier/Claimant Name ,Supplier/Claimant Site Code, Customer Name,Claim Number,Creation Date,Claim Type,Claim Date,Claim Amount,Claim Status,Claimant Ref #,Service Period,Parent Claim number \n';
			string finalstr = header;
			if (claimCatgory == 'Freight') {
				set<Id> inputClaimidSet = new Set<Id>();
				set<Id> inputIdSet = new Set<Id>();

				for (Case objCase : lstClims) {
					if (objCase.Type != 'Recharges Outbound Claim') {
						//FC RR inbound/Recharges Inbound Claim
						inputClaimidSet.add(objCase.Id);
					} else {
						inputIdSet.add(objCase.Id);
					}
				}
				List<CSX_CMP_Distribution__c> distributionClaimsList = new List<CSX_CMP_Distribution__c>();
				List<CSX_CMP_Related_Claim__c> relatedClaimList = new List<CSX_CMP_Related_Claim__c>();
				if (inputClaimidSet.size() > 0) {
					distributionClaimsList = [
						SELECT
							Id,
							Name,
							CSX_CMP_Equipment__c,
							CSX_CMP_Equipment__r.CSX_CMP_Claim__c,
							CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CaseNumber,
							CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Supplier_Claimant__r.Name,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Supplier_Claimant_Site__c,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Customer__r.Name,
							CSX_CMP_Distribution_Claim__r.CaseNumber,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Case_Number_Formula__c,
							CSX_CMP_Distribution_Claim__r.CreatedDate,
							CSX_CMP_Distribution_Claim__r.Type,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Claim_Date__c,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Claim_Amount__c,
							CSX_CMP_Distribution_Claim__r.Status,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Claimant_Ref_Num__c,
							CSX_CMP_Distribution_Claim__r.CSX_CMP_Service_Period__c,
							CSX_CMP_Distribution_Claim__c
						FROM CSX_CMP_Distribution__c
						WHERE
							CSX_CMP_Distribution_Claim__c IN :inputClaimidSet
							AND CSX_CMP_Distribution_Claim__r.Type != 'Recharges Outbound Claim'
						WITH SECURITY_ENFORCED
						ORDER BY CSX_CMP_Distribution_Claim__r.CSX_CMP_Supplier_Claimant__r.Name ASC
					];
				}
				if (inputIdSet.size() > 0) {
					relatedClaimList = [
						SELECT
							Id,
							Name,
							CSX_CMP_Related_Claim__c,
							CSX_CMP_Related_Claim__r.Type,
							CSX_CMP_Related_Claim__r.CaseNumber,
							CSX_CMP_Related_Claim__r.CSX_CMP_Case_Number_Formula__c,
							CSX_CMP_Claim__c,
							CSX_CMP_Claim_Type__c,
							CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant__r.Name,
							CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant_Site__c,
							CSX_CMP_Claim__r.CSX_CMP_Customer__r.Name,
							CSX_CMP_Claim__r.CaseNumber,
							CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c,
							CSX_CMP_Claim__r.CreatedDate,
							CSX_CMP_Claim__r.Type,
							CSX_CMP_Claim__r.CSX_CMP_Claim_Date__c,
							CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c,
							CSX_CMP_Claim__r.Status,
							CSX_CMP_Claim__r.CSX_CMP_Claimant_Ref_Num__c,
							CSX_CMP_Claim__r.CSX_CMP_Service_Period__c
						FROM CSX_CMP_Related_Claim__c
						WHERE
							CSX_CMP_Claim__c IN :inputIdSet
							AND (CSX_CMP_Related_Claim__r.Type = 'Recharges Inbound Claim'
							OR CSX_CMP_Related_Claim__r.Type = 'FC RR Inbound Claim')
						WITH SECURITY_ENFORCED
						ORDER BY CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant__r.Name ASC
					];
				}

				if (distributionClaimsList.size() > 0 && !distributionClaimsList.isEmpty()) {
					for (CSX_CMP_Distribution__c objCase : distributionClaimsList) {
						string recordString =
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Supplier_Claimant__r.Name +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Supplier_Claimant_Site__c +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Customer__r.Name +
							',' +
							//objCase.CSX_CMP_Distribution_Claim__r.CaseNumber +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Case_Number_Formula__c +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CreatedDate +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.Type +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Claim_Date__c +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Claim_Amount__c +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.Status +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Claimant_Ref_Num__c +
							',' +
							objCase.CSX_CMP_Distribution_Claim__r.CSX_CMP_Service_Period__c +
							',' +
							//objcase.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CaseNumber +
							objcase.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c +
							'\n';
						finalstr = finalstr + recordString;
						finalstr = finalstr.replace('null', '');
					}
				}

				if (relatedClaimList.size() > 0 && !relatedClaimList.isEmpty()) {
					for (CSX_CMP_Related_Claim__c relatedClaim : relatedClaimList) {
						string recordString =
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant__r.Name +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Supplier_Claimant_Site__c +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Customer__r.Name +
							',' +
							//relatedClaim.CSX_CMP_Claim__r.CaseNumber +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CreatedDate +
							',' +
							relatedClaim.CSX_CMP_Claim__r.Type +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Claim_Date__c +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Claim_Amount__c +
							',' +
							relatedClaim.CSX_CMP_Claim__r.Status +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Claimant_Ref_Num__c +
							',' +
							relatedClaim.CSX_CMP_Claim__r.CSX_CMP_Service_Period__c +
							',' +
							//relatedClaim.CSX_CMP_Related_Claim__r.CaseNumber +
							relatedClaim.CSX_CMP_Related_Claim__r.CSX_CMP_Case_Number_Formula__c +
							'\n';
						finalstr = finalstr + recordString;
						finalstr = finalstr.replace('null', '');
					}
				}
			} else {
				for (Case objCase : lstClims) {
					string recordString =
						objCase.CSX_CMP_Supplier_Claimant__r.Name +
						',' +
						objCase.CSX_CMP_Supplier_Claimant_Site__c +
						',' +
						objCase.CSX_CMP_Customer__r.Name +
						',' +
						//objCase.CaseNumber +
						objCase.CSX_CMP_Case_Number_Formula__c +
						',' +
						objCase.CreatedDate +
						',' +
						objCase.Type +
						',' +
						objCase.CSX_CMP_Claim_Date__c +
						',' +
						objCase.CSX_CMP_Claim_Amount__c +
						',' +
						objCase.Status +
						',' +
						objCase.CSX_CMP_Claimant_Ref_Num__c +
						',' +
						objCase.CSX_CMP_Service_Period__c +
						'\n';
					finalstr = finalstr + recordString;
					finalstr = finalstr.replace('null', '');
				}
			}

			csvBlob = Blob.valueOf(finalstr);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_HandleNettingCalculation', 'CreateExcel', 'csvBlob', ex);
		}
		return csvBlob;
	}

	public class CalculateNettingCalculationWrapper {
		// @AuraEnabled
		// public String RailroadId{get;set;}
		@AuraEnabled
		public String railRoadName { get; set; }
		@AuraEnabled
		public string supplierSiteStatus { get; set; }
		@AuraEnabled
		public Decimal sumOfAmount { get; set; }
		@AuraEnabled
		public Integer countOfClaims { get; set; }
		@AuraEnabled
		public String nettingClaim { get; set; }
		@AuraEnabled
		public String nettingClaimId { get; set; }
		@AuraEnabled
		public List<Case> inboundClaimsList { get; set; }
		@AuraEnabled
		public List<Case> outboundClaimsList { get; set; }
		@AuraEnabled
		public Integer inboundClaimCount { get; set; }
		@AuraEnabled
		public Integer outboundClaimCount { get; set; }
		@AuraEnabled
		public Decimal inboundClaimSumCount { get; set; }
		@AuraEnabled
		public Decimal outboundClaimSumCount { get; set; }
		@AuraEnabled
		public Boolean isColor { get; set; }
		@AuraEnabled
		public String railRoadUniqueId { get; set; }
	}
}