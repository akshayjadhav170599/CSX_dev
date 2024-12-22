/**************************************************************************************
Apex Class Name     : CSX_CMP_3rdPartyWebService
Function            : This class is to send or update email preferences information on Contact for 3rd party contractors
Author              : Infosys
Modification Log    :
* Developer         : Date             Description
* ----------------------------------------------------------------------------                 
* Infosys           28/03/2024        First version of this class.
*************************************************************************************/
@RestResource(urlMapping='/v1/contacts/*/email-subscriptions')
global with sharing class CSX_CMP_3rdPartyWebService {
	/*
    @description: This method is used to fetch the invoice email subscriptions for the given RACF ID
    @param: racfId
    @return: invoiceSummaryNotification, invoiceNotificationPDF, invoiceNotificationsOtherEmails
    RICEFW - CMP-I-0786
    */
	@HttpGet
	global static void fetchInvEmailSubscriptions() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req = RestContext.request;
		res = RestContext.response;
		ThirdPartyWrapper contactWrapper = new ThirdPartyWrapper();
		try {
			List<String> urlParts = req.requestURI.toString().split('/');
			String racfId = urlParts.get(urlParts.size() - 2);
			if (racfId == null || racfId == '' || racfId == 'null') {
				res.statusCode = 400;
				res.responseBody = Blob.valueOf('Invalid Request');
				return;
			}
			String query = 'SELECT Id,CSX_CMP_Invoice_Summary_Notification__c, CSX_CMP_Inv_Notif_PDF_Attach__c, CSX_CMP_Inv_Notif_Other_Emails__c FROM Contact WHERE CSX_CMP_RACF_ID__c = :racfId LIMIT 1';
			List<Contact> contactList = Database.query(query);
			if (!contactList.isEmpty() && contactList != null && contactList.size() > 0) {
				Contact contact = contactList[0];
				contactWrapper.invoiceNotificationPDF = contact.CSX_CMP_Inv_Notif_PDF_Attach__c;
				contactWrapper.invoiceNotificationsOtherEmails = contact.CSX_CMP_Inv_Notif_Other_Emails__c;
				res.statusCode = 200;
				res.responseBody = Blob.valueOf(JSON.serialize(contactWrapper));
				res.addHeader('Content-Type', 'application/json');
				// res.responseBody = Blob.valueOf('{"message" : "' + JSON.serialize(contactWrapper) + '"}');
				// res.responseBody = Blob.valueOf('{ "errorMessage" : "' +e.getMessage()+'" }');
			} else {
				res.statusCode = 404;
                res.addHeader('Content-Type', 'application/json');
				res.responseBody = Blob.valueOf('No Contact found with the given RACF ID');
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'Fetch 3rd Party Invoices',
				req.requestURI.toString(),
				''
			);
		}
	}

	/*
    @description: This method is used to update the invoice email subscriptions for the given RACF ID
    @param: racfId, invoiceSummaryNotification, invoiceNotificationPDF, invoiceNotificationsOtherEmails
    @return: Success message
    RICEFW - CMP-I-0866
    */
	@HttpPost
	global static void updateInvEmailSubscriptions() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req = RestContext.request;
		res = RestContext.response;

		try {
			List<String> urlParts = req.requestURI.toString().split('/');
			String racfId = urlParts.get(urlParts.size() - 2);
			if (racfId == null || racfId == '' || racfId == 'null') {
				res.statusCode = 400;
				res.responseBody = Blob.valueOf('Invalid Request');
				return;
			}

			Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
			String query = 'SELECT Id,CSX_CMP_Invoice_Summary_Notification__c, CSX_CMP_Inv_Notif_PDF_Attach__c, CSX_CMP_Inv_Notif_Other_Emails__c FROM Contact WHERE CSX_CMP_RACF_ID__c = :racfId LIMIT 1';
			List<Contact> contactList = Database.query(query);
			if (!contactList.isEmpty()) {
				Contact contact = contactList[0];
				contact.CSX_CMP_Inv_Notif_PDF_Attach__c = (Boolean) wrapper.get('invoiceNotificationPDF');
				contact.CSX_CMP_Inv_Notif_Other_Emails__c = (String) wrapper.get('invoiceNotificationsOtherEmails');
				Database.saveResult sr = Database.update(contact, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_3rdPartyWebService',
					'pushInvEmailSubscriptions',
					sr,
					'Contact'
				);
				res.statusCode = 201;
				res.addHeader('Content-Type', 'application/json');
				res.responseBody = Blob.valueOf('Invoice Email subscription preference updated successfully');
				// res.responseBody = Blob.valueOf('Invoice Email subscription preference updated successfully');
			} else {
				res.statusCode = 404;
                res.addHeader('Content-Type', 'application/json');
				res.responseBody = Blob.valueOf('No Contact found with the given RACF ID');
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'Fetch 3rd Party Invoices',
				req.requestURI.toString(),
				''
			);
			res.statusCode = 500;
			res.responseBody = Blob.valueOf('Error updating the Contact');
		}
	}

	global class ThirdPartyWrapper {
		public Boolean invoiceNotificationPDF;
		public String invoiceNotificationsOtherEmails;
	}
}