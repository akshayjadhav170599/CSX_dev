/**************************************************************************************
Apex Class Name     : CSX_CMP_SettlementUtility
Function            : Class to keep all reusuable methods 
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Akshay           02/11/2023       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_SettlementUtility {
	//method to create AP settlement record
	public static void createAPSettlements(List<Case> inputClaims) {
		List<CSX_CMP_AP_Settlement__c> newAPList = new List<CSX_CMP_AP_Settlement__c>();
		Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();
		String externalId;
		try {
			for (Case cs : inputClaims) {
				CSX_CMP_AP_Settlement__c newAP = new CSX_CMP_AP_Settlement__c();
				newAP.CSX_CMP_Currency__c = System.Label.CSX_CMP_Currency_Type;
				newAP.CSX_CMP_Document_Type__c = System.Label.CSX_CMP_AP_Document_Type;
				newAP.CSX_CMP_Integration_Status__c = System.Label.CSX_CMP_Default_Integration_Status;
				newAP.CSX_CMP_Payment_Amount__c = cs.CSX_CMP_Claim_Amount__c;
				newAP.CSX_CMP_Payment_Date__c = System.Today();
                newAP.CSX_CMP_Scheduled_Payment_Amount__c = cs.CSX_CMP_Claim_Amount__c;
				newAP.CSX_CMP_Scheduled_Pay_Date__c = System.Today()+1;
				newAp.CSX_CMP_Claim__c = cs.Id;
				if (rtMap.get(cs.RecordTypeId).getName().contains('Freight')) {
					newAP.CSX_CMP_Source__c = 'Freight';
				} else {
					newAP.CSX_CMP_Source__c = 'Revenue';
				}
				externalId = cs.Type + (cs.CSX_CMP_Terminal__c != null ? '_' + cs.CSX_CMP_Terminal__c : '_NA');
				CSX_CMP_SAP_Accounting_Detail__c sapAccInfo = CSX_CMP_SAP_Accounting_Detail__c.getValues(externalId);
				if (sapAccInfo != null) {
					if (String.isNotBlank(sapAccInfo.CSX_CMP_AP_GL_Account__c)) {
						newAP.CSX_CMP_GL_Account__c = sapAccInfo.CSX_CMP_AP_GL_Account__c;
					}
					if (String.isNotBlank(sapAccInfo.CSX_CMP_AP_Cost_Center__c)) {
						newAP.CSX_CMP_Cost_Center__c = sapAccInfo.CSX_CMP_AP_Cost_Center__c;
					}
                    if (String.isNotBlank(sapAccInfo.CSX_CMP_Payment_Terms__c)) {
						newAP.CSX_CMP_Payment_Terms__c = sapAccInfo.CSX_CMP_Payment_Terms__c;
					}
                    
					newAP.CSX_CMP_Integration_Status__c = System.Label.CSX_CMP_Default_Integration_Status;

					if (String.isNotBlank(sapAccInfo.CSX_CMP_AP_Company_Code__c)) {
						newAP.CSX_CMP_Company_Code__c = sapAccInfo.CSX_CMP_AP_Company_Code__c;
					}
				}
				newAPList.add(newAP);
			}

			Database.insert(newAPList);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SettlementUtility',
				'createAPSettlement',
				JSON.serialize(newAPList),
				ex
			);
		}
	}

	//method to create AR settlement record
	@AuraEnabled
	public static void createARSettlements(List<Case> inputClaims) {
		List<CSX_CMP_AR_Settlement__c> newARList = new List<CSX_CMP_AR_Settlement__c>();
		List<Id> caseIds = new List<Id>();
		map<Id,list<CSX_CMP_Equipment__c>> mapOfCaseIdWithListOfEquipment = new map<Id,list<CSX_CMP_Equipment__c>>();
		String externalId;

		for (Case cs : inputClaims) {
        	caseIds.add(cs.Id);
    	}

		list<CSX_CMP_Equipment__c> lstEquipment = [SELECT Id , Name, CSX_CMP_Waybill_Num__c,CSX_CMP_Claim__c
													, CSX_CMP_Waybill_Date__c, CSX_CMP_Act_Origin_City__c
													, CSX_CMP_Act_Origin_State__c, CSX_CMP_Act_Destination_City__c
													, CSX_CMP_Act_Destination_State__c
													, (SELECT Id, CSX_CMP_Incident_Location__c FROM X3rd_Partys__r)
													FROM CSX_CMP_Equipment__c
													WHERE CSX_CMP_Claim__c IN :caseIds WITH SECURITY_ENFORCED];

		if(lstEquipment != null && lstEquipment.size() > 0){
			for(CSX_CMP_Equipment__c objEquipment : lstEquipment){
				if(mapOfCaseIdWithListOfEquipment.get(objEquipment.CSX_CMP_Claim__c) == null){
					mapOfCaseIdWithListOfEquipment.put(objEquipment.CSX_CMP_Claim__c, new list<CSX_CMP_Equipment__c>());
				}
				mapOfCaseIdWithListOfEquipment.get(objEquipment.CSX_CMP_Claim__c).add(objEquipment);
			}
		}
		
		Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();

		try {
			for (Case cs : inputClaims) {
				CSX_CMP_Equipment__c objEquipment = new CSX_CMP_Equipment__c();

				if(mapOfCaseIdWithListOfEquipment.get(cs.id) != null && mapOfCaseIdWithListOfEquipment.get(cs.id).size() > 0){
					objEquipment = mapOfCaseIdWithListOfEquipment.get(cs.id)[0];
				}
				
				CSX_CMP_AR_Settlement__c newAR = new CSX_CMP_AR_Settlement__c();

				newAR.CSX_CMP_Currency_Type__c = System.Label.CSX_CMP_Currency_Type;
				newAR.CSX_CMP_Document_Type__c = System.Label.CSX_CMP_AR_Document_Type;
				newAR.CSX_CMP_Integration_Status__c = System.Label.CSX_CMP_Default_Integration_Status;
				newAR.CSX_CMP_Invoice_Amount__c = cs.CSX_CMP_Claim_Amount__c;
                newAR.CSX_CMP_Balance_Due__c = 0 - cs.CSX_CMP_Claim_Amount__c;
				newAR.CSX_CMP_Request_Type__c = 'Create';
				newAR.CSX_CMP_Claim__c = cs.Id;
				newAR.CSX_CMP_Customer_Name__c = cs.CSX_CMP_Customer__c;
				newAR.CSX_CMP_VIN__c = cs.CSX_CMP_VIN__c;
				newAR.CSX_CMP_Service_Period__c	= cs.CSX_CMP_Service_Period__c;
				newAR.CSX_CMP_Claim_Type__c = cs.Type;

				if(objEquipment != null){
					newAR.CSX_CMP_Equipment__c = objEquipment.Name;
					newAR.CSX_CMP_Waybill_Number__c = objEquipment.CSX_CMP_Waybill_Num__c;
					newAR.CSX_CMP_Waybill_Date__c = objEquipment.CSX_CMP_Waybill_Date__c;
					newAR.CSX_CMP_Origin__c = objEquipment.CSX_CMP_Act_Origin_City__c +' '+ objEquipment.CSX_CMP_Act_Origin_State__c;
					newAR.CSX_CMP_Destination__c = objEquipment.CSX_CMP_Act_Destination_City__c +' '+ objEquipment.CSX_CMP_Act_Destination_State__c;

					if (objEquipment.X3rd_Partys__r.size() > 0 && objEquipment.X3rd_Partys__r[0].CSX_CMP_Incident_Location__c != null) {
						newAR.CSX_CMP_Incident_Location__c = objEquipment.X3rd_Partys__r[0].CSX_CMP_Incident_Location__c;
					}
				}
				

				if (rtMap.get(cs.RecordTypeId).getName().contains('Freight')) {
					newAR.CSX_CMP_Source__c = 'Freight';
				} else {
					newAR.CSX_CMP_Source__c = 'Revenue';
				}

				newAR.CSX_CMP_Invoice_Date__c = system.today();
				externalId = cs.Type + (cs.CSX_CMP_Terminal__c != null ? '_' + cs.CSX_CMP_Terminal__c : '_NA');
				CSX_CMP_SAP_Accounting_Detail__c sapAccInfo = CSX_CMP_SAP_Accounting_Detail__c.getValues(externalId);
				if (sapAccInfo != null) {
					if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_GL_Account__c)) {
						newAR.CSX_CMP_GL_Account__c = sapAccInfo.CSX_CMP_AR_GL_Account__c;
					}
					if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_Cost_Center__c)) {
						newAR.CSX_CMP_Cost_Center__c = sapAccInfo.CSX_CMP_AR_Cost_Center__c;
					}
					if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_Company_Code__c)) {
						newAR.CSX_CMP_Company_Code__c = sapAccInfo.CSX_CMP_AR_Company_Code__c;
					}
				}
				newARList.add(newAR);
                
			}

		Database.SaveResult[] insertSettlementRecord =	Database.insert(newARList);
		CSX_CMP_LoggerUtility.addApexDMLErrorLog(
			'CSX_CMP_SettlementUtility',
			'createARSettlements',
			insertSettlementRecord[0],
			'ARSettlement'
		);


		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SettlementUtility',
				'createARSettlement',
				String.valueOf(newARList),
				ex
			);
		}
	}

	@AuraEnabled
	public static void create3rdPartyARSettlement(Id partyId) {
		try {
			String externalId;
			CSX_CMP_3rd_Party__c partyRecord = [
				SELECT
					Id,
					CSX_CMP_Equipment__r.CSX_CMP_Claim__c,CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_VIN__c,CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Service_Period__c,
					CSX_CMP_Amount__c,CSX_CMP_Party_Name__c,CSX_CMP_3rd_Party_Site__c,CSX_CMP_Equipment__r.CSX_CMP_Act_Destination_City__c,CSX_CMP_Equipment__r.CSX_CMP_Act_Destination_State__c,
					CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Terminal__c,CSX_CMP_Equipment__r.CSX_CMP_Act_Origin_City__c,CSX_CMP_Equipment__r.CSX_CMP_Act_Origin_State__c,
					CSX_CMP_Equipment__r.CSX_CMP_Claim__r.Type,CSX_CMP_Equipment__r.Name,CSX_CMP_Equipment__r.CSX_CMP_Waybill_Num__c,CSX_CMP_Equipment__r.CSX_CMP_Waybill_Date__c,
					CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Claim_Group__c,CSX_CMP_Incident_Location__c
				FROM CSX_CMP_3rd_Party__c
				WHERE ID = :partyId
				WITH SECURITY_ENFORCED
			];

			CSX_CMP_AR_Settlement__c newAR = new CSX_CMP_AR_Settlement__c();
			newAR.CSX_CMP_Currency_Type__c = System.Label.CSX_CMP_Currency_Type;
			newAR.CSX_CMP_Document_Type__c = System.Label.CSX_CMP_AR_Document_Type;
			newAR.CSX_CMP_Integration_Status__c = System.Label.CSX_CMP_Default_Integration_Status;
			//newAR.CSX_CMP_Invoice_Amount__c = partyRecord.CSX_CMP_Amount__c < 0? (0 - partyRecord.CSX_CMP_Amount__c): partyRecord.CSX_CMP_Amount__c;
			newAR.CSX_CMP_Invoice_Amount__c = partyRecord.CSX_CMP_Amount__c > 0? (0 - partyRecord.CSX_CMP_Amount__c): partyRecord.CSX_CMP_Amount__c;
            newAR.CSX_CMP_Balance_Due__c = partyRecord.CSX_CMP_Amount__c > 0? (partyRecord.CSX_CMP_Amount__c): 0 - partyRecord.CSX_CMP_Amount__c;
			newAR.CSX_CMP_Request_Type__c = 'Create';
			newAR.CSX_CMP_Invoice_Date__c = system.today();
			newAR.CSX_CMP_Claim__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__c;
			newAR.CSX_CMP_Customer_Name__c = partyRecord.CSX_CMP_3rd_Party_Site__c;
			newAR.CSX_CMP_Incident_Location__c = partyRecord.CSX_CMP_Incident_Location__c;

			if(partyRecord.CSX_CMP_Equipment__r != null){
				newAR.CSX_CMP_VIN__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_VIN__c;
				newAR.CSX_CMP_Service_Period__c	= partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Service_Period__c;
				newAR.CSX_CMP_Claim_Type__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.Type;
				newAR.CSX_CMP_Equipment__c = partyRecord.CSX_CMP_Equipment__r.Name;
				newAR.CSX_CMP_Waybill_Number__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Waybill_Num__c;
				newAR.CSX_CMP_Waybill_Date__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Waybill_Date__c;
				newAR.CSX_CMP_Origin__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Act_Origin_City__c +' '+ partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Act_Origin_State__c;
				newAR.CSX_CMP_Destination__c = partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Act_Destination_City__c +' '+ partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Act_Destination_State__c;
			}
			if (partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r != null && partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Claim_Group__c.contains('Freight')) {
				newAR.CSX_CMP_Source__c = 'Freight';
			} else {
				newAR.CSX_CMP_Source__c = 'Revenue';
			}

			externalId =
				partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.Type +
				(partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Terminal__c != null
					? '_' + partyRecord.CSX_CMP_Equipment__r.CSX_CMP_Claim__r.CSX_CMP_Terminal__c
					: '_NA');
			CSX_CMP_SAP_Accounting_Detail__c sapAccInfo = CSX_CMP_SAP_Accounting_Detail__c.getValues(externalId);

			if (sapAccInfo != null) {
				if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_GL_Account__c)) {
					newAR.CSX_CMP_GL_Account__c = sapAccInfo.CSX_CMP_AR_GL_Account__c;
				}
				if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_Cost_Center__c)) {
					newAR.CSX_CMP_Cost_Center__c = sapAccInfo.CSX_CMP_AR_Cost_Center__c;
				}
				if (String.isNotBlank(sapAccInfo.CSX_CMP_AR_Company_Code__c)) {
					newAR.CSX_CMP_Company_Code__c = sapAccInfo.CSX_CMP_AR_Company_Code__c;
				}
			}
			Database.SaveResult saveResult = Database.insert(newAR);
			CSX_CMP_LoggerUtility.addApexDMLErrorLog(
				'CSX_CMP_SettlementUtility',
				'create3rdPartyARSettlement',
				saveResult,
				'ARSettlement'
			);
			if (saveResult.isSuccess()) {
				partyRecord.CSX_CMP_AR_Settlement__c = newAR.id;
				Database.SaveResult saveResults = Database.update(partyRecord);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_SettlementUtility',
					'create3rdPartyARSettlement',
					saveResults,
					'ARSettlement'
				);
				//CSX_CMP_InvoiceAdjustmentController.sendInvoiceEmailCommunication(newAR.id);
				
			}
			/*  CSX_CMP_AR_Settlement__c newARRecord = [SELECT Id, CSX_CMP_Invoice_Number__c FROM CSX_CMP_AR_Settlement__c WHERE ID =: newAR.id];
            System.debug('newARRecord.CSX_CMP_Invoice_Number__c'+newARRecord.CSX_CMP_Invoice_Number__c);
            if(newARRecord.CSX_CMP_Invoice_Number__c != null){
                CSX_CMP_InvoiceAdjustmentController.sendInvoiceEmailCommunication(newAR.id);
            }*/
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_SettlementUtility',
				'create3rdPartyARSettlement',
				String.valueOf(partyId),
				ex
			);
		}
	}
	@InvocableMethod
	public static void invokeSendClaimLineToSAP(List<Id> apSettlementIds) {
		callClaimLineToSAP(apSettlementIds);
	}
	
	@future(Callout = true)
	public static void callClaimLineToSAP(List<Id> apSettlementIds)
	{
		List<CSX_CMP_AP_Settlement__c> lstAPSettlement = [SELECT Id, CSX_CMP_External_ID__c, CSX_CMP_Claim__c 
												FROM CSX_CMP_AP_Settlement__c
												WHERE Id IN :apSettlementIds WITH SECURITY_ENFORCED
												LIMIT 1 ];
		if (!lstAPSettlement.isEmpty()) {
			List<Case> lstCase = [SELECT Id, CaseNumber, ContactEmail, CSX_CMP_National_Account_Num__c, CSX_CMP_Supplier_Claimant__r.AccountNumber,
						(SELECT CSX_CMP_Freight_Bill_Num__c, CSX_CMP_Claim_Amount__c FROM ClaimLines__r)
						FROM Case
						WHERE Id = :lstAPSettlement[0].CSX_CMP_Claim__c WITH SECURITY_ENFORCED
						LIMIT 1];
			if (!lstCase.isEmpty()) {
				list<CSX_CMP_InterfaceUtility.FreightBill> cLPaymentAmount = new list<CSX_CMP_InterfaceUtility.FreightBill>();
				
				for (CSX_CMP_Claim_Line__c claimLine : lstCase[0].ClaimLines__r) {
					CSX_CMP_InterfaceUtility.FreightBill freightBill = new CSX_CMP_InterfaceUtility.FreightBill();
					freightBill.frieghtBillNumber = claimLine.CSX_CMP_Freight_Bill_Num__c;
					freightBill.amount = Integer.valueOf(claimLine.CSX_CMP_Claim_Amount__c);
					cLPaymentAmount.add(freightBill);
				}
				CSX_CMP_InterfaceUtility.SAPRequestWrapper claimLineWrap = new CSX_CMP_InterfaceUtility.SAPRequestWrapper();
					claimLineWrap.claimNumber = lstCase[0].CaseNumber;
					claimLineWrap.nationalAccountNumber = lstCase[0].CSX_CMP_National_Account_Num__c;
					claimLineWrap.apSettlementAutonumberClaimnumber = lstAPSettlement[0].CSX_CMP_External_ID__c;
					claimLineWrap.claimOwner = lstCase[0].ContactEmail;
					claimLineWrap.supplierNumber = Integer.valueOf(lstCase[0].CSX_CMP_Supplier_Claimant__r.AccountNumber);
					claimLineWrap.claimLinePaymentAmount = cLPaymentAmount;

				CSX_CMP_InterfaceUtility.sendClaimLineToSAP(claimLineWrap);
			}
		}
	}
}