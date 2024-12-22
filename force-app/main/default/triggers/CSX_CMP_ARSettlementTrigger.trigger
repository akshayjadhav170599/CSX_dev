trigger CSX_CMP_ARSettlementTrigger on CSX_CMP_AR_Settlement__c (after update) {
    CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    if (bypassTrigger != true){
        if(trigger.isAfter && trigger.isUpdate){
            CSX_CMP_ARSettlementTriggerHandler.handleAfterUpdate(trigger.new, trigger.oldMap);//, trigger.oldMap
           /* CSX_CMP_AR_Settlement__c arSettlementNew = trigger.new[0];
            CSX_CMP_AR_Settlement__c arSettlementOld = trigger.old[0];

            if(arSettlementOld.CSX_CMP_Integration_Status__c == 'Sent' && arSettlementNew.CSX_CMP_Integration_Status__c == 'Processed'){
                List<CSX_CMP_3rd_Party__c> thirdPartyList = [SELECT Id, CSX_CMP_Invoice_Num__c FROM CSX_CMP_3rd_Party__c WHERE CSX_CMP_AR_Settlement__c = :arSettlementNew.Id WITH SECURITY_ENFORCED];
                CSX_CMP_3rdPartyTriggerHandler.handleAfterUpdate(thirdPartyList, null);
            }*/
        } 
    }
}