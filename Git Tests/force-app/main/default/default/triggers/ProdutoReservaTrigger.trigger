trigger ProdutoReservaTrigger on ProdutoReserva__c (before insert, after insert, before update, after update, before delete, after delete) {
    ReservationProductTriggerHandler handler = new ReservationProductTriggerHandler(
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );

    if (ReservationProductTriggerHandler.isTriggerEnabled())
        handler.execute();
}