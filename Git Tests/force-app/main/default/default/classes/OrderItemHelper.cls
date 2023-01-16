public with sharing class OrderItemHelper {

    public static void updateTotalOrParcialWinField(Map<Id, OrderItem> newMapOrderItem, Map<Id, OrderItem> oldMap, boolean isInsertion) {
        try {
            
            Map<String, List<OrderItem>> newMapByOrder = (Map<String, List<OrderItem>>) SObjectUtils.mapObjectsByField(newMapOrderItem.values(), 'OrderId', true);
            List<Order> orderList = getOrderList(newMapByOrder.keySet());
    
            Map<String, List<Order>> orderMapByOpportunity = (Map<String, List<Order>>) SObjectUtils.mapObjectsByField(orderList, 'OpportunityId', true);
            Map<Id, Opportunity> opportunityMap = getMapOpportunity(orderMapByOpportunity.keySet());
    
            List<Order> ordersToUpdate = new List<Order>();
            for (Order order : orderList) {
                Opportunity opp = opportunityMap.get(order.OpportunityId);
                Decimal orderItemsSize = order.quantidadeItens__c;
                if (isInsertion) {
                    orderItemsSize = orderItemsSize + newMapByOrder.get(order.id).size();
                }
                if ((opp != null) && (opp.quoteItems__r != null) && (!opp.quoteItems__r.isEmpty())) {
                    Map<String, List<QuoteItem__c>> mapQuoteItemsByIdIntegrator = (Map<String, List<QuoteItem__c>>) SObjectUtils.mapObjectsByField(opp.quoteItems__r, 'IdPortal__c', true);
                    System.debug(order.QuantidadeItens__c + ' | ' + mapQuoteItemsByIdIntegrator.keySet().size());
                    if ((orderItemsSize > 0) && (mapQuoteItemsByIdIntegrator.keySet().size() == orderItemsSize)) {
                        order.GanhoParcialTotal__c = 'Ganho Total';
                    } else if ((orderItemsSize > 0)) {
                        order.GanhoParcialTotal__c = 'Ganho Parcial';
                    }
                    if ( ! order.RecordType.Name.equals('Pedido pai')) {
                        order.GanhoParcialTotal__c = '-';
                    }
                    ordersToUpdate.add(order);
                }
            }
            OrderItemHandler.disableTrigger();
            update ordersToUpdate;
            OrderItemHandler.enableTrigger();
        } catch (Exception e) {
            ExceptionUtils.debug(e);
        }
    }

    public static void updateTotalOrParcialWinField(Map<Id, OrderItem> newMap) {
        updateTotalOrParcialWinField(newMap, null, true);
    }

    private static Map<Id, Opportunity> getMapOpportunity(Set<String> opportunityId) {
        return new Map<Id, Opportunity>([
            SELECT
                Id, 
                (
                SELECT
                    Id,
                    IdPortal__c
                FROM
                    QuoteItems__r
                )
            FROM
                Opportunity
            WHERE
                Id IN :OpportunityId
        ]);
    }

    private static List<Order> getOrderList(Set<String> orderIdSet) {
        return [
            SELECT
                Id,
                OpportunityId,
                GanhoParcialTotal__c,
                RecordType.Name,
                QuantidadeItens__c
            FROM
                Order
            WHERE
                Id IN :orderIdSet
        ];
    }
}
