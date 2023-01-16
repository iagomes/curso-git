public class IntegrationPortalQuoteOUTQueueable implements Queueable, Database.AllowsCallouts{
    
    public Integer index {get;set;}
    public List<Id> oppIdSet {get;set;}

    
    public IntegrationPortalQuoteOUTQueueable(integer index, List<Id> oppIdSet){
        this.index = index;
        this.oppIdSet = oppIdSet;

    }

    public void execute(QueueableContext context){

        IntegrationPortalQuoteOUT.send(this.oppIdSet[this.index]);
        
        if(this.index < this.oppIdSet.size() - 1 && Limits.getQueueableJobs() < 50){

            this.index++;

            System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(this.index, this.oppIdSet));
        }
    }
}