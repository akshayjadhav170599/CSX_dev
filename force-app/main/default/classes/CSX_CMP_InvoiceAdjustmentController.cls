/**************************************************************************************
Apex Class Name     : CSX_CMP_InvoiceAdjustmentController
Function            : Class to send invoice emailhttps://csx-claims-dev--dev.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage#, update Invoice Amount, Cancel Invoice.
RICEFW #            : CMP-I-0491
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           04/10/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_InvoiceAdjustmentController { 
	/*
        @description : method to quary the data based on AR settlement Id 
        @param : arSettlementId
        @return : List<ARInvoiceWrapper>
    */
	@AuraEnabled
	public static ARInvoiceWrapper fetchARrecordDetails(Id arSettlementId) {
		ARInvoiceWrapper newObj = new ARInvoiceWrapper();
		try {
			CSX_CMP_AR_Settlement__c arRecordDetails = getARDetails(arSettlementId);
			newObj.invoiceNumber = arRecordDetails.CSX_CMP_Invoice_Number__c;
			newObj.invoiceAmount = arRecordDetails.CSX_CMP_Invoice_Amount__c;
			newObj.invoiceStatus = arRecordDetails.CSX_CMP_Invoice_Payment_Status__c;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_InvoiceAjustmentController',
				'fetchARrecordDetails',
				arSettlementId,
				e
			);
		}
		return newObj;
	}

	/*
        @description : method to update the invoice amount with new invoice amount
        @param : arSettlementId,invoiceAmount
        @return : String
    */
	@AuraEnabled
    public static String updateInvoiceAmount(Id arSettlementId,Decimal invoiceAmount,String createdDate){
        String recId;
		Database.SaveResult insertnewRecord;
        try{
			String updatestatus='';
            string cancellationReason= '01';
			String invoiceStatus='';
            CSX_CMP_AR_Settlement__c oldARrecord = getARDetails(arSettlementId);
			String invoiceDateToString=String.valueOf(oldARrecord.CSX_CMP_Invoice_Date__c);
			String cancelInvoiceStatus=CSX_CMP_InterfaceUtility.fetchCancelInvoiceStatus(oldARrecord.CSX_CMP_Invoice_Number__c,oldARrecord.CSX_CMP_Invoice_Number__c,oldARrecord.CSX_CMP_Company_Code__c,invoiceDateToString,oldARrecord.CSX_CMP_Reversal_Reason__c,'Cancel',createdDate,oldARrecord.CSX_CMP_Claim__r.caseNumber,arSettlementId);

			String ifInvoiceCancelled='';
			if(String.isNotBlank(cancelInvoiceStatus)){
				ifInvoiceCancelled=cancelInvoiceStatus;
			}

            //invoiceRecordUpdate(oldARrecord.Id,invoiceStatus);
			if(ifInvoiceCancelled=='Document posted successfully'){
				CSX_CMP_AR_Settlement__c newRecord = oldARrecord.clone(false,true);
				newRecord.CSX_CMP_Request_Type__c = 'Create';
				newRecord.CSX_CMP_Integration_Status__c = 'Sent';
				newRecord.CSX_CMP_Invoice_Amount__c = invoiceAmount;
				newRecord.CSX_CMP_External_ID__c = '';
				newRecord.CSX_CMP_Invoice_Payment_Status__c = 'Open';
				insertnewRecord = Database.insert(newRecord);
				recId = insertnewRecord.getId();
				if(insertnewRecord.isSuccess()){
					updatestatus = 'Success';
				}
				else{
					CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_InvoiceAjustmentController', 'updateInvoiceAmount', insertnewRecord,'ARSettlement');
				}
			
            If(!oldARrecord.X3rd_Partys__r.isEmpty()){
                oldARrecord.X3rd_Partys__r[0].CSX_CMP_AR_Settlement__c = recId;
                update oldARrecord.X3rd_Partys__r[0];
            }
		}
		else if(ifInvoiceCancelled=='Failed'){
			recId='Failed';

		}else{
			recId=ifInvoiceCancelled;
		}
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InvoiceAjustmentController','updateInvoiceAmount',String.valueOf(arSettlementId) + String.valueOf(invoiceAmount),ex);
        }
        return recId;
    }

	/*
        @description : method to cancel the AR record 
        @param : arSettlementId,cancellationReason
    */
	@AuraEnabled
    public static string invoiceRecordUpdate(Id arSettlementId, String responseType,string claimNumber){
		string updatestatus;
		Database.SaveResult updateClaimRecord;
        CSX_CMP_AR_Settlement__c oldARrecord = getARDetails(arSettlementId);
       // oldARrecord.CSX_CMP_Cancellation_Reason__c = cancellationReason;
	try{
	   if(responseType=='Success'){
			oldARrecord.CSX_CMP_Request_Type__c = 'Cancel';
			oldARrecord.CSX_CMP_Integration_Status__c='Processed';
			oldARrecord.CSX_CMP_Invoice_Payment_Status__c='Cancelled';
			oldARrecord.CSX_CMP_Balance_Due__c=0;
	   }
	   if(responseType=='Failed'){
			oldARrecord.CSX_CMP_Request_Type__c = 'Create';
			oldARrecord.CSX_CMP_Integration_Status__c='Error';
			oldARrecord.CSX_CMP_Invoice_Payment_Status__c='Open';
   	  	}
        Database.SaveResult updatenewRecord = Database.update(oldARrecord);
        If(!oldARrecord.X3rd_Partys__r.isEmpty()){
            oldARrecord.X3rd_Partys__r[0].CSX_CMP_AR_Settlement__c = null;
            update oldARrecord.X3rd_Partys__r[0];
        }
		/*if(claimNumber!='claimNumberNotFound'){	
			Case claimNew = [
				SELECT Id, Status, CaseNumber, CSX_CMP_System_Action_Toggle__c
				FROM Case
				WHERE CaseNumber=:claimNumber Limit 1
			];
			//claimNew.Status = 'Cancelled';
			//claimNew.CSX_CMP_System_Action_Toggle__c = !claimNew.CSX_CMP_System_Action_Toggle__c;
			updateClaimRecord=Database.update(claimNew);
		}*/
		if(updatenewRecord.isSuccess() ){
			updatestatus = 'Success';
		}
		else{
			updatestatus = 'Error';
		}
      //  CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_InvoiceAjustmentController', 'cancelInvoice', string.valueof(updatestatus),'ARSettlement');
		
	}catch(Exception ex)
			{
			}  
			return updatestatus;  
		}

	/*
        @description : method to fetch the data using query
        @param : arSettlementId
        @return : CSX_CMP_AR_Settlement__c  
    */
	private static CSX_CMP_AR_Settlement__c getARDetails(id arSettlementId) {
		try {
			CSX_CMP_AR_Settlement__c oldRecord = [
				SELECT
					CSX_CMP_Invoice_Amount__c,
					CSX_CMP_Invoice_Number__c,
					CSX_CMP_Adjusted_Amount__c,
					CSX_CMP_Amount_Paid__c,
					Name,
					CSX_CMP_Balance_Due__c,
					CSX_CMP_Bank_Account_Number__c,
					CSX_CMP_Claim__c,
					CSX_CMP_Company_Code__c,
					CSx_CMP_Cost_Center__c,
					CSX_CMP_Currency_Type__c,
					CSX_CMP_Customer_Name__c,
					CSX_CMP_Customer_Number__c,
					CSX_CMP_Customer_Site__c,
					CSX_CMP_Document_Type__c,
					CSX_CMP_GL_Account__c,
					CSX_CMP_External_ID__c,
					CSX_CMP_Invoice_Date__c,
					CSX_CMP_Claim__r.type,
					CSX_CMP_Claim__r.caseNumber,
					CSX_CMP_Invoice_Payment_Status__c,
					(SELECT id,CSX_CMP_Contact_Email__c, CSX_CMP_AR_Settlement__c FROM X3rd_Partys__r),
					CSX_CMP_Operating_Unit__c,
					CSX_CMP_Remit_Number__c,
					CSX_CMP_Remit_Amount__c,
					CSX_CMP_Remit_Date__c,
					CSX_CMP_Scheduled_Pay_Date__c,
					CSX_CMP_Source__c,
					CSX_CMP_Reversal_Reason__c
				FROM CSX_CMP_AR_Settlement__c
				WHERE ID = :arSettlementId
				WITH SECURITY_ENFORCED
			];
			return oldRecord;
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_InvoiceAjustmentController', 'getARDetails', arSettlementId, e);
			return null;
		}
	}
	/*
        @description : method to identify the email address and email data  
        @param : arSettlementId
		add this method in CSX_CMP_ARSettlementTriggerHandler
    */
	/*public static void sendInvoiceEmailCommunication(Id arSettlementId) {
		try {
			CSX_CMP_AR_Settlement__c arRecord = getARDetails(arSettlementId);
			List<string> listEmails = new List<string>();
			List<string> ccEmails = new List<string>();
			if (arRecord.CSX_CMP_Claim__r.type == 'FC Customer Claim') {
				if (!arRecord.X3rd_Partys__r.isEmpty() && arRecord.X3rd_Partys__r[0].CSX_CMP_Contact_Email__c != null) {
					listEmails.addAll(arRecord.X3rd_Partys__r[0].CSX_CMP_Contact_Email__c.split(';'));
				}
			} else if (arRecord.CSX_CMP_Claim__r.type == 'FC Customer Automobile Claim') {
				List<Contact> listContact = [
					SELECT Id, Email, CSX_CMP_Inv_Notif_Other_Emails__c
					FROM Contact
					WHERE
						AccountId = :arRecord.CSX_CMP_Customer_Name__c
						AND CSX_CMP_Status__c != 'Suspended'
						AND CSX_CMP_Inv_Notif_PDF_Attach__c = TRUE
					WITH SECURITY_ENFORCED
				];

				if (!listContact.isEmpty()) {
					for (Contact emailContact : listContact) {
						if (emailContact.Email != null) {
							listEmails.add(emailContact.Email);
						}

						if (emailContact.CSX_CMP_Inv_Notif_Other_Emails__c != null) {
							ccEmails.addAll(emailContact.CSX_CMP_Inv_Notif_Other_Emails__c.split(','));
						}
					}
				}
			}
			if (!listEmails.isEmpty()) {
				sendInvoiceEmail(arRecord.Id, listEmails, ccEmails);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_InvoiceAjustmentController',
				'sendInvoiceEmailCommunication',
				String.valueof(arSettlementId),
				ex
			);
		}
	}*/
	/*
        @description : method to send the invoice emails
        @param : arRecordId,emailAddress,ccEmails
    */
	@future(callout=true)
	public static void sendInvoiceEmail(Id arRecordId, List<String> emailAddress, List<String> ccEmails) {
		Long startTime = DateTime.now().getTime();
		Long finishTime = DateTime.now().getTime();
		
		while ((finishTime - startTime) < 9000) {
				//sleep for 9s
				finishTime = DateTime.now().getTime();
			}
		CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
		try {
			emailWrap.sourceRecordId = arRecordId;
			emailWrap.toEmailIdList = emailAddress;
			emailWrap.ccEmailIdList = ccEmails;
			emailWrap.templateDeveloperName = 'CSX_CMP_Auto_Contract_Invoice_Template';
			emailWrap.attachmentFileName = 'Invoice Report.pdf';
			emailWrap.pdfVFPageName = 'CSX_CMP_ARInvoiceReport';

			Messaging.SingleEmailMessage email = CSX_CMP_EmailUtility.sendVisualForceTemplateEmailWithPDF(emailWrap);
			Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

			if (results[0].success) {
				CSX_CMP_AR_Settlement__c temp = new CSX_CMP_AR_Settlement__c();
				temp.Id = arRecordId;
				temp.CSX_CMP_Invoice_Email_Sent_Date__c = Date.today();
				Database.SaveResult saveResult = Database.update(temp);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_InvoiceAjustmentController',
					'sendInvoiceEmail',
					saveResult,
					'ARSettlement'
				);
			}
			CSX_CMP_LoggerUtility.addApexEmailErrorLog('CSX_CMP_InvoiceAjustmentController', 'sendInvoiceEmail', results);
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_InvoiceAjustmentController',
				'sendInvoiceEmail',
				JSON.serialize(emailWrap),
				ex
			);
		}
	}

	public class ARInvoiceWrapper {
		@AuraEnabled
		public String invoiceNumber;
		@AuraEnabled
		public Decimal invoiceAmount;
		@AuraEnabled
		public String invoiceStatus;
	}
}