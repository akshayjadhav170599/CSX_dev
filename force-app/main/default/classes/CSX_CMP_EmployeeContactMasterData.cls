/**
@Author       - Infosys
@Name         - CSX_CMP_EmployeeContactMasterData
@Created Date - 20/08/2024
@Description  - Apex Class to create Contact of Type Employee from HCM
@RICEFW reference - CMP-I-1737
*/
@RestResource(urlMapping='/v1/contacts')
global with sharing class CSX_CMP_EmployeeContactMasterData {
    
    
    @HttpPut
    global static void doPut() {
        
        RestRequest objRequest = new RestRequest();
		RestResponse objResponse = new RestResponse();
        
        try{
        
            objRequest = RestContext.request;
			objResponse = RestContext.response;
            List<Account> accountList = new List<Account> ();

            List<Contact> contactList = new List<Contact> ();
            
            ContactMasterWrapper objConatactWrapper = (ContactMasterWrapper) json.deserialize(objRequest.requestBody.toString(), ContactMasterWrapper.class);
			
            accountList = [select Id from Account where Name = 'CSX Corporation' WITH SECURITY_ENFORCED]; 

            contactList = [select Id from Contact where CSX_CMP_RACF_ID__c =: objConatactWrapper.reportsToUserId WITH SECURITY_ENFORCED];
            
            Contact objContact = new Contact();
            
            objContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
            
            if(contactList != null && contactList.size() > 0)
            {
                objContact.ReportsToId = contactList[0].Id;
            }

            if(accountList != null && accountList.size() > 0)
            {
                objContact.AccountId = accountList[0].Id;
            }
            
            //if(!string.isempty(objConatactWrapper.employeeStatus) && ((objConatactWrapper.employeeStatus == 'A') || (objConatactWrapper.employeeStatus == 'F') || (objConatactWrapper.employeeStatus == 'L') || (objConatactWrapper.employeeStatus == 'P') || (objConatactWrapper.employeeStatus == 'S'))){
            if(!string.isempty(objConatactWrapper.employeeStatus) && ((objConatactWrapper.employeeStatus == 'Active - Payroll Eligible') || (objConatactWrapper.employeeStatus == 'Active - No Payroll'))){
                objContact.CSX_CMP_Status__c = 'Active';
            }
            else{
                objContact.CSX_CMP_Status__c = 'Inactive';
            }
            
            objContact.FirstName = objConatactWrapper.firstName;
            objContact.LastName = objConatactWrapper.lastName;
            objContact.Title = objConatactWrapper.title;            
            objContact.Email = objConatactWrapper.email;
            objContact.Phone = objConatactWrapper.phone;
            objContact.CSX_CMP_RACF_ID__c = objConatactWrapper.userId;
            objContact.Department = objConatactWrapper.departmentName;
            objContact.CSX_CMP_User_Type__c = 'Employee';
            objContact.CSX_CMP_Reports_To_RACF__c = objConatactWrapper.reportsToUserId;
            objContact.MailingStreet = objConatactWrapper.address.addressLine1+' '+objConatactWrapper.address.addressLine2+' '+objConatactWrapper.address.addressLine3;
            objContact.MailingCity = objConatactWrapper.address.cityName;
            objContact.MailingState = objConatactWrapper.address.stateCode;
            objContact.CSX_CMP_Company_Name__c = 'CSX Transportation';
            objContact.MailingCountry = objConatactWrapper.address.countryCode;
            objContact.MailingPostalCode = objConatactWrapper.address.postalCode;
            objContact.CSX_CMP_External_ID__c = objConatactWrapper.userId;
            
            //Upsert Contact record based on external id
            Schema.SObjectField externalIdField = Contact.Fields.CSX_CMP_RACF_ID__c;
            Database.UpsertResult[] upsertResults = Database.upsert(new list<Contact>{objContact}, externalIdField, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_EmployeeContactMasterData',
                'doPut',
                upsertResults,
                'Contact'
            );

            if (upsertResults[0].isSuccess()) {
                objResponse.statusCode = 201;
                objResponse.addHeader('Content-Type', 'application/json');
                objResponse.responseBody = Blob.valueOf('Successfully Processed ' + objConatactWrapper.userType + ' Contact Creation/Update in Salesforce Claims.');
            } 
            else {
                list<Database.Error> lstError = upsertResults[0].getErrors();
                objResponse.statusCode = 404;
                objResponse.addHeader('Content-Type', 'application/json');
                objResponse.responseBody = Blob.valueOf(lstError[0].getMessage());
                CSX_CMP_LoggerUtility.addIntegrationErrorLog(lstError[0].getMessage(), 'Employee Contact Creation from HCM', objRequest.requestBody.toString(),'');
            }        
        }
        catch (System.DMLException e) {
            objResponse.statusCode = 500;
            objResponse.addHeader('Content-Type', 'application/json');
            objResponse.responseBody = Blob.valueOf(e.getMessage());
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(e.getMessage(), 'Employee Contact Creation from HCM', objRequest.requestBody.toString(),'');
		}
    }
    
    //Wrapper class
    global class ContactMasterWrapper {
        public String firstName;
        public String lastName;
        public String title;
        public String employeeStatus;
        public String email;
        public String phone;
        public String userId;
        public String reportsToUserId;
        public String departmentName;
        public String userType;
        public Addresswrapper address;
    }
    
    global class Addresswrapper{
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;        
        public String cityName;        
        public String stateCode;
        public String countryCode;        
        public String postalCode;
    }


}