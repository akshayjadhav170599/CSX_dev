@isTest
public class CSX_CMP_ClaimTriggerHelper_Test {

    // @isTest
    // static void validateStatus1() { 
    //     CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c();
    //     objDesk.Name = 'Desk 3';
    //     Insert objDesk;
           
    //    /* Set<Id> setOfClaimId = new Set<Id>();
    // 	Case testCase = new Case();
    //     testCase.Status='New';
    //     testCase.Type='AR Adjustment Claim';
    //     testCase.CSX_CMP_Desk_Name__c='Desk 3';
    //     testCase.CSX_CMP_Claim_Amount__c=88;
    //     testCase.CSX_CMP_Service_Period__c='1233';
    //     testCase.CSX_CMP_Netting_Claim_Ref_Number__c = testCase.id;
    //     testCase.Reason='Damaged'; 
    //     insert testCase;
    //     setOfClaimId.add(testCase.Id);*/
    //     String gsRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Freight').getRecordTypeId();
        
                         
    //     Map<Id, Case> oldClaimsMap = new Map<Id, Case>();
    //     Case oldClaim = new Case();
    //     oldClaim.Status ='Open';
    //     oldClaim.Type='FC RR Outbound Claim';
    //     oldClaim.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     oldClaim.CSX_CMP_Unread_Email__c = true;
    //     oldClaim.CSX_CMP_Claim_Amount__c = 88;
    //     oldClaim.recordTypeId = gsRecordTypeID;
    //     oldClaim.CSX_CMP_Service_Period__c='1233';
    //     oldClaim.CSX_CMP_External_ID__c ='500Dz00000ZcyA2IAJ_01112024105158_1';
    //     oldClaim.Reason='Damaged';
    //     insert oldClaim; 
    //     oldClaimsMap.put(oldClaim.Id, oldClaim); 

    //     CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
    //     note.CSX_CMP_Notes__c='test';
    //     note.CSX_CMP_Note_Type__c = 'Cancellation Reason';
    //     note.CSX_CMP_Claim__c = oldClaim.id;
    //     insert note;       
                
    //     Map<Id, Case> newClaimsMap1 = new Map<Id, Case>();
    //     Case newclaim1 = new Case();
    //     newclaim1.Status ='Cancelled';
    //     newclaim1.Type='FC RR Outbound Claim';
    //     newclaim1.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     newclaim1.CSX_CMP_Claim_Amount__c = 88;
    //     newclaim1.CSX_CMP_Service_Period__c='1233';
    //     newclaim1.recordTypeId = gsRecordTypeID;
    //     newclaim1.Reason='Damaged';
    //     newclaim1.CSX_CMP_Distribution_Id__c = 'a0DDz00000CKdp1MAD';
    //     newclaim1.CSX_CMP_External_ID__c ='500Dz00000ZcyA2IAJ_01112024105156_1';
    //     newclaim1.id = oldClaim.id;        
    //     update newclaim1; 
    //     newClaimsMap1.put(newclaim1.Id, newclaim1);
                                  
       
    //     CSX_CMP_Equipment__c equip = new CSX_CMP_Equipment__c();
    //     equip.Name = 'equipment';
    //     equip.CSX_CMP_Equipment_Num__c = 'oneTWO';
    //     equip.CSX_CMP_Equipment_Initial__c = 'BNSF';
    //     equip.CSX_CMP_Claim__c = newclaim1.Id;
    //     equip.CSX_CMP_Act_Origin_City__c = 'Ngp';
    //     equip.CSX_CMP_Act_Origin_State__c = 'MH';
    //     equip.CSX_CMP_Act_Destination_State__c = 'AP';
    //     equip.CSX_CMP_Act_Origin_State__c = 'MS'; 
    //     Insert equip;
     	
    //     Map<string,Id> distribution = new Map<string,Id>();
 	// 	CSX_CMP_Distribution__c dist = new CSX_CMP_Distribution__c();
    //     dist.CSX_CMP_Distribution_Claim__c = newclaim1.id;
    //     dist.CSX_CMP_Distribution_Claim_Created__c = true;
    //     dist.CSX_CMP_Adj_Miles__c = 786;
    //     dist.CSX_CMP_Equipment__c = equip.id;
    //     insert dist;
    //     string distStr = string.valueOf(dist.id);
    //     distribution.put(distStr, newclaim1.id);
        
