/*
RICEF ID : CMP-I-0909
@author : Infosys
@description : Webservice for ShipCSX to fetch 3rd party contractor invoices
*/

@RestResource(urlMapping='/v1/automotive-contractor-invoices/search/*')
global with sharing class CSX_CMP_FetchInvoiceWebservice {
	/**
    @description: This method is used to fetch the invoice details based on the given parameters
    @param: companyName, sapAccountNumber, invoiceStatus, incidentLocation, invoiceFromDate, invoiceToDate, invoiceNumber, claimNumber, vinNumber
    @return: List of invoice details
     */
	@HttpPost
	global static void fetchinvoiceDetails() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		// Map<String, String> invoiceDetails = req.params;
		string request;
		try {
			req = RestContext.request;
			res = RestContext.response;
			RequestWrapper requestWrapper = new RequestWrapper();
			Map<String, object> reqpmap = (Map<String, object>) JSON.deserializeUntyped(req.requestBody.toString());
			List<Object> objList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(reqpmap.get('customerNumber')));
			requestWrapper.customerNumber = (List<String>) JSON.deserialize(JSON.serialize(objList), List<String>.class);
			requestWrapper.invoiceNumber = (String) reqpmap.get('invoiceNumber');

			Boolean isValid = false;
			if (!requestWrapper.customerNumber.isEmpty()) {
				isValid = true;
			}

			if (!isValid) {
				// CSX_CMP_LoggerUtility.addIntegrationErrorLog('Request Parameters are missing', 'Send 3rd party invoice', req.requestURI.toString(),'');
				res.responseBody = Blob.valueOf('Missing required Parameters');
				res.statusCode = 404;
				return;
			}

			String query = 'SELECT Id,CSX_CMP_Party_Name__r.Name,CSX_CMP_AR_Settlement__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Number__c, CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.CSX_CMP_Age__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.caseNumber,CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Date__c, CSX_CMP_AR_Settlement__r.CSX_CMP_Scheduled_Pay_Date__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Payment_Status__c,CSX_CMP_Party_Name__r.AccountNumber,CSX_CMP_Incident_Location__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.CSX_CMP_VIN__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Balance_Due__c,CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Amount__c FROM CSX_CMP_3rd_Party__c';

			List<String> whereClause = new List<String>();
			whereClause.add('CSX_CMP_AR_Settlement__c != null ');

			if (!requestWrapper.customerNumber.isEmpty()) {
				String customerNumberStr = String.join(requestWrapper.customerNumber, '\',\'');
				whereClause.add('CSX_CMP_Party_Name__r.AccountNumber IN (\'' + customerNumberStr + '\')');
			}

			if (String.isNotBlank(requestWrapper.invoiceNumber)) {
				whereClause.add(
					'CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Number__c = \'' +
					String.escapeSingleQuotes(requestWrapper.invoiceNumber) +
					'\''
				);
			}

			String whereClauseStr = '';
			if (!whereClause.isEmpty()) {
				whereClauseStr = String.join(whereClause, ' AND ');
			}
			query = query + ' WHERE ' + whereClauseStr;

			List<CSX_CMP_3rd_Party__c> invoiceList = Database.query(query);

			if (invoiceList.isEmpty()) {
				res.responseBody = Blob.valueOf('Invoices not Found for the given Customer');
				res.statusCode = 404;
				return;
			}

			Set<Id> arSettlementIds = new Set<Id>();
			for (CSX_CMP_3rd_Party__c invoice : invoiceList) {
				arSettlementIds.add(invoice.CSX_CMP_AR_Settlement__c);
			}

			Map<Id, CSX_CMP_AR_Settlement__c> arSettlementMap = new Map<Id, CSX_CMP_AR_Settlement__c>(
				[
					SELECT
						Id,
						(
							SELECT
								CSX_CMP_Remit_Amount__c,
								CSX_CMP_Remit_Date__c,
								CSX_CMP_Remit_Number__c,
								CSX_CMP_Paid_Amount__c,
								CSX_CMP_Adjusted_Amount__c
							FROM Payment_Transactions__r
						)
					FROM CSX_CMP_AR_Settlement__c
					WHERE Id IN :arSettlementIds
				]
			);

			List<ThirdPartyInvoiceWrapper> invoiceWrapperList = new List<ThirdPartyInvoiceWrapper>();
			if (invoiceList != null && !invoiceList.isEmpty()) {
				for (CSX_CMP_3rd_Party__c invoice : invoiceList) {
					ThirdPartyInvoiceWrapper invoiceWrapper = new ThirdPartyInvoiceWrapper();
					invoiceWrapper.companyName = invoice.CSX_CMP_Party_Name__r.Name;
					invoiceWrapper.customerNumber = invoice.CSX_CMP_Party_Name__r.AccountNumber;
					invoiceWrapper.invoiceNumber = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Number__c;
					invoiceWrapper.claimNumber = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.caseNumber;
					invoiceWrapper.invoiceStatus = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Payment_Status__c;
					invoiceWrapper.incidentLocation = invoice.CSX_CMP_Incident_Location__c;
					invoiceWrapper.vinNumber = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.CSX_CMP_VIN__c;
					invoiceWrapper.invoiceDate = (Date) invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Date__c;
					invoiceWrapper.dueDate = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Scheduled_Pay_Date__c;
					invoiceWrapper.age = (Integer) invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Claim__r.CSX_CMP_Age__c;
					invoiceWrapper.billAmount = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Invoice_Amount__c;
					invoiceWrapper.balanceDue = invoice.CSX_CMP_AR_Settlement__r.CSX_CMP_Balance_Due__c;
					if (!arSettlementMap.get(invoice.CSX_CMP_AR_Settlement__c).Payment_Transactions__r.isEmpty()) {
						for (
							CSX_CMP_Payment_Transactions__c remit : arSettlementMap.get(invoice.CSX_CMP_AR_Settlement__c)
								.Payment_Transactions__r
						) {
							RemitDetails remitDetails = new RemitDetails();
							remitDetails.remitAmount = remit.CSX_CMP_Remit_Amount__c;
							remitDetails.remitNumber = remit.CSX_CMP_Remit_Number__c;
							remitDetails.remitDate = remit.CSX_CMP_Remit_Date__c;
							remitDetails.adjustedAmount = remit.CSX_CMP_Adjusted_Amount__c;
							remitDetails.paidAmount = remit.CSX_CMP_Paid_Amount__c;
							invoiceWrapper.remitDetails.add(remitDetails);
						}
					}
					invoiceWrapperList.add(invoiceWrapper);
				}
			}

			if (!invoiceWrapperList.isEmpty()) {
				res.responseBody = Blob.valueOf(JSON.serialize(invoiceWrapperList));
				res.statusCode = 200;
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'Send 3rd party invoice',
				req.requestURI.toString(),
				''
			);
		}
	}

	public class ThirdPartyInvoiceWrapper {
		public string companyName; // AR Settlement - PartyName
		public string customerNumber; // AR Settlement - PartyName - AccountNumber
		public string invoiceNumber; // AR Settlement - InvoiceNumber
		public string claimNumber; // Case - CaseNumber
		public string invoiceStatus; // AR Settlement - InvoicePaymentStatus
		public string incidentLocation; // 3rd Party - IncidentLocation
		public string vinNumber; // AR Settlement - Claim - VIN
		public Date invoiceDate; // AR Settlement - InvoiceDate
		public Date dueDate; // AR Settlement - ScheduledPayDate
		public Integer age; // AR Settlement - Claim - Age
		public Decimal billAmount; // AR Settlement - InvoiceAmount
		public Decimal balanceDue; // AR Settlement - BalanceDue
		// public Blob     invoicePDF; // Invoice PDF - generated from VF page
		List<RemitDetails> remitDetails;

		public ThirdPartyInvoiceWrapper() {
			remitDetails = new List<RemitDetails>();
		}
	}

	public class RemitDetails {
		public Decimal remitAmount; // Payment Transactions - RemitAmount
		public String remitNumber; // Payment Transactions - RemitNumber
		public Date remitDate; // Payment Transactions - RemitDate
		public Decimal adjustedAmount; // Payment Transactions - AdjustedAmount
		public Decimal paidAmount; // Payment Transactions - PaidAmount
	}

	public class RequestWrapper {
		public List<String> customerNumber;
		public String invoiceNumber;
	}
}