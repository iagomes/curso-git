public without sharing class OrderCreatePDF {
    
    @InvocableMethod(label='Generate PDF' description='Button to generate the order PDF')
    public static List<String> flowCreateOrderPDF(List<FlowInputs> flowInputsList) {

        Order contextOrder = null;
        Opportunity newOpp = new Opportunity();

        String ordId = null;
        String pdf = null;
        for (FlowInputs flow : flowInputsList) {
            ordId = flow.orderId;
            pdf = flow.pdfChoice;
        }

        OrderItem contextOrdItem;
        for (OrderItem ordItem : [SELECT Id, CentroDistribuicao__c, cnpjCD__c FROM OrderItem WHERE OrderId = :ordId LIMIT 1]) {
            contextOrdItem = ordItem;
        }

        for (Order o : [SELECT Id, AprovadoComercial__c, AprovadoPricing__c, CanalEntrada__c, Pricebook2Id, CustomerAuthorizedById,
                                CNPJCD__c, BillToContactId, CompartilhamentoRealizado__c, CondicaoPagamento__c, OrderReferenceNumber,
                                ShipToContactId, ContatoOrcamento__c, QuoteId, CPF__c, CodigoPedido__c, ExternalId__c, ActivatedDate, 
                                DataUltimaModificacao__c, CompanyAuthorizedDate, CustomerAuthorizedDate, DataDivisaoParcelas__c, DiaParcelas__c,
                                EffectiveDate, EndDate, PoDate, DataEntrega__c, CompanyAuthorizedById, EnderecoEntrega__c, ClienteRecebedor__c, 
                                EnderecoRecebedor__c, EnviarAprovacao__c, ErroIntegracaoAprovacao__c, ErroIntegracaoCancelamento__c, CreatedDate,
                                ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, FormaPagamento__c, GerarBoleto__c, Margem__c, OrderNumber,
                                ModificadoPor__c, AccountId, NomeMedico__c, NomePaciente__c, Name, NumeroNotaFiscal__c, OriginalOrderId, MensagemNF__c, 
                                ContractId, PoNumber, NumeroPedidoCliente__c, Description, OpportunityId, Origem__c, IsReductionOrder, OwnerId,
                                PedidoPai__c, RecallProcesso__c, RejeicaoProcesso__c, Score__c, Status, StatusIntegracao__c, StatusAprovacao__c, 
                                TipoOperacao__c, RecordTypeId, TipoFrete__c, Type, ValorFrete__c, ValorTotal__c, Endereco_Entrega__c, PedidoPai__r.Type
                        FROM Order WHERE Id = :ordId]) {
            
            contextOrder = o;
            Date myDate = Date.newInstance(o.CreatedDate.year(), o.CreatedDate.month(), o.CreatedDate.day());
            // newOpp.CanalEntrada__c        = contextOrder.CanalEntrada__c;
            newOpp.Pricebook2Id           = contextOrder.Pricebook2Id;
            newOpp.ClienteRecebedor__c    = contextOrder.ClienteRecebedor__c;
            newOpp.CondicaoPagamento__c   = contextOrder.CondicaoPagamento__c;
            newOpp.ContatoOrcamento__c    = contextOrder.ContatoOrcamento__c;
            newOpp.ContractId             = contextOrder.ContractId;
            newOpp.CloseDate              = contextOrder.DataEntrega__c;
            newOpp.DataDivisaoParcelas__c = contextOrder.DataDivisaoParcelas__c;
            newOpp.DiaParcelas__c         = contextOrder.DiaParcelas__c;
            newOpp.DataEmissaoPedido__c   = myDate;
            newOpp.DataPrevistaEntrega__c = contextOrder.DataEntrega__c;
            newOpp.FormaPagamento__c      = contextOrder.FormaPagamento__c;
            newOpp.Margem__c              = contextOrder.Margem__c;
            newOpp.AccountId              = contextOrder.AccountId;
            newOpp.Name                   = contextOrder.OrderNumber;
            newOpp.Observacoes__c         = contextOrder.MensagemNF__c;
            newOpp.Description            = contextOrder.Description;
            newOpp.NumeroPedido__c        = contextOrder.id;
            // newOpp.ObservacoesCliente_    = contextOrder.
            newOpp.TipoFrete__c           = contextOrder.TipoFrete__c;
            newOpp.ValorFrete__c          = contextOrder.ValorFrete__c;
            newOpp.Score__c               = contextOrder.Score__c;
            newOpp.StageName              = 'Aprovado';
            newOpp.RecordTypeId           = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Orcamento').getRecordTypeId();
            if (contextOrder.RecordTypeId != OrderHelper.MOTHERORDER_RECORDTYPE) {
                newOpp.CentroDistribuicao__c = contextOrdItem.CentroDistribuicao__c;
                newOpp.CNPJCD__c             = contextOrdItem.CNPJCD__c;
            }
            newOpp.EnderecoEntregaPedido__c = contextOrder.EnderecoEntrega__c;
        }

        insert newOpp;


        Quote newQuote = new Quote(
            name           = contextOrder.OrderNumber,
            OpportunityId  = newOpp.Id,
            OwnerId        = contextOrder.OwnerId,
            ContactId      = newOpp.ContatoOrcamento__c,
            ExpirationDate = newOpp.CloseDate
        );
        insert newQuote;

        List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();

        List<OrderItem> newOrdItemList = new List<OrderItem>();

        for (OrderItem ordItem : [SELECT Id, CentroDistribuicao__c, CodigoProduto__c, ServiceDate, EndDate, Description, ForaMalha__c, ItemCampanha__c, 
                                        QuoteLineItemId, ItemContrato__c, OriginalOrderItemId, Lote__c, MargemAlvo__c, Margem__c, Vendedor__c, PricebookEntryId,
                                        ExternalId__c, OrderId, ListPrice, PrecoTotal__c, TotalPrice, UnitPrice, Product2Id, Quantity, QuantidadeUn__c,
                                        AvailableQuantity, ScoreAlvo__c, ScoreAtual__c, TipoOperacao__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, cnpjCD__c,
                                        Product2.ProductCode, Product2.Fornecedor__r.Name, Product2.FatorConversao__c, Product2.name, Product2.UnidadeMedida__c
                                  FROM OrderItem WHERE OrderId = :contextOrder.Id Order by PosicaoItem__c]) {
            
            QuoteLineItem quoteLineItem         = new QuoteLineItem();
            quoteLineItem.CodigoItem__c         = ordItem.Product2.ProductCode;
            quoteLineItem.ServiceDate           = ordItem.ServiceDate;
            quoteLineItem.Description           = ordItem.Description;
            quoteLineItem.Fabricante__c         = ordItem.Product2.Fornecedor__r.Name;
            quoteLineItem.FatorConversao__c     = ordItem.Product2.FatorConversao__c;
            quoteLineItem.Product2Id            = ordItem.Product2Id;
            quoteLineItem.QuoteId               = newQuote.Id;
            quoteLineItem.PricebookEntryId      = ordItem.PricebookEntryId;
            quoteLineItem.Produto__c            = ordItem.Product2.name;
            quoteLineItem.Quantity              = ordItem.Quantity;
            quoteLineItem.UnidadeMedida__c      = ordItem.Product2.UnidadeMedida__c;
            quoteLineItem.ValorCx__c            = ordItem.ValorCx__c;
            quoteLineItem.UnitPrice             = ordItem.ValorCx__c;
            if (contextOrder.RecordTypeId == OrderHelper.MOTHERORDER_RECORDTYPE) {
                quoteLineItem.CentroDistribuicao__c = ordItem.CentroDistribuicao__c;
                quoteLineItem.cnpjCD__c             = ordItem.cnpjCD__c;
            }

            quoteLineItemList.add(quoteLineItem);
        }

        if (!quoteLineItemList.isEmpty()) {
            insert quoteLineItemList;
        }

        getQuoteTemplate(newQuote.id, contextOrder.id, pdf);
        
        return new List<String>{newQuote.id};
    }

    @AuraEnabled
    public static void getQuoteTemplate(Id recordId, Id orderId, String pdf) {
        insertQuoteTemplate(recordId, orderId, pdf);
    }

    @future(callout=true)
    public static void insertQuoteTemplate(Id recordId, Id orderId, String pdf) {

        TemplatePDF__c template = TemplatePDF__c.getValues(pdf);
        String templateId = template.Id__c;

        PageReference pr = new PageReference('/quote/quoteTemplateDataViewer.apexp?id=' + recordId + '&summlid=' + templateId); 

        QuoteDocument qd = new QuoteDocument(); 
        Blob b = !Test.isRunningTest() ? pr.getContentAsPDF() : Blob.valueOf('Test');

        qd.Document = b;
        qd.QuoteId = recordId;
        insert qd;

        Quote contextQuote = null;
        for (Quote quote : [SELECT Id, Opportunity.Name, OpportunityId/*, ContatoOrcamento__c, ContatoOrcamento__r.Email*/ FROM Quote WHERE Id = :recordId]) {
            contextQuote = quote;
        }
        String ordNumber = '';
        for(Order ord : [SELECT id, OrderNumber FROM Order WHERE id = :orderId]){
            ordNumber = ord.OrderNumber;
        }

        ContentVersion ctVersion    = new ContentVersion();
        String attName = 'Pedido - ' + ordNumber +'.pdf';
        ctVersion.Title             = attName;
        ctVersion.PathOnClient      = attName;
        ctVersion.VersionData       = b;
        insert ctVersion;

        ContentDocumentLink cdl     = new ContentDocumentLink();
        cdl.ContentDocumentId       = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: ctVersion.Id].ContentDocumentId;
        cdl.LinkedEntityId          = orderId;
        cdl.ShareType               = 'V';
        cdl.Visibility              = 'AllUsers';
        insert cdl;

        List<Opportunity> oppToDelete = [SELECT Id FROM Opportunity WHERE Id = :contextQuote.OpportunityId];

        List<QuoteLineItem> quoteLineItemListToDelete = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :recordId];

        if (!oppToDelete.isEmpty()) {
            delete oppToDelete;
        }
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String orderId;
        
        @InvocableVariable
        public String pdfChoice;
    }
}
