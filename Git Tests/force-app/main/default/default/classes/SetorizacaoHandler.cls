public without sharing class SetorizacaoHandler extends TriggerHandler{

    public SetorizacaoHandler(System.TriggerOperation operation, List<Setorizacao__c> newRecordList, List<Setorizacao__c> oldRecordList, Map<Id, Setorizacao__c> newMap, Map<Id, Setorizacao__c> oldMap) {
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
        SetorizacaoHelper.fillEmptyActingTable(this.newRecordList);
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
        //SetorizacaoHelper.addAccTeamMemberBySectorization((Setorizacao__c[]) this.newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {
        SetorizacaoHelper.fillEmptyActingTable(this.newRecordList);
        //SetorizacaoHelper.upAccTeamMemberBySectorization((Map<Id, Setorizacao__c>) this.newMap, (Map<Id, Setorizacao__c>) this.oldMap, (Setorizacao__c[]) this.newRecordList);
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {}

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
        system.debug(this.oldRecordList);
        SetorizacaoHelper.delAccTeamMemberBySectorization((Setorizacao__c[]) this.oldRecordList);
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS
}
