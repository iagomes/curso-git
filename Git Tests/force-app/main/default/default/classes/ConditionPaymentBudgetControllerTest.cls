@isTest
public class ConditionPaymentBudgetControllerTest {

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();
        insert condPag;
        
        Pricebook2 pb = TestUtility.createPricebook2();
        insert pb;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, condPag);
        opp.ExternalPortal__c = '786876876';
        opp.StatusIntegracaoPortalCotacoes__c = 'Integrado';
        opp.Pricebook2Id = pb.Id;
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod = TestUtility.createProduct();
        prod.Name = 'prod1';
        insert prod;

        Product2 prod2 = TestUtility.createProduct();
        prod2.Name = 'prod2';
        insert prod2;
        

        PricebookEntry pbEntry = TestUtility.createPricebookEntry(pb.Id,prod.Id);
        insert pbEntry;

        
        OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opp, prod2, pbEntry);
        oppLineItem.CNPJCD__c = '18269125000187';
        oppLineItem.ValorPortal__c = 2;
        oppLineItem.QuantidadePortal__c = 2;
        insert oppLineItem;

        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.IdPortal__c = '012131231';
        qItem.Categoria__c = 'categTest';
        qItem.Product__c = prod.Id;
        qItem.CNPJCD__c = '18269125000187';
        qItem.OpportunityLineItem__c = oppLineItem.Id;
        insert qItem;

        CondicaoPagamentoPorCD__c conPagCD = new CondicaoPagamentoPorCD__c(
            CentroDistribuicao__c = 'ABC',
            CloseDate__c = System.today(),
            CNPJCD__c = '18269125000187',
            CondicaoPagamentoPL__c = '043/A VISTA',
            Integradora__c = 'Bionexo',
            CondicaoPagamento__c = condPag.Id,
            FretePicklist__c = 'CIF',
            MinimumBilling__c = 1,
            ObservacoesLongText__c = 'a',
            PrazoEntrega__c = 1,
            PrazoValidade__c = 1,
            Orcamento__c = opp.Id
        );
        insert conPagCD;
    }

    @isTest
    static void test_getConditionPayment(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ConditionPaymentBudgetController.getConditionPayment(opp.Id);
    }
}
