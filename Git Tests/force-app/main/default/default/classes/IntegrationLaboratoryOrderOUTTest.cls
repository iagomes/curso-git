@isTest
global class IntegrationLaboratoryOrderOUTTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        List<Order> listOrder = new List<Order>();
        Order ord1 = TestUtility.createOrder(acc);
        ord1.TipoFrete__c = 'CIF';
        ord1.CodigoIntegradora__c = '1234';
        listOrder.add(ord1);
        
        Order ord2 = TestUtility.createOrder(acc);
        ord2.CodigoIntegradora__c = '12345';
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
        orderItem1.Laboratorio__c   = 'FAB';
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
        orderItem2.Laboratorio__c   = 'FAB';
        orderItem2.cnpjCD__c        = '52202744000192';
        listOrderItem.add(orderItem2);

        insert listOrderItem;

        PedidoIntegradora__c pedIntegradora = new PedidoIntegradora__c();
        pedIntegradora.CodigoIntegradora__c = '1234';
        pedIntegradora.CNPJCliente__c       = acc.CNPJ__c;
        pedIntegradora.TipoIntegradora__c   = '20';
        pedIntegradora.Laboratorio__c       = 'FAB';
        pedIntegradora.Inconsistencias__c   = null;
        pedIntegradora.StatusAprovacao__c   = 'Aprovado';

        insert pedIntegradora;

        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaLaboratoryOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-AcaoComercialSincrono',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);

        Integracoes__c integration2 =  new Integracoes__c(
			Name        = 'ElfaVansOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-AcaoComercialSincrono',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert new List<Integracoes__c>{integration, integration2};
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
        List<PedidoIntegradora__c> listPedIntegradora = [SELECT Id, Name,TipoIntegradora__c,Laboratorio__c,CodigoIntegradora__c,StatusAprovacao__c,Pedido__r.CondicaoPagamento__r.ExternalId__c,Pedido__r.MensagemNF__c FROM PedidoIntegradora__c LIMIT 1];

        IntegrationLaboratoryOrderOUT.LaboratoryRequest labReq;
        labReq = new IntegrationLaboratoryOrderOUT.LaboratoryRequest(listPedIntegradora[0],'');

        Test.startTest();

        List<IntegrationLaboratoryOrderOUT.FlowInputs> listFInputs = new List<IntegrationLaboratoryOrderOUT.FlowInputs>();
        IntegrationLaboratoryOrderOUT.FlowInputs fInputs = new IntegrationLaboratoryOrderOUT.FlowInputs();
        fInputs.labId          = listPedIntegradora[0].id;
        fInputs.isApprove      = true;
        fInputs.partialInvoice = 'S';

        listFInputs.add(fInputs);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationLaboratoryOrderOUT.ApproveRejectLaboratoryOrder(listFInputs);
        IntegrationLaboratoryOrderOUT.sendLaboratoryToERP(listPedIntegradora[0].id,'');
        
        Test.stopTest();    

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        IntegrationLaboratoryOrderOUT.ApproveRejectLaboratoryOrder(listFInputs);
        
        //System.enqueueJob(new IntegrationOrderOUTQueueable(0, new List<Id>{listOrder[0].id}));
    }
}