/**************************************************************************************
Apex Class Name     : CSX_CMP_DistributionPDFController
Function            : 
RICEFW #            : 
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           04/10/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_DistributionPDFController {
	public list<CSX_CMP_ClaimWrapper> lstclaimWrapper { get; set; }
	public  string csxLogo {get; set;}
	public string strPropertyPortalId {
		get;
		set {
			strPropertyPortalId = value;
			getClaimDetails();
		}
	}

	public void getClaimDetails() {
		csxLogo = CSX_CMP_Utility.logoUrl(); 
		set<String> setOfClaimNumber = new Set<String>();
		lstclaimWrapper = new List<CSX_CMP_ClaimWrapper>();

		if (!string.isempty(strPropertyPortalId)) { 
			List<CSX_CMP_Property_Portal_Staging__c> objPropertyPortal = [
				SELECT id, CSX_CMP_Claim_Number__c
				FROM CSX_CMP_Property_Portal_Staging__c
				WHERE id = :strPropertyPortalId
				WITH SECURITY_ENFORCED
			];
			if (objPropertyPortal.size() > 0) {
				if (!string.isEmpty(objPropertyPortal[0].CSX_CMP_Claim_Number__c) && objPropertyPortal[0].CSX_CMP_Claim_Number__c.contains(',')) {
					list<String> lstClaimNumber = objPropertyPortal[0].CSX_CMP_Claim_Number__c.split(',');
					for (String strClaimNumber : lstClaimNumber) {
						setOfClaimNumber.add(strClaimNumber);
					}
				} else {
					setOfClaimNumber.add(objPropertyPortal[0].CSX_CMP_Claim_Number__c);
				}
			}

			list<Case> lstclaimDetails = [
				SELECT
					Id,
					CSX_CMP_Suspence_Code__c,
					CSX_CMP_Remarks__c,
					CSX_CMP_Previous_Claim_Num__c,
					CSX_CMP_Customer_Claim_Date__c,
					CSX_CMP_Original_Amount__c,
					CSX_CMP_Desk_Name__c,
					CSX_CMP_Claimant_Ref_Num__c,
					CSX_CMP_FCD_Cause_Code__c,
					CSX_CMP_Paid_Amount__c,
					CSX_CMP_Supplier_Claimant__r.Name,
					CSX_CMP_Claim_Date__c,
					Type,
					Owner.name,
					CSX_CMP_Claim_Reason__c,
					CSX_CMP_Salvage_Code__c,
					CaseNumber,
					recordType.Name,
					CSX_CMP_Period_End__c,
					CSX_CMP_Supplier_Claimant_Street__c,
					CSX_CMP_Supplier_Claimant_City_State_Zip__c,
					CSX_CMP_Contract_Num__r.Name,
					CSX_CMP_Period_Begin__c,
					CSX_CMP_Customer__r.Name,
					CSX_CMP_Case_Number_Formula__c,
					(
						SELECT
							Id,
							Name,
							CSX_CMP_Waybill_Date__c,
							CSX_CMP_Waybill_Num__c,
							CSX_CMP_Origin_Road_Num__c,
							CSX_CMP_Act_Origin_City__c,
							CSX_CMP_Supplier_Claimant_Type__c,
							CSX_CMP_Equipment_Num__c,
							CSX_CMP_STCC_Description__c,
							CSX_CMP_Act_Origin_State__c,
							CSX_CMP_Act_Destination_City__c,
							CSX_CMP_Act_Destination_State__c,
							CSX_CMP_Equipment_Initial__c,
							CSX_CMP_Shipper__c,
							CSX_CMP_Destination_Road_Num__c,
							CSX_CMP_Consignee__c,
							CSX_CMP_STCC__c
						FROM Equipments__r
					),
					(SELECT id, name, CSX_CMP_Salvage_Amount__c, CSX_CMP_Salvage__c FROM Salvages__r),
					(SELECT id, name, CSX_CMP_Check__c, CSX_CMP_Payment_Date__c FROM AP_Settlements__r),
					(
						SELECT
							Id,
							Name,
							CSX_CMP_Account__c,
							CSX_CMP_Code__c,
							CSX_CMP_Equipment__c,
							CSX_CMP_Road__c,
							CSX_CMP_Adj_Miles__c,
							CSX_CMP_Miles__c,
							CSX_CMP_Junction__c,
							CSX_CMP_Manual_Adj_Amt__c,
							CSX_CMP_Calculated_Amount__c,
							CSX_CMP_Total_Claim_Amount__c
						FROM Distributions__r
					)
				FROM Case
				//WHERE CaseNumber IN :setOfClaimNumber
				WHERE CSX_CMP_Case_Number_Formula__c IN :setOfClaimNumber
				WITH SECURITY_ENFORCED
			];

			if (lstclaimDetails != null && lstclaimDetails.size() > 0) {

				set<Id> setOfEquipmentId = new set<Id>();
				map<Id, CSX_CMP_Product__c> mapOfEquipmentIdWithProduct = new map<Id, CSX_CMP_Product__c>();

				//get the product details
				for (Case objclaimDetails : lstclaimDetails) {
					if(objclaimDetails.Equipments__r != null && objclaimDetails.Equipments__r.size() > 0){
						setOfEquipmentId.add(objclaimDetails.Equipments__r[0].Id);
					}
				}

				if(setOfEquipmentId.size() > 0){
					
					list<CSX_CMP_Product__c> lstproduct = [SELECT Id, CSX_CMP_VIN__c, CSX_CMP_Product_Description__c, CSX_CMP_Equipment__c
															FROM CSX_CMP_Product__c
															WHERE CSX_CMP_Equipment__c IN : setOfEquipmentId WITH SECURITY_ENFORCED];
					
					for(CSX_CMP_Product__c objProduct : lstproduct){
						if(mapOfEquipmentIdWithProduct.get(objProduct.CSX_CMP_Equipment__c) == null){
							mapOfEquipmentIdWithProduct.put(objProduct.CSX_CMP_Equipment__c, objProduct);
						}
					}								
				}

				for (Case objclaimDetails : lstclaimDetails) {
					CSX_CMP_ClaimWrapper claimWrapper = new CSX_CMP_ClaimWrapper();
					claimWrapper.companyName = objclaimDetails.CSX_CMP_Supplier_Claimant__r.Name;
					claimWrapper.claimantNumber = objclaimDetails.CSX_CMP_Claimant_Ref_Num__c;
					claimWrapper.claimDate = objclaimDetails.CSX_CMP_Claim_Date__c != null
						? CSX_CMP_Utility.formatDate(objclaimDetails.CSX_CMP_Claim_Date__c)
						: null;
					claimWrapper.customerClaimDate = objclaimDetails.CSX_CMP_Customer_Claim_Date__c != null
						? CSX_CMP_Utility.formatDate(objclaimDetails.CSX_CMP_Customer_Claim_Date__c)
						: '';
					claimWrapper.paidAmount = objclaimDetails.CSX_CMP_Paid_Amount__c;
					claimWrapper.claimReason = objclaimDetails.CSX_CMP_Claim_Reason__c;
					claimWrapper.desk = objclaimDetails.CSX_CMP_Desk_Name__c;
					claimWrapper.claimOwner = objclaimDetails.Owner.Name;
					claimWrapper.suspense = objclaimDetails.CSX_CMP_Suspence_Code__c;
					claimWrapper.supplierAddress = objclaimDetails.CSX_CMP_Supplier_Claimant_Street__c;
					claimWrapper.supplierCity = objclaimDetails.CSX_CMP_Supplier_Claimant_City_State_Zip__c;
					claimWrapper.remark = objclaimDetails.CSX_CMP_Remarks__c;
					//claimWrapper.claimNumber = objclaimDetails.CaseNumber;
					claimWrapper.claimNumber = objclaimDetails.CSX_CMP_Case_Number_Formula__c;
					
					claimWrapper.salvageCode = objclaimDetails.CSX_CMP_Salvage_Code__c;
					claimWrapper.fcdCauseCode = objclaimDetails.CSX_CMP_FCD_Cause_Code__c;
					claimWrapper.originalAmount = objclaimDetails.CSX_CMP_Original_Amount__c;
					claimWrapper.claimType = objclaimDetails.Type;
					claimWrapper.previousClaimNumber = objclaimDetails.CSX_CMP_Previous_Claim_Num__c;
					


					if (!objclaimDetails.Equipments__r.isEmpty()) {
						claimWrapper.claimantType = objclaimDetails.Equipments__r[0].CSX_CMP_Supplier_Claimant_Type__c;
						claimWrapper.equipmentID = objclaimDetails.Equipments__r[0].Name;
						claimWrapper.equipInitial = objclaimDetails.Equipments__r[0].CSX_CMP_Equipment_Initial__c;
						claimWrapper.equipmentNum = objclaimDetails.Equipments__r[0].CSX_CMP_Equipment_Num__c;
						claimWrapper.stcc = objclaimDetails.Equipments__r[0].CSX_CMP_STCC__c;
						claimWrapper.originRoad = objclaimDetails.Equipments__r[0].CSX_CMP_Origin_Road_Num__c;
						claimWrapper.distRoadNumber = objclaimDetails.Equipments__r[0].CSX_CMP_Destination_Road_Num__c;
						claimWrapper.shipperCode = objclaimDetails.Equipments__r[0].CSX_CMP_Shipper__c;
						claimWrapper.waybillDate = objclaimDetails.Equipments__r[0].CSX_CMP_Waybill_Date__c != null
							? CSX_CMP_Utility.formatDate(objclaimDetails.Equipments__r[0].CSX_CMP_Waybill_Date__c)
							: '';
						claimWrapper.consigneeCode = objclaimDetails.Equipments__r[0].CSX_CMP_Consignee__c;
						claimWrapper.originCity = objclaimDetails.Equipments__r[0].CSX_CMP_Act_Origin_City__c;
						claimWrapper.originState = objclaimDetails.Equipments__r[0].CSX_CMP_Act_Origin_State__c;
						claimWrapper.waybillNo = objclaimDetails.Equipments__r[0].CSX_CMP_Waybill_Num__c;
						claimWrapper.destinationCity = objclaimDetails.Equipments__r[0].CSX_CMP_Act_Destination_City__c;
						claimWrapper.destinationState = objclaimDetails.Equipments__r[0]
							.CSX_CMP_Act_Destination_State__c;

						if (!mapOfEquipmentIdWithProduct.isempty() && mapOfEquipmentIdWithProduct.containsKey(objclaimDetails.Equipments__r[0].id)) {
							claimWrapper.vin = mapOfEquipmentIdWithProduct.get(objclaimDetails.Equipments__r[0].id).CSX_CMP_VIN__c;
							claimWrapper.stccDescription = mapOfEquipmentIdWithProduct.get(objclaimDetails.Equipments__r[0].id).CSX_CMP_Product_Description__c;
						}
					}

					if (!objclaimDetails.Salvages__r.isEmpty()) {
						claimWrapper.salvageAmount = objclaimDetails.Salvages__r[0].CSX_CMP_Salvage_Amount__c;
					}

					if (!objclaimDetails.Distributions__r.isEmpty()) {
						claimWrapper.relatedDistributions = objclaimDetails.Distributions__r;
						claimWrapper.roadNum = objclaimDetails.Distributions__r[0].CSX_CMP_Road__c;
					}

					if (!objclaimDetails.AP_Settlements__r.isEmpty()) {
						claimWrapper.voucherCode = objclaimDetails.AP_Settlements__r[0].CSX_CMP_Check__c;
						claimWrapper.paymentDate = objclaimDetails.AP_Settlements__r[0].CSX_CMP_Payment_Date__c != null
							? CSX_CMP_Utility.formatDate(objclaimDetails.AP_Settlements__r[0].CSX_CMP_Payment_Date__c)
							: '';
					}
					lstclaimWrapper.add(claimWrapper);
				}
			}
		}
	}

	public CSX_CMP_DistributionPDFController() {
		String strPPId = apexpages.currentpage().getparameters().get('PPId');
		if (!string.isEmpty(strPPId)) {
			strPropertyPortalId = strPPId.escapeHtml4();
		}
	}

	public class CSX_CMP_ClaimWrapper {
		public String claimantNumber { get; set; }
		public String claimantType { get; set; }
		public String companyName { get; set; }
		public String claimDate { get; set; }
		public String claimType { get; set; }
		public Decimal paidAmount { get; set; }
		public String claimReason { get; set; }
		public String equipmentID { get; set; }
		public String waybillDate { get; set; }
		public String vin { get; set; }
		public Decimal suspense { get; set; }
		public String desk { get; set; }
		public String claimNumber { get; set; }
		public String supplierAddress { get; set; }
		public String supplierCity { get; set; }
		public String remark { get; set; }
		public Decimal originalAmount { get; set; }
		public Decimal salvageAmount { get; set; }
		public String distRoadNumber { get; set; }
		public String originRoad { get; set; }
		public String roadNum { get; set; }
		public String consigneeCode { get; set; }
		public String stcc { get; set; }
		public String stccDescription { get; set; }
		public String salvageCode { get; set; }
		public String fcdCauseCode { get; set; }
		public String shipperCode { get; set; }
		public String originCity { get; set; }
		public String originState { get; set; }
		public String destinationCity { get; set; }
		public String destinationState { get; set; }
		public String equipmentNum { get; set; }
		public List<CSX_CMP_Distribution__c> relatedDistributions { get; set; }
		public String voucherCode { get; set; }
		public String waybillNo { get; set; }
		public String equipInitial { get; set; }
		public string paymentDate { get; set; }
		public string customerClaimDate { get; set; }
		public string claimOwner { get; set; }
		public String previousClaimNumber{get;set;} //[MR-00776]
	}
}