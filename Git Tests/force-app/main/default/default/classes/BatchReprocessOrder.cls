global class BatchReprocessOrder implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts{

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Datetime threeDaysAgoDt = Datetime.now().addDays(-3);
        return Database.getQueryLocator([SELECT Id, Status, OrderNumber, MensagemErroIntegracao__c, CreatedDate
                                         FROM Order WHERE Status = 'ErroIntegracao' AND CreatedDate > :threeDaysAgoDt AND
                                         (StatusIntegracao__c = 'Erro integração (Envio ao Protheus)' OR StatusIntegracao__c = 'Erro integração (geração do pedido no Protheus)')
                                         ORDER BY CreatedDate]);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope) {
        IntegrationReprocessOrderOUT.sendReprocessOrderToERP(scope[0]);
    }

    global void finish(Database.BatchableContext BC) {}
}