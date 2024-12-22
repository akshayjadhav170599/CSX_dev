@isTest
private class CSX_CMP_OnHoldEmailRemScheduler_Test {
    @isTest
    static void testExecuteMethod() {
        // Create a new instance of the scheduler class
        CSX_CMP_OnHoldEmailReminderScheduler scheduler = new CSX_CMP_OnHoldEmailReminderScheduler();
        
        // Call the execute method (which internally invokes the batch class)
        Test.startTest();
        String jobId = System.schedule('Test Job', '0 0 0 15 3 ? 2022', scheduler);
        Test.stopTest();
        
        // Verify that the job was scheduled successfully
        System.assertNotEquals(null, jobId, 'Job was not scheduled successfully');
    }
}