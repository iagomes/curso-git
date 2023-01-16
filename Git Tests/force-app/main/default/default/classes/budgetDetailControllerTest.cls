@isTest
public with sharing class budgetDetailControllerTest {
    
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;

        Setorizacao__c setor = TestUtility.createSetorizacaoWithValidData(acc, new User(Id = UserInfo.getUserId()));
        setor.Categoria__c = 'M';
        setor.VendedorSuporte__c = UserInfo.getUserId();
        insert setor;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition2();
        insert condPag;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, condPag);
        opp.ExternalPortal__c = 'getBudgetDataWithItensTest';
        opp.StatusIntegracaoPortalCotacoes__c = 'Integrado';
        insert opp;

        OpportunityTeamMember oppTeamMember = TestUtility.createOpportunityTeamMember(opp);
        insert oppTeamMember;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.IdPortal__c = 'setTabulacao';
        qItem.Categoria__c = 'M';
        QuoteItem__c qItemWithEstoque = TestUtility.createQuoteItem(opp);
        qItemWithEstoque.Product__c = prod.Id;
        QuoteItem__c qItemProgEntrega = TestUtility.createQuoteItem(opp);
        qItemProgEntrega.IdPortal__c = 'progEntrega';
        qItemProgEntrega.ProgramacaoEntrega__c = '[{"quantidade":"10","data":"19/03/2022"}]';
        QuoteItem__c qItemCategoriaCliente = TestUtility.createQuoteItem(opp);
        qItemCategoriaCliente.IdPortal__c = 'categoriaCliente';
        qItemCategoriaCliente.Categoria__c = 'M';
        qItemCategoriaCliente.CategoriaCliente__c = 'categoriaTeste';
        insert new List<QuoteItem__c>{qItem, qItemWithEstoque, qItemProgEntrega, qItemCategoriaCliente};

        Estoque__c estoque = TestUtility.createStock('getBudgetDataWithItensTest', prod.Id);
        estoque.ExternalId__c = 'getBudgetDataWithItensTest';
        insert estoque;
    }

    @isTest
    static void getBudgetDataWithItensTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        StandardResponse response = BudgetDetailController.getBudgetDataWithItens(opp.Id);
        System.assertEquals(false, response.hasError);
        //StandardResponse responseError = BudgetDetailController.getBudgetDataWithItens('Error');
        //System.assertEquals(true, responseError.hasError);
    }

    @isTest
    static void setItemTabulacaoN1Test(){
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        StandardResponse response = BudgetDetailController.setItemTabulacaoN1(
            new List<String>{'setTabulacao'},
            opp.Id,
            opp.AccountId,
            new List<String>{'M','S'},
            'Não pertence a minha BU'
        );
        System.assertEquals(false, response.hasError);
        StandardResponse responseError = BudgetDetailController.setItemTabulacaoN1(
            new List<String>{'setTabulacao'},
            'error',
            opp.AccountId,
            new List<String>{'M','S'},
            'Não pertence a minha BU'
        );
        System.assertEquals(true, responseError.hasError);
    }

    @isTest
    static void getProgramacaoEntregaTest(){
        BudgetDetailController.getProgramacaoEntrega('progEntrega');
    }

    @isTest
    static void getCustomerCategoryTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        BudgetDetailController.getCustomerCategory(opp.Id);
        //BudgetDetailController.getCustomerCategory('Error');
    }

    @isTest
    static void saveBudgetTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        opp.TabulacaoN1__c = 'Aceite';
        opp.TabulacaoN2__c = 'Cotação Enviada TT';
        opp.StageName = 'Novo';
        update opp;
        BudgetDetailController.saveBudget(opp, false, null);
        opp.DataVencimento__c = DateTime.now().addDays(-1);
        update opp;
        BudgetDetailController.saveBudget(opp, true, null);
        opp.DataVencimento__c = DateTime.now().addDays(1);
        update opp;
        BudgetDetailController.saveBudget(opp, true, null);
        opp.TabulacaoN1__c = null;
        opp.TabulacaoN2__c = null;
        String cdValues = '[{"totItem":100,"resp":1,"qtdItensTotal":568,"PrazoValidade":0,"PrazoEntrega":3,"ObservacoesLongText":null,"MinimumBilling":1,"Id":"a0i21000003w8CYAAY","FretePicklist":"CIF","CondicaoPagamentoPL":"043/A VISTA","CNPJCD":"25211499000107","CloseDate":"2022-09-17","CentroDistribuicao":"MEDCOM - GOIANIA (MATRIZ)"}]';
        BudgetDetailController.saveBudget(opp, true, cdValues);
        BudgetDetailController.saveBudget(new Opportunity(), false, null);
    }

    @isTest
    static void getUserCategoriesTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        StandardResponse response = BudgetDetailController.getUserCategories(opp.Id);
        System.assertEquals(false, response.hasError);
        //StandardResponse responseError = BudgetDetailController.getUserCategories('error');
        //System.assertEquals(true, responseError.hasError);
    }

    @isTest
    static void getPdfPageTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        StandardResponse response = BudgetDetailController.getPdfPage(opp.Id);
        System.assertEquals(false, response.hasError);
        //StandardResponse responseError = BudgetDetailController.getPdfPage('error');
        //System.assertEquals(true, responseError.hasError);
    }

    @isTest
    static void putStatusItemAndStyleTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'getBudgetDataWithItensTest'];
        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.Status__c = 'Vinculado';
        qItem.TabulacaoN1__c = null;
        QuoteItem__c qItemAnswered = TestUtility.createQuoteItem(opp);
        qItemAnswered.Status__c = 'Vinculado';
        qItemAnswered.TabulacaoN1__c = 'Cotado';
        List<QuoteItem__c> qItemList = new List<QuoteItem__c>{qItemAnswered};
        BudgetDetailController.putStatusItemAndStyle(new BudgetDetailController.budgetItemData(), qItemList);
        qItemList.add(qItem);
        BudgetDetailController.putStatusItemAndStyle(new BudgetDetailController.budgetItemData(), qItemList);
    }
}
