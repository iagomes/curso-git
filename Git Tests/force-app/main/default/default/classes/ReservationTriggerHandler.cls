public with sharing class ReservationTriggerHandler extends TriggerHandler {
   
    public ReservationTriggerHandler(
        System.TriggerOperation operation, 
        List<Reserva__c> newRecordList, 
        List<Reserva__c> oldRecordList, 
        Map<Id, Reserva__c> newMap, 
        Map<Id, Reserva__c> oldMap
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
        ReservationTriggerHelper.updateDeliveryCenterName((List<Reserva__c>) this.newRecordList);
    }
    
    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
         ReservationTriggerHelper.updateCodigoReserva((Map<Id, Reserva__c>) this.newMap); 
    }
    
    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {}
    
    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {}
    
    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {}
    
    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}
    
    // @END TRIGGER HANDLERS
}
