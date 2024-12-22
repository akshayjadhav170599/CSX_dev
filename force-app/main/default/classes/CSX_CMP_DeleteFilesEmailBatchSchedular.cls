/**
@Author       - Infosys
@Name         - ScheduleDeleteFileEmailBatch Schedulable ControllerApex class
@Created Date - 10/01/2024
@Description  - This Schedulable Apex class is used to delete content document.
@RICEFW reference - CMP-E-0422
*/
public with sharing class CSX_CMP_DeleteFilesEmailBatchSchedular implements Schedulable {
   public void execute(SchedulableContext sc){
      CSX_CMP_DeleteFilesAndEmailsBatch objDeleteFilesEmailsBatch = new CSX_CMP_DeleteFilesAndEmailsBatch(); 
      Database.executeBatch(objDeleteFilesEmailsBatch,10);
   }
}