public without sharing class ResponsabilidadeAprovacaoHandler extends TriggerHandler {

    public ResponsabilidadeAprovacaoHandler(
        System.TriggerOperation operation, 
        List<ResponsabilidadeAprovacao__c> newRecordList, 
        List<ResponsabilidadeAprovacao__c> oldRecordList, 
        Map<Id, ResponsabilidadeAprovacao__c> newMap, 
        Map<Id, ResponsabilidadeAprovacao__c> oldMap
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
    public override void beforeInsert() {}

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
        // ResponsabilidadeAprovacaoHelper.deleteUserTerritoryAssiciation(
        //     (ResponsabilidadeAprovacao__c[]) this.newRecordList
        // );

        ResponsabilidadeAprovacaoHelper.createUserTerritoryAssiciation(
            (Map<Id, ResponsabilidadeAprovacao__c>) this.newMap
        );
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {}

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
        // ResponsabilidadeAprovacaoHelper.deleteUserTerritoryAssiciation(
        //     (ResponsabilidadeAprovacao__c[]) this.newRecordList
        // );

        ResponsabilidadeAprovacaoHelper.createUserTerritoryAssiciation(
            (Map<Id, ResponsabilidadeAprovacao__c>) this.newMap
        );
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {}

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {
        ResponsabilidadeAprovacaoHelper.deleteUserTerritoryAssiciation(
            (List<ResponsabilidadeAprovacao__c>) this.oldRecordList
        );
    }

    // @END TRIGGER HANDLERS
}
