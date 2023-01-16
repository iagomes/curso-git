global class BatchPendingOrder implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, AccountId, OrderNumber, CreatedById FROM Order WHERE PedidoPendente__c = true AND Status = 'Em digitação']);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope) {
        CustomNotificationType notificationType   = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NotificationPendingOrder'];
        
        for (Order order : scope) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();

            notification.setTitle(System.Label.PendingOrderTitle);
            notification.setBody(System.Label.PendingOrder);

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
        }
    }

    global void finish(Database.BatchableContext BC) {}

}
