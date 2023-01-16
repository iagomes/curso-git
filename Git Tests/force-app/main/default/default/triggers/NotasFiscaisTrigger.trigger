trigger NotasFiscaisTrigger on NotasFiscais__c (before insert, after insert, before update, after update, before delete, after delete) {

    NotasFiscaisTH handler = new NotasFiscaisTH(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (NotasFiscaisTH.isTriggerEnabled())
        handler.execute();
}