public with sharing class ReservationProductTriggerHandler extends TriggerHandler {
    public ReservationProductTriggerHandler(
        System.TriggerOperation operation, 
        List<ProdutoReserva__c> newRecordList, 
        List<ProdutoReserva__c> oldRecordList, 
        Map<Id, ProdutoReserva__c> newMap, 
        Map<Id, ProdutoReserva__c> oldMap
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
        
        ReservationProductTriggerHelper.populateChaveUnica(newRecordList);
    }
    
    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {

        System.debug('afterInsert validateStatusReservation');
    
        ReservationProductTriggerHelper.validateStatusReservation((Map<Id, ProdutoReserva__c>) this.newMap);
    }
    
    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {      
       
        ReservationProductTriggerHelper.updateLastDateReservationMovement( (Map<Id, ProdutoReserva__c>) this.newMap, (Map<Id, ProdutoReserva__c>) this.oldMap);
    }
    
    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
      
        System.debug('afterUpdate validateStatusReservation');
    
        ReservationProductTriggerHelper.validateStatusReservation( (Map<Id, ProdutoReserva__c>) this.newMap);
    }
    
    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {

        ReservationProductTriggerHelper.validateQuantityUsed( (Map<Id, ProdutoReserva__c>) this.oldMap);

    }
    
    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}
    
    // @END TRIGGER HANDLERS
}