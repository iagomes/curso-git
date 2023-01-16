trigger ItensNotasFiscaisTrigger on ItensNotaFiscal__c (before insert, after insert, before update, after update, before delete, after delete) {

    ItensNotasFiscaisTH handler = new ItensNotasFiscaisTH(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
     
    if (ItensNotasFiscaisTH.isTriggerEnabled())
        handler.execute();
}