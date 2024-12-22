/**************************************************************************************
/*
@author             : Infosys
@description        : Test class for CSX_CMP_EquipmentSummaryReport

Apex Class Name     : CSX_CMP_EquipmentSummaryReport_Test
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys                              First version of this class.
*************************************************************************************/
@isTest 
public class CSX_CMP_EquipmentSummaryReport_Test {
   
    @testSetup   
    static void makeTestData() {    
        // Calling MasterDataLoader to load the data
        //CSX_CMP_TestMasterDataUtility.createMasterData();
        
        // Inserting LD Report
        //Map<String, String> ldReport = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');        
        //CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(ldReport);
        
        // Create a new LD Report
        CSX_CMP_LD_Report__c ldReport = new CSX_CMP_LD_Report__c(
            CSX_CMP_Incident_Date__c = System.today(),
            CSX_CMP_Disposition__c = 'Returned',
            CSX_CMP_LD_Type__c = 'Customer',
            CSX_CMP_Incident_Comments__c = 'Test Comment'
        );
        insert ldReport;
        
        // Inserting Notes for LD Report
        CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
        note.CSX_CMP_Note_Type__c = 'Comment';
        note.CSX_CMP_LD_Report__c = ldReport.id;  // Using valid LDR ID from the response
        insert note;   
        	
        // Inserting Notes for LD Report
        CSX_CMP_Notes__c note2 = new CSX_CMP_Notes__c();
        note2.CSX_CMP_Note_Type__c = 'Decline Reason';
        note2.CSX_CMP_LD_Report__c = ldReport.id;  // Using valid LDR ID from the response
        insert note2; 
         
        // Inserting Equipment
        CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
        equipment.CSX_CMP_Equipment_Initial__c = 'BNSF'; 
        equipment.CSX_CMP_Waybill_Num__c = '456786';
        equipment.CSX_CMP_LD_Report__c = ldReport.id;
        equipment.CSX_CMP_Equipment_Num__c = '878987';
        insert equipment;
        
        // Inserting Transfer Equipment and Notes
        CSX_CMP_Transfer_Equipment__c transferEquipment = new CSX_CMP_Transfer_Equipment__c();
        transferEquipment.CSX_CMP_Transfer_Equipment_Initia__c = 'BOUD';  
        transferEquipment.CSX_CMP_Transfer_Equipment_Number__c = '345678';
        transferEquipment.CSX_CMP_Equipment__c = equipment.Id;
        insert transferEquipment;  
        
        CSX_CMP_Notes__c transferNote = new CSX_CMP_Notes__c();
        transferNote.CSX_CMP_Note_Type__c = 'Comment';
        transferNote.CSX_CMP_Transfer_Equipment__c = transferEquipment.Id;
        insert transferNote;    
        
        // Prepare equipment IDs for use in getEquipmentDetails method
        
        List<CSX_CMP_Equipment__c> equipmentLists = [SELECT Id FROM CSX_CMP_Equipment__c LIMIT 1];
        List<Id> opId = new List<Id>();
        for (CSX_CMP_Equipment__c equip : equipmentLists) {
            opId.add(equip.Id);
        }
        
        
        
        // Call the method to test
        Test.startTest();  
        List<CSX_CMP_Equipment__c> cxpFile = CSX_CMP_EquipmentSummaryReport.getEquipmentDetails(opId);
        Map<String, List<CSX_CMP_Notes__c>> notesResponse = CSX_CMP_EquipmentSummaryReport.getNotesOfLDReport(equipmentLists);
        
        Test.stopTest();  
    } 
    /*
    @isTest
    static void testConstructorWithValidEquipmentId() {
        // Retrieve the equipment for the setup
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            CSX_CMP_TestMasterDataUtility.createDocuments(UserInfo.getUserId());
            Test.startTest();
            // Mocking the ApexPages.StandardController
            ApexPages.StandardController sc = new ApexPages.StandardController(equipment);
            CSX_CMP_EquipmentSummaryReport report = new CSX_CMP_EquipmentSummaryReport(sc);
            Test.stopTest();
            // Assertions
            System.assertNotEquals(report.wrapper, null, 'Wrapper should be initialized');
            System.assertNotEquals(report.wrapper.equipment, null, 'Equipment should be initialized');
            System.assertEquals(report.wrapper.equipment.Id, equipment.Id, 'Equipment Id should match');
            System.assertNotEquals(report.wrapper.finalNotes, null, 'Notes should be fetched');
            System.assertEquals(report.wrapper.finalNotes.size(), 2, 'There should be two notes');
            System.assertNotEquals(report.wrapper.ldReport, null, 'LD Report should be initialized');
        }
    }*/
    
    // Test method for getEquipmentDetails method
    @isTest
    static void testGetEquipmentDetails() {
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c LIMIT 1];
        List<Id> equipmentIds = new List<Id>{ equipment.Id };
            
            // Calling the method
            List<CSX_CMP_Equipment__c> equipmentDetails = CSX_CMP_EquipmentSummaryReport.getEquipmentDetails(equipmentIds);
        
        // Assertions
        System.assertEquals(equipmentDetails.size(), 1, 'There should be 1 equipment record');
        System.assertEquals(equipmentDetails[0].Id, equipment.Id, 'Equipment Id should match');
    }
    
    // Test method for getNotesOfLDReport method
    @isTest
    static void testGetNotesOfLDReport() {
        CSX_CMP_Equipment__c equipment = [SELECT Id, CSX_CMP_LD_Report__c FROM CSX_CMP_Equipment__c LIMIT 1];
        List<CSX_CMP_Equipment__c> equipmentList = new List<CSX_CMP_Equipment__c>{ equipment };
            
            // Calling the method
            Map<String, List<CSX_CMP_Notes__c>> notesMap = CSX_CMP_EquipmentSummaryReport.getNotesOfLDReport(equipmentList);
        
        // Assertions
        System.assertNotEquals(notesMap, null, 'Notes map should not be null');
    }
    
    // Test method for fetchLDReport method
    @isTest
    static void testFetchLDReport() {
        CSX_CMP_Equipment__c equipment = [SELECT Id, CSX_CMP_LD_Report__c FROM CSX_CMP_Equipment__c LIMIT 1];
        List<CSX_CMP_Notes__c> notes = [SELECT Id, CSX_CMP_Note_Type__c FROM CSX_CMP_Notes__c WHERE CSX_CMP_Note_Type__c IN ('Comment', 'Decline Reason')];
         
        // Calling the method
        //EquipmentSummaryReportWrapper result = new CSX_CMP_EquipmentSummaryReport.fetchLDReport(equipment, notes);
    
    } 
    
    // Test method for generateAndSavePDF method
    @isTest
    static void testGenerateAndSavePDF() {
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c LIMIT 1];
        
        Test.startTest();
        CSX_CMP_EquipmentSummaryReport.generateAndSavePDF(equipment.Id);
        Test.stopTest();
        
        // Query the Equipment to check if the PDF was saved
        equipment = [SELECT CSX_CMP_Equipment_Summary_Report__c FROM CSX_CMP_Equipment__c WHERE Id = :equipment.Id];
        System.assertNotEquals(equipment.CSX_CMP_Equipment_Summary_Report__c, null, 'PDF should be generated and saved');
    }
}