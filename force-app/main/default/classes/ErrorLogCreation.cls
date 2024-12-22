/**
 
**/
public class ErrorLogCreation {
    public CSX_CMP_claimWrapper claimWrapper {get;set;}
    public Id errorId {
        get; 
        set{
            errorId = value;  
            getClaimDetails();
        }
    }
    public CSX_CMP_claimWrapper getClaimDetails(){
        CSX_CMP_Error_Log__c errordetails = [SELECT ID,CSX_CMP_Class_Name__c,CSX_CMP_Exception_Type__c, CSX_CMP_Execution_Time__c,CSX_CMP_Message__c,CSX_CMP_Method_Name__c,CSX_CMP_Object_Name__c,CSX_CMP_Parameters__c,CSX_CMP_Stack_Trace__c,CSX_CMP_User__c FROM CSX_CMP_Error_Log__c  WHERE Id =: errorId];
        if(errordetails != null){
            claimWrapper = new CSX_CMP_claimWrapper();
            claimWrapper.className = errordetails.CSX_CMP_Class_Name__c;
            claimWrapper.exceptionType = errordetails.CSX_CMP_Exception_Type__c;
            claimWrapper.executionTime = errordetails.CSX_CMP_Execution_Time__c;
            claimWrapper.message = errordetails.CSX_CMP_Message__c;
            claimWrapper.methodName = errordetails.CSX_CMP_Method_Name__c;
            claimWrapper.objectName = errordetails.CSX_CMP_Object_Name__c;
            claimWrapper.parameters = errordetails.CSX_CMP_Parameters__c;
            claimWrapper.stackTrace = errordetails.CSX_CMP_Stack_Trace__c;
            claimWrapper.user = errordetails.CSX_CMP_User__c;
        }
        return claimWrapper;
    }
    public class CSX_CMP_claimWrapper {
        public String className {get;set;}
        public String exceptionType {get;set;}
        public DateTime executionTime {get;set;}
        public String message {get;set;}
        public String methodName {get;set;}
        public String objectName {get;set;}
        public String parameters {get;set;}
        public String stackTrace {get;set;}
        public String user {get;set;}
       
}
}