public class IntegrationContractOUTQueueable implements Queueable, Database.AllowsCallouts{
    public Integer index {get;set;}
    public List<Id> contIdSet {get;set;}
    public IntegrationContractOUTQueueable(integer index, List<Id> contIdSet){
        this.index = index;
        this.contIdSet = contIdSet;

    }
    public void execute(QueueableContext context){

        IntegrationContractOUT.sendContractToERP(this.contIdSet[this.index]);
        
        if(this.index < this.contIdSet.size() - 1 && Limits.getQueueableJobs() < 50){

            this.index++;

            System.enqueueJob(new IntegrationContractOUTQueueable(this.index, this.contIdSet));
        }
    }
}
