/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRuleTriggerHandler
@Created Date - 3/8/2024
@Description  - business rules trigger to handle backend actions and validations
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_BusinessRuleTriggerHandler extends CSX_CMP_TriggerHandler{
	private static Boolean recursionVarBeforeUpdate = true;

	//This method will be used to handle the before update operation
	public override void beforeUpdate() {
		if (recursionVarBeforeUpdate) {
			recursionVarBeforeUpdate = false;
			try {
				handleBeforeUpdate((List<CSX_CMP_Business_Rule__c>) Trigger.new, (Map<Id, CSX_CMP_Business_Rule__c>) Trigger.oldMap);
			} catch (Exception ex) {
				CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleTriggerHandler', 'beforeUpdate', '', ex);
			}
		}
	}

	//This method will be used to check the where clause condition
	public static void handleBeforeUpdate(List<CSX_CMP_Business_Rule__c> lstOfBusinessRules, Map<Id, CSX_CMP_Business_Rule__c> oldBusinessRuleMap)
	{
		try{
			List<CSX_CMP_Business_Rule__c> businessRulesforWhereValidation = new List<CSX_CMP_Business_Rule__c>();
			List<CSX_CMP_Business_Rule__c> businessRulesforOnPriority = new List<CSX_CMP_Business_Rule__c>();

			for(CSX_CMP_Business_Rule__c objBusinessRule:lstOfBusinessRules){
				CSX_CMP_Business_Rule__c objOldBusinessRule = oldBusinessRuleMap.get(objBusinessRule.Id);

				if(objBusinessRule.CSX_CMP_Where_Clause__c !=null && objBusinessRule.CSX_CMP_Where_Clause__c != objOldBusinessRule.CSX_CMP_Where_Clause__c ){
					businessRulesforWhereValidation.add(objBusinessRule);
				}

				if(objBusinessRule.CSX_CMP_Where_Clause__c == null){
					objBusinessRule.addError(System.label.CSX_CMP_Where_Clause_can_not_be_blank);
				}

				//duplicate Check for priority value
				if (!string.isempty(string.valueof(objBusinessRule.CSX_CMP_Priority__c))
					&& objBusinessRule.CSX_CMP_Priority__c != objOldBusinessRule.CSX_CMP_Priority__c ){
					businessRulesforOnPriority.add(objBusinessRule);
				}
			}

			if(!businessRulesforWhereValidation.isempty()){
				validateWhereClauseCondition(businessRulesforWhereValidation, oldBusinessRuleMap);
			}

			if(!businessRulesforOnPriority.isempty()){
				validatePriorityCondition(businessRulesforOnPriority);
			}
		}catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleTriggerHandler', 'handleBeforeUpdate', String.valueOf(lstOfBusinessRules), ex);  
        } 
	}
	
    //This method will be used to check the Priority condition
    public static void validatePriorityCondition(List<CSX_CMP_Business_Rule__c> lstBusinessRulesWithPriority) 
	{
		try 
		{
			set<Decimal> setOfPriority = new set<Decimal>();

			if (!lstBusinessRulesWithPriority.isEmpty()) {
				List<CSX_CMP_Business_Rule__c> lstBusinessRules = [SELECT CSX_CMP_Priority__c 
																	FROM CSX_CMP_Business_Rule__c 
																	WHERE Id NOT IN : lstBusinessRulesWithPriority
																	WITH SECURITY_ENFORCED];

				for(CSX_CMP_Business_Rule__c objBusinessRule : lstBusinessRules){
					setOfPriority.add(objBusinessRule.CSX_CMP_Priority__c);
				}
				
				for(CSX_CMP_Business_Rule__c objBusinessRule : lstBusinessRulesWithPriority){
					if(setOfPriority.contains(objBusinessRule.CSX_CMP_Priority__c)){
						objBusinessRule.addError(System.label.CSX_CMP_Validate_Priority_Check);
					}
				}
			}
		} catch (Exception ex) {
			CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleTriggerHandler', 'checkOnPriority', String.valueOf(lstBusinessRulesWithPriority), ex);
		}
	}

	//This method will be used to check the where clause condition
	public static void validateWhereClauseCondition(List<CSX_CMP_Business_Rule__c> lstOfBusinessRule, Map<Id, CSX_CMP_Business_Rule__c> oldBusinessRuleMap)
	{
		try
		{
			Set<Id> setOfBusinessRuleId = new Set<Id>();
			
			for(CSX_CMP_Business_Rule__c objBusinessRule  : lstOfBusinessRule){
				objBusinessRule.CSX_CMP_Status__c = 'Invalid';
				setOfBusinessRuleId.add(objBusinessRule.Id);
			}

			map<Id, CSX_CMP_Business_Rule__c> mapOfBusinessRule = new map<Id, CSX_CMP_Business_Rule__c>([select Id, Name, CSX_CMP_Where_Clause__c, (Select Id, Name, CSX_CMP_Attribute_Name__c from Business_Rule_Conditions__r) from CSX_CMP_Business_Rule__c where Id in:setOfBusinessRuleId]);
			
			for(CSX_CMP_Business_Rule__c objBusinessRule  : lstOfBusinessRule)
			{
				Integer countofBRConditions = mapOfBusinessRule.get(objBusinessRule.Id).Business_Rule_Conditions__r.size();
				if(countofBRConditions > 0)
				{
					//Create a map of sequence with attribute name
					Map<String,String> mapOfSequenceWithAttributeName = new Map<String,String>();
					for(CSX_CMP_Business_Rule_Condition__c objBRCondition : mapOfBusinessRule.get(objBusinessRule.Id).Business_Rule_Conditions__r){
						mapOfSequenceWithAttributeName.put(objBRCondition.Name, objBRCondition.CSX_CMP_Attribute_Name__c);
					}

				String refinedWhereClause = objBusinessRule.CSX_CMP_Where_Clause__c.toupperCase().replaceAll('AND',' AND ').replaceAll('OR',' OR ').trim().normalizeSpace().replaceAll('\\( \\)','').replaceAll('\\(\\)','');
					objBusinessRule.CSX_CMP_Where_Clause__c = refinedWhereClause;


					//invalid character validation
					String whereClauseWOValidChars = refinedWhereClause.replaceAll('AND',' ').replaceAll('OR',' ').replaceAll('[0-9()]','').trim();
					if(whereClauseWOValidChars != ''){
						objBusinessRule.addError(System.label.CSX_CMP_Invalid_string_in_where_clause);
					}
					
					//Sequence number does not exist in business rule
					List<String> lstSequence = refinedWhereClause.replaceAll('AND','').replaceAll('OR','').replaceAll('[()]','').trim().normalizeSpace().replaceAll(' ',',').split(',');

					for(String strSequence : lstSequence){
						boolean isMatch = false;
						for(CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : mapOfBusinessRule.get(objBusinessRule.Id).Business_Rule_Conditions__r){
							if(objBusinessRuleCondition.Name == strSequence){
								isMatch = true;
							}
						}

						if(!isMatch){
							objBusinessRule.addError(System.label.CSX_CMP_Sequence_no_does_not_exist_in_BRC);
						}
					}

					//check if sequence no does not exist between AND or OR condition
					refinedWhereClause = objBusinessRule.CSX_CMP_Where_Clause__c;
					list<String> lstCheckSequenceNumber = refinedWhereClause.replaceAll('[()]','').trim().normalizeSpace().replaceAll(' ',',').split(',');
					
					for(Integer i=0; i < lstCheckSequenceNumber.size(); i++){
						
						integer num = i/2;
						integer result = num * 2;
						
						if(i == result){
							if(!lstCheckSequenceNumber[i].isNumeric()){
								objBusinessRule.addError(System.label.CSX_CMP_Invalid_string_in_where_clause);
							}
						}else if(i == lstCheckSequenceNumber.size() - 1 && !lstCheckSequenceNumber[i].isNumeric()){
							objBusinessRule.addError(System.label.CSX_CMP_Invalid_string_in_where_clause);
						}
						else if(!lstCheckSequenceNumber[i].isNumeric() && lstCheckSequenceNumber[i].toupperCase() == 'OR')
						{
							integer priorValue = i-1;
							integer nextValue = i+1;
							
							if(mapOfSequenceWithAttributeName.get(lstCheckSequenceNumber[priorValue]) != null && 
								mapOfSequenceWithAttributeName.get(lstCheckSequenceNumber[nextValue]) != null){
								String strPriorAttributeValue = mapOfSequenceWithAttributeName.get(lstCheckSequenceNumber[priorValue]);
								String strNextAttributeValue = mapOfSequenceWithAttributeName.get(lstCheckSequenceNumber[priorValue]);

								if(strPriorAttributeValue.countMatches('_') > 1 || strNextAttributeValue.countMatches('_') > 1){
									objBusinessRule.addError(System.label.CSX_CMP_OR_condition_Header_Level);
								}
							}
						}
					}

					//Check if open and closing bracket do not match
					Integer intOpenBracket = objBusinessRule.CSX_CMP_Where_Clause__c.countMatches('(');
					Integer intClosingBracket = objBusinessRule.CSX_CMP_Where_Clause__c.countMatches(')');

					if(intOpenBracket != intClosingBracket){
						objBusinessRule.addError(System.label.CSX_CMP_Validate_Open_and_Closing_Bracket);
					}
					
					//Either AND or OR should be provided in where clause condition
					if(countofBRConditions > 1 && !(objBusinessRule.CSX_CMP_Where_Clause__c.contains('AND') || objBusinessRule.CSX_CMP_Where_Clause__c.contains('OR'))){
						objBusinessRule.addError(System.label.CSX_CMP_Validate_AND_or_OR);
					}

					//Check if business rule condition sequence does not exist in where clause
					for(CSX_CMP_Business_Rule_Condition__c objBusinessRuleCondition : mapOfBusinessRule.get(objBusinessRule.Id).Business_Rule_Conditions__r){
						if(!objBusinessRule.CSX_CMP_Where_Clause__c.contains(objBusinessRuleCondition.Name)){
							objBusinessRule.addError(System.label.CSX_CMP_Sequence_no_does_not_exist);
						}
					}
				}	
			}
		}catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_BusinessRuleTriggerHandler', 'validateWhereClauseCondition', String.valueOf(lstOfBusinessRule), ex);  
        }												
	}
}