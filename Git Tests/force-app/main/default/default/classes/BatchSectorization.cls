global class BatchSectorization implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM Setorizacao__c WHERE DataFinal__c < TODAY]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {        
        List<Setorizacao__c> listSetorizacao = (List<Setorizacao__c>) scope;
        delete listSetorizacao;

    }

    global void finish(Database.BatchableContext BC) {}
}
