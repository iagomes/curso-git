@isTest
public with sharing class IntegrationPortalQuoteOUTScheduleTest {

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;
        CondicaoPagamento__c conditionPayment = TestUtility.createPaymentCondition2();
        insert conditionPayment;
        Contact contact = TestUtility.createContact(acc);
        insert contact;
        Opportunity opp = TestUtility.createOpportunity(acc, contact, conditionPayment);
        opp.DataVencimento__c = System.now().addMinutes(1);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
        opp.StageName = 'Em digitação';
        insert opp;
        CondicaoPagamentoPorCD__c conPagCd = TestUtility.createCondicaoPagamentoPorCD(conditionPayment);
        conPagCd.Orcamento__c = opp.Id;
        conPagCd.FretePicklist__c = null;
        CondicaoPagamentoPorCD__c conPagCdWithoutConPay = TestUtility.createCondicaoPagamentoPorCD(conditionPayment);
        conPagCdWithoutConPay.Orcamento__c = opp.Id;
        conPagCdWithoutConPay.FretePicklist__c = null;
        conPagCdWithoutConPay.CondicaoPagamento__r = null;
        conPagCdWithoutConPay.CondicaoPagamento__c = null;
        conPagCdWithoutConPay.CondicaoPagamentoPL__c = null;
        insert new List<CondicaoPagamentoPorCD__c>{conPagCd, conPagCdWithoutConPay};
        OpportunityTeamMember otm = TestUtility.createOpportunityTeamMember(opp);
        insert otm;
        QuoteItem__c qItem = TestUtility.createQuoteItem(opp, new User(Id = UserInfo.getUserId()));
        qItem.Status__c = 'Vinculado';
        qItem.TabulacaoN1__c = 'Sem Estoque';
        insert qItem;

        Integracoes__c integration =  new Integracoes__c(
            Name        = 'InformaticaAtualizarCotacao',
            Method__c   = 'POST',
            Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/',
            User__c     = 'test123@grupoelfa.com.br',
            Password__c = 'test123'
        );
        insert integration;
    }

    @isTest
    public static void testIntegrationQuoteOutSchedule(){
        Test.StartTest();
        IntegrationPortalQuoteOUTSchedule.scheduleQueue();
        Test.StopTest();
    }
}
