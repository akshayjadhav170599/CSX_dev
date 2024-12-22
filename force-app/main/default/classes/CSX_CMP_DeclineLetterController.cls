/**************************************************************************************

@Author       - Infosys
@Name         - CSX_CMP_DeclineLetterController
@Created Date - 11/18/2023
@Description  - Class for Claim Decline Letter VF Page and related operations.
@RICEFW reference - CMP-E-0458 and CMP-E-0493

*************************************************************************************/
public with sharing class CSX_CMP_DeclineLetterController {
	public CSX_CMP_claimWrapper claimWrapper { get; set; }	
	public string csxLogo { get; set; }
	public Id caseId {
		get;
		set {
			caseId = value;
			getclaimDetails();
		}
	}

	public CSX_CMP_claimWrapper getclaimDetails() {
        Case claim = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED LIMIT 1];
		csxLogo = CSX_CMP_Utility.logoUrl();
		claimWrapper = new CSX_CMP_claimWrapper();
		Case claimDetails;
		String query = 'Select CSX_CMP_Settled_Date__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c,CSX_CMP_Decline_Code__r.CSX_CMP_Description__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c,CSX_CMP_Decline_Code__r.CSX_CMP_Email_Message__c,CSX_CMP_Supplier_Claimant__r.Name,CSX_CMP_Claim_Date__c,CSX_CMP_Customer_Claim_Date__c,CSX_CMP_Claim_Amount__c,CaseNumber,CSX_CMP_Customer__c,CSX_CMP_Customer__r.Name,Owner.name,owner.title,owner.email,type,RecordType.name,CSX_CMP_Period_Begin__c,CSX_CMP_Period_End__c,CSX_CMP_Company_Claim__c,CSX_CMP_Supplier_Claimant_Num__c,CSX_CMP_Claimant_Ref_Num__c,CSX_CMP_Claim_Reason__c,Contact.name,ContactPhone,Contact.Email, CSX_CMP_Previous_Claim_Num__c,CSX_CMP_Case_Number_Formula__c,';
		if (claim.RecordType.DeveloperName == 'Revenue_Contract_Refund') {
			query += 'CSX_CMP_Contract_Num__r.Name,CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c,CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c,CSX_CMP_Contract_Num__r.CSX_CMP_Customer_Name__r.name,';
		}

		if (claim.RecordType.DeveloperName == 'Freight') {
			query += '(select Id,Name,CSX_CMP_Waybill_Date__c,CSX_CMP_Equipment_Num__c,CSX_CMP_Waybill_Num__c from Equipments__r),';
		}
		query += '(select Id,CSX_CMP_Note_Type__c,CSX_CMP_Notes__c from Notes__r WHERE CSX_CMP_Note_Type__c =\'Decline Reason\' ORDER BY CreatedDate DESC),(select Id,Name,CSX_CMP_Person__c,CSX_CMP_Zip_Code__c,CSX_CMP_City__c,CSX_CMP_State__c,CSX_CMP_Telephone__c,CSX_CMP_Address1__c,CSX_CMP_Address2__c,CSX_CMP_Emails__c FROM Claim_Contacts__r ORDER BY CreatedDate DESC ) FROM Case  where Id =: caseId WITH SECURITY_ENFORCED LIMIT 1';

		claimDetails = Database.query(query);
		
		if (claimDetails != null) {
			claimWrapper.csxClaimNumber = claimDetails.CSX_CMP_Case_Number_Formula__c;
			claimWrapper.recordType = claimDetails.RecordType.name;
			claimWrapper.claimantName = claimDetails.CSX_CMP_Supplier_Claimant__r.Name;
			claimWrapper.claimantNumber = claimDetails.CSX_CMP_Supplier_Claimant_Num__c;
			claimWrapper.claimAmount = claimDetails.CSX_CMP_Claim_Amount__c;
			claimWrapper.emailDate = CSX_CMP_Utility.formatDate(Date.today());
			claimWrapper.submissionDate = claimDetails.CSX_CMP_Claim_Date__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Claim_Date__c)
				: '';
			claimWrapper.claimBegin = claimDetails.CSX_CMP_Period_Begin__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Period_Begin__c)
				: '';
			claimWrapper.claimEnd = claimDetails.CSX_CMP_Period_End__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Period_End__c)
				: '';
			if (claim.RecordType.DeveloperName == 'Revenue_Contract_Refund') {
				claimWrapper.contractName = claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_Customer_Name__r.name;
				claimWrapper.contractNumber = claimDetails.CSX_CMP_Contract_Num__r.Name;
				claimWrapper.contractStartDate = claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c)
					: '';
				claimWrapper.contractEndDate = claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c)
					: '';
			}
			claimWrapper.claimantClaimNumber = claimDetails.CSX_CMP_Claimant_Ref_Num__c;
			claimWrapper.reason = claimDetails.CSX_CMP_Claim_Reason__c;
			claimWrapper.companyFilingClaim = claimDetails.CSX_CMP_Company_Claim__c;
			claimWrapper.owner = claimDetails.Owner.name;
			claimWrapper.title = claimDetails.owner.title;
			claimWrapper.email = claimDetails.owner.email;
			claimWrapper.previousClaimNumber = claimDetails.CSX_CMP_Previous_Claim_Num__c; //[MR-00776]
            if(claimDetails.Notes__r != null && !claimDetails.Notes__r.isEmpty()){ 
                claimWrapper.declineNotes  = claimDetails.Notes__r[0].CSX_CMP_Notes__c;
             }

			 if (claim.RecordType.DeveloperName == 'Freight') {
				if (String.isNotBlank(claimDetails.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c)) {
					claimWrapper.carrierAlphaCode = claimDetails.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c;
				}
			}else{
				if (String.isNotBlank(claimDetails.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c)) {
					claimWrapper.carrierAlphaCode = claimDetails.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c;
				}
			}

			if (!claimDetails.Claim_Contacts__r.isEmpty()) {
				claimWrapper.contactName = claimDetails.Claim_Contacts__r[0].CSX_CMP_Person__c;
				claimWrapper.contactPhone = claimDetails.Claim_Contacts__r[0].CSX_CMP_Telephone__c;
				claimWrapper.contactEmail = claimDetails.Claim_Contacts__r[0].CSX_CMP_Emails__c;
				claimWrapper.address1 = claimDetails.Claim_Contacts__r[0].CSX_CMP_Address1__c;
				claimWrapper.address2 = claimDetails.Claim_Contacts__r[0].CSX_CMP_Address2__c;
			/*	claimWrapper.cityStateZip =
					claimDetails.Claim_Contacts__r[0].CSX_CMP_City__c +
					' ' +
					claimDetails.Claim_Contacts__r[0].CSX_CMP_State__c +
					' ' +
					claimDetails.Claim_Contacts__r[0].CSX_CMP_Zip_Code__c; */

					claimWrapper.cityStateZip = 
                    (String.isNotBlank(claimDetails.Claim_Contacts__r[0].CSX_CMP_City__c) ? claimDetails.Claim_Contacts__r[0].CSX_CMP_City__c : '') +
                    (String.isNotBlank(claimDetails.Claim_Contacts__r[0].CSX_CMP_State__c) ? ' ' + claimDetails.Claim_Contacts__r[0].CSX_CMP_State__c : '') +
                    (String.isNotBlank(claimDetails.Claim_Contacts__r[0].CSX_CMP_Zip_Code__c) ? ' ' + claimDetails.Claim_Contacts__r[0].CSX_CMP_Zip_Code__c : '');
			}
			claimWrapper.declineCodeDescription = claimDetails.CSX_CMP_Decline_Code__r.CSX_CMP_Description__c;
			claimWrapper.declineDate = CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Settled_Date__c);
            claimWrapper.declineEmailMessage = claimDetails.CSX_CMP_Decline_Code__r.CSX_CMP_Email_Message__c;

			if (!claimDetails.Equipments__r.isEmpty()) {
				claimWrapper.equipmentNumber = claimDetails.Equipments__r[0].Name;
				claimWrapper.wayBillNumber = claimDetails.Equipments__r[0].CSX_CMP_Waybill_Num__c;
				claimWrapper.wayBillDate = claimDetails.Equipments__r[0].CSX_CMP_Waybill_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.Equipments__r[0].CSX_CMP_Waybill_Date__c)
					: '';
			}
			
		}
		return claimWrapper;
	}

	public CSX_CMP_DeclineLetterController() {
		String caseIdParam = apexpages.currentpage().getparameters().get('id');
		if (caseIdParam != null) {
			this.caseId = String.escapeSingleQuotes(caseIdParam).escapeHtml4();
		}
	}

	public class CSX_CMP_claimWrapper {
		public String emailDate { get; set; }
		public String csxClaimNumber { get; set; }
		public String upClaimNumber { get; set; }
		public String claimDeclineDate { get; set; }
		public String managerOverchargeClaims { get; set; }
		public String claimantName { get; set; }
		public String claimantNumber { get; set; }
		public Decimal claimAmount { get; set; }
		public String equipmentNumber { get; set; }
		public String wayBillNumber { get; set; }
		public String wayBillDate { get; set; }
		public String contractName { get; set; }
		public String contractNumber { get; set; }
		public String contractStartDate { get; set; }
		public String contractEndDate { get; set; }
		public String submissionDate { get; set; }
		public String claimBegin { get; set; }
		public String claimEnd { get; set; }
		public String adhocNotes { get; set; }
		public String claimantClaimNumber { get; set; }
		public String reason { get; set; }
		public String companyFilingClaim { get; set; }
		public String contactName { get; set; }
		public String contactPhone { get; set; }
		public String contactEmail { get; set; }
		public String address1 { get; set; }
		public String address2 { get; set; }
		public String cityStateZip { get; set; }
		public String declineCodeDescription { get; set; }
		public String declineDate { get; set; }
		public String owner { get; set; }
		public String title { get; set; }
		public String email { get; set; }
		public String recordType { get; set; }
		public String carrierAlphaCode { get; set; }
		public String previousClaimNumber { get; set; } //[MR-00776]
        public String declineEmailMessage {get; set;}
        public String declineNotes {get; set;}
        
	}
	
}