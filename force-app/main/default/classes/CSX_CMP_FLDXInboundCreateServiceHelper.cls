/**************************************************************************************
Apex Class Name     : CSX_CMP_FLDXInboundCreateServiceHelper
Function            : webservice class to prepare data for FLDX Inbound file to be consumed by sterling to create final FLDX file.
RICEFW #            : CMP-I-0415
Modification Log    :
* Developer         : Date :06/19/2024       Description 
* ----------------------------------------------------------------------------                  
* @author         : Infosys                  First version of this class.
*************************************************************************************/

public with sharing class CSX_CMP_FLDXInboundCreateServiceHelper {
	public static Map<String, Object> prepareClaimWrapper(List<Object> data) {
		Map<String, Object> responseMap = new Map<String, Object>();
		Map<String, CSX_CMP_NewClaimWrapper> wrapperMap = new Map<String, CSX_CMP_NewClaimWrapper>();
		try {
			Map<String, Integer> identifierToDistributionCount = new Map<String, Integer>();
			identifierToDistributionCount.put('3', 3);
			identifierToDistributionCount.put('4', 6);
			identifierToDistributionCount.put('5', 9);
			identifierToDistributionCount.put('6', 12);

			Map<String, Decimal> railroadCodetoTotalClaimAmountMap = new Map<String, Decimal>();
			Map<String, Integer> railroadCodetoRowCountMap = new Map<String, Integer>();
			Map<string, set<string>> uniqueClaimantMap = new Map<string, set<string>>();

			//variable to store Railraod summary from Railinc/Payload
			Map<String, Decimal> sourceRailroadCodetoTotalClaimAmountMap = new Map<String, Decimal>();
			Map<String, Integer> sourceRailroadCodetoClaimCountMap = new Map<String, Integer>();
			Map<String, Integer> sourceRailroadCodetoRowCountMap = new Map<String, Integer>();

			//variables to store grand summary from Railinc/Payload
			Decimal sourceGrandClaimTotalAmount = 0;
			Integer sourceGrandClaimCount = 0;
			Integer sourceGrandClaimRowCount = 0;

			//Custom Setting
			Map<String, String> railroadCodeMap = new Map<String, String>();
			List<CSX_CMP_RailroadCodeMapping__c> railroadList = CSX_CMP_RailroadCodeMapping__c.getAll().values();
			for (CSX_CMP_RailroadCodeMapping__c railroad : railroadList) {
				//String key = mapping.CSX_CMP_SupplierSCAC__c + '_' + mapping.CurrencyCode__c;
				railroadCodeMap.put(railroad.CSX_CMP_Canadian_Railroad_Code__c, railroad.CSX_CMP_SupplierSCAC__c);
			}

			// Create an empty map to store supplier IDs
			Map<String, string> supplierIdMap = new Map<String, string>();
			for (Account account : [
				SELECT Id, CSX_CMP_FC_Railroad_Road_Code__c
				FROM Account
				WHERE Type = 'Supplier' AND CSX_CMP_FC_Railroad_Road_Code__c != NULL AND RecordType.DeveloperName = 'Location' AND Location_Type__c = 'Billing Address'
				WITH SECURITY_ENFORCED
			]) {
				if (account.CSX_CMP_FC_Railroad_Road_Code__c != null) {
					supplierIdMap.put(account.CSX_CMP_FC_Railroad_Road_Code__c, account.Id);
				}
			}

			for (Object row : data) {
				Map<String, Object> fldxRowMap = (Map<String, Object>) row;
				CSX_CMP_NewClaimWrapper newClaimWrap = new CSX_CMP_NewClaimWrapper();
				CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipLine = new CSX_CMP_NewClaimWrapper.EquipmentORClaimLine();
				if (String.isBlank(String.valueOf(fldxRowMap.get('claimantReferenceNumber')))) {
					if (string.valueOf(fldxRowMap.get('recordIdentifier')) == '7') {
						sourceRailroadCodetoTotalClaimAmountMap.put(
							string.valueOf(fldxRowMap.get('senderSCAC')),
							(Decimal) fldxRowMap.get('summaryClaimAmount')
						);
						sourceRailroadCodetoClaimCountMap.put(
							string.valueOf(fldxRowMap.get('senderSCAC')),
							Integer.valueOf(fldxRowMap.get('summaryClaimCount'))
						);
						sourceRailroadCodetoRowCountMap.put(
							string.valueOf(fldxRowMap.get('senderSCAC')),
							Integer.valueOf(fldxRowMap.get('summaryRecordCount'))
						);
					}

					if (string.valueOf(fldxRowMap.get('recordIdentifier')) == '9') {
						//sourceGrandClaimTotalAmount = (Decimal) fldxRowMap.get('summaryClaimAmount');
						sourceGrandClaimTotalAmount = (Decimal) fldxRowMap.get('totalClaimAmount');
						sourceGrandClaimCount = Integer.valueOf(fldxRowMap.get('summaryClaimCount'));
						sourceGrandClaimRowCount = Integer.valueOf(fldxRowMap.get('summaryRecordCount'));
					}
				} else if (
					String.isNotBlank(String.valueOf(fldxRowMap.get('claimantReferenceNumber'))) &&
					String.valueOf(fldxRowMap.get('recordIdentifier')) != '7' &&
					String.valueOf(fldxRowMap.get('recordIdentifier')) != '9'
				) {
					if (wrapperMap.containsKey(String.valueOf(fldxRowMap.get('claimantReferenceNumber')))) {
						newClaimWrap = wrapperMap.get(String.valueOf(fldxRowMap.get('claimantReferenceNumber')));

						if (!newClaimWrap.equipment.isEmpty()) {
							equipLine = newClaimWrap.equipment[0];
						} else {
							equipLine.products = new List<CSX_CMP_NewClaimWrapper.Product>();
							equipLine.distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
						}
					} else {
						// newClaimWrap = new CSX_CMP_NewClaimWrapper();
						newClaimWrap.equipment = new List<CSX_CMP_NewClaimWrapper.EquipmentORClaimLine>();
						equipLine.products = new List<CSX_CMP_NewClaimWrapper.Product>();
						equipLine.distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
					}

					newClaimWrap.source = 'FLDX';
					newClaimWrap.claimRecordType = 'Freight';
					//newClaimWrap.fldxFileReceivedDate = system.Today();
					if (
						string.isNotBlank(string.valueOf(fldxRowMap.get('fldxFileReceivedDate'))) &&
						newClaimWrap.fldxFileReceivedDate == null
					) {
						newClaimWrap.fldxFileReceivedDate = Date.valueOf(string.valueOf(fldxRowMap.get('fldxFileReceivedDate')));
					}

					if (String.isNotBlank(string.valueOf(fldxRowMap.get('claimantReferenceNumber')))) {
						newClaimWrap.claimantReferenceNumber = string.valueOf(fldxRowMap.get('claimantReferenceNumber'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('causeCode'))) && String.isBlank(newClaimWrap.causeCode)
					) {
						if (string.valueOf(fldxRowMap.get('causeCode')).length() == 1) {
							newClaimWrap.causeCode = '0' + string.valueOf(fldxRowMap.get('causeCode'));
						} else {
							newClaimWrap.causeCode = string.valueOf(fldxRowMap.get('causeCode'));
						}
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('claimantCode'))) &&
						String.isBlank(newClaimWrap.claimantCode)
					) {
						newClaimWrap.claimantCode = string.valueOf(fldxRowMap.get('claimantCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('localInterlineTraffic'))) &&
						String.isBlank(newClaimWrap.localInterlineTraffic)
					) {
						newClaimWrap.localInterlineTraffic = string.valueOf(fldxRowMap.get('localInterlineTraffic'));
					}

					// if (String.isNotBlank(String.valueOf(fldxRowMap.get('amount'))) && newClaimWrap.claimAmount == null) {
					// 	newClaimWrap.claimAmount = Decimal.valueOf(string.valueOf(fldxRowMap.get('amount')));
					// }

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('claimType'))) &&
						String.isBlank(newClaimWrap.transactionType)
					) {
						newClaimWrap.transactionType = string.valueOf(fldxRowMap.get('claimType'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('claimType'))) && String.isBlank(newClaimWrap.claimType)
					) {
						if (string.valueOf(fldxRowMap.get('claimType')) == '0') {
							newClaimWrap.claimType = 'FC RR Inbound Claim';
						} else if (string.valueOf(fldxRowMap.get('claimType')) == '8') {
							newClaimWrap.claimType = 'Recharges Inbound Claim';
						} else if (
							string.valueOf(fldxRowMap.get('claimType')) == '2' &&
							(string.valueOf(fldxRowMap.get('senderSCAC')) == '777' ||
							string.valueOf(fldxRowMap.get('senderSCAC')) == '0777')
						) {
							newClaimWrap.claimType = 'Recharges Inbound Claim';
						} else {
							newClaimWrap.claimType = string.valueOf(fldxRowMap.get('claimType')); // 12 july changes
						}
					} else if (String.isBlank(newClaimWrap.claimType) && String.valueOf(fldxRowMap.get('claimType')) == null) {
						newClaimWrap.claimType = 'FC RR Inbound Claim';
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('senderSCAC'))) && String.isBlank(newClaimWrap.senderSCAC)
					) {
						newClaimWrap.senderSCAC = string.valueOf(fldxRowMap.get('senderSCAC'));
						newClaimWrap.supplierId = supplierIdMap.get(string.valueOf(fldxRowMap.get('senderSCAC')));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('salvageCarrierCode'))) && String.isBlank(newClaimWrap.scac)
					) {
						newClaimWrap.scac = string.valueOf(fldxRowMap.get('salvageCarrierCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('salvageFileNumber'))) &&
						newClaimWrap.salvageFileNumber == null
					) {
						newClaimWrap.salvageFileNumber = Integer.valueOf(string.valueOf(fldxRowMap.get('salvageFileNumber')));
					}
					if (fldxRowMap.get('packageLostFlag') != null && newClaimWrap.packageLostFlag == null) {
						newClaimWrap.packageLostFlag = Boolean.valueOf(string.valueOf(fldxRowMap.get('packageLostFlag')));
					}
					if (String.isNotBlank(String.valueOf(fldxRowMap.get('salvageProceeds'))) && newClaimWrap.amount == null) {
						newClaimWrap.amount = Decimal.valueOf(string.valueOf(fldxRowMap.get('salvageProceeds')));
					}
					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('proceedsCode'))) &&
						String.isBlank(newClaimWrap.proceedsCode)
					) {
						// if (string.valueOf(fldxRowMap.get('proceedsCode')).length() == 1) {
						// 	newClaimWrap.proceedsCode = '0' +string.valueOf(fldxRowMap.get('proceedsCode'));
						// }else{
						newClaimWrap.proceedsCode = string.valueOf(fldxRowMap.get('proceedsCode'));
						//}
					} // not mapped

					List<String> remarksList = new List<String>();
					if (String.isNotBlank(string.valueOf(fldxRowMap.get('primaryRemarks')))) {
						remarksList.add(string.valueOf(fldxRowMap.get('primaryRemarks')));
					}
					if (String.isNotBlank(string.valueOf(fldxRowMap.get('secondaryRemarks')))) {
						remarksList.add(string.valueOf(fldxRowMap.get('secondaryRemarks')));
					}
					if (remarksList.size() > 0 && String.isBlank(newClaimWrap.remarks)) {
						newClaimWrap.remarks = String.join(remarksList, ';');
					}

					// Identifier Two fields

					if (String.isNotBlank(string.valueOf(fldxRowMap.get('ruleCode'))) && String.isBlank(newClaimWrap.ruleCode)) {
						newClaimWrap.ruleCode = string.valueOf(fldxRowMap.get('ruleCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('ruleSecondary'))) &&
						String.isBlank(newClaimWrap.ruleSecondary)
					) {
						newClaimWrap.ruleSecondary = string.valueOf(fldxRowMap.get('ruleSecondary'));
					}

					if (
						string.isNotBlank(string.valueOf(fldxRowMap.get('claimReceivedDate'))) &&
						newClaimWrap.customerClaimDate == null
					) {
						newClaimWrap.customerClaimDate = Date.valueOf(string.valueOf(fldxRowMap.get('claimReceivedDate')));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('foreignCustomerClaimNumber'))) &&
						String.isBlank(newClaimWrap.foreignCustomerClaimNumber)
					) {
						newClaimWrap.foreignCustomerClaimNumber = string.valueOf(fldxRowMap.get('foreignCustomerClaimNumber'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('foreignCustomerClaimAmount'))) &&
						newClaimWrap.foreignCustomerClaimAmount == null
					) {
						newClaimWrap.foreignCustomerClaimAmount = Decimal.valueOf(
							string.valueOf(fldxRowMap.get('foreignCustomerClaimAmount'))
						);
					}
					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('currencyCode'))) &&
						(string.isBlank(newClaimWrap.currencyCode) ||
						newClaimWrap.currencyCode == 'USD' ||
						newClaimWrap.currencyCode == 'CAD')
					) {
						if (string.valueOf(fldxRowMap.get('currencyCode')) == 'U') {
							newClaimWrap.currencyCode = 'USD';
						} else if (string.valueOf(fldxRowMap.get('currencyCode')) == 'C') {
							newClaimWrap.currencyCode = 'CAD';
						} else {
							newClaimWrap.currencyCode = string.valueOf(fldxRowMap.get('currencyCode'));
						}
					}

					// 19 July Changes sent by Sarath regarding supplierId and currencyCode for Canadian Railroad code
					/*string key = '';
					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('senderSCAC'))) &&
						String.isNotBlank(string.valueOf(fldxRowMap.get('currencyCode')))
					) {
						key = string.valueOf(fldxRowMap.get('senderSCAC')) + '_' + string.valueOf(fldxRowMap.get('currencyCode'));
					}

					if (String.isNotBlank(key) && railroadCodeMap.containsKey(key)) {
						newClaimWrap.supplierId = supplierIdMap.get(railroadCodeMap.get(key));
						newClaimWrap.currencyCode = string.valueOf(fldxRowMap.get('currencyCode'));
					}*/

					if (
						string.isNotBlank(string.valueOf(fldxRowMap.get('freightBillDate'))) && equipLine.freightBillDate == null
					) {
						equipLine.freightBillDate = Date.valueOf(string.valueOf(fldxRowMap.get('freightBillDate')));
					}

					//Identifier 2 fields

					if (String.isNotBlank(string.valueOf(fldxRowMap.get('stcc'))) && String.isBlank(equipLine.stcc)) {
						equipLine.stcc = string.valueOf(fldxRowMap.get('stcc'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('shipperCode'))) && String.isBlank(equipLine.shipperCode)
					) {
						//equipLine.shipperCode = string.valueOf(fldxRowMap.get('shipperCode'));
						equipLine.shipperName = string.valueOf(fldxRowMap.get('shipperCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('shipperAsClaimant'))) &&
						String.isBlank(equipLine.shipperAsClaimant)
					) {
						equipLine.shipperAsClaimant = string.valueOf(fldxRowMap.get('shipperAsClaimant'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('consigneeCode'))) &&
						String.isBlank(equipLine.consigneeCode)
					) {
						//equipLine.consigneeCode = string.valueOf(fldxRowMap.get('consigneeCode'));
						equipLine.consigneeName = string.valueOf(fldxRowMap.get('consigneeCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualOriginSCAC'))) &&
						String.isBlank(equipLine.actualOriginSCAC)
					) {
						equipLine.actualOriginSCAC = string.valueOf(fldxRowMap.get('actualOriginSCAC'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualDestinationSCAC'))) &&
						String.isBlank(equipLine.actualDestinationSCAC)
					) {
						equipLine.actualDestinationSCAC = string.valueOf(fldxRowMap.get('actualDestinationSCAC'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('mvManufacturingCode'))) &&
						String.isBlank(equipLine.mvManufacturingCode)
					) {
						equipLine.mvManufacturingCode = string.valueOf(fldxRowMap.get('mvManufacturingCode'));
					}

					if (String.isNotBlank(string.valueOf(fldxRowMap.get('multiCarCount'))) && equipLine.multiCarCount == null) {
						equipLine.multiCarCount = Integer.valueOf(string.valueOf(fldxRowMap.get('multiCarCount')));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('piggybackPlanNumber'))) &&
						String.isBlank(equipLine.piggybackPlanNumber)
					) {
						equipLine.piggybackPlanNumber = string.valueOf(fldxRowMap.get('piggybackPlanNumber'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualOriginCityName'))) &&
						String.isBlank(equipLine.actualOriginCityName)
					) {
						equipLine.actualOriginCityName = string.valueOf(fldxRowMap.get('actualOriginCityName'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualOriginStateCode'))) &&
						String.isBlank(equipLine.actualOriginStateCode)
					) {
						equipLine.actualOriginStateCode = string.valueOf(fldxRowMap.get('actualOriginStateCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualDestinationCityName'))) &&
						String.isBlank(equipLine.actualDestinationCityName)
					) {
						equipLine.actualDestinationCityName = string.valueOf(fldxRowMap.get('actualDestinationCityName'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('actualDestinationStateCode'))) &&
						String.isBlank(equipLine.actualDestinationStateCode)
					) {
						equipLine.actualDestinationStateCode = string.valueOf(fldxRowMap.get('actualDestinationStateCode'));
					}

					if (
						String.isNotBlank(string.valueOf(fldxRowMap.get('waybillNumber'))) &&
						String.isBlank(equipLine.waybillNumber)
					) {
						equipLine.waybillNumber = string.valueOf(fldxRowMap.get('waybillNumber'));
					}

					if (string.isNotBlank(string.valueOf(fldxRowMap.get('waybillDate'))) && equipLine.waybillDate == null) {
						equipLine.waybillDate = Date.valueOf(string.valueOf(fldxRowMap.get('waybillDate')));
					}

					if (String.isNotBlank(String.valueOf(fldxRowMap.get('waybillFoundFlag'))) && equipLine.waybillFoundFlag == null) {
						equipLine.waybillFoundFlag = Boolean.valueOf(string.valueOf(fldxRowMap.get('waybillFoundFlag')));
					} else {
						equipLine.waybillFoundFlag = true;
					}

					if (
						String.isNotBlank(String.valueOf(fldxRowMap.get('equipmentInitial'))) &&
						String.isBlank(equipLine.equipmentInitial)
					) {
						equipLine.equipmentInitial = string.valueOf(fldxRowMap.get('equipmentInitial'));
					}

					if (
						String.isNotBlank(String.valueOf(fldxRowMap.get('equipmentNumber'))) &&
						String.isBlank(equipLine.equipmentNumber)
					) {
						equipLine.equipmentNumber = string.valueOf(fldxRowMap.get('equipmentNumber'));
					}

					if (
						String.isNotBlank(String.valueOf(fldxRowMap.get('originAuditNumber'))) &&
						String.isBlank(equipLine.originAuditNumber)
					) {
						equipLine.originAuditNumber = string.valueOf(fldxRowMap.get('originAuditNumber'));
					}

					if (
						String.isNotBlank(String.valueOf(fldxRowMap.get('destinationAuditNumber'))) &&
						String.isBlank(equipLine.destinationAuditNumber)
					) {
						equipLine.destinationAuditNumber = string.valueOf(fldxRowMap.get('destinationAuditNumber'));
					}

					if (fldxRowMap.containsKey('waybillToCityFSAC')) {
						if (
							String.isNotBlank(String.valueOf(fldxRowMap.get('waybillToCityFSAC'))) &&
							String.isBlank(equipLine.wayBillToFSAC)
						) {
							equipLine.wayBillToFSAC = String.valueOf(fldxRowMap.get('waybillToCityFSAC'));
						}
					}

					if (fldxRowMap.containsKey('waybillFromCityFSAC')) {
						if (
							String.isNotBlank(String.valueOf(fldxRowMap.get('waybillFromCityFSAC'))) &&
							String.isBlank(equipLine.wayBillFromFSAC)
						) {
							equipLine.wayBillFromFSAC = String.valueOf(fldxRowMap.get('waybillFromCityFSAC'));
						}
					}

					if (String.isNotBlank(String.valueOf(fldxRowMap.get('vin')))) {
						CSX_CMP_NewClaimWrapper.Product product = new CSX_CMP_NewClaimWrapper.Product();
						product.vin = String.valueOf(fldxRowMap.get('vin'));
						equipLine.products.add(product);
					}

					List<CSX_CMP_NewClaimWrapper.Distribution> distributions = new List<CSX_CMP_NewClaimWrapper.Distribution>();
					if (!equipLine.distributions.isEmpty()) {
						distributions = equipLine.distributions;
					}

					Decimal claimTotalAmount = 0;
					if (identifierToDistributionCount.containsKey(string.valueOf(fldxRowMap.get('recordIdentifier')))) {
						for (
							Integer i = 1;
							i <= identifierToDistributionCount.get(string.valueOf(fldxRowMap.get('recordIdentifier')));
							i++
						) {
							if (checkDistributionFields(fldxRowMap, i)) {
								CSX_CMP_NewClaimWrapper.Distribution distribution = new CSX_CMP_NewClaimWrapper.Distribution();
								if (string.isNotBlank(string.valueOf(fldxRowMap.get('junction' + i)))) {
									distribution.junctionCode = string.valueOf(fldxRowMap.get('junction' + i));
								}

								if (string.isNotBlank(string.valueOf(fldxRowMap.get('miles' + i)))) {
									distribution.miles = Integer.valueOf(string.valueOf(fldxRowMap.get('miles' + i)));
								}

								if (fldxRowMap.containsKey('roadReceivePapers')) {
									if (String.isNotBlank(String.valueOf(fldxRowMap.get('roadReceivePapers')))) {
										distribution.roadReceivePapers = string.valueOf(fldxRowMap.get('roadReceivePapers'));
									}
								}
								if (String.isNotBlank(string.valueOf(fldxRowMap.get('amountProrated' + i)))) {
									distribution.manualAdjustedAmount = Decimal.valueOf(
										string.valueOf(fldxRowMap.get('amountProrated' + i))
									);
								}
								if (String.isNotBlank(string.valueOf(fldxRowMap.get('specialAmount' + i)))) {
									distribution.foreignBilledAmount = Decimal.valueOf(
										string.valueOf(fldxRowMap.get('specialAmount' + i))
									);
								}
								// if (string.isNotBlank(string.valueOf(fldxRowMap.get('distributionTypeCode' + i)))) {
								// 	distribution.scac = string.valueOf(fldxRowMap.get('distributionTypeCode' + i));
								// }
								if (string.isNotBlank(string.valueOf(fldxRowMap.get('roadCode' + i)))) {
									distribution.scac = string.valueOf(fldxRowMap.get('roadCode' + i));

									if (
										string.valueOf(fldxRowMap.get('roadCode' + i)) == '0712' ||
										string.valueOf(fldxRowMap.get('roadCode' + i)) == '712'
									) {
										if (string.isNotBlank(string.valueOf(fldxRowMap.get('totalAmount' + i)))) {
											claimTotalAmount += Decimal.valueOf(string.valueOf(fldxRowMap.get('totalAmount' + i)));
										}
									}
								}

								//distribution.carrierCode = string.valueOf(fldxRowMap.get('distributionTypeCode' + i));
								distributions.add(distribution);
							}
						}
					}

					newClaimWrap.claimAmount = (newClaimWrap.claimAmount == null) ? 0 : newClaimWrap.claimAmount;

					Decimal claimAmount = 0;
					
					if (claimTotalAmount > 0) {
						newClaimWrap.claimAmount += claimTotalAmount;
						claimAmount =   newClaimWrap.claimAmount;
					}

					equipLine.distributions = distributions;

					// Will equipline added in else part contains all previously filled fields - need to check
					if (newClaimWrap.equipment.isEmpty()) {
						newClaimWrap.equipment.add(equipLine);
					} else {
						newClaimWrap.equipment[0] = equipLine;
					}

					wrapperMap.put(newClaimWrap.claimantReferenceNumber, newClaimWrap);

					string railRoadCode = string.valueOf(fldxRowMap.get('senderSCAC'));

					//string claimAmnt = string.valueOf(fldxRowMap.get('amount'));

					
					//claimAmount = (claimAmnt == '' || claimAmnt == '0' || claimAmnt == null) ? 0.00 : Decimal.valueOf(claimAmnt);

					/*if (railroadCodetoTotalClaimAmountMap.containsKey(railRoadCode)) {
						Decimal currentAmount = railroadCodetoTotalClaimAmountMap.get(railRoadCode);
						railroadCodetoTotalClaimAmountMap.put(railRoadCode, currentAmount + claimAmount);
					} else {
						railroadCodetoTotalClaimAmountMap.put(railRoadCode, claimAmount);
					}
					
					if (railroadCodetoRowCountMap.containsKey(railRoadCode)) {
						Integer currentCount = railroadCodetoRowCountMap.get(railRoadCode);
						railroadCodetoRowCountMap.put(railRoadCode, currentCount + 1);
					} else {
						railroadCodetoRowCountMap.put(railRoadCode, 1);
					}

					if (uniqueClaimantMap.containsKey(railRoadCode)) {
						uniqueClaimantMap.get(railRoadCode).add(newClaimWrap.claimantReferenceNumber);
					} else {
						uniqueClaimantMap.put(railRoadCode, new Set<string>());
					}
					*/

					if (railroadCodetoTotalClaimAmountMap.containsKey(railRoadCode)) {
						Decimal currentAmount = 0;

						if (
							railroadCodeMap.containsKey(railRoadCode) &&
							railroadCodetoTotalClaimAmountMap.containsKey(railroadCodeMap.get(railRoadCode))
						) {
							currentAmount =
								railroadCodetoTotalClaimAmountMap.get(railRoadCode) +
								railroadCodetoTotalClaimAmountMap.get(railroadCodeMap.get(railRoadCode));
						} else {
							currentAmount = railroadCodetoTotalClaimAmountMap.get(railRoadCode);
						}

						if (railroadCodeMap.containsKey(railRoadCode)) {
							railroadCodetoTotalClaimAmountMap.put(railroadCodeMap.get(railRoadCode), currentAmount + claimAmount);
							railroadCodetoTotalClaimAmountMap.remove(railRoadCode);
						} else {
							railroadCodetoTotalClaimAmountMap.put(railRoadCode, currentAmount + claimAmount);
						}

					} else {
						railroadCodetoTotalClaimAmountMap.put(railRoadCode, claimAmount);
					}

					if (railroadCodetoRowCountMap.containsKey(railRoadCode)) {
						Integer currentCount = 0;
						if (
							railroadCodeMap.containsKey(railRoadCode) &&
							railroadCodetoRowCountMap.containsKey(railroadCodeMap.get(railRoadCode))
						) {
							currentCount =
								railroadCodetoRowCountMap.get(railRoadCode) +
								railroadCodetoRowCountMap.get(railroadCodeMap.get(railRoadCode));
						} else {
							currentCount = railroadCodetoRowCountMap.get(railRoadCode);
						}

						if (railroadCodeMap.containsKey(railRoadCode)) {
							railroadCodetoRowCountMap.put(railroadCodeMap.get(railRoadCode), currentCount + 1);
							railroadCodetoRowCountMap.remove(railRoadCode);
						} else {
							railroadCodetoRowCountMap.put(railRoadCode, currentCount + 1);
						}
					} else {
						railroadCodetoRowCountMap.put(railRoadCode, 1);
					}

					if (uniqueClaimantMap.containsKey(railRoadCode)) {
						Set<string> claimantSet = new Set<string>();
						if (
							railroadCodeMap.containsKey(railRoadCode) &&
							uniqueClaimantMap.containsKey(railroadCodeMap.get(railRoadCode))
						) {
							claimantSet = uniqueClaimantMap.get(railroadCodeMap.get(railRoadCode));
						} else {
							claimantSet = uniqueClaimantMap.get(railRoadCode);
						}

						if (railroadCodeMap.containsKey(railRoadCode)) {
							claimantSet.add(newClaimWrap.claimantReferenceNumber);
							uniqueClaimantMap.put(railroadCodeMap.get(railRoadCode), claimantSet);
							uniqueClaimantMap.remove(railRoadCode);
						} else {
							claimantSet.add(newClaimWrap.claimantReferenceNumber);
							uniqueClaimantMap.put(railRoadCode, claimantSet);
						}
					} else {
						uniqueClaimantMap.put(railRoadCode, new Set<string>{ newClaimWrap.claimantReferenceNumber });
					}
				}
			}
			
			responseMap.put('railroadCodetoTotalClaimAmountMap', railroadCodetoTotalClaimAmountMap);
			responseMap.put('railroadCodetoRowCountMap', railroadCodetoRowCountMap);
			responseMap.put('uniqueClaimantMap', uniqueClaimantMap);
			responseMap.put('wrapperMap', wrapperMap);
			responseMap.put('sourceRailroadCodetoTotalClaimAmountMap', sourceRailroadCodetoTotalClaimAmountMap);
			responseMap.put('sourceRailroadCodetoClaimCountMap', sourceRailroadCodetoClaimCountMap);
			responseMap.put('sourceRailroadCodetoRowCountMap', sourceRailroadCodetoRowCountMap);
			responseMap.put('sourceGrandClaimTotalAmount', sourceGrandClaimTotalAmount);
			responseMap.put('sourceGrandClaimCount', sourceGrandClaimCount);
			responseMap.put('sourceGrandClaimRowCount', sourceGrandClaimRowCount);
			
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_FLDXInboundCreateServiceHelper', 'prepareClaimWrapper', '', e);
			
		}
		return responseMap;
	}

	private static Boolean checkDistributionFields(Map<String, Object> fldxRowMap, Integer i) {
		Boolean isValid = false;
		if (
			//fldxRowMap.containsKey('junction' + i) &&
			fldxRowMap.containsKey('miles' + i) && fldxRowMap.containsKey('roadCode' + i)
		) {
			if (
				//String.isNotBlank(String.valueOf(fldxRowMap.get('junction' + i))) &&
				(String.isNotBlank(String.valueOf(fldxRowMap.get('miles' + i))) 
				// && String.valueOf(fldxRowMap.get('miles' + i)) != '0000'
				) &&
				(String.isNotBlank(String.valueOf(fldxRowMap.get('roadCode' + i))) && String.valueOf(fldxRowMap.get('roadCode' + i)) != '0000')
			) {
				isValid = true;
			}
		}
		return isValid;
	}
}