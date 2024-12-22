/*
RICEFW Id : CMP-E-0411
@description : This class is used to update consumed budget on contract and check available budget against newly created claims
@author : Infosys
@name : CSX_CMP_ContractBudgetHandler
*/
public with sharing class CSX_CMP_ContractBudgetHandler {
    
    public static void updateConsumedBudget(List<Case> contractRefundClaims){
        
        List<Id> contractIds=new List<Id>();
        Map<Id,Decimal> contractToclaimAmountMap = new Map<Id,Decimal>();
        try{
        for(case claim:contractRefundClaims){
            contractIds.add(claim.CSX_CMP_Contract_Num__c);
        }
        //List<Case> casesUnderContract=[select Id,CSX_CMP_Contract_Num__c,CSX_CMP_Claim_Amount__c from Case where CSX_CMP_Contract_Num__c in:contractIds ];
        AggregateResult[] claimAmountAndContract = [SELECT Sum(CSX_CMP_Claim_Amount__c) SumOfClaimAmount, CSX_CMP_Contract_Num__c FROM Case where CSX_CMP_Contract_Num__c in:contractIds and Status in ('Pending Close','Closed') WITH SECURITY_ENFORCED group by CSX_CMP_Contract_Num__c ];
        
        for(AggregateResult ar:claimAmountAndContract){
            contractToclaimAmountMap.put((Id)ar.get('CSX_CMP_Contract_Num__c'),(Decimal)ar.get('SumOfClaimAmount'));
        }
        List<CSX_CMP_Contract__c> contractToUpdate=[select Id,CSX_CMP_Consumed_Budget__c,CSX_CMP_Remaining_Budget__c,CSX_CMP_Contract_Budget__c from CSX_CMP_Contract__c where id in: contractToclaimAmountMap.keySet() WITH SECURITY_ENFORCED ];
        for(CSX_CMP_Contract__c contract:contractToUpdate){
            contract.CSX_CMP_Consumed_Budget__c=contractToclaimAmountMap.get(contract.Id);  
        } 
        List<Database.SaveResult> updateContracts = Database.update(contractToUpdate,false);
        CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_ContractBudgetHandler','updateConsumedBudget',updateContracts,'CSX_CMP_Contract__c');
        }catch(Exception e){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ContractBudgetHandler','updateConsumedBudget',JSON.serialize(contractRefundClaims),e);
        }
        
    }

    public static void availableBudgetCheck(List<Case> contractRefundClaims){
        List<Id> contractIds=new List<Id>();
        List<Id> claimIds=new List<Id>();
        Map<Id,Decimal> contractToclaimAmountMap = new Map<Id,Decimal>();
        Map<Id,Decimal> oldCaseToclaimAmountMap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractToAvailableBudget = new Map<Id,Decimal>();
        try{
        for(case claim:contractRefundClaims){
            contractIds.add(claim.CSX_CMP_Contract_Num__c);
            claimIds.add(claim.Id);
        }
        
        List<Case> oldClaims=[select Id,CSX_CMP_Claim_Amount__c from Case where Id in:claimIds WITH SECURITY_ENFORCED ];
        AggregateResult[] claimAmountAndContract = [SELECT Sum(CSX_CMP_Claim_Amount__c) SumOfClaimAmount, CSX_CMP_Contract_Num__c FROM Case where CSX_CMP_Contract_Num__c in:contractIds and Status in ('New','Open','Re-Opened','On Hold','Pending Approval','Rejected') WITH SECURITY_ENFORCED group by CSX_CMP_Contract_Num__c ];
        
        for(AggregateResult ar:claimAmountAndContract){
            contractToclaimAmountMap.put((Id)ar.get('CSX_CMP_Contract_Num__c'),(Decimal)ar.get('SumOfClaimAmount'));
        }
        for(Case claim:oldClaims){
            oldCaseToclaimAmountMap.put(claim.Id,claim.CSX_CMP_Claim_Amount__c);
        }
        List<CSX_CMP_Contract__c> contractList=[select Id,CSX_CMP_Consumed_Budget__c,CSX_CMP_Remaining_Budget__c,CSX_CMP_Contract_Budget__c from CSX_CMP_Contract__c where id in: contractToclaimAmountMap.keySet() WITH SECURITY_ENFORCED ];
        
        for(CSX_CMP_Contract__c contract:contractList){
            contractToAvailableBudget.put(contract.Id,contract.CSX_CMP_Remaining_Budget__c);
        }
        for(case claim:contractRefundClaims){
            Decimal oldClaimAmount = oldCaseToclaimAmountMap.get(claim.Id);
            Decimal sumOfOpenClaimAmts = contractToclaimAmountMap.get(claim.CSX_CMP_Contract_Num__c) - oldClaimAmount + claim.CSX_CMP_Claim_Amount__c;
            if(sumOfOpenClaimAmts > contractToAvailableBudget.get(claim.CSX_CMP_Contract_Num__c) ){
                claim.CSX_CMP_Claim_Amount__c.addError('Amount exceeds available Budget');
            }
        }
        }catch(Exception e){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ContractBudgetHandler','availableBudgetCheck',JSON.serialize(contractRefundClaims),e);
        }
        
    }
    
    
}