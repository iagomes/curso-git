public class IntegrationLaboratoryOrderQueueable implements Queueable, Database.AllowsCallouts{
    public Integer index {get;set;}
    public String partialInvoice {get;set;}
    public List<Id> labIdSet {get;set;}
    public IntegrationLaboratoryOrderQueueable(integer index, List<Id> labIdSet, String partialInvoice){
        this.index = index;
        this.labIdSet = labIdSet;
        this.partialInvoice = partialInvoice;
    }
    public void execute(QueueableContext context){

        IntegrationLaboratoryOrderOUT.sendLaboratoryToERP(this.labIdSet[this.index], partialInvoice);        
        if(this.index < this.labIdSet.size() - 1 && Limits.getQueueableJobs() < 50){
            this.index++;
            System.enqueueJob(new IntegrationLaboratoryOrderQueueable(this.index, this.labIdSet, partialInvoice));
        }
    }
}