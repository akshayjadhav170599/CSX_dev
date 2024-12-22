/**
@Author       - Infosys
@Name         - ScheduleFLREmailBatch Schedulable ControllerApex class
@Created Date - 12/17/2023
@Description  - This Schedulable Apex class is used to schedule the FLR Emails
@RICEFW reference - CMP-E-0422
*/

public with sharing class CSX_CMP_FLREmailBatchScheduler implements Schedulable {
   public void execute(SchedulableContext sc){
      CSX_CMP_SendFLREmailsBatch objSendFLREmailsBatch = new CSX_CMP_SendFLREmailsBatch(); 
      Database.executeBatch(objSendFLREmailsBatch,10);
   }
}