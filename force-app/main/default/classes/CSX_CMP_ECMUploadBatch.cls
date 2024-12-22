/**
@Author       - Infosys
@Name         - CSX_CMP_ECMUploadBatch
@Created Date - 03/14/2024
@Description  - This class is used to upload documents to ECM. 
This batch job should be always triggered with batch size 1.
*/
public with sharing class CSX_CMP_ECMUploadBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
	public List<Id> contentVersionIds { get; set; }
	public Boolean isDelete { get; set; }
	public Boolean isManual { get; set; }
	public String parentEntityType = '';
	public Integer count = 0;

	public CSX_CMP_ECMUploadBatch(List<Id> cvIds, Boolean deletionIndicator, String parentType, Boolean isManual){
		this.contentVersionIds = cvIds;
		this.isDelete = deletionIndicator;
		this.isManual = isManual;
		this.parentEntityType = parentType;
	}

	public Iterable<sObject> start(Database.BatchableContext context) {
		String strQuery = 'SELECT Id, Title, FileExtension, VersionData, IsMajorVersion, ContentDocumentId ' +
						  ', CSX_CMP_Internal_Only__c ' +
						  '	FROM ContentVersion WHERE Id in: contentVersionIds';
					
		List<ContentVersion> cvRecs = Database.Query(strQuery);
		return cvRecs;
	}

	//execute to be run with batch size 1
	public void execute(Database.BatchableContext context, List<Sobject> cvRecords) {	
		//query contentDocumentLink to get LinkedEntityId (Case Id / Property portal Id)

		try {
			ContentVersion cv = (ContentVersion) cvRecords[0];
			Boolean internalOnly = cv.CSX_CMP_Internal_Only__c;
			List<ContentDocumentLink> contentDocLinks = [
				SELECT Id, LinkedEntityId, ContentDocumentId
				FROM ContentDocumentLink
				WHERE ContentDocumentId = :cv.ContentDocumentId
			];

			List<ContentVersion> contentVersionRec = [
				SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
				FROM ContentVersion
				WHERE ContentDocumentId = :cv.ContentDocumentId AND IsLatest = TRUE
			];
			if (!contentDocLinks.isEmpty()) {
				CSX_CMP_InterfaceUtility.ECMRequestWrapper request = new CSX_CMP_InterfaceUtility.ECMRequestWrapper();
				request.dDocTitle = contentVersionRec[0].Title;
				request.dSecurityGroup = 'Secure';
				//request.dDocAuthor = 'z_frc_user';
            	
				User objUser = [SELECT Id, FederationIdentifier FROM User where id =: userinfo.getUserId()];

				if(objUser.FederationIdentifier != null){
					request.dDocAuthor = objUser.FederationIdentifier.split('@')[0];
				}

				request.content = EncodingUtil.base64Encode(contentVersionRec[0].VersionData);
				request.filePath = contentVersionRec[0].Title + '.' + contentVersionRec[0].FileExtension;
				request.xInitial = string.valueOf(internalOnly);
				// to filter contentDocumentLink for case
				List<ContentDocumentLink> filteredCaseDocLinks = new List<ContentDocumentLink>();
				List<ContentDocumentLink> filteredPPortalLinks = new List<ContentDocumentLink>();
				List<ContentDocumentLink> filteredLDDocLinks = new List<ContentDocumentLink>();
				List<ContentDocumentLink> docLinksToDelete = new List<ContentDocumentLink>();
				CSX_CMP_Property_Portal_Staging__c updatePortalStagingRec = new CSX_CMP_Property_Portal_Staging__c();

				for (ContentDocumentLink cdlink : contentDocLinks) {

					String objectAPIName = (cdlink.LinkedEntityId).getSObjectType().getDescribe().getName();

					if (objectAPIName.ToUpperCase().contains('CASE')) {
						filteredCaseDocLinks.add(cdlink);
						docLinksToDelete.add(cdlink);
					} else if (objectAPIName.ToUpperCase().contains('PROPERTY_PORTAL_STAGING')) {
						filteredPPortalLinks.add(cdlink);
						docLinksToDelete.add(cdlink);
					} else if (objectAPIName.ToUpperCase().contains('LD_REPORT')) {
						filteredLDDocLinks.add(cdlink);
						docLinksToDelete.add(cdlink);
					}
				}

				switch on parentEntityType {
					when 'Claim' {
						if (!filteredCaseDocLinks.isEmpty()) {
							List<Case> parentClaim = [
								SELECT
									Id,
									CaseNumber,
									CSX_CMP_Case_Number_Formula__c,
									Type,
									recordType.DeveloperName,
									CSX_CMP_VIN__c,
									CSX_CMP_Equipment_Num__c,
									CSX_CMP_Equipment_Initial__c,
									CSX_CMP_Service_Period__c,
									//CSX_CMP_Supplier_Claimant__r.CSX_CMP_Class_1_Railroad__c,
									CSX_CMP_Customer__r.CSX_CMP_Class_1_Railroad__c,
									CSX_CMP_Contract_Num__r.Name,
									(SELECT Id, Name, CSX_CMP_Waybill_Date__c FROM Equipments__r where CSX_CMP_Waybill_Date__c != null LIMIT 1),
									(SELECT Id, CSX_CMP_File_Description__c FROM CSX_Document_Ref__r LIMIT 1)
								FROM case
								WHERE Id = :filteredCaseDocLinks[0].LinkedEntityId
								LIMIT 1
							];

							//child query on Equipment
							if (!parentClaim.isEmpty()) {

								if(parentClaim[0].CSX_Document_Ref__r != null && parentClaim[0].CSX_Document_Ref__r.size() > 0){
									request.xComments = parentClaim[0].CSX_Document_Ref__r[0].CSX_CMP_File_Description__c;
								}
								
								if(parentClaim[0].Equipments__r != null && parentClaim[0].Equipments__r.size() > 0){
									request.xEventDate = string.valueOf(parentClaim[0].Equipments__r[0].CSX_CMP_Waybill_Date__c);
								}
								
								request.xInvolvedPartyName = parentClaim[0].CSX_CMP_Contract_Num__r.Name;
								request.xEventNumber = parentClaim[0].CSX_CMP_Case_Number_Formula__c;

								if (parentClaim[0].recordType.DeveloperName == 'Freight') {
									request.xCarNumber = parentClaim[0].CSX_CMP_Equipment_Num__c;
									request.xCarInitial = parentClaim[0].CSX_CMP_Equipment_Initial__c;
									request.xIronMtnBoxNum = parentClaim[0].CSX_CMP_VIN__c;
									request.dDocType = 'FREIGHT_CLAIMS';
									request.dDocAccount = '020705';
									request.xRMProfileTrigger = 'FreightClaims';
									request.xCategoryID = 'FreightClaimsClaimFiles';
									if (parentClaim[0].type == 'Recharges Outbound Claim') {
										request.xCmisAttachment = parentClaim[0].CSX_CMP_Service_Period__c;
										if (parentClaim[0].CSX_CMP_Customer__r.CSX_CMP_Class_1_Railroad__c== true) {
											request.xGroupFour = '1';
										}
									}
								} else {
									request.dDocType = 'RevenueClaims';
									request.dDocAccount = '03080499';
									request.xRMProfileTrigger = 'RevenueClaims';



									if (parentClaim[0].recordType.DeveloperName == 'Revenue_Contract_Refund') {
										request.xCategoryID = 'ContractsAndAgreementsCoProductionAndOperatingAgreements';
									} else {
										request.xCategoryID = 'FreightClaimsClaimFiles';
									}
								}
							}
						}
					}
					when 'Property Portal' {
						//in property portal object based on record type update the request wrapper.
						if (!filteredPPortalLinks.isEmpty()) {
							List<CSX_CMP_Property_Portal_Staging__c> propertPortalRecs = [
								SELECT
									Id,
									Name,
									CSX_CMP_Record_Type__c,
									CSX_CMP_Service_Period__c,
									CSX_CMP_Claim_Number__c,
									CSX_CMP_Waybill_Date__c,
									CSX_CMP_Document_Type__c,
									CSX_CMP_VIN__c
								FROM CSX_CMP_Property_Portal_Staging__c
								WHERE Id = :filteredPPortalLinks[0].LinkedEntityId
								LIMIT 1
							];
							if (!propertPortalRecs.isEmpty()) {
								request.dDocType = 'FREIGHT_CLAIMS';
								request.dDocAccount = '020705';
								request.xRMProfileTrigger = 'FreightClaims';
								request.xCategoryID = 'FreightClaimsClaimFiles';
								request.xCmisAttachment = propertPortalRecs[0].CSX_CMP_Service_Period__c;

								if(propertPortalRecs[0].CSX_CMP_Document_Type__c == 'Distribution'){
									request.xEventNumber = propertPortalRecs[0].CSX_CMP_Claim_Number__c;
								}
							}
						}
					}
					when 'LD Report' {
						// this is only for freight request type and update xInvolvedPartyName
						if (!filteredLDDocLinks.isEmpty()) {
							List<CSX_CMP_LD_Report__c> ldReportRecs = [
								SELECT Id, Name, RecordTypeId
								FROM CSX_CMP_LD_Report__c
								WHERE Id = :filteredLDDocLinks[0].LinkedEntityId
								LIMIT 1
							];
							request.dDocType = 'FREIGHT_CLAIMS';
							request.dDocAccount = '020705';
							request.xRMProfileTrigger = 'FreightClaims';
							request.xCategoryID = 'FreightClaimsClaimFiles';
							request.xInvolvedPartyName = ldReportRecs[0].Name;
						}
					}
				}

				List<CSX_CMP_Document_Ref__c> availableDocRefRecs = [
					SELECT Id, CSX_CMP_ECM_Document_ID__c
					, CSX_CMP_UploadToECM__c, CSX_CMP_Property_Portal_Staging__c
					FROM CSX_CMP_Document_Ref__c
					WHERE CSX_CMP_Content_Document_ID__c = :contentVersionRec[0].ContentDocumentId
				];
				if (!availableDocRefRecs.isEmpty() && availableDocRefRecs[0].CSX_CMP_ECM_Document_ID__c != null) {
					request.dDocName = availableDocRefRecs[0].CSX_CMP_ECM_Document_ID__c;
				}

				CSX_CMP_InterfaceUtility.ECMResponseWrapper response;
				if (request.dDocName == null) {
					response = CSX_CMP_InterfaceUtility.uploadDocToECM(request);
					count++;
				} else {
					response = CSX_CMP_InterfaceUtility.updateDocInECM(request);
					count++;
				}

				if (response.documentId != '') {
					// ContentDocument to delete if no update Scenario is required
					if (isDelete == true) 
					{
						Database.DeleteResult[] deleteCdl = Database.delete(docLinksToDelete, false);
						CSX_CMP_LoggerUtility.addApexDMLErrorLog(
							'CSX_CMP_ECMUploadBatch',
							'execute',
							deleteCdl,
							'ContentDocumentLink'
						);

						ContentDocument contentDoc = new ContentDocument();
						if (contentVersionRec[0].title != 'Decline Letter.pdf') {
							contentDoc.Id = contentVersionRec[0].ContentDocumentId;
							List<Database.DeleteResult> deleteCd = Database.delete(new List<ContentDocument>{ contentDoc }, false);
							CSX_CMP_LoggerUtility.addApexDMLErrorLog(
								'CSX_CMP_ECMUploadBatch',
								'execute',
								deleteCd,
								'ContentDocument'
							);
						}
					}
					if (request.dDocName == null) {
						if (!availableDocRefRecs.isEmpty()) {
							if (response.documentId != null) {
								availableDocRefRecs[0].CSX_CMP_ECM_Document_ID__c = response.documentId;
								availableDocRefRecs[0].CSX_CMP_UploadToECM__c = true;
								if (availableDocRefRecs[0].CSX_CMP_Property_Portal_Staging__c != null) {
									updatePortalStagingRec = [
										SELECT id, CSX_CMP_ECM_Doc_ID__c
										FROM CSX_CMP_Property_Portal_Staging__c
										WHERE id = :availableDocRefRecs[0].CSX_CMP_Property_Portal_Staging__c
										LIMIT 1
									];
									updatePortalStagingRec.CSX_CMP_ECM_Doc_ID__c = response.documentId;

									Database.SaveResult updatePropertyStagingRef = Database.update(updatePortalStagingRec);
									CSX_CMP_LoggerUtility.addApexDMLErrorLog(
										'CSX_CMP_ECMUploadBatch',
										'execute',
										updatePropertyStagingRef,
										'CSX_CMP_Property_Portal_Staging__c'
									);
								}
							}
							Database.SaveResult updateDecumentRef = Database.update(availableDocRefRecs[0]);
							CSX_CMP_LoggerUtility.addApexDMLErrorLog(
								'CSX_CMP_ECMUploadBatch',
								'execute',
								updateDecumentRef,
								'CSX_CMP_Document_Ref__c'
							);
						}
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ECMUploadBatch', 'execute', String.valueOf(contentVersionIds), ex);
		}
	}

	public void finish(Database.BatchableContext context) {
		CSX_CMP_LoggerUtility.addExecutionLog('CSX_CMP_ECMUploadBatch', 'Upload to ECM', 'ContentVersion', count);
		if (isManual == true) {
			CSX_CMP_ECM_Upload_Notification__e event = new CSX_CMP_ECM_Upload_Notification__e();
			event.CSX_CMP_Completed__c = true;
			EventBus.publish(event);
		}
	}
}