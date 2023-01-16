public with sharing class OrderItemHandler extends TriggerHandler {

    public OrderItemHandler(System.TriggerOperation operation, List<OrderItem> newRecordList, List<OrderItem> oldRecordList, Map<Id, OrderItem> newMap, Map<Id, OrderItem> oldMap) {
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

    public override void afterInsert() {
        OrderItemHelper.updateTotalOrParcialWinField((Map<Id, OrderItem> ) newMap);
    }

    public override void afterUpdate() {
        OrderItemHelper.updateTotalOrParcialWinField((Map<Id, OrderItem> ) newMap, (Map<Id, OrderItem> ) oldMap, false);
    }

    public override void beforeDelete() {}

    public override void afterDelete() {}

    public override void beforeInsert() {}

    public override void beforeUpdate() {}
}