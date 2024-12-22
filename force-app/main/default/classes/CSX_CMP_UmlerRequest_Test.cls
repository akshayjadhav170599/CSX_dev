/**************************************************************************************
Apex Class Name     : CSX_CMP_UmlerRequest_Test
Function            : Test Class for generating Umler Request body
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           05/09/2024       First version of this class.
*************************************************************************************/

@isTest
private class CSX_CMP_UmlerRequest_Test {

    @TestSetup
    static void makeData(){
        List<CSX_CMP_Equipment__c> equipmentList = CSX_CMP_TestUtility.createEquipmentData(3);
        insert equipmentList;
    }
    
    /* @description : method to test generation of umler request body */
    @isTest 
    static void testUmlerInput() {

        List<CSX_CMP_Equipment__c> equipmentList =[SELECT Id, Name FROM CSX_CMP_Equipment__c];
        List<String> equipmentIds = new List<String>();
        for(CSX_CMP_Equipment__c equipment : equipmentList){
            equipmentIds.add(equipment.Id);
        }
        Test.startTest();
           String jsonString = CSX_CMP_UmlerRequest.umlerInput(equipmentIds);
        Test.stopTest();
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
    }
}