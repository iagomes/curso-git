public class IntegrationAutomaticLabOrderOUTQueueable implements Queueable, Database.AllowsCallouts {
    public Integer index {get;set;}
    public Id orderId {get;set;}
    public String integrationLogName {get;set;}
    public IntegrationAutomaticLabOrderOUTQueueable(integer index, Id orderId, String integrationLogName) {
        this.index = index;
        this.orderId = orderId;
        this.integrationLogName = integrationLogName;
    }

    public void execute(QueueableContext context) {
        IntegrationAutomaticLabOrderOUT.sendAutomaticLabOrderToERP(this.orderId, integrationLogName);
        // System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>{this.orderId}));
    }
}
