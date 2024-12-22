/**************************************************************************************
Apex Class Name     : CSX_CMP_ClaimSearchController
Function            : This class is to fetch the Claim records as per filtered criteria.
Author              : Infosys
Modification Log    :
* Developer         : Date             Description  -> working 
* ----------------------------------------------------------------------------                 
* Infosys           1/2/2024      Second version of this class.
*************************************************************************************/
global with sharing class CSX_CMP_ClaimSearchController {
    
    @AuraEnabled(cacheable=true)
    Public static CSX_CMP_Role_Access_Configuration__mdt getClaimSearchBasedOnRole(){
        String layoutDetail;
        List<CSX_CMP_Role_Access_Configuration__mdt> roleMdt;
        try{
            User usr= [Select Id, UserRole.Name  from User where Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            if(String.isNotBlank(usr.UserRole.Name)){
                roleMdt = [
                    SELECT
                    Id,
                    MasterLabel,
                    CSX_CMP_Eligible_Claim_Type_for_Creation__c,
                    CSX_CMP_Eligible_Claim_Types_for_Search__c,
                    CSX_CMP_Search_Layout_Access__c,
                    CSX_CMP_Create_Claim__c
                    FROM CSX_CMP_Role_Access_Configuration__mdt
                    WHERE MasterLabel = :usr.UserRole.Name WITH SECURITY_ENFORCED
                ];
                //  roleMdt= CSX_CMP_Role_Access_Configuration__mdt.getInstance(usr.UserRole.DeveloperName);
            }
            // if(String.isNotblank(roleMdt.CSX_CMP_Search_Layout_Access__c)){
            //     layoutDetail=roleMdt.CSX_CMP_Search_Layout_Access__c;
            // }
        }
        catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimSearchController','getClaimSearchBasedOnRole',JSON.serialize(layoutDetail),ex);
        }
        return roleMdt[0];
    }
     
    @AuraEnabled(cacheable=true)
    global static ClaimSearchResultWrapper getClaimRecords(String claimSearchParameters){
        list<Case> finalResults = new list<Case>();
        ClaimSearchResultWrapper claimSearchResultWrapper = new ClaimSearchResultWrapper();
        List<ClaimSearchResponseWrapper> claimResponseWrapper = new List<ClaimSearchResponseWrapper>();
        list<sObject> initialQueryResults = new list<sObject>();
        list<CSX_CMP_Related_LD_Report__c> ldrQueryResults = new List<CSX_CMP_Related_LD_Report__c>();
        List<Case> legacyCases= new List<Case>();
        Set<Id> claimIds = new Set<Id>();
        List<String> filters = new List<String>();
        
        String claimQuery = 'SELECT Id,CSX_CMP_Netting_Claim_Ref_Number__c,Reason,CSX_CMP_Supplier_Claimant_Site__c,CaseNumber,CSX_CMP_Case_Number_Formula__c,Priority,Status,Type,CSX_CMP_Claim_Date__c,CSX_CMP_Claim_Amount__c,CSX_CMP_Supplier_Claimant__c,CSX_CMP_Potential_Duplicate__c,CSX_CMP_Desk_Name__c,CSX_CMP_Customer__c,CSX_CMP_Original_Amount__c,CSX_CMP_Service_Period__c,CSX_CMP_Age__c,CSX_CMP_Unread_Email__c,CSX_CMP_Claimant_Ref_Num__c,CSX_CMP_National_Account_Num__c,CSX_CMP_Contract_Num__r.Name,CSX_CMP_RR_SCAC__c FROM Case ';
        String equipmentQuery = 'Select CSX_CMP_Claim__c,CSX_CMP_Equipment_Num__c,CSX_CMP_Equipment_Initial__c from CSX_CMP_Equipment__c';
        String claimLineQuery = 'Select CSX_CMP_Claim__c,CSX_CMP_Waybill_Num__c,CSX_CMP_Waybill_Date__c,CSX_CMP_URRWIN_Num__c,CSX_CMP_Freight_Bill_Num__c,CSX_CMP_STCC__c from CSX_CMP_Claim_Line__c';
        String productQuery = 'SELECT CSX_CMP_VIN__c ,CSX_CMP_Equipment__r.CSX_CMP_Claim__c FROM CSX_CMP_Product__c';
        
        String claimReferenceKey = '';
        String claimChildReferenceKey = '';
        String initialSearchQuery='';
        string claimReferenceValue = '';
        
        String claimWhereReferenceKey = '';
        String equipmenttoClaimReferenceKey = 'CSX_CMP_Claim__r.';
        String producttoClaimReferenceKey = 'CSX_CMP_Equipment__r.CSX_CMP_Claim__r.';
        String claimlinetoClaimReferenceKey = 'CSX_CMP_Claim__r.';
        
        Map<String,String> refKeykeyMap = new Map<String,String>(); 
        refKeykeyMap.put('producttoClaimReferenceKey',producttoClaimReferenceKey);
        refKeykeyMap.put('equipmenttoClaimReferenceKey',equipmenttoClaimReferenceKey);
        refKeykeyMap.put('claimlinetoClaimReferenceKey',claimlinetoClaimReferenceKey);
        refKeykeyMap.put('claimWhereReferenceKey',claimWhereReferenceKey);
        
        Map<String,String> refKeyQueryMap = new Map<String,String>();
        refKeyQueryMap.put('producttoClaimReferenceKey',productQuery);
        refKeyQueryMap.put('equipmenttoClaimReferenceKey',equipmentQuery);
        refKeyQueryMap.put('claimlinetoClaimReferenceKey',claimLineQuery);
        refKeyQueryMap.put('claimWhereReferenceKey',claimQuery);
        
        ClaimSearchRequestWrapper wrapperObj = (ClaimSearchRequestWrapper)JSON.deserialize(claimSearchParameters,ClaimSearchRequestWrapper.class);
        try{
            //logic to prepare where clause
            if(string.isNotBlank(wrapperObj.vinNumber)){
                claimReferenceKey = 'producttoClaimReferenceKey'; //Use Product query
            }else if ( string.isNotBlank(wrapperObj.equipmentNumber) || string.isNotBlank(wrapperObj.equipmentInitial)  || string.isNotBlank(wrapperObj.waybill)  || string.isNotBlank(wrapperObj.waybillfromDate) || string.isNotBlank(wrapperObj.waybilltoDate) || string.isNotBlank(wrapperObj.urrwin) || string.isNotBlank(wrapperObj.freightBillNumber) ||  string.isNotBlank(wrapperObj.stcc) ){
                if(wrapperObj.claimGroup.contains('Freight')){
                    claimReferenceKey = 'equipmenttoClaimReferenceKey'; // Use Equipment query
                }
                else {
                    claimReferenceKey = 'claimlinetoClaimReferenceKey'; // Use Claim line query
                }
            }else{
                claimReferenceKey = 'claimWhereReferenceKey'; //claimQuery
            }
            
            if(string.isNotBlank(wrapperObj.lDRNumber)){
                String lDRNumber = wrapperObj.lDRNumber;          
              //  String relatedLDRQuery = 'SELECT CSX_CMP_Claim__c FROM CSX_CMP_Related_LD_Report__c WHERE CSX_CMP_LD_Report__r.Name = :lDRNumber';
              String relatedLDRQuery = 'SELECT CSX_CMP_Claim__c FROM CSX_CMP_Related_LD_Report__c WHERE CSX_CMP_LD_Report__r.Name LIKE \'%' + lDRNumber + '%\'';
                ldrQueryResults = Database.query(relatedLDRQuery);
                if(ldrQueryResults.size()>0){
                    for(CSX_CMP_Related_LD_Report__c rec:ldrQueryResults){
                        claimIds.add(rec.CSX_CMP_Claim__c);
                    }
                }
                else{   
                    claimIds.add(null);
                }
            }           
            if(string.isNotBlank(wrapperObj.claimNumber)){
                String caseNumber = wrapperObj.claimNumber;  
                // String caseQuery = 'SELECT Id, CaseNumber FROM Case WHERE CaseNumber LIKE \'%' + caseNumber + '%\' OR CSX_CMP_Case_Number_Formula__c LIKE \'%' + caseNumber + '%\'';
                //legacyCases = Database.query(String.escapeSingleQuotes(caseQuery));
                //legacyCases = Database.query(caseQuery);
                String caseNumberPattern = '%' + caseNumber + '%';              
                String caseQuery = 'SELECT Id, CaseNumber FROM Case WHERE CaseNumber LIKE :caseNumberPattern OR CSX_CMP_Case_Number_Formula__c LIKE :caseNumberPattern';
                legacyCases = Database.query(caseQuery);
                
             
                if(legacyCases.size()>0){
                    for(Case rec:legacyCases){
                        claimIds.add(rec.Id);
                    }
                }
                else{   
                    claimIds.add(null);
                }
            }
            
            
            if(claimReferenceKey=='producttoClaimReferenceKey'){
                claimChildReferenceKey = 'CSX_CMP_Equipment__r.';
            }else if(claimReferenceKey=='equipmenttoClaimReferenceKey' || claimReferenceKey=='claimlinetoClaimReferenceKey'){
                claimChildReferenceKey='';
            }
            
            if(!String.isBlank(claimReferenceKey)){
                claimReferenceValue = refKeykeyMap.get(claimReferenceKey);
            }       
             
            //preparing filter clauses for Claim Object.
            if(string.isNotBlank(wrapperObj.claimGroup)){
                String recordType = wrapperObj.claimGroup;
                filters.add(claimReferenceValue+'RecordType.developerName=:recordType');
            }
            if(wrapperObj.statusValues!= null && !wrapperObj.statusValues.isEmpty()){
				List<String> statusValues = new list<string>();
                 for(String key :wrapperObj.statusValues){
                    if(key!= null && String.isNotBlank(Key)){
                        statusValues.add(key);
                    }
                }
                if(!statusValues.isEmpty()){
                    filters.add(claimReferenceValue+'Status IN :statusValues');
                }
                //filters.add(claimReferenceValue+'Status IN :statusValues');
            }
          /*  if(string.isNotBlank(wrapperObj.claimNumber)){
                String claimNumber =  String.valueOf(wrapperObj.claimNumber);
                filters.add(claimReferenceValue+'CSX_CMP_Case_Number_Formula__c Like '+'\'%'+claimNumber+'%\'');
            } */
            if(string.isNotBlank(wrapperObj.claimType) ){
                String claimType = String.valueOf(wrapperObj.claimType);
                filters.add(claimReferenceValue+'Type = :claimType');
            }
            if(string.isNotBlank(wrapperObj.assignedTo)){
                User us= [Select Id,Name from User where Id =:wrapperObj.assignedTo];
                String assignedTo =  String.valueOf(us.Name);
                filters.add(claimReferenceValue+'CSX_CMP_AssignedTo__c = :assignedTo');
            }
            if(string.isNotBlank(wrapperObj.claimAmountFrom)){
                Decimal claimAmountFrom = Decimal.valueOf(wrapperObj.claimAmountFrom); 
                filters.add(claimReferenceValue+'CSX_CMP_Claim_Amount__c >= :claimAmountFrom');
            }
            if(string.isNotBlank(wrapperObj.claimAmountTo)){
                Decimal claimAmountTo =  Decimal.valueOf(wrapperObj.claimAmountTo);
                filters.add(claimReferenceValue+'CSX_CMP_Claim_Amount__c <= :claimAmountTo');
            }
            if(string.isNotBlank(wrapperObj.claimFromDate)){
                Date claimFromDate= Date.valueOf(wrapperObj.claimFromDate);
                filters.add(claimReferenceValue+'CSX_CMP_Claim_Date__c >= :claimFromDate');
            }
            if(string.isNotBlank(wrapperObj.claimToDate) ){
                Date claimToDate =  Date.valueOf(wrapperObj.claimToDate).addDays(1);
                filters.add(claimReferenceValue+'CSX_CMP_Claim_Date__c < :claimToDate');
            }
            if(string.isNotBlank(wrapperObj.supplierClaimantName )){
                String supplierClaimantName =  String.valueOf(wrapperObj.supplierClaimantName);
                filters.add(claimReferenceValue+'CSX_CMP_Supplier_Claimant__c = :supplierClaimantName');
            }
            if(string.isNotBlank(wrapperObj.deskName)){
                String deskName =  String.valueOf(wrapperObj.deskName); 
                filters.add(claimReferenceValue+'CSX_CMP_Desk_Name__c = :deskName');
            }
            if(string.isNotBlank(wrapperObj.customerName)){
                String customerName =  String.valueOf(wrapperObj.customerName);
                filters.add(claimReferenceValue+'CSX_CMP_Customer__c = :customerName');
            }
            if(string.isNotBlank(wrapperObj.ageTo)){
                Integer ageTo =  Integer.valueOf(wrapperObj.ageTo);
                filters.add(claimReferenceValue+'CSX_CMP_Age__c <= :ageTo');
            }
            if(string.isNotBlank(wrapperObj.ageFrom)){
                Integer ageFrom =  Integer.valueOf(wrapperObj.ageFrom);
                filters.add(claimReferenceValue+'CSX_CMP_Age__c >= :ageFrom');
            }
            if(string.isNotBlank(wrapperObj.claimantAmountFrom)){
                Integer claimantAmountFrom =  Integer.valueOf(wrapperObj.claimantAmountFrom);
                filters.add(claimReferenceValue+'CSX_CMP_Original_Amount__c <= :claimantAmountFrom');
            }
            if(string.isNotBlank(wrapperObj.claimantAmountTo)){
                Integer claimantAmountTo =  Integer.valueOf(wrapperObj.claimantAmountTo);
                filters.add(claimReferenceValue+'CSX_CMP_Original_Amount__c >= :claimantAmountTo');
            }
            if(string.isNotBlank(wrapperObj.servicePeriod)){
                String servicePeriod = wrapperObj.servicePeriod;
                filters.add(claimReferenceValue+'CSX_CMP_Service_Period__c = :servicePeriod');
            }
            if(string.isNotBlank(wrapperObj.claimantReferenceNumber)){
                String claimantRefererence = wrapperObj.claimantReferenceNumber;
                filters.add(claimReferenceValue+'CSX_CMP_Claimant_Ref_Num__c = :claimantRefererence');
            }
            if(string.isNotBlank(wrapperObj.claimPriority)){
                String claimPriority = wrapperObj.claimPriority;
                filters.add(claimReferenceValue+'Priority = :claimPriority');
            }
            if(string.isNotBlank(wrapperObj.nationalAccNum)){
                String nationalAccNum = wrapperObj.nationalAccNum;
                filters.add(claimReferenceValue+'CSX_CMP_National_Account_Num__c = :nationalAccNum');
                
            }
            if(string.isNotBlank(wrapperObj.contractNumber)){
                String contractNumber = wrapperObj.contractNumber;
                filters.add(claimReferenceValue+'CSX_CMP_Contract_Num__r.Name like '+'\'%'+contractNumber+'%\'');
            }															
            if(string.isNotBlank(wrapperObj.rrSCAC)){
                String rrSCAC = wrapperObj.rrSCAC;
                filters.add(claimReferenceValue+'CSX_CMP_RR_SCAC__c = :rrSCAC');
            }
            if(string.isNotBlank(wrapperObj.claimReason)){
                String claimReason = wrapperObj.claimReason;
                filters.add(claimReferenceValue+'Reason = :claimReason');
            }
            if(string.isNotBlank(wrapperObj.supplierClaimantSite)){
                String supplierClaimantSite = wrapperObj.supplierClaimantSite;
                filters.add(claimReferenceValue+'CSX_CMP_Supplier_Claimant_Site__c = :supplierClaimantSite');
            }
            if(string.isNotBlank(wrapperObj.customerSite)){
                String customerSite = wrapperObj.customerSite;
                filters.add(claimReferenceValue+'CSX_CMP_Customer__c = :customerSite');
            } 
            if(string.isNotBlank(wrapperObj.potentialDuplicate)){
                if(wrapperObj.potentialDuplicate == 'Yes'){
                    filters.add(claimReferenceValue+'CSX_CMP_Potential_Duplicate__c = TRUE');
                }else{
                    filters.add(claimReferenceValue+'CSX_CMP_Potential_Duplicate__c = FALSE');
                }
            }      
            if(string.isNotBlank(wrapperObj.unreadEmail)){
                if(wrapperObj.unreadEmail == 'Yes'){
                    filters.add(claimReferenceValue+'CSX_CMP_Unread_Email__c = TRUE');
                }else{
                    filters.add(claimReferenceValue+'CSX_CMP_Unread_Email__c = FALSE');
                }
            }      
            if(string.isNotBlank(wrapperObj.nettingClaimNumber)){
                String nettingClaimNumber = wrapperObj.nettingClaimNumber;
                filters.add(claimReferenceValue+'CSX_CMP_Netting_Claim_Ref_Number__r.CaseNumber like '+'\'%'+nettingClaimNumber+'%\'');
            }
            
            //product filters
            if(string.isNotBlank(wrapperObj.vinNumber)){
                String vinNumber;
                if(wrapperObj.vinNumber.length() == 8){
                    vinNumber = wrapperObj.vinNumber.right(8);
                }else{
                    vinNumber = wrapperObj.vinNumber;
                }
                // filters.add('CSX_CMP_Identifier__c LIKE '+'\'%'+vinNumber+'%\'');
                filters.add('CSX_CMP_VIN__c  LIKE '+'\'%'+ vinNumber+'\'');
            }
            
            //Equipment filters
            if(wrapperObj.claimGroup.contains('Freight')) {
                if(string.isNotBlank(wrapperObj.equipmentInitial)){
                    String equipmentInitial = wrapperObj.equipmentInitial;
                    filters.add(claimChildReferenceKey+'CSX_CMP_Equipment_Initial__c = :equipmentInitial');
                }
                if(string.isNotBlank(wrapperObj.equipmentNumber)){
                    String equipmentNumber = wrapperObj.equipmentNumber;
                    String leadingZeroEquipNum = String.valueOf(equipmentNumber).leftPad(6, '0');
                    filters.add(claimChildReferenceKey+'CSX_CMP_Equipment_Num__c = :leadingZeroEquipNum');
                }
            }

            //ClaimLine Fields
            if(string.isNotBlank(wrapperObj.waybill )){
                String waybill = wrapperObj.waybill;
                filters.add(claimChildReferenceKey+'CSX_CMP_Waybill_Num__c= :waybill');
            }
            if(string.isNotBlank(wrapperObj.equipmentNumber)){
                String equipmentNumber = wrapperObj.equipmentNumber;
                String leadingZero = String.valueOf(equipmentNumber).leftPad(6, '0');
                filters.add(claimChildReferenceKey+'CSX_CMP_Equipment_Num__c = :leadingZero');
            }
            if(string.isNotBlank(wrapperObj.equipmentInitial )){
                String equipmentInitial = wrapperObj.equipmentInitial;
                filters.add(claimChildReferenceKey+'CSX_CMP_Equipment_Initial__c = :equipmentInitial');
            }
            if(string.isNotBlank(wrapperObj.waybillfromDate)){
                Date waybillfromDate =  Date.valueOf(wrapperObj.waybillfromDate);
                filters.add(claimChildReferenceKey+'CSX_CMP_Waybill_Date__c <= :waybillfromDate');
            }
            if(string.isNotBlank(wrapperObj.waybilltoDate)){
                Date waybilltoDate =  Date.valueOf(wrapperObj.waybilltoDate);
                filters.add(claimChildReferenceKey+'CSX_CMP_Waybill_Date__c >= :waybilltoDate');
            }
            if(string.isNotBlank(wrapperObj.urrwin) ){
                String urrwin = wrapperObj.urrwin;
                filters.add(claimChildReferenceKey+'CSX_CMP_URRWIN_Num__c = :urrwin');
            }
            if(string.isNotBlank(wrapperObj.freightBillNumber ) ){
                String freightBillNumber = wrapperObj.freightBillNumber;
                filters.add(claimChildReferenceKey+'CSX_CMP_Freight_Bill_Num__c = :freightBillNumber');
            }
            if(string.isNotBlank(wrapperObj.stcc)){
                String stcc = wrapperObj.stcc;
                filters.add(claimChildReferenceKey+'CSX_CMP_STCC__c = :stcc');
            }
            
            initialSearchQuery = refKeyQueryMap.get(claimReferenceKey);  
            if(!claimIds.isEmpty()){
                if(filters.size() > 0){
                    initialSearchQuery += ' WHERE '+claimReferenceValue +'Id in :claimIds AND ' + String.join(filters, ' AND '); 
                    
                }else{
                    
                    if(String.isNotBlank(claimReferenceValue)){
                        initialSearchQuery +=' WHERE '+claimReferenceValue +'Id in :claimIds'; 
                    }else{
                       
                        initialSearchQuery +=' WHERE Id in :claimIds';
                        
                    }
                }
            }else{
                if(filters.size() > 0){
                    initialSearchQuery +=' WHERE ' + String.join(filters, ' AND '); 
                }else{
                    initialSearchQuery = initialSearchQuery;
                }
           }
                    
            if((filters.size() == 1 && string.isNotBlank(wrapperObj.claimGroup) && claimIds.isEmpty())){
                
                claimSearchResultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
                claimSearchResultWrapper.status ='200';
            }
            else{  
                initialQueryResults= Database.query(initialSearchQuery);
               
            }
            if(initialQueryResults.size()>0){
                for(sObject rec:initialQueryResults){
                    if(claimReferenceKey == 'producttoClaimReferenceKey'){
                        CSX_CMP_Product__c obj = (CSX_CMP_Product__c)rec;
                        claimIds.add(obj.CSX_CMP_Equipment__r.CSX_CMP_Claim__c);
                    }else if(claimReferenceKey == 'equipmenttoClaimReferenceKey'){
                        CSX_CMP_Equipment__c obj = (CSX_CMP_Equipment__c)rec;
                        claimIds.add(obj.CSX_CMP_Claim__c); 
                    }else if(claimReferenceKey == 'claimlinetoClaimReferenceKey'){
                        CSX_CMP_Claim_Line__c obj = (CSX_CMP_Claim_Line__c)rec;
                        claimIds.add(obj.CSX_CMP_Claim__c);
                    }else if(claimReferenceKey == 'claimWhereReferenceKey'){
                        Case obj = (Case)rec;
                        claimIds.add(obj.Id);
                    }
                }
                
                if(!claimIds.isEmpty()){
                    claimQuery += ' WHERE Id in:claimIds';
                    
                    finalResults= Database.query(claimQuery);
                }
                
                claimResponseWrapper=CSX_CMP_ClaimSearchController.fetchFullClaimDetails(claimIds);
            }
            else{
                    claimSearchResultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
                    claimSearchResultWrapper.status ='200';
                }
        }catch (Exception e) {
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimSearchController','getClaimRecords','',e);
            claimSearchResultWrapper.status ='400';
            claimSearchResultWrapper.errorMessage= e.getMessage();
            //throw new AuraHandledException(e.getMessage());
            //return null;
        }
        if(!claimResponseWrapper.isEmpty()){
        claimSearchResultWrapper.status ='200';
        claimSearchResultWrapper.results = claimResponseWrapper;
        }
        else{
            claimSearchResultWrapper.results = claimResponseWrapper;
           	claimSearchResultWrapper.errorMessage = system.label.CSX_CMP_Results_not_found;
           	claimSearchResultWrapper.status ='200';
        }
        return claimSearchResultWrapper;
    }
    
    public static List<ClaimSearchResponseWrapper> fetchFullClaimDetails(Set<Id> claimIds){
        
        try{
            List<Id> equipmentIds= new List<Id>();
            List<ClaimSearchResponseWrapper> claimResponseWrapper = new List<ClaimSearchResponseWrapper>();
            List<Case> caseDetails= new List<Case>([select Id,CSX_CMP_AssignedTo__c,LastModifiedDate,CSX_CMP_Original_Amount__c,CSX_CMP_Terminal__c,CSX_CMP_Supplier_Claimant_Street__c,CSX_CMP_Supplier_Claimant__c,CSX_CMP_Supplier_Claimant_Site__c,
            	CSX_CMP_Supplier_Claimant_City_State_Zip__c,
                CSX_CMP_ECM_Link__c,CSX_CMP_Contract_Num__r.Name,CSX_CMP_Supplier_Claimant_Num__c,CSX_CMP_RR_SCAC__c,CSX_CMP_National_Account_Num__c,CSX_CMP_Claim_Reason__c,Type,Status,CSX_CMP_Desk_Name__r.Name,CSX_CMP_Age__c,CSX_CMP_Supplier_Claimant__r.Name,CSX_CMP_Customer__r.Name, CSX_CMP_Customer__r.CSX_CMP_FC_Railroad_Road_Code__c, 
                CSX_CMP_Customer__c,CSX_CMP_Decline_Code__r.Name,CSX_CMP_Service_Period__c,CSX_CMP_RailRoad_Name__c,CSX_CMP_Period_Begin__c,
                                                    CSX_CMP_Period_End__c,CSX_CMP_Supplier_Claimant__r.BillingAddress,CSX_CMP_Supplier_Claimant__r.Payment_Method__c,
                                                    CSX_CMP_Netting_Claim_Ref_Number__r.CaseNumber,CSX_CMP_Netting_Claim_Ref_Number__c,
                                                    CSX_CMP_Customer_Claim_Date__c,RecordType.DeveloperName,CaseNumber,CSX_CMP_Case_Number_Formula__c,Reason,SuppliedName,CSX_CMP_Claim_Date__c,CSX_CMP_Claimant_Ref_Num__c, 
                                                    (select id,Name,CSX_CMP_URRWIN_Date__c,CSX_CMP_URRWIN_Num__c,CSX_CMP_Waybill_Controls__c,
                                                     CSX_CMP_Waybill_Date__c,CSX_CMP_Waybill_Num__c,CSX_CMP_Weight_in_Tons__c,CSX_CMP_Received_Amount__c,CSX_CMP_No_of_Cars__c,CSX_CMP_Claim_Amount__c,
                                                     CSX_CMP_STCC__c,CSX_CMP_Act_Origin_City__c,CSX_CMP_Act_Origin_State__c,
                                                     CSX_CMP_Act_Destination_City__c,CSX_CMP_Act_Destination_State__c,
                                                     CSX_CMP_STCC_Description__c,CSX_CMP_Equipment_Initial__c,  
                                                     CSX_CMP_Equipment_Num__c,CSX_CMP_Unit_Refund_Price__c from ClaimLines__r limit 1), 
                                                    CSX_CMP_Claim_Amount__c,(select Id,Name,lastmodifiedDate,CSX_CMP_Waybill_Num__c,CSX_CMP_STCC__c,
                                                                             CSX_CMP_Act_Origin_City__c,CSX_CMP_Act_Origin_State__c,
                                                                             CSX_CMP_Act_Destination_City__c,CSX_CMP_Act_Destination_State__c,
                                                                             CSX_CMP_LD_Report__r.Name,CSX_CMP_Equipment_Initial__c,CSX_CMP_Shipper__c,
                                                                             CSX_CMP_Consignee__c,
                                                                             CSX_CMP_Equipment_Num__c,
                                                                             CSX_CMP_Waybill_Date__c,CSX_CMP_Equipment_Summary_Report__c from Equipments__r Limit 1),
                                                    (select CSX_CMP_Note_Type__c,CSX_CMP_Notes__c,Name from Notes__r 
                                                     where CSX_CMP_Note_Type__c IN ('CSX Explanation','Work Note')),
                                                    (select Name,CSX_CMP_LD_Report__c,CSX_CMP_LD_Report__r.Name,CSX_CMP_Decline_code__c from Related_L_D_Reports__r limit 10),(select CSX_CMP_Telephone__c,CSX_CMP_Emails__c,Name from Claim_Contacts__r Limit 1),
                                                    (select Id,Name,CSX_CMP_Payment_Address__c,CSX_CMP_Claim__r.Status,CSX_CMP_Claim__c,CSX_CMP_Claim__r.CaseNumber,CSX_CMP_Amount_Paid__c,CSX_CMP_Check__c,CSX_CMP_Check_Date__c,CSX_CMP_Check_Amount__c,
                                                    CSX_CMP_Claim__r.CSX_CMP_Payment_Method__c,
                                                     CSX_CMP_Bank_Account_Number__c,CSX_CMP_Invoice_Payment_Status__c from AP_Settlements__r where CSX_CMP_Claim__r.Status='Closed'),
                                                    (select Id,Name,CSX_CMP_Payment_Address__c,CSX_CMP_Claim__r.Status,CSX_CMP_Claim__c,CSX_CMP_Claim__r.CaseNumber,CSX_CMP_Amount_Paid__c,CSX_CMP_Invoice_Number__c,CSX_CMP_Invoice_Date__c,CSX_CMP_Invoice_Amount__c,CSX_CMP_Invoice_Payment_Status__c,
                                                     CSX_CMP_Bank_Account_Number__c from AR_Settlement__r where CSX_CMP_Claim__r.Status='Closed')
                                                    from Case where id =:claimIds]);
            for(Case cs:caseDetails){
                ClaimSearchResponseWrapper claimWrapper= new ClaimSearchResponseWrapper();
                
                if(String.isNotBlank(cs.CSX_CMP_Service_Period__c)) {
                    claimWrapper.servicePeriod=cs.CSX_CMP_Service_Period__c;
                }
                if(String.isNotBlank(cs.CSX_CMP_ECM_Link__c)) {
                    claimWrapper.ecmLink=cs.CSX_CMP_ECM_Link__c;
                }
                
                if(String.isNotBlank(cs.CSX_CMP_National_Account_Num__c)) {
                    claimWrapper.nationalAccountNumber=cs.CSX_CMP_National_Account_Num__c;
                }
                if(String.isNotBlank(cs.CSX_CMP_AssignedTo__c)) {
                    claimWrapper.assignedTo=cs.CSX_CMP_AssignedTo__c;
                }
                
                if(String.isNotBlank(cs.CaseNumber)) {
                    claimWrapper.claimNumber=cs.CaseNumber;
                }
                
                if(String.isNotBlank(cs.CSX_CMP_RR_SCAC__c)) {
                    claimWrapper.rrSCAC=cs.CSX_CMP_RR_SCAC__c;
                }
                if(String.isNotBlank(cs.CSX_CMP_Customer__r.Name)) {
                    claimWrapper.customerName=cs.CSX_CMP_Customer__r.Name;
                }
                if(String.isNotBlank(cs.CSX_CMP_Supplier_Claimant_City_State_Zip__c)) {
                    claimWrapper.supplierClaimantCity=cs.CSX_CMP_Supplier_Claimant_City_State_Zip__c;
                }
                if(String.isNotBlank(cs.CSX_CMP_Supplier_Claimant_Street__c)) {
                    claimWrapper.supplierClaimantStreet=cs.CSX_CMP_Supplier_Claimant_Street__c;
                }                
                if(String.isNotBlank(cs.Reason)) {
                    claimWrapper.claimReason=cs.Reason;
                }
                if(String.isNotBlank(cs.CSX_CMP_Supplier_Claimant_Site__c)) {
                    claimWrapper.supplierClaimantSite=cs.CSX_CMP_Supplier_Claimant_Site__c;
                }
                if(String.isNotBlank(cs.Id)) {
                    claimWrapper.caseId=cs.Id;
                }
                
                if(String.isNotBlank(cs.CSX_CMP_Contract_Num__r.Name)) {
                    claimWrapper.contractNumber=cs.CSX_CMP_Contract_Num__r.Name;
                } 
                
                if(String.isNotBlank(cs.CSX_CMP_Claimant_Ref_Num__c)) {
                    claimWrapper.claimantReferenceNumber=cs.CSX_CMP_Claimant_Ref_Num__c;
                }           
                if(cs.CSX_CMP_Claim_Date__c!=null) {
                    claimWrapper.claimDate=cs.CSX_CMP_Claim_Date__c;
                }
                if(String.isNotBlank(cs.CSX_CMP_Desk_Name__r.Name)) {
                    claimWrapper.deskName=cs.CSX_CMP_Desk_Name__r.Name;
                }
                if(cs.CSX_CMP_Age__c!=null) {
                    claimWrapper.claimAge=cs.CSX_CMP_Age__c;
                }
                if(cs.CSX_CMP_Claim_Amount__c!=null) {
                    Decimal claimAmountRound=cs.CSX_CMP_Claim_Amount__c.setScale(2);
                    claimWrapper.claimAmount=claimAmountRound;
                }
                if(String.isNotBlank(cs.Type)) {
                    claimWrapper.claimType=cs.Type;
                }
                if(String.isNotBlank(cs.CSX_CMP_Netting_Claim_Ref_Number__r.caseNumber)){
                    claimWrapper.claimNettingClaimNum=cs.CSX_CMP_Netting_Claim_Ref_Number__r.caseNumber;
                }

                if(String.isNotBlank(cs.CSX_CMP_Netting_Claim_Ref_Number__c)){
                    claimWrapper.claimNettingClaim=cs.CSX_CMP_Netting_Claim_Ref_Number__c;
                }

                if(String.isNotBlank(cs.Status)) {
                    claimWrapper.claimStatus=cs.Status;
                }

                if(String.isNotBlank(cs.CSX_CMP_Decline_Code__r.Name)) {
                    claimWrapper.declineCode=cs.CSX_CMP_Decline_Code__r.Name;
                }

                if(String.isNotBlank(cs.CSX_CMP_Supplier_Claimant__r.Name)) {
                    claimWrapper.supplierClaimantName=cs.CSX_CMP_Supplier_Claimant__r.Name;
                }
                if(cs.CSX_CMP_Period_End__c != null) {
                    claimWrapper.periodEnd=cs.CSX_CMP_Period_End__c;
                }
                if(cs.CSX_CMP_Period_Begin__c != null) {
                    claimWrapper.periodBegin=cs.CSX_CMP_Period_Begin__c;
                }
                if(cs.CSX_CMP_Customer_Claim_Date__c != null) {
                    claimWrapper.customerClaimDate=cs.CSX_CMP_Customer_Claim_Date__c;
                }
                if(cs.LastModifiedDate != null) {
                    Datetime dt = (Datetime) cs.LastModifiedDate;
                    claimWrapper.lastModifiedDate = dt.date();
                }
                if(cs.CSX_CMP_Original_Amount__c != null) {
                    claimWrapper.originalAmount=cs.CSX_CMP_Original_Amount__c;
                }
                if(string.isNotBlank(cs.CSX_CMP_Terminal__c)) {
                    claimWrapper.terminal=cs.CSX_CMP_Terminal__c;
                }
                if(string.isNotBlank(cs.CSX_CMP_Customer__r.CSX_CMP_FC_Railroad_Road_Code__c)) {
                    claimWrapper.rrCode=cs.CSX_CMP_Customer__r.CSX_CMP_FC_Railroad_Road_Code__c;
                }
                if(cs.Notes__r!=null && !cs.Notes__r.isEmpty()){
                    List<CSX_CMP_Notes__c> note=cs.Notes__r;
                    
                    for(CSX_CMP_Notes__c nt:note) {
                        if(nt.CSX_CMP_Note_Type__c == 'CSX Explanation') {
                            claimWrapper.csxExplanationRevContract=nt.CSX_CMP_Notes__c;
                            claimWrapper.csxExplanation=nt.CSX_CMP_Notes__c;
                        }
                        if(nt.CSX_CMP_Note_Type__c == 'Work Note') {
                            claimWrapper.workNote = nt.CSX_CMP_Notes__c;
                        }
                    }
                }
                
                if(cs.Claim_Contacts__r!=null && !cs.Claim_Contacts__r.isEmpty()){
                   
                    CSX_CMP_Claim_Contact__c claimContact = cs.Claim_Contacts__r;
                    
                    if(String.isNotBlank(claimContact.Name)){
                        claimWrapper.nameClaimContact=claimContact.Name;
                    }

                    if(String.isNotBlank(claimContact.CSX_CMP_Telephone__c)){
                        claimWrapper.telephoneClaimContact=claimContact.CSX_CMP_Telephone__c;
                    }

                    if(String.isNotBlank(claimContact.CSX_CMP_Emails__c)){
                        claimWrapper.emailClaimContact=claimContact.CSX_CMP_Emails__c;
                    }
                }
               
                if(cs.AP_Settlements__r!=null && !cs.AP_Settlements__r.isEmpty()){
                    List<PaymentWrapper> apSettlementsWrapper = new List<PaymentWrapper>();       
                    List<CSX_CMP_AP_Settlement__c> apSettlement=new List<CSX_CMP_AP_Settlement__c>();
                    apSettlement.addAll(cs.AP_Settlements__r);
                    for(CSX_CMP_AP_Settlement__c aPs:cs.AP_Settlements__r){
                       PaymentWrapper payWrapper= new PaymentWrapper();                   
                        payWrapper.claimID=aPs.CSX_CMP_Claim__r.CaseNumber; 
                        payWrapper.claimURL=aPs.CSX_CMP_Claim__c;
                        payWrapper.amountPaid=aPs.CSX_CMP_Amount_Paid__c;
                        payWrapper.paymentID=aPs.Name;
                        payWrapper.paymentURL=aPs.Id;
                        payWrapper.checkNumber=aPs.CSX_CMP_Check__c;
                        payWrapper.checkDate=aPs.CSX_CMP_Check_Date__c;
                        payWrapper.checkAmount=aPs.CSX_CMP_Check_Amount__c;
                        payWrapper.paymentMethod=aPs.CSX_CMP_Claim__r.CSX_CMP_Payment_Method__c;
                        payWrapper.paymentAddress=aPs.CSX_CMP_Payment_Address__c;
                        payWrapper.paymentStatus=aPs.CSX_CMP_Invoice_Payment_Status__c;
                        payWrapper.bankAccount=aPs.CSX_CMP_Bank_Account_Number__c;
                        apSettlementsWrapper.add(payWrapper);
                    }
                    claimWrapper.aPSettlements=apSettlementsWrapper;
                } 

                if(cs.AR_Settlement__r!=null && !cs.AR_Settlement__r.isEmpty()){
                    
                    List<CSX_CMP_AR_Settlement__c> arList= new List<CSX_CMP_AR_Settlement__c>();
                    List<GetInvoiceWrapper> invoiceWrapperWrapperList= new List<GetInvoiceWrapper>();
                    arList.addAll(cs.AR_Settlement__r);
                    
                    for(CSX_CMP_AR_Settlement__c aRs:cs.AR_Settlement__r){
                         GetInvoiceWrapper invoiceWrapperValues=new GetInvoiceWrapper();
                        invoiceWrapperValues.claimID=aRs.CSX_CMP_Claim__r.CaseNumber; 
                        invoiceWrapperValues.claimURL=aRs.CSX_CMP_Claim__c;
                        invoiceWrapperValues.amountPaid=aRs.CSX_CMP_Amount_Paid__c;
                        invoiceWrapperValues.invoiceID=aRs.Name;
                        invoiceWrapperValues.invoiceURL=aRs.Id;
                        invoiceWrapperValues.invoiceNumber=aRs.CSX_CMP_Invoice_Number__c;
                        invoiceWrapperValues.invoiceDate=aRs.CSX_CMP_Invoice_Date__c;
                        invoiceWrapperValues.invoiceAmount=aRs.CSX_CMP_Invoice_Amount__c;
                        invoiceWrapperValues.invoicePaymentStatus=aRs.CSX_CMP_Invoice_Payment_Status__c;
                        invoiceWrapperValues.paymentAddress=aRs.CSX_CMP_Payment_Address__c;
                        invoiceWrapperValues.bankAccount=aRs.CSX_CMP_Bank_Account_Number__c;
                        invoiceWrapperWrapperList.add(invoiceWrapperValues);
                    }
                    claimWrapper.aRSettlements=invoiceWrapperWrapperList;
                } 
                
                if(cs.Related_L_D_Reports__r!=null && !cs.Related_L_D_Reports__r.isEmpty()){
                    
                    List<CSX_CMP_Related_LD_Report__c> ldr=cs.Related_L_D_Reports__r;
                    
                    for(CSX_CMP_Related_LD_Report__c ldrRecords:cs.Related_L_D_Reports__r)  { 
                    	
                        if(String.isNotBlank(ldrRecords.CSX_CMP_LD_Report__r.Name)){
                            if(String.isNotBlank(claimWrapper.ldReportNumbers)){                    
                                claimWrapper.ldReportNumbers+=', '+ldrRecords.CSX_CMP_LD_Report__r.Name;      
                            }
                            else{
                                claimWrapper.ldReportNumbers=ldrRecords.CSX_CMP_LD_Report__r.Name;
                            }
                           
                        }
                    }
                }
                
                if(cs.Equipments__r!=null && !cs.Equipments__r.isEmpty()){
                    
                    List<CSX_CMP_Equipment__c> equipments=cs.Equipments__r;
                    List<String> equipmentIdList= new List<String>();
                    for(CSX_CMP_Equipment__c equ:cs.Equipments__r)  {  
                        equipmentIdList.add(equ.Id);  
                        equipmentIds.add(equ.Id);
                        
                        if(String.isNotBlank(equ.CSX_CMP_Act_Origin_City__c)){
                            claimWrapper.equipmentOriginCity=equ.CSX_CMP_Act_Origin_City__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Act_Origin_State__c)){
                            claimWrapper.equipmentOriginState=equ.CSX_CMP_Act_Origin_State__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Act_Destination_City__c)){
                            claimWrapper.equipmentDestCity=equ.CSX_CMP_Act_Destination_City__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Act_Destination_State__c)){
                            claimWrapper.equipmentDestState=equ.CSX_CMP_Act_Destination_State__c;
                        }
                        if(String.isNotBlank(equ.Name)){
                            claimWrapper.equipmentID=equ.Name; 
                        }
                        if(!(String.isNotBlank(equ.Name))){
                            claimWrapper.equipmentID='NA';
                        }
                        
                        if(String.isNotBlank(equ.CSX_CMP_Waybill_Num__c)){
                            claimWrapper.equipmentWaybillNumber=equ.CSX_CMP_Waybill_Num__c;
                        }
                        
                        if(equ.CSX_CMP_Waybill_Date__c!=null){
                            claimWrapper.equipmentWaybillDate=equ.CSX_CMP_Waybill_Date__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_STCC__c)){
                            claimWrapper.equipmentSTCCCode=equ.CSX_CMP_STCC__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Shipper__c)){
                            claimWrapper.equipmentShipper=equ.CSX_CMP_Shipper__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Consignee__c)){
                            claimWrapper.equipmentConsignee=equ.CSX_CMP_Consignee__c;
                        }
                        if(String.isNotBlank(equ.CSX_CMP_Consignee__c)){
                            claimWrapper.equipmentConsignee=equ.CSX_CMP_Consignee__c;
                        }
                    }
                    claimWrapper.equipmentIDs=equipmentIdList;
                }
                claimResponseWrapper.add(claimWrapper);
            }         
            
            Map<String,List< String>> productMap = new Map<String,List<String>>();
        if(equipmentIds!=null && !equipmentIds.isEmpty()){
            for(CSX_CMP_Product__c product:[select Id,CSX_CMP_Equipment__c,CSX_CMP_Product_Description__c,CSX_CMP_VIN__c  from CSX_CMP_Product__c where CSX_CMP_Equipment__c= :equipmentIds WITH SECURITY_ENFORCED]){
                List<String> vinList = new List<String>();
                if(productMap.containsKey(product.CSX_CMP_Equipment__c)){
                    if(product.CSX_CMP_VIN__c != null){
                        productMap.get(product.CSX_CMP_Equipment__c).add(product.CSX_CMP_VIN__c );
                    }
                    if(product.CSX_CMP_Product_Description__c != null){
                        productMap.get(product.CSX_CMP_Equipment__c).add(product.CSX_CMP_Product_Description__c);
                    }
                } else {
                    if(product.CSX_CMP_VIN__c != null){
                        vinList.add(product.CSX_CMP_VIN__c );
                        productMap.put(product.CSX_CMP_Equipment__c,vinList);
                    }
                    if(product.CSX_CMP_Product_Description__c != null){
                        vinList.add(product.CSX_CMP_Product_Description__c);
                        productMap.put(product.CSX_CMP_Equipment__c,vinList);
                    }
                }
            }
        }
            for(ClaimSearchResponseWrapper claimWrapper :claimResponseWrapper){
                if(claimWrapper.equipmentIDs != null && claimWrapper.equipmentIDs.size()>0){
                    for(String equipmentId: claimWrapper.equipmentIDs){
                        
                        if(productMap.containsKey(equipmentId)){
                            for(String vIN : productMap.get(equipmentId)){
                                if(String.isNotBlank(claimWrapper.productVinNumber)){                    
                                    claimWrapper.productVinNumber+=', '+vIN;      
                                }
                                else{
                                    claimWrapper.productVinNumber=vIN;
                                }
                            }
                        }
                    }   
                }
            } 
            return claimResponseWrapper;
        }
        catch(Exception e){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_ClaimSearchController','fetchFullClaimDetails','Search',e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    global class ClaimSearchResultWrapper{
        @AuraEnabled
        public string status;
        @AuraEnabled
        public string errorMessage;
        @AuraEnabled
        public list<ClaimSearchResponseWrapper> results;
    }
    
    global class ClaimSearchResponseWrapper{
        @AuraEnabled
        public List<PaymentWrapper> aPSettlements;
        @AuraEnabled
        public List<GetInvoiceWrapper> aRSettlements; 
        @AuraEnabled
        public String claimNumber{get;set;}         
        @AuraEnabled
        public String supplierClaimantCity{get;set;}    
        @AuraEnabled
        public String supplierClaimantStreet{get;set;}
        @AuraEnabled
        public String ecmLink{get;set;}    
        @AuraEnabled
        public String contractNumber{get;set;}
        @AuraEnabled
        public String claimantReferenceNumber{get;set;}      
        @AuraEnabled
        public String csxExplanation{get;set;}
        @AuraEnabled
        public String csxExplanationRevContract{get;set;}
        @AuraEnabled
        public String workNote{get;set;}
        @AuraEnabled
        public String assignedTo{get;set;}
        @AuraEnabled
        public String claimReason{get;set;}
        @AuraEnabled
        public String nationalAccountNumber{get;set;}
        @AuraEnabled
        public String productVinNumber{get;set;}
        @AuraEnabled
        public List<String> equipmentIDs{get;set;}    
        @AuraEnabled
        public String customerName{get;set;}       
        @AuraEnabled
        public String supplierClaimantName{get;set;}       
        @AuraEnabled
        public String deskName{get;set;}   
        @AuraEnabled
        public decimal claimAge{get;set;}
        @AuraEnabled
        public decimal claimAmount{get;set;}
        @AuraEnabled
        public String claimType{get;set;}
        @AuraEnabled
        public String declineCode{get;set;}       
        @AuraEnabled
        public String ldReportNumbers{get;set;}       
        @AuraEnabled
        public String equipmentOriginCity{get;set;}
        @AuraEnabled
        public String equipmentOriginState{get;set;}
        @AuraEnabled
        public String equipmentDestCity{get;set;}
        @AuraEnabled
        public String equipmentDestState{get;set;}
        @AuraEnabled
        public String equipmentID{get;set;}       
        @AuraEnabled
        public String equipmentWaybillNumber{get;set;}      
        @AuraEnabled
        public Date equipmentWaybillDate{get;set;}       
        @AuraEnabled
        public String equipmentSTCCCode{get;set;}        
        @AuraEnabled
        public String equipmentShipper{get;set;}         
        @AuraEnabled
        public String equipmentConsignee{get;set;}       
        @AuraEnabled
        public String claimNettingClaimNum{get;set;} 
        @AuraEnabled
        public String claimNettingClaim{get;set;}
        @AuraEnabled
        public String caseId{get;set;}        
        @AuraEnabled
        public Date claimDate{get;set;}
        @AuraEnabled
        public String claimStatus{get;set;}
        @AuraEnabled
        public String servicePeriod{get;set;}
        @AuraEnabled
        public string supplierClaimantSite{get;set;}        
        @AuraEnabled
        public string rrSCAC{get;set;}              
        @AuraEnabled
        public Date periodBegin{get;set;}
        @AuraEnabled
        public Date periodEnd{get;set;}
        @AuraEnabled
        public Date customerClaimDate{get;set;}
        @AuraEnabled
        public Decimal originalAmount{get;set;}
        @AuraEnabled
        public string terminal{get;set;}
        @AuraEnabled
        public Date lastModifiedDate{get;set;}
        @AuraEnabled
        public String rrCode{get;set;}
        @AuraEnabled
        public String nameClaimContact{get;set;}
        @AuraEnabled
        public String emailClaimContact{get;set;}
        @AuraEnabled
        public String telephoneClaimContact{get;set;}
              
    }
    
    public class ClaimSearchRequestWrapper{
        public String claimGroup{get;set;}     
        public String claimNumber{get;set;}
        public String claimType{get;set;}  
        public String ageFrom{get;set;}
        public String ageTo{get;set;}
        public String claimAmountFrom{get;set;}
        public String claimAmountTo{get;set;}
        public string claimantAmountFrom{get;set;}        
        public string claimantAmountTo{get;set;}        
        public String claimFromDate{get;set;}
        public String claimToDate{get;set;}
        public String assignedTo{get;set;}
        public String supplierClaimantName{get;set;}       
        public string supplierClaimantSite{get;set;}       
        public String customerName{get;set;}
        public string customerSite{get;set;}    
        public String deskName{get;set;}   
        public String equipmentInitial{get;set;}
        public String equipmentNumber{get;set;}
        public String vinNumber{get;set;}
        public String unreadEmail{get;set;}
        public String nettingClaimNumber{get;set;}
        public String servicePeriod{get;set;}
        public String lDRNumber{get;set;}        
        public String claimPriority{get;set;}
        public String potentialDuplicate{get;set;}
        public List<String> statusValues{get;set;}
        public String nationalAccNum{get;set;}
        public String contractNumber{get;set;}      
        public string rrSCAC{get;set;}                      
        public string claimReason{get;set;}         
        public string waybill{get;set;}
        public string waybillfromDate{get;set;}
        public string waybilltoDate{get;set;}
        public string urrwin{get;set;}
        public string freightBillNumber{get;set;}         
        public string stcc{get;set;} 
        public string claimantReferenceNumber{get;set;}        
    }

    public class PaymentWrapper{
        @AuraEnabled
        public String paymentID {get;set;}     
        @AuraEnabled
        public String paymentURL {get;set;}
        @AuraEnabled
        public decimal amountPaid {get;set;}   
        @AuraEnabled
        public String claimID {get;set;}        
        @AuraEnabled
        public String claimURL {get;set;}
        @AuraEnabled
        public String checkNumber {get;set;}
        @AuraEnabled
        public date checkDate {get;set;}
        @AuraEnabled
        public decimal checkAmount {get;set;}
        @AuraEnabled
        public String paymentMethod {get;set;}
        @AuraEnabled
        public String paymentAddress {get;set;}
        @AuraEnabled
        public String paymentStatus {get;set;}
        @AuraEnabled
        public string bankAccount {get;set;}
        
    }
    
    public class GetInvoiceWrapper {
        @AuraEnabled
        public String invoiceID {get;set;}  
        @AuraEnabled
        public String invoiceURL {get;set;}     
        @AuraEnabled
        public decimal amountPaid {get;set;}       
        @AuraEnabled
        public String claimID {get;set;}       
        @AuraEnabled
        public String claimURL {get;set;}
        @AuraEnabled
        public String invoiceNumber {get;set;}
        @AuraEnabled
        public date invoiceDate {get;set;}
        @AuraEnabled
        public decimal invoiceAmount {get;set;}
        @AuraEnabled
        public String invoicePaymentStatus {get;set;}
        @AuraEnabled
        public String paymentAddress {get;set;}
        @AuraEnabled
        public string bankAccount {get;set;}
    }
}