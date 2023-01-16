@isTest
global class IntegrationApprovalOrderOUTTest {

    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId(); 
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId(); 

    @TestSetup
    static void makeData(){
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaApprovalOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Liberacao-Pedido',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;

        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        Order ord1 = TestUtility.createOrder(acc);
        ord1.RecordTypeId = MOTHERORDER_RECORDTYPE;
        ord1.AprovadoComercial__c = false;
        ord1.AprovadoPricing__c   = false;
        ord1.RejeicaoProcesso__c  = false;
        insert ord1;
        
        Order ord2 = TestUtility.createOrder(acc);
        ord2.RecordTypeId = DIRECT_ORDER_RECORDTYPE;
        ord2.AprovadoComercial__c = false;
        ord2.AprovadoPricing__c   = false;
        ord2.RejeicaoProcesso__c  = false;
        ord2.PedidoPai__c = ord1.Id;
        insert ord2;

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
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId          = ord2.Id;
        orderItem2.Product2Id       = prod.Id;
        orderItem2.pricebookEntryId = pricebookEntryId;
        orderItem2.Quantity         = 5;
        orderItem2.UnitPrice        = 50;
        orderItem2.PrecoTotal__c    = 50;
        orderItem2.Lote__c          = '10';
        orderItem2.TipoOperacao__c  = '11';
        orderItem2.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem2);
        insert listOrderItem;

    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        public MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            List<Order> listOrder = [SELECT Id, Name, OrderNumber, AprovadoComercial__c, AprovadoPricing__c FROM Order WHERE PedidoPai__c != null];
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CgcEmp": "52202744000192","NumPedido": "012345","NumPedInte": "'+listOrder[0].OrderNumber+'","liberado": true}');
            res.setStatusCode(this.isSuccess? 201 : 500);

            if (res.getStatusCode() == 201){
                res.setBody('{"result": "Pedido incluido na fila de processamento!!","incluido": true}');
            } else {
                res.setBody('{"result": "Pedido não incluido na fila de processamento!!","incluido": false}');
            }
            return res;
        }
    }

    @isTest
    public static void sendOrderToERPTest(){        
        List<Order> listOrder = [SELECT Id, Name, AprovadoComercial__c, AprovadoPricing__c FROM Order WHERE PedidoPai__c = null];
        Order ord;

        for (Order o : listOrder) {
            ord = o;
        }
        ord.AprovadoComercial__c = true;
        ord.AprovadoPricing__c   = true;
        ord.RejeicaoProcesso__c  = true;
        update ord;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationApprovalOrderOUT.sendApprovalOrderToERP(listOrder[0].id);  
        Test.stopTest();

        System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>{listOrder[0].id}));
    }
}