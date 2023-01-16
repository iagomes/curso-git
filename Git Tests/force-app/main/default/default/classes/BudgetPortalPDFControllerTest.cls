@IsTest 
public with sharing class BudgetPortalPDFControllerTest {
    @TestSetup
    static void makeData(){
        Opportunity opp = TestUtility.createOpportunity(new User(Id = UserInfo.getUserId()));
        insert opp;
        Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
        insert fornecedor;

        Product2 product = TestUtility.createProduct();
        product.ExternalId__c = '1234';
        product.UnidadeMedida__c = 'F';
        product.fornecedor__c = fornecedor.Id;
        insert product;
        CondicaoPagamento__c conpag = TestUtility.createPaymentCondition();
        insert conpag;
        CondicaoPagamentoPorCD__c conpagCD = TestUtility.createCondicaoPagamentoPorCD(conpag);
        conpagCD.Orcamento__c = opp.Id;
        insert conpagCD;
        Pricebook2 pb2 = TestUtility.createPricebook2();
        pb2.ExternalId__c = 'B01';
        pb2.isActive = true;
        upsert pb2 Pricebook2.ExternalId__c;

        PricebookEntry pricebookEntry  = new PriceBookEntry(
            pricebook2Id = pb2.Id, 
            product2Id = product.Id,
            unitPrice = 10,
            isActive = true
        );
        insert pricebookEntry;

        OpportunityLineItem opportunityLineItem = TestUtility.createOpportunityLineItem(opp, product, pricebookEntry);
        opportunityLineItem.Status__c = 'Aguardando Integração';
        opportunityLineItem.CNPJCD__c = '52202744000788';
        

        OpportunityLineItem opportunityLineItem2 = TestUtility.createOpportunityLineItem(opp, product, pricebookEntry);
        opportunityLineItem2.CNPJCD__c = '52202744000788';
        opportunityLineItem2.Status__c = 'Respondido';
        insert new List<OpportunityLineItem>{opportunityLineItem, OpportunityLineItem2};

        QuoteItem__c quoteitem = TestUtility.createQuoteItem(opp, new User(Id = UserInfo.getUserId()));
        quoteitem.OpportunityLineItem__c = opportunityLineItem.Id;
        quoteitem.OpportunityId__c = opp.Id;
        quoteitem.Product__c = product.Id;
        quoteitem.idportal__c = '32443';
        quoteitem.Status__c = 'Vinculado';
        insert new List<QuoteItem__c> {quoteitem};
    }
    @IsTest
    static void BudgetPortalPDFControllerTest() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        BudgetPortalPDFController testAccPlan = new BudgetPortalPDFController(sc);
        
        PageReference pageRef = Page.BudgetPortalPDF;
        pageRef.getParameters().put('id', String.valueOf(opp.Id));
        Test.setCurrentPage(pageRef);
    }
}
