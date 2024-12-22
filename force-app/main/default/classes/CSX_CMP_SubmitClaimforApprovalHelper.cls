/*
@Author       - Infosys
@Name         - CSX_CMP_SubmitClaimforApprovalHelper
@Created Date - 3/8/2024
@Description  - Helper class for objClaim approval process
@RICEFW reference - CMP-I-0432
*/
public with sharing class CSX_CMP_SubmitClaimforApprovalHelper {

    //This method is used to call the approval Business rule and then call approval api
    public static String initiateApprovalProcess(Id caseId) {
        String strResult = '';
        try
        {
            if (!string.isempty(caseId)) {
                Case objCase = [SELECT Id,CaseNumber, CSX_CMP_Claim_Amount__c, Description, Type, OwnerId,
                                RecordType.DeveloperName, CSX_CMP_ECM_Link__c, CSX_CMP_System_Action_Toggle__c, CSX_CMP_Supplier_Claimant__r.Name
                                FROM Case
                                WHERE Id =: caseId
                                WITH SECURITY_ENFORCED];

                boolean isApproved = false;
                map<Id, list<CSX_CMP_Approval_Sequence__c>> mapOfApprovalClaims = CSX_CMP_BusinessRulesUtility.runApprovalBusinessRules(new set<Id>{caseId}, 'CSX_CMP_Approval',null);
                list<CSX_CMP_Approval_Sequence__c> lstApprovalSequence = new list<CSX_CMP_Approval_Sequence__c>();
                list<CSX_CMP_InterfaceUtility.ApprovalSequence> lstApprover = new list<CSX_CMP_InterfaceUtility.ApprovalSequence>();

                
                    if(mapOfApprovalClaims != null && mapOfApprovalClaims.size() > 0){
                        lstApprovalSequence = mapOfApprovalClaims.get(caseId); 
        
                        for(CSX_CMP_Approval_Sequence__c objApprovalSequence : lstApprovalSequence){
                            CSX_CMP_InterfaceUtility.ApprovalSequence objApprover = new CSX_CMP_InterfaceUtility.ApprovalSequence();
                            objApprover.approverName = objApprovalSequence.Name;
                            objApprover.approverType = objApprovalSequence.CSX_CMP_Approver_Type__c;
                            objApprover.approverUserId = objApprovalSequence.CSX_CMP_Approver__c;
                            lstApprover.add(objApprover);
                            
                            if(objApprovalSequence.CSX_CMP_Approver__c == 'CLAIM_AUTO_APPROVE'){
                                isApproved = true;	
                            }
                        }
                    }

                if(isApproved) {
                    if(objCase.RecordType.DeveloperName == 'Revenue_Contract_Refund' || objCase.RecordType.DeveloperName == 'Revenue_Overcharge'){
                        objCase.Status = 'Pending Close';
                        objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                        
                        if(objCase.OwnerId != UserInfo.getUserId()){
                            objCase.OwnerId = UserInfo.getUserId();
                        }
                    } 
                    else if(objCase.RecordType.DeveloperName == 'Freight' && (objCase.Type != 'FC RR Outbound Claim' 
                            && objCase.Type != 'Recharges Outbound Claim'))
                    {
                        if(objCase.Type == 'FC RR Inbound Claim' || objCase.Type == 'Recharges Inbound Claim' ){
                            objCase.Status = 'Pending Monthly Settlement';
                            objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                        }else{
                            objCase.Status = 'Pending Close';
                            objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                        }
                    } 
                    else if(objCase.RecordType.DeveloperName == 'Revenue_Railroad') {
                        objCase.Status = 'Pending Monthly Settlement';
                        objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;

                        if(objCase.OwnerId != UserInfo.getUserId()){
                            objCase.OwnerId = UserInfo.getUserId();
                        }
                    }

                    Database.SaveResult[] updateClaim = Database.update(new list<Case>{objCase}, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_SubmitForApprovalController',
                        'callApprovalBusinessRules',
                        updateClaim,
                        'caseId'
                    );
                    strResult = 'AUTO_APPROVED';

                } else {
                        //Send Request to BTP with Claim and approver details
                        CSX_CMP_InterfaceUtility.ApprovalInitationRequestWrapper objApprovalInitationRequestWrapper = new CSX_CMP_InterfaceUtility.ApprovalInitationRequestWrapper();
                        objApprovalInitationRequestWrapper.caseNumber = objCase.CaseNumber;
                    
                    User objUser = [SELECT Id, Name, FederationIdentifier, FirstName, LastName, Email FROM User WHERE Id =: UserInfo.getUserId() 
                    WITH SECURITY_ENFORCED];
                    string strRacfId = '';
                    string userFullName = '';
                    if(!string.isEmpty(objUser.FederationIdentifier)){
                        if(objUser.FederationIdentifier.contains('@')){
                            list<String> lstFedration = objUser.FederationIdentifier.split('@'); 
                            strRacfId = lstFedration[0];
                            userFullName = objUser.Name;

                        }else{
                            strRacfId = objUser.FederationIdentifier;
                            userFullName = objUser.Name;
                        }
                    }
                    objApprovalInitationRequestWrapper.claimAgentUserId = strRacfId;
                    objApprovalInitationRequestWrapper.claimAmount = string.valueOf(objCase.CSX_CMP_Claim_Amount__c);
                    objApprovalInitationRequestWrapper.firstName = objUser.FirstName;
                    objApprovalInitationRequestWrapper.lastName = objUser.lastName;
                    objApprovalInitationRequestWrapper.approverEmail = objUser.email;
                    objApprovalInitationRequestWrapper.supplierName = objCase.CSX_CMP_Supplier_Claimant__r.Name;

                    Blob objBlob;

                    if (!Test.isRunningTest()) {
                        if(objCase.RecordType.DeveloperName == 'Freight'){
                            objBlob = new PageReference(Site.getBaseUrl() +
                                        '/apex/CSX_CMP_FreightClaimSummary?id=' + objCase.Id).getContent();
                        }
                        else if(objCase.RecordType.DeveloperName =='Revenue_Contract_Refund'){
                            objBlob = new PageReference(Site.getBaseUrl() +
                                        '/apex/CSX_CMP_ContractRefundSummary?id=' + objCase.Id).getContent();
                        }
                        else if(objCase.RecordType.DeveloperName == 'Revenue_Overcharge'){
                            objBlob = new PageReference(Site.getBaseUrl() +
                                        '/apex/CSX_CMP_OverchargeSummaryReport?id=' + objCase.Id).getContent();
                        }
                        else if(objCase.RecordType.DeveloperName == 'Revenue_Railroad'){
                            objBlob = new PageReference(Site.getBaseUrl() +
                                        '/apex/CSX_CMP_RevenueRRSummaryReport?id=' + objCase.Id).getContent();
                        }			
                    } else {
                        objBlob = Blob.valueOf('test');
                    }		
                    
                    objApprovalInitationRequestWrapper.claimSummaryPdfUrl = EncodingUtil.base64Encode(objBlob);
                    objApprovalInitationRequestWrapper.documentationLink = objCase.CSX_CMP_ECM_Link__c;
                    objApprovalInitationRequestWrapper.claimId = objCase.id;
                    objApprovalInitationRequestWrapper.comments = objCase.Description;
                    objApprovalInitationRequestWrapper.claimType = objCase.Type;
                    objApprovalInitationRequestWrapper.approvalSequence = lstApprover; 
                    
                    // system.debug('objApprovalInitationRequestWrapper@@sarath'+objApprovalInitationRequestWrapper);
                    CSX_CMP_InterfaceUtility.ApprovalResponseWrapperBTP objResponseWrapper = CSX_CMP_InterfaceUtility.sendApprovalInitiationRequest(objApprovalInitationRequestWrapper);
                    if (Test.isRunningTest()) {
                        objResponseWrapper.integrationStatus = 'Processed';
                    } 
                    if(!string.isempty(objResponseWrapper.integrationStatus) && objResponseWrapper.integrationStatus == 'Processed'){
                        if (objCase.Type == 'Rev-RR - Receivable Rchg Claim' && objCase.Type == 'Rev-RR - Receivable Claim'){
                            objCase.status = 'Pending Monthly Settlement';
                            objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                        } else {
                            objCase.status = 'Pending Approval';
                            objCase.CSX_CMP_System_Action_Toggle__c = !objCase.CSX_CMP_System_Action_Toggle__c;
                        }

                        if(objCase.RecordType.DeveloperName == 'Revenue_Contract_Refund' || 
                            objCase.RecordType.DeveloperName == 'Revenue_Overcharge' || 
                            objCase.RecordType.DeveloperName == 'Revenue_Railroad'){
                            if(objCase.OwnerId != UserInfo.getUserId()){
                                objCase.OwnerId = UserInfo.getUserId();
                            }
                        }
                        

                        Database.SaveResult[] updateClaim = Database.update(new list<Case>{objCase}, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_SubmitForApprovalController',
                            'callApprovalBusinessRules',
                            updateClaim,
                            'caseId'
                        );

                        //Create Approval history record for submitted condtion
                        CSX_CMP_Approval_History__c objApprovalHistory = new CSX_CMP_Approval_History__c();
                        objApprovalHistory.CSX_CMP_Approval_Status__c = 'Approved';
                        objApprovalHistory.CSX_CMP_Created_Date_in_BTP__c = system.now();
                        objApprovalHistory.CSX_CMP_Claim__c = objCase.id;
                        objApprovalHistory.CSX_CMP_Date__c = system.now();
                        objApprovalHistory.CSX_CMP_Name__c = userFullName;
                        objApprovalHistory.CSX_CMP_RACF_ID__c = strRacfId;
                        objApprovalHistory.CSX_CMP_Sequence_Number__c = 0;

                        
                        Database.SaveResult[] createApprovalHistory = Database.Insert(new list<CSX_CMP_Approval_History__c>{objApprovalHistory}, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                            'CSX_CMP_SubmitForApprovalController',
                            'callApprovalBusinessRules',
                            createApprovalHistory,
                            'ApprovalHistoryId'
                        );

                        strResult = 'BTP_APPROVAL';
                    }else{
                        strResult = objResponseWrapper.errorReason;
                    }
                }
            }	
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_SubmitClaimforApprovalHelper',
                'initiateApprovalProcess',
                caseId,
                ex
            );
        }
        return strResult;
    }
    
    //This method is used to send the wrapper result to update
    public static map<Case,Boolean> updateLatestFreightBillInfofromSAP(list<Id> lstClaimIds) 
    {
        map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper> mapOfFreightBillWithResponseWrapper = new map<String, CSX_CMP_InterfaceUtility.FreightbillResponseWrapper>();
        map<Case,Boolean> claimIdtoGoodforApprStatusMap = new map<Case,Boolean>();
        list<CSX_CMP_Claim_Line__c> lstClaimLineToUpdate = new list<CSX_CMP_Claim_Line__c>();
        
        try {
            if (!lstClaimIds.isempty()) {
                List<Case> lstClaims = [SELECT id , Owner.Email, CaseNumber, CSX_CMP_System_Action_Toggle__c,
                                        (SELECT CSX_CMP_Claim__c, CSX_CMP_Claim_Amount__c, 	
                                         CSX_CMP_Freight_Bill_Num__c 
                                         FROM ClaimLines__r)
                                        FROM Case 
                                        WHERE id IN : lstClaimIds
                                        WITH SECURITY_ENFORCED]; 
                
                List<CSX_CMP_InterfaceUtility.FreightbillRequestWrapper> lstFreightBillRequestWrapper = new List<CSX_CMP_InterfaceUtility.FreightbillRequestWrapper>();
                //Loopover objClaim and objClaim line to create the request wrapper
                for(Case objCase : lstClaims){
                    //system.debug('objCase.ClaimLines__r::: '+objCase.ClaimLines__r.size());
                    if(objCase.ClaimLines__r != null && objCase.ClaimLines__r.size() > 0){
                        for (CSX_CMP_Claim_Line__c objClaimLIne : objCase.ClaimLines__r) {
                            CSX_CMP_InterfaceUtility.FreightbillRequestWrapper objFreightbillRequestWrapper = new CSX_CMP_InterfaceUtility.FreightbillRequestWrapper();
                            
                            if (objClaimLIne.CSX_CMP_Freight_Bill_Num__c != null) {
                                objFreightbillRequestWrapper.freightBillNumber = objClaimLIne.CSX_CMP_Freight_Bill_Num__c;
                            }
                            //objFreightbillRequestWrapper.systemName = 'Salesforce';
                            lstFreightBillRequestWrapper.add(objFreightbillRequestWrapper);
                        }
                    }
                }
                if(lstFreightBillRequestWrapper.size() > 0){
                    List<CSX_CMP_InterfaceUtility.FreightbillResponseWrapper> lstFreightBillResposeWrapper = CSX_CMP_InterfaceUtility.fetchFreightBillDetails(
                        lstFreightBillRequestWrapper
                    );
                    
                    for (CSX_CMP_InterfaceUtility.FreightbillResponseWrapper objFreightbillResponseWrapper : lstFreightBillResposeWrapper) {
                        mapOfFreightBillWithResponseWrapper.put(
                            objFreightbillResponseWrapper.freightBillNumber, objFreightbillResponseWrapper
                        );
                    }
                    
                    //Loopover objClaim and claimline to get the updated result
                    for(Case objCase : lstClaims) {
                        claimIdtoGoodforApprStatusMap.put(objCase, true);
                        if(objCase.ClaimLines__r != null && objCase.ClaimLines__r.size() > 0) {
                            for (CSX_CMP_Claim_Line__c objClaimLIne : objCase.ClaimLines__r) {
                                if (mapOfFreightBillWithResponseWrapper.containsKey(objClaimLIne.CSX_CMP_Freight_Bill_Num__c)) {
                                    CSX_CMP_InterfaceUtility.FreightbillResponseWrapper freightResponse = mapOfFreightBillWithResponseWrapper.get(
                                        objClaimLIne.CSX_CMP_Freight_Bill_Num__c
                                    );
                                    objClaimLIne.CSX_CMP_Billed_Amount__c = freightResponse.billedAmount;
                                    objClaimLIne.CSX_CMP_Received_Amount__c = freightResponse.amountRec;
                                    objClaimLIne.CSX_CMP_Balance_Due__c = freightResponse.balanceDue;
                                    lstClaimLineToUpdate.add(objClaimLIne);
                                    if (objClaimLIne.CSX_CMP_Claim_Amount__c > freightResponse.balanceDue) {
                                        claimIdtoGoodforApprStatusMap.put(objCase, false);
                                    }
                                }
                            }
                        }
                    }
                }
                
                if (!lstClaimLineToUpdate.isempty()) {
                    Database.SaveResult[] updateResClaimLine = Database.update(lstClaimLineToUpdate, false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                        'CSX_CMP_SubmitClaimforApprovalHelper',
                        'updateLatestFreightBillInfofromSAP',
                        updateResClaimLine,
                        'objClaim Line'
                    );
                }
            }
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_ApprovalSubmissionController',
                'fetchApprovedClaims',
                String.valueOf(lstClaimIds),
                ex
            );
        }
        return claimIdtoGoodforApprStatusMap;
    }
                                                    
	public static map<string, map<Id, Boolean>> claimApprovalEvalutionForARBalance(integer nationalAccountNumber, list<Case> lstClaim) 
    {
        map<string, map<Id, Boolean>> mapOfClaimWithTHStatus = new map<string, map<Id, Boolean>>();

        try
        {
            if(nationalAccountNumber != null && lstClaim.size() != null && lstClaim.size() > 0){

                List<CSX_CMP_Notes__c> lstARBalanceNote = new List<CSX_CMP_Notes__c>();
                Set<Id> setOfIncentiveClaim = new Set<Id>();
                Set<Id> setOfOverchargeClaim = new Set<Id>();
                Map<Id,String> mapOfIncentiveClaimWithTH = new Map<Id,String>();
                Map<Id,String> mapofOverchargeClaimWithTH = new Map<Id,String>();

                //Api callout for AR Balance wrapper
                CSX_CMP_InterfaceUtility.ARBalanceResponseWrapper objARBalanceResponse = CSX_CMP_InterfaceUtility.fetchARBalanceDetails(nationalAccountNumber);
                for(Case objClaim : lstClaim){
                    if(objClaim.RecordType.developerName == 'Revenue_Overcharge'){
                        setOfOverchargeClaim.add(objClaim.Id);
                    }
                    if(objClaim.Type == 'Incentive Claim'){
                        setOfIncentiveClaim.add(objClaim.Id);
                    }
                }

                if(!setOfIncentiveClaim.isempty()){
                    mapOfIncentiveClaimWithTH = CSX_CMP_BusinessRulesUtility.runARThresholdBusinessRules(setOfIncentiveClaim,'CSX_CMP_AR_Threshold',null); 
                }

                if(!setOfOverchargeClaim.isempty()){
                    mapofOverchargeClaimWithTH = CSX_CMP_BusinessRulesUtility.runARThresholdBusinessRules(setOfOverchargeClaim,'CSX_CMP_AR_Threshold',null);
                }

                if(!lstClaim.isEmpty())
                {
                    map<Id,Boolean> mapOfIncentiveClaimWithStatus = new map<Id,Boolean>();
                    map<Id,Boolean> mapOfOverchargeClaimWithStatus = new map<Id,Boolean>();

                    for(Case objClaim : lstClaim){
                        
                        String strNoteContent = objClaim.CreatedDate +': \n';

                        //update AR balance details on objClaim
                        objClaim.CSX_CMP_Past_Due_AR__c = objARBalanceResponse.pastDueAR;
                        objClaim.CSX_CMP_Finance_Charges__c = objARBalanceResponse.financeCharges;
                        objClaim.CSX_CMP_15_days_past_Due_date_AR_Balance__c = objARBalanceResponse.pastDueDateARBalance15Days;
                        objClaim.CSX_CMP_Total_Outstanding_AR_balance__c = objARBalanceResponse.totalOutstandingARBalance;
                        
                        if(objClaim.RecordType.developerName == 'Revenue_Overcharge'){
                            String strThreshold = mapofOverchargeClaimWithTH.get(objClaim.Id);
                            if(strThreshold.contains('###')){
                                List<String> lstThreshold = strThreshold.split('###');
                                Integer intTHPercentage =  Integer.valueOf(lstThreshold[2]);
                                Decimal percentageofTotalARBalance = ((objARBalanceResponse.totalOutstandingARBalance * intTHPercentage) / 100);

                                if(objARBalanceResponse.pastDueAR <= percentageofTotalARBalance){
                                    //AR check is passed. Good to proceed with next steps for approval submission.
                                    mapOfOverchargeClaimWithStatus.put(objClaim.Id, true);
                                }else{
                                    mapOfOverchargeClaimWithStatus.put(objClaim.Id, false);
                                }     
                                strNoteContent += 'Total Outstanding AR Balance:$' + String.valueOf(objARBalanceResponse.totalOutstandingARBalance)+ '\n'+ 'Past Due Date AR Balance:$' + String.valueOf(objARBalanceResponse.pastDueAR)+ '\n';
                            }
                        }else if(objClaim.Type == 'Incentive Claim'){
                            String strThreshold = mapOfIncentiveClaimWithTH.get(objClaim.Id);
                            if(strThreshold.contains('###')){
                                List<String> lstThreshold = strThreshold.split('###');
                                Decimal decTHAmount = Decimal.valueOf(lstThreshold[1]);
                                Decimal decFinanceTHAmount = Decimal.valueOf(lstThreshold[3]);
                                
                                if(objARBalanceResponse.pastDueDateARBalance15Days < decTHAmount && objARBalanceResponse.financeCharges < decFinanceTHAmount){
                                    mapOfIncentiveClaimWithStatus.put(objClaim.Id, true);
                                }else{
                                    mapOfIncentiveClaimWithStatus.put(objClaim.Id, false);
                                }     
                                strNoteContent += '15 days Past Due AR Balance:$'+String.valueOf(objARBalanceResponse.pastDueDateARBalance15Days)+ '\n'+ 'Finance Charges:$'+String.valueOf(objARBalanceResponse.financeCharges)+ '\n';
                            }
                        }

                        //create objNote with AR balance details
                        String strOutcomeDetails;
                        if(mapOfIncentiveClaimWithStatus.get(objClaim.id) == true){
                            strOutcomeDetails = 'AR Balance now below threshold';
                        }else{
                            strOutcomeDetails = 'AR Balance still above threshold';
                        }

                        CSX_CMP_Notes__c objNote = new CSX_CMP_Notes__c();
                        objNote.CSX_CMP_Claim__c = objClaim.Id;
                        objNote.CSX_CMP_Note_Type__c = 'AR Balance';
                        objNote.CSX_CMP_Notes__c = strNoteContent + 'Outcome: '+ strOutcomeDetails;
                        lstARBalanceNote.add(objNote);
                    }
                    Database.SaveResult [] updateResults = Database.update(lstClaim,false);
                    CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_SubmitClaimforApprovalHelper', 'OnHoldClaimApprEvaluation', updateResults,'Case');

                    if(!lstARBalanceNote.isempty()){
                        Database.SaveResult [] insertResults = Database.insert(lstARBalanceNote,false); 
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_SubmitClaimforApprovalHelper', 'OnHoldClaimApprEvaluation', insertResults,'CSX_CMP_Notes__c');
                    }
                    mapOfClaimWithTHStatus.put('Incentive', mapOfIncentiveClaimWithStatus);
                    mapOfClaimWithTHStatus.put('Overcharge', mapOfOverchargeClaimWithStatus);
                }
            }
        }Catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SubmitClaimforApprovalHelper','OnHoldClaimApprEvaluation', string.valueOf(nationalAccountNumber),ex);
        }
        return mapOfClaimWithTHStatus;
    }
}