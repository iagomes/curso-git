trigger PedidoIntegradora on PedidoIntegradora__c (before insert, after insert, before update, after update, before delete, after delete) {
    PedidoIntegradoraHandler handler = new PedidoIntegradoraHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (PedidoIntegradoraHandler.isTriggerEnabled())
        handler.execute();
}