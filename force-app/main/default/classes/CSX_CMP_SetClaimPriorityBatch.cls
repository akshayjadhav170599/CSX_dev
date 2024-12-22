/**
@Author       - Infosys
@Name         - CSX_CMP_SetClaimPriorityBatch
@Created Date - 03/14/2024
@Description  - This class is used to set the priority of the case based on the business rules.
*/
public with sharing class CSX_CMP_SetClaimPriorityBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Integer count = 0;
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        String query = 'SELECT Id, Priority FROM Case WHERE Status = \'Open\' ';             
        return Database.getQueryLocator(query);      
    }

    public void execute(Database.BatchableContext batchableContext, List<Case> scope) {
        try{
            Map<Id,String> priorityMap = new Map<Id,String>();           
            List<Case> casesToUpdate = new List<Case>();
            set<Id> caseIds = new set<Id>();
            for(Case c : scope) {
                caseIds.add(c.Id);
            }
            
            if(!caseIds.isEmpty()){
                priorityMap = CSX_CMP_BusinessRulesUtility.runClaimPriorityBusinessRules(caseIds,'CSX_CMP_Claim_Priority',null);
                
                for(Id claimId : priorityMap.keySet()){
                    List<String> values = priorityMap.get(claimId).split('###');
                    Case claim = new Case(Id = claimId);
                    claim.Priority = values[0];
                    casesToUpdate.add(claim);
                    count++;                                   
                }
            }
            
            Database.SaveResult[] results =  Database.update(casesToUpdate, false);           
            CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_SetClaimPriorityBatch', 'execute', results,'Case');
        } catch(Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SetClaimPriorityBatch', 'execute', JSON.serialize(scope),e);
        }
    }

    public void finish(Database.BatchableContext	 batchableContext) {       
        CSX_CMP_LoggerUtility.addExecutionLog('CSX_CMP_SetClaimPriorityBatch','Set Claim Priority','Case',count);
    }
}