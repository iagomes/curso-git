@isTest
public with sharing class MixClientControllerTest {
    
    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId();

    @isTest
    public static void createStandardEntriesTest() {        
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Fornecedor__c provider = new Fornecedor__c(
            Name = 'Provider Test'
        );
        insert provider;

        Product2 prod = TestUtility.createProduct();
        prod.ProductCode = '123';
        prod.Fornecedor__c = provider.id;
        insert prod;

        Order ord1 = TestUtility.createOrder(acc);
        ord1.RecordTypeId = MOTHERORDER_RECORDTYPE;
        ord1.Status = 'Faturado';
        ord1.Type = 'PedidoVenda';
        insert ord1;
        
        Id pricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod.Id][0].Id;

        List<OrderItem> listOrderItem = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId          = ord1.Id;
        orderItem1.Product2Id       = prod.Id;
        orderItem1.pricebookEntryId = pricebookEntryId;
        orderItem1.Quantity         = 5;
        orderItem1.PrecoTotal__c    = 50;
        orderItem1.UnitPrice        = 50;
        orderItem1.Lote__c          = '10';
        orderItem1.TipoOperacao__c  = '11';
        orderItem1.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem1);
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId          = ord1.Id;
        orderItem2.Product2Id       = prod.Id;
        orderItem2.pricebookEntryId = pricebookEntryId;
        orderItem2.Quantity         = 5;
        orderItem2.PrecoTotal__c    = 50;
        orderItem2.UnitPrice        = 50;
        orderItem2.Lote__c          = '10';
        orderItem2.TipoOperacao__c  = '11';
        orderItem2.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem2);
        insert listOrderItem;

        MixClientController.getClientProdData(acc.Id, 0, '', '');
        MixClientController.getClientOrderData(acc.Id, prod.id);
    }
}
