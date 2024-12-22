public with sharing class CSX_CMP_ECMUploadRequest {
    
    public static String generateECMRequest(CSX_CMP_InterfaceUtility.ECMRequestWrapper reqWrap){
        
        Map<String, Object> request = new Map<String, Object>();
        String filePath ;
        List<Map<String, Object>> metadata = new List<Map<String, Object>>();
        
        if(reqWrap.dDocName != null){
            Map<String, Object> metadata13 = new Map<String, Object>();
            metadata13.put('name', 'dDocName');
            metadata13.put('value', reqWrap.dDocName);
            metadata.add(metadata13);
        }
        
        if(reqWrap.dDocTitle != null){
            Map<String, Object> metadata1 = new Map<String, Object>();
            metadata1.put('name', 'dDocTitle');
            metadata1.put('value', reqWrap.dDocTitle);
            metadata.add(metadata1);
        }
        
        if(reqWrap.dDocType != null){
            Map<String, Object> metadata2 = new Map<String, Object>();
            metadata2.put('name', 'dDocType');
            metadata2.put('value', reqWrap.dDocType);
            metadata.add(metadata2);
        }
        
        if(reqWrap.dDocAuthor != null){
            Map<String, Object> metadata3 = new Map<String, Object>();
            metadata3.put('name', 'dDocAuthor');
            metadata3.put('value', reqWrap.dDocAuthor);
            metadata.add(metadata3);
        }
        
        if(reqWrap.dSecurityGroup != null){
            Map<String, Object> metadata4 = new Map<String, Object>();
            metadata4.put('name', 'dSecurityGroup');
            metadata4.put('value', reqWrap.dSecurityGroup);
            metadata.add(metadata4);
        }
        
        if(reqWrap.dDocAccount != null){
            Map<String, Object> metadata5 = new Map<String, Object>();
            metadata5.put('name', 'dDocAccount');
            metadata5.put('value', reqWrap.dDocAccount);
            metadata.add(metadata5);
        }
        
        if(reqWrap.xRMProfileTrigger != null){
            Map<String, Object> metadata6 = new Map<String, Object>();
            metadata6.put('name', 'xRMProfileTrigger');
            metadata6.put('value', reqWrap.xRMProfileTrigger);
            metadata.add(metadata6);
        }
        
        if(reqWrap.xCategoryID != null){
            Map<String, Object> metadata7 = new Map<String, Object>();
            metadata7.put('name', 'xCategoryID');
            metadata7.put('value', reqWrap.xCategoryID);
            metadata.add(metadata7);
        }
        
        if(reqWrap.xEventNumber != null){
            Map<String, Object> metadata8 = new Map<String, Object>();
            metadata8.put('name', 'xEventNumber');
            metadata8.put('value', reqWrap.xEventNumber);
            metadata.add(metadata8);
        }
        
        if(reqWrap.xCarNumber != null){
            Map<String, Object> metadata9 = new Map<String, Object>();
            metadata9.put('name', 'xCarNumber');
            metadata9.put('value', reqWrap.xCarNumber);
            metadata.add(metadata9);
        }
        
        if(reqWrap.xCarInitial != null){
            Map<String, Object> metadata10 = new Map<String, Object>();
            metadata10.put('name', 'xCarInitial');
            metadata10.put('value', reqWrap.xCarInitial);
            metadata.add(metadata10);
        }
        
        if(reqWrap.xIronMtnBoxNum != null){
            Map<String, Object> metadata11 = new Map<String, Object>();
            metadata11.put('name', 'xIronMtnBoxNum');
            metadata11.put('value', reqWrap.xIronMtnBoxNum);
            metadata.add(metadata11);
        }
        
        /*   Map<String, Object> metadata12 = new Map<String, Object>();
metadata12.put('name', 'revLabel');
metadata12.put('value', reqWrap.revLabel);
metadata.add(metadata12);*/
        
        if(reqWrap.xCmisAttachment != null){
            Map<String, Object> metadata14 = new Map<String, Object>();
            metadata14.put('name', 'xCmisAttachment');
            metadata14.put('value', reqWrap.xCmisAttachment);
            metadata.add(metadata14); 
        }
        
        if(reqWrap.xGroupFour != null){
            Map<String, Object> metadata15 = new Map<String, Object>();
            metadata15.put('name', 'xGroupFour');
            metadata15.put('value', reqWrap.xGroupFour);
            metadata.add(metadata15); 
        }
        
        request.put('metadata', metadata);
        request.put('filePath',reqWrap.filePath);
        
        String jsonRequest=JSON.serialize (request);
        return jsonRequest;
    } 
    
}