    //     CSX_CMP_ClaimTriggerHelper.updateDistributionwithClaimId(distribution);
	// //	CSX_CMP_ClaimTriggerHelper.validateNotesonStatusChange(newClaimsMap1,oldClaimsMap);
    // } 
    
    // @isTest
    // static void validateStatus2(){
    //     CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c();
    //     objDesk.Name = 'Desk 3';
    //     Insert objDesk; 
        
    //     Id recordTypeId2 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Overcharge').getRecordTypeId();
        
    //     Map<Id, Case> oldClaimsMap = new Map<Id, Case>();
    //     Case oldClaim = new Case();
    //     //oldClaim.CSX_CMP_Decline_Code__c = decline.id;
    //     oldClaim.Status ='New';
    //     oldClaim.Type='FC RR Outbound Claim';
    //     oldClaim.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     oldClaim.CSX_CMP_Unread_Email__c = true;
    //     oldClaim.CSX_CMP_Claim_Amount__c = 88;
    //     oldClaim.recordTypeId = recordTypeId2;
    //     oldClaim.CSX_CMP_Service_Period__c='1233';
    //     oldClaim.Reason='Damaged';
    //     insert oldClaim; 
    //     oldClaimsMap.put(oldClaim.Id, oldClaim);
        
    //     CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
    //     note.CSX_CMP_Notes__c='test';
    //     note.CSX_CMP_Note_Type__c = 'Decline Reason';
    //     note.CSX_CMP_Claim__c = oldClaim.id;
    //     insert note;
        

    //     Map<Id, Case> newClaimsMap2 = new Map<Id, Case>();
    //     Case newclaim2 = new Case();
    //     //newclaim2.CSX_CMP_Decline_Code__c = decline.id;
    //     newclaim2.Status ='Declined';     
    //     newclaim2.Type='FC RR Outbound Claim';
    //     newclaim2.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     newclaim2.CSX_CMP_Claim_Amount__c = 88;
    //     newclaim2.CSX_CMP_Service_Period__c='1233';
    //     newclaim2.recordTypeId = recordTypeId2;
    //     newclaim2.Reason='Damaged';
    //     newclaim2.CSX_CMP_Distribution_Id__c = '4567843456';
    //     newclaim2.CSX_CMP_System_Action_Toggle__c =! newclaim2.CSX_CMP_System_Action_Toggle__c;
    //     //newclaim2.CSX_CMP_External_ID__c ='500Dz00000ZcyA2IAJ_01112024105156_1';
    //     newclaim2.id = oldClaim.id;        
    //     update newclaim2;
    //     newClaimsMap2.put(newclaim2.Id, newclaim2);
        
    //  //   CSX_CMP_ClaimTriggerHelper.validateNotesonStatusChange(newClaimsMap2,oldClaimsMap);
    // }
    
    // @isTest
    // static void validateStatus3(){
    //     CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c();
    //     objDesk.Name = 'Desk 3';
    //     Insert objDesk; 
        
    //     Id recordTypeId1 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Freight').getRecordTypeId();
        
    //     Map<Id, Case> oldClaimsMap = new Map<Id, Case>();
    //     Case oldClaim = new Case();
    //     oldClaim.Status ='Open';
    //     oldClaim.Type='FC RR Outbound Claim';
    //     oldClaim.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     oldClaim.CSX_CMP_Unread_Email__c = true;
    //     oldClaim.CSX_CMP_Claim_Amount__c = 88;
    //     oldClaim.recordTypeId = recordTypeId1;
    //     oldClaim.CSX_CMP_Service_Period__c='1233';
    //     oldClaim.Reason='Damaged';
    //     insert oldClaim; 
    //     oldClaimsMap.put(oldClaim.Id, oldClaim);

	// 	CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
    //     note.CSX_CMP_Notes__c='test';
    //     note.CSX_CMP_Note_Type__c = 'Decline Reason';
    //     note.CSX_CMP_Claim__c = oldClaim.id;
    //     insert note;
        
