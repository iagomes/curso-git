public without sharing class ItensNotasFiscaisTH extends TriggerHandler{
    
    public ItensNotasFiscaisTH(System.TriggerOperation operation, List<ItensNotaFiscal__c> newRecordList, List<ItensNotaFiscal__c> oldRecordList, Map<Id, ItensNotaFiscal__c> newMap, Map<Id, ItensNotaFiscal__c> oldMap) {
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

        ItensNotasFiscaisBO ItensNotasFiscaisBO = new ItensNotasFiscaisBO();
        ItensNotasFiscaisBO.vinculaItemVenda(null, (List<ItensNotaFiscal__c>)this.newRecordList);       
        ItensNotasFiscaisBO.validateCFOP(null, (List<ItensNotaFiscal__c>)this.newRecordList);
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
       
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
       
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
       
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}
