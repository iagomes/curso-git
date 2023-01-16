public class IntegrationCancelOrderQueueable implements Queueable, Database.AllowsCallouts{
    public Integer index     { get; set; }
    public List<Id> ordIdSet { get; set; }
    public IntegrationCancelOrderQueueable(integer index, List<Id> ordIdSet){
        this.index    = index;
        this.ordIdSet = ordIdSet;

    }
    public void execute(QueueableContext context){

        IntegrationCancelOrderOUT.sendCancelOrderToERP(this.ordIdSet[this.index]);
        
        if(this.index < this.ordIdSet.size() - 1 && Limits.getQueueableJobs() < 50){

            this.index++;

            System.enqueueJob(new IntegrationCancelOrderQueueable(this.index, this.ordIdSet));
        }
    }
}
