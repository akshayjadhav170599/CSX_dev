/**
@Author       - Infosys
@Name         - CSX_CMP_SetClaimPriorityBatchScheduler Schedulable ControllerApex class
@Created Date - 12/17/2023
@Description  - This Schedulable Apex class is used to schedule  Claim Priority
@RICEFW reference - CMP-E-0439
*/
public with sharing class CSX_CMP_OnHoldApprEvalScheduler implements Schedulable{
	
    public void execute(SchedulableContext sc) {
        CSX_CMP_OnHoldClaimsApprEvaluationBatch onHoldClaimAppEvaluationBatch = new CSX_CMP_OnHoldClaimsApprEvaluationBatch();
        Database.executeBatch(onHoldClaimAppEvaluationBatch);
    }
    
}