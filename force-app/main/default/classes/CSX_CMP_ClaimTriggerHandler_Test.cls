/**
@author       - Infosys
@name         - CSX_CMP_ClaimTriggerHandler
@createdDate - 06/26/2024
@description  - This class is used to test the methods in CSX_CMP_ClaimTriggerHandler
*/
@isTest
private class CSX_CMP_ClaimTriggerHandler_Test {
    
    /*@description : method to create master data for test*/
    
    @testSetup
    static void makeTestData() {
        CSX_CMP_TestMasterDataUtility.createMasterData();
    }
    
    /* Description : method to test the Distribution Id to Claim Id Map */
    
    @isTest
    static void distributionToClaimIdMapTest() {
        //Creating Freight Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        CSX_CMP_Equipment__c equipment = [
            SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
            FROM CSX_CMP_Equipment__c
            LIMIT 1
        ];
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
        
        System.runAs(user) {
            Test.startTest();
            String distResponse = CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipment.Id);
            Test.stopTest();
            
            List<Object> distMap = new List<Object>();
            if(String.isNotBlank(distResponse)) {
                distMap = (List<Object>) JSON.deserializeUntyped(distResponse);
                Map<String, Object> distMapSingle = (Map<String, Object>) distMap[0];
                String distributionId = (String) distMapSingle.get('distributionId');
                CSX_CMP_Distribution__c distribution = [
                    SELECT Id, CSX_CMP_Distribution_Claim__c, CSX_CMP_Distribution_Claim__r.Type
                    FROM CSX_CMP_Distribution__c
                    WHERE Id = :distributionId
                    LIMIT 1
                ];
                
                System.assertEquals(
                    distribution.CSX_CMP_Distribution_Claim__c,
                    distMapSingle.get('claimId'),
                    'Distribution record claim is same as newly created distribution claim'
                );
            }   
        }
    }
    
    /* Description : method to test Create EDI Claim  and EDI926 records Creation*/
    
    @isTest
    static void createEDIclaimTest() {
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/v1/claims/create';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(requestJSON);
            RestContext.request = req;
            RestContext.response = res;
            CSX_CMP_ClaimCreateWebService.claimCreateService();
            Test.stopTest();   
            CSX_CMP_Creation_Request__c request = [SELECT Id, CSX_CMP_Claim__c FROM CSX_CMP_Creation_Request__c];
            System.assertNotEquals(
                null,
                request.CSX_CMP_Claim__c,
                'The claim creation service should return a 201 Created status code for EDI creation.'
            );
        }
        
    }
    
    /* Description : method to test Cancelled Freight Claim */
    
    @isTest
    static void cancelledFreightClaimTest() {
        try {
            //Creating Freight Data
            Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
            CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
                requestMap,
                null
            );
            
            User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
            
            System.runAs(user) {
                Test.startTest();
                
                Case claim = [SELECT Id, Status, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId];
                claim.Status = 'Cancelled';
                claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
                update claim;
                
                Test.stopTest();
            }
        } catch (Exception e) {
            System.assertNotEquals('Please add a cancellation reason in Notes section to proceed with Cancellation.', e.getMessage(),'Checking Catch Statement');
        }
    }
    
    /* Description : method to test Declined Freight Claim */
    
    @isTest
    public static void declinedFreightClaimTest() {
        try {
            //Creating Freight Data
            Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
            CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
                requestMap,
                null
            );
            
            User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
            
            System.runAs(user) {
                Test.startTest();
                
                Case claim1 = [
                    SELECT Id, Status, CSX_CMP_Decline_Code__c, CSX_CMP_System_Action_Toggle__c
                    FROM Case
                    WHERE Id = :response.claimId
                ];
                claim1.Status = 'Declined';
                claim1.CSX_CMP_System_Action_Toggle__c = !claim1.CSX_CMP_System_Action_Toggle__c;
                // decline code needs to be OTH so need to create a OTH decline code on master data
                claim1.CSX_CMP_Decline_Code__r = new CSX_CMP_Decline_Code_Master__c(CSX_CMP_External_ID__c = 'AOG');
                update claim1;
                
                Test.stopTest();
            }
        } catch (Exception e) {
            System.assertEquals('Please add a decline reason in Notes section to proceed with declination.', e.getMessage(),'Checking Catch');
        }
    }
    
    /* 
@description : method to test whether we are able to send LOA letter for Revenue Railroad payable claims when status is pending monthly settlement 
*/
    
    @isTest
    static void sendLOALetterTest() {
        //Creating RevenueRailroad Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newRevenueRailRoadClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            Case claim = [SELECT Id, Status, CSX_CMP_System_Action_Toggle__c FROM Case WHERE Id = :response.claimId AND Origin = 'Manual' LIMIT 1];
            claim.Status = 'Pending Monthly Settlement';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            update claim;
            
            Test.stopTest();
            List<CSX_CMP_Integration_Time_Log__c> logRecords = [
                SELECT Id
                FROM CSX_CMP_Integration_Time_Log__c
                WHERE Id = :response.claimId
            ];
            
            System.assertEquals(0, logRecords.size(), 'Expected an integration time log to be created');
        }
    }
    
    /* Description : method to test create Freight Claim and update claim Amount to a different number */
    
    @isTest
    public static void createFreightClaimToUpdateClaimAmount() {
        //Creating Freight Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            Case claim = [
                SELECT Id, CSX_CMP_Claim_Amount__c, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
            ];
            claim.CSX_CMP_Claim_Amount__c = Decimal.valueOf('260');
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            update claim;
            Test.stopTest();
            
            claim = [SELECT Id, CSX_CMP_Claim_Amount__c FROM Case WHERE Id = :response.claimId];
            System.assertEquals(
                Decimal.valueOf('260'),
                claim.CSX_CMP_Claim_Amount__c,
                'The updated claim amount should be a different number'
            );
        }
    }
    
    /* Description : method to test Customer Service Claim using JSON input and web service and update it's status to 'Pending Monthly Settlement' */
    
    @isTest
    public static void customerServiceClaimTest() {
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
        requestMapAny.put('source', 'Customer Service');
        requestMapAny.put('claimType', 'Intermodal Service Claim');
        requestJSON = JSON.serialize(requestMapAny);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/claims/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        CSX_CMP_ClaimCreateWebService.claimCreateService();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Type = 'Intermodal Service Claim'
                LIMIT 1
            ];
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            claim.Status = 'Pending Monthly Settlement';
            update claim;
            
            Test.stopTest();
            
            Case claimAssert = [SELECT Id, Status FROM Case WHERE Id = :claim.Id];
            System.assertEquals(
                'Pending Monthly Settlement',
                claimAssert.Status,
                'Claim status is updated to Pending Monthly Settlement'
            );
        }
    }
    
    /* Description : method to test Customer Service Claim using JSON input and web service and update it's status to 'Pending Monthly Settlement' */
    
    @isTest
    public static void customerServiceClaimTest1() {
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        Map<String, Object> requestMapAny = (Map<String, Object>) JSON.deserializeUntyped(requestJSON);
        requestMapAny.put('source', 'Customer Service');
        requestMapAny.put('claimType', 'Intermodal Service Claim');
        requestJSON = JSON.serialize(requestMapAny);
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/claims/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        CSX_CMP_ClaimCreateWebService.claimCreateService();
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Type = 'Intermodal Service Claim'
                LIMIT 1
            ];
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            claim.Status = 'Pending Close';
            update claim;
            
            Test.stopTest();
            
            Case claimAssert = [SELECT Id, Status FROM Case WHERE Id = :claim.Id];
            System.assertEquals(
                'Pending Close',
                claimAssert.Status,
                'Claim status is updated to Pending Close'
            );
        }
    }
    
    /* Description : method to test EDI Claim using JSON input */
    
    @isTest
    public static void createEDIClaimTest1 (){
        
        String requestJSON = CSX_CMP_TestUtility.claimCreationJSON();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/claims/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        CSX_CMP_ClaimCreateWebService.claimCreateService();
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        requestMap.put('source','EDI');
        requestMap.put('claimType','FC Customer Automobile Claim');
        requestMap.put('senderSCAC','433223');
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Type = 'FC Customer Automobile Claim'
                LIMIT 1
            ];
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            claim.Status = 'Pending Monthly Settlement';
            update claim;
            
            Test.stopTest();
            
            Case claimAssert = [SELECT Id, Status, Type FROM Case WHERE Id = :claim.Id];
            System.assertEquals(
                'Pending Monthly Settlement',
                claimAssert.Status,
                'Claim status is updated to Pending Monthly Settlement'
            );
        }
    }
    
    /* Description : method to test Create Distribution Claim  */
    
    @isTest
    public static void createDistributionClaimTest(){
        
        //Creating Freight Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        CSX_CMP_Equipment__c equipment = [
            SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
            FROM CSX_CMP_Equipment__c
            LIMIT 1
        ];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
        String distResponse = CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipment.Id);
        
        List<Object> distMap = new List<Object>();
        if(String.isNotBlank(distResponse)) {
            distMap = (List<Object>) JSON.deserializeUntyped(distResponse);
            Map<String, Object> distMapSingle = (Map<String, Object>) distMap[0];
            String distributionClaimNumber = (String) distMapSingle.get('CaseNumber');
            String distributionId = (String)distMapSingle.get('distributionId');
            
            System.runAs(user) {
                Test.startTest();
                
                Case claim = [
                    SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                    FROM Case
                    WHERE CaseNumber = :distributionClaimNumber
                    LIMIT 1
                ];
                claim.Status = 'Cancelled';
                CSX_CMP_Notes__c note =  new CSX_CMP_Notes__c();   
                note.CSX_CMP_Claim__c = claim.Id;
                note.CSX_CMP_Note_Type__c = 'Cancellation Reason';
                insert note;
                update claim;
                
                Test.stopTest();
                
                
                CSX_CMP_Distribution__c distribution = [
                    SELECT Id, CSX_CMP_Distribution_Claim__c, CSX_CMP_Distribution_Claim__r.Type
                    FROM CSX_CMP_Distribution__c
                    WHERE Id = :distributionId
                    LIMIT 1
                ];
                
                System.assertEquals(
                    null,
                    distribution.CSX_CMP_Distribution_Claim__c,
                    'Distribution record claim is same as newly created distribution claim'
                );
            }
        }
    }
    
    /* Description : method to test collect ids for Salvage Claim which are cancelled  */
    
    @isTest
    public static void salvageClaimTest(){
        
        Map<String,String> lDReport = CSX_CMP_TestUtility.newLDReportCreationRequest('Customer');
        CSX_CMP_LDRCreationController.CSX_CMP_LDRResponseWrapper response = CSX_CMP_LDRCreationController.createLDReport(ldReport);
        
        CSX_CMP_Equipment__c equipment = [SELECT Id FROM CSX_CMP_Equipment__c WHERE CSX_CMP_LD_Report__c =: response.ldrId LIMIT 1];
        
        CSX_CMP_Salvage__c salvage = new CSX_CMP_Salvage__c(
            CSX_CMP_Salvage_Amount__c = 132.86,
            CSX_CMP_Parent_Equipment__c = equipment.Id,
            CSX_CMP_Product__c = 'Test Product',
            CSX_CMP_Salvor_Name__r = new Account(CSX_CMP_External_Id__c = 'SAILAccount')
        );
        insert salvage;
        
        CSX_CMP_LD_Report__c ldr = [SELECT Id,(SELECT Id FROM Equipments__r) FROM CSX_CMP_LD_Report__c WHERE CSX_CMP_LD_Type__c = 'Customer' LIMIT 1];
        Map<String,String> data = new Map<String,String>();
        data.put('equipmentId', ldr.Equipments__r[0].Id);
        data.put('productDescription', salvage.CSX_CMP_Product__c);
        data.put('ldrId', ldr.Id);
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_SalvageClaimCreationController.createSalvageClaim(salvage.Id, JSON.serialize(data));
        
        System.runAs(user) {
            Test.startTest();
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                // WHERE Id = :salvage.Id
                LIMIT 1
            ];
            claim.Status = 'Cancelled';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            CSX_CMP_Notes__c note =  new CSX_CMP_Notes__c();   
            note.CSX_CMP_Claim__c = claim.Id;
            note.CSX_CMP_Note_Type__c = 'Cancellation Reason';
            insert note;
            update claim;
            
            CSX_CMP_Salvage__c updatedSalvage = [SELECT Id, CSX_CMP_Salvage_Claim__c FROM CSX_CMP_Salvage__c WHERE Id = :salvage.Id];
            
            Test.stopTest();
            System.assertEquals(null, updatedSalvage.CSX_CMP_Salvage_Claim__c,'Salvage claim should not be created');
        }
        
    }
    
    /* Description : method to test collect ids for service period update on distribution claims  */
    
    @isTest
    public static void servicePeriodUpdateClaimTest(){
        
        //Creating Freight Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        CSX_CMP_Equipment__c equipment = [
            SELECT Id, (SELECT id, name, CSX_CMP_Calculated_Amount__c, CSX_CMP_Manual_Adj_Amt__c FROM Distributions__r)
            FROM CSX_CMP_Equipment__c
            LIMIT 1
        ];
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(new List<Id>{ equipment.id });
        String distResponse = CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipment.Id);
        
        List<Object> distMap = new List<Object>(); 
        if(String.isNotBlank(distResponse)) {
        distMap = (List<Object>) JSON.deserializeUntyped(distResponse);
        // Map<String, Object> distMapSingle = (Map<String, Object>) distMap[0];
        
        System.runAs(user) {
            Test.startTest();
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
                LIMIT 1
            ];
            claim.Status = 'Closed';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            CSX_CMP_Notes__c note =  new CSX_CMP_Notes__c();   
            note.CSX_CMP_Claim__c = claim.Id;
            note.CSX_CMP_Note_Type__c = 'Cancellation Reason';
            insert note;
            update claim;
            
            Test.stopTest();
            System.assertEquals('Closed', claim.Status,'Status should be Closed'); // Assert one cancellation reason note exists
        } 
        }        
    }
    
    /* Description : method to test generate emails for Decline Letter and Dec Letter  */
    
    @isTest
    public static void generateEmails(){
        
        //Creating Freight Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
                LIMIT 1
            ];
            claim.Status = 'Declined';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            // decline code needs to be OTH so need to create a OTH decline code on master data
            claim.CSX_CMP_Decline_Code__r = new CSX_CMP_Decline_Code_Master__c(CSX_CMP_External_ID__c = 'AOG');
            update claim;
            
            Test.stopTest();
            System.assertEquals('Declined', claim.Status, 'Status should be Declined');
            // System.assertEquals(true, claim.CSX_CMP_System_Action_Toggle__c);
            System.assertEquals('AOG', claim.CSX_CMP_Decline_Code__r.CSX_CMP_External_ID__c, 'Decline Code\'s external Id should be AOG');
        }
    }
    
    /* Description : method to test claims for AP Settlement  */
    
    @isTest
    public static void aPSettlementClaims(){
        
        //Creating Freight Claim
        Map<String, String> freightRequestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(freightRequestJSON,null);
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            
            CSX_CMP_TestUtility.generateAPSettlement(); 
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
                LIMIT 1
            ];
            claim.Status = 'Pending Close';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            claim.CSX_CMP_Claim_Amount__c = Decimal.valueOf('100');
            update claim;
            
            Test.stopTest();
            System.assertEquals('Pending Close', claim.Status,'Status should be Pending Close');
        }
    }
    
    /* Description : method to test claims for AP Settlement  */
    
    @isTest
    public static void aRSettlementClaims(){
        
        //Creating Freight Claim
        Map<String, String> freightRequestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(freightRequestJSON,null);
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            
            CSX_CMP_TestUtility.generateARSettlement(); 
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
                LIMIT 1
            ];
            claim.Status = 'Pending Close';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            claim.CSX_CMP_Claim_Amount__c = Decimal.valueOf('-100') ;
            update claim;
            
            Test.stopTest();
            
            System.assertEquals('Pending Close', claim.Status,'Status should be Pending Close');
        }
    }
    
    /* Description : method to test Overcharge Claim to Declined status */
    
    @isTest
    public static void declinedOverchargeClaimTest() {
        
        //Creating Overcharge Data
        Map<String, String> requestMap = CSX_CMP_TestUtility.newRevenueOverchargeClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(
            requestMap,
            null
        );
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest();
            
            Case claim1 = [
                SELECT Id, Status, CSX_CMP_Decline_Code__c, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId LIMIT 1
            ];
            claim1.Status = 'Declined';
            claim1.CSX_CMP_System_Action_Toggle__c = !claim1.CSX_CMP_System_Action_Toggle__c;
            // decline code needs to be OTH so need to create a OTH decline code on master data
            claim1.CSX_CMP_Decline_Code__r = new CSX_CMP_Decline_Code_Master__c(CSX_CMP_External_ID__c = 'AOG');
            CSX_CMP_Notes__c note =  new CSX_CMP_Notes__c();   
            note.CSX_CMP_Claim__c = response.claimId;
            note.CSX_CMP_Note_Type__c = 'Do not send Decline Letter';
            insert note;
            //update claim1;
            
            Test.stopTest();
            System.assertEquals('Declined', claim1.Status,'Status should be Declined');
        }
        
    }
    
    /* Description : method to test Freight Claim to Declined status */
    
    @isTest
    public static void createFreightClaims(){
        
        //Creating Freight Claim
        Map<String, String> freightRequestJSON = CSX_CMP_TestUtility.newFreightClaimCreationRequest();
        CSX_CMP_ClaimCreationController.ClaimResponseWrapper response = CSX_CMP_ClaimCreationController.createNewClaim(freightRequestJSON,null);
        
        User user = [SELECT Id FROM User WHERE FirstName = 'Freight Claim' AND LastName = 'User' LIMIT 1];
        
        System.runAs(user) {
            Test.startTest(); 
            
            Case claim = [
                SELECT Id, Status, CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :response.claimId
                LIMIT 1
            ];
            claim.Status = 'Declined';
            claim.CSX_CMP_System_Action_Toggle__c = !claim.CSX_CMP_System_Action_Toggle__c;
            //update claim;
            
            Test.stopTest();
            
            System.assertEquals('Declined', claim.Status,'Status should be Declined');
        }
    }
    
}