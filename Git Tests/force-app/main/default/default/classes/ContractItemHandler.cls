public without sharing class ContractItemHandler extends TriggerHandler{

    public ContractItemHandler(System.TriggerOperation operation, List<ItemContrato__c> newRecordList, List<ItemContrato__c> oldRecordList, Map<Id, ItemContrato__c> newMap, Map<Id, ItemContrato__c> oldMap) {
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
        ContractItemHelper.validateStatusField(newRecordList, (Map<Id, ItemContrato__c>) this.oldMap, (Map<Id, ItemContrato__c>) this.newMap);
        ContractItemHelper.updateContractItemStatus(newRecordList);
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {        
        ContractItemHelper.submitContractToApproval(newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        ContractItemHelper.validateStatusField(newRecordList, (Map<Id, ItemContrato__c>) this.oldMap, (Map<Id, ItemContrato__c>) this.newMap);
        ContractItemHelper.updateContractItemStatus(newRecordList);
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
        ContractItemHelper.submitContractToApproval(newRecordList);
    }

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