public with sharing class EstoqueHelper {
    public EstoqueHelper() {}

    public static void stockNotification(List<Estoque__c> newRecords, Map<Id, Estoque__c> oldMapRecords) {
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'StockNotification'];
        GeneralParameters__c parameters = GeneralParameters__c.getValues('Parametro geral');
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        Map<OrderItem, String> mapOrderItemToStock = new Map<OrderItem, String>();
        Map<Id, Set<String>> recipientsToOrder = new Map<Id, Set<String>>();
        Set<String> recipientsIds = new Set<String>();
        Set<String> cdNameList = new Set<String>();
        Set<Id> productIdList = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> setOrderItemNotificationUpdate = new Set<Id>();


        Datetime datetimeCompare = datetime.now().addHours(-parameters.StockNotification__c.intValue());

        for (Estoque__c newStock : newRecords) {
            productIdList.add(newStock.NomeProduto__c);
            cdNameList.add(newStock.NomeCD__c);
        }

        List<OrderItem> orderItemList = [SELECT Id, OrderId, Order.OrderNumber, OrderItemNumber, Quantity, LastNotification__c, ItemPendente__c, Product2Id, Product2.Name, CreatedById, CentroDistribuicao__c, CNPJCD__c FROM OrderItem WHERE Product2Id IN: productIdList AND CentroDistribuicao__c IN: cdNameList AND ItemPendente__c = true AND Order.Status = 'Em digitação'];
        List<OrderItem> orderItemUpdateList = new List<OrderItem>();
        List<OrderItem> orderItemNotificationUpdate = new List<OrderItem>();
        
        for (Estoque__c stock : newRecords) {
            Estoque__c oldStock = oldMapRecords.get(stock.Id);
            List<OrderItem> orderItemProductList = new List<OrderItem>();
            for (OrderItem orderItem : orderItemList) {
                if (stock.NomeProduto__c == orderItem.Product2Id && stock.CNPJCD__c == orderItem.CNPJCD__c) {
                    if (stock.Saldo__c == 0) {
                        System.debug('NÃO VAI NOTIFICAR');
                        if (orderItem.LastNotification__c != null) {
                            orderItem.LastNotification__c = null;
                            if (!setOrderItemNotificationUpdate.contains(orderItem.id)) {
                                orderItemNotificationUpdate.add(orderItem);
                                setOrderItemNotificationUpdate.add(orderItem.id);
                            }
                        }
                    } else {
                        if (orderItem.LastNotification__c == null || orderItem.LastNotification__c <= datetimeCompare) {
                            System.debug('VAI NOTIFICAR');
                            orderItem.LastNotification__c = datetime.now();
                            if (!setOrderItemNotificationUpdate.contains(orderItem.id)) {
                                orderItemNotificationUpdate.add(orderItem);
                                setOrderItemNotificationUpdate.add(orderItem.id);
                            }
                            mapOrderItemToStock.put(orderItem, String.valueOf(stock.Saldo__c));
                            orderIds.add(orderItem.OrderId);
                            if (!recipientsToOrder.containsKey(orderItem.OrderId)) {
                                recipientsToOrder.put(orderItem.OrderId, new Set<String>{});
                            }
                            recipientsToOrder.get(orderItem.OrderId).add(orderItem.CreatedById);
                        } else if (stock.Saldo__c >= orderItem.Quantity) {
                            if (oldStock.Saldo__c < orderItem.Quantity) {
                                System.debug('VAI NOTIFICAR POR QUE CHEGOU MAIS ESTOQUE');
                                orderItem.LastNotification__c = datetime.now();
                                if (!setOrderItemNotificationUpdate.contains(orderItem.id)) {
                                    orderItemNotificationUpdate.add(orderItem);
                                    setOrderItemNotificationUpdate.add(orderItem.id);
                                }
                                mapOrderItemToStock.put(orderItem, String.valueOf(stock.Saldo__c));
                                orderIds.add(orderItem.OrderId);
                                if (!recipientsToOrder.containsKey(orderItem.OrderId)) {
                                    recipientsToOrder.put(orderItem.OrderId, new Set<String>{});
                                }
                                recipientsToOrder.get(orderItem.OrderId).add(orderItem.CreatedById);
                            } 
                        }
                    }
                }
            }
        }

        Map<Id, Order> orderMap = new Map<Id, Order>();
        for (Order order : [SELECT Id, Account.Name FROM Order WHERE Id IN: orderIds]) {
            orderMap.put(order.Id, order);
        }

        if (!orderItemNotificationUpdate.isEmpty()) {
            update orderItemNotificationUpdate;
        }
        if (!mapOrderItemToStock.isEmpty()) {
            System.debug('ENVIANDO ...');
            for (orderItem orderItem : mapOrderItemToStock.keySet()) {                
                notification.setTitle('Notificação de estoque.');
                notification.setBody('Estoque do produto ' + orderItem.Product2.Name + '\nCD => ' + orderItem.CentroDistribuicao__c + '\nEstoque novo => ' + Integer.valueOf(mapOrderItemToStock.get(orderItem)) + '\nPedido => ' + orderItem.Order.OrderNumber + '\nCliente => ' + orderMap.get(orderItem.OrderId).Account.Name);
    
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(orderItem.OrderId);
    
                try {
                    notification.send(recipientsToOrder.get(orderItem.OrderId));
                }
                catch (Exception e) {
                    System.debug('Erro ao enviar notificação de estoque ' + e.getMessage());
                }
            }
        }
    }
}
