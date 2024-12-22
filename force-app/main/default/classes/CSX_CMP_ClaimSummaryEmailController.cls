/**
@Author       - Infosys
@Name         - CSX_CMP_ClaimSummaryEmailController
@RICEFW #     - CMP-E-0428,CMP-R-0443,CMP-E-0411
@Created Date - 03/11/2024
@Description  - This class is used to get the claim details and build the email template to send to the claimant.
*/
public with sharing class CSX_CMP_ClaimSummaryEmailController {
	public ClaimWrapper claimWrapper { get; set; }
	public ClaimLineWrapper claimLineWrapper { get; set; }
	public Boolean renderProductDescription { get; set; }
	public Boolean renderVIN { get; set; }
	public string csxLogo { get; set; }
	public List<ClaimNotesWrapper> claimNotesWrappers { get; set; }

	public Id caseId {
		get;
		set {
			caseId = value;
			getclaimDetails();
		}
	}

	public CSX_CMP_ClaimSummaryEmailController() {
		String caseIdParam = apexpages.currentpage().getparameters().get('id');
		if (caseIdParam != null && this.caseId == null) {
			this.caseId = String.escapeSingleQuotes(caseIdParam).escapeHtml4();
		}
	}
	/*
    @description - This method is used to get the claim details and build the email template to send to the claimant.
    @return - ClaimWrapper
    */
	public ClaimWrapper getclaimDetails() {
		csxLogo = CSX_CMP_Utility.logoUrl();
		renderProductDescription = false;
		claimWrapper = new ClaimWrapper();

		

		Case objclaim = [SELECT id, RecordType.Name from Case where id =: caseId WITH SECURITY_ENFORCED];

		String strQuery = 'SELECT Id,CSX_CMP_Claimant_Ref_Num__c,CSX_CMP_LD_Report_Number__c,CSX_CMP_Supplier_Claimant__r.Name,' + 
						  'CSX_CMP_Claim_Date__c,CSX_CMP_Customer_Claim_Date__c,CSX_CMP_Claim_Amount__c,CaseNumber,CSX_CMP_Claim_Reason__c,' +
						  'recordType.Name,CSX_CMP_Period_End__c,CSX_CMP_Supplier_Claimant_Street__c,CSX_CMP_Supplier_Claimant_City_State_Zip__c,' +
						  'Type,Status,CSX_CMP_Supplier_Claimant__r.Payment_Method__c,CSX_CMP_Desk_Name__r.name,CSX_CMP_Documents_Link__c,' +
						  'CSX_CMP_Terminal__c,CSX_CMP_Period_Begin__c,CSX_CMP_Customer__c,' +
						  'CSX_CMP_Supplier_Claimant_Site__c,CSX_CMP_Supplier_Claimant_Num__c,CSX_CMP_Finance_Charges__c,CSX_CMP_Previous_Claim_Num__c,' +
						  'CSX_CMP_Company_Claim__c,CSX_CMP_Customer__r.Name,CSX_CMP_National_Account_Num__c,CSX_CMP_Past_Due_AR__c,' +
						  'CSX_CMP_Supplier_Claimant__r.BillingAddress,CSX_CMP_Supplier_Claimant__r.BillingCity,'+
						  'CSX_CMP_Supplier_Claimant__r.BillingStreet,CSX_CMP_Supplier_Claimant__r.BillingState,' +
						  'CSX_CMP_Supplier_Claimant__r.BillingPostalcode,CSX_CMP_Supplier_Claimant__r.BillingCountry,CSX_CMP_Case_Number_Formula__c,' +
						  'RecordType.DeveloperName';

						  if(Schema.SObjectType.CSX_CMP_Contract__c.isAccessible()){
							strQuery += ',CSX_CMP_Contract_Num__r.Name';
						  }

		if(objclaim.RecordType.Name == 'Freight'){
			if(Schema.SObjectType.CSX_CMP_Contract__c.isAccessible()){
			strQuery += ',CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c,CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c,' +
						'CSX_CMP_Contract_Num__r.CSX_CMP_Customer_Name__c';	
			}
		}

		strQuery += ',(SELECT Id, CSX_CMP_Note_Type__c, createdDate, CSX_CMP_Notes__c FROM Notes__r ORDER BY createdDate DESC),' +
					'(SELECT Id, CSX_CMP_Related_Claim__c FROM Related_Claims__r),' +
				    '(SELECT Id,Name,CSX_CMP_Amount_Paid__c,CSX_CMP_Payment_Address__c,CSX_CMP_Check__c,CSX_CMP_Check_Amount__c,' +
					'CSX_CMP_Check_Date__c,CSX_CMP_Payment_Amount__c FROM AP_Settlements__r LIMIT 1)';


		strQuery +=	 ' FROM Case WHERE Id = :caseId';
		       
		list<Case> lstCase = (list<Case>) Database.query(strQuery);	
        
		Case claimDetails = lstCase[0];

		if (claimDetails != null) {
			//claimWrapper.claimNumber = claimDetails.CaseNumber;
			claimWrapper.claimNumber = claimDetails.CSX_CMP_Case_Number_Formula__c;
			claimWrapper.claimantName = claimDetails.CSX_CMP_Supplier_Claimant__r.Name;
			claimWrapper.claimantNumber = claimDetails.CSX_CMP_Supplier_Claimant_Num__c;
			claimWrapper.claimAmount = claimDetails.CSX_CMP_Claim_Amount__c;
			claimWrapper.companyFilingClaim = claimDetails.CSX_CMP_Company_Claim__c;
			claimWrapper.claimType = claimDetails.type;
			claimWrapper.claimStatus = claimDetails.Status;
			claimWrapper.nationalAccountNumber = claimDetails.CSX_CMP_National_Account_Num__c;
			claimWrapper.paymentMethod = claimDetails.CSX_CMP_Supplier_Claimant__r.Payment_Method__c;
			claimWrapper.desk = claimDetails.CSX_CMP_Desk_Name__r.name;
			claimWrapper.claimDate = CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Claim_Date__c);
			claimWrapper.type = claimDetails.Type;
			claimWrapper.generalRuleNumber = claimDetails.CSX_CMP_Claim_Reason__c;
			claimWrapper.claimReason = claimDetails.CSX_CMP_Claim_Reason__c;
			if(string.isNotBlank(claimDetails.CSX_CMP_Previous_Claim_Num__c)){
				claimWrapper.previousClaimNumber = claimDetails.CSX_CMP_Previous_Claim_Num__c;//[MR-00776]
			}
			claimWrapper.contractNum = claimDetails.CSX_CMP_Contract_Num__r.Name;
			if(objclaim.RecordType.Name == 'Freight'){
			//	claimWrapper.contractNum = claimDetails.CSX_CMP_Contract_Num__r.Name;
				
				claimWrapper.effectiveDateStart = claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_Start_Date__c)
					: '';
				claimWrapper.effectiveDateEnd = claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Contract_Num__r.CSX_CMP_End_Date__c)
					: '';
			}	

			claimWrapper.contractName = claimDetails.CSX_CMP_Customer__r.Name;
			claimWrapper.submissionDate = claimDetails.CSX_CMP_Customer_Claim_Date__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Customer_Claim_Date__c)
				: claimDetails.CSX_CMP_Claim_Date__c != null
						? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Claim_Date__c)
						: '';
			claimWrapper.movementPeriodBegin = claimDetails.CSX_CMP_Period_Begin__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Period_Begin__c)
				: '';
			claimWrapper.movementPeriodEnd = claimDetails.CSX_CMP_Period_End__c != null
				? CSX_CMP_Utility.formatDate(claimDetails.CSX_CMP_Period_End__c)
				: '';
			claimWrapper.emailDate = CSX_CMP_Utility.formatDate(Date.today());
			claimWrapper.supplierSite = claimDetails.CSX_CMP_Supplier_Claimant_Site__c;
			claimWrapper.supplierStreet = claimDetails.CSX_CMP_Supplier_Claimant_Street__c;
			claimWrapper.supplierCity = claimDetails.CSX_CMP_Supplier_Claimant_City_State_Zip__c;
			claimWrapper.pastDueAr = claimDetails.CSX_CMP_Past_Due_AR__c;
			claimWrapper.financialCharges = claimDetails.CSX_CMP_Finance_Charges__c;
			claimWrapper.documents = claimDetails.CSX_CMP_Documents_Link__c;
			claimWrapper.terminal = claimDetails.CSX_CMP_Terminal__c;
			claimWrapper.recordType = claimDetails.recordType.Name;

			String address =
				claimDetails.CSX_CMP_Supplier_Claimant__r.BillingCity +
				' , ' +
				claimDetails.CSX_CMP_Supplier_Claimant__r.BillingStreet +
				' , ' +
				claimDetails.CSX_CMP_Supplier_Claimant__r.BillingState +
				' , ' +
				claimDetails.CSX_CMP_Supplier_Claimant__r.BillingPostalcode +
				' , ' +
				claimDetails.CSX_CMP_Supplier_Claimant__r.BillingCountry;

			claimWrapper.paymentAddress = address != null ? address : '';

			if (!claimDetails.Related_Claims__r.isEmpty()) {
				String baseUrl = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Case/';
				String relatedCaseId = claimDetails.Related_Claims__r[0].CSX_CMP_Related_Claim__c;
				claimWrapper.caseUrl = baseUrl + relatedCaseId + '/related/Related_Cases__r/view';
			}

			String baseUrl = URL.getOrgDomainURL().toExternalForm() + '/lightning/r/Case/';
			String caseId = claimDetails.id;
			claimWrapper.claimInformation = baseUrl + caseId + '/view';

			claimWrapper.ldrNumbers = new List<String>();
			if(claimDetails.recordType.DeveloperName == 'Freight'){
				if(Schema.SObjectType.CSX_CMP_Related_LD_Report__c.isAccessible()){
					for (CSX_CMP_Related_LD_Report__c relatedCase : [
						SELECT CSX_CMP_LD_Report__r.Name
						FROM CSX_CMP_Related_LD_Report__c
						WHERE CSX_CMP_Claim__c = :caseId
						WITH SECURITY_ENFORCED
					]) {
						if (!claimWrapper.ldrNumbers.isEmpty()) {
							claimWrapper.ldrNumbers.add(',');
						}
						claimWrapper.ldrNumbers.add(relatedCase.CSX_CMP_LD_Report__r.Name);
					}
				}
			}
			

			if (claimDetails.Notes__r != null && !claimDetails.Notes__r.isEmpty()) {
				claimNotesWrappers = new List<ClaimNotesWrapper>();
				Integer explanationNotesCount = 0;
				for (CSX_CMP_Notes__c note : claimDetails.Notes__r) {
					if (note.CSX_CMP_Note_Type__c == 'Summary Comments' && String.isNotBlank(note.CSX_CMP_Notes__c)) {
						claimWrapper.claimDetails = note.CSX_CMP_Notes__c;
					}

					if (
						note.CSX_CMP_Note_Type__c == 'CSX Explanation' &&
						String.isNotBlank(note.CSX_CMP_Notes__c) &&
						explanationNotesCount == 0
					) {
						ClaimNotesWrapper wrapperComment = new ClaimNotesWrapper();
						wrapperComment.creationDate = note.CreatedDate;
						wrapperComment.comment = note.CSX_CMP_Notes__c;
						claimNotesWrappers.add(wrapperComment);
						explanationNotesCount++;
					}
					if (note.CSX_CMP_Note_Type__c == 'Comment' && String.isNotBlank(note.CSX_CMP_Notes__c)) {
						ClaimNotesWrapper wrapper = new ClaimNotesWrapper();
						wrapper.creationDate = note.CreatedDate;
						wrapper.note = note.CSX_CMP_Notes__c;
						claimNotesWrappers.add(wrapper);
					}
				}
			}

			if (claimDetails.AP_Settlements__r != null && !claimDetails.AP_Settlements__r.isEmpty()) {
				claimWrapper.claimPaidAmount = claimDetails.AP_Settlements__r[0].CSX_CMP_Amount_Paid__c;
				claimWrapper.checkNumber = claimDetails.AP_Settlements__r[0].CSX_CMP_Check__c;
				claimWrapper.checkAmount = claimDetails.AP_Settlements__r[0].CSX_CMP_Check_Amount__c;
				claimWrapper.paymentAmount = claimDetails.AP_Settlements__r[0].CSX_CMP_Payment_Amount__c;
				claimWrapper.checkDate = claimDetails.AP_Settlements__r[0].CSX_CMP_Check_Date__c != null
					? CSX_CMP_Utility.formatDate(claimDetails.AP_Settlements__r[0].CSX_CMP_Check_Date__c)
					: '';
			}

			if (claimDetails.recordType.DeveloperName == 'Freight') {
				CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
				equipment = [
					SELECT
						Id,
						Name,
						CSX_CMP_Trace_Link__c,
						CSX_CMP_Consignee__c,
						CSX_CMP_Umler_Link__c,
						CSX_CMP_STCC__c,
						CSX_CMP_STCC_Description__c,
						CSX_CMP_Waybill_Num_Link__c,
						CSX_CMP_Shipper__c,
						CSX_CMP_Equipment_Initial__c,
						CSX_CMP_Waybill_Date__c,
						CSX_CMP_Act_Origin_City__c,
						CSX_CMP_Act_Origin_State__c,
						CSX_CMP_Act_Destination_City__c,
						CSX_CMP_Act_Destination_State__c,
						CSX_CMP_Equipment_Num__c,
						CSX_CMP_Waybill_Num__c
					FROM CSX_CMP_Equipment__c
					WHERE CSX_CMP_Claim__c = :caseId
					WITH SECURITY_ENFORCED
					LIMIT 1
				];
				
				if(equipment !=null){
				
				ClaimLineWrapper claimLineWrapper = new ClaimLineWrapper();
				claimLineWrapper.equipmentInitial = equipment.CSX_CMP_Equipment_Initial__c;
				claimLineWrapper.equipmentNumber = equipment.CSX_CMP_Equipment_Num__c;
				claimLineWrapper.waybillNumber = equipment.CSX_CMP_Waybill_Num__c;
				claimLineWrapper.wayBillDate = equipment.CSX_CMP_Waybill_Date__c != null
					? CSX_CMP_Utility.formatDate(equipment.CSX_CMP_Waybill_Date__c)
					: '';
				claimLineWrapper.origin = equipment.CSX_CMP_Act_Origin_City__c;
				claimLineWrapper.originState = equipment.CSX_CMP_Act_Origin_State__c;
				claimLineWrapper.destination = equipment.CSX_CMP_Act_Destination_City__c;
				claimLineWrapper.destinationState = equipment.CSX_CMP_Act_Destination_State__c;
				claimLineWrapper.stcc = equipment.CSX_CMP_STCC__c;
				claimLineWrapper.stccDescription = equipment.CSX_CMP_STCC_Description__c;
				claimLineWrapper.shipper = equipment.CSX_CMP_Shipper__c;
				claimLineWrapper.consignee = equipment.CSX_CMP_Consignee__c;
				claimLineWrapper.waybillNumberURL = equipment.CSX_CMP_Waybill_Num_Link__c;
				claimLineWrapper.umler = equipment.CSX_CMP_Umler_Link__c;
				claimLineWrapper.trace = equipment.CSX_CMP_Trace_Link__c;
				claimWrapper.codes = new List<String>();
				for (CSX_CMP_Distribution__c code : [
					SELECT CSX_CMP_Code__c
					FROM CSX_CMP_Distribution__c
					WHERE CSX_CMP_Equipment__c = :equipment.Id
					WITH SECURITY_ENFORCED
				]) {
					if (String.isNotBlank(code.CSX_CMP_Code__c)) {
						claimWrapper.codes.add(code.CSX_CMP_Code__c);
					}
				}

				claimLineWrapper.route = String.join(claimWrapper.codes, ' - ');
				claimWrapper.claimLines = new List<ClaimLineWrapper>();
				claimWrapper.claimLines.add(claimLineWrapper);

				List<CSX_CMP_Product__c> productList = [
					SELECT
						Id,
						CSX_CMP_VIN__c,
						CSX_CMP_Product_Description__c,
						CSX_CMP_Quantity__c,
						CSX_CMP_Unit_Price__c,
						CSX_CMP_Product_Amount__c,
						CSX_CMP_UOM__c,
						(
							SELECT Id, CSX_CMP_Area__c, CSX_CMP_Severity__c, CSX_CMP_Type__c, CSX_CMP_Amount__c
							FROM Customer_Damages__r
						),
						(
							SELECT
								Id,
								CSX_CMP_Type__c,
								CSX_CMP_Area__c,
								CSX_CMP_Report_Type__c,
								CSX_CMP_Severity__c,
								CSX_CMP_Source__c
							FROM Inspection_Damages__r
						)
					FROM CSX_CMP_Product__c
					WHERE CSX_CMP_Equipment__c = :equipment.Id
					WITH SECURITY_ENFORCED
				];

				claimWrapper.productList = new List<productWrapper>();
				claimWrapper.productList1 = new List<productWrapper>();
				Decimal totalAmt = 0;
				Decimal totalCustomerDamageAmount = 0;
				renderVIN = null;
				for (CSX_CMP_Product__c pro : productList) {
					if (string.isNotBlank(pro.CSX_CMP_Product_Description__c) && String.isEmpty(pro.CSX_CMP_VIN__c)) {
						renderProductDescription = true;
						renderVIN = renderVIN != null ? renderVIN : false;
						ProductWrapper productWrapper = new ProductWrapper();
						productWrapper.productDescription = pro.CSX_CMP_Product_Description__c;
						productWrapper.quantity = pro.CSX_CMP_Quantity__c;
						productWrapper.uom = pro.CSX_CMP_UOM__c;
						productWrapper.unitPrice = pro.CSX_CMP_Unit_Price__c;
						productWrapper.productAmount = pro.CSX_CMP_Product_Amount__c;
						totalAmt += pro.CSX_CMP_Product_Amount__c != null ? pro.CSX_CMP_Product_Amount__c : 0;
						claimWrapper.productList.add(productWrapper);
					}
					claimWrapper.isDescription = renderProductDescription;
					if (String.isNotBlank(pro.CSX_CMP_VIN__c)) {
						renderVIN = true;
						renderProductDescription = false;
						ProductWrapper productWrapper = new ProductWrapper();
						productWrapper.vin = pro.CSX_CMP_VIN__c;

						productWrapper.customerDamageList = new List<CustomerDamage>();
						productWrapper.inspectionDamageList = new List<InspectionDamage>();

						if (!pro.Customer_Damages__r.isEmpty()) {
							for (CSX_CMP_Customer_Damage__c customerDamage : pro.Customer_Damages__r) {
								CustomerDamage customerDamageWrapper = new CustomerDamage();
								customerDamageWrapper.amount = customerDamage.CSX_CMP_Amount__c;
								customerDamageWrapper.areaCustomer = customerDamage.CSX_CMP_Area__c;
								customerDamageWrapper.typeCustomer = customerDamage.CSX_CMP_Type__c;
								customerDamageWrapper.sevCustomer = customerDamage.CSX_CMP_Severity__c;
								productWrapper.customerDamageList.add(customerDamageWrapper);
								totalCustomerDamageAmount += customerDamage.CSX_CMP_Amount__c != null
									? customerDamage.CSX_CMP_Amount__c
									: 0;
							}
						}

						if (!pro.Inspection_Damages__r.isEmpty()) {
							for (CSX_CMP_Inspection_Damage__c inspectionDamage : pro.Inspection_Damages__r) {
								InspectionDamage inspectionDamageWrapper = new InspectionDamage();
								inspectionDamageWrapper.typeInspection = inspectionDamage.CSX_CMP_Type__c;
								inspectionDamageWrapper.areaInspection = inspectionDamage.CSX_CMP_Area__c;
								inspectionDamageWrapper.reportTypeInspection = inspectionDamage.CSX_CMP_Report_Type__c;
								inspectionDamageWrapper.sevInspection = inspectionDamage.CSX_CMP_Severity__c;
								inspectionDamageWrapper.sourceInspection = inspectionDamage.CSX_CMP_Source__c;
								productWrapper.inspectionDamageList.add(inspectionDamageWrapper);
							}
						}
						claimWrapper.productList1.add(productWrapper);
					}
				}
				claimWrapper.vinAvailable = renderVIN != null ? renderVIN : false;
				claimWrapper.totalAmt = totalAmt;
				claimWrapper.totalCustomerDamageAmount = totalCustomerDamageAmount;
			}
			}

			List<CSX_CMP_Claim_Line__c> claimLines = new List<CSX_CMP_Claim_Line__c>();
			if (claimDetails.recordType.DeveloperName != 'Freight') {
				claimLines = [
					SELECT
						Id,
						CSX_CMP_Unit_Type__c,
						CSX_CMP_No_of_Cars__c,
						CSX_CMP_Weight_in_Tons__c,
						CSX_CMP_Unit_Refund_Price__c,
						CSX_CMP_Act_Origin_City__c,
						CSX_CMP_Act_Origin_State__c,
						CSX_CMP_Act_Destination_City__c,
						CSX_CMP_Act_Destination_State__c,
						CSX_CMP_Equipment_Initial__c,
						CSX_CMP_Equipment_Num__c,
						CSX_CMP_Waybill_Num__c,
						CSX_CMP_STCC__c,
						CSX_CMP_Waybill_Date__c,
						CSX_CMP_Claim_Amount__c,
						CSX_CMP_Freight_Bill_Num__c,
						CSX_CMP_Freight_Bill_Date__c,
						CSX_CMP_BoL_Num__c,
						CSX_CMP_BoL_Date__c,
						CSX_CMP_Original_Amount__c,
						CSX_CMP_Received_Amount__c,
						CSX_CMP_Commodity_Num__c,
						CSX_CMP_URRWIN_Num__c,
						CSX_CMP_URRWIN_Date__c,
						CSX_CMP_STCC_Description__c,
						CSX_CMP_Waybill_Num_Link__c
					FROM CSX_CMP_Claim_Line__c
					WHERE CSX_CMP_Claim__c = :caseId
					WITH SECURITY_ENFORCED
				];

				claimWrapper.claimLines = new List<ClaimLineWrapper>();
				for (CSX_CMP_Claim_Line__c claimLine : claimLines) {
					claimLineWrapper = new ClaimLineWrapper();
					claimLineWrapper.type = claimLine.CSX_CMP_Unit_Type__c;

					if (claimLineWrapper.type == 'Cars') {
						claimLineWrapper.carsWeight = claimLine.CSX_CMP_No_of_Cars__c;
					} else if (claimLineWrapper.type == 'Weight(in Tons)') {
						claimLineWrapper.carsWeight = claimLine.CSX_CMP_Weight_in_Tons__c;
					}

					claimLineWrapper.invoice = claimLine.CSX_CMP_Freight_Bill_Num__c;
					claimLineWrapper.urrwin = claimLine.CSX_CMP_URRWIN_Num__c;
					claimLineWrapper.urrwinDate = claimLine.CSX_CMP_URRWIN_Date__c != null
						? CSX_CMP_Utility.formatDate(claimLine.CSX_CMP_URRWIN_Date__c)
						: '';
					claimLineWrapper.invoiceDate = claimLine.CSX_CMP_Freight_Bill_Date__c != null
						? CSX_CMP_Utility.formatDate(claimLine.CSX_CMP_Freight_Bill_Date__c)
						: '';
					claimLineWrapper.cars = claimLine.CSX_CMP_No_of_Cars__c;
					claimLineWrapper.origin = claimLine.CSX_CMP_Act_Origin_City__c;
					claimLineWrapper.originState = claimLine.CSX_CMP_Act_Origin_State__c;
					claimLineWrapper.destination = claimLine.CSX_CMP_Act_Destination_City__c;
					claimLineWrapper.destinationState = claimLine.CSX_CMP_Act_Destination_State__c;
					claimLineWrapper.commodity = claimLine.CSX_CMP_Commodity_Num__c;
					claimLineWrapper.equipmentInitial = claimLine.CSX_CMP_Equipment_Initial__c;
					claimLineWrapper.equipmentNumber = claimLine.CSX_CMP_Equipment_Num__c;
					claimLineWrapper.wayBillNumber = claimLine.CSX_CMP_Waybill_Num__c;
					claimLineWrapper.wayBillDate = claimLine.CSX_CMP_Waybill_Date__c != null
						? CSX_CMP_Utility.formatDate(claimLine.CSX_CMP_Waybill_Date__c)
						: '';
					claimLineWrapper.bol = claimLine.CSX_CMP_BoL_Num__c;
					claimLineWrapper.bolDate = claimLine.CSX_CMP_BoL_Date__c != null
						? CSX_CMP_Utility.formatDate(claimLine.CSX_CMP_BoL_Date__c)
						: '';
					claimLineWrapper.amountPaid = claimLine.CSX_CMP_Original_Amount__c;
					claimLineWrapper.correctAmount = claimLine.CSX_CMP_Received_Amount__c;
					claimLineWrapper.claimAmounts = claimLine.CSX_CMP_Claim_Amount__c;
					claimLineWrapper.refundUnitPrice = claimLine.CSX_CMP_Unit_Refund_Price__c;
					claimLineWrapper.stcc = claimLine.CSX_CMP_STCC__c;
					claimLineWrapper.stccDescription = claimLine.CSX_CMP_STCC_Description__c;
					claimLineWrapper.waybillNumberURL = claimLine.CSX_CMP_Waybill_Num_Link__c;
					claimWrapper.claimLines.add(claimLineWrapper);
				}
			}

			claimWrapper.companyName = claimDetails.CSX_CMP_Customer__r.Name;
		}

		return claimWrapper;
	}

	public class ClaimWrapper {
		public String emailDate { get; set; }
		public String claimNumber { get; set; }
		public String previousClaimNumber{get;set;} //[MR-00776]
		public String claimDetails { get; set; }
		public String claimStatus { get; set; }
		public String recordType { get; set; }
		public String generalRuleNumber { get; set; }
		public String claimReason { get; set; }

		public String desk { get; set; }
		public String claimDate { get; set; }
		public String claimantName { get; set; }
		public String claimantNumber { get; set; }
		public Decimal claimAmount { get; set; }

		public Decimal claimPaidAmount { get; set; }
		public String paymentMethod { get; set; }
		public String paymentAddress { get; set; }
		public String payAddress { get; set; }
		public String checkNumber { get; set; }

		public Decimal checkAmount { get; set; }
		public String checkDate { get; set; }
		public String movementPeriodBegin { get; set; }
		public String movementPeriodEnd { get; set; }
		public String contractName { get; set; }

		public String effectiveDateStart { get; set; }
		public String effectiveDateEnd { get; set; }
		public String emailAddress { get; set; }
		public String companyFilingClaim { get; set; }
		public String contractNum { get; set; }

		public Decimal paymentAmount { get; set; }
		public String companyName { get; set; }
		public String submissionDate { get; set; }
		public String vin { get; set; }
		public String claimType { get; set; }

		public String priceAuthority { get; set; }
		public String documents { get; set; }
		public String caseUrl { get; set; }
		public String claimInformation { get; set; }
		public Decimal totalAmt { get; set; }

		public Decimal totalCustomerDamageAmount { get; set; }
		public string type { get; set; }
		public string terminal { get; set; }
		public String nationalAccountNumber { get; set; }
		public String supplierSite { get; set; }

		public String supplierStreet { get; set; }
		public String supplierCity { get; set; }
		public decimal pastDueAr { get; set; }
		public decimal financialCharges { get; set; }
		public Boolean vinAvailable { get; set; }

		public Boolean isDescription { get; set; }
		public List<String> ldrNumbers { get; set; }
		public List<String> codes { get; set; }
		public List<ProductWrapper> productList { get; set; }
		public List<ProductWrapper> productList1 { get; set; }
		public List<ClaimLineWrapper> claimLines { get; set; }
	}
	public class ProductWrapper {
		public string vin { get; set; }
		public String productDescription { get; set; }
		public decimal quantity { get; set; }
		public string uom { get; set; }
		public decimal unitPrice { get; set; }
		public decimal productAmount { get; set; }
		public List<CustomerDamage> customerDamageList { get; set; }
		public List<InspectionDamage> inspectionDamageList { get; set; }
		public decimal getTotalCustomerDamageAmount { get; set; }
	}

	public class CustomerDamage {
		public decimal amount { get; set; }
		public string areaCustomer { get; set; }
		public string typeCustomer { get; set; }
		public string sevCustomer { get; set; }
	}

	public class InspectionDamage {
		public string typeInspection { get; set; }
		public string areaInspection { get; set; }
		public string reportTypeInspection { get; set; }
		public string sevInspection { get; set; }
		public string sourceInspection { get; set; }
	}

	public class ClaimLineWrapper {
		// common fields
		public String wayBillNumber { get; set; }
		public String wayBillDate { get; set; }
		public String equipmentInitial { get; set; }
		public String equipmentNumber { get; set; }
		public String origin { get; set; }
		public String originState { get; set; }
		public String destination { get; set; }
		public String destinationState { get; set; }
		public string stcc { get; set; }

		// Claim Line Fields
		public String type { get; set; }
		public Decimal carsWeight { get; set; }
		public Decimal cars { get; set; }
		public String commodity { get; set; }
		public Decimal claimAmounts { get; set; }
		public String invoice { get; set; }
		public String invoiceDate { get; set; }
		public String bol { get; set; }
		public String bolDate { get; set; }
		public decimal amountPaid { get; set; }
		public decimal correctAmount { get; set; }
		public String urrwin { get; set; }
		public String urrwinDate { get; set; }
		public decimal refundUnitPrice { get; set; }

		// Equipment Fields
		public String route { get; set; } //
		public String stccDescription { get; set; } //
		public String shipper { get; set; }
		public String consignee { get; set; }

		public String umler { get; set; } //
		public String trace { get; set; }
		public string waybillNumberURL { get; set; } //
		public String mti { get; set; } //
	}
	public class ClaimNotesWrapper {
		public String comment { get; set; }
		public String note { get; set; }
		public DateTime creationDate { get; set; }
	}
}