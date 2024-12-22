/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRulesHelper
@Created Date - 03/28/2023
@Description  - Apex utility method to maintain all helper methods related to business rules engine
@RICEFW reference - CMP-E-0425
*/
public with sharing class CSX_CMP_BusinessRulesHelper {
    
    //Method returns the Desk / team Number and Owner/Queue based on the business rules conditions for claims
    public static Set<Id> identifyClaimsforMatchesComparison(CSX_CMP_BusinessRulesUtility.ClaimWrapper objClaimWrapper, CSX_CMP_Business_Rule__c objBusinesssRule){
        Set<Id> setOfTargetClaimIds = new Set<Id>();
        
        //Create dynamic Query to get the target Claims Records
        if(objBusinesssRule.Business_Rule_Conditions__r != null && objBusinesssRule.Business_Rule_Conditions__r.size() > 0)
        { 
            //String strQuery = ' SELECT Id, ';
            String strequipmentorClaim = '';
            String strBRClaimType = '';

            if(objClaimWrapper.RecordType == 'Freight'){
                strequipmentorClaim = 'CSX_CMP_Equipment__c';
                if(objBusinesssRule.RecordType.DeveloperName == 'CSX_CMP_Duplicate'){
                    list<String> lstClaimtypes = new list<String>();

                    if(objBusinesssRule.CSX_CMP_Claim_Type__c.contains(';')){
                        lstClaimtypes = objBusinesssRule.CSX_CMP_Claim_Type__c.split(';');
                    }
                    else{
                        lstClaimtypes.add(objBusinesssRule.CSX_CMP_Claim_Type__c);
                    }
                    
                    String strFinalClaimType = '';

                    for(String strClaimType : lstClaimtypes){
						String prefixClaim =  strClaimType;
                        if(String.isempty(strFinalClaimType)){
                            strFinalClaimType = '\'' + String.escapeSingleQuotes(prefixClaim) + '\'';
                        }else{
                            strFinalClaimType += ',' + '\'' + String.escapeSingleQuotes(prefixClaim) + '\'';
                        }
                    }
                    strBRClaimType = strFinalClaimType;
                }
            }else{
                strequipmentorClaim = 'CSX_CMP_Claim_Line__c';
            }

            String equipmentorClaimQuery = 'Select Id,CSX_CMP_Claim__c From ' + strequipmentorClaim +' where CSX_CMP_Claim__c != null ';
            //String claimQuery = ' FROM Case where Id != null';

            for(CSX_CMP_Business_Rule_Condition__c objBRuleCondition : objBusinesssRule.Business_Rule_Conditions__r){
                //Claim Type
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_claimType'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type != ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(string.isempty(objClaimWrapper.claimType)){ 
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type =' + objClaimWrapper.claimType;
                            }else{
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Type =' + '\'' + String.escapeSingleQuotes(objClaimWrapper.claimType) + '\'';
                            }
                        }
                    }
                } 

                //Claim Status
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_claimStatus'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status !=  ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(string.isempty(objClaimWrapper.claimStatus)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status = ' + objClaimWrapper.claimStatus;
                            }else{
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.Status = ' + '\'' + String.escapeSingleQuotes(objClaimWrapper.claimStatus) + '\'';
                            }
                        }
                    }
                }

                //Contract Name
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_contractName'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name !=  ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(string.isempty(objClaimWrapper.contractName)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name = ' + objClaimWrapper.contractName;
                            }else{
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_Contract_Num__r.Name = ' + '\'' + String.escapeSingleQuotes(objClaimWrapper.contractName) + '\'';
                            }
                        }
                    }
                }

                //VIN#    
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_claimVin'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c != ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(string.isempty(objClaimWrapper.claimVin)){
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c != NULL';
                            }else{
                                equipmentorClaimQuery += ' and CSX_CMP_Claim__r.CSX_CMP_VIN__c != NULL and CSX_CMP_Claim__r.CSX_CMP_VIN__c = ' + '\'' + String.escapeSingleQuotes(objClaimWrapper.claimVin) + '\'';
                            }
                        }
                    }
                } 

                //Waybill #
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_waybillNum'){
                    
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Waybill_Num__c = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Waybill_Num__c != ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Waybill_Num__c IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Waybill_Num__c NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(objClaimWrapper.Equipment != null && objClaimWrapper.Equipment.size() > 0){
                                String strWayBillNum = '';
                                for(CSX_CMP_BusinessRulesUtility.EquipmentWrapper objEquipmentWrapper : objClaimWrapper.Equipment){
                                    if(!string.isempty(objEquipmentWrapper.waybillNum)){
                                        if(String.isempty(strWayBillNum)){
                                            strWayBillNum = '\'' + String.escapeSingleQuotes(string.isNotBlank(objEquipmentWrapper.waybillNum) ? objEquipmentWrapper.waybillNum : '') + '\'';
                                        }else{
                                            strWayBillNum += ',' + '\'' + String.escapeSingleQuotes(string.isNotBlank(objEquipmentWrapper.waybillNum) ? objEquipmentWrapper.waybillNum : '') + '\'';
                                        }
                                    }
                                }
                                
                                if(!string.isempty(strWayBillNum)){
                                    equipmentorClaimQuery += ' and CSX_CMP_Waybill_Num__c IN (' + strWayBillNum + ')';
                                }
                            }
                        }
                    }
                }

                //Freight Bill #
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_freightbillNum'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Freight_Bill_Num__c = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_Freight_Bill_Num__c != ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Freight_Bill_Num__c IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_Freight_Bill_Num__c NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(objClaimWrapper.Equipment != null && objClaimWrapper.Equipment.size() > 0){
                                String strFreightBillNum = '';
                                for(CSX_CMP_BusinessRulesUtility.EquipmentWrapper objEquipmentWrapper : objClaimWrapper.Equipment){
                                    if(!string.isempty(objEquipmentWrapper.freightbillNum)){
                                        if(string.isempty(strFreightBillNum)){
                                            strFreightBillNum = '\'' + String.escapeSingleQuotes(objEquipmentWrapper.freightbillNum) + '\'';
                                        }else{
                                            strFreightBillNum += ',' + '\'' + String.escapeSingleQuotes(objEquipmentWrapper.freightbillNum) + '\'';
                                        }
                                    }
                                }
                                if(!string.isempty(strFreightBillNum)){
                                    equipmentorClaimQuery += ' and CSX_CMP_Freight_Bill_Num__c IN (' + strFreightBillNum + ')';
                                }
                            }
                        }
                    }
                }

                //URWIN #
                if(objBRuleCondition.CSX_CMP_Attribute_Name__c == 'claim_equipment_urwinNum' && strequipmentorClaim == 'CSX_CMP_Claim_Line__c'){
                    switch on objBRuleCondition.CSX_CMP_Operator__c{
                        when 'Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_URRWIN_Num__c = ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'Not Equal To'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                equipmentorClaimQuery += ' and CSX_CMP_URRWIN_Num__c != ' + '\'' + String.escapeSingleQuotes(objBRuleCondition.CSX_CMP_Value__c) + '\'';
                            }
                        }
                        when 'In List'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_URRWIN_Num__c IN (' + strType + ') ';
                            }
                        }
                        when 'Not In'{
                            if(!string.isempty(objBRuleCondition.CSX_CMP_Value__c)){
                                list<String> lstValues = objBRuleCondition.CSX_CMP_Value__c.split(',');
                                string strType = '';

                                for(String srtValue : lstValues){
                                    if(string.isempty(strType)){
                                        strType = '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }else{
                                        strType += ',' + '\'' + String.escapeSingleQuotes(srtValue) + '\'';
                                    }
                                }
                                equipmentorClaimQuery += ' and CSX_CMP_URRWIN_Num__c NOT IN (' + strType + ') ';
                            }
                        }
                        when 'Matches'{
                            if(objClaimWrapper.Equipment != null && objClaimWrapper.Equipment.size() > 0){
                                String strUrwinNum = '';
                                for(CSX_CMP_BusinessRulesUtility.EquipmentWrapper objEqupmentWrapper : objClaimWrapper.Equipment){
                                    if(!string.isempty(objEqupmentWrapper.urwinNum)){
                                        if(string.isempty(strUrwinNum)){
                                            strUrwinNum = '\'' + String.escapeSingleQuotes(objEqupmentWrapper.urwinNum) + '\'';
                                        }else{
                                            strUrwinNum += ',' + '\'' + String.escapeSingleQuotes(objEqupmentWrapper.urwinNum) + '\'';
                                        }
                                    }
                                }
                                if(!string.isempty(strUrwinNum)){
                                    equipmentorClaimQuery += ' and CSX_CMP_URRWIN_Num__c IN (' + strUrwinNum + ')';
                                }
                            }
                        }
                    }
                }
            } 

            //equipmentorClaimQuery += ')';            
            String strFinalQuery = '';

            if(string.isEmpty(strBRClaimType)){
                if(string.isempty(objClaimWrapper.Id)){
                    strFinalQuery =  equipmentorClaimQuery;
                }else{
                    strFinalQuery = equipmentorClaimQuery + ' and CSX_CMP_Claim__c != ' + '\'' + String.escapeSingleQuotes(objClaimWrapper.Id) + '\'' ;
                }
            }else{
                if(string.isempty(objClaimWrapper.Id)){
                    strFinalQuery = equipmentorClaimQuery + ' and CSX_CMP_Claim__r.Type IN (' + strBRClaimType + ')';    
                }else{
                    strFinalQuery = equipmentorClaimQuery + ' and CSX_CMP_Claim__c != ' + '\'' + String.escapeSingleQuotes(objClaimWrapper.Id) + '\' and CSX_CMP_Claim__r.Type IN (' + strBRClaimType + ')';
                }
            }
            List<sObject> lstClaimsforComparison = (List<sObject>) Database.query(strFinalQuery);
			if (!lstClaimsforComparison.isEmpty()) {
				for (sObject childObject : lstClaimsforComparison) {
					setOfTargetClaimIds.add((Id) childObject.get('CSX_CMP_Claim__c'));
				}
			}
        }
        return setOfTargetClaimIds;
    }
}