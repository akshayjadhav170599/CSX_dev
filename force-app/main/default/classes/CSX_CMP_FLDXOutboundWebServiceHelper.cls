/**************************************************************************************
Apex Class Name     : CSX_CMP_FLDXOutboundWebservice
Function            : webservice class to prepare data for FLDX outbound file to be consumed by sterling to create final FLDX file.
RICEFW #            : CMP-I-0461
Modification Log    :
* Developer         : Date :03/27/2023       Description 
* ----------------------------------------------------------------------------                  
* @author         : Infosys                  First version of this class.
*************************************************************************************/
public with sharing class CSX_CMP_FLDXOutboundWebServiceHelper {

    public static CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper getFLDXOutboundWebServiceData(String servicePeriod){
        CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper objClaimWrap = new CSX_CMP_FLDXOutboundWebService.FLDXResponseWrapper();
        objClaimWrap.servicePeriod = '';
        objClaimWrap.createdDate = '';
        try{
            
            List<FLDXInitialWrapper> lstFLDX = new List<FLDXInitialWrapper>();
            Map<String,String> identifierMap = new Map<String,String>();
            Map<String,Boolean> flagMap = new Map<String,Boolean>();
            Set<Id> setOfEquipmentIds = new Set<Id>();
            Map<Id,CSX_CMP_Equipment__c> mapOfEquipmentIdtoDetails = new Map<Id, CSX_CMP_Equipment__c>();

            //get service period of previous month
            string formattedMonth = '';
            Date currentDate = Date.Today();
            Integer currentMonth = currentDate.month();
            Integer prevMonth = currentDate.month() - 1;
            Integer prevYear = currentDate.year();
            if(prevMonth == 0){
                prevMonth = 12;
                prevYear -= 1;
            }
            //servicePeriod = 'PER-'+prevMonth+'-'+string.valueOf(prevYear).substring(2,4);
            
            
            if(currentMonth < 10){
                formattedMonth = '0'+string.valueOf(currentMonth);
            }else{
                formattedMonth = string.valueOf(currentMonth);
            }

            for(Integer i=3;i<=6;i++){
                identifierMap.put('identifier'+i+'String','');
                flagMap.put('flag'+i,false);
            }

            //query to fetch outbound frieght claims
            List<Case> claimList = [SELECT Id,CaseNumber,CreatedDate,Type,CSX_CMP_Service_Period__c,CSX_CMP_Paid_Amount__c,CSX_CMP_Claim_Amount__c,CSX_CMP_Claimant_Ref_Num__c,CSX_CMP_Salvage_Amount__c,CSX_CMP_Remarks__c,CSX_CMP_Salvage_Code__c,CSX_CMP_RailRoad_Name__c, CSX_CMP_Supplier_Claimant__c, CSX_CMP_RailRoad_Claim_Ref_Num__c, CSX_CMP_Supplier_Claimant__r.CSX_CMP_FC_Railroad_Road_Code__c, 
                                    CSX_CMP_FCD_Rule_Code__c,CSX_CMP_Claim_Date__c,CSX_CMP_Currency_Code__c, Origin,CSX_CMP_FCD_Cause_Code__c,CSX_CMP_Case_Number_Formula__c,
                                    (SELECT Id,CSX_CMP_Supplier_Claimant_Type__c, CSX_CMP_STCC__c, CSX_CMP_Shipper__c, CSX_CMP_Consignee__c, CSX_CMP_Act_Origin_Road__c, CSX_CMP_Act_Destination_Road__c, CSX_CMP_PPN__c,
                                     CSX_CMP_Multi_Car_Count__c, CSX_CMP_Act_Origin_City__c, CSX_CMP_Act_Origin_State__c, CSX_CMP_Act_Destination_State__c, CSX_CMP_Act_Destination_City__c,CSX_CMP_Equipment_Num__c,
                                     CSX_CMP_Waybill_Date__c, CSX_CMP_Waybill_Num__c, CSX_CMP_Origin_Audit_Num__c,CSX_CMP_Origin_Road_Num__c,CSX_CMP_Destination_Road_Num__c, CSX_CMP_Destination_Audit__c, CSX_CMP_Equipment_Initial__c,CSX_CMP_Claim__r.CaseNumber,CSX_CMP_Claim__r.CSX_CMP_Case_Number_Formula__c From Equipments__r)
                                    From Case WHERE CSX_CMP_Service_Period__c =: servicePeriod AND Type IN ('FC RR Outbound Claim','Recharges Outbound Claim') AND Status NOT IN ('Cancelled','Declined','Re-Declined') WITH SECURITY_ENFORCED];//AND CaseNumber='CLA002144' 
            if(!claimList.isEmpty()){
                for(Case objCase: claimList){
                    if(!objCase.Equipments__r.isempty()){
                        for(CSX_CMP_Equipment__c objEquipment : objCase.Equipments__r){
                            setOfEquipmentIds.add(objEquipment.Id);   
                        }
                    }    
                }

                if(setOfEquipmentIds.size() > 0){
                    for(CSX_CMP_Equipment__c equip :[SELECT Id, (SELECT Id, CSX_CMP_Road__c,CSX_CMP_Junction__c,CSX_CMP_Code__c,CSX_CMP_Miles__c, CSX_CMP_Equipment__c,CSX_CMP_Manual_Adj_Amt__c,CSX_CMP_Distribution_Claim__c FROM Distributions__r), 
                                                     (SELECT Id, CSX_CMP_VIN__c FROM Products__r) FROM CSX_CMP_Equipment__c where Id in :setOfEquipmentIds WITH SECURITY_ENFORCED]){
                        mapOfEquipmentIdtoDetails.put(equip.Id, equip);
                    }
                }

                for(Case objCase: claimList){

                    FLDXInitialWrapper objFldx = new FLDXInitialWrapper();
                    Identifier1Wrapper objIdentifier1 = new Identifier1Wrapper();
                    Identifier2Wrapper objIdentifier2 = new Identifier2Wrapper();
                    
                    string foreignCurr = '';
                    string[] splitRemark;
                    string remark1 = '';
                    string remark2 = '';                    
                    
                    objClaimWrap.servicePeriod = servicePeriod != null ? servicePeriod : '';
                    objClaimWrap.createdDate = objCase.CreatedDate != null ? string.valueOf(objCase.CreatedDate.format('yyyy-MM-dd')) : '';
                    
                    //identifier 1
                    objIdentifier1.lYear = string.valueOf(currentDate.Year()).substring(2,4);
                    objIdentifier1.lMonth = formattedMonth;	
                    objIdentifier1.claimRoad = '0712';
                    //objIdentifier1.claimNumber = objCase.CaseNumber.rightPad(15,' ');
                    objIdentifier1.claimNumber = objCase.CSX_CMP_Case_Number_Formula__c.rightPad(15,' ');
                    objIdentifier1.recordType = '1';
                    if(objCase.Type.contains('Recharges')){
                        objIdentifier1.claimType  = '8';
                    }else{
                        objIdentifier1.claimType  = '0';
                    }
                    
                    if(objCase.CSX_CMP_Paid_Amount__c != null && Math.abs(objCase.CSX_CMP_Paid_Amount__c) > 0){
                        objIdentifier1.amountSettled = string.valueOf(Math.abs(objCase.CSX_CMP_Paid_Amount__c)).replace('.','').leftPad(9, '0');
                    }else{
                        objIdentifier1.amountSettled = '000000000';
                    }
                    
                    if(objCase.CSX_CMP_Salvage_Amount__c != null && Math.abs(objCase.CSX_CMP_Salvage_Amount__c) > 0){
                        objIdentifier1.netSalvageAmount = string.valueOf(Math.abs(objCase.CSX_CMP_Salvage_Amount__c)).replace('.','').leftPad(9, '0');
                    }else{
                        objIdentifier1.netSalvageAmount = '000000000';
                    }

                    //objIdentifier1.salvageCode = objCase.CSX_CMP_Salvage_Code__c != null ? objCase.CSX_CMP_Salvage_Code__c.substring(1,2) : ''.rightPad(1,' ');
                    objIdentifier1.salvageCode = objCase.CSX_CMP_Salvage_Code__c != null ? objCase.CSX_CMP_Salvage_Code__c : ''.rightPad(1,' ');
                    objIdentifier1.fcdCause = objCase.CSX_CMP_FCD_Cause_Code__c != null ? objCase.CSX_CMP_FCD_Cause_Code__c.rightPad(2,' ') : ''.rightPad(2,' ');
                    
                    if (objCase.CSX_CMP_Remarks__c != null) {
                        splitRemark = objCase.CSX_CMP_Remarks__c.split(';');
                        remark1 = splitRemark.size() >= 1 ? splitRemark[0] : '';
                        remark2 = splitRemark.size() >= 2 ? splitRemark[1] : '';
                      } else {
                        remark1 = '';
                        remark2 = '';
                      }
                    
                    if(remark1 != '' && remark1 != null){//19 April Change
                        if(remark1.length() < 5){
                            objIdentifier1.remark1 = remark1.rightPad(5, ' ');
                        }else {
                            objIdentifier1.remark1 = remark1.substring(0, 5);
                        }
                    }else{
                        objIdentifier1.remark1 = ''.rightPad(5, ' ');
                    }

                    if(remark2 != '' && remark2 != null){//19 April Change
                        if(remark2.length() < 5){
                            objIdentifier1.remark2 = remark2.rightPad(5, ' ');
                        }else {
                            objIdentifier1.remark2 = remark2.substring(0, 5);
                        }
                    }else{
                        objIdentifier1.remark2 = ''.rightPad(5, ' ');
                    }

                    //identifier 2
                    objIdentifier2.fcdRule = objCase.CSX_CMP_FCD_Rule_Code__c != null ? objCase.CSX_CMP_FCD_Rule_Code__c.leftPad(3,'0') : '0'.leftPad(3,'0');
                    if(objCase.Type != 'Recharges Outbound Claim'){
                        objIdentifier2.papersTo = '0000';
                    }else{
                        objIdentifier2.papersTo = '0000';
                    }
                    
                    objIdentifier2.claimRecDateYY = string.valueof(objCase.CSX_CMP_Claim_Date__c.Year()).substring(2,4).rightPad(2,'0');
                    Integer claimDateMonth = objCase.CSX_CMP_Claim_Date__c.Month();
                    string claimDateFormatMonth;
                    if(claimDateMonth < 10){
                        claimDateFormatMonth = '0'+string.valueOf(claimDateMonth);
                    }else{
                        claimDateFormatMonth = string.valueOf(claimDateMonth);
                    }
                    objIdentifier2.claimRecDateMM = claimDateFormatMonth.rightPad(2,'0');
                    
                    Integer claimDateDay = objCase.CSX_CMP_Claim_Date__c.Day();
                    string claimDateFormatDay;
                    if(claimDateDay < 10){
                        claimDateFormatDay = '0'+string.valueOf(claimDateDay);
                    }else{
                        claimDateFormatDay = string.valueOf(claimDateDay);
                    }
                    objIdentifier2.claimRecDateDD = claimDateFormatDay.rightPad(2,'0');
                    
                    objIdentifier2.claimantNumber = objCase.CSX_CMP_Claimant_Ref_Num__c != null ? objCase.CSX_CMP_Claimant_Ref_Num__c.rightPad(13,' ') : ''.rightPad(13,' ');

                    if(Math.abs(objCase.CSX_CMP_Claim_Amount__c) > 0){
                        objIdentifier2.amount = string.valueOf(Math.abs(objCase.CSX_CMP_Claim_Amount__c)).replace('.','').leftPad(9, '0');
                    }else{
                        objIdentifier2.amount = '000000000';
                    }
                    
                    if(objCase.CSX_CMP_Currency_Code__c == 'USD'){
                        foreignCurr = 'U';
                    }else if(objCase.CSX_CMP_Currency_Code__c == 'CAD'){
                        foreignCurr = 'C';
                    }
                    objIdentifier2.foreignCurrency = (foreignCurr != '' && foreignCurr != null) ? foreignCurr : foreignCurr.rightPad(1,' ');
                    //objFldx.claim = objCase.CaseNumber;
                    objFldx.claim = objCase.CSX_CMP_Case_Number_Formula__c;
                    //Equipment
                    if(!objCase.Equipments__r.isempty()){
                        for(CSX_CMP_Equipment__c objEquipment : objCase.Equipments__r){
                            //identifier 1
                            objIdentifier1.stcccode = objEquipment.CSX_CMP_STCC__c != null ? objEquipment.CSX_CMP_STCC__c.rightPad(7, ' ') : ''.rightPad(7,' ');

                            String shipperCode = objEquipment.CSX_CMP_Shipper__c != null ? objEquipment.CSX_CMP_Shipper__c.length() < 9 ? objEquipment.CSX_CMP_Shipper__c.rightPad(9, ' ') : objEquipment.CSX_CMP_Shipper__c.substring(0, 9) : ''.rightPad(9, ' ');
                            objIdentifier1.shipperCode = shipperCode;

                            String consigneeCode = objEquipment.CSX_CMP_Consignee__c != null ? objEquipment.CSX_CMP_Consignee__c.length() < 9 ? objEquipment.CSX_CMP_Consignee__c.rightPad(9, ' ') : objEquipment.CSX_CMP_Consignee__c.substring(0, 9) : ''.rightPad(9, ' ');
                            objIdentifier1.consigneeCode = consigneeCode;

                            objIdentifier1.originRoad = objEquipment.CSX_CMP_Origin_Road_Num__c != null ? objEquipment.CSX_CMP_Origin_Road_Num__c.leftPad(4,'0') : '0'.leftPad(4,'0');

                            objIdentifier1.destinationRoad = objEquipment.CSX_CMP_Destination_Road_Num__c != null ? objEquipment.CSX_CMP_Destination_Road_Num__c.leftPad(4,'0') : '0'.leftPad(4,'0') ;

                            if(objEquipment.CSX_CMP_PPN__c != null){
                                objIdentifier1.ppnNumber = objEquipment.CSX_CMP_PPN__c.leftPad(2,'0');
                            }else{
                                objIdentifier1.ppnNumber ='00';
                            }

                            if(objEquipment.CSX_CMP_Multi_Car_Count__c != null){
                                objIdentifier1.multiCarCount = string.valueOf(objEquipment.CSX_CMP_Multi_Car_Count__c);
                            }else{
                                objIdentifier1.multiCarCount = '00';
                            }
                            
                            String originCity = objEquipment.CSX_CMP_Act_Origin_City__c != null ? objEquipment.CSX_CMP_Act_Origin_City__c.length() < 6  ? objEquipment.CSX_CMP_Act_Origin_City__c.rightPad(6, ' ')  : objEquipment.CSX_CMP_Act_Origin_City__c.substring(0, 6)  : ''.rightPad(6, ' ');
                            objIdentifier1.originCity = originCity;

                            String destinationCity = objEquipment.CSX_CMP_Act_Destination_City__c != null ? objEquipment.CSX_CMP_Act_Destination_City__c.length() < 6  ? objEquipment.CSX_CMP_Act_Destination_City__c.rightPad(6, ' ') : objEquipment.CSX_CMP_Act_Destination_City__c.substring(0, 6) : ''.rightPad(6, ' ');
                            objIdentifier1.destinationCity = destinationCity;
                            
                            objIdentifier1.originState = objEquipment.CSX_CMP_Act_Origin_State__c != null ? objEquipment.CSX_CMP_Act_Origin_State__c.rightPad(2,' ') : ''.rightPad(2,' ');
                            
                            objIdentifier1.destinationState = objEquipment.CSX_CMP_Act_Destination_State__c != null ? objEquipment.CSX_CMP_Act_Destination_State__c.rightPad(2,' ') : ''.rightPad(2,' ') ;

                            objIdentifier1.waybillNumber = objEquipment.CSX_CMP_Waybill_Num__c != null ? objEquipment.CSX_CMP_Waybill_Num__c.rightPad(6,' ') : ''.rightPad(6,' ');

                            if(objEquipment.CSX_CMP_Waybill_Date__c != null){
                                objIdentifier1.waybillDateYY = string.valueof(objEquipment.CSX_CMP_Waybill_Date__c.Year()).substring(2,4).rightPad(2,' ');

                                Integer waybillMonth = objEquipment.CSX_CMP_Waybill_Date__c.Month();
                                objIdentifier1.waybillDateMM = waybillMonth < 10 ? '0'+string.valueOf(waybillMonth) : string.valueOf(waybillMonth);
                                
                                Integer waybillDay = objEquipment.CSX_CMP_Waybill_Date__c.Day();
                                objIdentifier1.waybillDateDD = waybillDay < 10 ? '0'+string.valueOf(waybillDay) : string.valueOf(waybillDay);

                            }else{
                                objIdentifier1.waybillDateYY = ''.rightPad(2,' ');
                                objIdentifier1.waybillDateMM = ''.rightPad(2,' ');
                                objIdentifier1.waybillDateDD = ''.rightPad(2,' ');
                            }

                            objIdentifier1.carInitial = objEquipment.CSX_CMP_Equipment_Initial__c != null ? objEquipment.CSX_CMP_Equipment_Initial__c.rightPad(4,' ') : ''.rightPad(4,' ');

                            objIdentifier1.carNumber = objEquipment.CSX_CMP_Equipment_Num__c != null ? objEquipment.CSX_CMP_Equipment_Num__c.leftPad(6,'0') : '0'.leftPad(6,'0');
                           
                           String originAudit = objEquipment.CSX_CMP_Origin_Audit_Num__c != null ? (objEquipment.CSX_CMP_Origin_Audit_Num__c.length() < 5)  ? objEquipment.CSX_CMP_Origin_Audit_Num__c.rightPad(5, '0') : objEquipment.CSX_CMP_Origin_Audit_Num__c.substring(0, 5) : '0'.rightPad(5, '0');
                           objIdentifier1.originAudit = originAudit;

                           String destinationAudit = objEquipment.CSX_CMP_Destination_Audit__c != null ? (objEquipment.CSX_CMP_Destination_Audit__c.length() < 5)  ? objEquipment.CSX_CMP_Destination_Audit__c.rightPad(5, '0') : objEquipment.CSX_CMP_Destination_Audit__c.substring(0, 5) : '0'.rightPad(5, '0');
                           objIdentifier1.destinationAudit = destinationAudit;

                            objIdentifier1.constant2 = '0000';
                            objIdentifier1.claimant = objEquipment.CSX_CMP_Supplier_Claimant_Type__c != null ? objEquipment.CSX_CMP_Supplier_Claimant_Type__c.rightPad(1,' ') : ''.rightPad(1,' ');
                            
                            //identifier 2
                            objIdentifier2.waybillNumber = objIdentifier1.waybillNumber;
                            objIdentifier2.waybillDateYY = objIdentifier1.waybillDateYY;
                            objIdentifier2.waybillDateMM = objIdentifier1.waybillDateMM;
                            objIdentifier2.waybillDateDD = objIdentifier1.waybillDateDD;
                            
                            //Product
                            if(!mapOfEquipmentIdtoDetails.isEmpty() != null && mapOfEquipmentIdtoDetails.containsKey(objEquipment.Id)){
                                if(!mapOfEquipmentIdtoDetails.get(objEquipment.Id).Products__r.isEmpty()){
                                    for(CSX_CMP_Product__c objProduct : mapOfEquipmentIdtoDetails.get(objEquipment.Id).Products__r){
                                         if(objProduct.CSX_CMP_VIN__c != null){
                                            objIdentifier2.autoVinNum = objProduct.CSX_CMP_VIN__c .rightPad(17,' ');
                                        }else{
                                            objIdentifier2.autoVinNum = ''.rightPad(17,' ');
                                        }
                                    }
                                }else{
                                    objIdentifier2.autoVinNum = ''.rightPad(17,' ');
                                }

                                List<CSX_CMP_Distribution__c> distributionList = new List<CSX_CMP_Distribution__c>();
                                distributionList = mapOfEquipmentIdtoDetails.get(objEquipment.Id).Distributions__r;
                                Integer distributionSize = distributionList.size();
                                if(!distributionList.isEmpty()){  
                                    for(Integer i = 0; i < distributionSize; i++){
                                        CSX_CMP_Distribution__c objDistribution = distributionList[i];
                                        if(i < 3) {
                                            JunctionWrapper objJunction = new JunctionWrapper();
                                            objJunction = fillJunction(objDistribution,objCase,distributionSize);
                                            if(objJunction != null){
                                                objFldx.identifier3List.add(objJunction);
                                                flagMap.put('flag3',true);
                                            }
                                        }
                                        
                                        if(i >= 3 && i < 6) {
                                            JunctionWrapper objJunction = new JunctionWrapper();
                                            objJunction = fillJunction(objDistribution,objCase,distributionSize);
                                            if(objJunction != null){
                                                objFldx.identifier4List.add(objJunction);
                                                flagMap.put('flag4',true);
                                            }
                                        }
                                        
                                        if( i >= 6 && i < 9) {
                                            JunctionWrapper objJunction = new JunctionWrapper();
                                            objJunction = fillJunction(objDistribution,objCase,distributionSize);
                                            if(objJunction != null){
                                                objFldx.identifier5List.add(objJunction);
                                                flagMap.put('flag5',true);
                                            }
                                        }
                                        
                                        if( i >= 9 && i < 12){
                                            JunctionWrapper objJunction = new JunctionWrapper();
                                            objJunction = fillJunction(objDistribution,objCase,distributionSize);
                                            if(objJunction != null){
                                                objFldx.identifier6List.add(objJunction);
                                                flagMap.put('flag6',true);
                                            }
                                        }   
                                    }
                                }
                            }
                            
                        }
                    } else {
                        objIdentifier1.stcccode = ''.rightPad(7, ' ');
                        objIdentifier1.shipperCode = ''.rightPad(9, ' ');
                        objIdentifier1.consigneeCode = ''.rightPad(9, ' ');
                        objIdentifier1.originRoad = '0'.leftPad(4,'0');
                        objIdentifier1.destinationRoad = '0'.leftPad(4,'0');
                        objIdentifier1.fcdCause = ''.rightPad(2,' ');
                        objIdentifier1.ppnNumber = '00';
                        objIdentifier1.multiCarCount = '00';
                        objIdentifier1.originCity = ''.rightPad(6, ' ');
                        objIdentifier1.destinationCity = ''.rightPad(6, ' ');
                        objIdentifier1.originState = ''.rightPad(2,' ');
                        objIdentifier1.destinationState = ''.rightPad(2,' ');
                        objIdentifier1.waybillNumber = ''.rightPad(6,' ');
                        objIdentifier1.waybillDateYY = ''.rightPad(2,' ');
                        objIdentifier1.waybillDateMM = ''.rightPad(2,' ');
                        objIdentifier1.waybillDateDD = ''.rightPad(2,' ');
                        objIdentifier1.carInitial = ''.rightPad(4,' ');
                        objIdentifier1.carNumber = '0'.leftPad(6,'0');
                        objIdentifier1.originAudit = '0'.rightPad(5,'0');
                        objIdentifier1.destinationAudit = '0'.rightPad(5,'0');
                        objIdentifier1.constant2 = '0000';
                        objIdentifier1.claimant = ''.rightPad(1,' ');

                        objIdentifier2.waybillNumber = ''.rightPad(6,' ');
                        objIdentifier2.waybillDateYY = ''.rightPad(2,' ');
                        objIdentifier2.waybillDateMM = ''.rightPad(2,' ');
                        objIdentifier2.waybillDateDD = ''.rightPad(2,' ');
                        objIdentifier2.autoVinNum = ''.rightPad(17,' ');
                    }
                    objFldx.identifier1 = objIdentifier1;
                    objFldx.identifier2 = objIdentifier2;
                    lstFLDX.add(objFldx);
                }
            }
                
            if(!lstFLDX.isEmpty()){
                for(FLDXInitialWrapper wrapObj: lstFLDX){ 
                    //create String for Identifier 1

                    string identifier1 = string.valueOf(currentDate.Year()).substring(2,4)+formattedMonth+'0712'+wrapObj.claim.rightPad(15, ' ')+'1'+'0'+wrapObj.identifier1.claimType+
                        wrapObj.identifier1.amountSettled+wrapObj.identifier1.stcccode+wrapObj.identifier1.netSalvageAmount+wrapObj.identifier1.salvageCode+wrapObj.identifier1.fcdCause+
                        wrapObj.identifier1.remark1+wrapObj.identifier1.remark2+wrapObj.identifier1.shipperCode+' '+wrapObj.identifier1.consigneeCode+wrapObj.identifier1.claimant+wrapObj.identifier1.originRoad+wrapObj.identifier1.destinationRoad+
                        wrapObj.identifier1.ppnNumber+''.rightPad(6,' ')+''.rightPad(2,' ')+wrapObj.identifier1.multiCarCount+wrapObj.identifier1.originCity+wrapObj.identifier1.originState+wrapObj.identifier1.destinationCity+
                        wrapObj.identifier1.destinationState+wrapObj.identifier1.waybillNumber+wrapObj.identifier1.waybillDateYY+wrapObj.identifier1.waybillDateMM+wrapObj.identifier1.waybillDateDD+wrapObj.identifier1.carInitial+wrapObj.identifier1.carNumber+
                        wrapObj.identifier1.originAudit+wrapObj.identifier1.destinationAudit+wrapObj.identifier1.constant2+''.rightPad(19,' ');
                    
                    //create String for Identifier 2
                    string identifier2 = string.valueOf(currentDate.Year()).substring(2,4)+formattedMonth+'0712'+wrapObj.claim.rightPad(15, ' ')+'2'+''.rightPad(16,' ')+wrapObj.identifier2.waybillNumber+wrapObj.identifier2.waybillDateYY+wrapObj.identifier2.waybillDateMM+wrapObj.identifier2.waybillDateDD+
                        wrapObj.identifier1.carInitial+'0'.rightPad(6,'0')+'0'.rightPad(5,'0')+'0'.rightPad(5,'0')+''.rightPad(10,' ')+''.rightPad(12,' ')+wrapObj.identifier2.autoVinNum+wrapObj.identifier2.fcdRule+''.rightPad(3,' ')+wrapObj.identifier2.papersTo+wrapObj.identifier2.claimRecDateYY+
                        wrapObj.identifier2.claimRecDateMM+wrapObj.identifier2.claimRecDateDD+'0'.rightPad(2,'0')+'0'.rightPad(2,'0')+'0'.rightPad(2,'0')+wrapObj.identifier2.claimantNumber+wrapObj.identifier2.amount+wrapObj.identifier2.foreignCurrency+''.rightPad(21,' ');
                    
                    //create String for Identifier 3,4,5,6
                    
                    for(String key : flagMap.keySet()){
                        if(flagMap.get(key)){
                            String flagNum = key.substring(4,key.length());
                            String identifierKey = 'identifier' + flagNum +'String';
                            identifierMap.put(identifierKey,'');
                        }
                    }

                    String initialIdentifierValue = string.valueOf(currentDate.Year()).substring(2,4)+formattedMonth+'0712'+wrapObj.claim.rightPad(15, ' ');

                    if(!wrapObj.identifier3List.isEmpty()){
                        String identifierValue = initialIdentifierValue + '3';
                        identifierMap.put('identifier3String',buildIdentifierMap(wrapObj.identifier3List,identifierValue));
                    }
                    
                    if(!wrapObj.identifier4List.isEmpty()){
                        String identifierValue = initialIdentifierValue + '4';
                        identifierMap.put('identifier4String',buildIdentifierMap(wrapObj.identifier4List,identifierValue));
                    }
                    
                    if(!wrapObj.identifier5List.isEmpty()){
                        String identifierValue = initialIdentifierValue + '5';
                        identifierMap.put('identifier5String',buildIdentifierMap(wrapObj.identifier5List,identifierValue));
                    }
                    
                    if(!wrapObj.identifier6List.isEmpty()){
                        String identifierValue = initialIdentifierValue + '6';
                        identifierMap.put('identifier6String',buildIdentifierMap(wrapObj.identifier6List,identifierValue));
                    }

                    ClaimWrapper objClaimWrapUpdated = new ClaimWrapper();
                    objClaimWrapUpdated.claimNumber = wrapObj.claim;
                    objClaimWrapUpdated.claimDetails = identifier1;
                    objClaimWrapUpdated.additionalClaimDetails = identifier2;
                    objClaimWrapUpdated.distributionsUpto3 = identifierMap.get('identifier3String');
                    objClaimWrapUpdated.distributions4to6 = identifierMap.get('identifier4String');
                    objClaimWrapUpdated.distributions7to9 = identifierMap.get('identifier5String');
                    objClaimWrapUpdated.distributionsOver9 = identifierMap.get('identifier6String');
                    objClaimWrap.claims.add(objClaimWrapUpdated);
                }
            }
        }catch(Exception ex){
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_FLDXOutboundWebServiceHelper','getFLDXOutboundWebServiceData',servicePeriod,ex);
        }
        return objClaimWrap;

    }

    private static String buildIdentifierMap(List<JunctionWrapper> lstJunction, String identifier){
        for(JunctionWrapper jun:lstJunction){
            String lAmount = calculateAmount(jun.lAmount);
            String lspecialAmount = calculateAmount(jun.lSpecialAmount);
            String lTotalAmount = calculateAmount(jun.lTotAmt);

            identifier = identifier + jun.railRoadJunction.rightPad(5, ' ')+jun.railRoadCode.rightPad(4,' ')+jun.type.rightpad(2,' ')+jun.railRoadMiles+formatAmount(lAmount)+formatAmount(lspecialAmount)+formatAmount(lTotalAmount);//lAmount+lspecialAmount+lTotalAmount;
        }
        return identifier;
    }

    private static String calculateAmount(String amount){
        string claimAmount = '000000000';
        if(amount != null && amount != '0'){
            Decimal decimalValue = Decimal.valueOf(amount);
            if (decimalValue != 0) {
                claimAmount = string.valueOf(Math.abs(decimalValue)).replace('.','').leftPad(9, '0');
            }else{
                claimAmount = '000000000';
            }
        }else{
            claimAmount = '000000000';
        }
        return claimAmount;
    }

    private static String formatAmount(String amount) {
        string formattedAmount = '0000000000';
        if(amount != null && amount != '0000000000' && amount != '0'){
            if(amount.length() < 9){
                formattedAmount = amount.leftPad(9, '0');
            }else {
                formattedAmount = amount.substring(0, 9);
            }
        }else{
            formattedAmount = '0'.leftPad(9, '0');
        }
        return formattedAmount;
    }

    private static JunctionWrapper fillJunction(CSX_CMP_Distribution__c objDistribution, Case objCase,Integer distSize) {
        JunctionWrapper objJun = new JunctionWrapper();
        try{
            objJun.railRoadJunction = objDistribution.CSX_CMP_Junction__c != null ? objDistribution.CSX_CMP_Junction__c.rightPad(5, ' ') : '';
            //objJun.railRoadCode = objDistribution.CSX_CMP_Code__c != null ? objDistribution.CSX_CMP_Code__c.rightPad(4,' ') : '';
            objJun.railRoadCode = objDistribution.CSX_CMP_Road__c != null ? objDistribution.CSX_CMP_Road__c.rightPad(4,' ') : '';
            objJun.railRoadMiles = objDistribution.CSX_CMP_Miles__c != null ? String.valueOf(Integer.valueOf(objDistribution.CSX_CMP_Miles__c)).leftPad(4,'0') : '0';
            if(objDistribution.CSX_CMP_Miles__c != null){
                objJun.type = 'M';
            }else{
                objJun.type = '0';
            }
            if(objDistribution.CSX_CMP_Distribution_Claim__c == null && objDistribution.CSX_CMP_Road__c != '0712'){
                if(objDistribution.CSX_CMP_Manual_Adj_Amt__c == 0 && objDistribution.CSX_CMP_Calculated_Amount__c == 0){
                    objJun.lAmount = '0';
                }else if(objDistribution.CSX_CMP_Manual_Adj_Amt__c != null && objDistribution.CSX_CMP_Manual_Adj_Amt__c == 0){
                    objJun.lAmount = String.valueOf(objDistribution.CSX_CMP_Calculated_Amount__c);
                }else{
                    if(objDistribution.CSX_CMP_Manual_Adj_Amt__c != null){
                        objJun.lAmount = String.valueOf(objDistribution.CSX_CMP_Manual_Adj_Amt__c);
                    }
                }
                
                if(objCase.CSX_CMP_Salvage_Amount__c != null){ 
                    Decimal speAmount = objCase.CSX_CMP_Salvage_Amount__c/distSize;
                    objJun.lSpecialAmount = string.valueOf(speAmount);
                }else{
                    objJun.lSpecialAmount = '000000000';
                    //0
                }
                
                if(objCase.Type == 'Recharges Outbound Claim'){
                    objJun.lTotAmt = string.valueOf(objDistribution.CSX_CMP_Manual_Adj_Amt__c);
                }else{
                    if(objDistribution.CSX_CMP_Manual_Adj_Amt__c == 0){
                        objJun.lTotAmt = string.valueOf(Decimal.valueOf(objJun.lAmount)+ Decimal.valueOf(objJun.lSpecialAmount));
                    }
                    else{
                        objJun.lTotAmt = string.valueOf(objDistribution.CSX_CMP_Manual_Adj_Amt__c);
                    }
                }


            }else{
                objJun.lTotAmt = '0';
                objJun.lSpecialAmount = '0';
                objJun.lAmount = '0';
            } 
           
        } catch (Exception e){
            Map<String,Object> parameterMap = new Map<String,Object>();
            parameterMap.put('objDistribution',objDistribution);
            parameterMap.put('objCase',objCase);           
            parameterMap.put('distSize',distSize);          
            CSX_CMP_LoggerUtility.addApexErrorLog('CSX_CMP_FLDXOutboundWebServiceHelper','fillJunction',JSON.serialize(parameterMap),e);
        }
        
        return objJun;
    }

    public class ClaimWrapper {
        public String claimNumber;
        public string claimDetails;
        public string additionalClaimDetails;
        public string distributionsUpto3;
        public string distributions4to6;
        public string distributions7to9;
        public string distributionsOver9;
    }

    public class FLDXInitialWrapper {
        public String claim;
        public Identifier1Wrapper identifier1;
        public Identifier2Wrapper identifier2;
        public List<JunctionWrapper> identifier3List;	//max 3 entries
        public List<JunctionWrapper> identifier4List;	//max 3 entries
        public List<JunctionWrapper> identifier5List;
        public List<JunctionWrapper> identifier6List;

        FLDXInitialWrapper(){
            identifier3List = new List<JunctionWrapper>();
            identifier4List = new List<JunctionWrapper>();
            identifier5List = new List<JunctionWrapper>();
            identifier6List = new List<JunctionWrapper>();
        }
    }
    
    public class Identifier1Wrapper{
        public String lYear;
        public String lMonth;
        public String claimRoad;
        public String claimNumber;
        public String recordType;
        public String claimType;
        public String amountSettled;
        public String stcccode;
        public String netSalvageAmount;
        public String salvageCode;
        public String fcdCause;
        public String remark1;
        public String remark2;
        public String shipperCode;
        public String consigneeCode;
        public String claimant;
        public String originRoad;
        public String destinationRoad;
        public String ppnNumber;
        public String multiCarCount;
        public String originCity;
        public String originState;
        public String destinationCity;
        public String destinationState;
        public String waybillNumber;
        public String waybillDateYY;
        public String waybillDateMM;
        public String waybillDateDD;
        public String carInitial;
        public String carNumber;
        public String originAudit;
        public String destinationAudit;
        public String constant2;
    }
    
    public class Identifier2Wrapper{
        public String lYear;
        public String lMonth;
        public String claimRoad;
        public String claimNumber;
        public String recordType;
        public String waybillNumber;
        public String waybillDateYY;
        public String waybillDateMM;
        public String waybillDateDD;
        public String autoVinNum;
        public String fcdRule;
        public String papersTo; //doubt
        public String claimRecDateYY;
        public String claimRecDateMM;
        public String claimRecDateDD;
        public String claimantNumber;
        public String amount;
        public String foreignCurrency;
    }
    
    public class JunctionWrapper{
        public String railRoadJunction;
        public String railRoadCode;
        public String type;
        public String railRoadMiles;
        public String lAmount = '0';
        public String lSpecialAmount = '0';
        public String lTotAmt = '0';
    }

}