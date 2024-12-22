/**************************************************************************************
/*
@author: Infosys
@description  : Class for Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.

Apex Class Name     : CSX_CMP_ClaimCreateWebService
Function            : Class for Webservice  to create claims from FLDX, EDI and Customer Service Salesforce systems.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           02/11/2023       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/claims/*')
global with sharing class CSX_CMP_ClaimCreateWebService {
	/*
    @description : Method to create claims from FLDX, EDI and Customer Service Salesforce systems.
    */
	@HttpPost
	global static void claimCreateService() {
		RestRequest req = new RestRequest();
		RestResponse response = new RestResponse();
		req = RestContext.request;
		response = RestContext.response;
		try {
			CSX_CMP_NewClaimWrapper claimInputWrapper = new CSX_CMP_NewClaimWrapper();
			Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUnTyped(req.requestBody.toString());
			Map<String, String> requestMap = new Map<String, String>();
			for (String key : requestMapAny.keyset()) {
				if (key == 'equipment') {
					requestMap.put(key, JSON.serialize(requestMapAny.get(key)));
				} else {
					if (requestMapAny.get(key) != null) {
						requestMap.put(key, requestMapAny.get(key).toString());
					} else {
						requestMap.put(key, null);
					}
				}
			}

			//Call method to validate input request for mandatory fields and data type
			try {
				claimInputWrapper = CSX_CMP_ClaimCreationHelper.newClaimInputMaptoWrapper(requestMap);
			} catch (Exception e) {
				response.responseBody = Blob.valueOf(e.getMessage());
				response.statusCode = 400;
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					e.getMessage(),
					'New Claim Creation',
					req.requestBody.toString(),
					''
				);
			}

			string source = claimInputWrapper.source;
			//Query to fetch duplicate claims
			if (source == 'Customer Service') {
				List<Case> duplicateClaimList = new List<Case>();
				if (claimInputWrapper.caseNumber != null) {
					String caseNumber = String.escapeSingleQuotes(claimInputWrapper.caseNumber);
					String claimType = String.escapeSingleQuotes(claimInputWrapper.claimType);
					String caseQuery = 'SELECT Id, Status,CaseNumber,CSX_CMP_System_Action_Toggle__c,CSX_CMP_Claim_Amount__c FROM Case WHERE Type =: claimType';
					caseQuery += ' AND CaseNumber =: caseNumber';
					caseQuery += ' LIMIT 1';
					duplicateClaimList = Database.query(String.escapeSingleQuotes(caseQuery));
				}

				Case duplicateCase = duplicateClaimList.size() > 0 ? duplicateClaimList[0] : null;
				if (duplicateCase != null) {
					if (
						duplicateCase.Status == 'Rejected' ||
						duplicateCase.Status == 'Declined' ||
						duplicateCase.Status == 'Cancelled' ||
						duplicateCase.Status == 'Re-Declined'
					) {
						//Method to update claim with new details in salesforce and submit for approval
						//Need to unwarp complete claim and need to change insert to upsert on claim creation - overwriting existing claim
						Boolean result = CSX_CMP_ClaimCreateWebServiceHelper.updateClaimandSubmitforApproval(
							duplicateCase,
							claimInputWrapper
						);
						if (result) {
							response.statusCode = 200;
							response.responseBody = Blob.valueOf(
								'Claim updated successfully and sent for approval. Please refer to the claim number(s) below: ' +
								duplicateCase.CaseNumber
							);
						}
					} else {
						//form message with claim # references and respond back to source system
						response.statusCode = 200;
						response.responseBody = Blob.valueOf(
							'Claim already exists with the same details. Please refer to the claim number(s) below: ' +
							duplicateCase.CaseNumber
						);
					}
				} else {
					Map<Boolean, String> validationMap = CSX_CMP_ClaimCreateWebServiceHelper.checkValidation(claimInputWrapper);
					if (validationMap.get(false) == null) {
						// CSX_CMP_Creation_Request__c claimStagingRecord = createStagingRecord(JSON.serialize(claimInputWrapper),JSON.serialize(duplicateClaimList),0);
						CSX_CMP_Creation_Request__c claimStagingRecord = CSX_CMP_ClaimCreationHelper.createStagingRecord(
							claimInputWrapper,
							'',
							0
						);
						Map<String, String> responseMap = new Map<String, String>();
						if (claimStagingRecord != null) {
							responseMap = CSX_CMP_ClaimCreationHelper.CreateNewClaim(claimStagingRecord);
						}
						if (responseMap != null) {
							if (responseMap.get('error') != null) {
								response.statusCode = 400;
								response.responseBody = Blob.valueOf(responseMap.get('error'));
								CSX_CMP_LoggerUtility.addIntegrationErrorLog(
									validationMap.get(false),
									'New Claim Creation',
									JSON.serialize(claimInputWrapper),
									''
								);
							} else if (responseMap.get('success') != null) {
								Map<String, String> detailMap = (Map<String, String>) JSON.deserialize(
									responseMap.get('success'),
									Map<String, String>.class
								);
								response.statusCode = 200;
								response.responseBody = Blob.valueOf(detailMap.get('CaseNumber'));
							}
						}
					} else {
						response.statusCode = 400;
						response.responseBody = Blob.valueOf(validationMap.get(false));
						CSX_CMP_LoggerUtility.addIntegrationErrorLog(
							validationMap.get(false),
							'New Claim Creation',
							JSON.serialize(claimInputWrapper),
							''
						);
					}
				}
			} else {
				//EDI and FLDX
				// Boolean EDIRefileFlag = false;
				Integer refileVersion = 0;
				if (source == 'EDI' || claimInputWrapper.claimType == 'FC Customer Automobile Claim') {
					//Refile flag set and incremented number as new Version
					refileVersion = CSX_CMP_ClaimCreationHelper.identifyRefileVersionNum(claimInputWrapper);
				}
				Map<Boolean, String> validationMap = CSX_CMP_ClaimCreateWebServiceHelper.checkValidation(claimInputWrapper);
				if (validationMap.get(false) == null) {
					//  CSX_CMP_Creation_Request__c claimStagingRecord = createStagingRecord(JSON.serialize(claimInputWrapper),JSON.serialize(duplicateClaimList),refileVersion);
					CSX_CMP_BusinessRulesUtility.ClaimWrapper wrapper = CSX_CMP_BusinessRulesUtility.newClaimWrapperToClaimWrapper(
						claimInputWrapper
					);
					Map<Id, String> duplicateClaimMap = CSX_CMP_BusinessRulesUtility.runDuplicateBusinessRules(
						null,
						wrapper,
						null
					);
					CSX_CMP_Creation_Request__c claimStagingRecord = CSX_CMP_ClaimCreationHelper.createStagingRecord(
						claimInputWrapper,
						JSON.serialize(duplicateClaimMap.values()),
						refileVersion
					);
					Boolean createClaim = CSX_CMP_ClaimCreateWebServiceHelper.checkQueueableValidation();
					if (createClaim) {
						System.enqueueJob(new CSX_CMP_ClaimCreationQueueable(claimStagingRecord));
					}
					response.statusCode = 201;
					response.responseBody = Blob.valueOf('Claim Creation Request Submitted successfully');
				} else {
					response.statusCode = 400;
					response.responseBody = Blob.valueOf(validationMap.get(false));
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						validationMap.get(false),
						'New Claim Creation',
						JSON.serialize(claimInputWrapper),
						''
					);
				}
			}
		} catch (System.JSONException e) {
			response.responseBody = Blob.valueOf(e.getMessage());
			response.statusCode = 400;
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'New Claim Creation',
				req.requestBody.toString(),
				''
			);
		} catch (Exception e) {
			response.responseBody = Blob.valueOf(e.getMessage());
			response.statusCode = 500;
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'New Claim Creation',
				req.requestBody.toString(),
				''
			);
		}
	}
}