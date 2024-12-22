/**
@Author       - Infosys
@Name         - CSX_CMP_ValidateRule
@Created Date - 10/18/2023
@Description  - Apex Class to Validate the business rules
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_ValidateRule {
    @AuraEnabled
    public static Integer evaluateWhereClause(String id)
    {
        boolean isResult = true;
        Integer intMessage = 0;

        try
        {
            CSX_CMP_Business_Rule__c objBusinessRule = [SELECT id,RecordType.DeveloperName, CSX_CMP_Where_Clause__c, CSX_CMP_Matches_Count__c,CSX_CMP_Status__c,
                                                        (Select id , Name, CSX_CMP_Attribute_Name__c from Business_Rule_Conditions__r)
                                                    FROM CSX_CMP_Business_Rule__c WHERE id =: id
                                                    WITH SECURITY_ENFORCED];
            
            if(objBusinessRule.Business_Rule_Conditions__r != null && objBusinessRule.Business_Rule_Conditions__r.size() > 0)
            {
                Boolean isMatch = objBusinessRule.CSX_CMP_Matches_Count__c > 0 ? true:false;
                Integer intMatchConditionCount = 0;
                Integer intCount = 0;
                String strWhereClause = objBusinessRule.CSX_CMP_Where_Clause__c;

                for(CSX_CMP_Business_Rule_Condition__c objCondition : objBusinessRule.Business_Rule_Conditions__r){
                    if(objBusinessRule.CSX_CMP_Where_Clause__c.contains(objCondition.Name)){
                        strWhereClause = strWhereClause.replaceFirst(objCondition.Name,'true');
                    }
                    else{intCount++;}

                    if(isMatch){
                        if(objCondition.CSX_CMP_Attribute_Name__c == 'claim_claimType'){
                            intMatchConditionCount++;
                        }
                        else if(objCondition.CSX_CMP_Attribute_Name__c == 'claim_claimStatus'){
                            intMatchConditionCount++;
                        }
                        else if(objCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_waybillNum' 
                                || objCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_freightbillNum'
                                || objCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_urwinNum'
                                || objCondition.CSX_CMP_Attribute_Name__c == 'claim_claimVin'
                                || objCondition.CSX_CMP_Attribute_Name__c == 'claim_contractName'){
                            intMatchConditionCount++;
                        }
                    }
                }
                
                if(isMatch && intMatchConditionCount < 3){
                    isResult =  false;
                    intMessage = 1;
                }
                else if(intCount > 0){
                    isResult =  false;
                    intMessage = 2;
                }
                else if(!isMatch && objBusinessRule.RecordType.DeveloperName == 'CSX_CMP_Duplicate'){
                    isResult =  false;
                    intMessage = 5;
                }

                if(isResult)
                {
                    if(objBusinessRule.RecordType.DeveloperName == 'CSX_CMP_RR_General_Rule'){
                        strWhereClause = 'true';
                    }
                    isResult = CSX_CMP_EvaluateBooleanExpression.eval(strWhereClause.toUpperCase().normalizeSpace());
                    
                    if(isResult){
                        objBusinessRule.CSX_CMP_Status__c = 'Valid';
                        intMessage = 3;    
                    }
                    else{
                        objBusinessRule.CSX_CMP_Status__c = 'Invalid';
                        intMessage = 2;
                    }

                    Database.SaveResult[] updateBusinessRule = Database.update(new list<CSX_CMP_Business_Rule__c>{objBusinessRule}, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_ValidateRule',
                        'evaluateWhereClause',
                        updateBusinessRule,
                        'BusinessRuleId'
                    );
                }
            }
            else{intMessage = 4;}
            return intMessage;
        }  
        catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EvaluateWhereClause','evaluateWhereClause','',e);
            return null;
        }
    }
}