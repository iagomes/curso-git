trigger EmailMessage on EmailMessage (before insert) {
    EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (EmailMessageTriggerHandler.isTriggerEnabled())
        handler.execute();
}