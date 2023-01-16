@isTest
public with sharing class ShippingTrackingControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        List<Order> listOrder = new List<Order>();
        Order ord1 = TestUtility.createOrder(acc);
        ord1.TipoFrete__c = 'CIF';
        listOrder.add(ord1);

        insert listOrder;

        Id pricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id][0].Id;

        List<OrderItem> listOrderItem = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId          = ord1.Id;
        orderItem1.Product2Id       = prod.Id;
        orderItem1.pricebookEntryId = pricebookEntryId;
        orderItem1.Quantity         = 5;
        orderItem1.UnitPrice        = 50;
        orderItem1.PrecoTotal__c    = 50;
        orderItem1.Lote__c          = '10';
        orderItem1.TipoOperacao__c  = '11';
        orderItem1.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem1);

        insert listOrderItem;
    }

    @isTest
    public static void ShippingTrackingControllerTest() {
        List<Order> lOrder = [SELECT Id, StatusEntrega__c FROM Order LIMIT 1];

        lOrder[0].StatusEntrega__c = 'Link de rastreamento disponível';

        update lOrder;

        ShippingTrackingController.getDeliveryHistory(lOrder[0].Id);

        ShippingTrackingController.getDeliveryURL(lOrder[0].Id);
        ShippingTrackingController.getStatusType('Entregue');
        ShippingTrackingController.getStatusType('Não entregue');
        ShippingTrackingController.getStatusType('Teste');
    }
}
