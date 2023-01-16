trigger Product on Product2 (before insert, after insert, before update, after update, before delete, after delete) {
    ProductHandler handler = new ProductHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (ProductHandler.isTriggerEnabled())
        handler.execute();
}