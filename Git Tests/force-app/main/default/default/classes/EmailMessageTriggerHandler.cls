public with sharing class EmailMessageTriggerHandler extends TriggerHandler {
    
    public EmailMessageTriggerHandler(System.TriggerOperation operation, List<EmailMessage> newRecordList, List<EmailMessage> oldRecordList, Map<Id, EmailMessage> newMap, Map<Id, EmailMessage> oldMap) {
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
    
    public override void beforeInsert() {
        
        Set<Id> caseIds = new Set<Id>();
        for (EmailMessage message : (List<EmailMessage>)newRecordList) {
            
            if (String.isNotBlank(message.ParentId) && message.ParentId.getSObjectType() == Case.sobjectType) 
            {
                caseIds.add(message.ParentId);    
            }
        }
        
        if (!caseIds.isEmpty()) {
            EmailMessageHelper.setCaseNumberInSubject(newRecordList, caseIds);   
        }
    }
    
    public override void afterInsert() {}
    
    public override void beforeDelete() {}
    
    public override void afterDelete() {}
    
    public override void beforeUpdate() {}
    
    public override void afterUpdate() {}
    
}