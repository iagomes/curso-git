public without sharing class ContactHandler {
    private static Boolean runTrigger;
    static{
	    runTrigger = true;
    }

    public List<Contact> oldRecords {get; set;}
    public List<Contact> newRecords {get; set;}
    public Map<Id, Contact> oldMap  {get; set;}
    public Map<Id, Contact> newMap  {get; set;}

    public ContactHandler(List<Contact> oldRecords, List<Contact> newRecords, Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {
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
        ContactHelper.formatNumber(this.newRecords);
        ContactHelper.changePriorityContactInsert(this.newRecords);
    }
    // BEFORE_UPDATE context
    public void beforeUpdate() {
        ContactHelper.updateNumber(this.newRecords);
        ContactHelper.changePriorityContactUpdate(this.newRecords, this.newMap);
    }
}