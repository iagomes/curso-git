@isTest
public with sharing class BudgetDetailTabulacaoControllerTest {
    public static final Id PRICEBOOKID = Test.getStandardPricebookId();
    public static final Id RECORDTYPE_PORTALID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
    @TestSetup
    static void makeData(){

        CondicaoPagamento__c condicaoPagamento1  =  TestUtility.createPaymentCondition();
        condicaoPagamento1.ExternalId__c = '00cp';
        insert condicaoPagamento1;

        Pricebook2 pb2 = TestUtility.createPricebook2();
        pb2.ExternalId__c = 'pb2';
        insert pb2;

        Account account1 = TestUtility.createAccPJ();
        insert account1;

        Contact contact1 = TestUtility.createContactFromCNPJ(account1.CNPJ__c);
        contact1.ExternalId__c = '00contact';
        insert contact1;

        Opportunity opportunity1 = new Opportunity(
            RecordTypeId = RECORDTYPE_PORTALID,
            Pricebook2 = new Pricebook2(ExternalId__c = pb2.ExternalId__c),
            CondicaoPagamento__r = new CondicaoPagamento__c(ExternalId__c = condicaoPagamento1.ExternalId__c),
            Account = new Account(CNPJ__c = account1.CNPJ__c),
            ContatoOrcamento__r = new Contact(ExternalId__c = contact1.ExternalId__c),
            Amount = 219.679262,
            Probability = 10,
            MargemAlvo__c = 100,
            Margem__c = 100,
            PrazoValidade__c = 3,
            Score__c = 100,
            TotalOpportunityQuantity = 22,
            IsPrivate = false,
            IsExcludedFromTerritory2Filter = false,
            Budget_Confirmed__c = false,
            Discovery_Completed__c = false,
            ROI_Analysis_Completed__c = false,
            AprovadoComercial__c = false,
            AprovadoPricing__c = false,
            EnviarAprovacao__c = false,
            RecomendacaoRespondida__c = false,
            NecessitaAprovacaoComercial__c = false,
            NecessitaAprovacaoPricing__c = false,
            RecallProcesso__c = false,
            RejeicaoProcesso__c = false,
            SolicitacaoAprovada__c = false,
            Name = 'OppTest',
            StageName = 'Em digitação',
            CanalEntrada__c = 'Chat',
            FormaPagamento__c = 'Carteira',
            ObservacoesCliente__c = 'Cliente não atende aos fins de semana.',
            TabulacaoN1__c  = 'Aceite',
            IdIntegrator__c = '001',
            CloseDate = Date.newInstance(2021,12,06),
            DataVencimento__c = Date.today()+1
        );
        insert opportunity1;

        OpportunityTeamMember opp1TeamMember = TestUtility.createOpportunityTeamMember(opportunity1);
        insert opp1TeamMember;

    }

    @isTest
    static void GetTabulacaoValuesTest(){
        Opportunity opp = [SELECT Id FROM Opportunity limit 1];

        Test.startTest();
        StandardResponse response =  BudgetDetailTabulacaoController.getTabulacaoValues(opp.Id);
        Test.stopTest();
        //System.assertEquals(true, response.data != null);
    }

    @isTest
    static void GetTabulacaoTeamMemberInOppTest(){
        Opportunity opp = [SELECT Id FROM Opportunity limit 1];

        Test.startTest();
        StandardResponse response =  BudgetDetailTabulacaoController.getTabulacaoTeamMember(opp.Id);
        Test.stopTest();
        //System.assertEquals(true, response.data != null);
    }

    @isTest
    static void GetTabulacaoTeamMemberNotInOppTest(){
        Opportunity opp = [SELECT Id FROM Opportunity limit 1];
        User user = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() limit 1];
        StandardResponse response = new StandardResponse();
        System.runAs(user){
            Test.startTest();
                response =  BudgetDetailTabulacaoController.getTabulacaoTeamMember(opp.Id);
            Test.stopTest();
        }
        //System.assertEquals(true, response.data != null);
    }

    @isTest
    static void oppDueDateWasUpdatedByPortalFalseTest(){
        Opportunity opp = [SELECT Id, DataVencimento__c FROM Opportunity limit 1];
        Test.startTest();
        Map<String, Boolean> response =  BudgetDetailTabulacaoController.oppDueDateWasUpdatedByPortal(opp.Id);
        Test.stopTest();
        //System.assertEquals(false, response.get('updatedByPortal'));
    }
}
