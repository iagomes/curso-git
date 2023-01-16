trigger Territory2 on Territory2 (before insert) {
    if (Territory2Handler.isTriggerEnabled()) {
        Territory2Handler handler = new Territory2Handler(
            Trigger.old, 
            Trigger.new, 
            Trigger.oldMap, 
            Trigger.newMap
        );

        switch on Trigger.operationType {
            when BEFORE_INSERT { handler.beforeInsert(); }
        }
    }
}