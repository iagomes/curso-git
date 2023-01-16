trigger Setorizacao on Setorizacao__c (before insert, after insert, before update, after update, before delete, after delete) {
    SetorizacaoHandler handler = new SetorizacaoHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (SetorizacaoHandler.isTriggerEnabled())
        handler.execute();
}