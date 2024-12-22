/**************************************************************************************
Apex Class Name     : CSX_CMP_LoggerUtility
Function            : This class is to log the errors captured in catch block of apex classes and triggers.
Author              : Infosys
Modification Log    :
* Developer         : Date             Description
* ----------------------------------------------------------------------------                 
* Infosys           31/10/2023        First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_LoggerUtility {
	@testVisible
	private static final String NOT_AVAILABLE = 'Not Available';
	public static boolean isShipCSX = false;

	/**
	 * Checks if the string is null or empty and resets it to a default value.
	 */
	public static String checkNResetStr(String value) {
		return value == null || String.isBlank(value) ? NOT_AVAILABLE : value;
	}

	/**
	 * Logs an error message and stack trace into the Error Log object for errors created from LWC.
	 */
	@AuraEnabled
	public static void addLWCErrorLog(String compName, String methodName, String parameters, String error) {
		try {
			Database.DMLOptions dmlOptions = new Database.DMLOptions();
			dmlOptions.allowFieldTruncation = true;
			dmlOptions.optAllOrNone = false;
			CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
			errorRec.CSX_CMP_Class_Name__c = checkNResetStr(compName);
			errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
			errorRec.CSX_CMP_Message__c = checkNResetStr(error);
			errorRec.CSX_CMP_Parameters__c = checkNResetStr(parameters); //parameters.length() > MAX_PARAM_LENGTH ? parameters.substring(0, MAX_PARAM_LENGTH) :
			errorRec.CSX_CMP_Execution_Time__c = system.now();
			errorRec.CSX_CMP_User__c = UserInfo.getUserId();
			if (isShipCSX) {
				errorRec.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				Database.insert(errorRec, dmlOptions);
			}
		} catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_LoggerUtility','addLWCErrorLog', parameters, e);
		}
	}

	/**
	 * Logs an error message and stack trace into the Error Log object.
	 */
	public static void addApexErrorLog(String className, String methodName, String parameters, Exception exc) {
		try {
			Database.DMLOptions dmlOptions = new Database.DMLOptions();
			dmlOptions.allowFieldTruncation = true;
			dmlOptions.optAllOrNone = false;
			CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
			errorRec.CSX_CMP_Class_Name__c = checkNResetStr(className);
			errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
			errorRec.CSX_CMP_Exception_Type__c = checkNResetStr(exc.getTypeName());
			errorRec.CSX_CMP_Stack_Trace__c = checkNResetStr(exc.getStackTraceString());
			errorRec.CSX_CMP_Message__c = checkNResetStr(exc.getMessage());
			errorRec.CSX_CMP_Parameters__c = checkNResetStr(parameters); //parameters.length() > MAX_PARAM_LENGTH ? parameters.substring(0, MAX_PARAM_LENGTH) : checkNResetStr(parameters);
			errorRec.CSX_CMP_Execution_Time__c = System.now();
			errorRec.CSX_CMP_User__c = UserInfo.getUserId();
			if (isShipCSX) {
				errorRec.CSX_CMP_Source__c = 'ShipCSX'; // CSX_CMP_Source__c field is not in dev org & sandbox
			}
			if (Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				database.insert(errorRec, dmlOptions);
			}
		} catch (Exception e) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexErrorLog', parameters, e);
		}
	}

	/**
	 * Logs an error message and parameters to the Integration Error Log object.
	 */
	public static void addIntegrationErrorLog(String errorMessage, String processName, String parameters, String recId) {
		try {
			CSX_CMP_Integration_Log__c integrationRec = new CSX_CMP_Integration_Log__c();
			integrationRec.CSX_CMP_Message__c = errorMessage;
			integrationRec.CSX_CMP_Process_Name__c = processName;
			integrationRec.CSX_CMP_Parameters__c = parameters;
			integrationRec.CSX_CMP_Record_ID__c = String.isBlank(recId) ? NOT_AVAILABLE : recId;
			integrationRec.CSX_CMP_Payload__c = parameters;
			if (isShipCSX) {
				integrationRec.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Integration_Log__c.isCreateable()) {
				database.insert(integrationRec, false);
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addIntegrationErrorLog', parameters, ex);
		}
	}

	/*****************************************************************************************
    Method : addIntegrationErrorLog
        Description : This method logs an Integration Time and parameters to Integration Time Log object.
         ******************************************************************************************/
	public static void addIntegrationTimeLog(CSX_CMP_LoggerUtility.IntegrationTimeLogWrapper input) {
		try {
			Double requestTimeLong = DateTime.now().getTime();
			Datetime requestTime = DateTime.now();
			Double responseDuration = requestTimeLong - input.responseTimeLong;
			CSX_CMP_Integration_Time_Log__c integrationRec = new CSX_CMP_Integration_Time_Log__c();
			integrationRec.CSX_CMP_Request_Time__c = requestTime;
			integrationRec.CSX_CMP_Response_Duration__c = responseDuration;
			integrationRec.CSX_CMP_Response_Time__c = input.responseTime;
			integrationRec.CSX_CMP_Class_Name__c = input.className;
			integrationRec.CSX_CMP_Integration_Name__c = input.integrationName;
			integrationRec.CSX_CMP_Input_Parameters__c = input.parameters;
			if (isShipCSX) {
				integrationRec.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Integration_Time_Log__c.isCreateable()) {
				 database.insert(integrationRec, false);
			}
		} catch (exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addIntegrationErrorLog', Json.serialize(input), ex);
		}
	}

	/**
	 * Logs an error message during Email send operation.
	 */
	public static void addApexEmailErrorLog(String className, String methodName, Messaging.SendEmailResult result) {
		CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
		try {
			errorRec.CSX_CMP_Class_Name__c = checkNResetStr(className);
			errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
			errorRec.CSX_CMP_Message__c = result.getErrors().isEmpty()
				? NOT_AVAILABLE
				: result.getErrors().get(0).getMessage();
			errorRec.CSX_CMP_Parameters__c = result.getErrors().isEmpty()
				? NOT_AVAILABLE
				: result.getErrors().get(0).getTargetObjectId();
			errorRec.CSX_CMP_Execution_Time__c = System.now();
			errorRec.CSX_CMP_User__c = UserInfo.getUserId();
			if (isShipCSX) {
				errorRec.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				database.insert(errorRec, false);
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexEmailErrorLog', errorRec.CSX_CMP_Parameters__c, ex);
		}
	}

	/*****************************************************************************************
    Method : addApexEmailErrorLog (Delete DML Operations Version)
        Description : Overloaded method to handle multiple email send results.
         ******************************************************************************************/
	public static Integer addApexEmailErrorLog(
		String className,
		String methodName,
		List<Messaging.SendEmailResult> results
	) {
		List<CSX_CMP_Error_Log__c> errorLogList = new List<CSX_CMP_Error_Log__c>();
		Integer successCount = 0;
		try {
			for (Messaging.SendEmailResult res : results) {
				if (!res.isSuccess()) {
					CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
					errorRec.CSX_CMP_Class_Name__c = checkNResetStr(className);
					errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
					errorRec.CSX_CMP_Message__c = res.getErrors().isEmpty() ? NOT_AVAILABLE : res.getErrors().get(0).getMessage();
					errorRec.CSX_CMP_Parameters__c = res.getErrors().isEmpty()
						? NOT_AVAILABLE
						: res.getErrors().get(0).getTargetObjectId();
					errorRec.CSX_CMP_Execution_Time__c = System.now();
					errorRec.CSX_CMP_User__c = UserInfo.getUserId();
					if (isShipCSX) {
						errorRec.CSX_CMP_Source__c = 'ShipCSX';
					}
					errorLogList.add(errorRec);
				} else {
					successCount++;
				}
			}
			if (!errorLogList.isEmpty() && Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				Database.insert(errorLogList, false);
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexEmailErrorLog', '', ex);
		}
		return successCount;
	}

	// Helper method to create error log records
	private static void createErrorLogRecords(
		String className,
		String methodName,
		String objectName,
		Database.Error[] errors,
		String stackTrace
	) {
		List<CSX_CMP_Error_Log__c> errorLogList = new List<CSX_CMP_Error_Log__c>();
		try {
			for (Database.Error error : errors) {
				CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
				errorRec.CSX_CMP_Object_Name__c = objectName;
				errorRec.CSX_CMP_Class_Name__c = checkNResetStr(className);
				errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
				errorRec.CSX_CMP_Execution_Time__c = System.now();
				errorRec.CSX_CMP_User__c = UserInfo.getUserId();
				errorRec.CSX_CMP_Message__c = error.getMessage();
				errorRec.CSX_CMP_Stack_Trace__c = stackTrace;
				for (String field : error.getFields()) {
					errorRec.CSX_CMP_Parameters__c += field + '; ';
				}
				if (isShipCSX) {
					errorRec.CSX_CMP_Source__c = 'ShipCSX';
				}
				errorLogList.add(errorRec);
			}
			if (!errorLogList.isEmpty() && Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				Database.insert(errorLogList, false);
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'createErrorLogRecords', '', ex);
		}
	}

	/*****************************************************************************************
    Method : addApexDMLErrorLog
        Description : This method logs an error message during Update/Insert DML Operations and returns the success count
         ******************************************************************************************/
	public static Integer addApexDMLErrorLog(
		String className,
		String methodName,
		Database.SaveResult[] updateResults,
		String objectName
	) {
		Integer successCount = 0;
		try {
			for (Integer i = 0; i < updateResults.size(); i++) {
				Database.SaveResult sr = updateResults[i];
				if (!sr.isSuccess()) {
					createErrorLogRecords(className, methodName, objectName, sr.getErrors(), String.valueOf(updateResults[i]));
				} else {
					successCount++;
				}
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexDMLErrorLog', '', ex);
		}

		return successCount;
	}

	/*****************************************************************************************
    Method : addApexDMLErrorLog
        Description : This method logs an error message during DML Operations and returns the success count
         ******************************************************************************************/
	public static Integer addApexDMLErrorLog(
		String className,
		String methodName,
		Database.SaveResult result,
		String objectName
	) {
		Integer successCount = 0;
		try {
			if (!result.isSuccess()) {
				createErrorLogRecords(className, methodName, objectName, result.getErrors(), String.valueOf(result));
			} else {
				successCount++;
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', ex.getMessage(), '', ex);
		}

		return successCount;
	}

	/*****************************************************************************************
    Method : addApexDMLErrorLog
        Description : This method logs an error message during Upsert DML Operations and returns the success count
         ******************************************************************************************/
	public static Integer addApexDMLErrorLog(
		String className,
		String methodName,
		Database.UpsertResult[] upsertResults,
		String objectName
	) {
		Integer successCount = 0;
		try {
			for (Integer i = 0; i < upsertResults.size(); i++) {
				Database.UpsertResult sr = upsertResults[i];
				if (!sr.isSuccess()) {
					createErrorLogRecords(className, methodName, objectName, sr.getErrors(), String.valueOf(upsertResults[i]));
				} else {
					successCount++;
				}
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexDMLErrorLog', '', ex);
		}

		return successCount;
	}

	/*****************************************************************************************
    Method : addApexDMLErrorLog
        Description : This method logs an error message during Delete DML Operations and returns the success count
         ******************************************************************************************/
	public static Integer addApexDMLErrorLog(
		String className,
		String methodName,
		Database.DeleteResult[] deleteResults,
		String objectName
	) {
		Integer successCount = 0;

		try {
			for (Integer i = 0; i < deleteResults.size(); i++) {
				Database.DeleteResult sr = deleteResults[i];
				if (!sr.isSuccess()) {
					createErrorLogRecords(className, methodName, objectName, sr.getErrors(), String.valueOf(deleteResults[i]));
				} else {
					successCount++;
				}
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexDMLErrorLog', '', ex);
		}

		return successCount;
	}

	/*****************************************************************************************
    Method : addApexDMLErrorLog
        Description : This method logs an error message during UnDelete DML Operations and returns the success count
         ******************************************************************************************/
	public static Integer addApexDMLErrorLog(
		String className,
		String methodName,
		Database.UndeleteResult[] undeleteResults,
		String objectName
	) {
		Integer successCount = 0;

		try {
			for (Integer i = 0; i < undeleteResults.size(); i++) {
				Database.UnDeleteResult sr = undeleteResults[i];
				if (!sr.isSuccess()) {
					createErrorLogRecords(className, methodName, objectName, sr.getErrors(), String.valueOf(undeleteResults[i]));
				} else {
					successCount++;
				}
			}
		} catch (Exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addApexDMLErrorLog', '', ex);
		}

		return successCount;
	}

	/*****************************************************************************************
    Method : addClientErrorLog
        Description : This method logs an error message for Client Error Log object.
         ******************************************************************************************/
	@AuraEnabled
	public static void addClientErrorLog(
		String className,
		String methodName,
		String message,
		String exceptiontype,
		String parameters
	) {
		try {
			Database.DMLOptions dmlOptions = new Database.DMLOptions();
			dmlOptions.allowFieldTruncation = true;
			dmlOptions.optAllOrNone = false;
			CSX_CMP_Error_Log__c errorRec = new CSX_CMP_Error_Log__c();
			errorRec.CSX_CMP_Class_Name__c = checkNResetStr(className);
			errorRec.CSX_CMP_Method_Name__c = checkNResetStr(methodName);
			errorRec.CSX_CMP_Message__c = checkNResetStr(message);
			errorRec.CSX_CMP_Exception_Type__c = exceptiontype;
			errorRec.CSX_CMP_Parameters__c = parameters;
			errorRec.CSX_CMP_Execution_Time__c = System.now();
			errorRec.CSX_CMP_User__c = UserInfo.getUserId();
			if (isShipCSX) {
				errorRec.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Error_Log__c.isCreateable()) {
				Database.insert(errorRec, dmlOptions);
			}
		} catch (exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', ex.getMessage(), '', ex);
		}
	}

	/*****************************************************************************************
    Method : addExecutionLog
        Description : This method logs batch execution details for all batch jobs.
         ******************************************************************************************/
	public static void addExecutionLog(String className, String processName, String objectName, Integer processedcount) {
		try {
			CSX_CMP_Batch_Execution_Log__c batch = new CSX_CMP_Batch_Execution_Log__c();
			batch.CSX_CMP_Class__c = className;
			batch.CSX_CMP_Object__c = objectName;
			batch.CSX_CMP_Process__c = processName;
			batch.CSX_CMP_Count__c = processedcount;
			batch.CSX_CMP_Execution_Time__c = System.now();
			if (isShipCSX) {
				batch.CSX_CMP_Source__c = 'ShipCSX';
			}
			if (Schema.sObjectType.CSX_CMP_Batch_Execution_Log__c.isCreateable()) {
				Database.insert(batch, false);
			}
		} catch (exception ex) {
			addApexErrorLog('CSX_CMP_LoggerUtility', 'addExecutionLog', '', ex);
		}
	}

	public class IntegrationTimeLogWrapper {
		public String className;
		public String integrationName;
		public String parameters;
		public DateTime responseTime;
		public decimal responseTimeLong;
	}
}