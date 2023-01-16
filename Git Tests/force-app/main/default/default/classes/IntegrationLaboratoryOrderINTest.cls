@isTest
public with sharing class IntegrationLaboratoryOrderINTest {
     
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        acc.ExternalId__c = '04585497000108';

        insert acc;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();

        insert condPag;

        List<Product2> listProduct = new List<Product2>();
        Product2 prod = TestUtility.createProduct();
        prod.ProductCode = 'prod001';
        prod.EanProduto__c = 'prod001';
        listProduct.add(prod);
        Product2 prod2 = TestUtility.createProduct();
        prod.ProductCode = 'prod002';
        prod.EanProduto__c = 'prod002';
        listProduct.add(prod2);
        ProductHandler.disableTrigger();
        insert listProduct;

        List<PricebookEntry> listPricebookEntry = new List<PricebookEntry>();
        PricebookEntry pbEntry = TestUtility.createPricebookEntry(Test.getStandardPricebookId(), prod.id);
        pbEntry.ExternalId__c = 'pbEntry001';
        listPricebookEntry.add(pbEntry);

        insert listPricebookEntry;

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

        Integracoes__c integration3 =  new Integracoes__c(
			Name        = 'ElfaAutomaticLabOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/p_Protheus_UpdOrder',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert new List<Integracoes__c>{integration, integration2, integration3};
    }

    @isTest
    static void upsertAccountTest() {
        
        TemplateDataIntegrationFields.LabOrderINData ordData = new TemplateDataIntegrationFields.LabOrderINData();

        ordData.CgcCli            = '04585497000108';
        ordData.PedidoIntegrador  = '123';
        ordData.TpInteg           = 'FID';
        ordData.Laboratorio       = 'AZI';
        ordData.Tabela            = '';
        ordData.Inconsistencias   = null;
        ordData.CondicaoPagamento = 'condPag001';
        ordData.Obs_NF            = '1234';

        TemplateDataIntegrationFields.LabOrderINData ordData2 = new TemplateDataIntegrationFields.LabOrderINData();

        ordData2.CgcCli            = '04585497000108';
        ordData2.PedidoIntegrador  = '1234';
        ordData2.TpInteg           = 'FID';
        ordData2.Laboratorio       = 'AZI';
        ordData2.Tabela            = '';
        ordData2.Inconsistencias   = 'Pedido com inconsistência';
        ordData2.CondicaoPagamento = 'condPag001';
        ordData2.Obs_NF            = '1234';
        ordData2.Filhos            = null;
        ordData2.Aprovacoes        = null;

        List<TemplateDataIntegrationFields.ItensINData> listOrderItemData = new List<TemplateDataIntegrationFields.ItensINData>();
        TemplateDataIntegrationFields.ItensINData orderItem = new TemplateDataIntegrationFields.ItensINData();

        orderItem.Produto    = 'prod001';
        orderItem.Quantidade = 10;
        orderItem.TpOper     = '20';

        listOrderItemData.add(orderItem);
        TemplateDataIntegrationFields.ItensINData orderItem2 = new TemplateDataIntegrationFields.ItensINData();

        orderItem2.Produto    = 'prod002';
        orderItem2.Quantidade = 10;
        orderItem2.TpOper     = '20';

        listOrderItemData.add(orderItem2);

        List<TemplateDataIntegrationFields.LabSonOrderINData> listLabOrderData = new List<TemplateDataIntegrationFields.LabSonOrderINData>();
        TemplateDataIntegrationFields.LabSonOrderINData labOrder = new TemplateDataIntegrationFields.LabSonOrderINData();

        labOrder.PedidoIntegrador  = '159358';
        labOrder.Pedido            = '45651244';
        labOrder.Cnpj_CD           = '09053134000145';
        labOrder.CondicaoPagamento = 'condPag001';
        
        List<TemplateDataIntegrationFields.LabSonOrderItemINData> listLabOrderItemData = new List<TemplateDataIntegrationFields.LabSonOrderItemINData>();
        TemplateDataIntegrationFields.LabSonOrderItemINData labOrderItem = new TemplateDataIntegrationFields.LabSonOrderItemINData();

        labOrderItem.Produto     = 'prod001';
        labOrderItem.QtdAtendida = 10;
        labOrderItem.Preco       = 100;

        listLabOrderItemData.add(labOrderItem);

        TemplateDataIntegrationFields.LabSonOrderItemINData labOrderItem2 = new TemplateDataIntegrationFields.LabSonOrderItemINData();

        labOrderItem2.Produto     = 'prod002';
        labOrderItem2.QtdAtendida = 10;
        labOrderItem2.Preco       = 100;

        listLabOrderItemData.add(labOrderItem2);

        labOrder.Itens = listLabOrderItemData;
        
        listLabOrderData.add(labOrder);
        
        TemplateDataIntegrationFields.ApprovalINData approvalData = new TemplateDataIntegrationFields.ApprovalINData();
        approvalData.Comercial = true;
        approvalData.Pricing   = false;

        ordData.Itens = listOrderItemData;
        ordData.Filhos = listLabOrderData;
        ordData.Aprovacoes = approvalData;

        ordData2.Itens = listOrderItemData;
        
        List<TemplateDataIntegrationFields.LabOrderINData> listOrdData = new List<TemplateDataIntegrationFields.LabOrderINData>{ordData, ordData2};

        IntegrationLaboratoryOrderIN.upsertLabOrder(listOrdData);
                
        //System.assertEquals(false, IntegrationLaboratoryOrderIN.upsertLabOrder(listOrdData).response[0].status);
    }
}