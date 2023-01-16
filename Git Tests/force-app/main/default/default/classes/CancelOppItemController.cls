public with sharing class CancelOppItemController {

    @AuraEnabled(cacheable=true)
    public static List<ProductData> getBudgetItens(String recId) {
        system.debug(recId);
        List<ProductData> prodDataList = new List<ProductData>();
        for (OpportunityLineItem oppLineItem : [SELECT Id, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Fornecedor__r.Name, Product2.Description, Quantity, ValorCx__c, CentroDistribuicao__c, OpportunityId, ScoreItem__c, Opportunity.NumeroOrcamento__c, MotivoCancelamento__c, CNPJCD__c, Opportunity.Description, ObservacaoCancelamento__c
                                                FROM OpportunityLineItem WHERE OpportunityId =: recId]) {
            system.debug(oppLineItem);
            prodDataList.add(new ProductData(oppLineItem));
        }

        return prodDataList;

    }

    // @AuraEnabled
    // public static String updateOppLineItens(String jsonProdList){
    //     String oppId;
    //     Map<Id, ProductData> mapKeyToProdData = new Map<Id, ProductData>();
    //     List<ProductData> listProdData = (List<ProductData>)JSON.deserialize(jsonProdList, List<ProductData>.class);
    //     for (ProductData prodData : listProdData) {
    //         if (!String.isEmpty(prodData.motivoCancelamento)) {
    //             oppId = prodData.oppId;
    //             mapKeyToProdData.put(prodData.id, prodData);
    //         }
    //     }
    //     List<OpportunityLineItem> listOppLineItemToUpdate = new List<OpportunityLineItem>();
    //     for (OpportunityLineItem oppLineItem : [SELECT Id, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Fornecedor__r.Name, Product2.Description, Quantity, ValorCx__c, CentroDistribuicao__c, OpportunityId, ScoreItem__c, Opportunity.NumeroOrcamento__c, MotivoCancelamento__c
    //                                             FROM OpportunityLineItem WHERE Id IN: mapKeyToProdData.keySet()]) {
    //         oppLineItem.MotivoCancelamento__c = mapKeyToProdData.get(oppLineItem.Id).motivoCancelamento;
    //         listOppLineItemToUpdate.add(oppLineItem);
    //     }

    //     system.debug(listOppLineItemToUpdate);

    //     if (!listOppLineItemToUpdate.isEmpty()) {
    //         OpportunityTH.disableTrigger();
    //         update listOppLineItemToUpdate;
    //         OpportunityTH.enableTrigger();
    //     }
    //     return oppId;
    // }

    @AuraEnabled
    public static String cloneBudget(String jsonProdList){
        String oppId;
        String newOppId;
        Boolean allItensCanceled = true;
        Boolean hasCancelItem = false;
        system.debug(jsonProdList);
        Map<String, ProductData> mapKeyToProdData = new Map<String, ProductData>();
        List<OpportunityLineItem> listOppLineItemToUpdate = new List<OpportunityLineItem>();
        List<ProductData> listProdData = (List<ProductData>)JSON.deserialize(jsonProdList, List<ProductData>.class);
        for (ProductData prodData : listProdData) {
            oppId = prodData.oppId;
            if (!String.isEmpty(prodData.motivoCancelamento)) {
                mapKeyToProdData.put(prodData.chave, prodData);
                hasCancelItem = true;
            } else {
                allItensCanceled = false;
            }
        }

        system.debug(oppId);

        Date today = Date.today();
        Opportunity contextOpportunity = null;
        for (Opportunity o : [SELECT Id, AprovadoComercial__c, AprovadoPricing__c, CanalEntrada__c, CanalVendas__c, Pricebook2Id,
                                ClienteRecebedor__c, CondicaoPagamento__c, ForecastCategoryName,
                                ContatoOrcamento__c, ContractId, SyncedQuoteId, CloseDate, EnviarAprovacao__c, MargemAlvo__c,
                                FormaPagamento__c, Margem__c, MotivoCancelamento__c, NecessitaAprovacaoComercial__c, NecessitaAprovacaoPricing__c, 
                                AccountId, Name, NumeroOrcamento__c, Observacoes__c, Description,  ObservacoesCliente__c, CampaignId, LeadSource, 
                                IsPrivate, IqScore, PrazoValidade__c, Probability, NextStep, TotalOpportunityQuantity, QuantidadeProrrogamentos__c,
                                RecallProcesso__c, ExpectedRevenue, RejeicaoProcesso__c, Score__c, StageName, StatusAprovacao__c, Idportalcotacoes__c,
                                RecordTypeId, Type
                              FROM Opportunity WHERE Id = :oppId]) {            
            o.StageName = 'Fechado/Perdido';
            contextOpportunity = o;
        }

        Opportunity newOpportunity = new Opportunity();
        system.debug('contextOpportunity: ' + contextOpportunity);
        if (contextOpportunity != null) {
            newOpportunity.OrcamentoOriginal__c           = oppId;
            newOpportunity.AprovadoComercial__c           = false;
            newOpportunity.AprovadoPricing__c             = false;
            newOpportunity.CanalEntrada__c                = contextOpportunity.CanalEntrada__c;
            newOpportunity.CanalVendas__c                 = contextOpportunity.CanalVendas__c;
            newOpportunity.Pricebook2Id                   = contextOpportunity.Pricebook2Id;
            newOpportunity.ClienteRecebedor__c            = contextOpportunity.ClienteRecebedor__c;
            newOpportunity.CondicaoPagamento__c           = contextOpportunity.CondicaoPagamento__c;
            newOpportunity.ForecastCategoryName           = contextOpportunity.ForecastCategoryName;
            newOpportunity.ContatoOrcamento__c            = contextOpportunity.ContatoOrcamento__c;
            newOpportunity.ContractId                     = contextOpportunity.ContractId;
            newOpportunity.SyncedQuoteId                  = contextOpportunity.SyncedQuoteId;
            newOpportunity.CloseDate                      = contextOpportunity.PrazoValidade__c == null ? null : today.addDays(Integer.valueOf(contextOpportunity.PrazoValidade__c));
            newOpportunity.EnviarAprovacao__c             = false;
            newOpportunity.FormaPagamento__c              = contextOpportunity.FormaPagamento__c;
            newOpportunity.MotivoCancelamento__c          = contextOpportunity.MotivoCancelamento__c;
            newOpportunity.Idportalcotacoes__c            = contextOpportunity.Idportalcotacoes__c;
            newOpportunity.NecessitaAprovacaoComercial__c = false;
            newOpportunity.NecessitaAprovacaoPricing__c   = false;
            newOpportunity.AccountId                      = contextOpportunity.AccountId;
            newOpportunity.Name                           = contextOpportunity.Name;
            newOpportunity.Observacoes__c                 = contextOpportunity.Observacoes__c;
            newOpportunity.Description                    = contextOpportunity.Description;
            newOpportunity.ObservacoesCliente__c          = contextOpportunity.ObservacoesCliente__c;
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
            newOpportunity.StageName                      = 'Em digitação';
            newOpportunity.RecordTypeId                   = contextOpportunity.RecordTypeId;
            newOpportunity.Type                           = contextOpportunity.Type;

            system.debug('allItensCanceled: ' + allItensCanceled);
            system.debug('hasCancelItem: ' + hasCancelItem);
            if (!allItensCanceled && hasCancelItem) {
                insert newOpportunity;
            }

            newOppId = newOpportunity.id;

            List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();

            for (OpportunityLineItem oLineItem : [SELECT Id, Custo__c, Imposto__c, CategoriaComercial__c, CentroDistribuicao__c, ProductCode, ServiceDate, Discount, Description, PricebookEntryId,
                                                    ForaMalha__c, Fornecedor__c, ItemCampanha__c, JustificativaDesconto__c, Lote__c, MargemAlvo__c, MargemAtual__c, cnpjCD__c, MotivoCancelamento__c, 
                                                    Name, NumeroAnvisa__c, OpportunityId, ListPrice, UnitPrice, TotalPrice, PrincipioAtivo__c, Product2Id, Quantity, ScoreBU__c, ScoreItem__c, ScoreMix__c,
                                                    QuantidadeUn__c, ScoreAlvo__c, ScoreAtual__c, Subtotal, Temperatura__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, ValorMalha__c, ObservacaoCancelamento__c,
                                                    ValorTotal__c, Vendedor__c
                                                  FROM OpportunityLineItem WHERE OpportunityId =: oppId]) {
                if (mapKeyToProdData.get(oLineItem.id + '_' + oLineItem.CNPJCD__c) != null) {
                    system.debug('mapKeyToProdData.get(oLineItem.Id): ' + mapKeyToProdData.get(oLineItem.id + '_' + oLineItem.CNPJCD__c));
                    system.debug(mapKeyToProdData.get(oLineItem.id + '_' + oLineItem.CNPJCD__c).motivoCancelamento);
                    oLineItem.MotivoCancelamento__c = mapKeyToProdData.get(oLineItem.id + '_' + oLineItem.CNPJCD__c).motivoCancelamento;
                    oLineItem.ObservacaoCancelamento__c = mapKeyToProdData.get(oLineItem.id + '_' + oLineItem.CNPJCD__c).obsCancelamento;
                    listOppLineItemToUpdate.add(oLineItem);
                } else if (!allItensCanceled){
                    oLineItem.MotivoCancelamento__c         = '';
                    listOppLineItemToUpdate.add(oLineItem);
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
                    newOppLineItem.ValorUn__c               = oLineItem.ValorUn__c;
                    newOppLineItem.ValorTotal__c            = oLineItem.ValorTotal__c;
                    newOppLineItem.Vendedor__c              = oLineItem.Vendedor__c;
                    newOppLineItem.ObservacaoCancelamento__c = oLineItem.ObservacaoCancelamento__c;
    
                    newOppLineItemList.add(newOppLineItem);
                }
            }

            if (!newOppLineItemList.isEmpty() && hasCancelItem){
                insert newOppLineItemList;
            }
            if (contextOpportunity != null && hasCancelItem) {
                OpportunityTH.disableTrigger();
                update contextOpportunity;
                OpportunityTH.enableTrigger();
            }
            
        }        

        if (!listOppLineItemToUpdate.isEmpty()) {
            OpportunityTH.disableTrigger();
            update listOppLineItemToUpdate;
            OpportunityTH.enableTrigger();
        }

        system.debug('newOpportunity: ' + newOpportunity);
        system.debug('newOppId: ' + newOppId);

        return newOppId == null ? oppId : newOppId;
    }

    public class ProductData {
        @auraEnabled public String id                 {get;set;}
        @auraEnabled public String chave              {get;set;}
        @auraEnabled public String prodId             {get;set;}
        @auraEnabled public String name               {get;set;}
        @auraEnabled public String code               {get;set;}
        @auraEnabled public String fornecedor         {get;set;}
        @auraEnabled public String pAtivo             {get;set;}
        @auraEnabled public String cd                 {get;set;}
        @auraEnabled public Decimal quantidade        {get;set;}
        @auraEnabled public Decimal valor             {get;set;}
        @auraEnabled public String valorFormatado     {get;set;}
        @auraEnabled public String oppId              {get;set;}
        @auraEnabled public String oppNumber          {get;set;}
        @auraEnabled public Decimal scoreItem         {get;set;}
        @auraEnabled public String motivoCancelamento {get;set;}
        @auraEnabled public String obsCancelamento    {get;set;}
        @auraEnabled public Boolean desabilitarMotivo {get;set;}


        public ProductData(OpportunityLineItem item) {
            this.id                 = item.Id;
            this.chave              = item.Id + '_' + item.CNPJCD__c;
            this.prodId             = item.Product2.Id;
            this.name               = item.Product2.Name;
            this.code               = item.Product2.ProductCode;
            this.fornecedor         = item.Product2.Fornecedor__r.Name;
            this.pAtivo             = item.Product2.Description;
            this.cd                 = item.CentroDistribuicao__c;
            this.quantidade         = item.Quantity;
            this.valor              = item.ValorCx__c;
            this.valorFormatado     = '';
            this.oppId              = item.OpportunityId;
            this.oppNumber          = item.Opportunity.NumeroOrcamento__c;
            this.scoreItem          = item.ScoreItem__c;
            this.motivoCancelamento = item.MotivoCancelamento__c;
            this.obsCancelamento    = item.ObservacaoCancelamento__c;
            this.desabilitarMotivo  = false;
        }
    }
}
