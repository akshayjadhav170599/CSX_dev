/**************************************************************************************
Apex Class Name     : CSX_CMP_SendCSXClaimNumWebService
Function            : Class for Webservice to search claims based on noOfDays for property Potal.
RICEFW #            : CMP-I-0451
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           02/11/2023       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/claim-numbers/*')
global with sharing class CSX_CMP_SendCSXClaimNumWebService {
	@HttpGet
	global static void searchCSXClaimNumbers() {
		List<ClaimNumResponseWrapper> responseWrapperList = new List<ClaimNumResponseWrapper>();
		RestResponse response = RestContext.response;
		RestRequest req;
		string request;
		try {
            String message = 'Invalid Date Format, Please Correct to: YYYY-MM-DD';
			req = RestContext.request;
			String startDate;
			String endDate;
			if (req.params.get('startDate') != null) {
				startDate = req.params.get('startDate');
				Boolean isStartDateValid = isValidDateFormat(startDate);
				if (!isStartDateValid) {	 
					HandledException e = new HandledException(message);
					throw e;
				}
			}
			if (req.params.get('endDate') != null) {
				endDate = req.params.get('endDate');
				Boolean isEndDateValid = isValidDateFormat(endDate);
				if (!isEndDateValid) {
					HandledException e = new HandledException(message);
					throw e;
				}
			}
			responseWrapperList = getEligibleClaims(startDate, endDate);
			if (!responseWrapperList.isEmpty()) {
				response.responseBody = Blob.valueOf(JSON.serialize(responseWrapperList));
				response.addHeader('Content-Type', 'application/json');
			} else {
				response.responseBody = Blob.valueOf(JSON.serialize(responseWrapperList));
				response.addHeader('Content-Type', 'application/json');
			}
		} catch (System.StringException ex) {
			response.statusCode = 400;
			response.responseBody = Blob.valueOf('{"error" : ' + ex.getMessage() + '}');
			response.addHeader('Content-Type', 'application/json');
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Send claims # to property portal',
				req.params.toString(),
				''
			);
		} catch (System.QueryException ex) {
			response.statusCode = 404;
			response.responseBody = Blob.valueOf('{"error" : ' + ex.getMessage() + '}');
			response.addHeader('Content-Type', 'application/json');
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Send claims # to property portal',
				req.params.toString(),
				''
			);
		} catch (System.HandledException e){
            response.statusCode = 400;
            response.responseBody = Blob.valueOf(e.getMessage());
            response.addHeader('Content-Type', 'application/json');
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'Send claims # to property portal',
				req.params.toString(),
				''
			);
        }
        
        catch (Exception ex) {
			response.statusCode = 500;
			response.responseBody = Blob.valueOf(ex.getMessage());
            System.debug('responseBody: '+ex.getMessage());
			response.addHeader('Content-Type', 'application/json');
            //main
            // Create an instance of the ErrorWrapper class
    		CSX_CMP_GenericErrorResponseWrapper genericError1 = new CSX_CMP_GenericErrorResponseWrapper();
            
            // Assign values to the traceId (if available)
    		genericError1.traceId = '12345'; // Example traceId, replace with actual value if available
            
            // Create an instance of the ErrorDetail class and assign values
            genericError1.error = new CSX_CMP_GenericErrorResponseWrapper.ErrorDetail();
            genericError1.error.code = 500;
            genericError1.error.message = ex.getMessage();
            genericError1.error.target = 'Send claims # to property portal';
            
            
            
            // Create a list for details and add a detail instance
            genericError1.details = new List<CSX_CMP_GenericErrorResponseWrapper.Detail>();
            CSX_CMP_GenericErrorResponseWrapper.Detail detail = new CSX_CMP_GenericErrorResponseWrapper.Detail();
            detail.code = 500;
            detail.message = ex.getMessage();
            detail.target = 'Exception Detail';
            genericError1.details.add(detail);
            
            // Check for specific error message to adjust status code
			if (ex.getMessage().contains('Please review the From date, valid format : YYYY-MM-DD')) {
				response.statusCode = 400;
			}
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				ex.getMessage(),
				'Send claims # to property portal',
				req.params.toString(),
				''
			);
             // Set the response
            response.statusCode = genericError1.error.code;
            response.responseBody = Blob.valueOf(JSON.serialize(genericError1));
            response.addHeader('Content-Type', 'application/json');
		}
	}
	public static Boolean isValidDateFormat(String dateStr) {
		// Regular expression for YYYY-MM-DD format
		String regex = '^\\d{4}-\\d{2}-\\d{2}$';
		Pattern pattern = Pattern.compile(regex);
		Matcher matcher = pattern.matcher(dateStr);
		return matcher.matches();
	}

	public static List<ClaimNumResponseWrapper> getEligibleClaims(string startDate, string endDate) {
		List<ClaimNumResponseWrapper> claimNumWebServiceWrapperResponse = new List<ClaimNumResponseWrapper>();
			List<Case> claimRecords = new List<Case>();
			if ((startDate == null || startDate == '') && (endDate == null || endDate == '')) {
				claimRecords = [
					SELECT CSX_CMP_Claimant_Ref_Num__c, Type, CaseNumber, CSX_CMP_Case_Number_Formula__c, CSX_CMP_VIN__c
					FROM Case
					WHERE
						((Type = 'FC RR Inbound Claim'
						OR Type = 'Recharges Inbound Claim')
						AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c = 'UP'
						AND CSX_CMP_Claimant_Ref_Num__c != '')
						OR (Type = 'FC Customer Automobile Claim'
						AND CSX_CMP_VIN__c != '')
					WITH SECURITY_ENFORCED
					ORDER BY CSX_CMP_Claim_Date__c DESC
				]; 
			} else {
				Date convertedFromDate = Date.valueOf(startDate);

				Date convertedToDate = Date.valueOf(endDate);
				claimRecords = [
					SELECT CSX_CMP_Claimant_Ref_Num__c, Type, CaseNumber, CSX_CMP_Case_Number_Formula__c, CSX_CMP_VIN__c
					FROM Case
					WHERE
						CSX_CMP_Claim_Date__c >= :convertedFromDate
						AND CSX_CMP_Claim_Date__c <= :convertedToDate
						AND (((Type = 'FC RR Inbound Claim'
						OR Type = 'Recharges Inbound Claim')
						AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c = 'UP'
						AND CSX_CMP_Claimant_Ref_Num__c != '')
						OR (Type = 'FC Customer Automobile Claim'
						AND CSX_CMP_VIN__c != ''))
					WITH SECURITY_ENFORCED
					ORDER BY CSX_CMP_Claim_Date__c DESC
				];
			}
			if (!claimRecords.isEmpty()) {
				for (Case cs : claimRecords) {
					ClaimNumResponseWrapper csNumWrapper = new ClaimNumResponseWrapper();
					//csNumWrapper.claimNumber=cs.CaseNumber;
					csNumWrapper.claimNumber = cs.CSX_CMP_Case_Number_Formula__c;
					if (cs.Type == 'FC RR Inbound Claim' || cs.Type == 'Recharges Inbound Claim') {
						csNumWrapper.foreignClaimNumber = cs.CSX_CMP_Claimant_Ref_Num__c;
					}
					if (cs.Type == 'FC Customer Automobile Claim') {
						csNumWrapper.vin = cs.CSX_CMP_VIN__c;
					}
					claimNumWebServiceWrapperResponse.add(csNumWrapper);
				}
			}
		return claimNumWebServiceWrapperResponse;
	}

	public class ClaimNumResponseWrapper {
		@AuraEnabled
		public String claimNumber { get; set; }
		@AuraEnabled
		public String vin { get; set; }
		@AuraEnabled
		public String foreignClaimNumber { get; set; }
	}
}