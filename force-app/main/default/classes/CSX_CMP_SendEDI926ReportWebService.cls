/**************************************************************************************
Apex Class Name     : CSX_CMP_SendEDI926ReportWebService
Function            : Class for Webservice to search EDI response based on created.
RICEFW #            : CMP-I-0877
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           03/08/2024       First version of this class.
*************************************************************************************/
@RestResource(urlmapping='/v1/claims-status/*')
global with sharing class CSX_CMP_SendEDI926ReportWebService {
	/*
        @description : method to fetch the record from EDI926report object
        @param : fromDate,toDate
        @return : RestContext.response
    */
	@httpGet
	global static void getEDI926Records() {
		RestResponse response = RestContext.response;
		List<EDIResponseWrapper> responseList = new List<EDIResponseWrapper>();
		Map<String, EDIResponseWrapper> responseMap = new Map<String, EDIResponseWrapper>();
		List<CSX_CMP_EDI926ClaimReport__c> responseData;
		try {
			String fromDate = RestContext.request.params.get('fromDate');
			String toDate = RestContext.request.params.get('toDate');
			if(Schema.sObjectType.CSX_CMP_EDI926ClaimReport__c.isAccessible()){
			if ((fromDate == null || fromDate == '') && (toDate == null || toDate == '')) {
				responseData = [
					SELECT
						CreatedDate,
						CSX_CMP_Claim__r.caseNumber,
						CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c,
						CSX_CMP_Segment1__c,
						CSX_CMP_Segment2__c,
						CSX_CMP_Segment3__c,
						CSX_CMP_Segment4__c,
						CSX_CMP_Sender_ID__c
					FROM CSX_CMP_EDI926ClaimReport__c
					ORDER BY CSX_CMP_Claim__r.caseNumber
				]; //CreatedDate = YESTERDAY Order By CSX_CMP_Claim__r.caseNumber //Order By CSX_CMP_Claim__r.caseNumber];
			} else {
				datetime convertedFromDate = date.valueOf(fromDate);
				datetime convertedToDate = date.valueOf(toDate) + 1;
				responseData = [
					SELECT
						CreatedDate,
						CSX_CMP_Claim__r.caseNumber,
						CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c,
						CSX_CMP_Segment1__c,
						CSX_CMP_Segment2__c,
						CSX_CMP_Segment3__c,
						CSX_CMP_Segment4__c,
						CSX_CMP_Sender_ID__c
					FROM CSX_CMP_EDI926ClaimReport__c
					WHERE CreatedDate >= :convertedFromDate AND CreatedDate <= :convertedToDate
					ORDER BY CSX_CMP_Claim__r.caseNumber
				];
			}

			if (!responseData.isEmpty()) {
				for (CSX_CMP_EDI926ClaimReport__c claimReport : responseData) {
					EDIResponseWrapper wrapperResponse = new EDIResponseWrapper();
					wrapperResponse.claimStatus = new List<ClaimStatusWrap>();
					ClaimStatusWrap claimStatusWrap = new ClaimStatusWrap();
					HeaderWrap headerWrap = new HeaderWrap();
					PaymentInformationWrap paymentInformationWrap = new PaymentInformationWrap();
					List<LineItemRejectWrap> lineItemRejectWrapList = new List<LineItemRejectWrap>();
					if (responseMap.containsKey(claimReport.CSX_CMP_Claim__r.caseNumber)) {
						wrapperResponse = responseMap.get(claimReport.CSX_CMP_Claim__r.caseNumber);

						if (claimReport.CSX_CMP_Segment1__c != null) {
							claimStatusWrap = getSegment1Data(claimReport.CSX_CMP_Segment1__c);
						} else {
							claimStatusWrap.currencyCode = '';
							claimStatusWrap.declinationCode = '';
							claimStatusWrap.createdDate = '';
							claimStatusWrap.claimStatus = '';
							claimStatusWrap.paidamount = 0;
							claimStatusWrap.claimAmount = 0;
							claimStatusWrap.claimNum = '';
							claimStatusWrap.customerReferenceNumber = '';
							claimStatusWrap.claimDate = '';
						}
					} else {
						if (claimReport.CSX_CMP_Segment1__c != null) {
							claimStatusWrap = getSegment1Data(claimReport.CSX_CMP_Segment1__c);
						} else {
							claimStatusWrap.currencyCode = '';
							claimStatusWrap.declinationCode = '';
							claimStatusWrap.createdDate = '';
							claimStatusWrap.claimStatus = '';
							claimStatusWrap.paidamount = 0;
							claimStatusWrap.claimAmount = 0;
							claimStatusWrap.claimNum = '';
							claimStatusWrap.customerReferenceNumber = '';
							claimStatusWrap.claimDate = '';
						}
					}
					if (claimReport.CSX_CMP_Segment4__c != null) {
						Map<String, Object> headerData = (Map<String, Object>) JSON.deserializeUntyped(
							claimReport.CSX_CMP_Segment4__c
						);
						headerWrap.constant4 = headerData.get('constant4') != null ? (String) headerData.get('constant4') : '';
						headerWrap.createdDate = headerData.get('createdDate') != null
							? (String) headerData.get('createdDate')
							: '';
						headerWrap.constant3 = headerData.get('constant3') != null ? (String) headerData.get('constant3') : '';
						headerWrap.constant2 = headerData.get('constant2') != null ? (String) headerData.get('constant2') : '';
						headerWrap.constant1 = headerData.get('constant1') != null ? (String) headerData.get('constant1') : '';
					} else {
						headerWrap.constant4 = '';
						headerWrap.createdDate = '';
						headerWrap.constant3 = '';
						headerWrap.constant2 = '';
						headerWrap.constant1 = '';
					}

					if (claimReport.CSX_CMP_Segment3__c != null) {
						Map<String, Object> paymentInformationData = (Map<String, Object>) JSON.deserializeUntyped(
							claimReport.CSX_CMP_Segment3__c
						);
						paymentInformationWrap.currencyCode = paymentInformationData.get('currencyCode') != null
							? (String) paymentInformationData.get('currencyCode')
							: '';
						paymentInformationWrap.createdDate = paymentInformationData.get('createdDate') != null
							? (String) paymentInformationData.get('createdDate')
							: '';
						paymentInformationWrap.checkNumber = paymentInformationData.get('checkNumber') != null
							? (String) paymentInformationData.get('checkNumber')
							: '';
						paymentInformationWrap.amountPaid = paymentInformationData.get('amountPaid') != null
							? (Decimal) paymentInformationData.get('amountPaid')
							: 0;
					} else {
						 paymentInformationWrap.currencyCode = '';
						 paymentInformationWrap.createdDate = '';
						 paymentInformationWrap.checkNumber = '';
						 paymentInformationWrap.amountPaid = 0;
                        //paymentInformationWrap = null;
					}
					if (claimReport.CSX_CMP_Segment2__c != null) {
						List<Object> lineItemRejectData = (List<Object>) JSON.deserializeUntyped(claimReport.CSX_CMP_Segment2__c);
						for (Object obj : lineItemRejectData) {
							Map<String, Object> objData = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
							LineItemRejectWrap lineItem = new LineItemRejectWrap();
							//lineItem.declinationCode = (String) objData.get('declinationCode');
                            lineItem.declinationCode = objData.get('declinationCode') != null
								? (String) objData.get('declinationCode')
								: '';
							lineItem.sequenceNum = (Integer) objData.get('sequenceNum');
							lineItemRejectWrapList.add(lineItem);
						}
					}
					wrapperResponse.Header = headerWrap;

					wrapperResponse.claimStatus.add(claimStatusWrap);
					wrapperResponse.paymentInformation = paymentInformationWrap;
					wrapperResponse.createdDate = date.valueof(claimReport.CreatedDate);
					//wrapperResponse.claimNumber = claimReport.CSX_CMP_Claim__r.caseNumber;
					wrapperResponse.claimNumber = claimReport.CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c;
					wrapperResponse.lineItemReject = lineItemRejectWrapList;
                    wrapperResponse.receiverId = claimReport.CSX_CMP_Sender_ID__c != null
								? claimReport.CSX_CMP_Sender_ID__c
								: '';

					//wrapperResponse.receiverId = claimReport.CSX_CMP_Sender_ID__c;
					responseList.add(wrapperResponse);
					responseMap.put(claimReport.CSX_CMP_Claim__r.caseNumber, wrapperResponse);
				}

				Map<String, Object> responseMapData = new Map<String, Object>();
				// responseMapData.put('claims', responseList);
				responseMapData.put('claims', responseMap.values());
				response.responseBody = Blob.valueOf(Json.serialize(responseMapData));
				response.statusCode = 200;
			} else {
				response.statusCode = 200;
				response.responseBody = Blob.valueOf('Results not found. Please provide valid Date range');
			}
		} }catch (Exception e) {
			Map<String,Object> parameters = new Map<String,Object> ();
			parameters.put('fromDate',RestContext.request.params.get('fromDate'));
			parameters.put('toDate',RestContext.request.params.get('toDate'));			
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SendEDI926ReportWebService', 'getEDI926Records', JSON.serialize(parameters), e);
		}
	}

	private static ClaimStatusWrap getSegment1Data(String data) {
		ClaimStatusWrap claimStatusWrap = new ClaimStatusWrap();
		try {
			if (data != null) {
				Map<String, Object> claimStatusData = (Map<String, Object>) JSON.deserializeUntyped(data);

				claimStatusWrap.currencyCode = claimStatusData.get('currencyCode') != null
					? (String) claimStatusData.get('currencyCode')
					: '';
				claimStatusWrap.declinationCode = claimStatusData.get('declinationCode') != null
					? (String) claimStatusData.get('declinationCode')
					: '';
				claimStatusWrap.createdDate = claimStatusData.get('createdDate') != null
					? (String) claimStatusData.get('createdDate')
					: '';
				claimStatusWrap.claimStatus = claimStatusData.get('claimStatus') != null
					? (String) claimStatusData.get('claimStatus')
					: '';
				claimStatusWrap.paidamount = claimStatusData.get('paidamount') != null
					? (Decimal) claimStatusData.get('paidamount')
					: 0;
				claimStatusWrap.claimAmount = claimStatusData.get('claimAmount') != null
					? (Decimal) claimStatusData.get('claimAmount')
					: 0;
				claimStatusWrap.claimNum = claimStatusData.get('claimNum') != null
					? (String) claimStatusData.get('claimNum')
					: '';
				claimStatusWrap.customerReferenceNumber = claimStatusData.get('customerRefNumber') != null
					? (String) claimStatusData.get('customerRefNumber')
					: '';
				claimStatusWrap.claimDate = claimStatusData.get('claimDate') != null
					? (String) claimStatusData.get('claimDate')
					: '';
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SendEDI926ReportWebService', 'getSegment1Data', '', e);
		}
		return claimStatusWrap;
	}

	public class EDIResponseWrapper {
		public HeaderWrap header;
		public List<LineItemRejectWrap> lineItemReject;
		public PaymentInformationWrap paymentInformation;
		public List<ClaimStatusWrap> claimStatus;
		public Date createdDate;
		public String claimNumber;
		public String receiverId;
	}

	public class HeaderWrap {
		public string constant4;
		public String createdDate;
		public string constant3;
		public string constant2;
		public string constant1;
	}

	public class ClaimStatusWrap {
		public string currencyCode;
		public String declinationCode;
		public String createdDate;
		public string claimStatus;
		public Decimal paidamount;
		public Decimal claimAmount;
		public string claimNum;
		public string customerReferenceNumber;
		public string claimDate;
	}

	public class PaymentInformationWrap {
		public string currencyCode;
		public string createdDate;
		public Decimal amountPaid;
		public string checkNumber;
	}

	public class LineItemRejectWrap {
		public string declinationCode;
		public Integer sequenceNum;
	}
}