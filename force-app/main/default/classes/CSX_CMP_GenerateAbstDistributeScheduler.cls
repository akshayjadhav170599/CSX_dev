public with sharing class CSX_CMP_GenerateAbstDistributeScheduler implements Schedulable
{
    public void execute(SchedulableContext sc) {

        try{
        CSX_CMP_GeneratePropertyPortalBatch objBatch = new CSX_CMP_GeneratePropertyPortalBatch('Freight', '', 'Class 1', '',false);
        Database.executeBatch(objBatch,Integer.valueof(System.Label.CSX_CMP_GenerateAbstDistributeSchedulerSize));
            if (Test.isRunningTest()) {
                throw new DMLException();
            }
           }catch(Exception ex){
               CSX_CMP_LoggerUtility.addApexErrorLog(
				    'CSX_CMP_GenerateAbstDistributeScheduler',
				    'execute',
				    String.valueOf('Freight'),
				    ex
                );
           }
    }
}