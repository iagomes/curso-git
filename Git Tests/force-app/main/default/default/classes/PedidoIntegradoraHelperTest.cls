@isTest
public with sharing class PedidoIntegradoraHelperTest {
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
        pedIntegradora.Pedido__c            = ord1.Id;

        insert pedIntegradora;

        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaLaboratoryOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
       
    }

    @isTest
    public static void createPedidoIntegradoraTest() {
        PedidoIntegradora__c prod = new PedidoIntegradora__c(
            CodigoIntegradora__c = '12345'
        );
        insert prod;

        prod.StatusAprovacao__c = 'Aprovado';
        
        update prod;

        prod.SolicitacaoAprovada__c = true;
        prod.RejeicaoProcesso__c = true;

        update prod;

        PedidoIntegradoraHelper.FlowInputs fInputs = new PedidoIntegradoraHelper.FlowInputs();
        fInputs.labId = prod.id;
        fInputs.isApprove = true;
        
        PedidoIntegradoraHelper.ApproveRejectLaboratoryOrderThisUser(new List<PedidoIntegradoraHelper.FlowInputs>{fInputs});
    }
    
    @isTest
    public static void PedidoIntegradoraTest() {
        System.debug(PedidoIntegradoraHandler.disableTrigger());
        System.debug(PedidoIntegradoraHandler.enableTrigger());
        System.assertEquals(false, PedidoIntegradoraHandler.disableTrigger());
        System.assertEquals(true, PedidoIntegradoraHandler.enableTrigger());
    }
}
