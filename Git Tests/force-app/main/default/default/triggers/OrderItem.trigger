trigger OrderItem on OrderItem (after insert, after update) {

    OrderItemHandler handler = new OrderItemHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (OrderItemHandler.isTriggerEnabled()) {
        handler.execute();
    }
}