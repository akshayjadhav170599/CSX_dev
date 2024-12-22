/**************************************************************************************
Apex Class Name     : CSX_CMP_FLDXInboundWebservice
Function            : webservice class to prepare data for FLDX Inbound file to be consumed by sterling to create final FLDX file.
RICEFW #            : CMP-I-0415
Modification Log    :
* Developer         : Date :06/19/2024       Description 
* ----------------------------------------------------------------------------                  
* @author         : Infosys                  First version of this class.
*************************************************************************************/

@RestResource(urlmapping='/v1/validate-fldx-claims-summary/*')
global with sharing class CSX_CMP_FLDXInboundCreateWebService {
	@HttpPost
	global static void fldxCreateService() {
		RestRequest req = new RestRequest();
		RestResponse response = new RestResponse();
		req = RestContext.request;
		response = RestContext.response;
		try {
			Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
			List<Object> fldxObject = (List<Object>) reqMap.get('claims');
			Boolean isValid = false;

			Map<string, set<string>> uniqueClaimantMap = new Map<string, set<string>>();

			//variable to store Railraod summary from Railinc/Payload
			Map<String, Decimal> sourceRailroadCodetoTotalClaimAmountMap = new Map<String, Decimal>();
			Map<String, Integer> sourceRailroadCodetoClaimCountMap = new Map<String, Integer>();
			Map<String, Integer> sourceRailroadCodetoRowCountMap = new Map<String, Integer>();

			//variables to store grand summary from Railinc/Payload
			Decimal sourceGrandClaimTotalAmount = 0;
			Integer sourceGrandClaimCount = 0;
			Integer sourceGrandClaimRowCount = 0;

			//variables to validate Railroad summary
			Map<String, Decimal> railroadCodetoTotalClaimAmountMap = new Map<String, Decimal>();
			Map<String, Integer> railroadCodetoClaimCountMap = new Map<String, Integer>();
			Map<String, Integer> railroadCodetoRowCountMap = new Map<String, Integer>();

			Map<String, CSX_CMP_NewClaimWrapper> claimtoNewClaimWrapperMap = new Map<String, CSX_CMP_NewClaimWrapper>();

			try {
				if (!fldxObject.isEmpty()) {
					Map<String, Object> responseMapFromHelper = CSX_CMP_FLDXInboundCreateServiceHelper.prepareClaimWrapper(
						fldxObject
					);
					claimtoNewClaimWrapperMap = (Map<String, CSX_CMP_NewClaimWrapper>) responseMapFromHelper.get('wrapperMap');

					railroadCodetoTotalClaimAmountMap = (Map<String, Decimal>) responseMapFromHelper.get(
						'railroadCodetoTotalClaimAmountMap'
					);
					railroadCodetoRowCountMap = (Map<String, Integer>) responseMapFromHelper.get('railroadCodetoRowCountMap');
					uniqueClaimantMap = (Map<string, set<string>>) responseMapFromHelper.get('uniqueClaimantMap');
					// Railroad source Maps
					sourceRailroadCodetoTotalClaimAmountMap = (Map<String, Decimal>) responseMapFromHelper.get(
						'sourceRailroadCodetoTotalClaimAmountMap'
					);
					sourceRailroadCodetoClaimCountMap = (Map<String, Integer>) responseMapFromHelper.get(
						'sourceRailroadCodetoClaimCountMap'
					);
					sourceRailroadCodetoRowCountMap = (Map<String, Integer>) responseMapFromHelper.get(
						'sourceRailroadCodetoRowCountMap'
					);
					// Grand Source Values
					sourceGrandClaimTotalAmount = (Decimal) responseMapFromHelper.get('sourceGrandClaimTotalAmount');
					sourceGrandClaimCount = (Integer) responseMapFromHelper.get('sourceGrandClaimCount');
					sourceGrandClaimRowCount = (Integer) responseMapFromHelper.get('sourceGrandClaimRowCount');

					if (!uniqueClaimantMap.isEmpty()) {
						for (String key : uniqueClaimantMap.keySet()) {
							railroadCodetoClaimCountMap.put(key, uniqueClaimantMap.get(key).size());
						}
					}

					//Response Map
					Map<String, Object> dataMap = new Map<String, Object>();
					Map<String, Object> railroadSummaryMap = new Map<String, Object>(); // payload data
					Map<String, Object> railroadSummaryFromRailincMap = new Map<String, Object>(); // calculated one
					set<String> railroadNumbers = new Set<String>();

					Boolean isAllValid = false;

					for (String railRoadCode : sourceRailroadCodetoTotalClaimAmountMap.keySet()) {
						SenderSCAC objSender = new SenderSCAC();
						objSender.railroad = railRoadCode;
						objSender.totalClaims = sourceRailroadCodetoClaimCountMap.get(railRoadCode);
						objSender.totalRows = sourceRailroadCodetoRowCountMap.get(railRoadCode);
						objSender.totalAmount = sourceRailroadCodetoTotalClaimAmountMap.get(railRoadCode);
						railroadSummaryMap.put(railRoadCode, objSender);
					}

					for (String railRoadCode : railroadCodetoTotalClaimAmountMap.keySet()) {
						SenderSCAC objSender = new SenderSCAC();
						objSender.railroad = railRoadCode;
						objSender.totalClaims = railroadCodetoClaimCountMap.get(railRoadCode);
						objSender.totalRows = railroadCodetoRowCountMap.get(railRoadCode);
						objSender.totalAmount = railroadCodetoTotalClaimAmountMap.get(railRoadCode);
						railroadSummaryFromRailincMap.put(railRoadCode, objSender);
					}

					dataMap.put('railroadSummaryFromRailinc', railroadSummaryMap.values()); //from payload
					dataMap.put('calculatedRailroadSummary', railroadSummaryFromRailincMap.values()); // calculated

					SenderSCAC objSenderGrandReceived = new SenderSCAC();
					Map<String, Object> objSenderGrandReceivedMap = new Map<String, Object>();
					objSenderGrandReceived.totalClaims = sourceGrandClaimCount;
					objSenderGrandReceived.totalRows = sourceGrandClaimRowCount;
					objSenderGrandReceived.totalAmount = sourceGrandClaimTotalAmount;
					objSenderGrandReceivedMap.put('totalClaims', sourceGrandClaimCount);
					objSenderGrandReceivedMap.put('totalRows', sourceGrandClaimRowCount);
					objSenderGrandReceivedMap.put('totalAmount', sourceGrandClaimTotalAmount);
					dataMap.put('grandSummaryFromRailinc', objSenderGrandReceivedMap);

					SenderSCAC objSenderGrandRailinc = new SenderSCAC();
					Map<String, Object> objSenderGrandRailincMap = new Map<String, Object>();
					objSenderGrandRailincMap.put('totalClaims', 0);
					objSenderGrandRailincMap.put('totalRows', 0);
					objSenderGrandRailincMap.put('totalAmount', 0.0);
					objSenderGrandRailinc.totalClaims = 0;
					objSenderGrandRailinc.totalRows = 0;
					objSenderGrandRailinc.totalAmount = 0.0;
					for (String railRoadCode : railroadCodetoTotalClaimAmountMap.keySet()) {
						objSenderGrandRailinc.totalClaims += railroadCodetoClaimCountMap.get(railRoadCode) != null
							? railroadCodetoClaimCountMap.get(railRoadCode)
							: 0;
						objSenderGrandRailinc.totalRows += railroadCodetoRowCountMap.get(railRoadCode) != null
							? railroadCodetoRowCountMap.get(railRoadCode)
							: 0;
						objSenderGrandRailinc.totalAmount += railroadCodetoTotalClaimAmountMap.get(railRoadCode) != null
							? railroadCodetoTotalClaimAmountMap.get(railRoadCode)
							: 0.0;

						objSenderGrandRailincMap.put('totalClaims', objSenderGrandRailinc.totalClaims);
						objSenderGrandRailincMap.put('totalRows', objSenderGrandRailinc.totalRows);
						objSenderGrandRailincMap.put('totalAmount', Math.round(objSenderGrandRailinc.totalAmount * 100.0) / 100.0);
					}

					Integer grandClaimCount = 0;
					if (objSenderGrandRailincMap.get('totalClaims') != null) {
						grandClaimCount = (Integer) objSenderGrandRailincMap.get('totalRows') ;
						grandClaimCount += Integer.valueOf(railroadCodetoRowCountMap.size());
						grandClaimCount += 2;
					}
					objSenderGrandRailincMap.put('totalRows', grandClaimCount);
					objSenderGrandRailinc.totalRows = grandClaimCount;

					dataMap.put('calculatedGrandSummary', objSenderGrandRailincMap);

					for (String railroadCode : railroadSummaryFromRailincMap.keySet()) {
						if (railroadSummaryMap.containsKey(railroadCode)) {
							SenderSCAC objSenderReceived = (SenderSCAC) railroadSummaryMap.get(railroadCode);
							SenderSCAC objSenderFromRailinc = (SenderSCAC) railroadSummaryFromRailincMap.get(railroadCode);

							if (
								// Decimal.valueOf (String.valueOf(objSenderReceived.totalClaims)).setScale(2) != Decimal.valueOf(String.valueOf(objSenderFromRailinc.totalAmount)).setScale(2) || Integer.valueOf(objSenderReceived.totalRows) != Integer.valueOf(objSenderFromRailinc.totalRows) || Integer.valueOf(objSenderReceived.totalClaims) != Integer.valueOf(objSenderFromRailinc.totalClaims)
								objSenderReceived.totalClaims != objSenderFromRailinc.totalClaims ||
								objSenderReceived.totalRows != objSenderFromRailinc.totalRows ||
								objSenderReceived.totalAmount != objSenderFromRailinc.totalAmount
							) {
								isAllValid = true;
								railroadNumbers.add(railroadCode);
							}
						} else {
							railroadNumbers.add(railroadCode);
						}
					}

					if (
						isAllValid == false &&
						Decimal.valueOf(String.valueOf(sourceGrandClaimTotalAmount)).setScale(2) == Decimal.valueOf(String.valueOf(objSenderGrandRailinc.totalAmount)).setScale(2) && Integer.valueOf(sourceGrandClaimRowCount) == Integer.valueOf(objSenderGrandRailinc.totalRows) && Integer.valueOf(sourceGrandClaimCount) == Integer.valueOf(objSenderGrandRailinc.totalClaims)
						// sourceGrandClaimTotalAmount == objSenderGrandRailinc.totalAmount &&
						// sourceGrandClaimCount == objSenderGrandRailinc.totalClaims &&
						// sourceGrandClaimRowCount == objSenderGrandRailinc.totalRows
					) {
						isValid = true;
					} else {
						isValid = false;
					}

					String message = '';

					if (isValid) {
						message = 'Data Validated Successfully. We will proceed with Claim creation';
						response.statusCode = 200;
					} else {
						message = 'Identified data discrepancy at Railroad Grand Summary';
						if (railroadNumbers.size() > 0) {
							message +=
								' and Railroad Summary. Please check the following Railroad Codes: ' +
								String.join(railroadNumbers, ', ');
						} else {
							message += '.';
						}
						response.statusCode = 400;
					}

					dataMap.put('message', message);
					response.responseBody = Blob.valueOf(JSON.serialize(dataMap));
				}

				if (isValid) {
					List<CSX_CMP_Creation_Request__c> claimStagingRecords = new List<CSX_CMP_Creation_Request__c>();
					for (String claimRefNumber : claimtoNewClaimWrapperMap.keySet()) {
						CSX_CMP_Creation_Request__c claimStagingRecord = new CSX_CMP_Creation_Request__c();
						claimStagingRecord.CSX_CMP_Creation_Status__c = 'Not Started';
						claimStagingRecord.CSX_CMP_Queueable_One_Execution_Status__c = 'Pending';
						claimStagingRecord.CSX_CMP_Service_Case_Fetch_Status__c = 'Pending';
						claimStagingRecord.CSX_CMP_Umler_Fetch_Status__c = 'Pending';
						claimStagingRecord.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Pending';
						claimStagingRecord.CSX_CMP_Waybill_Document_Fetch_Status__c = 'Pending';
						claimStagingRecord.CSX_CMP_Source__c = 'FLDX';
						claimStagingRecord.CSX_CMP_Request_Payload__c = JSON.serialize(
							claimtoNewClaimWrapperMap.get(claimRefNumber)
						);
						claimStagingRecord.CSX_CMP_Object_Type__c = 'Claim';
						claimStagingRecords.add(claimStagingRecord);
					}

					if (!claimStagingRecords.isEmpty()) {
						Database.SaveResult[] saveResults = Database.insert(claimStagingRecords, false);
						CSX_CMP_LoggerUtility.addApexDMLErrorLog(
							'CSX_CMP_FLDXInboundCreateWebService',
							'createStagingRecord',
							saveResults,
							'CSX_CMP_Request_Payload__c'
						);

						//Boolean createClaim = true;
						Boolean createClaim = CSX_CMP_ClaimCreateWebServiceHelper.checkQueueableValidation();
						if (createClaim) {
							System.enqueueJob(new CSX_CMP_ClaimCreationQueueable(claimStagingRecords[0]));
						}
					}
				}
			} catch (Exception e) {
				response.responseBody = Blob.valueOf(e.getMessage());
				response.statusCode = 400;
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					e.getMessage(),
					'FLDX Claim Creation',
					req.requestBody.toString(),
					''
				);
			}
		} catch (System.JSONException e) {
			response.responseBody = Blob.valueOf(e.getMessage());
			response.statusCode = 400;
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'FLDX Claim Creation',
				req.requestBody.toString(),
				''
			);
		}
	}

	//wrapper for response

	public class SenderSCAC {
		public String railroad;
		public Integer totalClaims;
		public Integer totalRows;
		public Decimal totalAmount;
	}
}