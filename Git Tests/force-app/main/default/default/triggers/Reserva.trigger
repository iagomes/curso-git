trigger Reserva on Reserva__c (before insert, after insert, before update, after update, before delete, after delete) {

    ReservationTriggerHandler handler = new ReservationTriggerHandler(
        Trigger.operationType,    
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );
    if (ReservationTriggerHandler.isTriggerEnabled())
        handler.execute();
}