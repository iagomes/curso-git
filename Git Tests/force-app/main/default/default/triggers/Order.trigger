trigger Order on Order (before insert, after insert, before update, after update, before delete, after delete) {
    OrderHandler handler = new OrderHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (OrderHandler.isTriggerEnabled())
        handler.execute();
}