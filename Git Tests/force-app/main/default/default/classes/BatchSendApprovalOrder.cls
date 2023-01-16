global class BatchSendApprovalOrder implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    
    public BatchSendApprovalOrder(Set<Id> orderIdSet) {
        ordIdSet.addAll(orderIdSet);
    }
    
    public Set<Id> ordIdSet = new Set<Id>();

    global static void run(Set<Id> orderIdSet){
        Database.executeBatch(new BatchSendApprovalOrder(orderIdSet), 1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        return Database.getQueryLocator('SELECT Id FROM Order WHERE Id IN :ordIdSet');     
    }    

    global void execute(Database.batchableContext bc, List<Order> scope){
        Id ordId = null;
        for (Order o : scope){
            ordId = o.id;
        }
        if (ordId != null){
            IntegrationApprovalOrderOUT.sendApprovalOrderToERP(ordId);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
		
	}
}