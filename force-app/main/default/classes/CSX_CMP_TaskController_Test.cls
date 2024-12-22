@isTest
public class CSX_CMP_TaskController_Test {
    
	@isTest
    static void testUpdateTaskStatus() {

        Case testCase = new Case(
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Freight' LIMIT 1].Id,
            Status = 'New',
            Type = 'FC Customer Claim'
        );
        insert testCase;

        Task task1 = new Task(
            WhatId = testCase.Id,
            Status = 'In Progress'
        );
        Task task2 = new Task(
            WhatId = testCase.Id,
            Status = 'In Progress'
        );
        insert new List<Task>{task1, task2};

        List<Task> tasksBefore = [SELECT Id, Status FROM Task WHERE WhatId = :testCase.Id];
        System.assertEquals('In Progress', tasksBefore[0].Status, '1st record of Task');
        System.assertEquals('In Progress', tasksBefore[1].Status, '2nd record of Task');

        Test.startTest();
        Integer result = CSX_CMP_TaskController.updateTaskStatus(testCase.Id);
        Test.stopTest();

        List<Task> tasksAfter = [SELECT Id, Status FROM Task WHERE WhatId = :testCase.Id];
        System.assertEquals('Completed', tasksAfter[0].Status, 'First record data of Task');
        System.assertEquals('Completed', tasksAfter[1].Status, 'Second record data of Task');

        //System.assertEquals(1, result);

    }
}