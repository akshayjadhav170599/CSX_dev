/**************************************************************************************
Apex Class Name     : CSX_CMP_HTTPUtility
Function            : Class to keep all reusuable methods
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Akshay           10/11/2023       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_HTTPUtility {
	public static String getAccessToken() {
		String authAccessToken = '';
		CSX_CMP_Axway_Connection_Detail__c axwayConnectionDetail = CSX_CMP_Axway_Connection_Detail__c.getOrgDefaults();
		CSX_CMP_SAP_CPI_Connection_Detail__c sapConnectionDetail = CSX_CMP_SAP_CPI_Connection_Detail__c.getOrgDefaults();
		String clientId;
		String clientSecret;
		string endpoint;
		try {
			Http auth = new Http();
			HttpRequest authReq = new HttpRequest();
			/*if (identifier == 'SAP CPI') {
				clientId = sapConnectionDetail.CSX_CMP_APIKey__c;
				clientSecret = sapConnectionDetail.CSX_CMP_APISecret__c;
				endpoint = sapConnectionDetail.CSX_CMP_End_Point__c;
			}*/
            //this is just for testing purpose for AR cancellation invoice  for older approach
			//if (identifier == 'Axway') {
				clientId = axwayConnectionDetail.CSX_CMP_APIKey__c;
				clientSecret = axwayConnectionDetail.CSX_CMP_APISecret__c;
				endpoint = axwayConnectionDetail.CSX_CMP_End_Point__c;
			//}

			authReq.setEndpoint(endpoint);
			authReq.setMethod('POST');
			authReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');

			clientId = clientId;
			clientSecret = clientSecret;
			authReq.setBody('grant_type=client_credentials' + '&client_id=' + clientId + '&client_secret=' + clientSecret);
			HttpResponse authRes = auth.send(authReq);
			if (authRes.getStatusCode() == 200) {
				Map<String, Object> authRresMap = (Map<String, Object>) JSON.deserializeUntyped(authRes.getBody());
				authAccessToken = (String) authRresMap.get('access_token');
                System.debug('authAccessToken: '+authAccessToken);
			} else {
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					authRes.getBody(),
					'CSX_CMP_HTTPUtility.getAccessToken',
					authReq.toString(),
					''
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_HTTPUtility', 'getAccessToken', authAccessToken, ex);
		}
		return authAccessToken;
	}
	public static HttpResponse getHttpResponseforECM(Map<String, String> requestMap, Blob body) {
		HttpResponse response;
		HttpRequest httpRequest;
		Http http = new Http();
		try {
			httpRequest = createHttpRequest(requestMap, body);
			response = http.send(httpRequest);		
			if (response.getStatusCode() != 200) {
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					response.getBody(),
					'CSX_CMP_HTTPUtility.getHttpResponseforECM',
					json.serialize(requestMap),
					''
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog(
				'CSX_CMP_HTTPUtility',
				'getHttpResponseforECM',
				json.serialize(requestMap),
				ex
			);
		}
		return response;
	}
	public static HttpRequest createHttpRequest(Map<String, String> requestMap, Blob body) {
		String authAccessToken = getAccessToken();
		HttpRequest httpRequest = new HttpRequest();
		if (authAccessToken != null) {
			try {
				httpRequest.setMethod(requestMap.get('Method'));
				httpRequest.setHeader('Authorization', 'Bearer ' + authAccessToken);
				httpRequest.setEndpoint(requestMap.get('EndpointURL'));
				if (requestMap.get('Method') == 'POST' || requestMap.get('Method') == 'PATCH') {
					httpRequest.setHeader('Content-Type', requestMap.get('Content-Type'));
					if (requestMap.get('Content-Type') == 'application/json') {
						httpRequest.setBody(requestMap.get('Body'));
					} else {
						httprequest.setTimeout(120000);
						if (body != null) {
							httpRequest.setBodyAsBlob(body);
							// httpRequest.setHeader('Content-Length',String.valueof(httpRequest.getBodyAsBlob().size()));
						} else {
							httpRequest.setBody(requestMap.get('Body'));
						}
					}
				}
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog(
					'CSX_CMP_HTTPUtility',
					'createHttpRequest',
					json.serialize(requestMap),
					ex
				);
			}
		}
		return httpRequest;
	}

	public static HttpResponse getHttpResponse(Map<String, String> requestMap) {
		HttpResponse response;
		Http http = new Http();
		HttpRequest httpRequest;
		try {
			httpRequest = createHttpRequest(requestMap, null);
			response = http.send(httpRequest);
			if (response.getStatusCode() != 200) {
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					response.getBody(),
					'CSX_CMP_HTTPUtility.getHttpResponse',
					json.serialize(requestMap),
					''
				);
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_HTTPUtility', 'getHttpResponse', json.serialize(requestMap), ex);
		}
		return response;
	}
}