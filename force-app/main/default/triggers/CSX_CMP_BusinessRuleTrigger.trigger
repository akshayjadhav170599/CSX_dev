/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRuleTrigger
@Created Date - 3/8/2024
@Description  - business rules trigger to handle backend actions and validations
@RICEFW reference - CMP-E-0425
*/
trigger CSX_CMP_BusinessRuleTrigger on CSX_CMP_Business_Rule__c (before update) {
//  CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
//     boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
//     if ( bypassTrigger != true){
//         if (Trigger.isBefore && Trigger.isUpdate) {
//            CSX_CMP_BusinessRuleTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
//         }
//     }
    new CSX_CMP_BusinessRuleTriggerHandler().run();

}