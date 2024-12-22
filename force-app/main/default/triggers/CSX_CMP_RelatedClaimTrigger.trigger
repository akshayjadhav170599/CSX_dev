/**************************************************************************************
Apex Trigger        : CSX_CMP_RelatedClaimTrigger
Function            : Create a reverserelated claim for the related claim.
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           07/29/2024       First version of this class.
*************************************************************************************/

trigger CSX_CMP_RelatedClaimTrigger on CSX_CMP_Related_Claim__c (after insert) {
 CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
    boolean bypassTrigger = objByPassRule.CSX_CMP_Apex_Triggers__c;
    if ( bypassTrigger != true){
        if(trigger.isInsert && trigger.isAfter && !CSX_CMP_RelatedClaimTriggerHandler.bypassTrigger){
            CSX_CMP_RelatedClaimTriggerHandler.bypassTrigger = true;
            CSX_CMP_RelatedClaimTriggerHandler.handleAfterInsert(trigger.new);
        }    
    }
}