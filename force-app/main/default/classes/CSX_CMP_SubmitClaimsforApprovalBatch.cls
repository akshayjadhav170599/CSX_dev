/*
@Author       - Infosys
@Name         - CSX_CMP_SubmitClaimsforApprovalBatch
@Created Date - 3/8/2024
@Description  - This batch Apex is used to submit eligible On Hold claims for Approval (called from CSX_CMP_OnHoldClaimsApprEvaluationBatch)
                Job will be run with batch size as 1 so it runs per 1 Claim
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_SubmitClaimsforApprovalBatch implements Database.Batchable<String>, Database.Stateful {
    List<Id> claimIds = new List<Id>();

    public CSX_CMP_SubmitClaimsforApprovalBatch(List<Id> inputClaimIds) {
        claimIds = inputClaimIds;
    }

    public Iterable<Id> start(Database.BatchableContext context){
        return claimIds;         
    }

    public void execute(Database.BatchableContext context, List<Id> scope) {
        CSX_CMP_SubmitForApprovalController.submitForApproval(scope[0]);
        
    }
    
    public void finish(Database.BatchableContext context) {
    }
}