    //     CSX_CMP_Decline_Code_Master__c decline = new CSX_CMP_Decline_Code_Master__c();
    //     decline.Name = 'AOG';
    //     insert decline;
        
    //     Map<Id, Case> newClaimsMap3 = new Map<Id, Case>();
    //     Case newclaim3 = new Case();
    //     newclaim3.CSX_CMP_Decline_Code__c = decline.id;
    //     newclaim3.Status ='Declined';
    //     newclaim3.Type='FC RR Outbound Claim';
    //     newclaim3.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     newclaim3.CSX_CMP_Claim_Amount__c = 88;
    //     newclaim3.CSX_CMP_Service_Period__c='1233';
    //     newclaim3.recordTypeId = recordTypeId1;
    //     newclaim3.Reason='Damaged';
    //     newclaim3.CSX_CMP_Distribution_Id__c = '4567843456';
    //     newclaim3.CSX_CMP_External_ID__c ='500Dz00000ZcyA2IAJ_01112024105156_1';
    //     newclaim3.id = oldClaim.id;        
    //     update newclaim3;
    //     newClaimsMap3.put(newclaim3.Id, newclaim3);
        
    //   //  CSX_CMP_ClaimTriggerHelper.validateNotesonStatusChange(newClaimsMap3,oldClaimsMap);
    // }
    
    // @isTest
    // static void validateStatus4(){
    //     CSX_CMP_Desk__c objDesk = new CSX_CMP_Desk__c();
    //     objDesk.Name = 'Desk 4';
    //     Insert objDesk; 
        
    //     Id recordTypeId2 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Freight').getRecordTypeId();
    //     CSX_CMP_Decline_Code_Master__c decline = new CSX_CMP_Decline_Code_Master__c();
    //     decline.Name = 'OTH';
    //     insert decline;
    //     Map<Id, Case> oldClaimsMap = new Map<Id, Case>();
    //     Case oldClaim = new Case();
    //     //oldClaim.CSX_CMP_Decline_Code__c = decline.id;
    //     oldClaim.Status ='Open';
    //     oldClaim.Type='FC RR Outbound Claim';
    //     oldClaim.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     oldClaim.CSX_CMP_Unread_Email__c = true;
    //     oldClaim.CSX_CMP_Claim_Amount__c = 88;
    //     oldClaim.recordTypeId = recordTypeId2;
    //     oldClaim.CSX_CMP_Service_Period__c='1233';
    //     oldClaim.Reason='Damaged';
    //     insert oldClaim; 
    //     oldClaimsMap.put(oldClaim.Id, oldClaim);
        
    //     CSX_CMP_Notes__c note = new CSX_CMP_Notes__c();
    //     note.CSX_CMP_Notes__c='test';
    //     note.CSX_CMP_Note_Type__c = 'Adhoc Decline Reason';
    //     note.CSX_CMP_Claim__c = oldClaim.id;
    //     insert note;
        

    //     Map<Id, Case> newClaimsMap2 = new Map<Id, Case>();
    //     Case newclaim2 = new Case();
    //     newclaim2.CSX_CMP_Decline_Code__c = decline.id;
    //     newclaim2.Status ='Declined';     
    //     newclaim2.Type='FC RR Outbound Claim';
    //     newclaim2.CSX_CMP_Desk_Name__c=objDesk.Id;
    //     newclaim2.CSX_CMP_Claim_Amount__c = 88;
    //     newclaim2.CSX_CMP_Service_Period__c='1233';
    //     newclaim2.recordTypeId = recordTypeId2;
    //     newclaim2.Reason='Damaged';
    //     newclaim2.CSX_CMP_Distribution_Id__c = '4567843456';
    //     newclaim2.CSX_CMP_System_Action_Toggle__c =! newclaim2.CSX_CMP_System_Action_Toggle__c;
    //     //newclaim2.CSX_CMP_External_ID__c ='500Dz00000ZcyA2IAJ_01112024105156_1';
    //     newclaim2.id = oldClaim.id;        
    //     update newclaim2;
    //     newClaimsMap2.put(newclaim2.Id, newclaim2);   
        
    //   //  CSX_CMP_ClaimTriggerHelper.validateNotesonStatusChange(newClaimsMap2,oldClaimsMap);
    // }
}