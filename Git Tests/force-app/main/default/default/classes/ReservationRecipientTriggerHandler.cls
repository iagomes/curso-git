public with sharing class ReservationRecipientTriggerHandler extends TriggerHandler {
    public ReservationRecipientTriggerHandler(
        System.TriggerOperation operation, 
        List<DestinatarioReserva__c> newRecordList, 
        List<DestinatarioReserva__c> oldRecordList, 
        Map<Id, DestinatarioReserva__c> newMap, 
        Map<Id, DestinatarioReserva__c> oldMap
    ) {
        super(operation, newRecordList, oldRecordList, newMap, oldMap);
    }
    
    // @TRIGGER METHODS
    private static Boolean runTrigger;
    
    static {
        runTrigger = true;
    }
    
    public static Boolean isTriggerEnabled(){
        return runTrigger;
    }
    
    public static Boolean enableTrigger(){
        return runTrigger = true;
    }
    
    public static Boolean disableTrigger(){
        return runTrigger = false;
    }
    // @END TRIGGER METHODS
    
    // @TRIGGER HANDLERS
    
    /*
    * Purpose: BEFORE_INSERT handler method
    */
    public override void beforeInsert() {

        
    }
    
    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
  
        ReservationRecipientTriggerHelper.getReservationRecordType((Map<Id, DestinatarioReserva__c>) this.newMap); 
        ReservationRecipientTriggerHelper.manageGroupClientsRecipient(newRecordList, true); 
        ReservationRecipientTriggerHelper.sendReservationRecipientERP((Map<Id, DestinatarioReserva__c>) this.newMap); 

    }
    
    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {      
       
    }
    
    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {

        ReservationRecipientTriggerHelper.getReservationRecordType((Map<Id, DestinatarioReserva__c>) this.newMap);       
    }
    
    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {

    }
    
    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {

        ReservationRecipientTriggerHelper.manageGroupClientsRecipient(oldRecordList, false); 
    }
    
    // @END TRIGGER HANDLERS
}