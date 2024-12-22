/**
@Author       - Infosys
@Name         - DataDictionaryExportController
@Created Date - 12/04/2023
@Description  - Apex class to extract data model
*/
public with sharing class DataDictionaryExportController {

    private static List<String> OBJ_STNDRD_LIST = new String[] {'Account', 'Contact', 'Case', 'Task', 'User', 'Event'};
    
    private static List<String> OBJ_CUSTOM_LIST = new String[] {'CSX_CMP_3rd_Party__c', 'CSX_CMP_AP_Settlement__c', 'CSX_CMP_Approval_History__c', 'CSX_CMP_Approval_Sequence__c', 'CSX_CMP_AR_Settlement__c', 'CSX_CMP_Auto_pay_kickout_Code_Master__c', 'CSX_CMP_Batch_Execution_Log__c', 'CSX_CMP_Business_Rule__c', 'CSX_CMP_Business_Rule_Condition__c', 'CSX_CMP_City_State_Master__c', 'CSX_CMP_Claim_Contact__c', 'CSX_CMP_Claim_Line__c', 'CSX_CMP_Contract__c', 'CSX_CMP_Creation_Request__c', 'CSX_CMP_Document_Ref__c', 'CSX_CMP_Customer_Damage__c', 'CSX_CMP_Decline_Code_Master__c', 'CSX_CMP_Desk__c', 'CSX_CMP_Distribution__c', 'CSX_CMP_EDI926ClaimReport__c', 'CSX_CMP_Equipment__c', 'CSX_CMP_Error_Log__c', 'CSX_CMP_FLR_Email_Master__c', 'CSX_CMP_FLR_Question__c', 'CSX_CMP_General_Rule_Configuration__c', 'CSX_CMP_Inspection_Damage__c', 'CSX_CMP_Inspection_Detail__c', 'CSX_CMP_Inspection_Header__c', 'CSX_CMP_Integration_Log__c', 'CSX_CMP_Integration_Time_Log__c', 'CSX_CMP_LD_Contact__c', 'CSX_CMP_LD_Report__c', 'CSX_CMP_Mileage__c', 'CSX_CMP_Notes__c', 'CSX_CMP_Payment_Transactions__c', 'CSX_CMP_Product__c', 'CSX_CMP_Property_Portal_Staging__c', 'CSX_CMP_Related_Case__c', 'CSX_CMP_Related_Claim__c', 'CSX_CMP_Related_LD_Report__c', 'CSX_CMP_Salvage__c', 'CSX_CMP_Similarity_Matrix__c', 'CSX_CMP_Task_Checklist__c', 'CSX_CMP_Transfer_Equipment__c', 'CSX_CMP_User_Request__c', 'CSX_CMP_FCD_Cause_Master__c', 'CSX_CMP_FCD_Rule_Master__c'};
        
    private static List<String> FLD_SKIP_LIST = new String[] {'IsDeleted','LastActivityDate','LastReferencedDate','LastViewedDate','SystemModstamp'};
    
    public static List<ObjInfo> objInfos { get; set;}
    public DataDictionaryExportController(){
        init();
    }
    
    private void init(){
        Map<String, Schema.SObjectType> allObjMap = Schema.getGlobalDescribe();
        objInfos = new List<ObjInfo>();
        List<String> sortedNames = new List<String>();
        for(String objName : allObjMap.keySet()){
            if( (CSX_CMP_Utility.contains(OBJ_STNDRD_LIST, objName) || isCustomObject(objName) ) && !allObjMap.get(objName).getDescribe().isCustomSetting()){    
                sortedNames.add(objName);
            }
        }
        sortedNames.sort();
        for(String objName : sortedNames){
            DescribeSObjectResult result = allObjMap.get(objName).getDescribe();
            Map<String, Schema.SObjectField> objectFields = result.fields.getMap();
            List<String> fieldNames = new List<String>();
            for(String fieldName : result.fields.getMap().keySet()) {
                if(!skipField(FLD_SKIP_LIST, fieldName)){
                    fieldNames.add(fieldName);
                }
            }
            fieldNames.sort();
            for(String fieldName : fieldNames) {
                ObjInfo objInfo = new ObjInfo(result.getLabel(), result.getName());
                Schema.DescribeFieldResult fr = objectFields.get(fieldName).getDescribe();
                String dataType = fr.getType().Name().toLowerCase().capitalize();
                if (fr.getType() == DisplayType.Reference) {
                    for (SObjectType r : fr.getReferenceTo()) {
                        dataType = 'Reference';
                        objInfo.referencedObject = String.valueOf(r);
                    }
                }
                
                objInfo.fieldLabel = fr.getLabel();
                objInfo.fieldName = fr.getName();
                if(fr.isCalculated()){
                    dataType = 'Formula('+dataType + ')' ;
                }
                if(fr.isAutoNumber()){
                    dataType = 'Auto Number' ;
                }
                objInfo.FieldType_x = dataType;
                String length = null != fr.getLength() ? String.valueOf(fr.getLength()) : '';        
                if(Schema.DisplayType.Double == fr.getType()){
                    length = '('+ String.valueOf(fr.getPrecision()) + ','+ String.valueOf(fr.getScale()) + ')';
                }
                if(Schema.DisplayType.Integer == fr.getType()){
                    length = String.valueOf(fr.getDigits());
                }   
                if(fr.isCalculated()){
                    length = '' ;
                }   
                objInfo.fieldLength = length;
                objInfo.FieldIsReq = fr.isNillable() ? 'No' : 'Yes';
               	objInfos.add(objInfo);
            }
        }
    }
    
    private static boolean skipField(List<String> allValues, String valueToCheck){
        boolean hasVal = false;
        for(Integer i=0; i< allValues.size(); i ++ ){
            if(allValues[i].equalsIgnoreCase(valueToCheck)){
                hasVal = true;
                break;
            }
        }
        return hasVal;
    }
    
    private static boolean isCustomObject(String valueToCheck){
        return valueToCheck.endsWithIgnoreCase('__c');
    }
    
    
    public class ObjInfo {
        public String label {get; set;}
        public String name {get; set;}
        public String dsc {get; set;}
        public String fieldLabel {get; set;}
        public String fieldName {get; set;}
        public String fieldType_x {get; set;}
        public String fieldLength {get; set;}
        public String referencedObject {get; set;}
        public String ChildRelationshipName {get; set;}
        public String fieldIsReq {get; set;} // nillable
        
        public ObjInfo(String label, String name){
            this.label = label;
            this.name = name;
            this.dsc = '';
        }
    }
}