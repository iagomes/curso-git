@isTest
public with sharing class IntegrationOrderINTest {
     
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        acc.ExternalId__c = '04585497000108';

        insert acc;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();

        insert condPag;

        List<Product2> listProduct = new List<Product2>();
        Product2 prod = TestUtility.createProduct();
        prod.ExternalId__c = 'prod001';
        listProduct.add(prod);
        Product2 prod2 = TestUtility.createProduct();
        prod.ExternalId__c = 'prod002';
        listProduct.add(prod2);
        ProductHandler.disableTrigger();
        insert listProduct;

        List<PricebookEntry> listPricebookEntry = new List<PricebookEntry>();
        PricebookEntry pbEntry = TestUtility.createPricebookEntry(Test.getStandardPricebookId(), prod.id);
        pbEntry.ExternalId__c = 'pbEntry001';
        listPricebookEntry.add(pbEntry);
        PricebookEntry pbEntry2 = TestUtility.createPricebookEntry(Test.getStandardPricebookId(), prod2.id);
        pbEntry2.ExternalId__c = 'pbEntry002';
        listPricebookEntry.add(pbEntry2);

        insert listPricebookEntry;
    }

    @isTest
    static void upsertAccountTest() {
        
        TemplateDataIntegrationFields.ContadorINData contadorData = new TemplateDataIntegrationFields.ContadorINData();
        List<TemplateDataIntegrationFields.OrderINData> listOrdData = new List<TemplateDataIntegrationFields.OrderINData>();
        TemplateDataIntegrationFields.OrderINData ordData = new TemplateDataIntegrationFields.OrderINData();

        ordData.CodigoPedido      = 'ped001';
        ordData.DataEmissao       = Date.valueOf('2021-04-14');
        ordData.DataEntrega       = Date.today();
        ordData.Conta             = '04585497000108';
        ordData.EnderecoEntrega   = 'Av. Brasil, 212 - SP';
        ordData.TipoFrete         = 'CIF';
        ordData.TipoOperacao      = 'Venda Direta';
        ordData.CondicaoPagamento = 'condPag001';
        ordData.ValorTotal        = 120000;
        ordData.Margem            = 100;
        ordData.NomePaciente      = 'Cleber Santos';
        ordData.OrigemPedido      = 'Histórico';
        ordData.Status            = 'Faturado (Histórico)';
        ordData.StatusIntegracao  = 'Integrado';
        ordData.GeraBoleto        = 'Não';
        ordData.Observacao        = 'Descrição de Teste';
        ordData.CanalEntrada      = 'WHATSAPP';

        List<TemplateDataIntegrationFields.OrderItemINData> listOrderItemData = new List<TemplateDataIntegrationFields.OrderItemINData>();
        TemplateDataIntegrationFields.OrderItemINData orderItem = new TemplateDataIntegrationFields.OrderItemINData();

        orderItem.CodigoPedido = 'ped001';
        orderItem.CodigoItemPedido = 'ordItem001';
        orderItem.DescricaoProduto = 'prod001'; // lookup (product2)
        orderItem.Quantidade = 100;
        orderItem.PrecoTabela = 100;
        orderItem.PrecoUnitario = 10;
        orderItem.Margem = 10;
        orderItem.Vendedor = '001';
        orderItem.PrecoTotal = 5000;
        orderItem.EntradaTabelaPreco = 'pbEntry001'; // lookup (pricebook2)

        listOrderItemData.add(orderItem);

        TemplateDataIntegrationFields.OrderItemINData orderItem2 = new TemplateDataIntegrationFields.OrderItemINData();

        orderItem2.CodigoPedido = 'ped001';
        orderItem2.CodigoItemPedido = 'ordItem002';
        orderItem2.DescricaoProduto = 'prod002';
        orderItem2.Quantidade = 150;
        orderItem2.PrecoTabela = 100;
        orderItem2.PrecoUnitario = 10;
        orderItem2.Margem = 10;
        orderItem2.Vendedor = '002';
        orderItem2.PrecoTotal = 7000;
        orderItem2.EntradaTabelaPreco = 'pbEntry002';
        
        listOrderItemData.add(orderItem2);
        
        List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData> listSharedUsersData = new List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>();
        TemplateDataIntegrationFields.UsuariosCompartilhadosINData sharedUsers = new TemplateDataIntegrationFields.UsuariosCompartilhadosINData();

        sharedUsers.CodigoPedido = 'ped001';
        sharedUsers.Vendedor = '001';
        listSharedUsersData.add(sharedUsers);
        
        TemplateDataIntegrationFields.UsuariosCompartilhadosINData sharedUsers2 = new TemplateDataIntegrationFields.UsuariosCompartilhadosINData();

        sharedUsers2.CodigoPedido = 'ped002';
        sharedUsers2.Vendedor = '002';
        listSharedUsersData.add(sharedUsers2);

        ordData.ItensPedido = listOrderItemData;
        ordData.Vendedor = listSharedUsersData;
        
        listOrdData.add(ordData);

        contadorData.Contador = '1';
        contadorData.Pedidos = listOrdData;

        IntegrationOrderIN.upsertOrder(contadorData);
                
        System.assertEquals(false, IntegrationOrderIN.upsertOrder(contadorData).response[0].status);
    }
}