trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete) {
    OpportunityTH handler = new OpportunityTH(
        Trigger.operationType,
        Trigger.new, 
        Trigger.old,
        Trigger.newMap, 
        Trigger.oldMap
    );
    
    if (OpportunityTH.isTriggerEnabled())
        handler.execute();

}