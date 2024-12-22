/**
 * @description       : Parent class for Trigger handler framework
 * @author            : Nagarro
 * @last modified on  : 08-13-2024
 * @last modified by  : Vaishali
 **/
public virtual class CSX_CMP_TriggerHandler {
    // static map of handlername, times run() was invoked
    public static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    // to avoid multiple update calls to same object in the same trigger
    private Map<SObjectType, Map<Id, SObject>> existingRecordsToUpdateMap = new Map<SObjectType, Map<Id, SObject>>();
    // the current context of the trigger, overridable in tests
    @TestVisible
    private CSX_CMP_TriggerHandlerHelper.TriggerContext context;
    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;
    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }
    
    /**
     * @description constructor
     **/
    public CSX_CMP_TriggerHandler() {
        this.setTriggerContext();
    }
    
    /**
     * @description main method that will be called during execution
     **/
    public void run() {
        if (!validateRun()){
            return;
        }
        if(bypassTrigger()){
            return;
        }
        addToLoopCount();
        // dispatch to the correct handler method
        if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.BEFORE_INSERT) {
            this.beforeInsert();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.BEFORE_UPDATE) {
            this.beforeUpdate();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.BEFORE_DELETE) {
            this.beforeDelete();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.AFTER_INSERT) {
            this.afterInsert();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.AFTER_UPDATE) {
            this.afterUpdate();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.AFTER_DELETE) {
            this.afterDelete();
        } else if (this.context == CSX_CMP_TriggerHandlerHelper.TriggerContext.AFTER_UNDELETE) {
            this.afterUndelete();
        }
        CSX_CMP_TriggerHandlerHelper.updateRecords(existingRecordsToUpdateMap, getHandlerName());
        this.clearBypasses();
    }
    
    /**
     * @description clearMaxLoopCount
     **/
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }
    
    /**
     * @description setMaxLoopCount
     * @param max
     **/
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!CSX_CMP_TriggerHandler.loopCountMap.containsKey(handlerName)) {
            CSX_CMP_TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            CSX_CMP_TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }
    
    /**
     * @description bypass
     * @param handlerName
     **/
    public static void bypass(String handlerName) {
        CSX_CMP_TriggerHandler.bypassedHandlers.add(handlerName);
    }
    
    /**
     * @description clearBypass
     * @param handlerName
     **/
    public static void clearBypass(String handlerName) {
        CSX_CMP_TriggerHandler.bypassedHandlers.remove(handlerName);
    }
    
    /**
     * @description isBypassed
     * @param handlerName
     * @return Boolean
     **/
    public static Boolean isBypassed(String handlerName) {
        return CSX_CMP_TriggerHandler.bypassedHandlers.contains(handlerName);
    }
    
    /**
     * @description clearAllBypasses
     **/
    public static void clearAllBypasses() {
        CSX_CMP_TriggerHandler.bypassedHandlers.clear();
    }

    /**
     * @description bypassTrigger
     * @return Boolean
     **/
    private Boolean bypassTrigger() {
        CSX_CMP_ByPass_Rules__c objByPassRule = CSX_CMP_ByPass_Rules__c.getInstance(userinfo.getUserId());
        return objByPassRule.CSX_CMP_Apex_Triggers__c;
    }
    
    /**
     * @description setTriggerContext
     **/
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }
    
    /**
     * @description setTriggerContext
     * @param ctx
     * @param testMode
     **/
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        }
        this.isTriggerExecuting = true;
        this.context = CSX_CMP_TriggerHandlerHelper.setTriggerContext(ctx, testMode);
    }
    
    /**
     * @description increment the loop count
     **/
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if (CSX_CMP_TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = CSX_CMP_TriggerHandler.loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max = CSX_CMP_TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }
    
    /**
     * @description make sure this trigger should continue to run
     * @return Boolean
     **/
    private Boolean validateRun() {
        CSX_CMP_TriggerHandlerHelper.validateRun(this.isTriggerExecuting, this.context);
        if (CSX_CMP_TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }
        return true;
    }
    
    /**
     * @description get Handler Name
     * @return String
     **/
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }
    
    // context-specific methods for override
    /**
     * @description beforeInsert
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeInsert() {
    }
    /**
     * @description beforeUpdate
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeUpdate() {
    }
    /**
     * @description beforeDelete
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeDelete() {
    }
    /**
     * @description afterInsert
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterInsert() {
    }
    /**
     * @description afterUpdate
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterUpdate() {
    }
    /**
     * @description afterDelete
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterDelete() {
    }
    /**
     * @description afterUndelete
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterUndelete() {
    }
    /**
     * @description clearBypasses
     **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void clearBypasses() {
    }
    
    /**
     * @description inner class for managing the loop count per handler
     **/
    @TestVisible
    public class LoopCount {
        public Integer max;
        public Integer count;
        
        /**
         * @description LoopCount
         **/
        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }
        
        /**
         * @description LoopCount
         * @param max
         **/
        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }
        
        /**
         * @description increment
         * @return Boolean
         **/
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }
        
        /**
         * @description exceeded
         * @return Boolean
         **/
        public Boolean exceeded() {
            if (this.max < 0){
                return false;
            }
            if (this.count > this.max) {
                return true;
            }
            return false;
        }
        
        /**
         * @description getMax
         * @return Integer
         **/
        public Integer getMax() {
            return this.max;
        }
        
        /**
         * @description getCount
         * @return Integer
         **/
        public Integer getCount() {
            return this.count;
        }
        
        /**
         * @description setMax
         * @param max
         **/
        public void setMax(Integer max) {
            this.max = max;
        }
    }
    
    /**
     * @description exception class
     **/
    public class TriggerHandlerException extends Exception {
    }
    
}