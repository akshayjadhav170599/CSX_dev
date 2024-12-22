/**
 * @description       : Helper class for CSX_CMP_TriggerHandler
 * @author            : Nagarro
 * @last modified on  : 08-13-2024
 * @last modified by  : Vaishali
**/
public with sharing class CSX_CMP_TriggerHandlerHelper {
    /**
    * @description Method to update records
    * @param existingRecordsToUpdateMap 
    * @param handlerName 
    **/
    public static void updateRecords(Map<SObjectType, Map<Id, SObject>> existingRecordsToUpdateMap, String handlerName) {
        while(!existingRecordsToUpdateMap.isEmpty()) {
            List<SObject> recordsToUpdate = new List<SObject>();
            for(Integer i = 0; i < 10 && !existingRecordsToUpdateMap.isEmpty(); i++) {
                SObjectType objType = new List<SObjectType>(existingRecordsToUpdateMap.keySet())[0];
                if(existingRecordsToUpdateMap.get(objType)?.isEmpty() == false) {
                    recordsToUpdate.addAll(existingRecordsToUpdateMap.get(objType).values());
                }
                existingRecordsToUpdateMap.remove(objType);
            }
            // CSX_CMP_DMLUtility.ParamsDMLUtility dmlparams = new CSX_CMP_DMLUtility.ParamsDMLUtility();
            // dmlparams.records = recordsToUpdate; 
            // dmlparams.sourceClassMethod = handlerName + 'updateRecords';
            // dmlparams.allOrNoneIndicator = true; 
            // CSX_CMP_DMLUtility.updateRecords(dmlparams);
        }
    }
    
    /**
    * @description Method to set trigger context
    * @param ctx 
    * @param testMode 
    * @return TriggerContext 
    **/
    public static TriggerContext setTriggerContext(String ctx, Boolean testMode) {
        Map<String, TriggerContext> contextMap = new Map<String, TriggerContext>{
            'before insert' => TriggerContext.BEFORE_INSERT,
            'before update' => TriggerContext.BEFORE_UPDATE,
            'before delete' => TriggerContext.BEFORE_DELETE,
            'after insert'  => TriggerContext.AFTER_INSERT,
            'after update'  => TriggerContext.AFTER_UPDATE,
            'after delete'  => TriggerContext.AFTER_DELETE,
            'after undelete'=> TriggerContext.AFTER_UNDELETE
        };
        if (ctx != null && contextMap.containsKey(ctx)) {
            return contextMap.get(ctx);
        } else {
            return getTriggerContext();
        }
    }
    
    /**
    * @description Method to get trigger context
    * @return TriggerContext 
    **/
    public static TriggerContext getTriggerContext() {
        Map<Boolean, TriggerContext> beforeMap = new Map<Boolean, TriggerContext>{
            Trigger.isInsert => TriggerContext.BEFORE_INSERT,
            Trigger.isUpdate => TriggerContext.BEFORE_UPDATE,
            Trigger.isDelete => TriggerContext.BEFORE_DELETE
        };
        Map<Boolean, TriggerContext> afterMap = new Map<Boolean, TriggerContext>{
            Trigger.isInsert => TriggerContext.AFTER_INSERT,
            Trigger.isUpdate => TriggerContext.AFTER_UPDATE,
            Trigger.isDelete => TriggerContext.AFTER_DELETE,
            Trigger.isUndelete => TriggerContext.AFTER_UNDELETE
        };
        if (Trigger.isBefore) {
            return beforeMap.get(true);
        } else if (Trigger.isAfter) {
            return afterMap.get(true);
        }
        return null; 
    }

    /**
    * @description Add Record To Update
    * @param existingRecordsToUpdateMap 
    * @param recs 
    * @return List<SObject> 
    **/
    public static List<SObject> addRecordToUpdate(Map<SObjectType, Map<Id, SObject>> existingRecordsToUpdateMap, List<SObject> recs) {
		if (recs != null && !recs.isEmpty()) {
			for (SObject rec : recs) {
				SObjectType objType = rec.getSobjectType();
				if(existingRecordsToUpdateMap.get(objType) == null) {
					existingRecordsToUpdateMap.put(objType, new Map<Id, SObject>());
				}
				existingRecordsToUpdateMap.get(objType).put(rec.Id, rec);
			}
		}
		return recs;
	}

    /**
    * @description Get Record To Update
    * @param existingRecordsToUpdateMap 
    * @param objId 
    * @return SObject 
    **/
    public static SObject getRecordToUpdate(Map<SObjectType, Map<Id, SObject>> existingRecordsToUpdateMap, Id objId) {
		SObject rec;
		if (objId != null) {
			SObjectType objType = objId.getSobjectType();
			if(existingRecordsToUpdateMap.get(objType) == null) {
				existingRecordsToUpdateMap.put(objType, new Map<Id, SObject>());
			}
			if (existingRecordsToUpdateMap.get(objType).get(objId) == null) {
				existingRecordsToUpdateMap.get(objType).put(objId, objType.newSObject(objId));
			}
			rec = existingRecordsToUpdateMap.get(objType).get(objId);
		}
		return rec;
	}
	
	/**
	* @description Make sure this trigger should continue to run
	* @param isTriggerExecuting 
	* @param context 
	**/
	public static void validateRun(Boolean isTriggerExecuting, TriggerContext context) {
		if (!isTriggerExecuting || context == null) {
			throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
		}
	}

    /**
	* @description possible trigger contexts
	**/
	@TestVisible
	public enum TriggerContext {
		BEFORE_INSERT,
		BEFORE_UPDATE,
		BEFORE_DELETE,
		AFTER_INSERT,
		AFTER_UPDATE,
		AFTER_DELETE,
		AFTER_UNDELETE
	} 

    /**
	* @description Exception class
	**/
	public class TriggerHandlerException extends Exception {
	}    
      
}