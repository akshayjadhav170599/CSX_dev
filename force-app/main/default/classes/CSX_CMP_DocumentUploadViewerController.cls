/**************************************************************************************
Apex Class Name     : CSX_CMP_DocumentUploadViewerController
Function            : 
RICEFW #            : 
Modification Log    :
* Developer         : Date           This Class is used to upload the documents against claim & L&D Report and sent to ECM
* ----------------------------------------------------------------------------                  
* Infosys           04/10/2024       First version of this class.
*************************************************************************************/
public  with sharing class CSX_CMP_DocumentUploadViewerController { 
    

    @AuraEnabled
    public static ScreenData fetchData(String strId){
        ScreenData objScreenData = New ScreenData();
        
        try{
            if(strId != null && strId.startsWith('500')){
                Case objCase = [SELECT Id, CaseNumber, CSX_CMP_VIN__c, Description, RecordType.DeveloperName, CSX_CMP_ECM_Link__c,
                                CSX_CMP_Contract_Num__r.Name, Type
                                ,(SELECT Id, Name, CSX_CMP_Waybill_Date__c FROM Equipments__r LIMIT 1)
                                ,(SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Comment')
                                FROM Case 
                                WHERE Id =: strId
                                WITH SECURITY_ENFORCED
                                LIMIT 1
                                ];
                if(objCase != null){
                    objScreenData.strClaimType = objCase.Type;
                    objScreenData.strID = objCase.id;
                    objScreenData.strNumber = objCase.CaseNumber;
                    objScreenData.strECMLink = objCase.CSX_CMP_ECM_Link__c;
                    objScreenData.strContractNumber = objCase.CSX_CMP_Contract_Num__r.Name;

                    if(objCase.Equipments__r != null && objCase.Equipments__r.size() > 0){
                        objScreenData.strEquipmentName = objCase.Equipments__r[0].Name;
                        objScreenData.strWayBillDate = string.valueOf(objCase.Equipments__r[0].CSX_CMP_Waybill_Date__c);
                    }

                    if(objCase.Notes__r != null && objCase.Notes__r.size() > 0){
                        objScreenData.strComments = objCase.Notes__r[0].CSX_CMP_Notes__c;
                    }
                    
                    objScreenData.strVin = objCase.CSX_CMP_VIN__c;
                    objScreenData.strRecordTypeDeveloperName = objCase.RecordType.DeveloperName;
                }                
            }
            else{
                CSX_CMP_LD_Report__c objLDReport = [SELECT Id, Name, RecordType.DeveloperName, CSX_CMP_ECM_Link__c,
                                                    CSX_CMP_Incident_Comments__c
                                                    ,(SELECT Id, Name, CSX_CMP_Waybill_Date__c FROM Equipments__r) 
                                                    FROM CSX_CMP_LD_Report__c 
                                                    WHERE Id =: strId
                                                    WITH SECURITY_ENFORCED
                                                    LIMIT 1
                                                    ];
                
                if(objLDReport != null){
                    objScreenData.strID = objLDReport.id;
                    objScreenData.strNumber = objLDReport.Name;
                    objScreenData.strECMLink = objLDReport.CSX_CMP_ECM_Link__c;
                    objScreenData.strComments =objLDReport.CSX_CMP_Incident_Comments__c;

                    if(objLDReport.Equipments__r != null && objLDReport.Equipments__r.size() > 0){
                        objScreenData.strEquipmentName = objLDReport.Equipments__r[0].Name;
                        objScreenData.strWayBillDate = string.valueOf(objLDReport.Equipments__r[0].CSX_CMP_Waybill_Date__c);
                    }
                } 
            }

            //get user role details
            if(Schema.sObjectType.UserRole.isAccessible()) {
                UserRole objUserRole = [SELECT Id, Name FROM UserRole where id =: userinfo.getUserRoleId()];

                    if(objUserRole != null){
                        objScreenData.strUserRole = objUserRole.Name;
                    }
                }
            } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper','fetchData','',ex);
            return null;
        }
        return objScreenData;
    }

    @AuraEnabled
    public static boolean fileUpload(String base64, String filename, String parentId, Boolean isInternalOnly, 
                                    Boolean isUploadToECM, String newComments, Boolean isReupload, 
                                    Boolean isUpload, string contentDocumentId, string docId) 
    {
        try {       
            Id contentVersionID = createContentVersion(base64, filename, isInternalOnly, isUploadToECM, newComments, 
                                                        isReupload, isUpload, contentDocumentId, docId, parentId);
            if (!isUpload || isReupload) {
                createContentLink(contentVersionID, parentId, isReupload, docId, isUploadToECM);
            }
            return true;
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper', 'fileUpload', '', ex); 
            return false;
        }
    }

    // Create ContentVersion
    private static Id createContentVersion(String base64, String filename, Boolean isInternalOnly, Boolean isUploadToECM, 
                                            String newComments, Boolean isReupload, Boolean isUpload,
                                            String contentDocumentId, string docId, String parentId) {

        // list<ContentVersion> lstContentVersion = new list<ContentVersion>();

        ContentVersion objContentVersion = new ContentVersion();
        objContentVersion.VersionData = EncodingUtil.base64Decode(base64);
        objContentVersion.Title = filename;
        objContentVersion.PathOnClient = filename;
        objContentVersion.CSX_CMP_Internal_Only__c = isInternalOnly;
        objContentVersion.CSX_CMP_UploadToECM__c = isUploadToECM;
        objContentVersion.CSX_CMP_Comments__c = newComments;    
        
        if(isReupload){ //update is reupload check to true 
            objContentVersion.CSX_CMP_isReUpload__c = true;
        }

        if(isUpload){ //change this if condition with actual reupload / upload condition
            objContentVersion.ContentDocumentId = contentDocumentId;
        }

        try {
            Database.SaveResult[] contentVersionResult = Database.Insert(new List<ContentVersion>{objContentVersion}, false);

            CSX_CMP_LoggerUtility.addApexDMLErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentVersion', contentVersionResult, filename);

            if (contentVersionResult[0].isSuccess()) {

                if(isUpload){
                    if(Schema.sObjectType.ContentDocument.isAccessible()) {
                        ContentDocument contentDoc = [SELECT Id, Title, Description, FileExtension, LatestPublishedVersionId 
                                                        FROM ContentDocument 
                                                        WHERE Id =: objContentVersion.ContentDocumentId];
                    
                        //update the info on doc reference
                        CSX_CMP_Document_Ref__c doc = new CSX_CMP_Document_Ref__c();
                        doc.id =  docId;
                        doc.CSX_CMP_File_Name__c = contentDoc.Title;
                        doc.CSX_CMP_File_Extension__c = contentDoc.FileExtension;
                        doc.CSX_CMP_Content_Document_ID__c = contentDoc.Id;
                        doc.CSX_CMP_ContentVersionID__c = contentDoc.LatestPublishedVersionId;

                        Database.SaveResult[] documentRef = Database.update(new List<CSX_CMP_Document_Ref__c>{doc}, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentVersion', documentRef, contentDoc.Title);

                        //upload the new file to ECM if upload to ECM is true
                        if(isUploadToECM){
                            String parentEntityType = parentId.startsWith('500') ? 'Claim' : 'LD Report';
                            List<Id> contentVersionIds = new List<Id>();
                            contentVersionIds.add(objContentVersion.Id);
                            scheduleBatchJob(contentVersionIds, true, parentEntityType, true);
                        }
                    }
                }                
                return contentVersionResult[0].getId();
            } else {
                throw new DMLException('Failed to insert ContentVersion');
            }
        } catch (DMLException ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentVersion', '', ex);
            throw ex;
        }
    }

    // Create ContentDocumentLink
    private static Id createContentLink(String contentVersionId, String parentId, Boolean isReupload, string docId, Boolean isUploadToECM) {
        try {
            ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
            objContentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId].ContentDocumentId;
            objContentDocumentLink.LinkedEntityId = parentId;
            objContentDocumentLink.ShareType = 'V';

            Database.SaveResult[] contentDocLinkResult = Database.Insert(new List<ContentDocumentLink>{objContentDocumentLink}, false);
            CSX_CMP_LoggerUtility.addApexDMLErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentLink', contentDocLinkResult, 'ContentDocumentLink');

            if (contentDocLinkResult[0].isSuccess()) {
                if(isReupload){
                    if(Schema.sObjectType.ContentDocument.isAccessible()) {
                        ContentDocument contentDoc = [SELECT Id, Title, Description, FileExtension, LatestPublishedVersionId 
                                                        FROM ContentDocument 
                                                        WHERE Id =: objContentDocumentLink.ContentDocumentId];
                        
                        //update the info on doc reference
                        CSX_CMP_Document_Ref__c doc = new CSX_CMP_Document_Ref__c();
                        doc.id =  docId;
                        doc.CSX_CMP_File_Name__c = contentDoc.Title;
                        doc.CSX_CMP_File_Extension__c = contentDoc.FileExtension;
                        doc.CSX_CMP_Content_Document_ID__c = contentDoc.Id;
                        doc.CSX_CMP_ContentVersionID__c = contentDoc.LatestPublishedVersionId;

                        Database.SaveResult[] documentRef = Database.update(new List<CSX_CMP_Document_Ref__c>{doc}, false);
                        CSX_CMP_LoggerUtility.addApexDMLErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentLink', documentRef, contentDoc.Title);
                    }
                }

                //upload the new file to ECM if upload to ECM is true
                String parentEntityType = parentId.startsWith('500') ? 'Claim' : 'LD Report';
                
                //schedule batch job
                if(isUploadToECM){
                    scheduleBatchJob(new list<Id>{contentVersionId}, true, parentEntityType, true);         
                }
                return contentDocLinkResult[0].getId();
            } else {
                throw new DMLException('Failed to insert ContentDocumentLink');
            }
        } catch (DMLException ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper', 'createContentLink', '', ex);
            throw ex;
        }
    }

    @AuraEnabled
    public static List<CSX_CMP_Document_Ref__c> getDocuments(String strId) //Datetime currentTime 
    {
        // ScreenData objScreenData = New ScreenData();

        String query = 'SELECT id, Name, CSX_CMP_Claim__c, CSX_CMP_Equipment_ID__c, CSX_CMP_Document_Type__c, CSX_CMP_VIN__c' +
                       ', CSX_CMP_ECM_Document_ID__c, CSX_CMP_File_Name__c, LastModifiedBy.Name, CSX_CMP_isUserDocument__c' +
                       ', CSX_CMP_Content_Document_ID__c, CSX_CMP_ContentVersionID__c, CSX_CMP_UploadToECM__c, CSX_CMP_File_Description__c' +
                       ', CSX_CMP_Internal_Only__c, CreatedDate, CSX_CMP_Salesforce_license__c, CSX_CMP_ECM_Document_Link__c ' + 
                       ' FROM CSX_CMP_Document_Ref__c';

        if (strId.startsWith('500')){
            query += ' WHERE CSX_CMP_Claim__c = :strId';
        } else {
            query += ' WHERE CSX_CMP_LD_Report__c = :strId'; 
        }
        return Database.query(String.escapeSingleQuotes(query));       
    }

    @AuraEnabled
    public static Boolean deleteDocument(String documentId) {
        try {
            CSX_CMP_Document_Ref__c objDocument = [SELECT Id, CSX_CMP_Content_Document_ID__c, CSX_CMP_ContentVersionID__c
                                                    FROM CSX_CMP_Document_Ref__c 
                                                    WHERE Id = :documentId
                                                    WITH SECURITY_ENFORCED 
                                                    LIMIT 1
                                                ];
            if (objDocument == null) {
                throw new AuraHandledException('Document not found');
            }

            // Fetch ContentDocuments using the contentDocumentIds
            List<ContentDocument> contentDocumentsToDelete = [SELECT Id 
                                                      FROM ContentDocument 
                                                      WHERE Id = :objDocument.CSX_CMP_Content_Document_ID__c
                                                      WITH SECURITY_ENFORCED ];

            // Delete ContentDocuments
            if (!contentDocumentsToDelete.isEmpty()) {
                List<Database.DeleteResult> deleteContentDocument = Database.delete(contentDocumentsToDelete, false);
                CSX_CMP_LoggerUtility.addApexDMLErrorLog(
                    'csx_cmp_documentUploadViewerHelper',
                    'deleteDocument',
                    deleteContentDocument,
                    ''
                );
            }
            
            Database.DeleteResult deleteCSXDocRef = Database.delete(objDocument, false);
            if (!deleteCSXDocRef.isSuccess()) {
                throw new AuraHandledException('Error deleting custom document record: ' + deleteCSXDocRef.getErrors()[0].getMessage());
            }
            return true;
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper','deleteDocument','', ex);  
            return null; 
            }
    }

    @AuraEnabled
    public static void scheduleBatchJob(List<Id> contentVersionIds, Boolean isDelete, String parentEntityType, Boolean isManual) {
        
        try {
            CSX_CMP_ECMUploadBatch uploadBatch = new CSX_CMP_ECMUploadBatch(contentVersionIds, true, parentEntityType, true);
                Database.executeBatch(uploadBatch, 1);
        } catch (Exception ex) {
            CSX_CMP_LoggerUtility.addApexErrorLog('csx_cmp_documentUploadViewerHelper', 'scheduleBatchJob', '', ex);
        }
    }

    /*
    @AuraEnabled
    public static void updateComments(String strId, String newComments) {
        try {
            if(strId.startsWith('500')) {
                Case objCase = [SELECT Id, CaseNumber
                                ,(SELECT Id, CSX_CMP_Notes__c FROM Notes__r WHERE CSX_CMP_Note_Type__c = 'Comment' LIMIT 1)
                                FROM Case 
                                WHERE Id =: strId
                                WITH SECURITY_ENFORCED
                                LIMIT 1
                                ];
                    if(objCase != null && objCase.Notes__r.size() > 0) {
                        CSX_CMP_Notes__c commentNote = objCase.Notes__r[0];
                        commentNote.CSX_CMP_Notes__c = newComments;
                         Database.SaveResult result = Database.update(commentNote, false);
                    }
                } else {
                    CSX_CMP_LD_Report__c objReport = [SELECT Id, CSX_CMP_Incident_Comments__c 
                                                 FROM CSX_CMP_LD_Report__c
                                                 WHERE Id = :strId 
                                                 LIMIT 1];
                    if(objReport != null) {
                        objReport.CSX_CMP_Incident_Comments__c = newComments;
                        Database.SaveResult result = Database.update(objReport, false);
                    }
                }
            } catch(Exception e) {
            throw new AuraHandledException('Error updating comments: ' + e.getMessage());
        }
    } */

    //Wrapper class
    public class ScreenData{
        @AuraEnabled
        public String strUserRole{get;set;}
        @AuraEnabled
        public String strID{get;set;}
        @AuraEnabled
        public String strNumber{get;set;}
        @AuraEnabled
        public String strEquipmentName{get;set;}
        @AuraEnabled
        public String strVin {get;set;}
        @AuraEnabled
        public String strWayBillDate {get;set;}
        @AuraEnabled
        public String strComments {get;set;}
        @AuraEnabled
        public String strContractNumber {get;set;}
        @AuraEnabled
        public String strRecordTypeDeveloperName {get;set;}
        @AuraEnabled
        public Boolean isRailRoadLink {get;set;}
        @AuraEnabled
        public Boolean isInternalOnly {get;set;}
        @AuraEnabled
        public Boolean isUploadToECM {get;set;}
        @AuraEnabled
        public String strECMLink {get;set;}
        @AuraEnabled
        public String strECMDocId {get;set;}
        @AuraEnabled
        public String strCreatedDate {get;set;}
        @AuraEnabled
        public String strClaimType {get;set;}
    }

    //wrapper class for fileupload
    public class FileDataWP {
        public String fileName;
        public String fileContent;
        public String parentId;
    }

}