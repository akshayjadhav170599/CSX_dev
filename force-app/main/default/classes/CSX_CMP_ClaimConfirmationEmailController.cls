/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimConfirmationEmailController
Function            : Class to fetch and provide dynamic data for email template
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Shyam           11/20/2023       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_ClaimConfirmationEmailController {
	@invocablemethod(label='Claim Acknowledge Summary' description='Claim Acknowledge Summary Descriptions')
	public static list<confirmationEmailWrapper> getClaimDetails(List<String> claimId) {		
		List<Case> caseDetails = new List<Case>(
			[
				SELECT
					id,
					CSX_CMP_RailRoad_Name__c,
					CSX_CMP_Period_Begin__c,
					CSX_CMP_Period_End__c,
					CSX_CMP_Supplier_Claimant__r.BillingAddress,
					CSX_CMP_Supplier_Claimant__r.Payment_Method__c,
					CSX_CMP_Netting_Claim_Ref_Number__c,
					CSX_CMP_Customer_Claim_Date__c,
					RecordType.DeveloperName,
					CaseNumber,
					Reason,
					SuppliedName,
					CSX_CMP_Claim_Date__c,
					CSX_CMP_Claimant_Ref_Num__c,
					(
						SELECT
							id,
							Name,
							CSX_CMP_URRWIN_Date__c,
							CSX_CMP_URRWIN_Num__c,
							CSX_CMP_Waybill_Controls__c,
							CSX_CMP_Waybill_Date__c,
							CSX_CMP_Waybill_Num__c,
							CSX_CMP_Weight_in_Tons__c,
							CSX_CMP_Received_Amount__c,
							CSX_CMP_No_of_Cars__c,
							CSX_CMP_Claim_Amount__c,
							CSX_CMP_STCC__c,
							CSX_CMP_Act_Origin_City__c,
							CSX_CMP_Act_Origin_State__c,
							CSX_CMP_Act_Destination_City__c,
							CSX_CMP_Act_Destination_State__c,
							CSX_CMP_STCC_Description__c,
							CSX_CMP_Equipment_Initial__c,
							CSX_CMP_Equipment_Num__c,
							CSX_CMP_Unit_Refund_Price__c
						FROM ClaimLines__r
						LIMIT 1
					),
					CSX_CMP_Claim_Amount__c,
					(SELECT Id, CSX_CMP_Equipment_Num__c, CSX_CMP_Waybill_Date__c, Name FROM Equipments__r LIMIT 1),
					(
						SELECT id, CSX_CMP_Notes__c, CSX_CMP_Note_Type__c
						FROM Notes__r
						WHERE CSX_CMP_Note_Type__c = 'Comment'
						LIMIT 1
					)
				FROM Case
				WHERE id = :claimId
			]
		);
		List<confirmationEmailWrapper> emailWrapperList = new List<confirmationEmailWrapper>();
		
		for (Case cs : caseDetails) {			
			confirmationEmailWrapper confirmWrapperCase = new confirmationEmailWrapper();
			if (String.isNotBlank(cs.CSX_CMP_Claimant_Ref_Num__c)) {
				confirmWrapperCase.claimRef = cs.CSX_CMP_Claimant_Ref_Num__c;
			}
			if (String.isNotBlank(cs.SuppliedName)) {
				confirmWrapperCase.supplierNameClaim = cs.SuppliedName;
			}
			if (String.isNotBlank(cs.CaseNumber)) {
				confirmWrapperCase.claimNumber = cs.CaseNumber;
			}
			if (cs.CSX_CMP_Customer_Claim_Date__c != null) {
				confirmWrapperCase.claimDate = cs.CSX_CMP_Customer_Claim_Date__c;
			}
			if (cs.CSX_CMP_Claim_Amount__c != null) {
				confirmWrapperCase.claimAmount = cs.CSX_CMP_Claim_Amount__c;
			}
			if (String.isNotBlank(cs.Reason)) {
				confirmWrapperCase.claimReason = cs.Reason;
			}
			if (cs.CSX_CMP_Period_Begin__c != null) {
				confirmWrapperCase.claimPeriodBegin = cs.CSX_CMP_Period_Begin__c;
			}
			if (cs.CSX_CMP_Period_End__c != null) {
				confirmWrapperCase.claimPeriodEnd = cs.CSX_CMP_Period_End__c;
			}
			if (String.isNotBlank(cs.CSX_CMP_RailRoad_Name__c)) {
				confirmWrapperCase.issuingRailroad = cs.CSX_CMP_RailRoad_Name__c;
			}

			if (String.isNotBlank(cs.CSX_CMP_Supplier_Claimant__r.Payment_Method__c)) {
				confirmWrapperCase.remittanceAddressClaim = cs.CSX_CMP_Supplier_Claimant__r.Payment_Method__c;
			}
			if (String.isNotBlank(cs.RecordType.DeveloperName)) {
				confirmWrapperCase.recordTypeName = cs.RecordType.DeveloperName;
			}			

			if (cs.Notes__r != null && !cs.Notes__r.isEmpty()) {				
				CSX_CMP_Notes__c note = cs.Notes__r;

				if (String.isNotBlank(note.CSX_CMP_Notes__c)) {
					confirmWrapperCase.notes = note.CSX_CMP_Notes__c;
				}
			}			

			if (cs.ClaimLines__r != null && !cs.ClaimLines__r.isEmpty()) {				

				confirmWrapperCase.claimLineList = cs.ClaimLines__r;
				CSX_CMP_Claim_Line__c claimLine = cs.ClaimLines__r;
				if (claimLine.CSX_CMP_URRWIN_Num__c != null) {
					confirmWrapperCase.urrWinNumClaimLine = claimLine.CSX_CMP_URRWIN_Num__c;
				}
				if (claimLine.CSX_CMP_URRWIN_Date__c != null) {
					confirmWrapperCase.urrWinDateClaimLine = claimLine.CSX_CMP_URRWIN_Date__c;
				}

				if (claimLine.CSX_CMP_No_of_Cars__c != null) {
					confirmWrapperCase.noOfCarClaimLine = claimLine.CSX_CMP_No_of_Cars__c;
				}
				if (
					(String.isNotBlank(claimLine.CSX_CMP_Act_Origin_City__c)) ||
					(String.isNotBlank(claimLine.CSX_CMP_Act_Origin_State__c))
				) {
					confirmWrapperCase.originClaimLine =
						claimLine.CSX_CMP_Act_Origin_City__c + claimLine.CSX_CMP_Act_Origin_State__c;
				}
				if (
					(String.isNotBlank(claimLine.CSX_CMP_Act_Destination_City__c)) ||
					(String.isNotBlank(claimLine.CSX_CMP_Act_Destination_State__c))
				) {
					confirmWrapperCase.destinationClaimLine =
						claimLine.CSX_CMP_Act_Destination_City__c + claimLine.CSX_CMP_Act_Destination_State__c;
				}
				if (
					(String.isNotBlank(claimLine.CSX_CMP_STCC__c)) ||
					(String.isNotBlank(claimLine.CSX_CMP_STCC_Description__c))
				) {
					confirmWrapperCase.commodityClaimLine =
						claimLine.CSX_CMP_STCC__c + claimLine.CSX_CMP_STCC_Description__c;
				}
				if (
					(String.isNotBlank(claimLine.CSX_CMP_Equipment_Initial__c)) ||
					(String.isNotBlank(claimLine.CSX_CMP_Equipment_Initial__c))
				) {
					confirmWrapperCase.leadEquipmentClaimLine =
						claimLine.CSX_CMP_Equipment_Initial__c + claimLine.CSX_CMP_Equipment_Initial__c;
				}

				if (claimLine.CSX_CMP_Waybill_Num__c != null) {
					confirmWrapperCase.waybillNumberClaimLine = claimLine.CSX_CMP_Waybill_Num__c;
				}
				if (claimLine.CSX_CMP_Waybill_Date__c != null) {
					confirmWrapperCase.waybillDateClaimLine = claimLine.CSX_CMP_Waybill_Date__c;
				}

				if (String.isNotBlank(claimLine.Name)) {
					confirmWrapperCase.claimLineType = claimLine.Name;
				}
				if (claimLine.CSX_CMP_No_of_Cars__c != null) {
					confirmWrapperCase.claimLineCarWeight = claimLine.CSX_CMP_No_of_Cars__c;
				}

				if (claimLine.CSX_CMP_Unit_Refund_Price__c != null) {
					confirmWrapperCase.claimLineUnitRate = claimLine.CSX_CMP_Unit_Refund_Price__c;
				}
				if (claimLine.CSX_CMP_Claim_Amount__c != null) {
					confirmWrapperCase.refundAmount = claimLine.CSX_CMP_Claim_Amount__c;
				}
			}			

			if (cs.Equipments__r != null && !cs.Equipments__r.isEmpty()) {				
				CSX_CMP_Equipment__c equ = cs.Equipments__r;
				confirmWrapperCase.equipmentNumber = equ.CSX_CMP_Equipment_Num__c;
				confirmWrapperCase.wayBillDateEquipment = equ.CSX_CMP_Waybill_Date__c;
				confirmWrapperCase.equipmentIdDetails = equ.Id;
			}						
			emailWrapperList.add(confirmWrapperCase);			
		}

		//CSX_CMP_Product__c productDetails=new CSX_CMP_Product__c();
		//productDetails=(select id,CSX_CMP_Equipment__c, CSX_CMP_Identifier__c from CSX_CMP_Product__c where CSX_CMP_Equipment__c=:equipmentId limit 1);
		/* List<CSX_CMP_Product__c> productDetails=new List<CSX_CMP_Product__c>([select id,CSX_CMP_Equipment__c, CSX_CMP_Identifier__c from CSX_CMP_Product__c where CSX_CMP_Equipment__c=:equipmentId limit 1]);      
for(CSX_CMP_Product__c product:productDetails){

confirmationEmailWrapper confirmWrapperCase= new confirmationEmailWrapper();
confirmWrapperCase.vinNumber=product.CSX_CMP_Identifier__c;
emailWrapperList.add(confirmWrapperCase);
} */		
		
		return emailWrapperList;
	}

	public class ConfirmationEmailWrapper {
		@invocablevariable
		public string claimNumber;
		@invocablevariable
		public string generalRuleNumber;
		@invocablevariable
		public string issuingRailroad;
		@invocablevariable
		public string remittanceAddressClaim;
		@invocablevariable
		public string equipmentIdDetails;
		@invocablevariable
		public string claimReason;
		@invocablevariable
		public date claimDate;
		@invocablevariable
		public string vinNumber;
		@invocablevariable
		public string claimRef;
		@invocablevariable
		public date claimPeriodBegin;
		@invocablevariable
		public date claimPeriodEnd;
		@invocablevariable
		public string supplierNameClaim;
		@invocablevariable
		public decimal weightInTonsClaimLine;
		@invocablevariable
		public decimal refundAmountClaimLine;
		@invocablevariable
		public decimal claimAmount;
		@invocablevariable
		public List<CSX_CMP_Claim_Line__c> claimLineList;
		@invocablevariable
		public String recordTypeName;
		@invocablevariable
		public String urrWinNumClaimLine;
		@invocablevariable
		public String leadEquipmentClaimLine;
		@invocablevariable
		public String originClaimLine;
		@invocablevariable
		public String destinationClaimLine;
		@invocablevariable
		public decimal noOfCarClaimLine;
		@invocablevariable
		public date urrWinDateClaimLine;
		@invocablevariable
		public String waybillNumberClaimLine;
		@invocablevariable
		public date waybillDateClaimLine;
		@invocablevariable
		public String commodityClaimLine;
		//@invocablevariable
		//public List<CSX_CMP_Equipment__c> EquipmentList;
		@invocablevariable
		public string equipmentNumber;
		@invocablevariable
		public date wayBillDateEquipment;
		@invocablevariable
		public string notes;
		@invocablevariable
		public string identifier;
		@invocablevariable
		public string claimLineType;
		@invocablevariable
		public decimal claimLineCarWeight;
		@invocablevariable
		public decimal claimLineUnitRate;
		@invocablevariable
		public decimal refundAmount;
	}
}