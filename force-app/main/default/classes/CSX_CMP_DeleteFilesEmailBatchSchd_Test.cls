@isTest
public class CSX_CMP_DeleteFilesEmailBatchSchd_Test {
	@isTest
    public static void testScheduler() {
         Test.startTest();
        
        CSX_CMP_DeleteFilesEmailBatchSchedular scheduler = new CSX_CMP_DeleteFilesEmailBatchSchedular();
        
        scheduler.execute(null);
        
        
        List<AsyncApexJob> jobs = [SELECT Status, JobType FROM AsyncApexJob WHERE JobType = 'BatchApex' AND CreatedDate = TODAY];
        
        System.assertEquals(1, jobs.size(), 'A batch job should be created.');
        System.assertEquals('Holding', jobs[0].Status, 'The batch job should be holding.');

        Test.stopTest();
    }
}