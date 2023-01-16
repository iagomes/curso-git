global class BatchExpiredContractItem implements Database.Batchable<sObject>, Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT 
                Id, 
                VigenciaFinal__c
            FROM ItemContrato__c
            WHERE VigenciaFinal__c < TODAY
            AND Status__c != 'Expirado'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<ItemContrato__c> scope) {
        List<ItemContrato__c> contractItemList = new List<ItemContrato__c>();
        for (ItemContrato__c contractItem : scope) {
            contractItemList.add(new ItemContrato__c(Id = contractItem.Id, Status__c = 'Expirado'));
        }
        if(!contractItemList.isEmpty()) {
            ContractHandler.disableTrigger();
            ContractItemHandler.disableTrigger();
            update contractItemList;
            ContractHandler.enableTrigger();
            ContractItemHandler.enableTrigger();
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
