@isTest
public with sharing class BudgetDetailEditItemControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();
        insert condPag;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, condPag);
        opp.ExternalPortal__c = '786876876';
        opp.StatusIntegracaoPortalCotacoes__c = 'Integrado';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = TestUtility.createProduct();
        prod.Name = 'prod1';
        insert prod;

        Product2 prod2 = TestUtility.createProduct();
        prod2.Name = 'prod2';
        insert prod2;
        
        Pricebook2 pb = TestUtility.createPricebook2();
        insert pb;

        PricebookEntry pbEntry = TestUtility.createPricebookEntry(pb.Id,prod.Id);
        insert pbEntry;

        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.IdPortal__c = '012131231';
        qItem.Categoria__c = 'categTest';
        qItem.Product__c = prod.Id;
        insert qItem;
    }

    @isTest
    static void getQuoteItemAnswersTest(){        
        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.getQuoteItemAnswers('786876876', '012131231');
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }
    
    @isTest
    static void vincularProdutoTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        Product2 prod = [SELECT Id FROM Product2][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(qItem.Id, prod.id, opp.Id);
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }
    

    @isTest
    static void vincularProdutoVazioTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(qItem.Id, null, opp.Id);
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }
    @isTest
    static void vincularProdutoQuoteItemVazioTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(null, '12312312', opp.Id);
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }

    @isTest
    static void vincularProdutoDiferenteTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE Name = 'prod2'][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(String.valueOf(qItem.Id), String.valueOf(prod2.Id), String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }

    @isTest
    static void vincularProdutoOrcamentoTravadoTest(){
        Opportunity opp = [SELECT Id,OrcamentoTravado__c FROM Opportunity][0];
        opp.OrcamentoTravado__c = true;
        update opp;
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(String.valueOf(qItem.Id), 'id diferente', String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }
    @isTest
    static void vincularProdutoCondiPagNullTest(){
        Opportunity opp = [SELECT Id,CondicaoPagamento__c FROM Opportunity][0];
        opp.CondicaoPagamento__c = null;
        update opp;
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(String.valueOf(qItem.Id), 'id diferente', String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }

    @isTest
    static void vincularProdutoQuoteItemStatusAprovadoTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        qItem.Status__c = 'Aprovado';
        update qItem;
        Product2 prod = [SELECT Id FROM Product2][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.vincularProduto(qItem.Id, prod.id, opp.Id);
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }

    @isTest
    static void adicionarRespostaTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.adicionarResposta('012131231', String.valueOf(opp.Id),'BU' );
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }

    @isTest
    static void changeQuoteItemTabulacaoTest(){
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Map<String, Object> obj = new Map<String, Object>();

        obj.put('id', String.valueOf(qItem.Id));
        obj.put('status', 'Vinculado');
        obj.put('tabulacaoN1', 'Cotado');

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.changeQuoteItemTabulacao(JSON.Serialize(obj), String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }
    @isTest
    static void changeQuoteItemTabulacaoOrcamentoTravadoTest(){
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        Opportunity opp = [SELECT Id,OrcamentoTravado__c FROM Opportunity][0];
        opp.OrcamentoTravado__c = true;
        update opp;
        Map<String, Object> obj = new Map<String, Object>();

        obj.put('id', String.valueOf(qItem.Id));
        obj.put('status', 'Vinculado');
        obj.put('tabulacaoN1', 'Cotado');

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.changeQuoteItemTabulacao(JSON.Serialize(obj), String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(true, response.hasError);
    }
    @isTest
    static void changeQuoteItemTabulacaoStageNameNovoTest(){
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c][0];
        Opportunity opp = [SELECT Id,StageName FROM Opportunity][0];
        opp.StageName = 'Novo';
        update opp;
        Map<String, Object> obj = new Map<String, Object>();

        obj.put('id', String.valueOf(qItem.Id));
        obj.put('status', 'Vinculado');
        obj.put('tabulacaoN1', 'Cotado');

        Test.startTest();
        StandardResponse response = BudgetDetailEditItemController.changeQuoteItemTabulacao(JSON.Serialize(obj), String.valueOf(opp.Id));
        Test.stopTest();
        System.assertEquals(false, response.hasError);
    }
    @isTest
    static void buildQuoteItemTest(){
        QuoteItem__c qItem = [SELECT Status__c, TabulacaoN1__c,Vendedor__c,Product__r.Temperatura__c,Product__r.TipoConversao__c,
        Product__r.UnidadeMedida__c,Product__r.SegundaUnidade__c,OpportunityLineItem__r.ValorPortal__c,Product__r.CategoriaComercial__c,
        Product__r.Name, Product__r.FatorConversao__c,Product__r.Fornecedor__r.Name,Product__r.Description,Product__r.ProductCode,IdPortal__c,
        Product__c,OpportunityLineItem__r.SequenciaOC__c,OpportunityLineItem__c, Categoria__c, CNPJCD__c,Vendedor__r.Name,
        OpportunityLineItem__r.CentroDistribuicao__c,OpportunityLineItem__r.comentarios__c,DataHoraResposta__c, SequenciaOC__c
        FROM QuoteItem__c limit 1][0];
        
        BudgetDetailEditItemController.BudgetResposta bgResposta = new BudgetDetailEditItemController.BudgetResposta(qItem);
        Test.startTest();
        QuoteItem__c newQItem= bgResposta.buildQuoteItem();
        Test.stopTest();

        System.debug('new qt '+newQItem);
    }

    @isTest
    static void buildOpportunityLineItemTest(){
        QuoteItem__c qItem = [SELECT Status__c, TabulacaoN1__c,Vendedor__c,Product__r.Temperatura__c,Product__r.TipoConversao__c,
        Product__r.UnidadeMedida__c,Product__r.SegundaUnidade__c,OpportunityLineItem__r.ValorPortal__c,Product__r.CategoriaComercial__c,
        Product__r.Name, Product__r.FatorConversao__c,Product__r.Fornecedor__r.Name,Product__r.Description,Product__r.ProductCode,IdPortal__c,
        Product__c,OpportunityLineItem__r.SequenciaOC__c,OpportunityLineItem__c, Categoria__c, CNPJCD__c,Vendedor__r.Name,
        OpportunityLineItem__r.CentroDistribuicao__c,OpportunityLineItem__r.comentarios__c,DataHoraResposta__c, SequenciaOC__c
        FROM QuoteItem__c limit 1][0];

        Opportunity opp = [SELECT Id FROM Opportunity][0];

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry][1];
        
        BudgetDetailEditItemController.BudgetResposta bgResposta = new BudgetDetailEditItemController.BudgetResposta(qItem);
        Test.startTest();
        OpportunityLineItem newOppLineItem= bgResposta.buildOpportunityLineItem(opp, qItem, pbe);
        Test.stopTest();

        System.debug('new qt '+newOppLineItem);
    }
}
