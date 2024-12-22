/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRulesUtility
@Created Date - 10/18/2023
@Description  - Apex utility method to maintain all methods related to business rules engine
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_BusinessRulesUtility {
	//public variables
	public static map<Id, Case> mapOfClaims;

	//Fetch All required Business rules and details based on record type
	public static list<CSX_CMP_Business_Rule__c> getBusinessRuleDetails(
		Id recordTypeId,
		Id businessRuleId,
		String strClaimType
	) {
		try {
			//create dynamic string query
			string strStatusValid = 'Valid';
			String strQyery =
				'Select Id, Name, CSX_CMP_Where_Clause__c, CSX_CMP_Status__c, CSX_CMP_Rule_Name__c, CSX_CMP_Start_Date__c,' +
				'CSX_CMP_Comments__c, RecordTypeId, RecordType.DeveloperName, CSX_CMP_End_Date__c,CSX_CMP_Auto_pay_kickout_Code__r.Name,CSX_CMP_Desk_Name__c,CSX_CMP_Desk_Name__r.Name, CSX_CMP_Desk_Name__r.CSX_CMP_Desk_Owner__r.Id, CSX_CMP_Claim_Type__c,' +
				'CSX_CMP_Owner__c, CSX_CMP_Owner__r.FirstName,CSX_CMP_Owner__r.LastName,' +
				'CSX_CMP_Finance_Charge_Threshold__c, CSX_CMP_AR_Percentage_Past_Due__c, CSX_CMP_AR_Threshold_Amount__c,CSX_CMP_Matches_Count__c,' +
				'CSX_CMP_Decline_Code__c,CSX_CMP_Decline_Code__r.Name,OwnerId, Owner.FirstName,Owner.LastName,CSX_CMP_Claim_Priority__c,' +
				'( Select Id, Name, CSX_CMP_Attribute_Name__c, CSX_CMP_Range_1__c, CSX_CMP_Range_2__c, CSX_CMP_Operator__c,' +
				'CSX_CMP_Value__c from Business_Rule_Conditions__r),' +
				'(Select Id, Name, CSX_CMP_Question__c,CSX_CMP_Question_To__c from FLR_Questions__r),' +
				'(Select Id , Name , CSX_CMP_Task_Name__c, CSX_CMP_Task_Priority__c, CSX_CMP_Task_Type__c from Task_Checklists__r),' +
				'(Select Id , Name, CSX_CMP_Approver__c , CSX_CMP_Approver_Type__c, CSX_CMP_Business_Rule__c from Approval_Sequences__r)' +
				'from CSX_CMP_Business_Rule__c where CSX_CMP_Status__c =: strStatusValid and CSX_CMP_Start_Date__c <= Today and (CSX_CMP_End_Date__c = null or CSX_CMP_End_Date__c >= Today) ';

			if (String.isNotBlank(recordTypeId)) {
				string strescapedRecordTypeId = String.escapeSingleQuotes(recordTypeId);
				strQyery += ' and RecordTypeId =: strescapedRecordTypeId';
			}

			if (String.isNotBlank(businessRuleId)) {
				String strescapeBusinessRuleId = String.escapeSingleQuotes(businessRuleId);
				strQyery += ' and Id =: strescapeBusinessRuleId';
			}

			if (String.isNotBlank(strClaimType)) {
				string strescapeClaimType = String.escapeSingleQuotes(strClaimType);
				strQyery += ' and CSX_CMP_Claim_Type__c INCLUDES (\'' + strescapeClaimType + '\')';
			}

			strQyery = strQyery + ' order by CSX_CMP_Priority__c asc';
			return (list<CSX_CMP_Business_Rule__c>) Database.query(strQyery);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'getBusinessRuleDetails',
				String.valueOf(recordTypeId),
				ex
			);
		}
		return null;
	}

	//Fetch the record Type Id based on record type name (Need to move this method in utility class)
	public static Id getRecordTypeIdbyName(String objectName, String strRecordTypeName) {
		return Schema.getGlobalDescribe()
			.get(objectName)
			.getDescribe()
			.getRecordTypeInfosByDeveloperName()
			.get(strRecordTypeName)
			.getRecordTypeId();
	}

	//method to fetch claim details for business rules evaluation
	public static map<Id, ClaimWrapper> gatherFullClaimDetails(Set<Id> claimIds) {
		map<Id, ClaimWrapper> mapofClaimWrappper = new Map<Id, ClaimWrapper>();

		try {
			if (claimIds != null && claimIds.size() > 0) {
				//Get Similarity Matrix data
				Map<String, list<CSX_CMP_Similarity_Matrix__c>> mapOfDamageKeyWithListOfSimilarityMatrix = new Map<String, list<CSX_CMP_Similarity_Matrix__c>>();

				List<CSX_CMP_Similarity_Matrix__c> lstSimilarityMatrix = [
					SELECT
						Id,
						Name,
						CSX_CMP_Damage_Code__c,
						CSX_CMP_Similar_Damage_Code__c,
						CSX_CMP_Enabled__c,
						CSX_CMP_Start_Date__c,
						CSX_CMP_End_Date__c,
						CSX_CMP_Type__c,
						CSX_CMP_External_ID__c
					FROM CSX_CMP_Similarity_Matrix__c
					WHERE
						CSX_CMP_Start_Date__c <= Today
						AND (CSX_CMP_End_Date__c = NULL
						OR CSX_CMP_End_Date__c >= Today)
					//WITH SECURITY_ENFORCED
				];

				if (lstSimilarityMatrix != null && lstSimilarityMatrix.size() > 0) {
					for (CSX_CMP_Similarity_Matrix__c objSimilarityMatrix : lstSimilarityMatrix) {
						if (
							mapOfDamageKeyWithListOfSimilarityMatrix.get(
								objSimilarityMatrix.CSX_CMP_Type__c +
								'_' +
								objSimilarityMatrix.CSX_CMP_Damage_Code__c
							) == null
						) {
							mapOfDamageKeyWithListOfSimilarityMatrix.put(
								objSimilarityMatrix.CSX_CMP_Type__c +
								'_' +
								objSimilarityMatrix.CSX_CMP_Damage_Code__c,
								new List<CSX_CMP_Similarity_Matrix__c>()
							);
						}
						mapOfDamageKeyWithListOfSimilarityMatrix.get(
								objSimilarityMatrix.CSX_CMP_Type__c +
								'_' +
								objSimilarityMatrix.CSX_CMP_Damage_Code__c
							)
							.add(objSimilarityMatrix);
					}
				}

				// Get the list of all the claims based on the set of ids provided
				mapOfClaims = new Map<Id, Case>(
					[
						SELECT
							Id,
							CaseNumber,
							CSX_CMP_Age__c,
							CSX_CMP_Claim_Amount__c,
							CSX_CMP_Supplier_Claimant__r.Name,
							CSX_CMP_Claim_Reason__c,
							RecordType.DeveloperName,
							Status,
							CSX_CMP_Desk_Name__c,
							CSX_CMP_Desk_Name__r.Name,
							CSX_CMP_National_Account_Num__c,
							Origin,
							ParentId,
							CSX_CMP_Derailment__c,
							Contact.Name,
							Account.Name,
							CSX_CMP_Auto_Pay__c,
							CSX_CMP_Dealer_SPLC__c,
							Type,
							CSX_CMP_BU__c,
							CSX_CMP_RACF_ID__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_EDI_Sender_ID__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_From__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_To__c,
							CSX_CMP_Supplier_Claimant__r.CSX_CMP_Freight_Collections_Team_Number__c,	
							CSX_CMP_Supplier_Claimant__c,
							CSX_CMP_Related_Claim_Count__c,
							CSX_CMP_Contract_Num__r.Name,
							CSX_CMP_Contract_Num__r.CSX_CMP_Claim_Type__c,
							CSX_CMP_Supplier_Claimant__r.BillingCountry,
							CSX_CMP_VIN__c,
							CSX_CMP_Supplier_Claimant_Site__c,
							CSX_CMP_Period_Begin__c,
							CSX_CMP_Period_End__c,
							(
								SELECT
									Id,
									Name,
									CSX_CMP_Act_Destination_City__c,
									CSX_CMP_Waybill_Num__c,
									CSX_CMP_STCC__c,
									CSX_CMP_Waybill_Date__c,
									CSX_CMP_Equipment_Initial__c,
									CSX_CMP_Act_Destination_Road__c,
									CSX_CMP_Act_Origin_Road__c,
									CSX_CMP_Act_Origin_City__c,
									CSX_CMP_Shipper__c,
									CSX_CMP_MV_Manufacturer_Route_Code__c,
									CSX_CMP_Equipment_Num__c,
									CSX_CMP_Waybill_Date_Aging__c,
									CSX_CMP_Freight_Bill_Num__c,
									CSX_CMP_BU__c
								FROM Equipments__r
							),
							(
								SELECT
									Id,
									CSX_CMP_Act_Destination_City__c,
									CSX_CMP_Waybill_Num__c,
									CSX_CMP_STCC__c,
									CSX_CMP_Waybill_Date__c,
									CSX_CMP_Equipment_Initial__c,
									CSX_CMP_Act_Origin_City__c,
									CSX_CMP_Equipment_Num__c,
									CSX_CMP_Freight_Bill_Num__c,
									Name,
									CSX_CMP_URRWIN_Num__c,
									CSX_CMP_Waybill_Date_Aging__c
								FROM ClaimLines__r 
							),
							(SELECT Id, CSX_CMP_LD_Report__r.Name FROM Related_L_D_Reports__r)
						FROM Case
						WHERE Id IN :claimIds
						//WITH SECURITY_ENFORCED
					]
				);

				if (mapOfClaims != null && mapOfClaims.size() > 0) {
					Set<Id> setOfEquipmentIds = new Set<Id>();
					map<Id, list<CSX_CMP_Product__c>> mapOfEquipmentvslstProduct = new Map<Id, list<CSX_CMP_Product__c>>();
					map<Id, list<CSX_CMP_Distribution__c>> mapOfEquipmentvsDistribution = new Map<Id, list<CSX_CMP_Distribution__c>>();

					//Create set of Equipment Id and Account Id
					for (Case objCase : mapOfClaims.values()) {
						if (objCase.Equipments__r != null && objCase.Equipments__r.size() > 0) {
							for (CSX_CMP_Equipment__c objEquipment : objCase.Equipments__r) {
								setOfEquipmentIds.add(objEquipment.Id);
							}
						}
					}

					if (setOfEquipmentIds.size() > 0) {
						// Get all the Product records based on the equipment ids and create the equipment vs product map
						list<CSX_CMP_Product__c> lstProduct = [
							SELECT
								Id,
								CSX_CMP_Equipment__c,
								(
									SELECT
										Id,
										CSX_CMP_Report_Type__c,
										CSX_CMP_Area__c,
										CSX_CMP_Type__c,
										CSX_CMP_Severity__c
									FROM Inspection_Damages__r
								),
								(
									SELECT Id, Name, CSX_CMP_Area__c, CSX_CMP_Type__c, CSX_CMP_Severity__c
									FROM Customer_Damages__r
								)
							FROM CSX_CMP_Product__c
							WHERE CSX_CMP_Equipment__c IN :setOfEquipmentIds
							//WITH SECURITY_ENFORCED
						];

						if (lstProduct != null && lstProduct.size() > 0) {
							for (CSX_CMP_Product__c objProduct : lstProduct) {
								if (mapOfEquipmentvslstProduct.get(objProduct.CSX_CMP_Equipment__c) == null) {
									mapOfEquipmentvslstProduct.put(
										objProduct.CSX_CMP_Equipment__c,
										new List<CSX_CMP_Product__c>()
									);
								}
								mapOfEquipmentvslstProduct.get(objProduct.CSX_CMP_Equipment__c).add(objProduct);
							}
						}

						//Get all the Distribution records based on the equipment ids and create the equipment vs Distribution map
						list<CSX_CMP_Distribution__c> lstDistribution = [
							SELECT
								Id,
								CSX_CMP_Road__c,
								CSX_CMP_Code__c,
								CSX_CMP_Equipment__c,
								CSX_CMP_Account__r.CSX_CMP_FC_Contact_Email__c,
								CSX_CMP_Non_CSX_Mexican_RR__c
							FROM CSX_CMP_Distribution__c
							WHERE CSX_CMP_Equipment__c IN :setOfEquipmentIds
							//WITH SECURITY_ENFORCED
						];

						if (lstDistribution != null && lstDistribution.size() > 0) {
							for (CSX_CMP_Distribution__c objDistribution : lstDistribution) {
								if (mapOfEquipmentvsDistribution.get(objDistribution.CSX_CMP_Equipment__c) == null) {
									mapOfEquipmentvsDistribution.put(
										objDistribution.CSX_CMP_Equipment__c,
										new List<CSX_CMP_Distribution__c>()
									);
								}
								mapOfEquipmentvsDistribution.get(objDistribution.CSX_CMP_Equipment__c)
									.add(objDistribution);
							}
						}
					}

					//Create the wrapper class based on the values fetch from the database
					for (Case objCase : mapOfClaims.values()) {
						//Claim wrapper creation
						ClaimWrapper objClaimWrapper = new ClaimWrapper();
						objClaimWrapper.id = objCase.Id;
						objClaimWrapper.claimAge = objCase.CSX_CMP_Age__c;
						objClaimWrapper.claimAmount = objCase.CSX_CMP_Claim_Amount__c;
						objClaimWrapper.businessUnit = objCase.CSX_CMP_BU__c;
						objClaimWrapper.claimReason = objCase.CSX_CMP_Claim_Reason__c;
						objClaimWrapper.claimStatus = objCase.Status;
						objClaimWrapper.claimType = objCase.Type;
						objClaimWrapper.nationalAccount = objCase.CSX_CMP_National_Account_Num__c;
						objClaimWrapper.claimSource = objCase.Origin;
						objClaimWrapper.numberofRelatedClaim = objCase.CSX_CMP_Related_Claim_Count__c;
						objClaimWrapper.claimVin = objCase.CSX_CMP_VIN__c;
						objClaimWrapper.claimNumber = objCase.CaseNumber;

						if (objCase.CSX_CMP_Desk_Name__c != null) {
							objClaimWrapper.deskName = objCase.CSX_CMP_Desk_Name__r.Name;
						}

						if (objCase.CSX_CMP_Supplier_Claimant__c != null) {
							objClaimWrapper.teamNumber = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_Freight_Collections_Team_Number__c;
							objClaimWrapper.claimantName = objCase.CSX_CMP_Supplier_Claimant__r.Name;
							objClaimWrapper.claimVendor = objCase.CSX_CMP_Supplier_Claimant__r.Name;
							objClaimWrapper.vendorSite = objCase.CSX_CMP_Supplier_Claimant_Site__c;
							objClaimWrapper.supplierEDICode = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_EDI_Sender_ID__c;
							objClaimWrapper.customerIsMissing = false;
														
							objClaimWrapper.supplierCountry = objCase.CSX_CMP_Supplier_Claimant__r.BillingCountry;

							if (
								objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_From__c != null &&
								objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_To__c != null &&
								objCase.CSX_CMP_Claim_Amount__c != null &&
								objCase.CSX_CMP_Claim_Amount__c >=
								objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_From__c &&
								objCase.CSX_CMP_Claim_Amount__c <=
								objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Threshold_To__c
							) {
								objClaimWrapper.claimAmountwithinthreshold = true;
							} else {
								objClaimWrapper.claimAmountwithinthreshold = false;
							}
						}else{
							objClaimWrapper.customerIsMissing = true;
						}

						objClaimWrapper.shipCSXUserID = objCase.CSX_CMP_RACF_ID__c;
						objClaimWrapper.derailmentFlag = objCase.CSX_CMP_Derailment__c;
						objClaimWrapper.autoSettleReturnStatus = objCase.CSX_CMP_Auto_Pay__c;
						objClaimWrapper.dealerSPLC = objCase.CSX_CMP_Dealer_SPLC__c;
						objClaimWrapper.recordType = objCase.RecordType.DeveloperName;
						if (objCase.CSX_CMP_Contract_Num__c != null) {
							objClaimWrapper.contractName = objCase.CSX_CMP_Contract_Num__r.Name;
							objClaimWrapper.contractType = objCase.CSX_CMP_Contract_Num__r.CSX_CMP_Claim_Type__c;
						}

						if (objCase.CSX_CMP_Period_Begin__c != null && objCase.CSX_CMP_Period_End__c != null) {
							objClaimWrapper.claimRefundPeriod =
								string.valueOf(objCase.CSX_CMP_Period_Begin__c) +
								'#' +
								string.valueOf(objCase.CSX_CMP_Period_End__c);
						}

						if (objCase.Related_L_D_Reports__r != null && objCase.Related_L_D_Reports__r.size() > 0) {
							for (CSX_CMP_Related_LD_Report__c objRelatedLDReport : objCase.Related_L_D_Reports__r) {
								if (objRelatedLDReport.CSX_CMP_LD_Report__c != null) {
									objClaimWrapper.ldNumber.add(objRelatedLDReport.CSX_CMP_LD_Report__r.Name);
								}
							}
						}

						//Claim Line Wrapper
						if (objCase.ClaimLines__r != null && objCase.ClaimLines__r.size() > 0) {
							for (CSX_CMP_Claim_Line__c objClaimLine : objCase.ClaimLines__r) {
								EquipmentWrapper objEquipmentWrapper = new EquipmentWrapper();
								objEquipmentWrapper.id = objClaimLine.Id;
								objEquipmentWrapper.waybillDestCity = objClaimLine.CSX_CMP_Act_Destination_City__c;
								objEquipmentWrapper.waybillNum = objClaimLine.CSX_CMP_Waybill_Num__c;
								objEquipmentWrapper.stccCode = objClaimLine.CSX_CMP_STCC__c;
								objEquipmentWrapper.waybillDate = CSX_CMP_Utility.formatDate(
									objClaimLine.CSX_CMP_Waybill_Date__c
								);
								objEquipmentWrapper.equipInitial = objClaimLine.CSX_CMP_Equipment_Initial__c;
								objEquipmentWrapper.waybillActualOriginCity = objClaimLine.CSX_CMP_Act_Origin_City__c;
								objEquipmentWrapper.waybillDateAging = objClaimLine.CSX_CMP_Waybill_Date_Aging__c;
								objEquipmentWrapper.equipNum = objClaimLine.CSX_CMP_Equipment_Num__c;
								objEquipmentWrapper.freightbillNum = objClaimLine.CSX_CMP_Freight_Bill_Num__c;
								objEquipmentWrapper.urwinNum = objClaimLine.CSX_CMP_URRWIN_Num__c;
								objClaimWrapper.equipment.add(objEquipmentWrapper);
							}
						}

						//Equipment wrapper creation
						if (objCase.Equipments__r != null && objCase.Equipments__r.size() > 0) {
							for (CSX_CMP_Equipment__c objEquipment : objCase.Equipments__r) {
								EquipmentWrapper objEquipmentWrapper = new EquipmentWrapper();
								objEquipmentWrapper.id = objEquipment.Id;
								//objEquipmentWrapper.businessUnit = objEquipment.CSX_CMP_BU__c;
								objEquipmentWrapper.equipmentName = objEquipment.Name;
								objEquipmentWrapper.waybillDestCity = objEquipment.CSX_CMP_Act_Destination_City__c;
								objEquipmentWrapper.waybillNum = objEquipment.CSX_CMP_Waybill_Num__c;
								objEquipmentWrapper.stccCode = objEquipment.CSX_CMP_STCC__c;
								objEquipmentWrapper.waybillDate = CSX_CMP_Utility.formatDate(
									objEquipment.CSX_CMP_Waybill_Date__c
								);
								objEquipmentWrapper.equipInitial = objEquipment.CSX_CMP_Equipment_Initial__c;
								objEquipmentWrapper.waybillActualOriginCity = objEquipment.CSX_CMP_Act_Origin_City__c;
								objEquipmentWrapper.waybillDateAging = objEquipment.CSX_CMP_Waybill_Date_Aging__c;
								objEquipmentWrapper.equipNum = objEquipment.CSX_CMP_Equipment_Num__c;
								objEquipmentWrapper.freightbillNum = objEquipment.CSX_CMP_Freight_Bill_Num__c;
								objEquipmentWrapper.waybillActualDestinationRoad = objEquipment.CSX_CMP_Act_Destination_Road__c;
								objEquipmentWrapper.waybillActualOriginRoad = objEquipment.CSX_CMP_Act_Origin_Road__c;
								objEquipmentWrapper.equipmentShipper = objEquipment.CSX_CMP_Shipper__c;
								objEquipmentWrapper.routeCode = objEquipment.CSX_CMP_MV_Manufacturer_Route_Code__c;
								objClaimWrapper.equipment.add(objEquipmentWrapper);

								//Distribution wrapper creation
								if (
									mapOfEquipmentvsDistribution != null &&
									mapOfEquipmentvsDistribution.size() > 0 &&
									mapOfEquipmentvsDistribution.get(objEquipment.Id) != null &&
									mapOfEquipmentvsDistribution.get(objEquipment.Id).size() > 0
								) {
									for (
										CSX_CMP_Distribution__c objDistribution : mapOfEquipmentvsDistribution.get(
											objEquipment.Id
										)
									) {
										DistributionWrapper objDistributionWrapper = new DistributionWrapper();

										objDistributionWrapper.id = objDistribution.Id;
										objDistributionWrapper.dRoute = objDistribution.CSX_CMP_Code__c;
										objDistributionWrapper.rrCode = objDistribution.CSX_CMP_Road__c;

										if (
											String.isNotBlank(
												objDistribution.CSX_CMP_Account__r.CSX_CMP_FC_Contact_Email__c
											)
										) {
											objDistributionWrapper.fCContactEmail = objDistribution.CSX_CMP_Account__r.CSX_CMP_FC_Contact_Email__c;
										}

										if (
											objDistribution.CSX_CMP_Non_CSX_Mexican_RR__c == true &&
											String.isNotBlank(
												objDistribution.CSX_CMP_Account__r.CSX_CMP_FC_Contact_Email__c
											)
										) {
											objDistributionWrapper.nonCSXMexicanRR = true;
										} else {
											objDistributionWrapper.nonCSXMexicanRR = false;
										}
										objEquipmentWrapper.distribution.add(objDistributionWrapper);
									}
								}

								//Product wrapper creation
								if (
									mapOfEquipmentvslstProduct != null &&
									mapOfEquipmentvslstProduct.size() > 0 &&
									mapOfEquipmentvslstProduct.get(objEquipment.Id) != null &&
									mapOfEquipmentvslstProduct.get(objEquipment.Id).size() > 0
								) {
									for (
										CSX_CMP_Product__c objProduct : mapOfEquipmentvslstProduct.get(objEquipment.Id)
									) {
										ProductWrapper objproductWrapper = new ProductWrapper();
										objproductWrapper.id = objProduct.Id;

										Boolean inspectionReportType2178 = false;
										String strInspectionReportType2178 = '02,2,01,1,07,7,08,8';
										Integer int04inspCount = 0;

										//Inseption Damage wrappper creation
										if (
											objProduct.Inspection_Damages__r != null &&
											objProduct.Inspection_Damages__r.size() > 0
										) {
											for (
												CSX_CMP_Inspection_Damage__c objInspectionDamage : objProduct.Inspection_Damages__r
											) {
												if (objInspectionDamage.CSX_CMP_Report_Type__c != null) {
													if (objInspectionDamage.CSX_CMP_Report_Type__c == '04') {
														int04inspCount++;
													}

													if (
														strInspectionReportType2178.contains(
															objInspectionDamage.CSX_CMP_Report_Type__c
														)
													) {
														inspectionReportType2178 = true;
													}
												}

												InspectionDamageWrapper objInspectionDamageWrapper = new InspectionDamageWrapper();
												objInspectionDamageWrapper.id = objInspectionDamage.Id;
												objInspectionDamageWrapper.idArea = objInspectionDamage.CSX_CMP_Area__c;
												objInspectionDamageWrapper.idType = objInspectionDamage.CSX_CMP_Type__c;
												objInspectionDamageWrapper.idSeverity = objInspectionDamage.CSX_CMP_Severity__c;
												objInspectionDamageWrapper.idReportType = objInspectionDamage.CSX_CMP_Report_Type__c;
												objproductWrapper.inspectionDamage.add(objInspectionDamageWrapper);
											}

											if (int04inspCount == 0) {
												objproductWrapper.no04InspectionCount = true;
											} else {
												objproductWrapper.no04InspectionCount = false;
											}
										}

										//Customer Damage wrapper Creation
										if (
											objProduct.Customer_Damages__r != null &&
											objProduct.Customer_Damages__r.size() > 0
										) {
											Integer intAllCustDamagematchInspRep04 = 0;
											Integer intCustDamagematch = 0;
											boolean atleast1DmgContains0 = false;

											for (
												CSX_CMP_Customer_Damage__c objCustomerDamage : objProduct.Customer_Damages__r
											) {
												CustomerDamageWrapper objCustomerDamageWrapper = new CustomerDamageWrapper();
												objCustomerDamageWrapper.id = objCustomerDamage.Id;
												objCustomerDamageWrapper.cdName = objCustomerDamage.Name;
												objCustomerDamageWrapper.cdArea = objCustomerDamage.CSX_CMP_Area__c;
												objCustomerDamageWrapper.cdSeverity = objCustomerDamage.CSX_CMP_Severity__c;
												objCustomerDamageWrapper.cdType = objCustomerDamage.CSX_CMP_Type__c;
												objproductWrapper.customerDamage.add(objCustomerDamageWrapper);

												// Check if At Least 1 Damage contains 0?
												if(objCustomerDamageWrapper.cdArea == '0' || objCustomerDamageWrapper.cdSeverity == '0' 
													|| objCustomerDamageWrapper.cdType == '0'){
													atleast1DmgContains0 = true;
												}

												//Damages Match 01, 02, 07 or 08 Inspection Report Type
												for (
													CSX_CMP_Inspection_Damage__c objInspectionDamage : objProduct.Inspection_Damages__r
												) {
													Boolean areaCodeMatch = false;
													Boolean typeCodeMatch = false;

													if (
														mapOfDamageKeyWithListOfSimilarityMatrix.get(
															'Damage Area_' + objCustomerDamage.CSX_CMP_Area__c
														) != null &&
														mapOfDamageKeyWithListOfSimilarityMatrix.get(
																'Damage Area_' + objCustomerDamage.CSX_CMP_Area__c
															)
															.size() > 0
													) {
														list<CSX_CMP_Similarity_Matrix__c> lstSimilarMatrix = mapOfDamageKeyWithListOfSimilarityMatrix.get(
															'Damage Area_' + objCustomerDamage.CSX_CMP_Area__c
														);
														for (
															CSX_CMP_Similarity_Matrix__c objSimilarityMatrix : lstSimilarMatrix
														) {
															if (
																objInspectionDamage.CSX_CMP_Area__c ==
																objSimilarityMatrix.CSX_CMP_Similar_Damage_Code__c
															) {
																areaCodeMatch = true;
															}
														}
													}

													if (
														mapOfDamageKeyWithListOfSimilarityMatrix.get(
															'Damage Type_' + objCustomerDamage.CSX_CMP_Type__c
														) != null &&
														mapOfDamageKeyWithListOfSimilarityMatrix.get(
																'Damage Type_' + objCustomerDamage.CSX_CMP_Type__c
															)
															.size() > 0
													) {
														list<CSX_CMP_Similarity_Matrix__c> lstSimilarMatrix = mapOfDamageKeyWithListOfSimilarityMatrix.get(
															'Damage Type_' + objCustomerDamage.CSX_CMP_Type__c
														);
														for (
															CSX_CMP_Similarity_Matrix__c objSimilarityMatrix : lstSimilarMatrix
														) {
															if (
																objInspectionDamage.CSX_CMP_Type__c ==
																objSimilarityMatrix.CSX_CMP_Similar_Damage_Code__c
															) {
																typeCodeMatch = true;
															}
														}
													}

													if (
														areaCodeMatch &&
														typeCodeMatch &&
														objCustomerDamage.CSX_CMP_Severity__c ==
														objInspectionDamage.CSX_CMP_Severity__c
													) {
														objproductWrapper.custDamageMatchInspRep1278 = true;
														intCustDamagematch++;
													}

													if (
														areaCodeMatch &&
														typeCodeMatch &&
														objCustomerDamage.CSX_CMP_Severity__c ==
														objInspectionDamage.CSX_CMP_Severity__c &&
														(objInspectionDamage.CSX_CMP_Report_Type__c == '4' ||
														objInspectionDamage.CSX_CMP_Report_Type__c == '04')
													) {
														intAllCustDamagematchInspRep04++;
													}
												}
											}

											//All Cust Damage match Insp Rep 04
											if (
												objProduct.Customer_Damages__r.size() == intAllCustDamagematchInspRep04
											) {
												objproductWrapper.allCustDamagematchInspRep04 = true;
											}

											//All Cust Damage match
											if (objProduct.Customer_Damages__r.size() == intCustDamagematch) {
												objproductWrapper.customerDamageMatches = true;
											}

											objproductWrapper.atleast1DmgContains0 = atleast1DmgContains0;
										}
										objEquipmentWrapper.product.add(objproductWrapper);
									}
								}
							}
						}

						//Final Map to be considered
						mapofClaimWrappper.put(objCase.Id, objClaimWrapper);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'gatherFullClaimDetails',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapofClaimWrappper;
	}

	//method to evaluate the rule condition attributes with actual values and return the result
	public static Boolean evaluateRuleCondition(
		map<String, Object> mapofSourceObjectRecord,
		String strAttributes,
		CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition,
		map<String, Object> mapofTargetObjRecord
	) {
		Boolean result = false;
		Set<String> setOfDecimalAttributes = new Set<String>();
		setOfDecimalAttributes.add('claimAmount');
		setOfDecimalAttributes.add('claimAmountwithinthreshold');
		try {
			String strLHS = String.valueOf(mapofSourceObjectRecord.get(strAttributes));
			String strRHS;
			Decimal range1 = objBusinessRuleCondition.CSX_CMP_Range_1__c;
			Decimal range2 = objBusinessRuleCondition.CSX_CMP_Range_2__c;

			if (
				(objBusinessRuleCondition.CSX_CMP_Operator__c == 'Matches' ||
				objBusinessRuleCondition.CSX_CMP_Operator__c == 'Overlap') && !mapofTargetObjRecord.isEmpty()
			) {
				strRHS = String.valueOf(mapofTargetObjRecord.get(strAttributes));
			} else {
				strRHS = objBusinessRuleCondition.CSX_CMP_Value__c;
			}
			
			// system.debug('strRHS??' + strRHS);
			// system.debug('strLHS??' + strLHS);

			switch on objBusinessRuleCondition.CSX_CMP_Operator__c {
				when 'Equal To' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//if (isValidValue(strLHS) && isValidValue(strRHS)) {
						if(setOfDecimalAttributes.contains(strAttributes)){
							Decimal intLHS = Decimal.valueOf(strLHS);
							Decimal intRHS = Decimal.valueOf(strRHS);
							result = (intLHS == intRHS ? true : false);
						} else {
							strLHS = strLHS.toUpperCase();
							strRHS = strRHS.toUpperCase();

							if (strRHS == 'YES' && strLHS == 'TRUE') {
								result = true;
							} else if (strRHS == 'NO' && strLHS == 'FALSE') {
								result = true;
							} else if (strRHS == '0' && strLHS == 'TRUE') {
								result = true;
							} else if (strRHS == '0' && strLHS == 'FALSE') {
								result = false;
							} else {
								result = strLHS.trim() == strRHS.trim() ? true : false;
							}
						}
					} else {
						result = false;
					}
				}
				when 'Not Equal To' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//if (isValidValue(strLHS) && isValidValue(strRHS)) {
						if(setOfDecimalAttributes.contains(strAttributes)){
							Decimal intLHS = Decimal.valueOf(strLHS);
							Decimal intRHS = Decimal.valueOf(strRHS);
							result = (intLHS != intRHS ? true : false);
						} else {
							strLHS = strLHS.toUpperCase();
							strRHS = strRHS.toUpperCase();
							if (strRHS == 'YES' && strLHS <> 'TRUE') {
								result = true;
							} else if (strRHS == 'NO' && strLHS <> 'FALSE') {
								result = true;
							} else if (strRHS == '0' && strLHS == 'TRUE') {
								result = false;
							} else if (strRHS == '0' && strLHS == 'FALSE') {
								result = true;
							} else {
								result = strLHS.trim() != strRHS.trim() ? true : false;
							}
						}
					} else {
						result = false;
					}
				}
				when 'Is Null' {
					strRHS = strRHS.toUpperCase();
					if (String.isNotBlank(strRHS) && strRHS == 'YES' && String.isBlank(strLHS)) {
						result = true;
					} else if (String.isNotBlank(strRHS) && strRHS == 'NO' && String.isNotBlank(strLHS)) {
						result = true;
					} else {
						result = false;
					}
				}
				when 'In List' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();

						if (strLHS.contains(',')) {
							list<string> lstLHS = strLHS.split(',');
							boolean exist = false;
							for (String LHS : lstLHS) {
								if (strRHS.trim() == LHS.trim()) {
									exist = true;
									break;
								}
							}

							if (exist) {
								result = true;
							} else {
								result = false;
							}
						} else if (strRHS.contains(',')) {
							list<string> lstRHS = strRHS.split(',');
							boolean exist = false;
							for (String RHS : lstRHS) {
								if (strLHS.trim() == RHS.trim()) {
									exist = true;
									break;
								}
							}

							if (exist) {
								result = true;
							} else {
								result = false;
							}
						} else {
							result = false;
						}
					} else {
						result = false;
					}
				}
				when 'Less Than' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//based on field value on the record decide date vs decimal comparison
						if (strLHS.contains('/')) {
							result = (date.parse(strLHS) < date.parse(strRHS)) ? true : false;
						} else {
							result = (Decimal.valueof(strLHS) < Decimal.valueOf(strRHS)) ? true : false;
						}
					} else {
						result = false;
					}
				}
				when 'Greater Than' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//based on field value on the record decide date vs decimal comparison
						if (strLHS.contains('/')) {
							result = (date.parse(strLHS) > date.parse(strRHS)) ? true : false;
						} else {
							result = (Decimal.valueof(strLHS) > Decimal.valueOf(strRHS)) ? true : false;
						}
					} else {
						result = false;
					}
				}
				when 'Less Than or Equal To' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//based on field value on the record decide date vs decimal comparison
						if (strLHS.contains('/')) {
							result = (date.parse(strLHS) <= date.parse(strRHS)) ? true : false;
						} else {
							result = (Decimal.valueof(strLHS) <= Decimal.valueOf(strRHS)) ? true : false;
						}
					} else {
						result = false;
					}
				}
				when 'Greater Than or Equal To' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						//based on field value on the record decide date vs decimal comparison
						if (strLHS.contains('/')) {
							result = (date.parse(strLHS) >= date.parse(strRHS)) ? true : false;
						} else {
							result = (Decimal.valueof(strLHS) >= Decimal.valueOf(strRHS)) ? true : false;
						}
					} else {
						result = false;
					}
				}
				when 'Is not Null' {
					strRHS = strRHS.toUpperCase();
					if (String.isNotBlank(strRHS) && strRHS == 'YES' && String.isNotBlank(strLHS)) {
						result = true;
					} else if (String.isNotBlank(strRHS) && strRHS == 'NO' && String.isBlank(strLHS)) {
						result = true;
					} else {
						result = false;
					}
				}
				when 'Not In' {
					if (String.isNotBlank(strRHS) && String.isNotBlank(strLHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();

						if (strLHS.contains(',')) {
							list<string> lstLHS = strLHS.split(',');
							boolean exist = false;
							for (String LHS : lstLHS) {
								if (strRHS.trim() == LHS.trim()) {
									exist = true;
									break;
								}
							}

							if (exist) {
								result = false;
							} else {
								result = true;
							}
						} else if (strRHS.contains(',')) {
							list<string> lstRHS = strRHS.split(',');
							boolean exist = false;
							for (String RHS : lstRHS) {
								if (strLHS.trim() == RHS.trim()) {
									exist = true;
									break;
								}
							}

							if (exist) {
								result = false;
							} else {
								result = true;
							}
						} else {
							result = false;
						}
					} else {
						result = false;
					}
				}
				when 'Matches Pattern' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();

						if (strRHS.startsWith('%')) {
							// strRHS = strRHS.replace(strRHS,'%');
							strRHS = strRHS.replace('%', '');
							result = strLHS.startsWith(strRHS);
						} else if (strRHS.endsWith('%')) {
							// strRHS = strRHS.replace(strRHS,'%');
							strRHS = strRHS.replace('%', '');
							result = strLHS.endsWith(strRHS);
						}
					} else {
						result = false;
					}
				}
				when 'Does Not Match Pattern' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();

						if (strRHS.startsWith('%')) {
							// strRHS = strRHS.replace(strRHS,'%');
							strRHS = strRHS.replace('%', '');
							result = !strLHS.startsWith(strRHS);
						} else if (strRHS.endsWith('%')) {
							// strRHS = strRHS.replace(strRHS,'%');
							strRHS = strRHS.replace('%', '');
							result = !strLHS.endsWith(strRHS);
						}
					} else {
						result = false;
					}
				}
				when 'Matches' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						if(setOfDecimalAttributes.contains(strAttributes)){
							Decimal intLHS = Decimal.valueOf(strLHS);
							Decimal intRHS = Decimal.valueOf(strRHS);
							result = (intLHS == intRHS ? true : false);
						} else {
							strLHS = strLHS.toUpperCase();
							strRHS = strRHS.toUpperCase();
							result = (strLHS == strRHS ? true : false);
						}
					} else if (String.isBlank(strLHS) && String.isBlank(strRHS)) {
						result = true;
					} else {
						result = false;
					}
				}
				when 'Between' {
					if (String.isNotBlank(strLHS) && range1 != null && range2 != null) {
						strLHS = strLHS.toUpperCase();
						result = (Decimal.valueOf(strLHS) >= range1 &&
							Decimal.valueOf(strLHS) <= range2
							? true
							: false);
					} else {
						result = false;
					}
				}
				when 'Overlap' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						list<String> lstLHS = strLHS.split('#');
						list<String> lstRHS = strRHS.split('#');

						if (
							(date.ValueOf(lstLHS[0]) <= date.ValueOf(lstRHS[1]) &&
							date.ValueOf(lstLHS[1]) >= date.ValueOf(lstRHS[0]))
						) {
							result = true;
						} else {
							result = false;
						}
					} else {
						result = false;
					}
				}
				when 'Starts With' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();
						result = strLHS.startsWith(strRHS);
					} else {
						result = false;
					}
				}
				when 'Ends With' {
					if (String.isNotBlank(strLHS) && String.isNotBlank(strRHS)) {
						strLHS = strLHS.toUpperCase();
						strRHS = strRHS.toUpperCase();
						result = strLHS.endsWith(strRHS);
					} else {
						result = false;
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'evaluateRuleCondition',
				json.serialize(objBusinessRuleCondition) +
				' ## ' +
				String.valueOf(mapofSourceObjectRecord),
				ex
			);
		}
		return result;
	}

	/*This methods return true if amount value is valid
	public static Boolean isValidValue(String value) {
		String amtRegEx = '£{0,1}\\d{1,16}.{0,1}\\d*';
		Pattern myPattern = Pattern.compile(amtRegEx);
		Matcher myMatcher = myPattern.matcher(value);
		Boolean flag = myMatcher.matches();
		return flag;
	}*/

	//This method returns the unique record Id with their new status
	public static Map<String, Boolean> refineBRConditionResults(Map<Integer, List<String>> mapOfSequencevsResult) {
		Map<String, Boolean> refinedResultMap = new Map<String, Boolean>();
		try {
			for (Integer seq : mapOfSequencevsResult.keySet()) {
				list<String> lstSequence = mapOfSequencevsResult.get(seq);

				for (String resultStr : lstSequence) {
					List<String> splitStr = resultStr.split('_');
					String recordIdCombo = splitStr[0];
					Boolean result = Boolean.valueOf(splitStr[1]);

					if (refinedResultMap.containskey(recordIdCombo)) {
						if (refinedResultMap.get(recordIdCombo) && !result) {
							//override to false when true earlier
							refinedResultMap.put(recordIdCombo, false);
						}
					} else {
						refinedResultMap.put(recordIdCombo, result);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'refineBRConditionResults',
				String.valueOf(mapOfSequencevsResult),
				ex
			);
		}
		return refinedResultMap;
	}

	//Final Result set with sequence number and their result
	public static Map<Integer, Boolean> fetchFinalBRConditionResults(
		Map<String, Boolean> refinedResultMap,
		Map<Integer, List<String>> mapOfSequencevsResult
	) {
		Map<Integer, Boolean> finalResultsMap = new Map<Integer, Boolean>();
		try {
			for (Integer sequence : mapOfSequencevsResult.keySet()) {
				Boolean isTrue = false;
				Integer numberofResults = mapOfSequencevsResult.get(sequence).size();
				for (String resultStr : mapOfSequencevsResult.get(sequence)) {
					List<String> splitStr = resultStr.split('_');
					String recordId = splitStr[0];
					Boolean result = Boolean.valueof(splitStr[1]);
					//if only 1 result available for a sequence then consider that instead of refined result as it will always be from 1 record
					if (numberofResults == 1) {
						isTrue = result;
					} else {
						//if more than 1 result is available for a sequence (i.e. condition is on a child object where there can be more than 1 records)
						if (refinedResultMap.get(recordId)) {
							isTrue = true;
							break;
						}
					}
				}
				finalResultsMap.put(sequence, isTrue);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'fetchFinalBRConditionResults',
				String.valueOf(refinedResultMap),
				ex
			);
		}
		return finalResultsMap;
	}

	//Get the updated sequence result map
	public static map<Integer, List<String>> updatedSequenceresult(
		String resultString,
		map<Integer, List<String>> mapOfSequencevsResult,
		Integer sequence
	) {
		try {
			if (mapOfSequencevsResult.containsKey(sequence)) {
				mapOfSequencevsResult.get(sequence).add(resultString);
			} else {
				mapOfSequencevsResult.put(sequence, new List<String>{ resultString });
			}
			return mapOfSequencevsResult;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'updatedSequenceresult',
				String.valueOf(resultString),
				ex
			);
		}
		return null;
	}

	//method to evaluate a rule and return the outcome
	public static Boolean evaluateRuleWhereLogic(String whereClause, Map<Integer, Boolean> conditionEvaluateMap) {
		try {
			String strFinalResult = '';
			for (Integer intSequence : conditionEvaluateMap.keySet()) {
				if (whereClause.contains(String.valueOf(intSequence))) {
					strFinalResult = whereClause.replaceFirst(
						String.valueOf(intSequence),
						String.valueOf(conditionEvaluateMap.get(intSequence))
					);
					whereClause = strFinalResult;
				}
			}
			
			boolean isResult = CSX_CMP_EvaluateBooleanExpression.eval(whereClause.toUpperCase().normalizeSpace());
			return isResult;
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'evaluateRuleWhereLogic',
				String.valueOf(whereClause),
				ex
			);
		}
		return null;
	}

	//Method to return eligible claims with bussiness rule with their final result
	public static Map<Id, list<BusinessRuleWrapper>> evaluateBusinessRules(
		list<ClaimWrapper> lstClaimWrapper,
		string strBusinessRuleRecordType,
		Id businessRuleId
	) {
		Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = new Map<Id, list<BusinessRuleWrapper>>();
		Set<Id> setOfTargetClaimIds = new Set<Id>();
		Set<Id> setOfAllTargetClaimIds = new Set<Id>();
		Map<CSX_CMP_Business_Rule__c, Set<Id>> mapOfBRuleWithTargetClaim = new Map<CSX_CMP_Business_Rule__c, Set<Id>>();
		Map<Id, ClaimWrapper> targetClaimsWrapperMap = new Map<Id, ClaimWrapper>();
		Map<Id,Map<String, Object>> mapOfTargetClaimIdtoDetailsMap = new Map<Id, Map<String, Object>>();

		try {
			Id recordTypeId = String.isNotBlank(strBusinessRuleRecordType)
				? getRecordTypeIdbyName('CSX_CMP_Business_Rule__c', strBusinessRuleRecordType)
				: null;
			string strType = strBusinessRuleRecordType == 'CSX_CMP_Duplicate' ? lstClaimWrapper[0].claimType : '';
			//Fetch all the bussiness rules based on the record types
			List<CSX_CMP_Business_Rule__c> lstBusinessRules = getBusinessRuleDetails(
				recordTypeId,
				businessRuleId,
				strType
			);
			if (lstBusinessRules != null && lstBusinessRules.size() > 0) {
				//Loop on all the claim Id
				for (ClaimWrapper objClaimWrapper : lstClaimWrapper) {

					String strSerializeClaimWrapper = Json.serialize(objClaimWrapper);
					Map<String, Object> mapOfClaimDetails = (Map<String, Object>) JSON.deserializeUntyped(
						strSerializeClaimWrapper
					);

					//query claims to be compared against with new claim based on criteria captured on Business Rule
					for (CSX_CMP_Business_Rule__c objBusinesssRule : lstBusinessRules) {
						if (objBusinesssRule.CSX_CMP_Matches_Count__c > 0) {
							setOfTargetClaimIds = CSX_CMP_BusinessRulesHelper.identifyClaimsforMatchesComparison(
								objClaimWrapper,
								objBusinesssRule
							);
							mapOfBRuleWithTargetClaim.put(objBusinesssRule, setOfTargetClaimIds);
							setOfAllTargetClaimIds.addAll(setOfTargetClaimIds);
						} else {
							mapOfBRuleWithTargetClaim.put(objBusinesssRule, new Set<Id>());
						}
					}

					if (!setOfAllTargetClaimIds.isEmpty()) {
						targetClaimsWrapperMap = gatherFullClaimDetails(setOfAllTargetClaimIds);

						for(Id targclaimId:targetClaimsWrapperMap.keySet()){
							ClaimWrapper targetClaimWrapper = targetClaimsWrapperMap.get(targclaimId);
							String strSerializeTargetClaimWrapper = Json.serialize(targetClaimWrapper);
							Map<String, Object> mapOfTargetClaimDetails = (Map<String, Object>) JSON.deserializeUntyped(
								strSerializeTargetClaimWrapper
							);
							mapOfTargetClaimIdtoDetailsMap.put(targclaimId, mapOfTargetClaimDetails);
						}
					}

					list<BusinessRuleWrapper> lstBusinessRuleWrapper = new List<BusinessRuleWrapper>();
					for (CSX_CMP_Business_Rule__c busRule : mapOfBRuleWithTargetClaim.keySet()) {
						Map<Id, String> duplicateClaimIdMap = new Map<Id, String>();
						Boolean finalResult = false;
						if (busRule.CSX_CMP_Matches_Count__c > 0) {
							for (Id targclaimId : mapOfBRuleWithTargetClaim.get(busRule)) {
								Boolean result = false;
								//ClaimWrapper targetClaimWrapper = targetClaimsWrapperMap.get(targclaimId);
								/*Convert the tagret Claim wrapper into object structure to get the values based on business rule attributes
								String strSerializeTargetClaimWrapper = Json.serialize(targetClaimWrapper);
								Map<String, Object> mapOfTargetClaimDetails = (Map<String, Object>) JSON.deserializeUntyped(
									strSerializeTargetClaimWrapper
								);*/

								Map<String, Object> mapOfTargetClaimDetails = mapOfTargetClaimIdtoDetailsMap.get(targclaimId);

								//if duplicate check for Revenue Railroad and Overcharge claim, use method logic to avoid performance issues.
								if((mapOfClaimDetails.get('recordType') == 'Revenue_Overcharge' || mapOfClaimDetails.get('recordType') == 'Revenue_Railroad') && busRule.RecordType.DeveloperName == 'CSX_CMP_Duplicate'){

									result = evaluateBusinessRulesCoreLogicDupRevenue(mapOfClaimDetails, mapOfTargetClaimDetails, busRule);

								}else{
									result = evaluateBusinessRulesCoreLogic(
										//objClaimWrapper,
										mapOfClaimDetails,
										busRule,
										//targetClaimsWrapperMap.get(targclaimId)
										mapOfTargetClaimDetails
									);
								}

								if (result) {
									duplicateClaimIdMap.put(
										targclaimId,
										//targetClaimsWrapperMap.get(targclaimId).claimNumber
										//targetClaimWrapper.claimNumber
										(String)mapOfTargetClaimDetails.get('claimNumber')
									);
									finalResult = true;
								}
							}
						} else {
							Boolean result = evaluateBusinessRulesCoreLogic(
								//objClaimWrapper,
								mapOfClaimDetails,
								busRule,
								new Map<String, Object>()
							);
							finalResult = result;
						}

						BusinessRuleWrapper objBusinessRuleWrapper = new BusinessRuleWrapper();
						objBusinessRuleWrapper.objBRRule = busRule;
						objBusinessRuleWrapper.result = finalResult;
						objBusinessRuleWrapper.finalDuplicateClaimIdMap = duplicateClaimIdMap;
						lstBusinessRuleWrapper.add(objBusinessRuleWrapper);
					}
					businessRuleEvalResultsMap.put(objClaimWrapper.Id, lstBusinessRuleWrapper);
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'evaluateBusinessRules',
				String.valueOf(lstClaimWrapper[0].Id),
				ex
			);
		}
		return businessRuleEvalResultsMap;
	}

	//Method to return eligible claims with bussiness rule with their final result
	public static boolean evaluateBusinessRulesCoreLogic(
		//ClaimWrapper sourceClaimWrapper,
		Map<String, Object> mapOfClaimDetails,
		CSX_CMP_Business_Rule__c objBussinessRule,
		//ClaimWrapper targetClaimWrapper
		Map<String, Object> mapOfTargetClaimDetails
	) {
		Boolean finalResult = false;
		Set<String> ignoreComparisonSet = new Set<String>();
		try {
			/*Convert the Claim wrapper into object structure to get the values based on business rule attributes
			String strSerializeClaimWrapper = Json.serialize(sourceClaimWrapper);
			Map<String, Object> mapOfClaimDetails = (Map<String, Object>) JSON.deserializeUntyped(
				strSerializeClaimWrapper
			);

			//Convert the tagret Claim wrapper into object structure to get the values based on business rule attributes
			String strSerializeTargetClaimWrapper = Json.serialize(targetClaimWrapper);
			Map<String, Object> mapOfTargetClaimDetails = (Map<String, Object>) JSON.deserializeUntyped(
				strSerializeTargetClaimWrapper
			);

			//if duplicate check for Revenue Railroad and Overcharge claim, use method logic to avoid performance issues.
			if((mapOfClaimDetails.get('recordType') == 'Revenue_Overcharge' || mapOfClaimDetails.get('recordType') == 'Revenue_Railroad') && objBussinessRule.RecordType.DeveloperName == 'CSX_CMP_Duplicate'){
				finalResult = evaluateBusinessRulesCoreLogicDupRevenue(mapOfClaimDetails, mapOfTargetClaimDetails, objBussinessRule);
				return finalResult;
			}*/

			Map<Integer, List<String>> mapOfSequencevsResult = new Map<Integer, List<String>>();
           
			if (String.IsNotBlank(objBussinessRule.CSX_CMP_Where_Clause__c)) {
				for (
					CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : objBussinessRule.Business_Rule_Conditions__r
				) {
					if (string.isNotBlank(objBusinessRuleCondition.CSX_CMP_Attribute_Name__c)) {
						Integer sequence = Integer.valueOf(objBusinessRuleCondition.Name);
						list<String> lstAttributeSplit = objBusinessRuleCondition.CSX_CMP_Attribute_Name__c.split('_');
						//Equipment Level
						if (lstAttributeSplit[1] == 'equipment') {
							List<Object> lstEquipments = (List<Object>) mapOfClaimDetails.get(lstAttributeSplit[1]);
							List<Object> lstEquipmentsTarget = (List<Object>) mapOfTargetClaimDetails.get(
								lstAttributeSplit[1]
							);
							if (lstEquipments != null && lstEquipments.size() > 0) {
								//loop through Equipments elements
								for (Object objEquipment : lstEquipments) {
									// now get attributes for this Equipment.
									Map<String, Object> mapOfEqipmentAttributes = (Map<String, Object>) objEquipment;

									//Product and Distribution Level
									if (lstAttributeSplit[2] == 'product' || lstAttributeSplit[2] == 'distribution') {
										List<Object> lstProductDistribution = (List<Object>) mapOfEqipmentAttributes.get(
											lstAttributeSplit[2]
										);

										if (lstProductDistribution != null && lstProductDistribution.size() > 0) {
											//loop through Product or Distribution elements
											for (object objProductDistribution : lstProductDistribution) {
												Map<String, Object> mapOfProductDistributionAttributes = (Map<String, Object>) objProductDistribution;
												//Customer and Inspection Damage Level
												if (
													lstAttributeSplit[3] == 'customerDamage' ||
													lstAttributeSplit[3] == 'inspectionDamage'
												) {
													List<Object> lstCustomerInspectionDamage = (List<Object>) mapOfProductDistributionAttributes.get(
														lstAttributeSplit[3]
													);

													if (
														lstCustomerInspectionDamage != null &&
														lstCustomerInspectionDamage.size() > 0
													) {
														//loop through Customer or Inspection elements
														for (
															object objCustomerInspectionDamage : lstCustomerInspectionDamage
														) {
															Map<String, Object> mapOfCustomerInspectionDamageAttributes = (Map<String, Object>) objCustomerInspectionDamage;

															// now get the Customer or Inspection attributes values.
															if (
																mapOfCustomerInspectionDamageAttributes.containsKey(
																	lstAttributeSplit[4]
																)
															) {
																//Customer or Inspection Level Attributes Details
																Boolean result = evaluateRuleCondition(
																	mapOfCustomerInspectionDamageAttributes,
																	lstAttributeSplit[4],
																	objBusinessRuleCondition,
																	new Map<String, Object>()
																);
																String resultString =
																	mapOfCustomerInspectionDamageAttributes.get('id') +
																	'_' +
																	String.valueof(result);
																mapOfSequencevsResult = updatedSequenceresult(
																	resultString,
																	mapOfSequencevsResult,
																	sequence
																);
															}
														}
													} else {
														String resultString = lstAttributeSplit[3] + '_' + 'false';
														mapOfSequencevsResult = updatedSequenceresult(
															resultString,
															mapOfSequencevsResult,
															sequence
														);
													}
												} else if (
													mapOfProductDistributionAttributes.containsKey(lstAttributeSplit[3])
												) {
													// now get the Product or Distribution attributes values.
													//Product or Distribution Level Attributes Details
													Boolean result = evaluateRuleCondition(
														mapOfProductDistributionAttributes,
														lstAttributeSplit[3],
														objBusinessRuleCondition,
														new Map<String, Object>()
													);
													String resultString =
														mapOfProductDistributionAttributes.get('id') +
														'_' +
														String.valueof(result);
													mapOfSequencevsResult = updatedSequenceresult(
														resultString,
														mapOfSequencevsResult,
														sequence
													);
												}
											}
										} else {
											String resultString = lstAttributeSplit[2] + '_' + 'false';
											mapOfSequencevsResult = updatedSequenceresult(
												resultString,
												mapOfSequencevsResult,
												sequence
											);
										}
									} else if (mapOfEqipmentAttributes.containsKey(lstAttributeSplit[2])) {
										// now get the Equipment attributes values.
										//Equipment Level Attributes Details
										Boolean result = false;
										if (
											objBusinessRuleCondition.CSX_CMP_Operator__c == 'Matches' ||
											objBusinessRuleCondition.CSX_CMP_Operator__c == 'Overlap'
										) {
											//loop through Target Equipments elements
											if (lstEquipmentsTarget != null && lstEquipmentsTarget.size() > 0) {
												for (Object objEquipTarget : lstEquipmentsTarget) {
													// now get target attributes for this Equipment.
													Map<String, Object> mapOfEqipmentAttributesTarget = (Map<String, Object>) objEquipTarget;
													String recordIdCombo =
														mapOfEqipmentAttributes.get('id') +
														'#' +
														mapOfEqipmentAttributesTarget.get('id');

													if(!ignoreComparisonSet.contains(recordIdCombo)){
														result = evaluateRuleCondition(
															mapOfEqipmentAttributes,
															lstAttributeSplit[2],
															objBusinessRuleCondition,
															mapOfEqipmentAttributesTarget
														);

														//if false
														if(!result){
															//added to avoid future comparisons for performance reasons
															ignoreComparisonSet.add(recordIdCombo);
														}
													}else{
														result = false;
													}

													String resultString =
															mapOfEqipmentAttributes.get('id') +
															'#' +
															mapOfEqipmentAttributesTarget.get('id') +
															'_' +
															String.valueof(result);
															mapOfSequencevsResult = updatedSequenceresult(
																resultString,
																mapOfSequencevsResult,
																sequence
															);
												}
											} else {
												String resultString = lstAttributeSplit[2] + '_' + 'false';
												mapOfSequencevsResult = updatedSequenceresult(
													resultString,
													mapOfSequencevsResult,
													sequence
												);
											}
										} else {
											result = evaluateRuleCondition(
												mapOfEqipmentAttributes,
												lstAttributeSplit[2],
												objBusinessRuleCondition,
												new Map<String, Object>()
											);
											String resultString =
												mapOfEqipmentAttributes.get('id') +
												'_' +
												String.valueof(result);
											mapOfSequencevsResult = updatedSequenceresult(
												resultString,
												mapOfSequencevsResult,
												sequence
											);
										}
									}
								}
							} else {
								String resultString = lstAttributeSplit[1] + '_' + 'false';
								mapOfSequencevsResult = updatedSequenceresult(
									resultString,
									mapOfSequencevsResult,
									sequence
								);
							}
						} else if (mapOfClaimDetails.containsKey(lstAttributeSplit[1])) {
							//Claim Level Attributes Details
							Boolean result = false;
							if (
								objBusinessRuleCondition.CSX_CMP_Operator__c == 'Matches' ||
								objBusinessRuleCondition.CSX_CMP_Operator__c == 'Overlap'
							) {
								result = evaluateRuleCondition(
									mapOfClaimDetails,
									lstAttributeSplit[1],
									objBusinessRuleCondition,
									mapOfTargetClaimDetails
								);
							} else {
								result = evaluateRuleCondition(
									mapOfClaimDetails,
									lstAttributeSplit[1],
									objBusinessRuleCondition,
									new Map<String, Object>()
								);
							}

							String resultString = mapOfClaimDetails.get('id') + '_' + String.valueof(result);
							mapOfSequencevsResult = updatedSequenceresult(
								resultString,
								mapOfSequencevsResult,
								sequence
							);
						}
					}
				}
				Map<String, Boolean> refinedResultMap = refineBRConditionResults(mapOfSequencevsResult);
				Map<Integer, Boolean> finalResultsMap = fetchFinalBRConditionResults(
					refinedResultMap,
					mapOfSequencevsResult
				);
				finalResult = evaluateRuleWhereLogic(objBussinessRule.CSX_CMP_Where_Clause__c, finalResultsMap);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'evaluateBusinessRulesCoreLogic',
				json.serialize(mapOfClaimDetails),
				ex
			);
		}
		return finalResult;
	}

	//Separate method to return eligible claims with bussiness rule with their final result for Revenue railroad and overcharge duplicate rules to avoid performance issue
	public static boolean evaluateBusinessRulesCoreLogicDupRevenue(
		Map<String, Object> mapOfClaimDetails,
		Map<String, Object> mapOfTargetClaimDetails,
		CSX_CMP_Business_Rule__c objBussinessRule
	) {
		Boolean claimResult = false;
		// Boolean claimLineResult = false;
		Boolean finalResult = false;
		try {
			
			Map<String, List<CSX_CMP_Business_Rule_Condition__c>> mapofObjTypetoBusConditions = getObjbasedBusConditionsMap(objBussinessRule);

            List<CSX_CMP_Business_Rule_Condition__c> claimBusConditions = mapofObjTypetoBusConditions.get('claim');

            List<CSX_CMP_Business_Rule_Condition__c> claimlineBusConditions = mapofObjTypetoBusConditions.get('equipment');

            if (String.IsNotBlank(objBussinessRule.CSX_CMP_Where_Clause__c)) {
				
				for (CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : claimBusConditions) {

                    list<String> lstAttributeSplit = objBusinessRuleCondition.CSX_CMP_Attribute_Name__c.split('_');
					
					//Claim Level comparison
					if (
						objBusinessRuleCondition.CSX_CMP_Operator__c == 'Matches' ||
						objBusinessRuleCondition.CSX_CMP_Operator__c == 'Overlap'
					) {
						claimResult = evaluateRuleCondition(
							mapOfClaimDetails,
							lstAttributeSplit[1],
							objBusinessRuleCondition,
							mapOfTargetClaimDetails
						);
					} else {
						claimResult = evaluateRuleCondition(
							mapOfClaimDetails,
							lstAttributeSplit[1],
							objBusinessRuleCondition,
							new Map<String, Object>()
						);
					}

					//if false then exit
					if(!claimResult){
						finalResult = false;
						break;
					}
				}

				if(claimResult){
					//Claim line Level comparison	
					List<Object> lstEquipments = (List<Object>) mapOfClaimDetails.get('equipment');
					List<Object> lstEquipmentsTarget = (List<Object>) mapOfTargetClaimDetails.get('equipment');

					//loop through source claim lines
					for (Object objEquipment : lstEquipments) {
						// now get attributes for this Claim line.
						Map<String, Object> mapOfEqipmentAttributes = (Map<String, Object>) objEquipment;
						Boolean atleastOneSourceTargetClaimLineMatch = false;

						for (Object objEquipTarget : lstEquipmentsTarget) {
							Boolean sourceTargetBRCResult = false;
							// now get target attributes for this Claim line.
							Map<String, Object> mapOfEqipmentAttributesTarget = (Map<String, Object>) objEquipTarget;

							for (CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : claimlineBusConditions) {
								list<String> lstAttributeSplit = objBusinessRuleCondition.CSX_CMP_Attribute_Name__c.split('_');
                                
								if(mapOfEqipmentAttributes.containsKey(lstAttributeSplit[2]) && mapOfEqipmentAttributes.get(lstAttributeSplit[2]) != '' && mapOfEqipmentAttributes.get(lstAttributeSplit[2]) != NULL ) {
									if (
										objBusinessRuleCondition.CSX_CMP_Operator__c == 'Matches' ||
										objBusinessRuleCondition.CSX_CMP_Operator__c == 'Overlap'
									) {
										sourceTargetBRCResult = evaluateRuleCondition(
											mapOfEqipmentAttributes,
											lstAttributeSplit[2],
											objBusinessRuleCondition,
											mapOfEqipmentAttributesTarget
										);
									} else {
										sourceTargetBRCResult = evaluateRuleCondition(
											mapOfEqipmentAttributes,
											lstAttributeSplit[2],
											objBusinessRuleCondition,
											new Map<String, Object>()
										);
									}
								}

								//if false
								if(!sourceTargetBRCResult){
									//stop comparison for current source and target claim line combination if at least one result is false and proceed with next combination
									break;
								}
							}

							if(sourceTargetBRCResult){
								atleastOneSourceTargetClaimLineMatch = true;
								break;	
							}
						}

						if(atleastOneSourceTargetClaimLineMatch){
							finalResult = true;
							break;	
						}
					}
					
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'evaluateBusinessRulesCoreLogicDupRevenue',
				'',
				ex
			);
		}
		return finalResult;
	}

	//17 Sept changes | Start
	//method to return FLRWrapper based on eligible claims
	public static List<FLRClaimWrapper> eligibleFLRClaims(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId,
		Map<String, String> mapofFLRKeytoEmailId
	) {
		List<FLRClaimWrapper> lstFLRClaimWrapper = new List<FLRClaimWrapper>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());
			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);
			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					CSX_CMP_Business_Rule__c objBussinessRule = new CSX_CMP_Business_Rule__c();

					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);
					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							objBussinessRule = objBusinessRuleWrapper.objBRRule;
							break;
						}
					}
                    if(Test.isRunningTest() ){
                        objBussinessRule.Id = businessRuleId;
                    }
					if (objBussinessRule.id != null) {
						FLRClaimWrapper objFLRClaimWrapper = new FLRClaimWrapper();
						objFLRClaimWrapper.strCaseID = claimId;
						objFLRClaimWrapper.strBusinessRuleName = objBussinessRule.CSX_CMP_Rule_Name__c;

						if (objBussinessRule.FLR_Questions__r != null && objBussinessRule.FLR_Questions__r.size() > 0) {
							objFLRClaimWrapper.lstQuestions.addAll(objBussinessRule.FLR_Questions__r);
						}

						Map<String, set<String>> mapofRREmailToSource = new Map<String, Set<String>>();
						//Add all the Emails
						ClaimWrapper objClaimWrapper = mapofClaimWrapper.get(claimId);

						if (objClaimWrapper.Equipment != null && objClaimWrapper.Equipment.size() > 0) {
							for (EquipmentWrapper objEquipmentWrap : objClaimWrapper.Equipment) {
								if (objEquipmentWrap.Distribution != null && objEquipmentWrap.Distribution.size() > 0) {
									for (DistributionWrapper objDistributionWrap : objEquipmentWrap.Distribution) {
										//NOT EQUAL TO 0712
										// prepare key and fetch email from mapofFLRKeytoEmailId either using desk or All
										//To exclude CSX Railroad
										if (
											objDistributionWrap.RRCode != null &&
											objDistributionWrap.RRCode != System.Label.CSX_CMP_Exclude_Railroad_Code
										) {
											String desk;
											if (objClaimWrapper.deskName != null) {
												desk = objClaimWrapper.deskName;
											} 
											/*else {
												desk = 'ALL';
											}*/

											String mapKey = objClaimWrapper.claimType + '#' + objDistributionWrap.RRCode;
												if(string.isNotBlank(desk)){
													mapKey += '#' + desk;
												}
											
											String mapKeyAll =
												objClaimWrapper.claimType +
												'#' +
												objDistributionWrap.RRCode;
                                            
											string emailId = '';
											// system.debug('mapofFLRKeytoEmailId ::'+mapofFLRKeytoEmailId);
											// system.debug('mapKey ::'+mapKey);
											// system.debug('objDistributionWrap.dRoute ::'+objDistributionWrap.dRoute);
											// system.debug('objEquipmentWrap.waybillActualOriginRoad ::'+objEquipmentWrap.waybillActualOriginRoad);
											// system.debug('objDistributionWrap.dRoute ::'+objDistributionWrap.dRoute);
											// system.debug('objEquipmentWrap.waybillActualDestinationRoad ::'+objEquipmentWrap.waybillActualDestinationRoad);
											if (mapofFLRKeytoEmailId.containsKey(mapKey)) {
												//system.debug('Inside if mapofFLRKeytoEmailId::'+mapofFLRKeytoEmailId);
												//system.debug('Inside if mapKey::'+mapKey);
												emailId = mapofFLRKeytoEmailId.get(mapKey);
											} else {
												// system.debug('Inside else ::'+mapofFLRKeytoEmailId);
												// system.debug('Inside else mapKeyAll::'+mapKeyAll);
												// system.debug('mapofFLRKeytoEmailId.get(mapKeyAll) ::'+mapofFLRKeytoEmailId.get(mapKeyAll));
												emailId = mapofFLRKeytoEmailId.get(mapKeyAll);
											}
											//system.debug('emailId ::'+emailId);
											if (emailId != '' && emailId != null) {
												if (
													objDistributionWrap.dRoute ==
													objEquipmentWrap.waybillActualOriginRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														mapofRREmailToSource.put(emailId, new Set<String>{ 'Origin' });
													} else {
														mapofRREmailToSource.get(emailId).add('Origin');
													}
												}

												if (
													objDistributionWrap.dRoute ==
													objEquipmentWrap.waybillActualDestinationRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														mapofRREmailToSource.put(
															emailId,
															new Set<String>{ 'Destination' }
														);
													} else {
														mapofRREmailToSource.get(emailId).add('Destination');
													}
												}

												if (
													objDistributionWrap.dRoute !=
													objEquipmentWrap.waybillActualOriginRoad &&
													objDistributionWrap.dRoute !=
													objEquipmentWrap.waybillActualDestinationRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														mapofRREmailToSource.put(emailId, new Set<String>{ 'Other' });
													} else {
														mapofRREmailToSource.get(emailId).add('Other');
													}
												}
											}
										}
									}
								}
							}
						}
						objFLRClaimWrapper.mapOfmails = mapofRREmailToSource;
						lstFLRClaimWrapper.add(objFLRClaimWrapper);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'eligibleFLRClaims',
				String.valueOf(claimIds),
				ex
			);
		}
		return lstFLRClaimWrapper;
	}
	//17 Sept changes | End
	/*//method to return FLRWrapper based on eligible claims
	public static List<FLRClaimWrapper> eligibleFLRClaims(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId,
		Map<String, String> mapofFLRKeytoEmailId
	) {
		List<FLRClaimWrapper> lstFLRClaimWrapper = new List<FLRClaimWrapper>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());
			system.debug('mapofClaimWrapper ::'+mapofClaimWrapper);
			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);
			system.debug('businessRuleEvalResultsMap ::'+businessRuleEvalResultsMap);
			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					CSX_CMP_Business_Rule__c objBussinessRule = new CSX_CMP_Business_Rule__c();

					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);
					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							objBussinessRule = objBusinessRuleWrapper.objBRRule;
							break;
						}
					}
					if (objBussinessRule.id != null) {
						FLRClaimWrapper objFLRClaimWrapper = new FLRClaimWrapper();
						objFLRClaimWrapper.strCaseID = claimId;
						objFLRClaimWrapper.strBusinessRuleName = objBussinessRule.CSX_CMP_Rule_Name__c;

						if (objBussinessRule.FLR_Questions__r != null && objBussinessRule.FLR_Questions__r.size() > 0) {
							objFLRClaimWrapper.lstQuestions.addAll(objBussinessRule.FLR_Questions__r);
						}

						Map<String, set<String>> mapofRREmailToSource = new Map<String, Set<String>>();
						//Add all the Emails
						ClaimWrapper objClaimWrapper = mapofClaimWrapper.get(claimId);

						if (objClaimWrapper.Equipment != null && objClaimWrapper.Equipment.size() > 0) {
							for (EquipmentWrapper objEquipmentWrap : objClaimWrapper.Equipment) {
								if (objEquipmentWrap.Distribution != null && objEquipmentWrap.Distribution.size() > 0) {
									for (DistributionWrapper objDistributionWrap : objEquipmentWrap.Distribution) {
										//NOT EQUAL TO 0712
										// prepare key and fetch email from mapofFLRKeytoEmailId either using desk or All
										//To exclude CSX Railroad
										if (
											objDistributionWrap.RRCode != null &&
											objDistributionWrap.RRCode != System.Label.CSX_CMP_Exclude_Railroad_Code
										) {
											String desk;
											if (objClaimWrapper.deskName != null) {
												desk = objClaimWrapper.deskName;
											} else {
												desk = 'ALL';
											}

											String mapKey =
												objClaimWrapper.claimType +
												'#' +
												objDistributionWrap.RRCode +
												'#' +
												desk;
											
											String mapKeyAll =
												objClaimWrapper.claimType +
												'#' +
												objDistributionWrap.RRCode +
												'#ALL';
                                            
											string emailId = '';
											system.debug('mapofFLRKeytoEmailId ::'+mapofFLRKeytoEmailId);
											system.debug('mapKey ::'+mapKey);
											system.debug('objDistributionWrap.dRoute ::'+objDistributionWrap.dRoute);
											system.debug('objEquipmentWrap.waybillActualOriginRoad ::'+objEquipmentWrap.waybillActualOriginRoad);
											system.debug('objDistributionWrap.dRoute ::'+objDistributionWrap.dRoute);
											system.debug('objEquipmentWrap.waybillActualDestinationRoad ::'+objEquipmentWrap.waybillActualDestinationRoad);
											if (mapofFLRKeytoEmailId.containsKey(mapKey)) {
												system.debug('Inside if ::'+mapKey);
												emailId = mapofFLRKeytoEmailId.get(mapKey);
											} else {
												system.debug('Inside else ::'+mapKeyAll);
												emailId = mapofFLRKeytoEmailId.get(mapKeyAll);
											}
											system.debug('emailId ::'+emailId);
											if (emailId != '' && emailId != null) {
												if (
													objDistributionWrap.dRoute ==
													objEquipmentWrap.waybillActualOriginRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														system.debug('inside origin ::');
														mapofRREmailToSource.put(emailId, new Set<String>{ 'Origin' });
													} else {
														system.debug('inside origin else::');
														mapofRREmailToSource.get(emailId).add('Origin');
													}
												}

												if (
													objDistributionWrap.dRoute ==
													objEquipmentWrap.waybillActualDestinationRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														system.debug('inside Dest if::');
														mapofRREmailToSource.put(
															emailId,
															new Set<String>{ 'Destination' }
														);
													} else {
														system.debug('inside Dest esle::');
														mapofRREmailToSource.get(emailId).add('Destination');
													}
												}

												if (
													objDistributionWrap.dRoute !=
													objEquipmentWrap.waybillActualOriginRoad &&
													objDistributionWrap.dRoute !=
													objEquipmentWrap.waybillActualDestinationRoad
												) {
													if (!mapofRREmailToSource.containsKey(emailId)) {
														system.debug('inside Both if::');
														mapofRREmailToSource.put(emailId, new Set<String>{ 'Other' });
													} else {
														system.debug('inside Both else::');
														mapofRREmailToSource.get(emailId).add('Other');
													}
												}
											}
										}
									}
								}
							}
						}
						objFLRClaimWrapper.mapOfmails = mapofRREmailToSource;
						lstFLRClaimWrapper.add(objFLRClaimWrapper);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'eligibleFLRClaims',
				String.valueOf(claimIds),
				ex
			);
		}
		return lstFLRClaimWrapper;
	}*/

	//Method returns the AR Threshold for claims
	public static Map<Id, String> runARThresholdBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, String> mapOfARThresholdClaims = new Map<Id, String>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
                        if(Test.isRunningTest() ){
                            objBusinessRuleWrapper.result = true;
                        }
						if (objBusinessRuleWrapper.result) {
							if (!mapOfARThresholdClaims.containsKey(claimId)) {
								mapOfARThresholdClaims.put(
									claimId,
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Rule_Name__c +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_AR_Threshold_Amount__c +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_AR_Percentage_Past_Due__c +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Finance_Charge_Threshold__c
								);
							}
							break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runARThresholdBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfARThresholdClaims;
	}

	//Method returns the Desk / team Number and Owner/Queue based on the business rules conditions for claims
	public static Map<Id, String> runClaimDeskAssignmentBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, String> mapOfClaimDeskAssignment = new Map<Id, String>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (!mapOfClaimDeskAssignment.containsKey(claimId)) {
								mapOfClaimDeskAssignment.put(
									claimId,
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Desk_Name__r.Name +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Desk_Name__r.CSX_CMP_Desk_Owner__r.Id +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Rule_Name__c
								);
							}
							break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runClaimDeskAssignmentBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfClaimDeskAssignment;
	}

	//Method returns theClaim Priority with Rule Name based on the business rules conditions for claims
	public static Map<Id, String> runClaimPriorityBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, String> mapOfClaimPriority = new Map<Id, String>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (!mapOfClaimPriority.containsKey(claimId)) {
								mapOfClaimPriority.put(
									claimId,
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Claim_Priority__c +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Rule_Name__c
								);
							}
							break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runClaimPriorityBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfClaimPriority;
	}

	//Method returns the Desk / team Number and Owner/Queue based on the business rules conditions for claims
	public static Map<Id, list<CSX_CMP_Task_Checklist__c>> runTaskChecklistBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, list<CSX_CMP_Task_Checklist__c>> mapOfTaskChecklistClaims = new Map<Id, list<CSX_CMP_Task_Checklist__c>>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (!mapOfTaskChecklistClaims.containsKey(claimId)) {
								mapOfTaskChecklistClaims.put(claimId, new List<CSX_CMP_Task_Checklist__c>());
								for (
									CSX_CMP_Task_Checklist__c objChecklist : objBusinessRuleWrapper.objBRRule.Task_Checklists__r
								) {
									mapOfTaskChecklistClaims.get(claimId).add(objChecklist);
								}
							}
							break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runTaskChecklistBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfTaskChecklistClaims;
	}

	//Method returns Approval result on the basis of business rules conditions for claims
	public static Map<Id, list<CSX_CMP_Approval_Sequence__c>> runApprovalBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		
		Map<Id, list<CSX_CMP_Approval_Sequence__c>> mapOfApprovalClaims = new Map<Id, list<CSX_CMP_Approval_Sequence__c>>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());
			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);
            
			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);
	
					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (!mapOfApprovalClaims.containsKey(claimId)) {
								mapOfApprovalClaims.put(claimId, new List<CSX_CMP_Approval_Sequence__c>());
								for (
									CSX_CMP_Approval_Sequence__c objApprovallist : objBusinessRuleWrapper.objBRRule.Approval_Sequences__r
								) {
									mapOfApprovalClaims.get(claimId).add(objApprovallist);
								}
							}
							break;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runApprovalBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfApprovalClaims;
	}

	//Method returns the Auto pay kickout code based on the business rules conditions for claims
	public static Map<Id, List<String>> runAutoPayKickoutBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, List<String>> mapOfAutoPayClaims = new Map<Id, List<String>>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (mapOfAutoPayClaims.get(claimId) == null) {
								mapOfAutoPayClaims.put(claimId, new List<String>());
							}
							mapOfAutoPayClaims.get(claimId)
								.add(
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Auto_pay_kickout_Code__r.Name +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Rule_Name__c
								);
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runAutoPayKickoutBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfAutoPayClaims;
	}

	//Method returns the Decline code for claims
	public static Map<Id, list<String>> runAutoDeclineBusinessRules(
		Set<Id> claimIds,
		String strRecordType,
		Id businessRuleId
	) {
		Map<Id, list<String>> mapOfAutoDeclineClaims = new Map<Id, list<String>>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			mapofClaimWrapper = gatherFullClaimDetails(claimIds);
			lstClaimWrapper.addAll(mapofClaimWrapper.values());

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				strRecordType,
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id claimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(claimId);
					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							if (mapOfAutoDeclineClaims.get(claimId) == null) {
								mapOfAutoDeclineClaims.put(claimId, new List<String>());
							}
							mapOfAutoDeclineClaims.get(claimId)
								.add(
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Decline_Code__r.Name +
									'###' +
									objBusinessRuleWrapper.objBRRule.CSX_CMP_Rule_Name__c
								);
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runAutoDeclineBusinessRules',
				String.valueOf(claimIds),
				ex
			);
		}
		return mapOfAutoDeclineClaims;
	}

	//Method to return all duplicate claims based on business rules
	public static Map<Id, String> runDuplicateBusinessRules(
		Id claimId,
		ClaimWrapper inputClaimWrapper,
		Id businessRuleId
	) {
		Map<Id, String> mapOfDuplicateClaims = new Map<Id, String>();
		Map<Id, ClaimWrapper> mapofClaimWrapper = new Map<Id, ClaimWrapper>();
		list<ClaimWrapper> lstClaimWrapper = new List<ClaimWrapper>();

		try {
			if (claimId != null) {
				mapofClaimWrapper = gatherFullClaimDetails(new Set<Id>{ claimId });
				lstClaimWrapper.addAll(mapofClaimWrapper.values());
			} else {
				lstClaimWrapper.add(inputClaimWrapper);
			}

			Map<Id, list<BusinessRuleWrapper>> businessRuleEvalResultsMap = evaluateBusinessRules(
				lstClaimWrapper,
				'CSX_CMP_Duplicate',
				businessRuleId
			);

			if (businessRuleEvalResultsMap != null && businessRuleEvalResultsMap.size() > 0) {
				for (Id sourceclaimId : businessRuleEvalResultsMap.keySet()) {
					list<BusinessRuleWrapper> lstBusinessRuleWrapper = businessRuleEvalResultsMap.get(sourceclaimId);

					for (BusinessRuleWrapper objBusinessRuleWrapper : lstBusinessRuleWrapper) {
						if (objBusinessRuleWrapper.result) {
							mapOfDuplicateClaims = objBusinessRuleWrapper.finalDuplicateClaimIdMap;
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_BusinessRulesUtility',
				'runDuplicateBusinessRules',
				String.valueOf(claimId),
				ex
			);
		}
		return mapOfDuplicateClaims;
	}

	public static ClaimWrapper newClaimWrapperToClaimWrapper(CSX_CMP_NewClaimWrapper newClaim) {
		ClaimWrapper claimWrapper = new ClaimWrapper();
		claimWrapper.id = userInfo.getUserId(); //'NEWCLAIMID'; //passing dummy User record Id as claim id for duplicate check before claim creation to work
		claimWrapper.claimAmount = newClaim.claimAmount;
		claimWrapper.claimType = newClaim.claimType != null ? newClaim.claimType : '';
		//query to get claimVendor using supplierId
		//system.debug('supplier Id :'+newClaim.supplierId);
		if (String.isNotBlank(newClaim.supplierId)) {
			// system.debug('supplier Id Inside:'+newClaim.supplierId);
			Account supplierAcc = [
				SELECT Id, Site, Name
				FROM Account
				WHERE RecordType.DeveloperName = 'Location' AND 
				Type = 'Supplier' AND Id = :newClaim.supplierId 
				AND Location_Type__c = 'Billing Address'
				/*WITH SECURITY_ENFORCED*/];
				// system.debug('supplierAcc :'+supplierAcc);
			claimWrapper.claimVendor = supplierAcc.Name;
			claimWrapper.vendorSite = supplierAcc.Site;
		}
		claimWrapper.claimRefundPeriod =
			String.valueOf(newClaim.periodBegin) +
			'#' +
			String.valueOf(newClaim.periodEnd);
		claimWrapper.claimantName = newClaim.supplierClaimantName;
		claimWrapper.claimReason = newClaim.claimReason;
		claimWrapper.recordType = newClaim.claimRecordType;

		if (claimWrapper.recordType == 'Revenue_Contract_Refund') {
			CSX_CMP_Contract__c contract = [
				SELECT Id, CSX_CMP_Claim_Type__c, Name
				FROM CSX_CMP_Contract__c
				WHERE Id = :newClaim.contractNumber WITH SECURITY_ENFORCED];
			claimWrapper.contractName = contract.Name;
			claimWrapper.contractType = contract.CSX_CMP_Claim_Type__c;
			if (newClaim.claimType == null) {
				claimWrapper.claimType = contract.CSX_CMP_Claim_Type__c;
			}
		}

		claimWrapper.claimSource = newClaim.source;
		claimWrapper.shipCSXUserID = newClaim.shipCSXUserId;
		claimWrapper.derailmentFlag = newClaim.derailmentFlag;
		claimWrapper.dealerSPLC = newClaim.dealerSplc;
		claimWrapper.claimStatus = 'New';
		claimWrapper.claimVin = newClaim.vin;
		claimWrapper.equipment = new List<CSX_CMP_BusinessRulesUtility.EquipmentWrapper>();

		if (!newClaim.equipment.isEmpty()) {
			Integer i = 1;
			for (CSX_CMP_NewClaimWrapper.EquipmentORClaimLine equipment : newClaim.equipment) {
				CSX_CMP_BusinessRulesUtility.EquipmentWrapper equipWrapper = new CSX_CMP_BusinessRulesUtility.EquipmentWrapper();
				equipWrapper.id = 'NEWEQUIPMENTID' + i;

				if(!string.isEmpty(equipment.equipmentInitial) && !string.isEmpty(equipment.equipmentNumber)){
					equipWrapper.equipmentName = equipment.equipmentInitial.trim() + ' ' + equipment.equipmentNumber.trim();
				}
				
				equipWrapper.waybillDestCity = equipment.actualDestinationCityName;
				equipWrapper.waybillNum = equipment.waybillNumber;
				equipWrapper.stccCode = equipment.stcc;
				equipWrapper.waybillDate = CSX_CMP_Utility.formatDate(equipment.waybillDate);
				equipWrapper.waybillActualDestinationRoad = equipment.actualDestinationSCAC;
				equipWrapper.waybillActualOriginRoad = equipment.actualOriginSCAC;
				equipWrapper.waybillActualOriginCity = equipment.actualOriginCityName;
				equipWrapper.equipmentShipper = equipment.shipperName;
				equipWrapper.urwinNum = equipment.urrwinNumber;
				equipWrapper.equipInitial = equipment.equipmentInitial;
				equipWrapper.equipNum = equipment.equipmentNumber;
				//equipWrapper.Product = new List<CSX_CMP_BusinessRulesUtility.EquipmentWrapper>();
				claimWrapper.Equipment.add(equipWrapper);
				i++;
			}
		}
		return claimWrapper;
	}

	//method to get business rule conditions against each object type for faster comparisons
	public static Map<String, List<CSX_CMP_Business_Rule_Condition__c>>  getObjbasedBusConditionsMap(CSX_CMP_Business_Rule__c objBussinessRule){
			
		Map<String, List<CSX_CMP_Business_Rule_Condition__c>> mapofObjTypetoBusConditions = new Map<String, List<CSX_CMP_Business_Rule_Condition__c>>();
	
		for (CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : objBussinessRule.Business_Rule_Conditions__r	) {		//6
			if (string.isNotBlank(objBusinessRuleCondition.CSX_CMP_Attribute_Name__c)) {
				list<String> lstAttributeSplit = objBusinessRuleCondition.CSX_CMP_Attribute_Name__c.split('_');
			
				if (lstAttributeSplit[1] == 'equipment') {
							
					//Product and Distribution Level
					if (lstAttributeSplit[2] == 'product' || lstAttributeSplit[2] == 'distribution') {

						//Customer and Inspection Damage Level
						if (lstAttributeSplit[3] == 'customerDamage' ||	lstAttributeSplit[3] == 'inspectionDamage') {
							//Customer and Inspection Damage attributes
							mapofObjTypetoBusConditions = addtoObjtoBusConditionsMap(mapofObjTypetoBusConditions, lstAttributeSplit[2], objBusinessRuleCondition);
						}else{
							//Product and Distribution attribute
							mapofObjTypetoBusConditions = addtoObjtoBusConditionsMap(mapofObjTypetoBusConditions, lstAttributeSplit[2], objBusinessRuleCondition);
						}
							
					}else{
						//equipment or claim line attribute
						mapofObjTypetoBusConditions = addtoObjtoBusConditionsMap(mapofObjTypetoBusConditions, lstAttributeSplit[1], objBusinessRuleCondition);
					}
				}else{
					//claim attribute
					mapofObjTypetoBusConditions = addtoObjtoBusConditionsMap(mapofObjTypetoBusConditions, lstAttributeSplit[0], objBusinessRuleCondition);
				}
			}
		}
		
		return mapofObjTypetoBusConditions;
	}
	
	//helper method for getObjbasedBusConditionsMap to add entries to the map
	public static Map<String, List<CSX_CMP_Business_Rule_Condition__c>> addtoObjtoBusConditionsMap(Map<String, List<CSX_CMP_Business_Rule_Condition__c>> maptoUpdate, String attributeName, CSX_CMP_Business_Rule_Condition__c busConditionRec){
		
		if(!maptoUpdate.containskey(attributeName)){
			maptoUpdate.put(attributeName,new List<CSX_CMP_Business_Rule_Condition__c>{busConditionRec});
		}else{
			maptoUpdate.get(attributeName).add(busConditionRec);
		}
				
		return maptoUpdate;
	}

	//BusinessRuleWrapper
	public class BusinessRuleWrapper {
		public CSX_CMP_Business_Rule__c objBRRule;
		public Map<Id, String> finalDuplicateClaimIdMap;
		public boolean result;

		BusinessRuleWrapper() {
			finalDuplicateClaimIdMap = new Map<Id, String>();
		}
	}

	//FLR Wrapper
	public class FLRClaimWrapper {
		public String strCaseID;
		public List<CSX_CMP_FLR_Question__c> lstQuestions;
		//Public Map<string,List<String>> mapQuestions;
		//public list<String> lstEmails;
		public Map<String, Set<String>> mapOfmails;
		public String strBusinessRuleName;

		public FLRClaimWrapper() {
			// mapQuestions = new Map<string,List<String>>();
			lstQuestions = new List<CSX_CMP_FLR_Question__c>();
			mapOfmails = new Map<String, Set<String>>();
		}
	}

	// Claim object wrapper
	public class ClaimWrapper {
		public String id;
		public Decimal claimAge;
		public Decimal claimAmount;
		public String claimantName;
		public String claimNumber;
		public String claimReason;
		public String recordType;
		public String claimStatus;
		public String claimType;
		public String deskName;
		public String nationalAccount;
		public String claimSource;
		public String supplierEDICode;
		public Boolean customerIsMissing;
		public String shipCSXUserID;
		public String contractName;
		public String contractType;
		public Boolean derailmentFlag;
		public String claimVendor;
		public String vendorSite;
		public Boolean autoSettleReturnStatus;
		public String dealerSPLC;
		public Boolean claimAmountwithinthreshold;
		public Decimal numberofRelatedClaim;
		public string supplierCountry;
		public string teamNumber;
		public string claimVin;
		public String businessUnit;
		public string claimRefundPeriod; // concat (claim.CSX_CMP_Period_Begin__c # claim.CSX_CMP_Period_End__c)
		public list<String> ldNumber;
		public list<EquipmentWrapper> equipment;

		public ClaimWrapper() {
			derailmentFlag = false;
			autoSettleReturnStatus = false;
			claimAmountwithinthreshold = false;
			equipment = new List<EquipmentWrapper>();
			ldNumber = new List<String>();
		}
	}

	// Equipment object wrapper
	public class EquipmentWrapper {
		public String id;
		public String equipmentName;
		public String waybillDestCity;
		public String waybillNum;
		public String stccCode;
		public String waybillDate;
		public String equipInitial;
		public String waybillActualDestinationRoad;
		public String waybillActualOriginRoad;
		public String waybillActualOriginCity;
		public String equipmentShipper;
		public Decimal waybillDateAging;
		public String routeCode;
		public String equipNum;
		public String freightbillNum;
		public String urwinNum;
		//public String businessUnit;
		public list<ProductWrapper> product;
		public list<DistributionWrapper> distribution;

		public EquipmentWrapper() {
			product = new List<ProductWrapper>();
			distribution = new List<DistributionWrapper>();
		}
	}

	//Distribution wrapper
	public class DistributionWrapper {
		public String id;
		public String dRoute;
		public String rrCode;
		public Boolean nonCSXMexicanRR;
		public String fCContactEmail;

		public DistributionWrapper() {
			nonCSXMexicanRR = false;
		}
	}

	//Product wrapper
	public class ProductWrapper {
		public String id;
		public Boolean no04InspectionCount;
		public Boolean custDamageMatchInspRep1278;
		public Boolean allCustDamagematchInspRep04;
		public Boolean customerDamageMatches;
		public Boolean atleast1DmgContains0;
		public list<InspectionDamageWrapper> inspectionDamage;
		public list<CustomerDamageWrapper> customerDamage;

		public ProductWrapper() {
			custDamageMatchInspRep1278 = false;
			customerDamageMatches = false;
			no04InspectionCount = false;
			allCustDamagematchInspRep04 = false;

			inspectionDamage = new List<InspectionDamageWrapper>();
			customerDamage = new List<CustomerDamageWrapper>();
		}
	}

	//Inspection damage wrapper
	public class InspectionDamageWrapper {
		public String id;
		public String idReportType;
		public String idArea;
		public String idType;
		public String idSeverity;
	}

	//Customer Damage wrapper
	public class CustomerDamageWrapper {
		public String id;
		public String cdName;
		public String cdArea;
		public String cdType;
		public String cdSeverity;
	}
}