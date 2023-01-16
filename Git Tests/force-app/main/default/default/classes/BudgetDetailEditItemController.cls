public without sharing class BudgetDetailEditItemController {
    
    @AuraEnabled
    public static StandardResponse getQuoteItemAnswers(String oppId, String idPortal){
        StandardResponse response = new StandardResponse();
        try {
            List<BudgetResposta> answerList = new List<BudgetResposta>(); 
            List<QuoteItem__c> qItemList = BudgetDetailSelector.getQuoteItemsByIdPortal(idPortal, oppId);
            Map<String, String> productsAlreadyUsedMap = verifyProductsAlreadyUsed(qItemList);
            List<AggregateResult> AggregateSetorizationList = BudgetDetailSelector.getUserCategoriesAggregated(oppId);
            List<String> currentUserCategories = processUserCategories(AggregateSetorizationList);
            for(QuoteItem__c qItem : qItemList){
                answerList.add(new BudgetResposta(qItem, currentUserCategories, productsAlreadyUsedMap.get(qItem.Product__c)));
            }
            response.setData(JSON.serialize(answerList));
        } catch (Exception ex) {
            response.addError(ex.getMessage());
            ExceptionUtils.debug(ex);
        }

        return response;
    }

    @AuraEnabled
    public static StandardResponse vincularProduto(String quoteitemId, String productId, String oppId){
        StandardResponse response = new StandardResponse();
        try {
            AutomationsController.stop('QuoteItemTH.statusAndProductReset');

            if(String.isEmpty(productId)){
                return response.addError('Não foi possível identificar o produto.');
            } else if(String.isEmpty(quoteitemId)){
                return response.addError('Não foi possível identificar o item da cotação.');
            }

            Opportunity opp = BudgetDetailSelector.getOpportunity(oppId);
            if(opp.OrcamentoTravado__c == true){
                return response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento', '205');
            }
            QuoteItem__c quoteitem = BudgetDetailSelector.getQuoteItem(quoteitemId);

            if(String.isBlank(opp.CondicaoPagamento__c)){
                response.addError('A condição de pagamento deve ser especificada antes de responder a uma cotação.');
            }

            if(quoteitem.Status__c == 'Resgatado' || quoteitem.Status__c == 'Aprovado'){
                return response.addError('Não é possível alterar o vínculo deste produto, pois já foi gerado um pedido.');
                
            } else if(quoteitem.OpportunityLineItem__c != null && quoteitem.Product__c != productId){
                delete new OpportunityLineItem(Id = quoteitem.OpportunityLineItem__c);
            }
            if(quoteitem.Product__c != productId){
                quoteitem.CNPJCD__c = null;
                quoteitem.UnitPrice__c = null;
                quoteitem.OpportunityLineItem__c = null;
                quoteItem.Product__c = productId;
                quoteitem.StatusIntegracaoVinculoProdutos__c = 'Não integrado';
                quoteItem.DataHoraResposta__c = system.now();
                quoteItem.Status__c = 'Vinculado';
                quoteItem.TabulacaoN1__c = null;
                quoteItem.PaymentConditionByDC__c = null;
                update quoteItem;
            }

            Map<String, String> productsAlreadyUsedMap = verifyProductsAlreadyUsed(new List<QuoteItem__c>{quoteitem});
            response.setData(JSON.serialize(new BudgetResposta(BudgetDetailSelector.getQuoteItem(quoteitemId), productsAlreadyUsedMap.get(quoteItem.Product__c))));
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse adicionarResposta(String idPortal, String oppId, String selectedBU){
        StandardResponse response = new StandardResponse();
        QuoteItem__c qItem = BudgetDetailSelector.getUniqueQuoteItemByIdPortal(idPortal, oppId);
        Opportunity opp = BudgetDetailSelector.getOpportunity(oppId);
        try { 
            QuoteItem__c newQItem = new QuoteItem__c(
                Categoria__c = selectedBU,
                CustomerDescription__c = qItem.CustomerDescription__c,
                CustomerMeasurementUnit__c = qItem.CustomerMeasurementUnit__c,
                IdPortal__c = qItem.IdPortal__c,
                IdIntegrator__c = qItem.IdIntegrator__c,
                IdCustomer__c = qItem.IdCustomer__c,
                IntegratorMeasurementUnit__c = qItem.IntegratorMeasurementUnit__c,
                OpportunityId__c = oppId,
                ProdutosVinculadosAnteriormente__c = qItem.ProdutosVinculadosAnteriormente__c,
                Quantity__c = qItem.Quantity__c,
                SequenciaOC__c = qItem.SequenciaOC__c,
                Status__c = 'Não Vinculado',
                Vendedor__c = UserInfo.getUserId()
            );
            newQItem.ExternalId__c = opp.ExternalPortal__c + newQItem.IdPortal__C + newQItem.Vendedor__c + Datetime.now();
            insert newQItem;
            BudgetResposta budgetResposta = new BudgetResposta(BudgetDetailSelector.getQuoteItem(newQItem.Id));
            response.setData(JSON.serialize(budgetResposta));
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse changeQuoteItemTabulacao(String jsonReqBody, String oppId){
        StandardResponse response = new StandardResponse();
        try {
            BudgetResposta budgetResposta = (BudgetResposta)JSON.deserialize(jsonReqBody, BudgetResposta.class);
            Opportunity opp = BudgetDetailSelector.getOpportunity(oppId);
            QuoteItem__c qItem = BudgetDetailSelector.getQuoteItem(budgetResposta.id);

            qItem.TabulacaoN1__c = budgetResposta.tabulacaoN1;
            if(budgetResposta.tabulacaoN1 != null){   
                qItem.DataHoraResposta__c = system.now();
                qItem.VendedorRespondeu__c = UserInfo.getUserId();
            }

            if(opp.OrcamentoTravado__c == true){
                response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento','205');
                return response;
            }

            Database.update(qItem);
            Map<String, String> productsAlreadyUsedMap = verifyProductsAlreadyUsed(new List<QuoteItem__c>{qItem});
            response.setData(JSON.serialize(new BudgetResposta(qItem, productsAlreadyUsedMap.get(qItem.Product__c))));
            
            if(opp != null && opp.StageName == 'Novo'){
                update new Opportunity(Id = opp.Id, StageName = 'Em digitação'); 
            }
           
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static List<String> processUserCategories(List<AggregateResult> AggregateSetorizationList){
        List<String> currentUserCategories = new List<String>();
        for(AggregateResult aggrResult : AggregateSetorizationList){
            currentUserCategories.add((String)aggrResult.get('Categoria__c'));
        }
        return currentUserCategories;
    }

    public static Map<String, String> verifyProductsAlreadyUsed(List<QuoteItem__c> qItemList){
        
        Map<String, String> productsAlreadyUsedMap = new Map<String, String>();
        Set<String> currentProducts = new Set<String>();
        for(QuoteItem__c qItem : qItemList){

            if(qItem.Product__c != null){
                currentProducts.add(qItem.Product__c);
            }
        }

        if(!currentProducts.isEmpty()){

            List<QuoteItem__c> qItemUsingSameProductList = BudgetDetailSelector.getQuoteItensUsingSameProduct(
                qItemList[0].OpportunityId__c,
                currentProducts,
                qItemList[0].IdPortal__c
            );

            for(QuoteItem__c qItemSameProd : qItemUsingSameProductList){
                productsAlreadyUsedMap.put(qItemSameProd.Product__c, qItemSameProd.OpportunityLineItem__r.SequenciaOC__c);
            }
        }

        return productsAlreadyUsedMap;
    }
    
    @AuraEnabled
    public static StandardResponse eraseQuoteItemAnswer(String qItemId){
        StandardResponse response = new StandardResponse();
        try {
            QuoteItem__c qItem = BudgetDetailSelector.getQuoteItem(qItemId);
            if(qItem.StatusIntegrationResponse__c != 'Não Respondido'){
                response.setData(JSON.serialize(new BudgetResposta(qItem)));
                return response.addError('Essa resposta ja foi enviada para integração, não é permitido apagar a resposta.');
            }
            
            if(qItem.OpportunityId__r.DataVencimento__c < Datetime.now()){
                response.setData(JSON.serialize(new BudgetResposta(qItem)));
                return response.addError('A cotação venceu, não é permitido apagar a resposta');
            }
            
            QuoteItem__c newQItem = new QuoteItem__c(
                Id = qItemId,
                CNPJCD__c = null,
                PaymentConditionByDC__c = null,
                DataHoraResposta__c = null,
                FatorConversao__c = null,
                OpportunityLineItem__c = null,
                Product__c = null,
                Status__c = 'Não Vinculado',
                TabulacaoN1__c = null,
                TipoConversao__c = null,
                UnitPrice__c = null,
                VendedorRespondeu__c = null
            );
            AutomationsController.stop('QuoteItemTH.statusAndProductReset');
            update newQItem;

            if(qItem.OpportunityLineItem__c != null){
                delete new OpportunityLineItem(Id = qItem.OpportunityLineItem__c);
            }

            response.setData(JSON.serialize(new BudgetResposta(BudgetDetailSelector.getQuoteItem(qItemId))));
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }

        return response;
    }

    public class BudgetResposta {
        
        public String id {get;set;}
        public String categoria {get;set;}
        public String categoriaDesc {get;set;}
        public String categoriaVendedor {get;set;}
        public String categoriaVendedorDesc {get;set;}
        public String comentario {get;set;}
        public String cnpjCd {get;set;}
        public String dataHoraResposta {get;set;}
        public Decimal fatorConversao {get;set;}
        public Decimal fatorConversaoProd {get;set;}
        public Boolean hideEraseButton {get;set;}
        public String idPortal {get;set;}
        public String itemId {get;set;}
        public String marcaProdOfertado {get;set;}
        public String nome {get;set;}
        public String nomeCd {get;set;}
        public String nomeVendedor {get;set;}
        public String principioAtivo {get;set;}
        public String prodCode {get;set;}
        public String prodId {get;set;}
        public String sequenceWithSameProduct {get;set;}
        public String productURL {get;set;}
        public String SequenciaOC {get;set;}
        public String status {get;set;}
        public String tabulacaoN1 {get;set;}
        public String temperatura {get;set;}
        public String tipoConversao {get;set;}
        public String tipoConversaoProd {get;set;}
        public String unidadePrincipal {get;set;}
        public String unidadeSecundaria {get;set;}
        public Decimal unitarioPortal {get;set;}
        public Boolean valorBloqueado {get;set;}
        public String vendedorId {get;set;}

        public BudgetResposta(){}

        public BudgetResposta(QuoteItem__c qItem){
            this(qItem, new List<String>{qItem.Categoria__c}, null);
        }

        public BudgetResposta(QuoteItem__c qItem, String sequenceWithSameProduct){
            this(qItem, new List<String>{qItem.Categoria__c}, sequenceWithSameProduct);
        }

        public BudgetResposta(QuoteItem__c qItem, List<String> currentUserCategories, String sequenceWithSameProduct){
            this.id = qItem.Id;
            this.categoria = qItem.Product__r?.CategoriaComercial__c;
            if(!String.isEmpty(this.categoria)){
                this.categoriaDesc = Utils.getPicklistApi(Product2.CategoriaComercial__c).get(this.categoria);
            }

            this.categoriaVendedor = qItem.Categoria__c;
            if(!String.isEmpty(this.categoriaVendedor)){
                this.categoriaVendedorDesc = Utils.getPicklistApi(Product2.CategoriaComercial__c).get(this.categoriaVendedor);
            }
            
            this.cnpjCd = qItem.CNPJCD__c;
            this.comentario = qItem.OpportunityLineItem__r?.comentarios__c;
            this.dataHoraResposta = String.valueOf(qItem.DataHoraResposta__c);
            this.fatorConversao = qItem.OpportunityLineItem__r?.FatorConversao__c;
            this.fatorConversaoProd = qItem.Product__r?.FatorConversao__c != null ? Decimal.valueOf(qItem.Product__r.FatorConversao__c) : null;
            this.hideEraseButton = this.getHideEraseButton(qItem, currentUserCategories);
            this.idPortal = qItem.IdPortal__c;
            this.itemId = qItem.OpportunityLineItem__c;
            this.marcaProdOfertado = qItem.Product__r?.Fornecedor__r?.Name;
            this.nome = qItem.Product__r.Name;
            this.nomeCd = qItem.OpportunityLineItem__r?.CentroDistribuicao__c;
            this.nomeVendedor = qItem.Vendedor__r?.Name;
            this.principioAtivo = qItem.Product__r?.Description;
            this.prodCode = qItem.Product__r?.ProductCode;
            this.prodId = qItem.Product__c;
            this.sequenceWithSameProduct = sequenceWithSameProduct;
            if(this.prodId != null){
                this.productURL = '/' + qItem.Product__c;
            }
            this.SequenciaOC = qItem.SequenciaOC__c;
            this.status = qItem.Status__c;
            this.tabulacaoN1 = qItem.TabulacaoN1__c;
            this.temperatura = qItem.Product__r?.Temperatura__c;
            this.tipoConversao = qItem.OpportunityLineItem__r?.TipoConversao__c;
            this.tipoConversaoProd = qItem.Product__r?.TipoConversao__c;
            this.unidadePrincipal = qItem.Product__r?.UnidadeMedida__c;
            this.unidadeSecundaria = qItem.Product__r?.SegundaUnidade__c;
            this.unitarioPortal = qItem.OpportunityLineItem__r?.ValorPortal__c;
            this.valorBloqueado = false;
            this.vendedorId = qItem.Vendedor__c;
        }

        public QuoteItem__c buildQuoteItem(){
            return new QuoteItem__c(
                Id = this.id,
                IdPortal__c = this.idPortal,
                Categoria__c = this.categoriaVendedor,
                CNPJCD__c = this.cnpjCd,
                OpportunityLineItem__c = this.itemId,
                Product__c = this.prodId,
                Status__c = this.status,
                TabulacaoN1__c = this.tabulacaoN1,
                Vendedor__c = this.vendedorId
            );
        }

        public OpportunityLineItem buildOpportunityLineItem(Opportunity opp, QuoteItem__c quoteItem, PricebookEntry pbe){
            return new OpportunityLineItem(
                ExternalId__c = (this.id + '_' + this.idPortal + (this.vendedorId != null ? '_' + this.vendedorId : '')),
                IdPortal__c = this.idPortal,
                OpportunityId = opp.Id,
                Product2Id = this.prodId,
                SequenciaOC__c = this.SequenciaOC,
                Status__c = this.status,
                PricebookEntryId = pbe.Id
                // IdCustomer__c = quoteitem.IdCustomer__c,
                // IdIntegrator__c = quoteitem.IdIntegrator__c,
                // CentroDistribuicao__c = cds,
                // CNPJCD__c = cnpjCd,
                // Quantity = quantidade,
                // UnitPrice = valor,
                // ValidadeMinima__c = validadeMinima,
                // ForaMalha__c = foraMalha
            );
        }

        public Boolean getHideEraseButton(QuoteItem__c qItem, List<String> currentUserCategories){
            return (
                String.isEmpty(qItem.TabulacaoN1__c) ||
                qItem.OpportunityId__r.DataVencimento__c < Datetime.now() ||
                qItem.StatusIntegrationResponse__c != 'Não Respondido' ||
                !(
                    currentUserCategories.contains(qItem.Categoria__c) ||
                    qItem.VendedorRespondeu__c == UserInfo.getUserId() ||
                    qItem.Vendedor__c == UserInfo.getUserId()
                )
            );
        }
    }
}
