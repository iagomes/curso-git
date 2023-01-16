public without sharing class CloneOpportunity {

    @InvocableMethod(label='Clone Opportunity' 
                    description='Button to clone the opportunity and its items')
    public static List<String> flowCloneOpportunity(List<FlowInputs> flowInputs) {
        Id oppId = null;
        Id accId = null;
        for (FlowInputs flowInput : flowInputs) {
            oppId = flowInput.oppId;
            accId = flowInput.accId;
        }
        // Pricebook2 bionexoPB = [SELECT Id FROM Pricebook2 WHERE ExternalId__c = 'B01' LIMIT 1];
        // Boolean isBionexo = false;
        Account newAccount = [SELECT Id, TabelaPrecos__c, Observacoes__c FROM Account WHERE Id = :accId LIMIT 1];
        Date today = Date.today();
        Opportunity contextOpportunity = null;
        for (Opportunity o : [SELECT Id, AprovadoComercial__c, AprovadoPricing__c, CanalEntrada__c, CanalVendas__c, Pricebook2Id,
                                ClienteRecebedor__c, CondicaoPagamento__c, ForecastCategoryName, DiaParcelas__c,
                                ContatoOrcamento__c, ContractId, SyncedQuoteId, CloseDate, EnviarAprovacao__c, MargemAlvo__c,
                                FormaPagamento__c, Margem__c, MotivoCancelamento__c, NecessitaAprovacaoComercial__c, NecessitaAprovacaoPricing__c, 
                                AccountId, Name, NumeroOrcamento__c, Observacoes__c, Description,  ObservacoesCliente__c, CampaignId, LeadSource, 
                                IsPrivate, IqScore, PrazoValidade__c, Probability, NextStep, TotalOpportunityQuantity, QuantidadeProrrogamentos__c,
                                RecallProcesso__c, ExpectedRevenue, RejeicaoProcesso__c, Score__c, StageName, StatusAprovacao__c, Idportalcotacoes__c,
                                RecordTypeId, Type
                              FROM Opportunity WHERE Id = :oppId]) {
            
            contextOpportunity = o;
            // if (o.Pricebook2Id == bionexoPB.Id) {
            //     isBionexo = true;
            // }
        }
        Opportunity newOpportunity = new Opportunity();
        if (contextOpportunity != null) {
            newOpportunity.AprovadoComercial__c           = false;
            newOpportunity.AprovadoPricing__c             = false;
            newOpportunity.CanalEntrada__c                = contextOpportunity.CanalEntrada__c;
            newOpportunity.CanalVendas__c                 = contextOpportunity.CanalVendas__c;
            newOpportunity.Pricebook2Id                   = contextOpportunity.Pricebook2Id;
            newOpportunity.ClienteRecebedor__c            = contextOpportunity.ClienteRecebedor__c;
            newOpportunity.CondicaoPagamento__c           = contextOpportunity.CondicaoPagamento__c;
            newOpportunity.ForecastCategoryName           = contextOpportunity.ForecastCategoryName;
            if (accId == contextOpportunity.AccountId) {
                newOpportunity.ContatoOrcamento__c                   = contextOpportunity.ContatoOrcamento__c;
            }
            newOpportunity.ContractId                     = contextOpportunity.ContractId;
            newOpportunity.SyncedQuoteId                  = contextOpportunity.SyncedQuoteId;
            newOpportunity.CloseDate                      = contextOpportunity.PrazoValidade__c == null ? null : today.addDays(Integer.valueOf(contextOpportunity.PrazoValidade__c));
            newOpportunity.EnviarAprovacao__c             = false;
            newOpportunity.FormaPagamento__c              = contextOpportunity.FormaPagamento__c;
            newOpportunity.Margem__c                      = contextOpportunity.Margem__c;
            newOpportunity.MargemAlvo__c                  = contextOpportunity.MargemAlvo__c;
            newOpportunity.MotivoCancelamento__c          = contextOpportunity.MotivoCancelamento__c;
            newOpportunity.Idportalcotacoes__c            = contextOpportunity.Idportalcotacoes__c;
            newOpportunity.NecessitaAprovacaoComercial__c = false;
            newOpportunity.NecessitaAprovacaoPricing__c   = false;
            newOpportunity.AccountId                      = accId;
            newOpportunity.Name                           = contextOpportunity.Name;
            newOpportunity.Observacoes__c                 = contextOpportunity.Observacoes__c;
            newOpportunity.Description                    = contextOpportunity.Description;
            newOpportunity.ObservacoesCliente__c          = newAccount.Observacoes__c;
            newOpportunity.CampaignId                     = contextOpportunity.CampaignId;
            newOpportunity.LeadSource                     = contextOpportunity.LeadSource;
            newOpportunity.IsPrivate                      = contextOpportunity.IsPrivate;
            newOpportunity.PrazoValidade__c               = contextOpportunity.PrazoValidade__c;
            newOpportunity.Probability                    = contextOpportunity.Probability;
            newOpportunity.NextStep                       = contextOpportunity.NextStep;
            newOpportunity.TotalOpportunityQuantity       = contextOpportunity.TotalOpportunityQuantity;
            newOpportunity.QuantidadeProrrogamentos__c    = 0;
            newOpportunity.RecallProcesso__c              = false;
            newOpportunity.RejeicaoProcesso__c            = contextOpportunity.RejeicaoProcesso__c;
            newOpportunity.Score__c                       = contextOpportunity.Score__c;
            newOpportunity.StageName                      = 'Em digitação';
            // newOpportunity.StatusAprovacao__c             = 'Em digitação';
            newOpportunity.RecordTypeId                   = contextOpportunity.RecordTypeId;
            newOpportunity.Type                           = contextOpportunity.Type;

            insert newOpportunity;

            List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();
            Map<Id, Id> prodIdToPBEntryIdMap = new Map<Id, Id>();

            for (OpportunityLineItem oLineItem : [SELECT Id, Custo__c, Imposto__c, CategoriaComercial__c, CentroDistribuicao__c, ProductCode, ServiceDate, Discount, Description, PricebookEntryId,
                                                    ForaMalha__c, Fornecedor__c, ItemCampanha__c, JustificativaDesconto__c, Lote__c, MargemAlvo__c, MargemAtual__c, cnpjCD__c,
                                                    Name, NumeroAnvisa__c, OpportunityId, ListPrice, UnitPrice, TotalPrice, PrincipioAtivo__c, Product2Id, Quantity, ScoreBU__c, ScoreItem__c, ScoreMix__c,
                                                    QuantidadeUn__c, ScoreAlvo__c, ScoreAtual__c, Subtotal, Temperatura__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, ValorMalha__c, ValorSugerido__c, Range__c,
                                                    ValorTotal__c, Vendedor__c, BloqueadoRegionalizacao__c
                                                  FROM OpportunityLineItem WHERE OpportunityId = :contextOpportunity.Id]) {
                
                OpportunityLineItem newOppLineItem = new OpportunityLineItem();
                newOppLineItem.CentroDistribuicao__c    = oLineItem.CentroDistribuicao__c;
                newOppLineItem.ServiceDate              = oLineItem.ServiceDate;
                newOppLineItem.Discount                 = oLineItem.Discount;
                newOppLineItem.Description              = oLineItem.Description;
                newOppLineItem.ForaMalha__c             = oLineItem.ForaMalha__c;
                newOppLineItem.ItemCampanha__c          = oLineItem.ItemCampanha__c;
                newOppLineItem.PricebookEntryId         = oLineItem.PricebookEntryId;
                newOppLineItem.JustificativaDesconto__c = oLineItem.JustificativaDesconto__c;
                newOppLineItem.Lote__c                  = oLineItem.Lote__c;
                newOppLineItem.MargemAlvo__c            = oLineItem.MargemAlvo__c;
                newOppLineItem.MargemAtual__c           = oLineItem.MargemAtual__c;
                newOppLineItem.cnpjCD__c                = oLineItem.cnpjCD__c;
                newOppLineItem.OpportunityId            = newOpportunity.Id;
                // newOppLineItem.UnitPrice                = oLineItem.UnitPrice;
                newOppLineItem.TotalPrice               = oLineItem.TotalPrice;
                newOppLineItem.Product2Id               = oLineItem.Product2Id;
                newOppLineItem.Quantity                 = oLineItem.Quantity;
                newOppLineItem.QuantidadeUn__c          = oLineItem.QuantidadeUn__c;
                newOppLineItem.ScoreAlvo__c             = oLineItem.ScoreAlvo__c;
                newOppLineItem.ScoreAtual__c            = oLineItem.ScoreAtual__c;
                newOppLineItem.ScoreBU__c               = oLineItem.ScoreBU__c;
                newOppLineItem.ScoreItem__c             = oLineItem.ScoreItem__c;
                newOppLineItem.ScoreMix__c              = oLineItem.ScoreMix__c;
                newOppLineItem.ValidadeMinima__c        = oLineItem.ValidadeMinima__c;
                newOppLineItem.ValorCx__c               = oLineItem.ValorCx__c;
                newOppLineItem.ValorMalha__c            = oLineItem.ValorMalha__c;
                newOppLineItem.ValorSugerido__c         = oLineItem.ValorSugerido__c;
                newOppLineItem.Range__C                 = oLineItem.Range__C;
                newOppLineItem.ValorUn__c               = oLineItem.ValorUn__c;
                newOppLineItem.ValorTotal__c            = oLineItem.ValorTotal__c;
                newOppLineItem.Vendedor__c              = oLineItem.Vendedor__c;

                newOppLineItem.Custo__c                 = oLineItem.Custo__c;
                newOppLineItem.Imposto__c               = oLineItem.Imposto__c;
                newOppLineItem.BloqueadoRegionalizacao__c = oLineItem.BloqueadoRegionalizacao__c;

                newOppLineItemList.add(newOppLineItem);
            }

            if (!newOppLineItemList.isEmpty()){
                insert newOppLineItemList;
            }
        }
        newOpportunity = [SELECT Id, NumeroOrcamento__c FROM Opportunity WHERE Id = :newOpportunity.id];

        return new List<String>{newOpportunity.Id};
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String oppId;
        
        @InvocableVariable
        public String accId;
    }
}