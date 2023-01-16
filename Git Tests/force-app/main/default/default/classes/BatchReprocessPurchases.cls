global class BatchReprocessPurchases implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, StatusIntegracao__c, Pedido__r.PedidoPendente__c FROM SolicitacaoCompras__c WHERE Pedido__r.PedidoPendente__c = true AND StatusIntegracao__c = 'Erro']);
    }

    global void execute(Database.BatchableContext BC, List<SolicitacaoCompras__c> scope) {
        IntegrationPurchaseReqOUT.sendPurchaseReqToERP(scope[0].Id);
    }

    global void finish(Database.BatchableContext BC) {}
}
