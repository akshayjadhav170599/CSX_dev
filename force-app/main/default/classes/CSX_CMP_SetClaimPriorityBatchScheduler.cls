/**
@Author       - Infosys
@Name         - CSX_CMP_SetClaimPriorityBatchScheduler Schedulable ControllerApex class
@Created Date - 12/17/2023
@Description  - This Schedulable Apex class is used to schedule  Claim Priority
@RICEFW reference - CMP-E-0428
*/
public with sharing class CSX_CMP_SetClaimPriorityBatchScheduler implements Schedulable{

    public void execute(SchedulableContext sc) {
        CSX_CMP_SetClaimPriorityBatch batch = new CSX_CMP_SetClaimPriorityBatch();
        Database.executeBatch(batch);
    }

}