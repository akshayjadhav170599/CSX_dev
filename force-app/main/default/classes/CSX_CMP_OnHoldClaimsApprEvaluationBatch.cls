/*
@Author       - Infosys
@Name         - CSX_CMP_OnHoldClaimsApprEvaluationBatch
@Created Date - 3/8/2024
@Description  - This batch Apex is used to reevaluate On Hold claims and submit for Approval when AR balance is below threshold
                Job will be run with batch size as 1 so it runs per 1 Account and its related claims
@RICEFW reference - CMP-I-0439
*/
public with sharing class CSX_CMP_OnHoldClaimsApprEvaluationBatch implements Database.Batchable<String>,Database.AllowsCallouts, Database.Stateful {

    public List<Id> lstClaimIdForApproveIncentive = new List<Id>();
    public Set<Id> lstClaimIdForOvercharge = new Set<Id>();
    public Map<String,List<Case>> nationalAccNumtoClaimsMap = new Map<String,List<Case>>();

    public CSX_CMP_OnHoldClaimsApprEvaluationBatch() {
        List<Case> onHoldClaims = [Select Id, RecordType.developerName, CaseNumber, CreatedDate, Owner.Email, CSX_CMP_National_Account_Num__c, Status, Type, CSX_CMP_Claim_Amount__c, CSX_CMP_System_Action_Toggle__c
                                   FROM Case WHERE (RecordType.developerName = 'Revenue_Overcharge' OR Type = 'Incentive Claim') AND Status = 'On Hold' AND CSX_CMP_National_Account_Num__c != '' AND CSX_CMP_AR_Balance_Check_Failed__c = true ];
        if(!onHoldClaims.isEmpty()){
            for(Case claim : onHoldClaims){
                if(claim.CSX_CMP_National_Account_Num__c != null){ 
                    if(nationalAccNumtoClaimsMap.containsKey(claim.CSX_CMP_National_Account_Num__c)){
                        nationalAccNumtoClaimsMap.get(claim.CSX_CMP_National_Account_Num__c).add(claim);
                    }
                    else{
                        nationalAccNumtoClaimsMap.put(claim.CSX_CMP_National_Account_Num__c, new List<Case>{claim});
                    }
                }  
            } 
        }
    }

    public Iterable<String> start(Database.BatchableContext context) {    
            return nationalAccNumtoClaimsMap.keySet(); 
    }

    public void execute(Database.BatchableContext context, List<String> scope) {
        try
        {

            if(scope != null && scope.size() > 0){
                for(string strNationalAccountNumber : scope){
                    map<string, map<Id, Boolean>> mapOfClaimWithTHStatus = CSX_CMP_SubmitClaimforApprovalHelper.claimApprovalEvalutionForARBalance(integer.valueOf(strNationalAccountNumber), nationalAccNumtoClaimsMap.get(strNationalAccountNumber));
                    for(String strType : mapOfClaimWithTHStatus.keySet()){
                        Map<Id,Boolean> mapOfIncentive = mapOfClaimWithTHStatus.get(strType);
                        for(Id claimId : mapOfIncentive.keySet()){
                            if(mapOfIncentive.get(claimId) == true){
                                if(strType == 'Incentive'){
                                    lstClaimIdForApproveIncentive.add(claimId);
                                }
                                else{       
                                    lstClaimIdForOvercharge.add(claimId);
                                }
                            }
                        }
                    }
                }
            } 
        }Catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_OnHoldClaimsApprEvaluationBatch','execute',json.serialize(scope),ex);
        }
    }
    
    public void finish(Database.BatchableContext context) {
        try{
            if(!lstClaimIdForApproveIncentive.isEmpty()){
                //invoke batch job submit for approval with batch size 1
                CSX_CMP_SubmitClaimsforApprovalBatch batchJob = new CSX_CMP_SubmitClaimsforApprovalBatch(lstClaimIdForApproveIncentive);
                id batchJobId = Database.executeBatch(batchJob,1);
            }
            
            if(!lstClaimIdForOvercharge.isEmpty()){
                //invoke batch job submit for approval with batch size 1
                CSX_CMP_OnHoldClaimsApprOverchargeBatch batchJob = new CSX_CMP_OnHoldClaimsApprOverchargeBatch(lstClaimIdForOvercharge);
                id batchJobId = Database.executeBatch(batchJob,1);
            }
            
        }Catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_OnHoldClaimsApprEvaluationBatch','finish',JSON.serialize(context),ex);
        }
    }
}