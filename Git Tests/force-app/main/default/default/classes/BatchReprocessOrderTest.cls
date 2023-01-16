@isTest
global with sharing class BatchReprocessOrderTest {

    @TestSetup
    static void makeData(){
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaReprocessOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			// Endpoint__c = 'https://use4-cai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
        Account account = TestUtility.createAccPJ();
        insert account;
        Product2 product = TestUtility.createProduct();
        insert product;
        Order order = TestUtility.createOrder(account);
        order.PedidoPendente__c   = true;
        order.Status              = 'ErroIntegracao';
        order.StatusIntegracao__c = 'Erro integração (Envio ao Protheus)';
        insert order;
    }
    
    @isTest
    public static void BatchReprocessOrder() {
        BatchReprocessOrderSchedule batchSchedule = new BatchReprocessOrderSchedule();
        batchSchedule.execute(null);
        BatchReprocessOrderSchedule.scheduleBatch();
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        public MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            List<Order> listOrder = [SELECT Id, Name, OrderNumber, AprovadoComercial__c, AprovadoPricing__c FROM Order];
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"PedidoIntegrador": "'+listOrder[0].OrderNumber+'"}');
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
        List<Order> listOrder = [SELECT Id FROM Order];
        Order ord;

        for (Order o : listOrder) {
            ord = o;
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationReprocessOrderOUT.sendReprocessOrder(new List<Id>{listOrder[0].id});  
        Test.stopTest();
    }
}