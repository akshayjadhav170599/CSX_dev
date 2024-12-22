/**
@Author       - Infosys  
@Name         - CSX_CMP_GenerateAbstractDistributionCtrl
@Created Date - 04/08/2023
@Description  - This Apex Class is used to generate the abstract and distribution documents for claims
@RICEFW reference - CMP-E-0441
*/
public with sharing class CSX_CMP_GenerateAbstractDistributionCtrl 
{
    //This method is used to return the Claim category based on logged in user
    @AuraEnabled(cacheable=true)
    public static String checkProfileName() 
    {
        String strValue = '';
        try{
            //Need to change the below logic 
            List<CSX_CMP_Role_Access_Configuration__mdt> lstRoleAccessConfig = CSX_CMP_Role_Access_Configuration__mdt.getAll().values();
            UserRole objUserRole = [SELECT id , Name 
                                    FROM UserRole 
                                    WHERE id =: UserInfo.getUserRoleId()
                                    WITH SECURITY_ENFORCED];

            if(lstRoleAccessConfig != null && lstRoleAccessConfig.size() > 0){
                for(CSX_CMP_Role_Access_Configuration__mdt objRoleAccessConfig : lstRoleAccessConfig){
                    if(objUserRole.Name == objRoleAccessConfig.Label && objUserRole.Name == 'Claims Admin'){
                        strValue = 'Other';
                        break;
                    }
                    else if(objUserRole.Name == objRoleAccessConfig.Label && objUserRole.Name == 'Freight Claim Manager'){
                        strValue = 'Freight';
                        break;
                    }
                    else if(objUserRole.Name == objRoleAccessConfig.Label 
                            && (objUserRole.Name == 'Revenue Railroad Manager' || objUserRole.Name == 'Revenue Railroad User')){
                        strValue = 'Revenue';
                        break;
                    }
                }
            }
            
            if(string.isEmpty(strValue)){
                strValue = 'Other';
            }
            /*Profile objProfile = [SELECT Id, Name from Profile where Id =: UserInfo.getProfileId()];
			
            if(objProfile.Name.toUpperCase().contains('FREIGHT')){
                strValue = 'Freight';
            }
            else if(objProfile.Name.toUpperCase().contains('REVENUE')){
                strValue = 'Revenue';
            }
            //strValue = 'Freight';*/
        }
        catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_GenerateAbstractDistribution', 'checkProfileName', UserInfo.getProfileId(), ex);  
        }
        return strValue;
    }

    //This method is used to get the Carrier Alpha code based on the values provided on screen by user
    @AuraEnabled(cacheable=true)
    public static List<String> searchCarrierAlphaCode(String strSelectedValue, String strServicePeriod, String strRunFor) 
    {
        if(string.isempty(strServicePeriod)){
            strServicePeriod = CSX_CMP_Utility.calculateServicePeriod();
        }

        List<String> uniqueRRCodes = new List<String>();

        try 
        {
            list<Case> lstCases = fetchClaim(strSelectedValue, strServicePeriod, strRunFor , '');
            if(lstCases != null && !lstCases.isEmpty()){
                for(Case objCase : lstCases){
                    if(!string.isempty(strSelectedValue) && strSelectedValue == 'Freight'){
                        if(!uniqueRRCodes.contains(objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c)){
                            uniqueRRCodes.add(objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c);
                        }
                    }else{
                        if(!uniqueRRCodes.contains(objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c)){
                            uniqueRRCodes.add(objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c);    
                        }
                    }
                }
            }
        }
        catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_GenerateAbstractDistribution', 'searchCase', strSelectedValue+'_'+strServicePeriod+'_'+strRunFor, ex);  
        }
        return uniqueRRCodes;
    }
    
    //This is the common method used to get the claim
    public static list<Case> fetchClaim(String strRecordType, String strServicePeriod, String strRunFor, string strSpecificRR)
    {
        List<Case> lstCase  = new List<Case>();
        try
        {
            string strStatus = 'Pending Monthly Settlement';
            String strQuery = 'SELECT id, CSX_CMP_Supplier_Claimant__r.Name, CaseNumber,CSX_CMP_Case_Number_Formula__c, CSX_CMP_Supplier_Claimant_City_State_Zip__c,' +
                            'CSX_CMP_Currency_Code__c,CSX_CMP_Service_Period__c,CSX_CMP_Supplier_Claimant_Street__c,' +
                            'CSX_CMP_Customer_Claim_Date__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c,' +
                            'CSX_CMP_Supplier_Claimant__r.CSX_CMP_Rev_Railroad_Road_Code__c,'+
                            'CSX_CMP_Customer__r.CSX_CMP_Class_1_Railroad__c,CSX_CMP_Claim_Amount__c,'+
                            'CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c,CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c,' +
                            'CSX_CMP_Claim_Date__c, CSX_CMP_VIN__c';
        
            if(!string.isempty(strRecordType) && strRecordType == 'Freight')
            {
                strQuery +=  ',(SELECT id, CSX_CMP_Waybill_Num__c, CSX_CMP_Waybill_Date__c, CSX_CMP_Equipment_Initial__c,CSX_CMP_Equipment_Num__c from Equipments__r)';
            }
            
            strQuery += ' FROM Case WHERE RecordType.DeveloperName =: strRecordType' +
                        ' AND Status =: strStatus' +
                        ' AND CSX_CMP_Service_Period__c =: strServicePeriod';
                                
            if(!string.isempty(strRecordType) && strRecordType == 'Freight'){
                string strFCRROut = 'FC RR Outbound Claim';
                string strRechrgOut = 'Recharges Outbound Claim';
                strQuery += ' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c != null AND (Type =: strFCRROut OR Type =: strRechrgOut) ';           
            }else if(!string.isempty(strRecordType) && strRecordType == 'Revenue_Railroad'){
                string strRevRR = 'Rev-RR - Receivable Claim';
                string strRevRRRechrg = 'Rev-RR - Receivable Rchg Claim';
                strQuery +=  '  AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c != null AND (Type =: strRevRR OR Type =: strRevRRRechrg)'; 
            }

            if(!string.isempty(strRunFor) && strRunFor == 'Class 1')
            {
                strQuery += ' AND CSX_CMP_Customer__r.CSX_CMP_Class_1_Railroad__c = True';
            }
            else if(!string.isempty(strRunFor) && strRunFor == 'Non Class 1')
            {
                strQuery += ' AND CSX_CMP_Customer__r.CSX_CMP_Class_1_Railroad__c = False';
            }    
            
            if(!string.isempty(strSpecificRR)){
                if(!string.isempty(strRecordType) && strRecordType == 'Freight'){
                    strQuery += ' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c =: strSpecificRR';
                }else{
                    strQuery += ' AND CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c =: strSpecificRR';
                }
            }
            lstCase = (list<Case>) Database.query(String.escapeSingleQuotes(strQuery));
        }
        catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_GenerateAbstractDistribution', 'fetchClaim', strRecordType+'_'+strServicePeriod+'_'+strRunFor+'_'+strSpecificRR, ex);  
        }
        return lstCase;
    }

    //This method is used to get the default service period
    @AuraEnabled(cacheable=true)
    public static String calculateServicePeriod()
    {
       return CSX_CMP_Utility.calculateServicePeriod();
    }

    //This method is used to schedule the batch class based on the data provided on screen
    @AuraEnabled(cacheable=true)
    public static string scheduleBatchJob(String strSelectedValue, String strServicePeriod, String strRunFor, String strspecificRailRoad, boolean isManual) 
    {
        String strMessage = '';
        try{
            CSX_CMP_GeneratePropertyPortalBatch obj = new CSX_CMP_GeneratePropertyPortalBatch(strSelectedValue, strServicePeriod, strRunFor, strspecificRailRoad, isManual);
            Database.executeBatch(obj,10);
            strMessage = system.Label.CSX_CMP_Batch_Scheduled_Successfully;
        }
        catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_GenerateAbstractDistribution', 'scheduleBatchJob', strSelectedValue+'_'+strServicePeriod+'_'+strRunFor+'_'+strspecificRailRoad, ex);  
            strMessage = ex.getMessage();
        }
        return strMessage;
    }
}