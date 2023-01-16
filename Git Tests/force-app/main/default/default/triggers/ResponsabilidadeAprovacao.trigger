trigger ResponsabilidadeAprovacao on ResponsabilidadeAprovacao__c (after insert, after update, after delete) {
    ResponsabilidadeAprovacaoHandler handler = new ResponsabilidadeAprovacaoHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (ResponsabilidadeAprovacaoHandler.isTriggerEnabled())
        handler.execute();
}