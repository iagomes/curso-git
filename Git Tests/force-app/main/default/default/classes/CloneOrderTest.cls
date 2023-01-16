@isTest
global class CloneOrderTest {

    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId(); 
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId(); 

    @TestSetup
    static void makeData(){

       
    }

    @isTest
    public static void sendOrderToERPTest(){        
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        Order ord1 = TestUtility.createOrder(acc);
        ord1.RecordTypeId = MOTHERORDER_RECORDTYPE;
        ord1.Type = 'PedidoVenda';
        insert ord1;
        
        Order ord2 = TestUtility.createOrder(acc);
        ord2.RecordTypeId = DIRECT_ORDER_RECORDTYPE;
        ord2.PedidoPai__c = ord1.Id;
        insert ord2;
        
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
        orderItem2.orderId          = ord2.Id;
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

        List<Order> listOrder = [SELECT Id, Name, AprovadoComercial__c, AprovadoPricing__c FROM Order WHERE PedidoPai__c = null];
        Id ordId;

        for (Order o : listOrder) {
            ordId = o.Id;
        }
        callFlow(ordId);  
    }

    @future(callout=true)
    public static void callFlow(Id ordId) {

        List<Order> listOrder = [SELECT Id, Name, AprovadoComercial__c, AprovadoPricing__c, AccountId FROM Order WHERE Id = :ordId];

        CloneOrder.FlowInputs fInputs = new CloneOrder.FlowInputs();

        for (Order o : listOrder) {
            fInputs.ordId = o.Id;
            fInputs.accId = o.AccountId;
        }
        CloneOrder.flowCloneOrder(new List<CloneOrder.FlowInputs>{fInputs});
    }
}