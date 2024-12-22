/**
@Author       - Infosys  
@Name         - CSX_CMP_GenerateAbstarctDistributeBatch
@Created Date - 04/08/2023
@Description  - This batch Apex is used to generate the property portal records based on parameters
@RICEFW reference - CMP-E-0441
*/
public class CSX_CMP_GeneratePropertyPortalBatch implements Database.Batchable<sObject>, Database.Stateful {
    //Variables
    public string strRecordType;
    public string strServicePeriod;
    public string strRunFor;
    public string strSpecificRR;
    public boolean isManualProcess;
    public list<CSX_CMP_Property_Portal_Staging__c> lstPropertyPortal = new List<CSX_CMP_Property_Portal_Staging__c>();
    public map<String, list<Case>> mapOfRRAlphaCodeWithClaim = new Map<String, list<Case>>();
    public List<ID> lstPortalids = new List<Id>();

    //This custructor is used to evaludate the claim and create the instance of Property Portal Record
    public CSX_CMP_GeneratePropertyPortalBatch(
        string recordType,
        string servicePeriod,
        string runFor,
        string specificRR,
        boolean isManual
    ) {
        this.strRecordType = !string.isempty(recordType) ? recordType : '';
        this.strServicePeriod = !string.isempty(servicePeriod)
            ? servicePeriod
            : CSX_CMP_Utility.calculateServicePeriod();
        this.strRunFor = !string.isempty(runFor) ? runFor : '';
        this.strSpecificRR = !string.isempty(specificRR) ? specificRR : '';
        this.isManualProcess = isManual;
        
        List<Case> lstCase = CSX_CMP_GenerateAbstractDistributionCtrl.fetchClaim(
            strRecordType,
            strServicePeriod,
            strRunFor,
            strSpecificRR
        );
        if (lstCase != null && lstCase.size() > 0) {
            bindPropertyPortalRecords(lstCase);
        }
    }
    
    public Iterable<SObject> start(Database.BatchableContext context) {
        return lstPropertyPortal;
    }
    
