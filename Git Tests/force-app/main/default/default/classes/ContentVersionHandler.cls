public without sharing class ContentVersionHandler extends TriggerHandler {
    
    public ContentVersionHandler(System.TriggerOperation operation, List<ContentVersion> newRecordList, List<ContentVersion> oldRecordList, Map<Id, ContentVersion> newMap, Map<Id, ContentVersion> oldMap) {
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
    public override void beforeInsert() {}

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
        ContentVersionHelper.updateCtDocumentDescription(this.newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {}

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {}

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {}

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}