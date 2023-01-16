trigger ContentVersion on ContentVersion (before insert, before update, after insert, after update) {
    ContentVersionHandler handler = new ContentVersionHandler(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (ContentVersionHandler.isTriggerEnabled())
        handler.execute();
}