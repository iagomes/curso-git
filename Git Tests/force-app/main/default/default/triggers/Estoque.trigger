trigger Estoque on Estoque__c (before update) {
    System.debug('Estoque Trigger.operationType => ' + Trigger.operationType);

    if (EstoqueHandler.isTriggerEnabled()) {
        EstoqueHandler handler = new EstoqueHandler(
            Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
        );

        switch on Trigger.operationType {
            when BEFORE_UPDATE { handler.beforeUpdate(); }
        }
    }
}