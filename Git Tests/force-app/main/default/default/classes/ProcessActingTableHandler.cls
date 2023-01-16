public with sharing class ProcessActingTableHandler extends TriggerHandler {
    
    public ProcessActingTableHandler(System.TriggerOperation operation, List<ProcessActingTable__e> newRecordList) {
        super(operation, newRecordList, null, null, null);
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
        ProcessActingTableHelper.handleProcessType(Trigger.new);
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