    public void execute(
        Database.BatchableContext context,
        List<CSX_CMP_Property_Portal_Staging__c> lstPropertyPortalStage
    ) {
        try {
            if (lstPropertyPortalStage != null && lstPropertyPortalStage.size() > 0) {
                //Upsert Property Portal Staging record based on external id
                Schema.SObjectField externalIdField = CSX_CMP_Property_Portal_Staging__c.Fields.CSX_CMP_External_ID__c;
                Database.UpsertResult[] upsertResults = Database.upsert(lstPropertyPortalStage, externalIdField, false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'CSX_CMP_GeneratePropertyPortalBatch',
                    'Execute',
                    upsertResults,
                    'CSX_CMP_Property_Portal_Staging__c'
                );

                for(Database.UpsertResult portalid : upsertResults ){
                    lstPortalids.add(portalid.getId());
                } 
            }
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_GeneratePropertyPortalBatch',
                'execute',
                String.valueOf(lstPropertyPortal),
                ex
            );
        }
    }
    
    public void finish(Database.BatchableContext context) 
    {
        //System.debug('lstPropertyPortal??? '+ lstPortalids);  
         try {
        CSX_CMP_GenerateAbstractDistributeBatch obj = new CSX_CMP_GenerateAbstractDistributeBatch(lstPortalids);
        Database.executeBatch(obj,Integer.valueof(System.Label.CSX_CMP_GeneratePropertyPortalBatchSize));
         } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog(
                'CSX_CMP_GeneratePropertyPortalBatch',
                'execute',
                String.valueOf(lstPropertyPortal),
                ex
            );
        }
    }
    
    //This methods bind the list of Property Portal Record
    public void bindPropertyPortalRecords(list<Case> lstCase) {
        if (lstCase != null && lstCase.size() > 0) {
            for (Case objCase : lstCase) {
                //Instansiate the Property Portal record for Distribution
                if (
                    !string.isempty(strRecordType) &&
                    strRecordType == 'Freight'  &&
                    !string.isempty(strRunFor) &&
                    strRunFor == 'Class 1' &&
                    !isManualProcess
                ) {
                    CSX_CMP_Property_Portal_Staging__c objPropertyPortal = new CSX_CMP_Property_Portal_Staging__c();
                    objPropertyPortal.CSX_CMP_Record_Type__c = strRecordType;
                    //objPropertyPortal.CSX_CMP_Claim_Number__c = objCase.CaseNumber;
                    objPropertyPortal.CSX_CMP_Claim_Number__c = objCase.CSX_CMP_Case_Number_Formula__c;
                    objPropertyPortal.CSX_CMP_Currency__c = system.label.CSX_CMP_Currency_Type;
                    objPropertyPortal.CSX_CMP_Document_Type__c = 'Distribution';
                    objPropertyPortal.CSX_CMP_Email_List__c = system.Label.CSX_CMP_FLDX_Emails;
                    objPropertyPortal.CSX_CMP_Count_of_Claims__c = 1;
                    objPropertyPortal.CSX_CMP_Claim__c = objCase.id;
                    objPropertyPortal.CSX_CMP_Run_For__c = strRunFor;
                    objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;
                    objPropertyPortal.CSX_CMP_Document_Created_Date__c = system.today();
                    objPropertyPortal.CSX_CMP_External_ID__c =
                        strRecordType +
                        '_' +
                        strServicePeriod +
                        '_' +
                        objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c +
                        '_' +
                        //objCase.CaseNumber;
                        objCase.CSX_CMP_Case_Number_Formula__c;
                    
                    if (isManualProcess == false) {
                        objPropertyPortal.CSX_CMP_Generated_By__c = 'Batch Job';
                        objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;
                    } else {
                        objPropertyPortal.CSX_CMP_Generated_By__c = 'Ad-hoc';
                        objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;
                    }
                    
                    objPropertyPortal.CSX_CMP_Foreign_RR_Code__c = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c;
                    objPropertyPortal.CSX_CMP_Foreign_RR_Name__c = objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c;
                    objPropertyPortal.CSX_CMP_Document_Name__c =
                        objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c +
                        '_DISTRIBUTION_STATEMENT_' +
                        strServicePeriod +
                        '_' +
                        //objCase.CaseNumber +
                        objCase.CSX_CMP_Case_Number_Formula__c +
                        '.PDF';
                    objPropertyPortal.CSX_CMP_Path__c =
                        strServicePeriod +
                        '/Dist_Stmt/' +
                        objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c +
                        '_DISTRIBUTION_STATEMENT_' +
                        strServicePeriod +
                        //objCase.CaseNumber +
                        objCase.CSX_CMP_Case_Number_Formula__c +
                        '.PDF';
                    
                    objPropertyPortal.CSX_CMP_Service_Period__c = strServicePeriod;
                    objPropertyPortal.CSX_CMP_Total_Claim_Amount__c = decimal.valueOf(string.valueOf(objCase.CSX_CMP_Claim_Amount__c).replace('-',''));
                    objPropertyPortal.CSX_CMP_VIN__c = objCase.CSX_CMP_VIN__c;
                    
                    if (
                        !string.isempty(strRecordType) &&
                        strRecordType == 'Freight' &&
                        objCase.Equipments__r != null &&
                        objCase.Equipments__r.size() > 0
                    ) {
                        objPropertyPortal.CSX_CMP_Equipment_Number__c = objCase.Equipments__r[0]
                            .CSX_CMP_Equipment_Num__c;
                        objPropertyPortal.CSX_CMP_Equipment_Initial__c = objCase.Equipments__r[0]
                            .CSX_CMP_Equipment_Initial__c;
                        objPropertyPortal.CSX_CMP_Waybill_Number__c = objCase.Equipments__r[0].CSX_CMP_Waybill_Num__c;
                        objPropertyPortal.CSX_CMP_Waybill_Date__c = objCase.Equipments__r[0].CSX_CMP_Waybill_Date__c;
                    }
                    
                    lstPropertyPortal.add(objPropertyPortal);
                }
                
                String SCAC = strRecordType == 'Freight' ? objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_SCAC__c : objCase.CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_SCAC__c;

                if (mapOfRRAlphaCodeWithClaim.get(SCAC) == null) {
                    mapOfRRAlphaCodeWithClaim.put(SCAC,new List<Case>());
                }
                mapOfRRAlphaCodeWithClaim.get(SCAC).add(objCase);
            }
            
            //Instantiate the Property Portal record for Abstract
            for (String strAlphaCode : mapOfRRAlphaCodeWithClaim.keySet()) {
                list<Case> lstClaim = mapOfRRAlphaCodeWithClaim.get(strAlphaCode);
                Integer intCount = lstClaim.size();
                Decimal decTotalAmout = 0;
                String strClaimNumber = '';
                
                for (Case objCase : lstClaim) {
                    decTotalAmout += objCase.CSX_CMP_Claim_Amount__c;
                    
                    if (String.isempty(strClaimNumber)) {
                        //strClaimNumber = objCase.CaseNumber;
                        strClaimNumber = objCase.CSX_CMP_Case_Number_Formula__c;
                    } else {
                        //strClaimNumber += ',' + objCase.CaseNumber;
                        strClaimNumber += ',' + objCase.CSX_CMP_Case_Number_Formula__c;
                    }
                }
                
                CSX_CMP_Property_Portal_Staging__c objPropertyPortal = new CSX_CMP_Property_Portal_Staging__c();
                
                if (
                    !string.isempty(strRecordType) &&
                    strRecordType == 'Freight' &&
                    !string.isempty(strRunFor) &&
                    strRunFor == 'Class 1'
                ) {
                    objPropertyPortal.CSX_CMP_Email_List__c = system.Label.CSX_CMP_FLDX_Emails;
                    objPropertyPortal.CSX_CMP_Path__c =
                        strServicePeriod +
                        '/Abstract/' +
                        strAlphaCode +
                        '_ABSTRACT_DOCUMENT_' +
                        strServicePeriod +
                        '.PDF';
                    objPropertyPortal.CSX_CMP_Foreign_RR_Code__c = lstClaim[0]
                    .CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c;
                } else {
                    objPropertyPortal.CSX_CMP_Foreign_RR_Code__c = lstClaim[0]
                    .CSX_CMP_Supplier_Claimant__r.CSX_CMP_REV_Railroad_Road_Code__c;
                }
                
                objPropertyPortal.CSX_CMP_Currency__c = system.label.CSX_CMP_Currency_Type;
                objPropertyPortal.CSX_CMP_Record_Type__c = strRecordType;
                objPropertyPortal.CSX_CMP_Claim_Number__c = strClaimNumber;
                objPropertyPortal.CSX_CMP_Document_Created_Date__c = system.today();
                objPropertyPortal.CSX_CMP_Document_Type__c = 'Abstract';
                objPropertyPortal.CSX_CMP_Count_of_Claims__c = intCount;
                objPropertyPortal.CSX_CMP_External_ID__c = strRecordType + '_' + strServicePeriod + '_' + strAlphaCode;
                objPropertyPortal.CSX_CMP_Run_For__c = strRunFor;
                objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;
                //System.debug(objPropertyPortal.CSX_CMP_External_ID__c);

                if (isManualProcess == false) {
                    objPropertyPortal.CSX_CMP_Generated_By__c = 'Batch Job';
                    objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;

                } else {
                    objPropertyPortal.CSX_CMP_Generated_By__c = 'Ad-hoc';
                    objPropertyPortal.CSX_CMP_Manual_Process__c = isManualProcess;
                }
                
                
                objPropertyPortal.CSX_CMP_Foreign_RR_Name__c = strAlphaCode;
                objPropertyPortal.CSX_CMP_Document_Name__c =
                    strAlphaCode +
                    '_ABSTRACT_DOCUMENT_' +
                    strServicePeriod +
                    '.PDF';
                objPropertyPortal.CSX_CMP_Service_Period__c = strServicePeriod;
                objPropertyPortal.CSX_CMP_Total_Claim_Amount__c = decimal.valueOf(string.valueOf(decTotalAmout).replace('-',''));
                lstPropertyPortal.add(objPropertyPortal);
            }
        }
    }
}