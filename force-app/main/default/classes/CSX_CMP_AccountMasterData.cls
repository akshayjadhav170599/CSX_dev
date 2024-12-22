/**
@Author       - Infosys
@Name         - CSX_CMP_AccountMasterData
@Created Date - 12/07/2024
@Description  - Apex Class to create Account of Type Customer 
@RICEFW reference - CMP-I-1739/CMP-I-1740
*/
@RestResource(urlMapping='/v1/accounts')
global with sharing class CSX_CMP_AccountMasterData {

    @HttpPut
    global static void doPut() {

        RestRequest objRequest = new RestRequest();
		RestResponse objResponse = new RestResponse();
		
        try{
            objRequest = RestContext.request;
			objResponse = RestContext.response;

            AccountMasterWrapper objAccountWrapper = (AccountMasterWrapper) json.deserialize(objRequest.requestBody.toString(), AccountMasterWrapper.class);

            if(string.isempty(objAccountWrapper.accountType)){
                objResponse.statusCode = 400;
                objResponse.addHeader('Content-Type', 'application/json');
                objResponse.responseBody = Blob.valueOf('accountType is Mandatory');
                return;
            }
            
            Account objAccount = new Account();
            
            if(!string.isempty(objAccountWrapper.accountType) && objAccountWrapper.accountType == 'Customer'){
                objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
                objAccount.Name = objAccountWrapper.customerName;
               
            }else{
                objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Supplier').getRecordTypeId();
                objAccount.Name = objAccountWrapper.supplierName;
            }

            if(!string.isempty(objAccountWrapper.status) && objAccountWrapper.status == 'X'){
                objAccount.Status__c = 'Inactive';
            } else {
                objAccount.Status__c = 'Active';
            }

            if(!string.isempty(objAccountWrapper.accountType) && objAccountWrapper.accountType == 'Customer'){
                objAccount.CSX_CMP_External_ID__c = objAccountWrapper.partyId;
            }
            else
            {
                objAccount.CSX_CMP_External_ID__c = objAccountWrapper.businessPartnerId;
            }

            objAccount.party_Id__c = objAccountWrapper.partyId;
            objAccount.AccountNumber = objAccountWrapper.businessPartnerId;
            objAccount.Patron_Root__c = objAccountWrapper.patronRoot;
            objAccount.National_Account__c = objAccountWrapper.nationalAccountNumber;
            objAccount.Party_Score__c = objAccountWrapper.partyScore;
            objAccount.LE1_Code__c = objAccountWrapper.legalEntityId;
            objAccount.Tax_Id__c = objAccountWrapper.taxId;
            objAccount.Care_of_Name__c = objAccountWrapper.customerShortName;

            //Upsert Account record based on external id
            Schema.SObjectField externalIdField = Account.Fields.CSX_CMP_External_ID__c;
            Database.UpsertResult[] upsertResults = Database.upsert(new list<Account>{objAccount}, externalIdField, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_CustomerMasterData',
                'doPut',
                upsertResults,
                'Account'
            );

            if (upsertResults[0].isSuccess()) {
                objResponse.statusCode = 201;
                objResponse.addHeader('Content-Type', 'application/json');
                objResponse.responseBody = Blob.valueOf('Successfully Processed ' + objAccountWrapper.accountType + ' Creation/Update in Salesforce Claims.');
            } 
            else {
                list<Database.Error> lstError = upsertResults[0].getErrors();
                objResponse.statusCode = 400;
                objResponse.addHeader('Content-Type', 'application/json');
                objResponse.responseBody = Blob.valueOf(lstError[0].getMessage());
            }
        }
        catch (System.DMLException e) {
            objResponse.statusCode = 400;
            objResponse.addHeader('Content-Type', 'application/json');
            objResponse.responseBody = Blob.valueOf(e.getMessage());
		}
    }

    //Wrapper class
    global class AccountMasterWrapper {
        public String businessPartnerId;
        public String partyId;
        public String customerName;
        public String customer333Name;
        public String customerShortName;
        public String supplierName;
        public String status;
        public String patronRoot;
        public String oldPatronRoot;
        public String nationalAccountNumber;
        public String accountType;
        public Decimal partyScore;
        public String legalEntityId;
        public String taxId;
        public String customerType;
        public Date effectiveDate;
        public Date expirationDate;
    }
}