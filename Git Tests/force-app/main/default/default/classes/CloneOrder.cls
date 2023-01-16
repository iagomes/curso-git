public without sharing class CloneOrder {

    @InvocableMethod(label='Clone Order' 
                    description='Button to clone the order and its items')
    public static List<String> flowCloneOrder(List<FlowInputs> flowInputs) {
        Id ordId = null;
        Id accId = null;
        for (FlowInputs flowInput : flowInputs) {
            ordId = flowInput.ordId;
            accId = flowInput.accId;
        }
        Id MOTHERORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();
        Id ACC_ORDER_RECORDTYPE   = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoContaOrdem').getRecordTypeId(); 
        
        // Pricebook2 bionexoPB = [SELECT Id FROM Pricebook2 WHERE ExternalId__c = 'B01' LIMIT 1];
        // Boolean isBionexo = false;
        Account newAccount = [SELECT Id, TabelaPrecos__c FROM Account WHERE Id = :accId LIMIT 1];

        Order contextOrder = null;
        for (Order o : [SELECT Id, AprovadoComercial__c, AprovadoPricing__c, CanalEntrada__c, Pricebook2Id, CustomerAuthorizedById,
                                CNPJCD__c, BillToContactId, CompartilhamentoRealizado__c, CondicaoPagamento__c, OrderReferenceNumber,
                                ShipToContactId, ContatoOrcamento__c, QuoteId, CPF__c, CodigoPedido__c, ExternalId__c, ActivatedDate, DatasParcelas__c, 
                                DataUltimaModificacao__c, CompanyAuthorizedDate, CustomerAuthorizedDate, DataDivisaoParcelas__c, DiaParcelas__c,
                                EffectiveDate, EndDate, PoDate, DataEntrega__c, CompanyAuthorizedById, EnderecoEntrega__c, ClienteRecebedor__c, 
                                EnderecoRecebedor__c, EnviarAprovacao__c, ErroIntegracaoAprovacao__c, ErroIntegracaoCancelamento__c, PedidoPai__r.AccountId,
                                ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, FormaPagamento__c, GerarBoleto__c, Margem__c, Frete__c,
                                MensagemErroIntegracaoAprovacao__c, MensagemErroIntegracaoCancelamento__c, MensagemErroIntegracaoConfirmacao__c, 
                                MensagemErroIntegracaoRejeitado__c, ModificadoPor__c, NecessitaAprovacaoComercial__c, NecessitaAprovacaoPricing__c, 
                                AccountId, NomeMedico__c, NomePaciente__c, Name, NumeroNotaFiscal__c, OriginalOrderId, MensagemNF__c, MargemAlvo__c,
                                ContractId, PoNumber, NumeroPedidoCliente__c, Description, OpportunityId, Origem__c, IsReductionOrder,
                                PedidoPai__c, RecallProcesso__c, RejeicaoProcesso__c, Score__c, Status, StatusIntegracao__c, StatusAprovacao__c, Idportalcotacoes__c,
                                TipoOperacao__c, RecordTypeId, TipoFrete__c, Type, ValorFrete__c, ValorTotal__c, Endereco_Entrega__c, PedidoPai__r.Type
                        FROM Order WHERE Id = :ordId]) {
            
            contextOrder = o;
            // if (o.Pricebook2Id == bionexoPB.Id) {
            //     isBionexo = true;
            // }
        }
        Order newOrder = new Order();
        if (contextOrder != null) {
            newOrder.AprovadoComercial__c                  = false;
            newOrder.AprovadoPricing__c                    = false;
            newOrder.CanalEntrada__c                       = contextOrder.CanalEntrada__c;
            newOrder.Pricebook2Id                          = contextOrder.Pricebook2Id;
            newOrder.CustomerAuthorizedById                = contextOrder.CustomerAuthorizedById;
            newOrder.ClienteRecebedor__c                   = contextOrder.ClienteRecebedor__c;
            newOrder.CNPJCD__c                             = contextOrder.CNPJCD__c;
            newOrder.BillToContactId                       = contextOrder.BillToContactId;
            newOrder.CompartilhamentoRealizado__c          = contextOrder.CompartilhamentoRealizado__c;
            newOrder.CondicaoPagamento__c                  = contextOrder.CondicaoPagamento__c;
            newOrder.ShipToContactId                       = contextOrder.ShipToContactId;
            if (accId == contextOrder.AccountId) {
                newOrder.ContatoOrcamento__c                   = contextOrder.ContatoOrcamento__c;
                newOrder.Endereco_Entrega__c                   = contextOrder.Endereco_Entrega__c;
            }
            newOrder.QuoteId                               = contextOrder.QuoteId;
            newOrder.Idportalcotacoes__c                   = contextOrder.Idportalcotacoes__c;

            newOrder.DataUltimaModificacao__c              = contextOrder.DataUltimaModificacao__c;
            newOrder.CompanyAuthorizedDate                 = contextOrder.CompanyAuthorizedDate;
            newOrder.CustomerAuthorizedDate                = contextOrder.CustomerAuthorizedDate;
            newOrder.CreatedDatetime__c                    = Datetime.now();
            newOrder.EffectiveDate                         = contextOrder.EffectiveDate;
            newOrder.EndDate                               = contextOrder.EndDate;
            // newOrder.Frete__c                              = contextOrder.Frete__c;
            newOrder.PoDate                                = contextOrder.PoDate;
            // newOrder.DataEntrega__c                        = contextOrder.DataEntrega__c;
            newOrder.CompanyAuthorizedById                 = contextOrder.CompanyAuthorizedById;
            newOrder.EnderecoEntrega__c                    = contextOrder.EnderecoEntrega__c;
            newOrder.EnderecoRecebedor__c                  = contextOrder.EnderecoRecebedor__c;
            newOrder.EnviarAprovacao__c                    = false;
            newOrder.ErroIntegracaoAprovacao__c            = false;
            newOrder.ErroIntegracaoCancelamento__c         = false;
            newOrder.ErroIntegracaoConfirmacao__c          = false;
            newOrder.ErroIntegracaoRejeitado__c            = false;
            newOrder.FormaPagamento__c                     = contextOrder.FormaPagamento__c;
            newOrder.GerarBoleto__c                        = contextOrder.GerarBoleto__c;
            newOrder.Margem__c                             = contextOrder.Margem__c;
            newOrder.MargemAlvo__c                         = contextOrder.MargemAlvo__c;
            newOrder.MensagemNF__c                         = contextOrder.MensagemNF__c;
            newOrder.MensagemErroIntegracaoAprovacao__c    = null;
            newOrder.MensagemErroIntegracaoCancelamento__c = null;
            newOrder.MensagemErroIntegracaoConfirmacao__c  = null;
            newOrder.MensagemErroIntegracaoRejeitado__c    = null;
            newOrder.ModificadoPor__c                      = contextOrder.ModificadoPor__c;
            newOrder.NecessitaAprovacaoComercial__c        = false;
            newOrder.NecessitaAprovacaoPricing__c          = false;
            newOrder.AccountId                             = accId;
            newOrder.NomeMedico__c                         = contextOrder.NomeMedico__c;
            newOrder.NomePaciente__c                       = contextOrder.NomePaciente__c;
            newOrder.Name                                  = contextOrder.Name;
            newOrder.PedidoClonado__c                      = true;
            newOrder.OrderReferenceNumber                  = contextOrder.OrderReferenceNumber;
            newOrder.ContractId                            = contextOrder.ContractId;
            newOrder.PoNumber                              = contextOrder.PoNumber;
            newOrder.NumeroPedidoCliente__c                = contextOrder.NumeroPedidoCliente__c;
            newOrder.Description                           = contextOrder.Description;
            newOrder.OpportunityId                         = contextOrder.OpportunityId;
            newOrder.Origem__c                             = contextOrder.Origem__c;
            newOrder.IsReductionOrder                      = contextOrder.IsReductionOrder;
            newOrder.OriginalOrderId                       = contextOrder.OriginalOrderId;
            newOrder.PedidoPai__c                          = null;
            newOrder.RecallProcesso__c                     = false;
            newOrder.RejeicaoProcesso__c                   = contextOrder.RejeicaoProcesso__c;
            newOrder.Score__c                              = contextOrder.Score__c;
            newOrder.Status                                = 'Em digitação';
            // newOrder.StatusIntegracao__c                   = contextOrder.StatusIntegracao__c;
            // newOrder.StatusAprovacao__c                    = 'Em digitação';
            newOrder.TipoOperacao__c                       = contextOrder.TipoOperacao__c;
            newOrder.RecordTypeId                          = MOTHERORDER_RECORDTYPE;
            // newOrder.TipoFrete__c                          = contextOrder.TipoFrete__c;
            newOrder.Type                                  = contextOrder.RecordTypeId == MOTHERORDER_RECORDTYPE ? contextOrder.Type : contextOrder.PedidoPai__r.Type;
            // newOrder.ValorFrete__c                         = contextOrder.ValorFrete__c;
            newOrder.ValorTotal__c                         = contextOrder.ValorTotal__c;
            if (contextOrder.RecordTypeId == ACC_ORDER_RECORDTYPE && contextOrder.PedidoPai__r.AccountId != contextOrder.AccountId) {
                newOrder.Endereco_Entrega__c               = null;
                newOrder.ClienteRecebedor__c               = null;
            }

            insert newOrder;

            List<OrderItem> newOrderItemList = new List<OrderItem>();
            Map<Id, Id> prodIdToPBEntryIdMap = new Map<Id, Id>();

            for (OrderItem oi : [SELECT Id, Custo__c, Imposto__c, CentroDistribuicao__c, CodigoProduto__c, ServiceDate, EndDate, Description, ForaMalha__c, ItemCampanha__c, BloqueadoRegionalizacao__c, Laboratorio__c,
                                        QuoteLineItemId, ItemContrato__c, OriginalOrderItemId, Lote__c, MargemAlvo__c, Margem__c, Vendedor__c, PricebookEntryId, Desconto__c, TipoIntegradora__c,
                                        ExternalId__c, OrderId, ListPrice, PrecoTotal__c, TotalPrice, UnitPrice, Product2Id, Quantity, QuantidadeUn__c, ScoreBU__c, ScoreItem__c, ScoreMix__c,
                                        AvailableQuantity, ScoreAlvo__c, ScoreAtual__c, TipoOperacao__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, cnpjCD__c, ValorMalha__c, ValorSugerido__c, Range__c
                                 FROM OrderItem WHERE OrderId = :contextOrder.Id]) {
                
                OrderItem newOrderItem = new OrderItem();
                newOrderItem.CentroDistribuicao__c = oi.CentroDistribuicao__c;
                newOrderItem.ServiceDate           = oi.ServiceDate;
                newOrderItem.EndDate               = oi.EndDate;
                newOrderItem.Description           = oi.Description;
                newOrderItem.ForaMalha__c          = oi.ForaMalha__c;
                newOrderItem.ItemCampanha__c       = oi.ItemCampanha__c;
                newOrderItem.QuoteLineItemId       = oi.QuoteLineItemId;
                newOrderItem.PricebookEntryId      = oi.PricebookEntryId;
                newOrderItem.ItemContrato__c       = oi.ItemContrato__c;
                newOrderItem.OriginalOrderItemId   = oi.OriginalOrderItemId;
                newOrderItem.Lote__c               = oi.Lote__c;
                newOrderItem.MargemAlvo__c         = oi.MargemAlvo__c;
                newOrderItem.cnpjCD__c             = oi.cnpjCD__c;
                newOrderItem.Margem__c             = oi.Margem__c;
                newOrderItem.ExternalId__c         = oi.ExternalId__c;
                newOrderItem.OrderId               = newOrder.Id;
                newOrderItem.PrecoTotal__c         = oi.PrecoTotal__c;
                newOrderItem.UnitPrice             = oi.UnitPrice;
                newOrderItem.Product2Id            = oi.Product2Id;
                newOrderItem.Quantity              = oi.Quantity;
                newOrderItem.QuantidadeUn__c       = oi.QuantidadeUn__c;
                newOrderItem.ScoreAlvo__c          = oi.ScoreAlvo__c;
                newOrderItem.ScoreAtual__c         = oi.ScoreAtual__c;
                newOrderItem.ScoreBU__c            = oi.ScoreBU__c;
                newOrderItem.ScoreItem__c          = oi.ScoreItem__c;
                newOrderItem.ScoreMix__c           = oi.ScoreMix__c;
                newOrderItem.TipoOperacao__c       = oi.TipoOperacao__c;
                newOrderItem.ValidadeMinima__c     = oi.ValidadeMinima__c;
                newOrderItem.ValorCx__c            = oi.ValorCx__c;
                newOrderItem.ValorUn__c            = oi.ValorUn__c;
                newOrderItem.ValorMalha__c         = oi.ValorMalha__c;
                newOrderItem.ValorSugerido__c      = oi.ValorSugerido__c;
                newOrderItem.Range__c              = oi.Range__c;
                newOrderItem.Vendedor__c           = oi.Vendedor__c;

                newOrderItem.Custo__c              = oi.Custo__c;
                newOrderItem.Imposto__c            = oi.Imposto__c;
                newOrderItem.Desconto__c           = oi.Desconto__c;
                newOrderItem.Laboratorio__c        = oi.Laboratorio__c;
                newOrderItem.TipoIntegradora__c    = oi.TipoIntegradora__c;
                newOrderItem.BloqueadoRegionalizacao__c = oi.BloqueadoRegionalizacao__c;

                newOrderItemList.add(newOrderItem);
            }

            if (!newOrderItemList.isEmpty()){
                insert newOrderItemList;
            }
        }
        newOrder = [SELECT Id, OrderNumber FROM Order WHERE Id = :newOrder.id];

        return new List<String>{newOrder.Id};
    }
    
    public class FlowInputs{
    
        @InvocableVariable
        public String ordId;
        
        @InvocableVariable
        public String accId;
    }
}