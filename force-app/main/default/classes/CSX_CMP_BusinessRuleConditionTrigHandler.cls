/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRuleConditionTrigHandler
@Created Date - 3/8/2024
@Description  - business rules condition handler to handle backend actions and validations
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_BusinessRuleConditionTrigHandler {

    //This method is used to handle the after insert operations in trigger handler
    public static void handleAfterInsert(List<CSX_CMP_Business_Rule_Condition__c> triggerNewList){
        createWhereClauseCondition(triggerNewList); 
    }

    //This method is used to handle the after update operations in trigger handler
    public static void handleAfterUpdate(List<CSX_CMP_Business_Rule_Condition__c> triggerNewList){
        createWhereClauseCondition(triggerNewList); 
    }

    //This method is used to handle the after Delete operations in trigger handler
    public static void handleAfterDelete(List<CSX_CMP_Business_Rule_Condition__c> triggerOldList){
        createWhereClauseCondition(triggerOldList);
    }

    //This method is used to handle the before insert operations in trigger handler
    public static void handleBeforeInsert(List<CSX_CMP_Business_Rule_Condition__c> triggerNewList){
        validateSequence(triggerNewList);
        validateCondition(triggerNewList);
        // checkAttributeForLDType(triggerNewList);
    }

    //This method is used to handle the before update operations in trigger handler
    public static void handleBeforeupdate(List<CSX_CMP_Business_Rule_Condition__c> triggerNewList){
        validateSequence(triggerNewList);
        validateCondition(triggerNewList);
        // checkAttributeForLDType(triggerNewList);
    }

    //This method is used to populate the where clause condition and update the status to valid
    public static void createWhereClauseCondition(List<CSX_CMP_Business_Rule_Condition__c> lstOfBusinessCondition) 
    {
        try
        {
            Set<Id> setOfBusinessRuleId = new Set<Id>();
            List<CSX_CMP_Business_Rule__c> lstBusinessRuleToUpdate = new List<CSX_CMP_Business_Rule__c>();
            
            if (lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0)
            {
                for (CSX_CMP_Business_Rule_Condition__c objBussinesssRuleCondition : lstOfBusinessCondition) {
                    setOfBusinessRuleId.add(objBussinesssRuleCondition.CSX_CMP_Business_Rule__c);
                }
                
                Map<Id, CSX_CMP_Business_Rule__c> mapOfBusinessRule = new Map<Id, CSX_CMP_Business_Rule__c>([Select Id , Name, CSX_CMP_Where_Clause__c, (Select Id , Name from Business_Rule_Conditions__r) from  CSX_CMP_Business_Rule__c  where Id in : setOfBusinessRuleId WITH SECURITY_ENFORCED]);

                for(Id businessRuleID  : mapOfBusinessRule.keySet()){

                    CSX_CMP_Business_Rule__c objBusinessRule = mapOfBusinessRule.get(businessRuleId);
                    String strWhereClause = '';

                    if(objBusinessRule.Business_Rule_Conditions__r != null && objBusinessRule.Business_Rule_Conditions__r.size() > 0)
                    {
                        if( 
                            (String.isNotBlank(objBusinessRule.CSX_CMP_Where_Clause__c) && !objBusinessRule.CSX_CMP_Where_Clause__c.contains('OR')) || 
                            (String.isBlank(objBusinessRule.CSX_CMP_Where_Clause__c))
                        ){
                            for (CSX_CMP_Business_Rule_Condition__c objCondition : objBusinessRule.Business_Rule_Conditions__r){
                                strWhereClause += objCondition.Name + ' AND ';
                            }
                            String finalWhere = strWhereClause.substring(0, strWhereClause.length() - 4);
                            objBusinessRule.CSX_CMP_Where_Clause__c = finalWhere;
                            objBusinessRule.CSX_CMP_Status__c = 'Valid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }/*
                        else if(String.isBlank(objBusinessRule.CSX_CMP_Where_Clause__c)){
                            for (CSX_CMP_Business_Rule_Condition__c objCondition : objBusinessRule.Business_Rule_Conditions__r){
                                    strWhereClause += objCondition.Name + ' AND ';
                            }
                            String finalWhere = strWhereClause.substring(0, strWhereClause.length() - 4);
                            objBusinessRule.CSX_CMP_Where_Clause__c = finalWhere;
                            objBusinessRule.CSX_CMP_Status__c = 'Valid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }*/else{
                            objBusinessRule.CSX_CMP_Status__c = 'Invalid';
                            lstBusinessRuleToUpdate.add(objBusinessRule);
                        }
                    }
                }

                if (lstBusinessRuleToUpdate.size() > 0) {
                    Database.SaveResult[] updateBusinessRule = Database.update(lstBusinessRuleToUpdate, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_BusinessRuleConditionTrigHandler',
                        'createWhereClauseCondition',
                        updateBusinessRule,
                        'BusinessRuleId'
                    );
                }
            }
            if(Test.isRunningTest()) {
                    throw new DMLException();
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'createWhereClauseCondition','', ex);  
        }     
    }

    /*public static void checkAttributeForLDType(List<CSX_CMP_Business_Rule_Condition__c> lstOfBusinessCondition) {
        try{
            String businessRuleRecordTypeId = CSX_CMP_BusinessRulesUtility.getRecordTypeIdbyName('CSX_CMP_Business_Rule__c', 'CSX_CMP_L_D_Report_Assignment');

            if(lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0){
                Set<Id> setOfBusinessRuleId = new Set<Id>();
                for (CSX_CMP_Business_Rule_Condition__c objBussinesssRuleCondition : lstOfBusinessCondition) {
                    setOfBusinessRuleId.add(objBussinesssRuleCondition.CSX_CMP_Business_Rule__c);
                }
                Map<Id, CSX_CMP_Business_Rule__c> mapOfBusinessRule = new Map<Id, CSX_CMP_Business_Rule__c>([SELECT Id , Name, CSX_CMP_Where_Clause__c,RecordTypeId,  (SELECT Id , Name, CSX_CMP_Attribute_Name__c FROM Business_Rule_Conditions__r) FROM  CSX_CMP_Business_Rule__c  WHERE Id IN : setOfBusinessRuleId WITH SECURITY_ENFORCED]);
                for(CSX_CMP_Business_Rule_Condition__c objCondition : lstOfBusinessCondition){
                    if(mapOfBusinessRule.get(objCondition.CSX_CMP_Business_Rule__c).RecordTypeId == businessRuleRecordTypeId){
                        if(objCondition.CSX_CMP_Attribute_Name__c != 'ldr_ldType'){
                            objCondition.addError(system.label.CSX_CMP_LDReport_Attribute_Check_For_Type);
                        }
                    }
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'checkAttributeForLDType',JSON.serialize(lstOfBusinessCondition), ex);  
        }    
    }*/
    
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
                            if(objBusinessRuleCondition.Name == objCondition.Name && objBusinessRuleCondition.Id != objCondition.Id){
                                objBusinessRuleCondition.adderror(system.label.CSX_CMP_Sequence_No_Already_Exist);
                            }
                        }
                    }
                }
            }
            if(Test.isRunningTest()) {
                    throw new DMLException();
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
            List<String> greaterOrLessOrEqualOperators = new List<String>{'Greater Than', 'Greater Than or Equal To', 'Less Than', 'Less Than or Equal To', 'Equal To'};
            List<String> equalOrNotEqualOperators = new List<String>{'Equal To', 'Not Equal To'};
            List<String> inListOrNotInOperators = new List<String>{'In List', 'Not In'};

            List<String> attributesforNumericCheck = new List<String>{'claim_claimAge' ,'claim_claimAmount' ,'claim_equipment_waybillDateAging' ,'claim_equipment_carNum' ,'claim_equipment_product_customerDamage_CdArea' ,'claim_equipment_product_customerDamage_cdSeverity' ,'claim_equipment_product_customerDamage_cdType' ,'claim_equipment_product_inspectionDamage_idArea' ,'claim_equipment_product_inspectionDamage_idType' ,'claim_equipment_product_inspectionDamage_idSeverity' ,'claim_equipment_product_inspectionDamage_idReportType' ,'claim_nationalAccount' ,'claim_equipment_waybillNum' ,'claim_numberofRelatedClaim' ,'claim_equipment_freightbillNum' ,'claim_equipment_urwinNum'};

            List<String> attributesforNumericCheckList2 = new List<String>{'claim_equipment_carNumInitial', 'claim_claimantName', 'claim_recordType', 'claim_claimStatus','claim_claimType','claim_contract_cType'};
            
            List<String> attributesforYesOrNoCheck = new List<String>{'claim_equipment_distribution_nonCSXMexicanRR' ,'claim_autoSettleReturnStatus' ,'claim_derailmentFlag' ,'claim_equipment_product_custDamageMatchInspRep1278' ,'claim_equipment_product_allCustDamagematchInspRep04' ,'claim_claimAmountwithinthreshold' ,'claim_equipment_product_no04InspectionCount'};

            List<String> attributesforLengthCheck = new List<String>{'claim_equipment_product_customerDamage_cdArea' ,'claim_equipment_product_customerDamage_cdSeverity' ,'claim_equipment_product_customerDamage_cdType' ,'claim_equipment_product_inspectionDamage_idArea' ,'claim_equipment_product_inspectionDamage_idType' ,'claim_equipment_product_inspectionDamage_idSeverity' ,'claim_equipment_product_inspectionDamage_idReportType'};

            if(lstOfBusinessCondition != null && lstOfBusinessCondition.size() > 0)
            {
                for(CSX_CMP_Business_Rule_Condition__c objBRCondition: lstOfBusinessCondition){

                    //date validation
                    if(objBRCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_waybillDate' && CSX_CMP_Utility.contains(greaterOrLessOrEqualOperators, objBRCondition.CSX_CMP_Operator__c) && String.isNotBlank(objBRCondition.CSX_CMP_Value__c))
                    {
                        if(objBRCondition.CSX_CMP_Value__c.contains('-') || objBRCondition.CSX_CMP_Value__c.contains('/'))
                        {
                            //Validate for Date 
                            String regex = '[0-9]{0,2}[/][0-9]{0,2}[/][0-9]{4}';
                            Pattern datePattern = Pattern.compile(regex);
                            Matcher matchDate = datePattern.matcher(objBRCondition.CSX_CMP_Value__c);

                            if(!matchDate.matches()){
                                objBRCondition.addError(system.label.CSX_CMP_Valid_Date_Format);
                            }
                        }else{
                            objBRCondition.addError(system.label.CSX_CMP_Valid_Date_Format);
                        }
                    }
                    //numeric check 
                    else if( CSX_CMP_Utility.contains(attributesforNumericCheck, objBRCondition.CSX_CMP_Attribute_Name__c)
                            && (CSX_CMP_Utility.contains(greaterOrLessOrEqualOperators, objBRCondition.CSX_CMP_Operator__c) || objBRCondition.CSX_CMP_Operator__c == 'Not Equal To') && string.isNotBlank(objBRCondition.CSX_CMP_Value__c))
                    {
                        if(!objBRCondition.CSX_CMP_Value__c.isNumeric()){ 
                            objBRCondition.addError(system.label.CSX_CMP_Validate_Numeric_Value);
                        }
                    }
                    //Yes or No check 
                    else if(CSX_CMP_Utility.contains(attributesforYesOrNoCheck, objBRCondition.CSX_CMP_Attribute_Name__c) && CSX_CMP_Utility.contains(equalOrNotEqualOperators, objBRCondition.CSX_CMP_Operator__c) && string.isNotBlank(objBRCondition.CSX_CMP_Value__c))
                    {
                        if(objBRCondition.CSX_CMP_Value__c.toupperCase() != 'YES' && objBRCondition.CSX_CMP_Value__c.toupperCase() != 'NO'){ 
                            objBRCondition.addError(system.label.CSX_CMP_Validate_YES_OR_NO_in_value);
                        }
                    }  
                    //numeric check for list attributes
                    else if(CSX_CMP_Utility.contains(attributesforNumericCheck, objBRCondition.CSX_CMP_Attribute_Name__c) && CSX_CMP_Utility.contains(inListOrNotInOperators, objBRCondition.CSX_CMP_Operator__c) && string.isNotBlank(objBRCondition.CSX_CMP_Value__c))
                    {
                        list<String> lstString = objBRCondition.CSX_CMP_Value__c.split(',');

                        for(String strValue : lstString){
                            if(!strValue.isNumeric()){
                                objBRCondition.addError(system.label.CSX_CMP_Validate_Numeric_Value);
                            }
                        }
                    }
                    //numeric check 
                    else if(CSX_CMP_Utility.contains(attributesforNumericCheckList2, objBRCondition.CSX_CMP_Attribute_Name__c) 
                            && ( CSX_CMP_Utility.contains(inListOrNotInOperators, objBRCondition.CSX_CMP_Operator__c) || CSX_CMP_Utility.contains(equalOrNotEqualOperators, objBRCondition.CSX_CMP_Operator__c)))
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
                    //email validation
                    else if((objBRCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_distribution_fCContactEmail') && CSX_CMP_Utility.contains(equalOrNotEqualOperators, objBRCondition.CSX_CMP_Operator__c))
                    {
                        String emailRegex = '^[a-zA-Z0-9._|\\\\%⌗~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
                        Pattern myPattern = Pattern.compile(emailRegex);
                        Matcher myMatcher = myPattern.matcher(objBRCondition.CSX_CMP_Value__c);

                        if (!myMatcher.matches()){
                            objBRCondition.addError(system.label.CSX_CMP_Invalid_Email_Address);
                        }
                    }
                    //length validation 
                    else if( CSX_CMP_Utility.contains(attributesforLengthCheck, objBRCondition.CSX_CMP_Attribute_Name__c))
                    {
                        if(CSX_CMP_Utility.contains(equalOrNotEqualOperators, objBRCondition.CSX_CMP_Operator__c)){
                            if(objBRCondition.CSX_CMP_Value__c.length() > 2){
                                objBRCondition.addError(system.label.CSX_CMP_Validate_Cust_and_Ins_length);
                            }
                        }
                        else if(CSX_CMP_Utility.contains(inListOrNotInOperators, objBRCondition.CSX_CMP_Operator__c)){
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
            if(Test.isRunningTest()) {
                    throw new DMLException();
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleConditionHandler', 'validateCondition','', ex);  
        }    
    }
}