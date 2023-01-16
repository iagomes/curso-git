public without sharing class OpportunityTH extends TriggerHandler {


    public OpportunityTH(System.TriggerOperation operation, List<Opportunity> newRecordList, List<Opportunity> oldRecordList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
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
        OpportunityBO OpportunityBO = new OpportunityBO();
        OpportunityBO.setVendedorOnLookupChange((Map<Id,Opportunity>)this.oldMap, (List<Opportunity>)this.newRecordList);
        
        for(Opportunity opp: (List<Opportunity>)newRecordList){
            OpportunityBO.setStandardValues(opp, (Map<Id, Opportunity>)this.oldMap);
        }
    }

    /*
    * Purpose: AFTER_INSERT handler method
    */
    public override void afterInsert() {
        OpportunityBO OpportunityBO = new OpportunityBO();
        OpportunityBO.preencherNomeOportunidade(this.newRecordList);
    }

    /*
    * Purpose: BEFORE_UPDATE handler method
    */
    public override void beforeUpdate() {

        OpportunityBO OpportunityBO = new OpportunityBO();
        // OpportunityBO.automaticOpportunityApproval((Map<Id, Opportunity>) this.oldMap, (Map<Id, Opportunity>) this.newMap);
        OpportunityBO.recallApprovalProcess((Map<Id, Opportunity>) this.oldMap, (Map<Id, Opportunity>) this.newMap);
        OpportunityBO.setVendedorOnLookupChange((Map<Id, Opportunity>) this.oldMap, (List<Opportunity>) newRecordList);
        OpportunityBO.checkDueDateUpdates((Map<Id, Opportunity>) this.newMap, (Map<Id, Opportunity>) this.oldMap);

        //Ajuste H-1078
        OpportunityBO.updateNameOrcamento((List<Opportunity>)newRecordList, (Map<Id, Opportunity>)this.oldMap);
    }

    /*
    * Purpose: AFTER_UPDATE handler method
    */
    public override void afterUpdate() {
       // OpportunityBO.validaAprovacao((Map<Id, Opportunity>) this.oldMap, (Map<Id, Opportunity>) this.newMap, this.newRecordList);
        OpportunityBO.automaticOpportunityApproval((Map<Id, Opportunity>) this.oldMap, (Map<Id, Opportunity>) this.newMap);
        OpportunityBO.uncheckApproval((Map<Id, Opportunity>) this.oldMap, (Map<Id, Opportunity>) this.newMap);
    }

    /*
    * Purpose: BEFORE_DELETE handler method
    */
    public override void beforeDelete() {
        OpportunityBO.deleteQuoteItems(this.oldMap.keySet());
    }

    /*
    * Purpose: AFTER_DELETE handler method
    */
    public override void afterDelete() {}

    // @END TRIGGER HANDLERS

}