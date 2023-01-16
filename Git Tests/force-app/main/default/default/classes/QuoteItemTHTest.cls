@IsTest
public with sharing class QuoteItemTHTest {

    public static final Id PRICEBOOKID = Test.getStandardPricebookId();
    public static final Id RECORDTYPE_PORTALID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
    
    @TestSetup
    public static void init() {

        List<SObject> listToInsert = new List<SObject>();
        List<SObject> listToInsert2 = new List<SObject>();


        CondicaoPagamento__c condicaoPagamento1  =  TestUtility.createPaymentCondition();
        condicaoPagamento1.ExternalId__c = '00cp';
        listToInsert.add(condicaoPagamento1);

        Account account1 = TestUtility.createAccPJ();
        listToInsert.add(account1);

        Contact contact1 = TestUtility.createContactFromCNPJ(account1.CNPJ__c);
        contact1.ExternalId__c = '00contact';
        listToInsert.add(contact1);

        User user1 = TestUtility.createUser();
        user1.CodigoUsuario__c = 'user1';
        listToInsert.add(user1);

        Pricebook2 pb2 = TestUtility.createPricebook2();
        pb2.ExternalId__c = 'pb2';
        listToInsert.add(pb2);
                
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
       

        listToInsert.add(opportunity1);

        Product2 product1 = TestUtility.createProduct();
        product1.ExternalId__c = '00prod';
        product1.ProductCode = '00prod';
        listToInsert.add(product1);

        PricebookEntry pbEntry1 = TestUtility.createPricebookEntry(pb2, product1);
        pbEntry1.ExternalId__c = '00pb';
        listToInsert.add(pbEntry1);

        OpportunityLineItem oppLineItem11 = TestUtility.createOpportunityLineItem(opportunity1.IdIntegrator__c, product1.ExternalId__c, pbEntry1.ExternalId__c);
        oppLineItem11.IdCustomer__c   = 'oLitem11';
        oppLineItem11.IdIntegrator__c = 'oLitem11';
        oppLineItem11.IdPortal__c 	  = 'oLitem11';
        oppLineItem11.CNPJCD__c = '79231541000180';
        oppLineItem11.Quantity = 1;
        oppLineItem11.UnitPrice = 1;
        oppLineItem11.ValidadeMinima__c = '168';
        oppLineItem11.Vendedor__r = new User(CodigoUsuario__c = 'user1');
        oppLineItem11.Status__c = 'Não Vinculado';
        oppLineItem11.TabulacaoN1__c  = 'Não tem no portifólio';
       
        listToInsert.add(oppLineItem11);


        QuoteItem__c quoteItem1 = TestUtility.createQuoteItem(opportunity1.IdIntegrator__c, user1.CodigoUsuario__c);
        quoteItem1.IdPortal__c = '001quoteItem';
        quoteItem1.IdCustomer__c = '001quoteItem';
        quoteItem1.IdERP__c = '001quoteItem';
        quoteItem1.ExternalId__c = '001quoteItem';
        quoteItem1.CNPJCD__c = '79231541000180';
        quoteItem1.ProgramacaoEntrega__c = '[{"quantidade":"8000","data":"16/02/2022"},{"quantidade":"9000","data":"03/03/2022"}]';
        quoteItem1.Quantity__c = 1;
        quoteItem1.UnitPrice__c = 1;
        quoteItem1.OpportunityLineItem__c = oppLineItem11.Id;
        quoteItem1.Status__c = 'Vinculado';
        quoteItem1.TabulacaoN1__c = 'Sem estoque';

        listToInsert.add(quoteItem1);

        OpportunityTeamMember oppTeamMember1 = TestUtility.createOpportunityTeamMember(opportunity1.IdIntegrator__c, 'user1');
        listToInsert2.add(oppTeamMember1);

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();
        listToInsert2.add(condPag);

        CondicaoPagamentoPorCD__c condPagCD =  TestUtility.createCondicaoPagamentoPorCD(condPag);
        condPagCD.CloseDate__c = Date.today()-1;
        condPagCD.MinimumBilling__c = 1;
        condPagCD.ObservacoesLongText__c = 'test';
        condPagCD.Orcamento__r = new Opportunity(IdIntegrator__c = opportunity1.IdIntegrator__c);
        condPagCD.PrazoEntrega__c = 10;
        condPagCD.PrazoValidade__c = 10;
        condPagCD.FretePicklist__c  = 'CIF';
        condPagCD.CNPJCD__c = '52202744000788';
        listToInsert2.add(condPagCD);

        Integracoes__c integ = New Integracoes__c(
            Name = 'InformaticaAtualizarCotacao',
            User__c = 'cloud.dev@grupoelfa.com.br',
            Password__c = 'Elf@Cloud',
            Method__c = 'POST',
            EndPoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-PORT-COT-SFDC-RESPOSTA'
        );
        listToInsert2.add(integ);

        insert listToInsert;
        insert listToInsert2;
    }

    
    @IsTest
    public static void testAllMethods() {
        
        QuoteItemTH qtItem = new QuoteItemTH();
        QuoteItem__c qt = [SELECT id,OpportunityLineItem__c, name,Product__c,Status__c, TabulacaoN1__c, OpportunityId__c, Vendedor__c, VendedorRespondeu__c FROM QuoteItem__c LIMIT 1];
        CondicaoPagamentoPorCD__c condPagCD = [SELECT Id, CNPJCD__c FROM CondicaoPagamentoPorCD__c][0];
        OpportunityLineItem opItem = [SELECT id,Status__c, name FROM OpportunityLineItem LIMIT 1];
        Map<Id, SObject> mapOld = new Map<Id, SObject>{qt.id => qt};
        Map<Id,OpportunityLineItem> mapOppLineItemsToUpdate = new Map<Id,OpportunityLineItem>{opItem.id => opItem};
        qt.Quantity__c = 2;
        qt.OpportunityLineItem__c = opItem.id;
        qt.Status__c = 'Vinculado';
        qt.TabulacaoN1__c = 'Cotado';
        qt.Product__c = [SELECT id FROM Product2 limit 1].Id;
        qtItem.clearMaxLoopCount();
        qtItem.doImportantAutomationsAfterInsertOrUpdate();
        qtItem.restartDoImportantAutomationsAfterInsertOrUpdate();
        qtItem.restartFixNewDataBeforeInsertOrUpdate();
        qtItem.setMaxLoopCount(2);
        update   qt;

        qt.UnitPrice__c = 3;
        AutomationsController.stop('TriggerHandlerV2.MaximumLoopCountException');
        update   qt;
        QuoteItemTH.updateOppTeamMemberAllQuoteItems(new List<QuoteItem__c>{qt}, true);
        QuoteItemTH.updateOppTeamMemberAllQuoteItems(new List<QuoteItem__c>{qt}, false);
        QuoteItem__c oldItem = new QuoteItem__c(Id= qt.Id, Status__c = 'Vinculado', TabulacaoN1__c = null, Vendedor__c =UserInfo.getUserId(), OpportunityId__c= qt.OpportunityId__c, CNPJCD__c=condPagCD.CNPJCD__c, PaymentConditionByDC__c = condPagCD.Id);
        QuoteItem__c newItem = new QuoteItem__c(Id= qt.Id, Status__c = 'Vinculado', TabulacaoN1__c = 'Fora malha', Vendedor__c =UserInfo.getUserId(), OpportunityId__c= qt.OpportunityId__c, CNPJCD__c=null, PaymentConditionByDC__c = null);
        insert new OpportunityTeamMember(
            UserId = newItem.Vendedor__c,
            OpportunityId = newItem.OpportunityId__c,
            AllQuotes__c = 0,
            AnsweredQuotes__c = 0,
            TeamMemberRole = 'Sales Rep',
            OpportunityAccessLevel = 'EDIT'
        );
        Map<Id,QuoteItem__c> oldMap = new Map<Id,QuoteItem__c>{oldItem.Id => oldItem};
        Map<Id,QuoteItem__c> newMap = new Map<Id,QuoteItem__c>{newItem.Id => newItem};
        QuoteItemTH.updateOppTeamMemberAnsweredQuoteItems(oldMap, newMap);
        QuoteItemTH.deleteCondicaoPagamentoCDSemVinculo(oldMap, newMap);        
        QuoteItemTH.deleteCondicaoPagamentoCDSemVinculo(oldMap, null);
        delete oldItem;
        QuoteItemTH.updateDistributionCenterRelationship(oldMap, newMap);
    }
}
