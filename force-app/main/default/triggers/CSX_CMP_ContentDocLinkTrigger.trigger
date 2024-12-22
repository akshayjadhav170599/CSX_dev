/*
@author       - Infosys
@name         - CSX_CMP_ContentDocLinkTrigger
@createdDate  - 06/04/2024
@description  - Apex trigger on ContentDocumentLink object.
*/
trigger CSX_CMP_ContentDocLinkTrigger on ContentDocumentLink(after insert) {
 CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    if ( bypassTrigger != true){
        if (Trigger.isInsert && Trigger.isAfter) {
            CSX_CMP_ContentDocLinkTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}

//1. Try to insert that content doc link data
//2. on insertion automatically that trigger should call and it will cover that method
//3.