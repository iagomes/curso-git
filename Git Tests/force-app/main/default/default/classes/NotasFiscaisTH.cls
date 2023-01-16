public without sharing class NotasFiscaisTH extends TriggerHandler{
    
    public NotasFiscaisTH(System.TriggerOperation operation, List<NotasFiscais__c> newRecordList, List<NotasFiscais__c> oldRecordList, Map<Id, NotasFiscais__c> newMap, Map<Id, NotasFiscais__c> oldMap) {
        super(operation, newRecordList, oldRecordList, newMap, oldMap);
    }

      // @TRIGGER METHODS
    private static Boolean runTrigger;

    static {
        runTrigger = true;
    }

    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }

    public static Boolean enableTrigger(){
        return runTrigger = true;
    }

    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    // @END TRIGGER METHODS

    // @TRIGGER HANDLERS

    /*
    * Purpose: BEFORE_INSERT handler method
    */
    public override void beforeInsert() {

        //NotasFiscaisBO NotasFiscaisBO = new NotasFiscaisBO();
        //NotasFiscaisBO.validateCFOP(null, (List<NotasFiscais__c>)this.newRecordList);       
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
       
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
       
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
       
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}
