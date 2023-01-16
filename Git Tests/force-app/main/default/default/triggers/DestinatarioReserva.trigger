trigger DestinatarioReserva on DestinatarioReserva__c (before insert, after insert, before update, after update, before delete, after delete) {
    ReservationRecipientTriggerHandler handler = new ReservationRecipientTriggerHandler(
        Trigger.operationType,    
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );
    if (ReservationRecipientTriggerHandler.isTriggerEnabled())
        handler.execute();
}
