/**
@Author       - Infosys  
@Name         - CSX_CMP_SendFLREmailsBatch
@Created Date - 12/18/2023
@Description  - This batch Apex is used to send the FLR emails to the Rail Road
@RICEFW reference - CMP-E-0422
*/
public class CSX_CMP_SendFLREmailsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public integer intFinalCount = 0;
    public Map<String, String> mapofFLRKeytoEmailId = new Map<String, String>();
    public Id originFLREmailTemplateId;
    public Id destinationFLREmailTemplateId;
    public Id otherFLREmailTemplateId;
    public Id bothFLREmailTemplateId;
    public set<Id> setofClaimIds = new Set<Id>();
    
    public CSX_CMP_SendFLREmailsBatch() {
        //add logic to prepare FLR map and populate mapofFLRKeytoEmailId
        List<CSX_CMP_FLR_Email_Master__c> flrEmails = [
            SELECT Id,Name,CSX_CMP_Railroad_Code__c,CSX_CMP_Desk_Name__c,CSX_CMP_Desk_Name__r.Name,CSX_CMP_Claim_Type__c,CSX_CMP_Email__c
            FROM CSX_CMP_FLR_Email_Master__c];
        for (CSX_CMP_FLR_Email_Master__c flrEmail : flrEmails) {
            //string keyCom = flrEmail.CSX_CMP_Claim_Type__c +'#' +flrEmail.CSX_CMP_Railroad_Code__c +'#' +flrEmail.CSX_CMP_Desk_Name__r.Name;
            //17 Sept Changes | Start
            string keyCom = flrEmail.CSX_CMP_Claim_Type__c +'#' +flrEmail.CSX_CMP_Railroad_Code__c;
			if(string.isNotBlank(flrEmail.CSX_CMP_Desk_Name__r.Name)){
				keyCom += '#' +flrEmail.CSX_CMP_Desk_Name__r.Name;
			}
            //17 Sept Changes | End
            if (!mapofFLRKeytoEmailId.containsKey(keyCom)) {
                mapofFLRKeytoEmailId.put(keyCom, flrEmail.CSX_CMP_Email__c);
            } else {
                mapofFLRKeytoEmailId.put(keyCom, flrEmail.CSX_CMP_Email__c);
            }
        }
        //system.debug('mapofFLRKeytoEmailId ::'+mapofFLRKeytoEmailId);
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        CSX_CMP_Last_Execution_Log__c lastExecutionLog = CSX_CMP_Last_Execution_Log__c.getValues(
            'CMP-E-0425_FLR_Email_Batch'
        );
        Datetime dtExecutionDateTime = lastExecutionLog.CSX_CMP_Execution_Time__c;
        Datetime dtNow = System.now();
        
        String strQuery = 'SELECT Id FROM Case WHERE RecordType.Name =  \'Freight\''+ 
            ' and CreatedDate >=: dtExecutionDateTime and CreatedDate <=: dtNow' +
            ' and  CSX_CMP_FLR_Email_Sent_Date__c = ' + null;
           // +' AND CaseNumber=\'CLA000614\'';
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext context, List<Case> lstClaims) {
        //system.debug('lstClaims ::'+lstClaims);
        list<Case> lstCaseToUpdate = new List<Case>();
        // Map<String,List<String>> mapofClaimWithEmails = new Map<String,List<String>>();
        Map<String, Map<String, set<string>>> mapCaseIdsOfwithSetOfEmail = new Map<String, Map<String, set<string>>>();
        
        if (lstClaims != null && lstClaims.size() > 0) {
            for (Case objCase : lstClaims) {
                setofClaimIds.add(objCase.id);
                //System.debug('setofClaimIds++' + setofClaimIds);
            }
            //Get all the claims valid for FLR rules
            List<CSX_CMP_BusinessRulesUtility.FLRClaimWrapper> lstFLRClaimWrapper = CSX_CMP_BusinessRulesUtility.eligibleFLRClaims(
                setofClaimIds,'CSX_CMP_FLR',null,mapofFLRKeytoEmailId);
            
            //system.debug('lstFLRClaimWrapper???' + lstFLRClaimWrapper);
            //update the Questions on the Case records and email sent date
            if (lstFLRClaimWrapper != null && lstFLRClaimWrapper.size() > 0) {
                for (CSX_CMP_BusinessRulesUtility.FLRClaimWrapper objFLRWrapper : lstFLRClaimWrapper) {
                    if (objFLRWrapper.mapOfmails != null && objFLRWrapper.mapOfmails.size() > 0) {
                        case objCase = new Case(id = objFLRWrapper.strCaseID);
                        objCase.CSX_CMP_FLR_Questions__c = '';
                        
                        if (objFLRWrapper.lstQuestions != null && objFLRWrapper.lstQuestions.size() > 0) {
                            objCase.CSX_CMP_FLR_Questions__c = JSON.serialize(objFLRWrapper.lstQuestions);
                        }
                        objCase.CSX_CMP_FLR_Email_Sent_Date__c = System.today();
                        lstCaseToUpdate.add(objCase);
                        //Map of case with Emails
                        if (mapCaseIdsOfwithSetOfEmail.get(objCase.id) == null && objFLRWrapper.mapOfmails != null && objFLRWrapper.mapOfmails.size() > 0) {
                            mapCaseIdsOfwithSetOfEmail.put(objCase.id, objFLRWrapper.mapOfmails);
                        }
                    }
                }
                
                if (lstCaseToUpdate != null && lstCaseToUpdate.size() > 0) {
                    try {
                        list<Database.SaveResult> lstSaveResult = Database.update(lstCaseToUpdate);
                        
                        //Log the result
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_SendFLREmailsBatch','Execute',lstSaveResult,'Case');
                    } catch (Exception exc) {
                        //Log the Exception
                        CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SendFLREmailsBatch', 'Execute', JSON.serialize(lstClaims), exc);
                    }
                }
                
                //get OrgWideEmailAddress (From Address) - Need to uncomment for production
                /*Organization orgEnvironment = [SELECT Id,Name,OrganizationType,IsSandbox,InstanceName FROM Organization LIMIT 1];
                OrgWideEmailAddress owa;
                if(orgEnvironment != null && !orgEnvironment.IsSandbox){
                    owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName=:System.Label.CSX_CMP_FLR_Email LIMIT 1];
                }*/
                /*CSX_CMP_Environment_Settings__c environmentSetting = CSX_CMP_Environment_Settings__c.getInstance();
                OrgWideEmailAddress owa;
                if (environmentSetting != null && environmentSetting.CSX_CMP_IsProduction__c) {
                    // Production-specific logic
                    owa = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :System.Label.CSX_CMP_FLR_Email LIMIT 1];
                }*/
                //Send the FLR emails
                list<Messaging.SingleEmailMessage> lstSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
                
                for (Case objCase : lstClaims) {
                    if (mapCaseIdsOfwithSetOfEmail.get(objCase.id) != null) {
                        //Create the subject of the FLR Email for each case
                        CSX_CMP_FLREmailController objFLREmail = new CSX_CMP_FLREmailController();
                        objFLREmail.caseId = objCase.id;
                        Date objDate = objFLREmail.objCaseWrapper.waybillDate;
                        String strSubject =
                            'Foreign Line Request - ' +
                            objFLREmail.objCaseWrapper.CaseNumber +
                            ' - ' +
                            objFLREmail.objCaseWrapper.route +
                            ' (Car #: ' +
                            objFLREmail.objCaseWrapper.equipment +
                            ' - Waybill #: ' +
                            objFLREmail.objCaseWrapper.strWaybillNumber +
                            ' - Waybill Date: ' +
                            DateTime.newInstance(
                                objDate.year(),
                                objDate.month(),
                                objDate.day()
                            ).format('MM/dd/yyyy');
                            //objFLREmail.objCaseWrapper.waybillDate;
                            if (String.isNotBlank(objFLREmail.objCaseWrapper.vin)) {
                                strSubject += ' - VIN #: ' + objFLREmail.objCaseWrapper.vin + ')';
                            } else {
                                strSubject += ')';
                            }
                        Map<string, set<String>> mapOfSetSource = mapCaseIdsOfwithSetOfEmail.get(objCase.id);
                        for (String strEmail : mapOfSetSource.keySet()) {
                            for (String strSource : mapOfSetSource.get(strEmail)) {
                                if (strSource == 'Origin') {
                                    CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap = new CSX_CMP_EmailUtility.EmailRequestWrapper();
                                    emailWrap.templateDeveloperName='CSX_CMP_FLR_Origin_Email_Template';
                                    emailWrap.toEmailIdList=new String[]{strEmail};     
                                        emailWrap.sourceRecordId = objCase.Id;
                                    String subject = strSubject;
                                    emailWrap.subject = subject;
                                    //if(owa != null){
                                    //emailWrap.setOrgWideEmailAddressId = owa.Id;
                                    //}
                                    lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
                                } else if (strSource == 'Destination') {
                                    CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap= new CSX_CMP_EmailUtility.EmailRequestWrapper();
                                    emailWrap.templateDeveloperName='CSX_CMP_FLR_Destination_Email_Template';
                                    emailWrap.toEmailIdList=new String[]{strEmail};     
                                        emailWrap.sourceRecordId=objCase.Id;
                                    String subject= strSubject;
                                    emailWrap.subject=subject;
                                    //if(owa != null){
                                    //emailWrap.setOrgWideEmailAddressId = owa.Id;
                                    //}
                                    lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
                                    
                                } else if (strSource == 'Other') {
                                    CSX_CMP_EmailUtility.EmailRequestWrapper emailWrap= new CSX_CMP_EmailUtility.EmailRequestWrapper();
                                    emailWrap.templateDeveloperName='CSX_CMP_FLR_Email_Template';
                                    emailWrap.sourceRecordId=objCase.Id;
                                    emailWrap.toEmailIdList=new String[]{strEmail};     
                                        String subject= strSubject;
                                    emailWrap.subject=subject;
                                    //if(owa != null){
                                    //emailWrap.setOrgWideEmailAddressId = owa.Id;
                                    //}
                                    lstSingleEmailMessage.add(CSX_CMP_EmailUtility.sendVisualForceTemplateEmail(emailWrap));
                                }
                            }
                        }
                        intFinalCount++;
                    }
                }
                
                try {
                    list<Messaging.SendEmailResult> lstSendEmailResult = Messaging.sendEmail(lstSingleEmailMessage);
                } catch (Exception exc) {
                    CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_SendFLREmailsBatch', 'Execute', JSON.serialize(lstClaims), exc);
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        //execution log summary
        CSX_CMP_LoggerUtility.addExecutionLog('CSX_CMP_SendFLREmailsBatch', 'Send FLR Email', 'Case', intFinalCount);
        
        //update the custom setting
        CSX_CMP_Last_Execution_Log__c lastExecutionLog = CSX_CMP_Last_Execution_Log__c.getValues(
            'CMP-E-0425_FLR_Email_Batch'
        );
        lastExecutionLog.CSX_CMP_Execution_Time__c = system.now();
        
        // to upload flr emails to ECM
        List<EmailMessage> flrEmails = [
            SELECT
            Id,
            TextBody,
            HtmlBody,
            Subject,
            FromAddress,
            ToAddress,
            CcAddress,
            CreatedDate,
            ParentId
            FROM EmailMessage
            WHERE ParentId = :setofClaimIds and Subject like '%Foreign Line Request%'
        ];
        CSX_CMP_UploadEmailToECMBatch uploadEmailBatch = new CSX_CMP_UploadEmailToECMBatch(flrEmails);
        Database.executeBatch(uploadEmailBatch);
        Database.SaveResult saveResult = Database.update(lastExecutionLog);
        
        //Log the result
        CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_SendFLREmailsBatch', 'Finish', new Database.SaveResult[] {saveResult}, 'Case');
    }
}