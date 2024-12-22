/**
@Author       - Infosys
@Name         - FLR Visualforce Email Controller
@Created Date - 12/17/2023
@Description  - This Apex class is used to bind the FLR
@RICEFW reference - CMP-E-0422
*/
public with sharing class CSX_CMP_FLREmailController {
	public CaseWrapper objCaseWrapper { get; set; }
	public string originRoad { get; set; }

	public string destinationRoad { get; set; }
	public string csxLogo {get; set;}
	Public String formattedClaimAmount{get; set;}
	public string caseId {
		get;
		set {
			caseId = value;
			getClaimDetails();
		}
	}

	public string otherRoadValue { get; set; }

	public CaseWrapper getClaimDetails() {
		csxLogo = CSX_CMP_Utility.logoUrl();
		list<Case> objCaseDetails = [
			SELECT
				Id,
				CSX_CMP_Claim_Date__c,
				CSX_CMP_Claim_Amount__c,
				CaseNumber,
				CSX_CMP_FLR_Questions__c,
				(
					SELECT
						Id,
						Name,
						CSX_CMP_STCC__c,
						CSX_CMP_Equipment_Num__c,
						CSX_CMP_Waybill_Date__c,
						CSX_CMP_Waybill_Num__c,
						CSX_CMP_Shipper__c,
						CSX_CMP_Consignee__c,
						CSX_CMP_Act_Origin_City__c,
						CSX_CMP_Act_Origin_State__c,
						CSX_CMP_Act_Destination_City__c,
						CSX_CMP_Act_Destination_State__c
					FROM Equipments__r
				)
			FROM Case
			WHERE Id = :caseId
			WITH SECURITY_ENFORCED
		];	
		if (objCaseDetails != null && objCaseDetails.size() > 0) {
			objCaseWrapper = new CaseWrapper();
			objCaseWrapper.claimDate = Date.valueOf(objCaseDetails[0].CSX_CMP_Claim_Date__c);
			//objCaseWrapper.claimAmount =decimal.valueOf('$'+String.valueOf(objCaseDetails[0].CSX_CMP_Claim_Amount__c));
		    formattedClaimAmount = '$' + String.valueOf(objCaseDetails[0].CSX_CMP_Claim_Amount__c.setScale(2, RoundingMode.HALF_UP));
			objCaseWrapper.caseNumber = objCaseDetails[0].CaseNumber;
			if (String.isNotBlank(objCaseDetails[0].CSX_CMP_FLR_Questions__c)) {
				//objCaseWrapper.lstQuestion = objCaseDetails[0].CSX_CMP_FLR_Questions__c.split(';');
				string questions = objCaseDetails[0].CSX_CMP_FLR_Questions__c;
				List<CSX_CMP_FLR_Question__c> questionsList = (List<CSX_CMP_FLR_Question__c>) JSON.deserialize(
					questions,
					List<CSX_CMP_FLR_Question__c>.class
				);				
				if (!questionsList.isEmpty()) {
					for (CSX_CMP_FLR_Question__c objQue : questionsList) {
						if (objQue.CSX_CMP_Question_To__c == originRoad) {
							objCaseWrapper.lstQuestion.add(objQue.CSX_CMP_Question__c);
						} else if (objQue.CSX_CMP_Question_To__c == destinationRoad) {
							objCaseWrapper.lstQuestion.add(objQue.CSX_CMP_Question__c);
						} 
                        if (objQue.CSX_CMP_Question_To__c == otherRoadValue) {
							objCaseWrapper.lstQuestion.add(objQue.CSX_CMP_Question__c);
						}
					}
				}				
			}

			if (objCaseDetails[0].Equipments__r != null && objCaseDetails[0].Equipments__r.size() > 0) {
				objCaseWrapper.commodity = objCaseDetails[0].Equipments__r[0].CSX_CMP_STCC__c;
				objCaseWrapper.shipper = objCaseDetails[0].Equipments__r[0].CSX_CMP_Shipper__c;
				objCaseWrapper.consignee = objCaseDetails[0].Equipments__r[0].CSX_CMP_Consignee__c;
				objCaseWrapper.origin =
					objCaseDetails[0].Equipments__r[0].CSX_CMP_Act_Origin_City__c +
					', ' +
					objCaseDetails[0].Equipments__r[0].CSX_CMP_Act_Origin_State__c;
				objCaseWrapper.destination =
					objCaseDetails[0].Equipments__r[0].CSX_CMP_Act_Destination_City__c +
					', ' +
					objCaseDetails[0].Equipments__r[0].CSX_CMP_Act_Destination_State__c;
				objCaseWrapper.equipment = objCaseDetails[0].Equipments__r[0].Name;
				objCaseWrapper.strWaybillNumber = objCaseDetails[0].Equipments__r[0].CSX_CMP_Waybill_Num__c;
				
				if (objCaseDetails[0].Equipments__r[0].CSX_CMP_Waybill_Date__c != null) {
					//Date objDate = objCaseDetails[0].Equipments__r[0].CSX_CMP_Waybill_Date__c;
					/*objCaseWrapper.waybillDate = DateTime.newInstance(objDate.year(), objDate.month(), objDate.day())
						.format('d/MM/yyyy');*/
                    objCaseWrapper.waybillDate = objCaseDetails[0].Equipments__r[0].CSX_CMP_Waybill_Date__c;
                    /*objCaseWrapper.waybillDateSubject = DateTime.newInstance(
                        objDate.year(),
                        objDate.month(),
                        objDate.day()
                    ).format('MM/dd/yyyy');*/
				}

				list<CSX_CMP_Equipment__c> lstEquipment = [
					SELECT
						Id,
						(SELECT Id, CSX_CMP_VIN__c FROM Products__r WHERE CSX_CMP_VIN__c != NULL),
						(
							SELECT Id, CSX_CMP_Code__c
							FROM Distributions__r
							WHERE CSX_CMP_Code__c != 'CSXT' AND CSX_CMP_Code__c != 'FXE' AND CSX_CMP_Code__c != ''
						)
					FROM CSX_CMP_Equipment__c
					WHERE Id = :objCaseDetails[0].Equipments__r[0].Id
					WITH SECURITY_ENFORCED
				];

				if (lstEquipment != null && lstEquipment.size() > 0) {
					if (lstEquipment[0].Products__r != null && lstEquipment[0].Products__r.size() > 0) {
						objCaseWrapper.vin = lstEquipment[0].Products__r[0].CSX_CMP_VIN__c;
					}

					if (lstEquipment[0].Distributions__r != null && lstEquipment[0].Distributions__r.size() > 0) {
						objCaseWrapper.route = lstEquipment[0].Distributions__r[0].CSX_CMP_Code__c;
					}
				}
			}
		}

		return objCaseWrapper;
	}

	public class CaseWrapper {
		public Date claimDate { get; set; }
		public decimal claimAmount { get; set; }
		public String caseNumber { get; set; }
		public String commodity { get; set; }
		public String vin { get; set; }
		public String shipper { get; set; }
		public String consignee { get; set; }
		public String origin { get; set; }
		public String destination { get; set; }
		public String equipment { get; set; }
		public String route { get; set; }
		//public String waybillDateSubject { get; set; }
		//public String waybillDate { get; set; }
        public Date waybillDate { get; set; }
		public List<string> lstQuestion { get; set; }
		public string strLogoUrl { get; set; }
		public list<string> lstAddress { get; set; }
		public string strWaybillNumber { get; set; }

		CaseWrapper() {
			lstQuestion = new List<string>();
		}
	}
}