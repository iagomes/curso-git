public with sharing class Territory2Handler {
    private static Boolean runTrigger;
    static{
	    runTrigger = true;
    }

    public List<Territory2> oldRecords {get; set;}
    public List<Territory2> newRecords {get; set;}
    public Map<Id, Territory2> oldMap  {get; set;}
    public Map<Id, Territory2> newMap  {get; set;}

    public Territory2Handler(
        List<Territory2> oldRecords, 
        List<Territory2> newRecords, 
        Map<Id, Territory2> oldMap, 
        Map<Id, Territory2> newMap
    ) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
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
    
    // BEFORE_INSERT context
    public void beforeInsert() {
        Territory2Helper.associateParentTerritories(this.newRecords);
    }
}
