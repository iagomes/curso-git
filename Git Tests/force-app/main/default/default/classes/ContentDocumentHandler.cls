public with sharing class ContentDocumentHandler {
    public List<ContentDocument> oldRecords {get; set;}
    public List<ContentDocument> newRecords {get; set;}
    public Map<Id, ContentDocument> oldMap  {get; set;}
    public Map<Id, ContentDocument> newMap  {get; set;}

    public ContentDocumentHandler(List<ContentDocument> oldRecords, List<ContentDocument> newRecords, Map<Id, ContentDocument> oldMap, Map<Id, ContentDocument> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
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

    public void beforeDelete() {
        ContentDocumentHelper.deletePaymentAttachment(this.oldRecords);
    }
}
