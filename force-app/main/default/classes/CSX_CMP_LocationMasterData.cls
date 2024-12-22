/**
@Author       - Infosys
@Name         - CSX_CMP_LocationMasterData
@Created Date - 12/07/2024
@Description  - Apex Class to create Account of Type Location 
@RICEFW reference - CMP-I-1739/CMP-I-1740
*/
@RestResource(urlMapping='/v1/locations')
global with sharing class CSX_CMP_LocationMasterData {
    
    @HttpPut
    global static void doPut() { 
        
        RestRequest objRequest = new RestRequest();
		RestResponse objResponse = new RestResponse();
		 
        try{
            objRequest = RestContext.request;
			objResponse = RestContext.response;

            locationMasterWrapper objLocationWrapper = (locationMasterWrapper) json.deserialize(objRequest.requestBody.toString(), locationMasterWrapper.class);
			
            if(string.isempty(objLocationWrapper.siteType)){
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('siteType is Mandatory');
                    return;
            }
            
            if((objLocationWrapper.siteType == 'CustomerSite') && (string.isempty(objLocationWrapper.topicType))){
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('Topic Identifier is Mandatory to process Customer Site.');
                    return;
             }
            
            
            Account objAccount = new Account();
            
            if(!string.isempty(objLocationWrapper.topicType) && objLocationWrapper.topicType == 'BillingProfile')
            {
                if(string.isempty(objLocationWrapper.partyId) || string.isempty(objLocationWrapper.partySiteId))
                {
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('PartyId/PartySiteId are Mandatory');
                    return;
                }
                objAccount.CSX_CMP_External_ID__c = objLocationWrapper.partyId+'_'+objLocationWrapper.partySiteId;
                
                if(!string.isempty(objLocationWrapper.topicType) && objLocationWrapper.topicType == 'BillingProfile')
                {
                   objAccount.CSX_CMP_Freight_Collections_Team_Number__c = objLocationWrapper.freightCollectionsTeamNumber;    
                   objAccount.CSX_CMP_INCD_Collections_Team_Number__c = objLocationWrapper.incidentalCollectionsTeamNumber;    
                }
                
            }
            else
            {
            	if((objLocationWrapper.siteType == 'CustomerSite') && (string.isempty(objLocationWrapper.partySiteName))){
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('partySiteName is Mandatory to process Customer Site.');
                    return;
             	}
                
                if((objLocationWrapper.siteType == 'SupplierSite') && (string.isempty(objLocationWrapper.supplierSiteName))){
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('supplierSiteName is Mandatory to process supplierSite.');
                    return;
             	}
                
                if(string.isempty(objLocationWrapper.siteType) && (string.isempty(objLocationWrapper.partyId) || string.isempty(objLocationWrapper.partySiteId))){
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('PartyId/PartySiteId are Mandatory');
                    return;
            	}
                List<Account> lstparentAccount = new List<Account>();
                list<Account> lstcustomerName = new list<Account>();
                
    
                if(!string.isempty(objLocationWrapper.siteType) && objLocationWrapper.siteType == 'CustomerSite' && (!string.isempty(objLocationWrapper.partyId))){
                    lstparentAccount = [SELECT id, Name FROM Account WHERE Party_Id__c = :objLocationWrapper.partyId and RecordType.DeveloperName = 'Customer' WITH SECURITY_ENFORCED];
                }
                else if (!string.isempty(objLocationWrapper.siteType) && objLocationWrapper.siteType == 'SupplierSite' && (!string.isempty(objLocationWrapper.supplierId)))
                {
                    lstparentAccount = [SELECT id, Name FROM Account WHERE AccountNumber = :objLocationWrapper.supplierId and RecordType.DeveloperName = 'Supplier' WITH SECURITY_ENFORCED];
                }
                
                
                
                if(lstparentAccount == null || lstparentAccount.size() == 0)
                {
                    objResponse.statusCode = 400;
                    objResponse.addHeader('Content-Type', 'application/json');
                    objResponse.responseBody = Blob.valueOf('Related Parent Customer/Supplier is not Found');
                    return;
                }
                else
                {
                   objAccount.ParentId = lstparentAccount[0].Id;
                }
    
                if(!string.isempty(objLocationWrapper.siteType) && (objLocationWrapper.siteType == 'CustomerSite' )){
                    objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
                    objAccount.Type = 'Customer';
                    objAccount.Name = objLocationWrapper.partySiteName;
                }
                if(!string.isempty(objLocationWrapper.siteType) && (objLocationWrapper.siteType == 'SupplierSite')){
                    objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
                    objAccount.Type = 'Supplier';
                    objAccount.Name = objLocationWrapper.supplierSiteName;
                }
    
                    if(!string.isempty(objLocationWrapper.customerSiteId)){
                        lstcustomerName = [SELECT id, Name FROM Account WHERE CSX_CMP_External_ID__c =: objLocationWrapper.customerSiteId];
    
                        if(lstcustomerName != null && lstcustomerName.size() > 0){
                            objAccount.CSX_CMP_Customer_Name__c = lstcustomerName[0].id;
                        }
                    }
                
    
                
                if(!string.isempty(objLocationWrapper.status) && objLocationWrapper.status == 'X'){
                    objAccount.Status__c = 'Inactive';
                } else {
                    objAccount.Status__c = 'Active';
                }
    
                if(!string.isempty(objLocationWrapper.siteType) && (objLocationWrapper.siteType == 'CustomerSite' )){
                    objAccount.CSX_CMP_External_ID__c = objLocationWrapper.partyId+'_'+objLocationWrapper.partySiteId;
                }
                else
                {
                    objAccount.CSX_CMP_External_ID__c = objLocationWrapper.businessPartnerId+'_'+objLocationWrapper.supplierId;
                }
                
                
                objAccount.AccountNumber = objLocationWrapper.businessPartnerId;
                objAccount.Phone = objLocationWrapper.phoneNumber;
                objAccount.CSX_CMP_Operating_Unit__c = objLocationWrapper.operatingUnit;
                
                objAccount.Tax_Id__c = objLocationWrapper.taxId; 
    
                if(!string.isempty(objLocationWrapper.siteType) && objLocationWrapper.siteType == 'CustomerSite' )
                {
                    objAccount.Party_Id__c = objLocationWrapper.partyId;  
                    objAccount.Patron_Root__c = objLocationWrapper.patronRoot;
                    objAccount.Party_Score__c = objLocationWrapper.partyScore;
                    objAccount.Party_Site_ID__c = objLocationWrapper.partySiteId;
                    objAccount.Care_of_Name__c = objLocationWrapper.careOfName;
                    objAccount.Patron_Code__c = objLocationWrapper.patronCode;
                    objAccount.Party_Site_Score__c = objLocationWrapper.partySiteScore;
                    objAccount.Site = objLocationWrapper.siteCode;
                    objAccount.LE1_Code__c = objLocationWrapper.legalEntityId; 
                    objAccount.Le_Code__c = objLocationWrapper.legalEntityAtLocationId;
                    objAccount.IIDS_Key__c = objLocationWrapper.aumProfileId; 
                  
                    
                }
                if(!string.isempty(objLocationWrapper.siteType) && objLocationWrapper.siteType == 'SupplierSite' )
                {
                    objAccount.Payment_Method__c = objLocationWrapper.paymentMethod;
                    objAccount.Bank_Account_Number__c = objLocationWrapper.bankAccountNumber;
                    objAccount.Bank_Name__c = objLocationWrapper.bankName;
                    objAccount.Bank_City__c = objLocationWrapper.bankCity;
                    objAccount.Payment_Term__c = objLocationWrapper.paymentTerm;            
                    objAccount.Supplier_type__c = objLocationWrapper.supplierType;
                    objAccount.CSX_CMP_FC_Railroad_Road_Code__c = objLocationWrapper.freightRailNumericRoadCode;
                    objAccount.CSX_CMP_FC_SCAC__c = objLocationWrapper.freightScac;
                    objAccount.CSX_CMP_FC_Gross_Net_Customer__c = objLocationWrapper.freightGrossNetCustomer;
                    objAccount.CSX_CMP_REV_Railroad_Road_Code__c = objLocationWrapper.revenueRailNumericRoadCode;
                    objAccount.CSX_CMP_REV_SCAC__c = objLocationWrapper.revenueScac;
                    objAccount.CSX_CMP_REV_Gross_Net_Customer__c = objLocationWrapper.revenueGrossNetCustomer;
                    objAccount.CSX_CMP_FC_EDI_Sender_ID__c = objLocationWrapper.freightEdiSenderId;
                    objAccount.CSX_CMP_FC_Contact_Email__c = objLocationWrapper.freightContactEmail;
                    objAccount.CSX_CMP_FC_Threshold_From__c = objLocationWrapper.thresholdFromAmount;
                    objAccount.CSX_CMP_FC_Threshold_To__c = objLocationWrapper.thresholdToAmount;
                }
    
              
                        if(!string.isempty(objLocationWrapper.addressType) && (objLocationWrapper.addressType == 'Local Address') || (objLocationWrapper.addressType == 'Shipping Address'))
                        {
                            objAccount.Location_Type__c = 'Local Address';
                        }
                        else
                        {
                            objAccount.Location_Type__c = 'Billing Address';
                        }        
                        
                        objAccount.BillingStreet = objLocationWrapper.address.addressLine1;
                        objAccount.BillingStreet += objLocationWrapper.address.addressLine2;
                        objAccount.BillingStreet += objLocationWrapper.address.addressLine3;
                        objAccount.BillingStreet += objLocationWrapper.address.addressLine4;
                        objAccount.BillingCity = objLocationWrapper.address.cityName;
                        objAccount.BillingCountry = objLocationWrapper.address.countyName;
                        objAccount.BillingPostalCode = objLocationWrapper.address.postalCode;
                        objAccount.BillingState = objLocationWrapper.address.stateCode;
                  
            }
			         
            
            
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
                objResponse.responseBody = Blob.valueOf('Successfully Processed '+ objLocationWrapper.siteType +' Creation/Update in Salesforce Claims.');
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
    
    // Wrapper class
    global class locationMasterWrapper {
            public String topicType;    
            public String businessPartnerId;
            public String partyId;
            public String customerName;
            public String customer333Name;
            public String status;
            public Date effectiveDate;
            public Date expirationDate;
            public String patronRoot;
            public String siteType;
            public Decimal partyScore;
            public String legalEntityId;
            public String partySiteId;
            public String careOfName;
            public String patronCode;
            public String oldPatronCode;
            public Decimal partySiteScore;
            public String legalEntityAtLocationId;
            public String partySiteName;
        	public String supplierSiteName;
            public String phoneNumber;
            public String siteCode;
            public String paymentMethod;
            public String bankAccountNumber;
            public String bankName;
            public String bankCity;
            public String paymentTerm;
            public String operatingUnit;
            public String customerSiteId;
            public String supplierType;
            public String supplierId;
            public String freightRailNumericRoadCode;
            public String freightScac;
            public String freightGrossNetCustomer;
            public String revenueRailNumericRoadCode;
            public String revenueScac;
            public String revenueGrossNetCustomer;
            public String freightEdiSenderId;
            public String freightContactEmail;
            public Decimal thresholdFromAmount;
            public Decimal thresholdToAmount;
            public String taxId;
            public String addressType;
            public String addressIdentifierFalg;
        	public String aumProfileId;
        	public String freightCollectionsTeamNumber;
        	public String incidentalCollectionsTeamNumber;
            public addresswrapper address;
    }

    global class addresswrapper{
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;
        public String addressLine4;
        public String cityName;
        public String city333;
        public String stateCode;
        public String countryCode;
        public String countyName;
        public String postalCode;
    }

}