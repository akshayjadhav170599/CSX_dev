/**
@Author       - Infosys
@Name         - CSX_CMP_BusinessRuleConditionTrigger
@Created Date - 3/8/2024
@Description  - business rules condition trigger to handle backend actions and validations
@RICEFW reference - CMP-E-0425
*/
trigger CSX_CMP_BusinessRuleConditionTrigger on CSX_CMP_Business_Rule_Condition__c (after insert, after update, before insert, before update, after delete) 
{ 
CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    if ( bypassTrigger != true){
      if(Trigger.isAfter && Trigger.isInsert ){  
        CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterInsert(Trigger.new);
      }

      if(Trigger.isAfter && Trigger.isUpdate){  
        CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterUpdate(Trigger.new);
      }

      if(Trigger.isAfter && Trigger.isDelete){  
        CSX_CMP_BusinessRuleConditionTrigHandler.handleAfterDelete(Trigger.old);
      }
      
      if(Trigger.isBefore && Trigger.isInsert ) {
        CSX_CMP_BusinessRuleConditionTrigHandler.handleBeforeInsert(Trigger.new);
      }

      if(Trigger.isBefore && Trigger.isUpdate) {
        CSX_CMP_BusinessRuleConditionTrigHandler.handleBeforeupdate(Trigger.new);
      }
    }
}