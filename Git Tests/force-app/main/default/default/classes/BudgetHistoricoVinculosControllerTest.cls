@isTest
public class BudgetHistoricoVinculosControllerTest {
    public static final Id RT_ORCAMENTOS_PORTAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Orçamento do Portal').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '12345678901234';
        insert acc;
        Contact contact = TestUtility.createContact(acc);
        insert contact;
        CondicaoPagamento__c conPay = TestUtility.createPaymentCondition2();
        insert conPay;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, conPay);
        opp.ExternalPortal__c = 'testHistoricoVinculos';
        opp.RecordTypeId = RT_ORCAMENTOS_PORTAL_ID;
        opp.StageName = 'Gerar Pedido';
        insert opp;
        Product2 prod = TestUtility.createProduct();
        prod.ProductCode = '0000364';
        insert prod;
        PricebookEntry pb = [
            SELECT Id 
            FROM PricebookEntry 
            WHERE Product2Id = :prod.Id 
            AND Pricebook2Id = :Test.getStandardPricebookId()
        ];
        Estoque__c estoque = TestUtility.createStock('extEstoque', prod.Id);
        insert estoque;
        OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opp, prod, pb);
        oppLineItem.Status__c = 'Vinculado';
        oppLineItem.TabulacaoN1__c = 'Cotado';
        insert oppLineItem;
        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.ProdutosVinculadosAnteriormente__c = '[{"vendedor":"","updateAt":"2022-09-17T19:10:55.700Z","tipoConversaoUnidadeMedida":"DIVIDIR","mesa":"","idERP":null,"fatorConversao":1.0,"createdAt":"2022-07-06T17:51:45.373Z","codigoProdutoERP":"0000364","bu":"G"}]';
        qItem.IdPortal__c = 'testHistoricoVinculos';
        insert qItem;
    }

    @IsTest
    static void getHistoricoVinculosTest(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE ExternalPortal__c = 'testHistoricoVinculos'];
        Test.startTest();
        StandardResponse response = BudgetHistoricoVinculosController.getHistoricoVinculos('testHistoricoVinculos', opp.Id);
        System.assertEquals(false, response.hasError);

        StandardResponse responseError1 = BudgetHistoricoVinculosController.getHistoricoVinculos(null, opp.Id);
        System.assertEquals(true, responseError1.hasError);
        QuoteItem__c qItem = [
            SELECT Id, ProdutosVinculadosAnteriormente__c 
            FROM QuoteItem__c 
            WHERE OpportunityId__c = :opp.Id 
            AND IdPortal__c = 'testHistoricoVinculos'
        ];
        qItem.ProdutosVinculadosAnteriormente__c = '[{{error]';
        update qItem;
        StandardResponse responseError2 = BudgetHistoricoVinculosController.getHistoricoVinculos('testHistoricoVinculos', opp.Id);
        System.assertEquals(true, responseError2.hasError);
        Test.stopTest();

    }
}