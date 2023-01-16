public with sharing class IntegrationVansOrderOUTQueueable implements Queueable, Database.AllowsCallouts{
    public Integer index     { get; set; }
    public List<Id> ordIdSet { get; set; }
    public IntegrationVansOrderOUTQueueable(integer index, List<Id> ordIdSet){
        this.index    = index;
        this.ordIdSet = ordIdSet;

    }
    public void execute(QueueableContext context){

        IntegrationVansOrderOUT.sendVansOrderToERP(this.ordIdSet[this.index]);
        
        if(this.index < this.ordIdSet.size() - 1 && Limits.getQueueableJobs() < 50){

            this.index++;

            System.enqueueJob(new IntegrationVansOrderOUTQueueable(this.index, this.ordIdSet));
        }
    }
}
