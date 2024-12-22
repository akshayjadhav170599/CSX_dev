/**
@Author       - Infosys
@Name         - CSX_CMP_OnHoldEmailReminderScheduler Schedulable ControllerApex class
@Created Date - 5/29/2024
@Description  - This Schedulable Apex class is used to schedule the FLR Emails
@RICEFW reference - CMP-E-0439
*/

public with sharing class CSX_CMP_OnHoldEmailReminderScheduler implements Schedulable {
 public void execute(SchedulableContext sc){
      CSX_CMP_OnHoldIncentiveReminderBatch onHoldReminderEmailbatch = new CSX_CMP_OnHoldIncentiveReminderBatch(); 
      Database.executeBatch(onHoldReminderEmailbatch);
   }
}