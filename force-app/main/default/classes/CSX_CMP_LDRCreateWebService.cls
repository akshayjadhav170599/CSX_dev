/**
@Author       - Infosys
@Name         - CSX_CMP_LDRCreateWebService
@Created Date - 02/10/2024
@RICEFW       - CMP-I-0454
@Description  - web service to accept L&D report creation requests
*/
@RestResource(urlmapping='/v1/loss-damage-reports/*')
global with sharing class CSX_CMP_LDRCreateWebService {
	@HttpPost
	global static void ldrCreateService() {
		CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = new CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req = RestContext.request;
		res = RestContext.response;
		Id ldrId;
		try {
			Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUnTyped(req.requestBody.toString());
			Map<String, String> requestMap = new Map<String, String>();
			for (String key : requestMapAny.keyset()) {
				if (key == 'equipment') {
					requestMap.put(key, JSON.serialize(requestMapAny.get(key)));
				} else {
					requestMap.put(key, requestMapAny.get(key).toString());
				}
			}
			Map<Boolean, String> validationResponse = checkValidation(requestMap);
			if (!validationResponse.keyset().isEmpty() && validationResponse.get(false) == null) {
				requestMap.put('contactId', getContactDetails(requestMap)); // added line
				response = CSX_CMP_LDRCreationController.createLDReport(requestMap);
				if (response.ldrId != null) {
					res.responseBody = Blob.valueOf(JSON.serialize(response.ldrName));
					res.statusCode = 201;
				} else if (response.errorMessage != null) {
					res.responseBody = Blob.valueOf(JSON.serialize(response.errorMessage));
					res.statusCode = 400;
					CSX_CMP_LoggerUtility.addIntegrationErrorLog(
						response.errorMessage,
						'New L&D Report Creation',
						req.requestBody.toString(),
						''
					);
				}
			} else {
				res.responseBody = Blob.valueOf(JSON.serialize(validationResponse.get(false)));
				res.statusCode = 400;
				CSX_CMP_LoggerUtility.addIntegrationErrorLog(
					validationResponse.get(false),
					'New L&D Report Creation',
					req.requestBody.toString(),
					''
				);
			}
		} catch (Exception e) {
			// catch(System.DMLException e){
			//     res.responseBody = Blob.valueOf(e.getMessage());
			//     res.statusCode = 500;
			//      CSX_CMP_LoggerUtility.addIntegrationErrorLog(e.getMessage(),'New L&D Report Creation',req.requestBody.toString(),'');
			// }catch(System.NullPointerException e){
			//     res.responseBody = Blob.valueOf(e.getMessage());
			//     res.statusCode = 500;
			//     CSX_CMP_LoggerUtility.addIntegrationErrorLog(e.getMessage(),'New L&D Report Creation',req.requestBody.toString(),'');
			// }
			res.responseBody = Blob.valueOf(e.getMessage());
			res.statusCode = 500;
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'New L&D Report Creation',
				req.requestBody.toString(),
				''
			);
		}
	}

	private static Map<Boolean, String> checkValidation(Map<String, String> recordMap) {
		Map<Boolean, String> responseMap = new Map<Boolean, String>();
		try {
			if (
				!String.isNotBlank(recordMap.get('reportType')) ||
				!String.isNotBlank(recordMap.get('source')) ||
				!String.isNotBlank(recordMap.get('cause')) ||
				!String.isNotBlank(recordMap.get('damageReason')) ||
				!String.isNotBlank(recordMap.get('incidentAction')) ||
				!String.isNotBlank(recordMap.get('incidentDate')) ||
				!String.isNotBlank(recordMap.get('multipleBadOrders')) ||
				!String.isNotBlank(recordMap.get('incidentCity')) ||
				!String.isNotBlank(recordMap.get('incidentState')) ||
				!String.isNotBlank(recordMap.get('milepost'))
			) {
				responseMap.put(false, ' mandatory fields are missing');
				return responseMap;
			}

			String query = 'SELECT Id,Name FROM CSX_CMP_City_State_Master__c';
			if (
				String.isNotBlank(recordMap.get('incidentState')) &&
				String.isNotBlank(recordMap.get('incidentCity')) &&
				String.isNotBlank(recordMap.get('milepost'))
			) {
				String whereClause = '';
                String stateWithLike = '%' + String.escapeSingleQuotes(recordMap.get('incidentState')) + '%';
				String cityWithLike = '%' + String.escapeSingleQuotes(recordMap.get('incidentCity')) + '%';
				whereClause = buildWhereClause(recordMap);
				query = query + ' WHERE ' + whereClause + ' LIMIT 1';
				List<CSX_CMP_City_State_Master__c> cityState = Database.query(String.escapeSingleQuotes(query));
				if (!cityState.isEmpty()) {
					recordMap.put('incidentLocation', cityState[0].Id);
					responseMap.put(true, '');
				} else {
					responseMap.put(false, 'City/State/Milepost not found');
				}
			} else {
				responseMap.put(false, 'City/State/Milepost is mandatory');
			}
		} catch (Exception e) {
			responseMap.put(false, e.getMessage());
		}
		return responseMap;
	}

	private static String buildWhereClause(Map<String, String> recordMap) {
		List<String> whereClause = new List<String>();
		if (String.isNotBlank(recordMap.get('incidentState'))) {
			whereClause.add('CSX_CMP_State__c LIKE :stateWithLike');
		}
		if (String.isNotBlank(recordMap.get('incidentCity'))) {
			whereClause.add('CSX_CMP_City__c LIKE :cityWithLike');
		}
		//Commented by Sarath P to fix the issue raised by MTI. MTI can send only Incident City and State, Not Milepost
		/*if(String.isNotBlank(recordMap.get('milepost'))){
            whereClause.add('CSX_CMP_Milepost__c LIKE '+ '\'%'+recordMap.get('milepost')+'%\'');
        }*/
		return String.join(whereClause, ' AND ');
	}

	private static String getContactDetails(Map<String, String> recordMap) {
		String contactId;
		try {
			if (String.isNotBlank(recordMap.get('racfId'))) {
				if (Schema.sObjectType.Contact.isAccessible()) {
					List<Contact> contacts = [
						SELECT Id
						FROM Contact
						WHERE CSX_CMP_RACF_Id__c = :recordMap.get('racfId')
						WITH SECURITY_ENFORCED
						LIMIT 1
					];
					if (!contacts.isEmpty()) {
						contactId = contacts[0].Id;
					}
				}
			} else if (
				String.isNotBlank(recordMap.get('contactName')) ||
				String.isNotBlank(recordMap.get('phone')) ||
				String.isNotBlank(recordMap.get('email'))
			) {
				String query = 'SELECT Id FROM Contact WHERE ';
				List<String> whereClause = new List<String>();
				String contactWithLike;
				String phoneWithLike;
				String emailWithLike;
				if (String.isNotBlank(recordMap.get('contactName'))) {
					contactWithLike = '%' + String.escapeSingleQuotes(recordMap.get('contactName')) + '%';
					whereClause.add('Name LIKE :contactWithLike');
				}
				if (String.isNotBlank(recordMap.get('phone'))) {
					phoneWithLike = '%' + String.escapeSingleQuotes(recordMap.get('phone')) + '%';
					whereClause.add('Phone LIKE :phoneWithLike');
				}
				if (String.isNotBlank(recordMap.get('email'))) {
					emailWithLike = '%' + String.escapeSingleQuotes(recordMap.get('email')) + '%';
					whereClause.add('Email LIKE :emailWithLike');
				}
				query = query + String.join(whereClause, ' AND ');
				query = query + ' LIMIT 1';
				List<Contact> contacts = Database.query(String.escapeSingleQuotes(query));
				if (!contacts.isEmpty()) {
					contactId = contacts[0].Id;
				}
			}
		} catch (Exception e) {
			CSX_CMP_LoggerUtility.addIntegrationErrorLog(
				e.getMessage(),
				'New L&D Report Creation - getContactDetails',
				JSON.serialize(recordMap),
				''
			);
		}
		return contactId;
	}
}