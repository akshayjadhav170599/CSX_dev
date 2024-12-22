/**************************************************************************************
Apex Class Name     : CSX_CMP_CreateEDI926RecordController
Function            : Class to create EDI 926 staging records to be sent to Sterling.
RICEFW #            : CMP-I-0877
Modification Log    :
* Developer         : Date             Description 
* ----------------------------------------------------------------------------                  
* Infosys           03/08/2024       First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_CreateEDI926RecordController {
    /* 
    @description : method to ceate record in EDI926ClaimReport object 
    @params : List<Id> caseIds - List of case Ids
    */
    public static void createEDI926StagingRecord(List<ID> caseIds){
        try{
            List<case> ediCases = [SELECT Id, CSX_CMP_Claim_Date__c, CaseNumber, CSX_CMP_Claimant_Ref_Num__c, CSX_CMP_Claim_Amount__c,CSX_CMP_Paid_Amount__c, Status, CSX_CMP_Decline_Code__r.Name, CSX_CMP_Currency_Code__c, CSX_CMP_Sender_ID__c, (SELECT Id FROM Equipments__r),(SELECT id,CSX_CMP_Check__c,CSX_CMP_Amount_Paid__c,CSX_CMP_Currency__c FROM AP_Settlements__r) FROM Case WHERE id IN: caseIds WITH SECURITY_ENFORCED];
            Set<id> setOfEquipmentIds = new Set<id>();
            Integer totalcustomerdamage = 0;
            List<CSX_CMP_EDI926ClaimReport__c> recordList = new List<CSX_CMP_EDI926ClaimReport__c>();
            if(!ediCases.isEmpty()){
                for(case cs : ediCases){
                    if( cs.Equipments__r.size() > 0){
                        for(CSX_CMP_Equipment__c objEquipment : cs.Equipments__r){
                            setOfEquipmentIds.add(objEquipment.id);
                        }
                    }
                }

                list<CSX_CMP_Product__c> lstProduct = [SELECT id, (SELECT Id FROM Customer_Damages__r) FROM CSX_CMP_Product__c WHERE CSX_CMP_Equipment__c IN :setOfEquipmentIds WITH SECURITY_ENFORCED];
                for(CSX_CMP_Product__c product : lstProduct){
                    if(product.Customer_Damages__r.size()>0){
                        totalcustomerdamage += product.Customer_Damages__r.size();
                    }
                } 

                for(case cs : ediCases){
                    CSX_CMP_EDI926ClaimReport__c record = new CSX_CMP_EDI926ClaimReport__c();
                    Map<String, Object> segmentOne = new Map<String, Object>();
                    Map<String, String> ctatustoCodeMap = new Map<String, String>{'New' =>'OH', 'Closed'=>'PF' , 'Declined'=>'DC', 'Cancelled' => 'CD', 'Re-Declined' => 'DC'};
                    record.CSX_CMP_Claim__c = cs.Id;
                    record.CSX_CMP_Sender_ID__c = cs.CSX_CMP_Sender_ID__c;
                    String newstatus = cs.status;
                    String statusCode = ctatustoCodeMap.containskey(newstatus)?ctatustoCodeMap.get(newstatus):'';
                    segmentOne.put('claimDate',cs.CSX_CMP_Claim_Date__c);
                    segmentOne.put('customerRefNumber',cs.CSX_CMP_Claimant_Ref_Num__c);
                    segmentOne.put('claimNum',cs.CaseNumber);
                    segmentOne.put('claimAmount',cs.CSX_CMP_Claim_Amount__c);
                    segmentOne.put('paidamount',cs.CSX_CMP_Paid_Amount__c);
                    segmentOne.put('claimStatus',statusCode);
                    segmentOne.put('createdDate',System.Today());
                    if (cs.CSX_CMP_Decline_Code__c != null) {
                        segmentOne.put('declinationCode',cs.CSX_CMP_Decline_Code__r.Name.substringBefore('-'));   
                    }
                    segmentOne.put('currencyCode',cs.CSX_CMP_Currency_Code__c);
                    record.CSX_CMP_Segment1__c = JSON.serialize(segmentOne);

                    if(cs.status == 'Declined' || cs.Status == 'Re-Declined'){
                        List<Map<String, Object>> segments = new List<Map<String, Object>>();
                        if(totalcustomerdamage > 0){
                            for(Integer i = 1; i <= totalcustomerdamage ; i++){
                                Map<String, Object> segmentSecond = new Map<String, Object>();
                                segmentSecond.put('sequenceNum',i); 
                                 if (cs.CSX_CMP_Decline_Code__c != null) {
                                segmentSecond.put('declinationCode',cs.CSX_CMP_Decline_Code__r.Name.substringBefore('-'));
                                 }
                                segments.add(segmentSecond);
                            }
                            record.CSX_CMP_Segment2__c = JSON.serialize(segments);
                        }
                    }

                    if(cs.status == 'Closed'){
                        if(!cs.AP_Settlements__r.isEmpty()){
                            Map<String, Object> segmentThird = new Map<String, Object>();
                            segmentThird.put('checkNumber',cs.AP_Settlements__r[0].CSX_CMP_Check__c);
                            segmentThird.put('createdDate',System.Today());
                            segmentThird.put('amountPaid',cs.AP_Settlements__r[0].CSX_CMP_Amount_Paid__c);
                            segmentThird.put('currencyCode',cs.AP_Settlements__r[0].CSX_CMP_Currency__c);
                            record.CSX_CMP_Segment3__c = JSON.serialize(segmentThird);
                        }
                    }

                    if(cs.status == 'New' || cs.status == 'Cancelled' || cs.status == 'Closed' || cs.status == 'Declined' || cs.status == 'Re-Declined' ){
                        Map<String, Object> segmentfourth = new Map<String, Object>();
                        segmentfourth.put('constant1','SW926');
                        segmentfourth.put('constant2','CSXT');
                        segmentfourth.put('constant3','926PO');
                        segmentfourth.put('createdDate',System.Today());
                        segmentfourth.put('constant4','GISOB926');
                        record.CSX_CMP_Segment4__c = JSON.serialize(segmentfourth);
                    }
                    recordList.add(record);      
                }
            }
            if (!recordList.isEmpty()) {
                Database.SaveResult[] ediInsertReportList = Database.insert(recordList,false); 
                CSX_CMP_LoggerUtility.addApexDMLErrorLog('CSX_CMP_CreateEDI926RecordController','createEDI926StagingRecord',ediInsertReportList,'CSX_CMP_EDI926ClaimReport__c');
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_EDIRequest','createEDI926StagingRecord',string.valueOf(caseIds),ex);
        }
    }
}