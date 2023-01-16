trigger Contract on Contract (before insert, after insert, before update, after update, before delete, after delete) {
    ContractHandler handler = new ContractHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (ContractHandler.isTriggerEnabled())
        handler.execute();
}