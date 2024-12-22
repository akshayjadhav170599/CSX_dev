/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimsTrigger
Function            : Class for Webservice to search claims based on noOfDays for property Potal.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           02/19/2024       First version of this class.
*************************************************************************************/
trigger CSX_CMP_ClaimTrigger on Case (after insert,after update,before insert, before update){
    // CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    // boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    // if ( bypassTrigger != true){
        
        if(trigger.isUpdate && trigger.isBefore){
            CSX_CMP_ClaimTriggerHandler.handleBeforeUpdate(trigger.newMap, trigger.oldMap);
        }
        
        if(trigger.isInsert && trigger.isAfter){
            CSX_CMP_ClaimTriggerHandler.handleAfterInsert(trigger.newMap);
        }
        
        if(trigger.isUpdate && trigger.isAfter){
            CSX_CMP_ClaimTriggerHandler.handleAfterUpdate(trigger.newMap, trigger.oldMap);
        }
    // }
    
}