trigger ContractItem on ItemContrato__c (before insert, after insert, before update, after update, before delete, after delete) {
    ContractItemHandler handler = new ContractItemHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (ContractItemHandler.isTriggerEnabled())
        handler.execute();
}