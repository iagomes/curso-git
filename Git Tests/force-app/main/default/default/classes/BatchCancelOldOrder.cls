global class BatchCancelOldOrder implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Datetime threeDaysAgoDt = Datetime.now().addDays(-3);
        return Database.getQueryLocator(
            [SELECT Id, AccountId, OrderNumber, CreatedById, Status, StatusIntegracao__c, ErroIntegracaoCancelamento__c, ErroIntegracaoAprovacao__c,
                    ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, MensagemErroIntegracao__c FROM Order 
             WHERE Status = 'ErroIntegracao' AND CreatedDate < :threeDaysAgoDt AND
             (StatusIntegracao__c = 'Erro integração (Envio ao Protheus)' OR StatusIntegracao__c = 'Erro integração (geração do pedido no Protheus)')]);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope) {
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NotificationCancelOldOrder'];
        List<Order> ordToUpdateList = new List<Order>();
        if (!Test.isRunningTest())
            IntegrationCancelOrderOUT.sendCancelOrderToERP(scope[0].Id);
        
        for (Order order : scope) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Pedido '+ order.OrderNumber + ' cancelado');
            notification.setBody('O pedido '+ order.OrderNumber + ' foi cancelado pois não foi possível enviá-lo ao Protheus por 3 dias.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(order.Id);
            try {
                Set<String> recipientsIds = new Set<String>();
                recipientsIds.add(order.CreatedById);
                notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug(System.Label.NotificationOrderError + e.getMessage());
            }
            // order.Status                    = 'Cancelado';
            // order.StatusIntegracao__c       = null;
            // order.MensagemErroIntegracao__c = null;
            // OrderHelper.clearErrors(order);

            // ordToUpdateList.add(order);
        }
    }

    global void finish(Database.BatchableContext BC) {}

}
