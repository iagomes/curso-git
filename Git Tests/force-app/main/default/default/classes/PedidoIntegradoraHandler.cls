public without sharing class PedidoIntegradoraHandler extends TriggerHandler{

    public PedidoIntegradoraHandler(System.TriggerOperation operation, List<PedidoIntegradora__c> newRecordList, List<PedidoIntegradora__c> oldRecordList, Map<Id, PedidoIntegradora__c> newMap, Map<Id, PedidoIntegradora__c> oldMap) {
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
        PedidoIntegradoraHelper.fillInconsistencyOrder( (Map<Id, PedidoIntegradora__c>) this.oldMap, (Map<Id, PedidoIntegradora__c>) this.newMap);
        PedidoIntegradoraHelper.checkLabOrder(this.newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        PedidoIntegradoraHelper.checkLabOrder(this.newRecordList);
        PedidoIntegradoraHelper.cleanApprovalStatus( (Map<Id, PedidoIntegradora__c>) this.oldMap, (Map<Id, PedidoIntegradora__c>) this.newMap);
        PedidoIntegradoraHelper.fillInconsistencyOrder( (Map<Id, PedidoIntegradora__c>) this.oldMap, (Map<Id, PedidoIntegradora__c>) this.newMap);
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
        PedidoIntegradoraHelper.automaticPedidoIntegradoraApproval( (Map<Id, PedidoIntegradora__c>) this.oldMap, (Map<Id, PedidoIntegradora__c>) this.newMap);
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

    }

    // @END TRIGGER HANDLERS
}
