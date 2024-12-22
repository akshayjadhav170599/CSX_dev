/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRuleConditionHandler
@Created Date - 3/8/2024
@Description  - business rules condition handler to handle backend actions and validations
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_BusinessRuleConditionHandler {
    
    //This method is used to handel the after insert operations in trigger handler
    public static void handleAfterInsert(List<CSX_CMP_Business_Rule_Condition__c> triggerNew){
        createWhereClauseCondition(triggerNew); 
    }

    //This method is used to handel the after update operations in trigger handler
    public static void handleAfterUpdate(List<CSX_CMP_Business_Rule_Condition__c> triggerNew){
        createWhereClauseCondition(triggerNew); 
    }

    //This method is used to handel the after Delete operations in trigger handler
    public static void handleAfterDelete(List<CSX_CMP_Business_Rule_Condition__c> triggerOld){
        createWhereClauseCondition(triggerOld);
    }

    //This method is used to handel the before insert operations in trigger handler
    public static void handleBeforeInsert(List<CSX_CMP_Business_Rule_Condition__c> triggerNew){
        validateSequence(triggerNew);
        validateCondition(triggerNew);
    }

    //This method is used to handel the before update operations in trigger handler
    public static void handleBeforeupdate(List<CSX_CMP_Business_Rule_Condition__c> triggerNew){
        validateSequence(triggerNew);
        validateCondition(triggerNew);
    }

    //This method is used to populate the where clause condition and update the status to valid
    public static void createWhereClauseCondition(List<CSX_CMP_Business_Rule_Condition__c> lstOfBusinessCondition) 
    {
        try
        {
            Set<Id> setOfBusinessRuleId = new Set<Id>();
            // Map<Id, List<CSX_CMP_Business_Rule_Condition__c>> mapOfBusinessRuleandListCondtion = new Map<Id, List<CSX_CMP_Business_Rule_Condition__c>>();
            List<CSX_CMP_Business_Rule__c> lstBusinessRuleToUpdate = new List<CSX_CMP_Business_Rule__c>();
            
            if (lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0)
            {
                for (CSX_CMP_Business_Rule_Condition__c objBussinesssRuleCondition : lstOfBusinessCondition) {
                    setOfBusinessRuleId.add(objBussinesssRuleCondition.CSX_CMP_Business_Rule__c);
                }
                
                Map<id, CSX_CMP_Business_Rule__c> mapOfBusinessRule = new Map<id, CSX_CMP_Business_Rule__c>([Select id , Name, CSX_CMP_Where_Clause__c,
                                                                                                            (Select id , Name from Business_Rule_Conditions__r order by Name Asc)
                                                                                                            from  CSX_CMP_Business_Rule__c
                                                                                                            where Id in : setOfBusinessRuleId
                                                                                                            WITH SECURITY_ENFORCED]);

                for(id businessRuleID  : mapOfBusinessRule.keySet()){

                    CSX_CMP_Business_Rule__c objBusinessRule = mapOfBusinessRule.get(businessRuleId);
                    String strWhereClause = '';

                    if(objBusinessRule.Business_Rule_Conditions__r != null && objBusinessRule.Business_Rule_Conditions__r.size() > 0)
                    {
                        if(String.isNotBlank(objBusinessRule.CSX_CMP_Where_Clause__c) && !objBusinessRule.CSX_CMP_Where_Clause__c.contains('OR')){
                            for (CSX_CMP_Business_Rule_Condition__c objCondition : objBusinessRule.Business_Rule_Conditions__r){
                                    strWhereClause += objCondition.Name + ' ' + 'AND ';
                            }
                            String finalWhere = strWhereClause.substring(0, strWhereClause.length() - 4);
                            objBusinessRule.CSX_CMP_Where_Clause__c = finalWhere;
                            objBusinessRule.CSX_CMP_Status__c = 'Valid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }
                        else if(String.isBlank(objBusinessRule.CSX_CMP_Where_Clause__c)){
                            for (CSX_CMP_Business_Rule_Condition__c objCondition : objBusinessRule.Business_Rule_Conditions__r){
                                    strWhereClause += objCondition.Name + ' ' + 'AND ';
                            }
                            String finalWhere = strWhereClause.substring(0, strWhereClause.length() - 4);
                            objBusinessRule.CSX_CMP_Where_Clause__c = finalWhere;
                            objBusinessRule.CSX_CMP_Status__c = 'Valid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }else{
                            objBusinessRule.CSX_CMP_Status__c = 'Invalid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }
                    }
                }
                if (lstBusinessRuleToUpdate.size() > 0) {
                    Database.SaveResult[] updateBusinessRule = Database.update(lstBusinessRuleToUpdate, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_BusinessRuleConditionHandler',
                        'createWhereClauseCondition',
                        updateBusinessRule,
                        'BusinessRuleId'
                    );
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'createWhereClauseCondition','', ex);  
        }     
    }
    
    //This method run on before insert and update to check the sequence number already exist or not
    public static void validateSequence(List<CSX_CMP_Business_Rule_Condition__c> lstOfBusinessCondition) 
    {
        try
        {
            if(lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0){
                Set<Id> setOfBusinessId = new Set<Id>();
                Map<Id, list<CSX_CMP_Business_Rule_Condition__c>> mapOfBusinessRuleWithCondition = new Map<ID, list<CSX_CMP_Business_Rule_Condition__c>>();
                
                for(CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : lstOfBusinessCondition){
                    setOfBusinessId.add(objBusinessRuleCondition.CSX_CMP_Business_Rule__c);
                }
                
                List<CSX_CMP_Business_Rule_Condition__c> listOfExistingBRCondition = [SELECT Id, Name, CSX_CMP_Business_Rule__c
                                                                                    FROM CSX_CMP_Business_Rule_Condition__c
                                                                                    WHERE CSX_CMP_Business_Rule__c IN :setOfBusinessId
                                                                                    WITH SECURITY_ENFORCED];
                
                for (CSX_CMP_Business_Rule_Condition__c objExistingCondition : listOfExistingBRCondition) {
                    if(mapOfBusinessRuleWithCondition.get(objExistingCondition.CSX_CMP_Business_Rule__c) == null){
                        mapOfBusinessRuleWithCondition.put(objExistingCondition.CSX_CMP_Business_Rule__c, new list<CSX_CMP_Business_Rule_Condition__c>());
                    }
                    mapOfBusinessRuleWithCondition.get(objExistingCondition.CSX_CMP_Business_Rule__c).add(objExistingCondition);
                }
                
                if(mapOfBusinessRuleWithCondition != null && mapOfBusinessRuleWithCondition.size() > 0){
                    for(CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : lstOfBusinessCondition){
                        for(CSX_CMP_Business_Rule_Condition__c objCondition : mapOfBusinessRuleWithCondition.get(objBusinessRuleCondition.CSX_CMP_Business_Rule__c)){
                            if(objBusinessRuleCondition.Name == objCondition.Name && objBusinessRuleCondition.id != objCondition.id){
                                objBusinessRuleCondition.adderror(system.label.CSX_CMP_Sequence_No_Already_Exist);
                            }
                        }
                    }
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'validateSequence','', ex);  
        } 
    }

    //This method is used to validate the business rule condition so that the value entered by the used are correct
    public static void validateCondition(List<CSX_CMP_Business_Rule_Condition__c> lstOfBusinessCondition) 
    {
        try
        {
            if(lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0)
            {
                for(CSX_CMP_Business_Rule_Condition__c objBRCondition: lstOfBusinessCondition){
                    if(objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_WaybillDate' 
                        && (objBRCondition.CSX_CMP_Operator__c == 'Greater Than' || objBRCondition.CSX_CMP_Operator__c == 'Greater Than or Equal To' 
                        || objBRCondition.CSX_CMP_Operator__c == 'Less Than' || objBRCondition.CSX_CMP_Operator__c == 'Less Than or Equal To'
                        || objBRCondition.CSX_CMP_Operator__c == 'Equal To'))
                    {
                        if(String.isNotBlank(objBRCondition.CSX_CMP_Value__c)) 
                        {
                            if(objBRCondition.CSX_CMP_Value__c.contains('-') || objBRCondition.CSX_CMP_Value__c.contains('/'))
                            {
                                //Validate for Date 
                                String regex = '[0-9]{0,2}[-/][0-9]{0,2}[-/][0-9]{4}';
                                Pattern datePattern = Pattern.compile(regex);
                                Matcher matchDate = datePattern.matcher(objBRCondition.CSX_CMP_Value__c);

                                if(!matchDate.matches()){
                                    objBRCondition.addError(system.label.CSX_CMP_Valid_Date_Format);
                                }
                            }else{
                                objBRCondition.addError(system.label.CSX_CMP_Valid_Date_Format);
                            }
                        }
                    }
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Age' 
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Amount'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_WaybillDateAging'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_CarNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdReportType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_NationalAccount'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_WaybillNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_NumberofRelatedClaim'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_FreightbillNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_UrwinNum') 
                            && (objBRCondition.CSX_CMP_Operator__c == 'Greater Than' || objBRCondition.CSX_CMP_Operator__c == 'Greater Than or Equal To' 
                            || objBRCondition.CSX_CMP_Operator__c == 'Less Than' || objBRCondition.CSX_CMP_Operator__c == 'Less Than or Equal To'
                            || objBRCondition.CSX_CMP_Operator__c == 'Equal To' || objBRCondition.CSX_CMP_Operator__c == 'Not Equal To'))
                    {
                        if(string.isNotBlank(objBRCondition.CSX_CMP_Value__c) && !objBRCondition.CSX_CMP_Value__c.isNumeric()){ 
                            objBRCondition.addError(system.label.CSX_CMP_Validate_Numeric_Value);
                        }
                    }
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Distribution_NonCSXMexicanRR' 
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_AutoSettleReturnStatus'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_DerailmentFlag'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_custDamageMatchInspRep1278'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_allCustDamagematchInspRep04'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_ClaimAmountwithinthreshold'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_No04InspectionCount')
                            && (objBRCondition.CSX_CMP_Operator__c == 'Equal To'|| objBRCondition.CSX_CMP_Operator__c == 'Not Equal To'))
                    {
                        if(string.isNotBlank(objBRCondition.CSX_CMP_Value__c) && (objBRCondition.CSX_CMP_Value__c.toupperCase() != 'YES'
                            && objBRCondition.CSX_CMP_Value__c.toupperCase() != 'NO')){ 
                            objBRCondition.addError(system.label.CSX_CMP_Validate_YES_OR_NO_in_value);
                        }
                    }  
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_CarNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdReportType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_NationalAccount'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_WaybillNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_FreightbillNum'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_UrwinNum')
                            && (objBRCondition.CSX_CMP_Operator__c == 'In List' || objBRCondition.CSX_CMP_Operator__c == 'Not In') 
                            && string.isNotBlank(objBRCondition.CSX_CMP_Value__c))
                    {
                        list<String> lstString = objBRCondition.CSX_CMP_Value__c.split(',');

                        for(String strValue : lstString){
                            if(!strValue.isNumeric()){
                                objBRCondition.addError(system.label.CSX_CMP_Validate_Numeric_Value);
                            }
                        }
                    }
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_CarNumInitial'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_ClaimantName'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_RecordType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Status'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Type'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Contract_CType') 
                            && (objBRCondition.CSX_CMP_Operator__c == 'In List' || objBRCondition.CSX_CMP_Operator__c == 'Not In'
                            || objBRCondition.CSX_CMP_Operator__c == 'Equal To' || objBRCondition.CSX_CMP_Operator__c == 'Not Equal To'))
                    {
                        if(string.isNotBlank(objBRCondition.CSX_CMP_Value__c) && !objBRCondition.CSX_CMP_Value__c.contains(',') 
                            && objBRCondition.CSX_CMP_Value__c.isNumeric()){
                            objBRCondition.addError(system.label.CSX_CMP_Validate_non_numeric_value);
                        }else{
                            list<String> lstString = objBRCondition.CSX_CMP_Value__c.split(',');
                            for(String strValue : lstString){
                                if(strValue.isNumeric()){
                                    objBRCondition.addError(system.label.CSX_CMP_Validate_non_numeric_value);
                                }
                            }
                        }
                    }
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Distribution_FCContactEmail')
                            && (objBRCondition.CSX_CMP_Operator__c == 'Equal To' || objBRCondition.CSX_CMP_Operator__c == 'Not Equal To'))
                    {
                        String emailRegex = '^[a-zA-Z0-9._|\\\\%⌗~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
                        Pattern myPattern = Pattern.compile(emailRegex);
                        Matcher myMatcher = myPattern.matcher(objBRCondition.CSX_CMP_Value__c);

                        if (!myMatcher.matches()){
                            objBRCondition.addError(system.label.CSX_CMP_Invalid_Email_Address);
                        }
                    }
                    else if(objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_CustomerDamage_CdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdArea'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdType'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdSeverity'
                            || objBRCondition.CSX_CMP_Attribute_Name__c == 'Claim_Equipment_Product_InspectionDamage_IdReportType')
                    {
                        if(objBRCondition.CSX_CMP_Operator__c == 'Equal To' || objBRCondition.CSX_CMP_Operator__c == 'Not Equal To'){
                            if(objBRCondition.CSX_CMP_Value__c.length() > 2){
                                objBRCondition.addError(system.label.CSX_CMP_Validate_Cust_and_Ins_length);
                            }
                        }
                        else if(objBRCondition.CSX_CMP_Operator__c == 'In List' || objBRCondition.CSX_CMP_Operator__c == 'Not In'){
                            list<String> lstString = objBRCondition.CSX_CMP_Value__c.split(',');
                            for(String strValue : lstString){
                                if(strValue.length() > 2){
                                    objBRCondition.addError(system.label.CSX_CMP_Validate_Cust_and_Ins_length);
                                }
                            }
                        }
                    }
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'validateCondition','', ex);  
        }    
    }
}