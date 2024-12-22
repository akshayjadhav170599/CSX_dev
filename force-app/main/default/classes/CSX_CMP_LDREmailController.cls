/**
@Author       - Infosys
@Name         - CSX_CMP_LDREmailController
RICEFW #      - CMP-I-0413
@Created Date - 01/12/2024
@Description  - This class is used to send email to claim associated to LDR.
*/
public with sharing class CSX_CMP_LDREmailController {
	public CSX_CMP_ldrWrapper ldrWrapper { get; set; }
	public LDRProductWrapper ldrProductWrapper { get; set; }
	public string csxLogo { get; set; }

	public Id caseId {
		get;
		set {
			caseId = value;
			getldrDetails();
		}
	}

	public CSX_CMP_ldrWrapper getldrDetails() {
		csxLogo = CSX_CMP_Utility.logoUrl();
		list<CSX_CMP_Equipment__c> ldrDetails = [
			SELECT
				ID,
				CSX_CMP_Equipment_Initial__c,
				CSX_CMP_Equipment_Num__c,
				CSX_CMP_Waybill_Date__c,
				CSX_CMP_Act_Origin_City__c,
				CSX_CMP_Act_Origin_State__c,
				CSX_CMP_Act_Destination_City__c,
				CSX_CMP_Act_Destination_State__c,
				CSX_CMP_LD_Report__r.id,
				CSX_CMP_LD_Report__r.CSX_CMP_Damage_Reason__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Product_Condition__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Damage_Location__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Bracing_Method__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Cause__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Visible_Damage__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Can_Not_Unload__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Unloading_Exceeded_hr__c,
				CSX_CMP_LD_Report__r.CSX_CMP_Disposition__c,
				CSX_CMP_LD_Report__r.name,
				(SELECT ID, CSX_CMP_Quantity__c, CSX_CMP_Product_Description__c FROM Products__r)
			FROM CSX_CMP_Equipment__c
			WHERE Id = :caseId
			WITH SECURITY_ENFORCED
		];

		if (ldrDetails != null && ldrDetails.size() > 0) {
			ldrWrapper = new CSX_CMP_ldrWrapper();
			ldrWrapper.ldrProducts = new List<LDRProductWrapper>();

			ldrWrapper.equipmentInitial = ldrDetails[0].CSX_CMP_Equipment_Initial__c;
			ldrWrapper.equipmentNumber = ldrDetails[0].CSX_CMP_Equipment_Num__c;
			ldrWrapper.dateShipped = CSX_CMP_Utility.formatDate(ldrDetails[0].CSX_CMP_Waybill_Date__c);
			ldrWrapper.originCity = ldrDetails[0].CSX_CMP_Act_Origin_City__c;
			ldrWrapper.originState = ldrDetails[0].CSX_CMP_Act_Origin_State__c;
			ldrWrapper.destinationCity = ldrDetails[0].CSX_CMP_Act_Destination_City__c;
			ldrWrapper.destinationState = ldrDetails[0].CSX_CMP_Act_Destination_State__c;
			ldrWrapper.reason = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Damage_Reason__c;
			ldrWrapper.productCondition = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Product_Condition__c;
			ldrWrapper.locationDamage = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Damage_Location__c;
			ldrWrapper.bracingMethod = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Bracing_Method__c;
			ldrWrapper.causeDamage = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Cause__c;
			ldrWrapper.visiblyDamage = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Visible_Damage__c;
			ldrWrapper.canNotUnload = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Can_Not_Unload__c;
			ldrWrapper.unloadingExceed = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Unloading_Exceeded_hr__c;
			ldrWrapper.dispositionCommodity = ldrDetails[0].CSX_CMP_LD_Report__r.CSX_CMP_Disposition__c;
			ldrWrapper.reportNum = ldrDetails[0].CSX_CMP_LD_Report__r.name;

			if (ldrDetails[0].Products__r != null && ldrDetails[0].Products__r.size() > 0) {
				for (CSX_CMP_Product__c ldrProduct : ldrDetails[0].Products__r) {
					ldrProductWrapper = new LDRProductWrapper();

					ldrProductWrapper.quantity = ldrProduct.CSX_CMP_Quantity__c;
					ldrProductWrapper.description = ldrProduct.CSX_CMP_Product_Description__c;
					ldrWrapper.ldrProducts.add(ldrProductWrapper);
				}
			}
			return ldrWrapper;
		}
		return null;
	}

	public class CSX_CMP_ldrWrapper {
		public String equipmentInitial { get; set; }
		public String equipmentNumber { get; set; }
		public String dateShipped { get; set; }
		public String originCity { get; set; }
		public String originState { get; set; }
		public String destinationCity { get; set; }
		public String destinationState { get; set; }
		public String reason { get; set; }
		public String productCondition { get; set; }
		public String locationDamage { get; set; }
		public String bracingMethod { get; set; }
		public String causeDamage { get; set; }
		public boolean visiblyDamage { get; set; }
		public boolean canNotUnload { get; set; }
		public boolean unloadingExceed { get; set; }
		public decimal estimatedValue { get; set; }
		public String dispositionCommodity { get; set; }
		public String reportNum { get; set; }
		public List<LDRProductWrapper> ldrProducts { get; set; }
	}
	public class LDRProductWrapper {
		public decimal quantity { get; set; }
		public String description { get; set; }
	}
}