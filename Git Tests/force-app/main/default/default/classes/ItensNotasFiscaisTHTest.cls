@IsTest
public with sharing class ItensNotasFiscaisTHTest {

    public static final Id PRICEBOOKID = Test.getStandardPricebookId();
    public static final Id RECORDTYPE_PORTALID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
    
    @TestSetup
    public static void init() {

        List<SObject> listToInsert = new List<SObject>();
        List<SObject> listToInsert2 = new List<SObject>();

        Account account = TestUtility.createAccPJ();
        insert account;

        Pricebook2 pb2 = TestUtility.createPricebook2();
        pb2.ExternalId__c = 'pb2';
        listToInsert.add(pb2);
  

        Product2 product1 = TestUtility.createProduct();
        product1.ExternalId__c = '00prod';
        product1.ProductCode = '00prod';
        listToInsert.add(product1);

        PricebookEntry pbEntry1 = TestUtility.createPricebookEntry(pb2, product1);
        pbEntry1.ExternalId__c = '00pb';
        listToInsert.add(pbEntry1);

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();
        insert condPag;
       
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pb2.Id;
        insert order;


        NotasFiscais__c nf = new NotasFiscais__c();
        nf.Name = 'testeVenda';
        nf.SerieNota__c = '2';
        nf.DataEmissao__c = System.Today();
        nf.Pedido__c = order.Id;
        nf.CondicaoPagamento__c = condPag.Id;
        nf.Empresa__c = 'Emrpesa teste Venda';
        nf.Conta__c = account.Id;
        insert nf;

        ItensNotaFiscal__c itemVenda = new ItensNotaFiscal__c();
        itemVenda.ExternalId__c = '123';
        itemVenda.NotaFiscal__c = nf.id;
        insert itemVenda;

        NotasFiscais__c nfDevolucao = new NotasFiscais__c();
        nfDevolucao.Name = 'testeDevolucao';
        nfDevolucao.SerieNota__c = '1';
        nfDevolucao.DataEmissao__c = System.Today();
        nfDevolucao.Pedido__c = order.Id;
        nfDevolucao.CondicaoPagamento__c = condPag.Id;
        nfDevolucao.Empresa__c = 'Emrpesa teste';
        nfDevolucao.CFOP__c = '1202';
        nfDevolucao.Conta__c = account.Id;
        insert nfDevolucao;

        ItensNotaFiscal__c itemDevolucao = new ItensNotaFiscal__c();
        itemDevolucao.CodigoItemNotaVenda__c = '123';
        itemDevolucao.NotaFiscal__c = nfDevolucao.id;
        itemDevolucao.ItemNotaVenda__c = null;
        insert itemDevolucao;  

        //insert listToInsert;
        //insert listToInsert2;
    }

    
    @IsTest
    public static void testAllMethods() {

        List<ItensNotaFiscal__c> newRecordList = [SELECT id, CodigoItemNotaVenda__c, ExternalId__c,ItemNotaVenda__c FROM ItensNotaFiscal__c WHERE CodigoItemNotaVenda__c != '' LIMIT 1];
        Map<Id, ItensNotaFiscal__c> mapOld = new Map<Id, ItensNotaFiscal__c>{newRecordList[0].Id => newRecordList[0]};
        ItensNotasFiscaisTH.disableTrigger();

        ItensNotasFiscaisBO ItensNotasFiscaisBO = new ItensNotasFiscaisBO();
        ItensNotasFiscaisBO.vinculaItemVenda(mapOld, newRecordList);

        ItensNotasFiscaisTH.enableTrigger();
        
        update   newRecordList;

        delete newRecordList;

    }
}
