trigger Contact on Contact (before insert, before update) {
    System.debug('Contact Trigger.operationType => ' + Trigger.operationType);
    
    if (ContactHandler.isTriggerEnabled()) {
        ContactHandler handler = new ContactHandler(
            Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
        );

        switch on Trigger.operationType {
            when BEFORE_INSERT { handler.beforeInsert(); }
            when BEFORE_UPDATE { handler.beforeUpdate(); }
        }
    }
}