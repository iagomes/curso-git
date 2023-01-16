public without sharing class ContractHandler extends TriggerHandler{

    public ContractHandler(System.TriggerOperation operation, List<Contract> newRecordList, List<Contract> oldRecordList, Map<Id, Contract> newMap, Map<Id, Contract> oldMap) {
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
        ContractHelper.replicateContractNumber(newRecordList);
        ContractHelper.checkContractType(newRecordList);
        ContractHelper.validateStatusFieldInsert(newRecordList);
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {        
        ContractHelper.replicateContractNumber(newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        ContractHelper.checkContractType(newRecordList);
        ContractHelper.updateContractItensStatus((Map<Id, Contract>) this.oldMap, (Map<Id, Contract>) this.newMap);
        ContractHelper.validateStatusFieldUpdate((Map<Id, Contract>) this.oldMap, (Map<Id, Contract>) this.newMap);
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
        ContractHelper.unlockContract(newRecordList);
        ContractHelper.changeStatusActive(newRecordList);
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
        ContractHelper.checkUserRoleBeforeDelete(oldRecordList);
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}