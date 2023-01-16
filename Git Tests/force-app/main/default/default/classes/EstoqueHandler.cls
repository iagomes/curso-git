public with sharing class EstoqueHandler {
    public EstoqueHandler(List<Estoque__c> oldRecords, List<Estoque__c> newRecords, Map<Id, Estoque__c> oldMap, Map<Id, Estoque__c> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    private static Boolean runTrigger;
    static{
	    runTrigger = true;
    }

    public List<Estoque__c> oldRecords {get; set;}
    public List<Estoque__c> newRecords {get; set;}
    public Map<Id, Estoque__c> oldMap  {get; set;}
    public Map<Id, Estoque__c> newMap  {get; set;}

    public static Boolean isTriggerEnabled(){ 
        return runTrigger; 
    }
    public static Boolean enableTrigger(){ 
        return runTrigger = true; 
    }
    public static Boolean disableTrigger(){ 
        return runTrigger = false; 
    }

    // BEFORE_UPDATE context
    public void beforeUpdate() {
        EstoqueHelper.stockNotification(this.newRecords, this.oldMap);
    }
}
