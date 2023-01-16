trigger ContentDocument on ContentDocument (before delete) {
    System.debug('ContentDocument Trigger.operationType => ' + Trigger.operationType);
    
    if (ContentDocumentHandler.isTriggerEnabled()) {
        ContentDocumentHandler handler = new ContentDocumentHandler(
            Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
        );

        switch on Trigger.operationType {
            when BEFORE_DELETE {
                handler.beforeDelete();
            }
        }
    }
}