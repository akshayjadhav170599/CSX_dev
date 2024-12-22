/*
RICEF ID : CMP-E-0416
@author : Infosys
@description : This class is used to handle post claim creation helper processes
*/
public with sharing class CSX_CMP_PostClaimCreationHelper {
    public static void updateMileageDetails(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            String claimId = inputStagingRec.CSX_CMP_Claim__c;
            CSX_CMP_Equipment__c equipment = new CSX_CMP_Equipment__c();
            equipment = [
                SELECT
                Id,
                CSX_CMP_Act_Origin_State__c,
                CSX_CMP_Act_Origin_City__c,
                CSX_CMP_Act_Origin_Road__c,
                CSX_CMP_Act_Destination_City__c,
                CSX_CMP_Act_Destination_State__c,
                CSX_CMP_Act_Destination_Road__c,
                (
                    SELECT Id, CSX_CMP_Junction__c, CSX_CMP_Road__c, CSX_CMP_Code__c
                    FROM Distributions__r
                    //WHERE CSX_CMP_Road__c != NULL
                    WHERE CSX_CMP_Code__c != NULL
                )
                FROM CSX_CMP_Equipment__c
                WHERE CSX_CMP_Claim__c = :claimId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if(equipment.CSX_CMP_Act_Origin_Road__c == equipment.CSX_CMP_Act_Destination_Road__c){
                List<CSX_CMP_InterfaceUtility.TotalMilesReqWrapper> reqMilWrapList = new List<CSX_CMP_InterfaceUtility.TotalMilesReqWrapper>();
                CSX_CMP_InterfaceUtility.TotalMilesReqWrapper objTotalMilesReqWrapper = new CSX_CMP_InterfaceUtility.TotalMilesReqWrapper();
                
                objTotalMilesReqWrapper.originCarrier = equipment.CSX_CMP_Act_Origin_Road__c.trim();//'CSXT';
                objTotalMilesReqWrapper.destinationCarrier = equipment.CSX_CMP_Act_Destination_Road__c.trim();
                CSX_CMP_InterfaceUtility.OriginMiles objOriginMiles = new CSX_CMP_InterfaceUtility.OriginMiles();
                objOriginMiles.state = equipment.CSX_CMP_Act_Origin_State__c.trim();//'FL';
                objOriginMiles.city = equipment.CSX_CMP_Act_Origin_City__c.trim();//'JACKSONVILLE';
                objTotalMilesReqWrapper.origin = objOriginMiles;
                
                CSX_CMP_InterfaceUtility.DestinationMiles objDestMiles = new CSX_CMP_InterfaceUtility.DestinationMiles();
                objDestMiles.state = equipment.CSX_CMP_Act_Destination_State__c.trim();//'FL';
                objDestMiles.city = equipment.CSX_CMP_Act_Destination_City__c.trim();//'TAMPA';
                objTotalMilesReqWrapper.destination = objDestMiles;
                reqMilWrapList.add(objTotalMilesReqWrapper);
                
                CSX_CMP_InterfaceUtility.MileageResWrapper response = CSX_CMP_InterfaceUtility.fetchTotalMiles(reqMilWrapList);
                if (!equipment.Distributions__r.isEmpty()) {
                    if(response.totalMiles != '-1' && response.totalMiles != null){
                        
                        try {
                            equipment.Distributions__r[0].CSX_CMP_Miles__c = Decimal.valueOf(response.totalMiles);
                            equipment.Distributions__r[0].CSX_CMP_Adj_Miles__c = Decimal.valueOf(response.totalMiles);
                            Database.SaveResult updateResults = Database.update(equipment.Distributions__r[0], false);
                            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                                'CSX_CMP_PostClaimCreationHelper',
                                'updateMileageDetails',
                                updateResults,
                                'CSX_CMP_Distribution__c'
                            );
                        } catch (DMLException e) {
                            inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Error';
                            inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                                ? inputStagingRec.CSX_CMP_Error_Message__c + e.getMessage() + ' ; '
                                : e.getMessage() + '  ; ';
                        }
                        
                        inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Completed';
                    } else {
                        inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Error';
                        inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                            ? inputStagingRec.CSX_CMP_Error_Message__c + 'Mileage Fetch Error: No Mileage found  ; '
                            : 'Mileage Fetch Error: No Mileage found ; ';
                    }
                    CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
                    
                }
            }else{
                //Mileage Request Wrapper
                CSX_CMP_InterfaceUtility.MileageReqWrapper objMileage = new CSX_CMP_InterfaceUtility.MileageReqWrapper();
                if (equipment != null) {
                    List<CSX_CMP_InterfaceUtility.RouteRequests> lstRouteReq = new List<CSX_CMP_InterfaceUtility.RouteRequests>();
                    CSX_CMP_InterfaceUtility.RouteRequests objRouteReq = new CSX_CMP_InterfaceUtility.RouteRequests();
                    
                    objRouteReq.origin = new CSX_CMP_InterfaceUtility.Origin();
                    objRouteReq.origin.state = equipment.CSX_CMP_Act_Origin_State__c != null
                        ? equipment.CSX_CMP_Act_Origin_State__c
                        : ''; //'FL';
                    objRouteReq.origin.city = equipment.CSX_CMP_Act_Origin_City__c != null
                        ? equipment.CSX_CMP_Act_Origin_City__c
                        : ''; //'MIAMI';
                    
                    objRouteReq.destination = new CSX_CMP_InterfaceUtility.Destination();
                    objRouteReq.destination.state = equipment.CSX_CMP_Act_Destination_State__c != null
                        ? equipment.CSX_CMP_Act_Destination_State__c
                        : ''; //'TX';
                    objRouteReq.destination.city = equipment.CSX_CMP_Act_Destination_City__c != null
                        ? equipment.CSX_CMP_Act_Destination_City__c
                        : ''; //'LAREDO';
                    
                    List<CSX_CMP_InterfaceUtility.Route> lstRoute = new List<CSX_CMP_InterfaceUtility.Route>();
                    for (CSX_CMP_Distribution__c distribution : equipment.Distributions__r) {
                        CSX_CMP_InterfaceUtility.Route objRoute = new CSX_CMP_InterfaceUtility.Route();
                        objRoute.roadCode = distribution.CSX_CMP_Code__c != null ? distribution.CSX_CMP_Code__c : '';
                        objRoute.junctionCode = distribution.CSX_CMP_Junction__c != null ? distribution.CSX_CMP_Junction__c : '';
                        lstRoute.add(objRoute);
                    }
                    objRouteReq.route = lstRoute;
                    
                    lstRouteReq.add(objRouteReq);
                    objMileage.routeRequests = lstRouteReq;
                }
                CSX_CMP_InterfaceUtility.MileageResWrapper objMileageResponse = CSX_CMP_InterfaceUtility.fetchMileage(objMileage);
                List<CSX_CMP_Distribution__c> distributions = new List<CSX_CMP_Distribution__c>();
                // handling response (draft version, needs to be updated)
                if (objMileageResponse != null) {
                    if (!equipment.Distributions__r.isEmpty() && objMileageResponse.segmentMileageMap != null) {
                        for (string rrcodeKey : objMileageResponse.segmentMileageMap.keySet()) {
                            for (CSX_CMP_Distribution__c distRecord : equipment.Distributions__r) {
                                String rrcode = distRecord.CSX_CMP_Code__c != null ? distRecord.CSX_CMP_Code__c.trim() : '';
                                String junctioncode = distRecord.CSX_CMP_Junction__c != null ? distRecord.CSX_CMP_Junction__c.trim() : '';
                                string codeJunction = rrcode + '_' + junctioncode;
                                
                                if (codeJunction == rrcodeKey.trim()) {
                                    distRecord.CSX_CMP_Miles__c = Decimal.valueOf(objMileageResponse.segmentMileageMap.get(rrcodeKey)); 
                                    distRecord.CSX_CMP_Adj_Miles__c = Decimal.valueOf(objMileageResponse.segmentMileageMap.get(rrcodeKey));
                                    //res.totalMiles;
                                    distributions.add(distRecord);
                                }
                            }
                        }
                    }
                }
                
                if (!distributions.isEmpty()) {
                    try {
                        Database.SaveResult[] updateResults = Database.update(distributions, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_PostClaimCreationHelper',
                            'updateMileageDetails',
                            updateResults,
                            'CSX_CMP_Distribution__c'
                        );
                    } catch (DMLException e) {
                        inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Error';
                        inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                            ? inputStagingRec.CSX_CMP_Error_Message__c + e.getMessage() + ' ; '
                            : e.getMessage() + '  ; ';
                    }
                    
                    inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Completed';
                } else {
                    inputStagingRec.CSX_CMP_Mileage_Fetch_Status__c = 'Error';
                    inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                        ? inputStagingRec.CSX_CMP_Error_Message__c + 'Mileage Fetch Error: No Mileage found  ; '
                        : 'Mileage Fetch Error: No Mileage found ; ';
                }
                CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
            }
        } catch (Exception e) {
            updateStagingRecord('Mileage Fetch Error: ' + e.getMessage(), 'CSX_CMP_Mileage_Fetch_Status__c', inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'updateMileageDetails',
                JSON.serialize(inputStagingRec),
                e
            );
        }
    }
    public static void updateCaseAvailable(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            String claimId = inputStagingRec.CSX_CMP_Claim__c;
            Boolean caseAvailable;
            
            Case claim = [
                SELECT Id, Type, CSX_CMP_Case_Available__c, (SELECT Id, Name FROM Equipments__r)
                FROM case
                WHERE Id = :claimId
                WITH SECURITY_ENFORCED
            ];
            
            if (claim.Type == 'FC Customer Claim' || claim.Type == 'FC RR Inbound Claim') {
                List<CSX_CMP_InterfaceUtility.CaseSummaryResponseWrapper> response = CSX_CMP_InterfaceUtility.fetchCaseSummary(
                    claim.Equipments__r[0].name
                );
                if (!response.isEmpty() && response != null) {
                    for (CSX_CMP_InterfaceUtility.CaseSummaryResponseWrapper res : response) {
                        if (res.caseAvailable == true) {
                            caseAvailable = true;
                        }
                    }
                } else {
                    inputStagingRec.CSX_CMP_Service_Case_Fetch_Status__c = 'Error';
                    inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                        ? inputStagingRec.CSX_CMP_Error_Message__c + 'Service Case Fetch Error: No Service Case found  ; '
                        : 'Service Case Fetch Error: No Service Case found ; ';
                }
                if (caseAvailable == true) {
                    claim.CSX_CMP_Case_Available__c = true;
                    Database.SaveResult updateCaseRecord = Database.update(claim, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_PostClaimCreationHelper',
                        'updateCaseAvailable',
                        updateCaseRecord,
                        'Case'
                    );
                    inputStagingRec.CSX_CMP_Service_Case_Fetch_Status__c = 'Completed';
                }
            } else {
                inputStagingRec.CSX_CMP_Service_Case_Fetch_Status__c = 'Not Applicable';
            }
            CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
        } catch (Exception e) {
            updateStagingRecord(
                'Service Case Fetch Error: ' + e.getMessage(),
                'CSX_CMP_Service_Case_Fetch_Status__c',
                inputStagingRec
            );
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'updateCaseAvailable',
                JSON.serialize(inputStagingRec),
                e
            );
        }
    }
    
    public static void updateWaybillImage(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            List<Id> cvIds = new List<Id>();
            Case claim = [
                SELECT Id, CaseNumber, (SELECT Id, Name, CSX_CMP_Waybill_Controls__c FROM Equipments__r)
                FROM case
                WHERE Id = :inputStagingRec.CSX_CMP_Claim__c
                WITH SECURITY_ENFORCED
            ];
            String equipmentId;
            String controlNumber;
            if (!claim.Equipments__r.isEmpty()) {
                equipmentId = claim.Equipments__r[0].Name;
                equipmentId = equipmentId.deleteWhitespace();
                controlNumber = claim.Equipments__r[0].CSX_CMP_Waybill_Controls__c;
            }
            
            Blob pdfBlob;
            ContentVersion contversion = new ContentVersion();
            ContentDocumentLink cdLink = new ContentDocumentLink();
            if (controlNumber != null && equipmentId != null) {
                pdfBlob = CSX_CMP_InterfaceUtility.getWaybillImage(controlNumber, equipmentId);
            }
            
            if (pdfBlob != null) {
                contversion.Title = 'Waybill_' + claim.CaseNumber;
                contversion.PathOnClient = 'Waybill.pdf';
                contversion.VersionData = pdfBlob;
                contversion.Origin = 'H';
            
                Database.SaveResult cvRecord = Database.Insert(contversion, false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'CSX_CMP_PostClaimCreationHelper',
                    'updateWaybillImage',
                    cvRecord,
                    'ContentVersion'
                );

                if(cvRecord.isSuccess()){
                    ContentVersion contentVersionRec = [
                        SELECT Id, ContentDocumentId, Title
                        FROM ContentVersion
                        WHERE Id = :cvRecord.Id
                        WITH SECURITY_ENFORCED
                    ];
                    if (contentVersionRec != null) {
                        cdLink.ContentDocumentId = contentVersionRec.ContentDocumentId;
                        String caseNum = String.valueOf(contentVersionRec.Title.split('_')[1]);
                        if (claim.CaseNumber == caseNum) {
                            cdLink.LinkedEntityId = claim.Id;
                        }
                        cdLink.ShareType = 'V';
                        cvIds.add(contentVersionRec.Id);
                        
                        Database.SaveResult cdRecord = Database.Insert(cdLink, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_PostClaimCreationHelper',
                            'updateWaybillImage',
                            cdRecord,
                            'ContentDocumentLink'
                        );
                    }
                    
                    //send the way bill image to ECM
                    CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(cvIds, false, 'Claim', false);
                    Database.executeBatch(uploadBatch, 1);
                }
            }

            inputStagingRec.CSX_CMP_Waybill_Document_Fetch_Status__c = 'Completed';
            Database.SaveResult updateStagingRecord = Database.update(inputStagingRec, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'updateWaybillImage',
                updateStagingRecord,
                'CSX_CMP_Creation_Request__c'
            );     
        } catch (Exception e) {
            updateStagingRecord(
                'Waybill Image Fetch Error: ' + e.getMessage(),
                'CSX_CMP_Waybill_Document_Fetch_Status__c',
                inputStagingRec
            );
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'updateWaybillImage',
                JSON.serialize(inputStagingRec),
                e
            );
        }
    }
    
    public static void updateFreightBillDetails(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            List<CSX_CMP_InterfaceUtility.FreightbillRequestWrapper> request = new List<CSX_CMP_InterfaceUtility.FreightbillRequestWrapper>();
            List<Case> caseRecord = new List<Case>();
            List<String> waybillControls = new List<String>();
            Map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper> waybillCtrlToFreightBillMap = new Map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper>();
            String claimId = inputStagingRec.CSX_CMP_Claim__c;
            
            caseRecord = [
                SELECT Id, CaseNumber, recordtype.Name
                FROM Case
                WHERE Id = :claimId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!caseRecord.isEmpty()) {
                List<CSX_CMP_Equipment__c> equipments = new List<CSX_CMP_Equipment__c>();
                List<CSX_CMP_Claim_Line__c> claimLines = new List<CSX_CMP_Claim_Line__c>();
                
                if (caseRecord[0].recordtype.Name == 'Freight') {
                    equipments = [
                        SELECT Id, CSX_CMP_Waybill_Controls__c
                        FROM CSX_CMP_Equipment__c
                        WHERE CSX_CMP_Waybill_Controls__c != NULL AND CSX_CMP_Claim__c = :claimId
                        WITH SECURITY_ENFORCED
                    ];
                    for (CSX_CMP_Equipment__c equipment : equipments) {
                        waybillControls.add(equipment.CSX_CMP_Waybill_Controls__c);
                    }
                } else {
                    claimLines = [
                        SELECT Id, CSX_CMP_Waybill_Controls__c
                        FROM CSX_CMP_Claim_Line__c
                        WHERE CSX_CMP_Waybill_Controls__c != NULL AND CSX_CMP_Claim__c = :claimId
                        WITH SECURITY_ENFORCED
                    ];
                    for (CSX_CMP_Claim_Line__c claimLine : claimLines) {
                        waybillControls.add(claimLine.CSX_CMP_Waybill_Controls__c);
                    }
                }
                
                if (!waybillControls.isEmpty()) {
                    for (String waybillControl : waybillControls) {
                        CSX_CMP_InterfaceUtility.FreightbillRequestWrapper req = new CSX_CMP_InterfaceUtility.FreightbillRequestWrapper();
                        req.waybillControlNumber = waybillControl;
                        request.add(req);
                    }
                }
                
                if (!request.isEmpty()) {
                    List<CSX_CMP_InterfaceUtility.FreightbillResponseWrapper> response = new List<CSX_CMP_InterfaceUtility.FreightbillResponseWrapper>();
                    response = CSX_CMP_InterfaceUtility.fetchFreightBillDetails(request);
                    List<CSX_CMP_Equipment__c> equipmentRecords = new List<CSX_CMP_Equipment__c>();
                    List<CSX_CMP_Claim_Line__c> claimLineRecords = new List<CSX_CMP_Claim_Line__c>();
                    if (!response.isEmpty()) {
                        for (CSX_CMP_InterfaceUtility.FreightbillResponseWrapper obj : response) {
                            waybillCtrlToFreightBillMap.put(obj.wayBillControlNumber, obj);
                        }
                        // how to check whether to update Equipment or claim line?
                        if (caseRecord[0].recordtype.Name == 'Freight') {
                            for (CSX_CMP_Equipment__c equipment : equipments) {
                                // freightBillNumber we are receiving this but at our end this might be different so need to convert this
                                CSX_CMP_InterfaceUtility.FreightbillResponseWrapper freightResponse = waybillCtrlToFreightBillMap.get(
                                    equipment.CSX_CMP_Waybill_Controls__c
                                );
                                
                                equipment.CSX_CMP_Billed_Amount__c = freightResponse.billedAmount != null
                                    ? freightResponse.billedAmount
                                    : 0;
                                equipment.CSX_CMP_Amount_Rec__c = freightResponse.amountRec;
                                equipment.CSX_CMP_Balance_Due__c = freightResponse.balanceDue;
                                equipment.CSX_CMP_Freight_Bill_Num__c = freightResponse.freightBillNumber;
                                equipmentRecords.add(equipment);
                            }
                        } else {
                            for (CSX_CMP_Claim_Line__c claimLineRec : claimLines) {
                                //commented this as key is changed to freight
                                CSX_CMP_InterfaceUtility.FreightbillResponseWrapper freightResponse = waybillCtrlToFreightBillMap.get(
                                    claimLineRec.CSX_CMP_Waybill_Controls__c
                                );
                                if (freightResponse != null) {
                                    claimLineRec.CSX_CMP_Billed_Amount__c = freightResponse.billedAmount;
                                    claimLineRec.CSX_CMP_Received_Amount__c = freightResponse.amountRec;
                                    claimLineRec.CSX_CMP_Balance_Due__c = freightResponse.balanceDue;
                                    claimLineRec.CSX_CMP_Freight_Bill_Num__c = freightResponse.freightBillNumber;
                                    claimLineRecords.add(claimLineRec);
                                }
                            }
                        }
                    } else {
                        inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Error';
                        inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                            ? inputStagingRec.CSX_CMP_Error_Message__c + 'Freight Bill Fetch Error: No Freight Bill found  ; '
                            : 'Freight Bill Fetch Error: No Freight Bill found ; ';
                    }
                    
                    if (!equipmentRecords.isEmpty()) {
                        try {
                            Database.SaveResult[] updateEquipResults = Database.update(equipmentRecords, false);
                            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                                'CSX_CMP_PostClaimCreationHelper',
                                'updateFreightBillDetails',
                                updateEquipResults,
                                'CSX_CMP_Equipment__c'
                            );
                            inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Completed';
                        } catch (DMLException e) {
                            inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Error';
                            inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                                ? inputStagingRec.CSX_CMP_Error_Message__c + e.getMessage() + ' ; '
                                : e.getMessage() + '  ; ';
                        }
                    }
                    if (!claimLineRecords.isEmpty()) {
                        try {
                            Database.SaveResult[] updateCLResults = Database.update(claimLineRecords, false);
                            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                                'CSX_CMP_PostClaimCreationHelper',
                                'updateFreightBillDetails',
                                updateCLResults,
                                'CSX_CMP_Equipment__c'
                            );
                            inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Completed';
                        } catch (DMLException e) {
                            inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Error';
                            inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                                ? inputStagingRec.CSX_CMP_Error_Message__c + e.getMessage() + ' ; '
                                : e.getMessage() + '  ; ';
                        }
                    }
                } else {
                    //Added 27 June
                    inputStagingRec.CSX_CMP_Freight_Bill_Fetch_Status__c = 'Error';
                    inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                        ? inputStagingRec.CSX_CMP_Error_Message__c + 'Freight Bill Fetch Error: Request is empty.  ; '
                        : 'Freight Bill Fetch Error: Request is empty. ; ';
                }
                Database.SaveResult updateStagingRecord = Database.update(inputStagingRec, false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'CSX_CMP_PostClaimCreationHelper',
                    'updateFreightBillDetails',
                    updateStagingRecord,
                    'CSX_CMP_Creation_Request__c'
                );
            }
        } catch (Exception e) {
            updateStagingRecord(
                'Freight Bill Fetch Error: ' + e.getMessage(),
                'CSX_CMP_Freight_Bill_Fetch_Status__c',
                inputStagingRec
            );
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'updateFreightBillDetails',
                JSON.serialize(inputStagingRec),
                e
            );
        }
    }
    
    public static void createChecklistTasks(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            List<CSX_CMP_Task_Checklist__c> checklistTasks;
            List<Task> tasksforInsert = new List<Task>();
            
            CSX_CMP_NewClaimWrapper claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
                inputStagingRec.CSX_CMP_Request_Payload__c,
                CSX_CMP_NewClaimWrapper.class
            );
            claimInput.claimId = inputStagingRec.CSX_CMP_Claim__c;
            
            Case caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :claimInput.claimId WITH SECURITY_ENFORCED];
            
            Map<Id, list<CSX_CMP_Task_Checklist__c>> claimIdtochecklistTasksMap = CSX_CMP_BusinessRulesUtility.RunTaskChecklistBusinessRules(
                new Set<Id>{ claimInput.claimId },
                'CSX_CMP_Task_Checklist',
                null
            );
            if (!claimIdtochecklistTasksMap.isEmpty()) {
                for (Id claimIdInMap : claimIdtochecklistTasksMap.keySet()) {
                    if (claimIdInMap == claimInput.claimId) {
                        checklistTasks = claimIdtochecklistTasksMap.get(claimIdInMap);
                    }
                }
                
                //insert tasks
                if (!checklistTasks.isEmpty()) {
                    for (CSX_CMP_Task_Checklist__c clTask : checklistTasks) {
                        Task newTask = new Task();
                        newTask.Subject = clTask.CSX_CMP_Task_Name__c;
                        newTask.WhatId = caseRecord.Id;
                        newTask.OwnerId = caseRecord.OwnerId;
                        tasksforInsert.add(newTask);
                    }
                    if (!tasksforInsert.isEmpty()) {
                        Database.SaveResult[] taskResults = Database.insert(tasksforInsert, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_PostClaimCreationHelper',
                            'createChecklistTasks',
                            taskResults,
                            'Task'
                        );
                    }
                }
            }
        } catch (Exception e) {
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'createChecklistTasks', parameters, e);
        }
    }
    
    public static void updateUmlerDetails(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            CSX_CMP_NewClaimWrapper claimInput;
            
            if (inputStagingRec.CSX_CMP_Request_Payload__c == null || inputStagingRec.CSX_CMP_Request_Payload__c == '') {
                claimInput = CSX_CMP_ClaimCreationHelper.getNewClaimWrapper(inputStagingRec.Id);
            } else {
                claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
                    inputStagingRec.CSX_CMP_Request_Payload__c,
                    CSX_CMP_NewClaimWrapper.class
                );
            }
            
            claimInput.claimId = inputStagingRec.CSX_CMP_Claim__c;
            String equipmentId;
            Set<String> equipmentIds = new Set<String>();
            
            Map<String, List<CSX_CMP_InterfaceUtility.UmlerResponseWrapper>> umlerDetails = new Map<String, List<CSX_CMP_InterfaceUtility.UmlerResponseWrapper>>();
            Map<String, CSX_CMP_InterfaceUtility.UmlerResponseWrapper> equipmentToUmlerResponseMap = new Map<String, CSX_CMP_InterfaceUtility.UmlerResponseWrapper>();
            Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
            Id recordTypeId = recordTypeMap.get(claimInput.claimRecordType).getRecordTypeId();
            if (recordTypeId == recordTypeMap.get('Freight').getRecordTypeId()) {
                List<CSX_CMP_Equipment__c> equipmentRecords = [
                    SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c
                    FROM CSX_CMP_Equipment__c
                    WHERE CSX_CMP_Claim__c = :claimInput.claimId
                    WITH SECURITY_ENFORCED
                ];
                
                if(!equipmentRecords.isEmpty()){
                    List<String> equipmentIdList = new List<String>();
                    Map<String, CSX_CMP_Equipment__c> eqpMap = new Map<String, CSX_CMP_Equipment__c>();
                    List<CSX_CMP_Equipment__c> eqpListToUpdate = new List<CSX_CMP_Equipment__c>();
                    for (CSX_CMP_Equipment__c eqp : equipmentRecords) {
                        string equipInitial ='';
                        string equipNumber ='';
                        string equipId ='';
                        String equipmentIdForMap = eqp.CSX_CMP_Equipment_Initial__c;
                        if (eqp.CSX_CMP_Equipment_Initial__c.length() < 4) {
                            equipInitial = eqp.CSX_CMP_Equipment_Initial__c.rightPad(4, ' ');
                        } else {
                            equipInitial = eqp.CSX_CMP_Equipment_Initial__c;
                        }
                        
                        if(string.isNotBlank(eqp.CSX_CMP_Equipment_Num__c)){
                            if (eqp.CSX_CMP_Equipment_Num__c.length() < 6) {
                                equipNumber = eqp.CSX_CMP_Equipment_Num__c.leftPad(6, ' ');	
                            } else {
                                equipNumber = eqp.CSX_CMP_Equipment_Num__c;
                            }
                        }
                        
                        if (string.isNotBlank(equipInitial) && string.isNotBlank(equipNumber)) {
                            equipId = equipInitial + equipNumber;
                            equipNumber = equipNumber.replace(' ','0');
                            equipmentIdForMap += equipNumber;
                        }
                        equipmentIdList.add(equipId);
                        eqpMap.put(equipmentIdForMap, eqp);
                    }
                    
                    Map<String, List<CSX_CMP_InterfaceUtility.UmlerResponseWrapper>> umlerResponse = CSX_CMP_InterfaceUtility.fetchUmlerdetails(
                        equipmentIdList
                    );
                    
                    if (umlerResponse.get('Success') != null) {
                        for (CSX_CMP_InterfaceUtility.UmlerResponseWrapper umlerEqp : umlerResponse.get('Success')) {
                            if(umlerEqp != null){
                                CSX_CMP_Equipment__c eqp;
                                if (eqpMap.containsKey(umlerEqp.carId)) {
                                    eqp = eqpMap.get(umlerEqp.carId);
                                } else if (eqpMap.containsKey(umlerEqp.equipmentNumber)){
                                    eqp = eqpMap.get(umlerEqp.equipmentNumber);
                                }
                                if (eqp != null) {
                                    eqp.CSX_CMP_AAR_Car_Type__c = umlerEqp.aaaCarType != null ? umlerEqp.aaaCarType : '';
                                    eqp.CSX_CMP_Equipment_Group__c = umlerEqp.equipmentGroup != null ? umlerEqp.equipmentGroup : '';
                                    eqp.CSX_CMP_Inside_Length__c = umlerEqp.insideLength != null ? umlerEqp.insideLength : null;
                                    eqp.CSX_CMP_Inside_Width__c = umlerEqp.insideWidth != null ? umlerEqp.insideWidth : null;
                                    eqp.CSX_CMP_Actual_Owner__c = umlerEqp.actualOwner != null ? umlerEqp.actualOwner : '';
                                    eqp.CSX_CMP_Lessee__c = umlerEqp.lessee != null ? umlerEqp.lessee : '';
                                    eqp.CSX_CMP_Outer_Length__c = umlerEqp.outerLength != null ? umlerEqp.outerLength : null;
                                    
                                    eqpListToUpdate.add(eqp);
                                }
                            }
                        }
                    }else if (umlerResponse.get('Error') != null) {
                        String errorMessage = 'Not able to fetch UMLER details ';
                        inputStagingRec.CSX_CMP_Umler_Fetch_Status__c = 'Error';
                        inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                            ? inputStagingRec.CSX_CMP_Error_Message__c + errorMessage + ' ; '
                            : errorMessage + ' ; ';
                    }
                    
                    Database.SaveResult[] updateEquipRecord = Database.update(eqpListToUpdate, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_PostClaimCreationHelper',
                        'updateUmlerDetails',
                        updateEquipRecord,
                        'CSX_CMP_Equipment__c'
                    );
                    Boolean allSuccess = true;
                    
                    for (Database.SaveResult result : updateEquipRecord) {
                        if (!result.isSuccess()) {
                            allSuccess = false;
                            break;
                        }
                    }
                    if (allSuccess) {
                        inputStagingRec.CSX_CMP_Umler_Fetch_Status__c = 'Completed';
                    }
                }
            }  else {
                List<CSX_CMP_Claim_Line__c> claimLineRecords = [
                    SELECT Id, CSX_CMP_Claim__c, CSX_CMP_Equipment_Initial__c, CSX_CMP_Equipment_Num__c
                    FROM CSX_CMP_Claim_Line__c
                    WHERE CSX_CMP_Claim__c = :claimInput.claimId
                    WITH SECURITY_ENFORCED
                ];
                
                // Map<string,object> claimLineequpMap = new Map<string,object>();
                for (CSX_CMP_Claim_Line__c cl : claimLineRecords) {
                    equipmentId = cl.CSX_CMP_Equipment_Initial__c + cl.CSX_CMP_Equipment_Num__c;
                    equipmentIds.add(equipmentId);
                    // claimLineequpMap.put(equipmentId,cl);
                }
                
                if (!equipmentIds.isEmpty()) {
                    umlerDetails = CSX_CMP_InterfaceUtility.fetchUmlerdetails(new List<String>(equipmentIds));
                    
                    if (umlerDetails.get('Success') != null) {
                        for (CSX_CMP_InterfaceUtility.UmlerResponseWrapper obj : umlerDetails.get('Success')) {
                            equipmentToUmlerResponseMap.put(obj.equipmentNumber, obj);
                            equipmentToUmlerResponseMap.put(obj.carId, obj);
                        }
                        for (CSX_CMP_Claim_Line__c claimLine : claimLineRecords) {
                            String equipmentKey = claimLine.CSX_CMP_Equipment_Initial__c + claimLine.CSX_CMP_Equipment_Num__c;
                            CSX_CMP_InterfaceUtility.UmlerResponseWrapper umlerResponse = new CSX_CMP_InterfaceUtility.UmlerResponseWrapper();
                            if (equipmentIds.contains((String) equipmentToUmlerResponseMap.get(equipmentKey).carId) && equipmentToUmlerResponseMap.get(equipmentKey) != null) {
                                umlerResponse = equipmentToUmlerResponseMap.get(
                                    equipmentKey
                                );
                            }else{
                                umlerResponse = equipmentToUmlerResponseMap.get(
                                    equipmentKey
                                );
                            }
                            
                            if(umlerResponse != null){
                                claimLine.CSX_CMP_AAR_Car_Type__c = umlerResponse.aaaCarType;
                                claimLine.CSX_CMP_Actual_Owner__c = umlerResponse.actualOwner;
                                claimLine.CSX_CMP_Equipment_Group__c = umlerResponse.equipmentGroup;
                                claimLine.CSX_CMP_Inside_Length__c = umlerResponse.insideLength;
                                claimLine.CSX_CMP_Inside_Width__c = umlerResponse.insideWidth;
                                claimLine.CSX_CMP_Lessee__c = umlerResponse.lessee;
                                claimLine.CSX_CMP_Outer_Length__c = umlerResponse.outerLength;
                            }
                        }
                        Database.SaveResult[] claimLineRecs = Database.Update(claimLineRecords, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_PostClaimCreationHelper',
                            'updateUmlerDetails',
                            claimLineRecs,
                            'CSX_CMP_Claim_Line__c'
                        );
                        
                        inputStagingRec.CSX_CMP_Umler_Fetch_Status__c = 'Completed';
                    } else if (umlerDetails.get('Error') != null) {
                        String errorMessage = 'Not able to fetch UMLER details ';
                        inputStagingRec.CSX_CMP_Umler_Fetch_Status__c = 'Error';
                        inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                            ? inputStagingRec.CSX_CMP_Error_Message__c + errorMessage + ' ; '
                            : errorMessage + ' ; ';
                    }
                }
            }
            CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
        } catch (Exception e) {
            updateStagingRecord('UMER Fetch Error: ' + e.getMessage(), 'CSX_CMP_Umler_Fetch_Status__c', inputStagingRec);
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'updateUmlerDetails', parameters, e);
        }
    }
    
    public static void linkRelatedClaims(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            CSX_CMP_NewClaimWrapper claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
                inputStagingRec.CSX_CMP_Request_Payload__c,
                CSX_CMP_NewClaimWrapper.class
            );
            // Map<Id, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosById();
            claimInput.claimId = inputStagingRec.CSX_CMP_Claim__c;
            Map<Id, List<String>> relatedClaimIds = new Map<Id, List<String>>();
            List<String> relatedClaims = new List<String>();
            //Set<Id> totalCostCalculationIds = new Set<Id>();
            if (claimInput.claimRecordType == 'Revenue_Contract_Refund') {
                List<Case> claimsUnderContract = [
                    SELECT Id, caseNumber
                    FROM Case
                    WHERE
                    CSX_CMP_Contract_Num__c = :claimInput.contractNumber
                    AND CreatedDate = LAST_N_DAYS:365
                    AND Id != :claimInput.claimId
                    WITH SECURITY_ENFORCED
                ];
                for (Case claim : claimsUnderContract) {
                    relatedClaims.add(claim.Id);
                }
                relatedClaimIds.put(claimInput.claimId, relatedClaims);
                
                CSX_CMP_Utility.createRelatedClaim(relatedClaimIds);
            } else if (claimInput.claimRecordType == 'Freight') {
                List<CSX_CMP_Equipment__c> relatedEquipmentRecords = [
                    SELECT
                    Id,
                    CSX_CMP_Claim__c,
                    CSX_CMP_Claim__r.RecordTypeId,
                    Name,
                    CSX_CMP_Waybill_Num__c,
                    CSX_CMP_Waybill_Date__c,
                    (SELECT Id, CSX_CMP_VIN__c FROM Products__r WHERE CSX_CMP_VIN__c != NULL)
                    FROM CSX_CMP_Equipment__c
                    WHERE
                    CSX_CMP_Waybill_Num__c != NULL
                    AND CSX_CMP_Waybill_Num__c = :claimInput.equipment[0].waybillNumber
                    AND CSX_CMP_Waybill_Date__c = :claimInput.equipment[0].waybillDate
                    AND CSX_CMP_Claim__c != :claimInput.claimId
                    AND CSX_CMP_Claim__c != NULL
                    WITH SECURITY_ENFORCED
                ];
                
                if (!relatedEquipmentRecords.isEmpty()) {
                    for (CSX_CMP_Equipment__c relatedEqp : relatedEquipmentRecords) {
                        relatedClaims.add(relatedEqp.CSX_CMP_Claim__c);
                    }
                    relatedClaimIds.put(claimInput.claimId, relatedClaims);
                }
                //totalCostCalculationIds.add(claimInput.claimId);
                
                CSX_CMP_Utility.createRelatedClaim(relatedClaimIds);
            } else {
                List<CSX_CMP_Claim_Line__c> newClaimLineRecords = [
                    SELECT
                    Id,
                    CSX_CMP_Claim__c,
                    CSX_CMP_Equipment_Initial__c,
                    CSX_CMP_Equipment_Num__c,
                    CSX_CMP_Waybill_Num__c,
                    CSX_CMP_Waybill_Date__c
                    FROM CSX_CMP_Claim_Line__c
                    WHERE CSX_CMP_Waybill_Num__c != NULL AND CSX_CMP_Claim__c = :claimInput.claimId
                    WITH SECURITY_ENFORCED
                ];
                
                List<String> newWaybillNumbers = new List<String>();
                Set<String> relatedClaimsSet = new Set<String>();
                for (CSX_CMP_Claim_Line__c claimLine : newClaimLineRecords) {
                    newWaybillNumbers.add(claimLine.CSX_CMP_Waybill_Num__c);
                }
                
                if (!newWaybillNumbers.isEmpty()) {
                    List<CSX_CMP_Claim_Line__c> existingClaimLineRecords = [
                        SELECT
                        Id,
                        CSX_CMP_Claim__c,
                        CSX_CMP_Claim__r.RecordTypeId,
                        CSX_CMP_Equipment_Initial__c,
                        CSX_CMP_Equipment_Num__c,
                        CSX_CMP_Waybill_Num__c,
                        CSX_CMP_Waybill_Date__c
                        FROM CSX_CMP_Claim_Line__c
                        WHERE CSX_CMP_Waybill_Num__c IN :newWaybillNumbers AND CSX_CMP_Claim__c != :claimInput.claimId
                        WITH SECURITY_ENFORCED
                    ];
                    for (CSX_CMP_Claim_Line__c newclaimLine : newClaimLineRecords) {
                        for (CSX_CMP_Claim_Line__c existingClaimLine : existingClaimLineRecords) {
                            if (
                                newclaimLine.CSX_CMP_Waybill_Num__c == existingClaimLine.CSX_CMP_Waybill_Num__c &&
                                newclaimLine.CSX_CMP_Waybill_Date__c == existingClaimLine.CSX_CMP_Waybill_Date__c
                            ) {
                                relatedClaimsSet.add(existingClaimLine.CSX_CMP_Claim__c);
                            }
                        }
                    }
                    
                    if (string.isNotBlank(claimInput.previousClaimNumber)) {
                        Case objClaim = [
                            SELECT Id
                            FROM Case
                            WHERE CaseNumber = :claimInput.previousClaimNumber
                            WITH SECURITY_ENFORCED
                        ];
                        relatedClaimsSet.add(objClaim.Id); //[MR -00776]
                    }
                    relatedClaims.addAll(relatedClaimsSet);
                    relatedClaimIds.put(claimInput.claimId, relatedClaims);
                    
                    CSX_CMP_Utility.createRelatedClaim(relatedClaimIds);
                }
            }
        } catch (Exception e) {
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'linkRelatedClaims', parameters, e);
        }
    }
    
    public static void linkRelatedLDReports(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            CSX_CMP_NewClaimWrapper claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
                inputStagingRec.CSX_CMP_Request_Payload__c,
                CSX_CMP_NewClaimWrapper.class
            );
            claimInput.claimId = inputStagingRec.CSX_CMP_Claim__c;
            Map<String, String> relatedLdrAndClaim = new Map<String, String>();
            
            List<CSX_CMP_Equipment__c> relatedEquipmentRecords = [
                SELECT Id, CSX_CMP_Claim__c, CSX_CMP_LD_Report__c, CSX_CMP_Waybill_Num__c, CSX_CMP_Waybill_Date__c
                FROM CSX_CMP_Equipment__c
                WHERE
                CSX_CMP_Waybill_Num__c = :claimInput.equipment[0].waybillNumber
                AND CSX_CMP_Waybill_Date__c = :claimInput.equipment[0].waybillDate
                AND CSX_CMP_LD_Report__c != NULL
                WITH SECURITY_ENFORCED
            ];
            if (!relatedEquipmentRecords.isEmpty()) {
                for (CSX_CMP_Equipment__c relatedEqp : relatedEquipmentRecords) {
                    relatedLdrAndClaim.put(relatedEqp.CSX_CMP_LD_Report__c, claimInput.claimId);
                }
            }
            CSX_CMP_ClaimCreationHelper.createRelatedClaimForLDReport(relatedLdrAndClaim);
        } catch (Exception e) {
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'linkRelatedLDReports', parameters, e);
        }
    }
    
    public static void linkRelatedInspections(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            List<CSX_CMP_Inspection_Detail__c> inspectionDetailRecords = new List<CSX_CMP_Inspection_Detail__c>();
            CSX_CMP_Product__c productRecord = new CSX_CMP_Product__c();
            List<CSX_CMP_Inspection_Damage__c> inspectionDamageList = new List<CSX_CMP_Inspection_Damage__c>();
            // CSX_CMP_NewClaimWrapper claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
            //     inputStagingRec.CSX_CMP_Request_Payload__c,
            //     CSX_CMP_NewClaimWrapper.class
            // );
            Case caseRecord = [
                SELECT Id, CaseNumber, CSX_CMP_VIN__c, (SELECT Id FROM Equipments__r)
                FROM Case
                WHERE Id = :inputStagingRec.CSX_CMP_Claim__c
                WITH SECURITY_ENFORCED
            ];
            if (caseRecord != null && caseRecord.CSX_CMP_VIN__c != null) {
                inspectionDetailRecords = [
                    SELECT Id, CSX_CMP_VIN__c
                    FROM CSX_CMP_Inspection_Detail__c
                    WHERE CSX_CMP_VIN__c = :caseRecord.CSX_CMP_VIN__c
                    WITH SECURITY_ENFORCED
                ];
                productRecord = [
                    SELECT Id, CSX_CMP_VIN__c
                    FROM CSX_CMP_Product__c
                    WHERE
                    CSX_CMP_VIN__c != NULL
                    AND CSX_CMP_VIN__c = :caseRecord.CSX_CMP_VIN__c
                    AND CSX_CMP_Equipment__c = :caseRecord.Equipments__r[0].Id
                    WITH SECURITY_ENFORCED
                ];
            }
            if (!inspectionDetailRecords.isEmpty() && productRecord != null) {
                for (CSX_CMP_Inspection_Detail__c inspectionDetail : inspectionDetailRecords) {
                    CSX_CMP_Inspection_Damage__c inspectionDamage = new CSX_CMP_Inspection_Damage__c();
                    inspectionDamage.CSX_CMP_Inspection_Detail__c = inspectionDetail.Id;
                    inspectionDamage.CSX_CMP_Product__c = productRecord.Id;
                    inspectionDamageList.add(inspectionDamage);
                }
                if (!inspectionDamageList.isEmpty()) {
                    Database.SaveResult[] relatedInspectionDamageResult = Database.insert(inspectionDamageList, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_ClaimCreationHelper',
                        'createRelatedInspection',
                        relatedInspectionDamageResult,
                        'CSX_CMP_Inspection_Damage__c'
                    );
                }
            }
        } catch (Exception e) {
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'linkRelatedInspections', parameters, e);
        }
    }
    
    public static void invokeBusinessRules(CSX_CMP_Creation_Request__c inputStagingRec) {
        try {
            //invoking AutoDecline and AutoPayRules
            CSX_CMP_NewClaimWrapper claimInput = (CSX_CMP_NewClaimWrapper) JSON.deserialize(
                inputStagingRec.CSX_CMP_Request_Payload__c,
                CSX_CMP_NewClaimWrapper.class
            );
            claimInput.claimId = inputStagingRec.CSX_CMP_Claim__c;
            Case caseRecord = [
                SELECT
                Id,
                CaseNumber,
                RecordTypeId,
                CSX_CMP_Desk_Name__c,
                CSX_CMP_Claim_Amount__c,
                Type,
                Origin,
                CSX_CMP_AutoPay_Kickout__c,
                CSX_CMP_Auto_Pay__c,
                CSX_CMP_Decline_Code__c,
                Status,
                CSX_CMP_Dealer_SPLC__c,
                CSX_CMP_RACF_ID__c,
                CSX_CMP_System_Action_Toggle__c
                FROM Case
                WHERE Id = :claimInput.claimId
                WITH SECURITY_ENFORCED
            ];
            
            set<Id> claimIds = new Set<Id>();
            List<String> codeAndReason = new List<String>();
            List<String> returnedList = new List<String>();
            String declineCode;
            String autoPayCode;
            claimIds.add(claimInput.claimId);
            CSX_CMP_Notes__c newNote = new CSX_CMP_Notes__c();
            Map<Id, List<String>> declineRuleResults = CSX_CMP_BusinessRulesUtility.RunAutoDeclineBusinessRules(
                claimIds,
                'CSX_CMP_Auto_decline',
                null
            );
            //none of the decline rules satisfy
            if (declineRuleResults.isEmpty()) {
                Map<Id, List<String>> autoPayKickoutResults = CSX_CMP_BusinessRulesUtility.RunAutoPayKickoutBusinessRules(
                    claimIds,
                    'CSX_CMP_Auto_pay_kickout',
                    null
                );
                
                if (!autoPayKickoutResults.isEmpty()) {
                    returnedList = autoPayKickoutResults.get(claimInput.claimId);
                    // stamping the first kickout code from the list
                    if (!returnedList.isEmpty()) {
                        codeAndReason = returnedList[0].split('###');
                        autoPayCode = codeAndReason[0];
                        List<CSX_CMP_Auto_pay_kickout_Code_Master__c> kickoutCodeMaster = [
                            SELECT Id
                            FROM CSX_CMP_Auto_pay_kickout_Code_Master__c
                            WHERE Name = :autoPayCode
                            WITH SECURITY_ENFORCED
                            LIMIT 1
                        ];
                        caseRecord.CSX_CMP_AutoPay_Kickout__c = kickoutCodeMaster[0].id;
                        caseRecord.CSX_CMP_AutoPay_Kickout_Description__c = codeAndReason[1];
                    }
                } else {
                    caseRecord.CSX_CMP_Auto_Pay__c = true;
                    caseRecord.Status = 'Pending Close';
                    // add auto distribution logic here
                    Map<Id, CSX_CMP_Equipment__c> equipmentMap = new Map<Id, CSX_CMP_Equipment__c>(
                        [
                            SELECT Id, CSX_CMP_Claim__c
                            FROM CSX_CMP_Equipment__c
                            WHERE CSX_CMP_Claim__c = :claimInput.claimId
                            WITH SECURITY_ENFORCED
                        ]
                    );
                    List<String> equipmentIds = new List<String>();
                    for (CSX_CMP_Equipment__c equipment : equipmentMap.values()) {
                        equipmentIds.add(equipment.Id);
                    }
                    List<CSX_CMP_Distribution__c> distributionList = new List<CSX_CMP_Distribution__c>();
                    distributionList = CSX_CMP_DistributionClaimCreateControlr.calculateDistributionAmount(equipmentIds);
                    
                    if (!distributionList.isEmpty()) {
                        CSX_CMP_DistributionClaimCreateControlr.createDistributionClaim(equipmentIds[0]);
                    }
                }
            } else {
                //decline the claim
                returnedList = declineRuleResults.get(claimInput.claimId);
                if (!returnedList.isEmpty()) {
                    codeAndReason = returnedList[0].split('###');
                    declineCode = codeAndReason[0];
                    List<CSX_CMP_Decline_Code_Master__c> declineCodeMaster = [
                        SELECT Id
                        FROM CSX_CMP_Decline_Code_Master__c
                        WHERE Name = :declineCode
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                    ];
                    caseRecord.CSX_CMP_Decline_Code__c = declineCodeMaster[0].Id;
                    caseRecord.Status = 'Declined';
                }
            }
            if (!returnedList.isEmpty()) {
                newNote.CSX_CMP_Note_Type__c = 'AutoPay/Decline Result';
                newNote.CSX_CMP_Claim__c = caseRecord.Id;
                String returnedMsg = JSON.serialize(returnedList).replace('###', ' - ');
                returnedMsg = returnedMsg.replace(',', ', \n');
                //String returnedMsg = returnedList[0].replace('###',' - ');
                if (caseRecord.CSX_CMP_AutoPay_Kickout__c != null) {
                    newNote.CSX_CMP_Notes__c = 'Auto-Pay evaluation: \n' + returnedMsg;
                } else if (caseRecord.CSX_CMP_Decline_Code__c != null) {
                    newNote.CSX_CMP_Notes__c = 'Auto-decline evaluation: \n' + returnedMsg;
                }
            }
            Database.SaveResult declineNote = Database.Insert(newNote, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'invokeBusinessRules',
                declineNote,
                'CSX_CMP_Notes__c'
            );
            
            caseRecord.CSX_CMP_System_Action_Toggle__c = !(caseRecord.CSX_CMP_System_Action_Toggle__c);
            Database.SaveResult updateClaimRecord = Database.update(caseRecord, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                'CSX_CMP_PostClaimCreationHelper',
                'invokeBusinessRules',
                updateClaimRecord,
                'Case'
            );
            
            //update staging record
            inputStagingRec.CSX_CMP_Autopay_Decline_Execution_Status__c = 'Completed';
            CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
        } catch (Exception e) {
            inputStagingRec.CSX_CMP_Autopay_Decline_Execution_Status__c = 'Error';
            inputStagingRec.CSX_CMP_Error_Message__c = inputStagingRec.CSX_CMP_Error_Message__c != null
                ? inputStagingRec.CSX_CMP_Error_Message__c + e.getMessage() + ' ; '
                : e.getMessage() + '  ; ';
            CSX_CMP_ClaimCreationHelper.updateStagingRecord(inputStagingRec);
            String parameters = JSON.serialize(inputStagingRec);
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_PostClaimCreationHelper', 'invokeBusinessRules', parameters, e);
        }
    }
    
    private static void updateStagingRecord(
        String errorMessage,
        String statusField,
        CSX_CMP_Creation_Request__c stagingRec
    ) {
        stagingRec.CSX_CMP_Error_Message__c = stagingRec.CSX_CMP_Error_Message__c != null
            ? stagingRec.CSX_CMP_Error_Message__c + errorMessage + ' ; '
            : errorMessage + ' ; ';
        stagingRec.put(statusField, 'Error');
        Database.SaveResult stagingRecUpdateRes = Database.update(stagingRec, false);
        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
            'CSX_CMP_PostClaimCreationAPIQueueable',
            'execute',
            stagingRecUpdateRes,
            'CSX_CMP_Creation_Request__c'
        );
    }
    
    //temporary method
    public static String waybillBase64() {
        String waybill = 'JVBERi0xLjQKJeLjz9MKMyAwIG9iago8PC9GaWx0ZXIvRmxhdGVEZWNvZGUvTGVuZ3RoIDcxMz4+c3RyZWFtCnic7ZlNb6MwEIbv+RUjVVrtVopiGwfD0YADbsFQ21manld72Nv+/8sa0qoNbfrBAk0qXikBbDwPM4A9xn8XkV0QBAFhYH8tEKBms9pgCMD+XnyHgfXD/nHWCWCyN98c30MRLJvSA/rlQztvzWAJUiWSKw4Z11GpIRK5Bc1lrkueQFwWFVe7DnDZNu1HH0ySYt8bnG5qaeMMar6LZJ6/dfbYvusi3moohI4/g/66PkZPub0FYCHzgqaxxSiYkP5eqwjh5m//A2X2Zejp4Yj0z/X9JOgoWCG2It5BISY+88MJ6A+qeCocFsoNAJnKd+yvQ7i4uDgoNLVamlpP6PtRzfSZPizda7vVOJMxT8sX6mX+YTpF6zB80+gJ+P4V6TKLmsg3YX+yG5Wxvd8djR6bW/seq1bzRETCbQW3hVAWvoEW8S7OpUpdfYXvbhA5v8i/R9SjHlwLpUSyA/5TTEsX3NgX3kqpgPoefhxkv2LkO0JkTRnG2Lu6um6PH3Kec/I9EzIReSR0CgW3QkueG9gaiEX7WrmOeKsZdWZDH5HQTRZZc5MRw8xNjLtPg3sKRvK9iS1t88nOBOR/fPdQQKF2c+OtsjvQCRCyBvPc6jiRz8uUK1OV+rDHa9+kkLIjjKHo/b0Ek1Ua6tQCTx+vfeJnnlAWtFlHL/o+uzieW7yZXfh+6OjbIhd6et87mpiOAxT2j/zAmulT0CstKi6TT6K/pP50N5Bg1P0wMRn9QDQAjNbgo6NnjEnvqZHonV5lWrpULvEpRCJdAvTah+Ozi7zJZFUJbSBv1gBqIdOsmSm1Cc/4dBdW7fLDNqjuQvb55GS+D6iZPtNn+kyf6SdGv88Y2vF7w2ORHDXcfD8I27QPIepabavEjUvJYzqIMMYfo186gRve3By43EDG7wpuwVnlcNlWjex7L+0XxMjzBbHTXQ0UdnGz+AdNQnvvCmVuZHN0cmVhbQplbmRvYmoKNSAwIG9iago8PC9Db250ZW50cyAzIDAgUi9UeXBlL1BhZ2UvUmVzb3VyY2VzPDwvUHJvY1NldCBbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0vRm9udDw8L0YxIDEgMCBSL0YyIDIgMCBSPj4+Pi9QYXJlbnQgNCAwIFIvTWVkaWFCb3hbMCAwIDU5NSA4NDJdPj4KZW5kb2JqCjYgMCBvYmoKPDwvRmlsdGVyL0ZsYXRlRGVjb2RlL0xlbmd0aCA1ODk+PnN0cmVhbQp4nO3WS3ObMBAA4Du/Yk+dJNPa4hUgMz3IYo2VCIGRqO1Mjp0eeuv/v1TY9SSNY+jImF6kC34w+7FIu9Ivb6G9gEAaJKC/ewS++EH3Yb70IQX9w7uBbvjA5gJ6B65bXpco9QMUVG8BkiwJ09P7bvVPEz2AzunCd98JkD69lX6Whf08ow2wqu14Qvyzt1nosKFKIywFLUu6EAiCm1Rz9fk1qlrxusbmof8R7XSQs2qmZn1hdUNzXKC5ItXdFMAnaJDtmOCyAKj95zUJrPSXm+1OoDShK9Ga68vtUIrjZs8EVQr6pz4KoxCeUErMd0C/4Xj6fF4XwHmvjmZxAFtxRovq9VcuIboPTdAL9Gb9D6+fVVLxQiIOrD2ruc/3ldQ/5yvkOYoFNgWUVGPDqVDQKmC4X4gRaZsksvJLKvkSzdvNK9bug8m2NBAMltkY2QMJ4ijxfT94fHw6EzYkaQSbQ9vZQZNDEMSgxtAHKno/RFVQqeqq0W+x/crLouQS/X1FyfZcUV3jzX9cUVPpJ5U7qR74WWi2zSw+v4NdUWdqqweiXlHX9WYk3EYXuOLF6ti22CUrz0I/dJKu2f3VTE57yXVy/7CTTJV7V3Hx2441qR4nURKHsR/8l4ozq60pULJdt5FryrTF5mavA6RRlJpTehIMnK6vof85NB8zt07cNveze+wk+puN/LJhoa/oszmrgdKMfY1Sn8T3ZBr9rhuAModqeXyKnGoKd4d/Jsh9xOF0pzvd6U53utOd7nSnO93pTne60y/UUXtr7zetOwk8CmVuZHN0cmVhbQplbmRvYmoKNyAwIG9iago8PC9Db250ZW50cyA2IDAgUi9UeXBlL1BhZ2UvUmVzb3VyY2VzPDwvUHJvY1NldCBbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0vRm9udDw8L0YxIDEgMCBSL0YyIDIgMCBSPj4+Pi9QYXJlbnQgNCAwIFIvTWVkaWFCb3hbMCAwIDU5NSA4NDJdPj4KZW5kb2JqCjEgMCBvYmoKPDwvU3VidHlwZS9UeXBlMS9UeXBlL0ZvbnQvQmFzZUZvbnQvQ291cmllci9FbmNvZGluZy9XaW5BbnNpRW5jb2Rpbmc+PgplbmRvYmoKMiAwIG9iago8PC9TdWJ0eXBlL1R5cGUxL1R5cGUvRm9udC9CYXNlRm9udC9IZWx2ZXRpY2EvRW5jb2RpbmcvV2luQW5zaUVuY29kaW5nPj4KZW5kb2JqCjQgMCBvYmoKPDwvS2lkc1s1IDAgUiA3IDAgUl0vVHlwZS9QYWdlcy9Db3VudCAyL0lUWFQoMi4xLjcpPj4KZW5kb2JqCjggMCBvYmoKPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDQgMCBSPj4KZW5kb2JqCjkgMCBvYmoKPDwvTW9kRGF0ZShEOjIwMjQwMzIwMDMwMzMwLTA0JzAwJykvQ3JlYXRpb25EYXRlKEQ6MjAyNDAzMjAwMzAzMzAtMDQnMDAnKS9Qcm9kdWNlcihpVGV4dCAyLjEuNyBieSAxVDNYVCk+PgplbmRvYmoKeHJlZgowIDEwCjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMTc4MyAwMDAwMCBuIAowMDAwMDAxODY5IDAwMDAwIG4gCjAwMDAwMDAwMTUgMDAwMDAgbiAKMDAwMDAwMTk1NyAwMDAwMCBuIAowMDAwMDAwNzk1IDAwMDAwIG4gCjAwMDAwMDA5NjEgMDAwMDAgbiAKMDAwMDAwMTYxNyAwMDAwMCBuIAowMDAwMDAyMDI2IDAwMDAwIG4gCjAwMDAwMDIwNzEgMDAwMDAgbiAKdHJhaWxlcgo8PC9JbmZvIDkgMCBSL0lEIFs8NWQ1M2MyODE0ZjIxODM4ZjFkMjU0YTFhNWYyZjYxMDI+PDY1MDAzMTdjYzUwNTQ1MWJkMDA3MGE5ZTlkNGYwMDk5Pl0vUm9vdCA4IDAgUi9TaXplIDEwPj4Kc3RhcnR4cmVmCjIxOTMKJSVFT0YK';
        return waybill;
    }
}