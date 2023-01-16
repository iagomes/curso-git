@isTest
global with sharing class IntegrationAutomaticLabOrderOUTTest {
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
        
        Order ord2 = TestUtility.createOrder(acc);        
        ord2.DatasParcelas__c = '02/09/2021, 07/09/2021, 14/09/2021';
        listOrder.add(ord2);

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

        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaAutomaticLabOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-AcaoComercialSincrono',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
    }    

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        public MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CgcCli": "","CgcEmp": "","TpInteg": "","laboratorio": "","regra": "","PedidoIntegrador": "","CondicaoPagamento": "","TabelaPreco": "","TipoFrete": "CIF","observacoes": "","ObservacoesNF": "","itens": [{"produto": "","TpOper": "","ShelfLife": "AAAAMMDD","preco": 1,"lote": "","quantidade": 0.00}]}');
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
        List<Order> listOrder = [SELECT Id, Name FROM Order LIMIT 2];

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationAutomaticLabOrderOUT.sendAutomaticLabOrderToERP(listOrder[0].id);         

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        IntegrationAutomaticLabOrderOUT.sendAutomaticLabOrderToERP(listOrder[1].id);      

        Test.stopTest();    
        
        System.enqueueJob(new IntegrationAutLabOrderOUTQueueable(0, new List<Id>{listOrder[0].id}));
    }
}
