/**************************************************************************************
Apex Class Name     : CSX_CMP_Fetch_3PL_AccountsWebservice
Function            : This class is to send 3PL Accounts to SHIPCSX based on the Contact's RACF ID
Author              : Infosys
Modification Log    :
* Developer         : Date             Description
* ----------------------------------------------------------------------------                 
* Infosys           28/03/2024        First version of this class.
*************************************************************************************/
@RestResource(urlMapping='/v1/contacts/*/accounts') 
global with sharing class CSX_CMP_Fetch_3PL_AccountsWebservice {
    @HttpGet
    global static void fetchInvEmailSubscriptions (){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        // ThirdPartyAccountWrapper accountWrapper = new ThirdPartyAccountWrapper();
        List<AccountRespWrap> accountRespWrapList = new List<AccountRespWrap>();
        try
        {   
            List<String> urlParts = req.requestURI.toString().split('/');
            String racfId = urlParts.get(urlParts.size()-2);
            if(racfId == null || racfId == '' || racfId == 'null'){
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Invalid Request');
                return;
            }
            String query = 'select AccountId from AccountContactRelation where Contact.CSX_CMP_RACF_ID__c = :racfId';
            
            List<AccountContactRelation> accountContactRelList = Database.query(query);
            if (accountContactRelList.isEmpty()) {
				AccountRespWrap lineItem = new AccountRespWrap();
                        lineItem.companyName = '';
                        lineItem.customerNumber = '';
                        accountRespWrapList.add(lineItem);
                        res.statusCode = 404;
                        res.addHeader('Content-Type', 'application/json');
                        res.responseBody = Blob.valueOf('No Contact found with the given RACF ID');
            
			}
            else
            {
                List<Id> accId = new List<Id>();
                for (AccountContactRelation acc : accountContactRelList) 
                {
                    accId.add(acc.AccountId);
                }
                
                for(Account acc : [SELECT Id,AccountNumber,Name FROM Account WHERE Id = :accId WITH SECURITY_ENFORCED])
                {
                    AccountRespWrap lineItem = new AccountRespWrap();
                    lineItem.companyName = acc.Name;
                    lineItem.customerNumber = acc.AccountNumber;
                    accountRespWrapList.add(lineItem);                        
                }
                res.statusCode = 200;
                res.addHeader('Content-Type', 'application/json');
                res.responseBody = Blob.valueOf(JSON.serialize(accountRespWrapList));
            }
               
        } catch (Exception e){
            res.statusCode = 400;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf('No Contact found with the given RACF ID');
            CSX_CMP_LoggerUtility.addIntegrationErrorLog(e.getMessage(), 'Fetch 3rd Party Account', req.requestURI.toString(),'');
             
        }
    }
    
    global class ThirdPartyAccountWrapper {
        public List<AccountRespWrap> accountResponses;
    }
    
    public class AccountRespWrap{
        public String companyName;
        public String customerNumber;
    }

}