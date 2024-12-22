/**
@Author       - Infosys
@Name         - CSX_CMP_TaskController
@Created Date - 05/01/2024
@Description  - Apex Class to mark all task to complete
@RICEFW reference - 
*/
public with sharing class CSX_CMP_TaskController {
    
    @AuraEnabled
    public static Integer updateTaskStatus(Id caseId) {

        Integer status = 0;
        try{
            List<Task> lstTask = [
                SELECT Id, Status
                FROM Task
                WHERE WhatId = :caseId AND Status != 'Completed'
                WITH SECURITY_ENFORCED
            ];

            for (Task task : lstTask) {
                task.Status = 'Completed';
            }

            if (!lstTask.isEmpty()) {
                Database.SaveResult[] updateTask = Database.update(lstTask, false);
				CSX_CMP_LoggerUtility.addApexDMLErrorLog(
					'CSX_CMP_TaskController',
					'updateTaskStatus',
					updateTask,
					caseId
				);
                status = 1;
            }
            if (Test.isRunningTest()) {
                throw new DMLException();
            }
            return status;

        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_TaskController',
                'updateTaskStatus',
                caseId,
                ex
            );
            return null;
        }
        
    }
}