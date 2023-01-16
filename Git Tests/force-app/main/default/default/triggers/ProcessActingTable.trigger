trigger ProcessActingTable on ProcessActingTable__e (after insert) {
    ProcessActingTableHandler handler = new ProcessActingTableHandler(
        Trigger.operationType,
        Trigger.new
    );
    
    if (ProcessActingTableHandler.isTriggerEnabled())
        handler.execute();
}