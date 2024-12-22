/*
RICEF ID : CMP-E-0416
@author : Infosys
@description : This class is used to handle post claim creation API fetch processes - Umler, Freight Bill, Mileage, Service Case, Waybill image
*/
public with sharing class CSX_CMP_PostClaimCreationAPIQueueable implements Queueable, Database.AllowsCallouts {
	public String claimId;
	public String externalSource;
	public CSX_CMP_Creation_Request__c stagingRec;

	public CSX_CMP_PostClaimCreationAPIQueueable(String source, CSX_CMP_Creation_Request__c stagingrecord) {
		this.claimId = stagingrecord.CSX_CMP_Claim__c;
		this.externalSource = source;
		String stagingFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Creation_Request__c');
		Id stgId = stagingrecord.Id;
		String query = 'SELECT ' + stagingFields + ' FROM CSX_CMP_Creation_Request__c WHERE Id = :stgId';
		List<CSX_CMP_Creation_Request__c> stagingRecords = Database.query(String.escapeSingleQuotes(query));
		this.stagingRec = stagingRecords[0];
	}

	public void execute(QueueableContext context) {
		String parameters = 'claimId-' + claimId + ' - externalSource-' + externalSource;
		parameters += '\n\n' + JSON.serialize(stagingRec);
		try {
			switch on externalSource {
				when 'UMLER' {
					try {
						if (
							stagingRec.CSX_CMP_Umler_Fetch_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Umler_Fetch_Status__c != 'Not Applicable'
						) {
							CSX_CMP_PostClaimCreationHelper.updateUmlerDetails(stagingRec);
						}
					} catch (Exception e) {
						CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameters, e);
					}

					System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Freight Bill', stagingRec));
				}
				when 'Freight Bill' {
					try {
						if (
							stagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c != 'Not Applicable'
						) {
							CSX_CMP_PostClaimCreationHelper.updateFreightBillDetails(stagingRec);
						}
					} catch (Exception e) {
						CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameters, e);
					}

					System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Mileage', stagingRec));
				}
				when 'Mileage' {
					try {
						if (
							stagingRec.CSX_CMP_Mileage_Fetch_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Mileage_Fetch_Status__c != 'Not Applicable'
						) {
							CSX_CMP_PostClaimCreationHelper.updateMileageDetails(stagingRec);
						}
					} catch (Exception e) {
						CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameters, e);
					}

					System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Service Case', stagingRec));
				}
				when 'Service Case' {
					//check for available Cases in Service Application and set "Cases Available?" checkbox
					try {
						if (
							stagingRec.CSX_CMP_Service_Case_Fetch_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Service_Case_Fetch_Status__c != 'Not Applicable'
						) {
							CSX_CMP_PostClaimCreationHelper.updateCaseAvailable(stagingRec);
						}
					} catch (Exception e) {
						CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameters, e);
					}

					System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Waybill Image', stagingRec));
				}
				when 'Waybill Image' {
					// Fetch Waybill Document and push to ECM
					try {
						if (
							stagingRec.CSX_CMP_Waybill_Document_Fetch_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Waybill_Document_Fetch_Status__c != 'Not Applicable'
						) {
							CSX_CMP_PostClaimCreationHelper.updateWaybillImage(stagingRec);
						}

						//invoke batch job to upload claim confirmation email to ECM
						//Confirmation Email Upload Status
						if (
							stagingRec.CSX_CMP_Confirmation_Email_Upload_Status__c != 'Completed' &&
							stagingRec.CSX_CMP_Confirmation_Email_Upload_Status__c != 'Not Applicable'
						) {
							List<EmailMessage> confirmationEmail = [
								SELECT Id, TextBody, HtmlBody, Subject, FromAddress, ToAddress, CcAddress, CreatedDate, ParentId
								FROM EmailMessage
								WHERE ParentId = :claimId AND Subject LIKE '%Confirmation%'
								LIMIT 1
							];
							CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(confirmationEmail);
							Database.executeBatch(uploadEmailBatch);
							//CSX_CMP_UploadEmailToECM.createEmailContent(confirmationEmail[0]);
							stagingRec.CSX_CMP_Confirmation_Email_Upload_Status__c = 'Completed';
						}
					} catch (Exception e) {
						CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameters, e);
					}

					//mark creation request status as Completed.
					completeStagingRecord(stagingRec);
				}
				when 'Enqueue New Claim Creation' {
					Boolean isInternalUser = FeatureManagement.checkPermission('CSX_CMP_Internal_User');
					 if (!isInternalUser) { // need to uncomment
						newClaimCreation();
					 }
				}
			}
		} catch (Exception e) {
			String parameter =
				'claimId-' +
				claimId +
				' - externalSource-' +
				externalSource +
				'\n\n' +
				JSON.serialize(stagingRec);
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'execute', parameter, e);
		}
	}

	public static void completeStagingRecord(CSX_CMP_Creation_Request__c stagingRec) {
		stagingRec.CSX_CMP_Creation_Status__c = 'Completed';
		Database.SaveResult stagingRecUpdateRes = Database.update(stagingRec, false);
		CSX_CMP_LoggerUtility.addApexDMLErrorLog(
			'CSX_CMP_PostClaimCreationAPIQueueable',
			'execute',
			stagingRecUpdateRes,
			'CSX_CMP_Creation_Request__c'
		);

		//enqueue next claim creation job if pending creation
		System.enqueueJob(new CSX_CMP_PostClaimCreationAPIQueueable('Enqueue New Claim Creation', stagingRec));
	}

	public static void newClaimCreation() {
		try {
			Boolean createClaim = CSX_CMP_ClaimCreateWebServiceHelper.checkQueueableValidation();
			if (createClaim) {
				String stagingFields = CSX_CMP_ClaimCloneHelper.getFields('CSX_CMP_Creation_Request__c');
				String claimStatus = 'Not Started';
				String objectType = 'Claim';
				String query =
					'SELECT ' +
					stagingFields +
					' FROM CSX_CMP_Creation_Request__c WHERE CSX_CMP_Claim__c = NULL AND CSX_CMP_Object_Type__c =: objectType AND CSX_CMP_Creation_Status__c = :claimStatus';
				List<CSX_CMP_Creation_Request__c> creationRequestList = Database.query(String.escapeSingleQuotes(query));
				if (!creationRequestList.isEmpty()) {
					System.enqueueJob(new CSX_CMP_ClaimCreationQueueable(creationRequestList[0]));
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationAPIQueueable', 'newClaimCreation', '', e);
		}
	}
}