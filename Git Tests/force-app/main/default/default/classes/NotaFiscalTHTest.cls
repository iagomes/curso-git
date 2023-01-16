@IsTest
public with sharing class NotaFiscalTHTest {

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
        nf.Name = 'teste';
        nf.Conta__c = account.id;
        nf.SerieNota__c = '1';
        nf.DataEmissao__c = System.Today();
        nf.Pedido__c = order.Id;
        nf.CondicaoPagamento__c = condPag.Id;
        nf.Empresa__c = 'Emrpesa teste';
        nf.CFOP__c = '1202';
        insert nf;

        insert listToInsert;
        insert listToInsert2;
    }

    
    @IsTest
    public static void testAllMethods() {
        
        NotasFiscaisTH.disableTrigger();
        List<NotasFiscais__c> newRecordList = [SELECT id,Name,CFOP__c FROM NotasFiscais__c LIMIT 1];
        Map<Id, NotasFiscais__c> mapOld = new Map<Id, NotasFiscais__c>{newRecordList[0].Id => newRecordList[0]};
       
        NotasFiscaisBO NotasFiscaisBO = new NotasFiscaisBO();
        NotasFiscaisBO.validateCFOP(mapOld, newRecordList);

        NotasFiscaisTH.enableTrigger();
        
        update   newRecordList;

        delete newRecordList;

    }
}
