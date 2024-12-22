/*
@author       - Infosys
@name         - CSX_CMP_EmailMessageTrigger
@createdDate  - 06/04/2024
@description  - Apex trigger on EmailMessage object.
*/
trigger CSX_CMP_EmailMessageTrigger on EmailMessage(after insert) {
 CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    if ( bypassTrigger != true){
        if (Trigger.isInsert && Trigger.isAfter) {
            CSX_CMP_EmailMsgTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}