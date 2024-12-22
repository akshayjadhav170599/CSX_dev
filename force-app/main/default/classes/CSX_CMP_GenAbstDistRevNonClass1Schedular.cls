public with sharing class CSX_CMP_GenAbstDistRevNonClass1Schedular implements Schedulable
{
    public void execute(SchedulableContext sc) {
        try{
            
            CSX_CMP_GeneratePropertyPortalBatch objBatch = new CSX_CMP_GeneratePropertyPortalBatch('Revenue_Railroad', '', 'Non Class 1', '',false);
        Database.executeBatch(objBatch,Integer.valueof(System.Label.CSX_CMP_GenerateAbstDistributeSchedulerSize));
            if (Test.isRunningTest()) {
                throw new DMLException();
            }
       	}catch (Exception ex) {
			    CSX_CMP_LoggerUtility.addApexErrorLog(
				    'CSX_CMP_GenAbstDistRevClass1Schedular',
				    'execute',
				    String.valueOf('Revenue_Railroad'),
				    ex
			);
		}
    }
    
}