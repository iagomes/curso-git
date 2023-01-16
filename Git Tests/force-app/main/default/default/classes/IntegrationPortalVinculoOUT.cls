global without sharing class IntegrationPortalVinculoOUT {

    public static final Integer MAX_ROWS = 100;

    @future(callout=true)
    public static void sendAsync(Set<Id> quoteItemIds) {
        send(quoteItemIds);
    }

    public static StandardResponse send(Set<Id> quoteItemIds) {
        RequestData reqData;
        List<Setorizacao__c> setorizacao;
        List<QuoteItem__c> quoteItems;
        HttpRequest req                     = new HttpRequest();
        HttpResponse resp                   = new HttpResponse();
        StandardResponse response           = new StandardResponse();
        Integracoes__c apiSettings          = Integracoes__c.getValues('InformaticaAtualizarVinculo');
        String method                       = apiSettings.Method__c;
        String endpoint                     = apiSettings.Endpoint__c;
        String authorizationHeader          = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiSettings.User__c + ':' + apiSettings.Password__c));

        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');

        try {
            
            List<Opportunity> lstOpps = [
                SELECT Id,
                    Account.CNPJ__c,
                    Integradora__c,
                    IdIntegrator__c,
                    ExternalPortal__c,
                    CanalEntrada__c,
                    (
                        SELECT Id,
                            Categoria__c,
                            IdCustomer__c,
                            IdIntegrator__c,
                            OpportunityId__c,
                            Product__r.ProductCode,
                            VendedorRespondeu__r.CodigoUsuario__c,
                            LastModifiedBy.CodigoUsuario__c
                        FROM QuoteItems__r 
                        WHERE (StatusIntegracaoVinculoProdutos__c = 'Não Integrado' OR StatusIntegracaoVinculoProdutos__c = '') AND Id IN: quoteItemIds
                        LIMIT :MAX_ROWS
                    )
                FROM Opportunity 
                WHERE Id IN (SELECT OpportunityId__c FROM QuoteItem__c WHERE (StatusIntegracaoVinculoProdutos__c = 'Não Integrado' OR StatusIntegracaoVinculoProdutos__c = '') AND Id IN: quoteItemIds)
                LIMIT :MAX_ROWS
            ];

                
            Boolean hasError = false;
            String body;

            if(!lstOpps.isEmpty()){

                reqData = new RequestData(lstOpps);
            
                body = JSON.serialize(reqData);
                
                req.setBody(body);
                resp = new Http().send(req);
                
                response.setData('response', resp.getBody());
    
                List<QuoteItem__c> quoteItemToUpdate = new List<QuoteItem__c>();
    
                if(resp.getStatusCode() != 200 && resp.getStatusCode() != 201){
                    
                    hasError = true;
                    for(Opportunity opp: lstOpps){
                        for(QuoteItem__c qItem: opp.QuoteItems__r){
                            quoteItemToUpdate.add(new QuoteItem__c(
                                Id = qItem.Id,
                                StatusIntegracaoVinculoProdutos__c = 'Falha na Integração'
                            ));
                        }
                    }
    
                } else {
                    
                    for(Opportunity opp: lstOpps){
                        for(QuoteItem__c qItem: opp.QuoteItems__r){
                            quoteItemToUpdate.add(new QuoteItem__c(
                                Id = qItem.Id,
                                StatusIntegracaoVinculoProdutos__c = 'Integrado'
                            ));
                        }
                    }
                }
                    
                update quoteItemToUpdate;
    
                if(hasError){
                    response.addError('Falha na integração');
                }
                
                IntegrationUtils.WSLog('Vinculo de Produtos', 'Outbound', body, resp.getBody(), hasError, endpoint, response.code);

            } else {

                IntegrationUtils.WSLog('Vinculo de Produtos', 'Outbound', body, 'Não há vinculos a serem integrados.', hasError, endpoint, response.code);
            }

        } catch (Exception e) {
            response.addError(e);
        }
        return response;
    }
    
	public class RequestData {
		public List<OrcamentosCls> orcamentos { get; set; }

        public RequestData(List<Opportunity> lstOpps){
            this.orcamentos = new List<OrcamentosCls>();
            for(Opportunity opp: lstOpps){
                this.orcamentos.add(new OrcamentosCls(opp));
            }
        }
	}

	public class OrcamentosCls {
		public List<ItemsCls> items { get; set; }
		public String id { get; set; }
		public String integradoraId { get; set; }
		public String integradora { get; set; }
		public CustomerCls cliente { get; set; }

        public OrcamentosCls(Opportunity opp){
            this.id = opp.ExternalPortal__c;
            this.integradoraId = opp.IdIntegrator__c;
            this.integradora = opp.CanalEntrada__c;
            this.cliente = new CustomerCls(opp.Account);

            this.items = new List<ItemsCls>();
            for(QuoteItem__c item: opp.Quoteitems__r){
                this.items.add(new ItemsCls(item));
            }
        }
	}

	public class ItemsCls {
		public String codigoProduto { get; set; }
		public String vendedorRespondeu { get; set; }
		public String codigoProdutoErp { get; set; }
		public String mesa { get; set; }
		public String bu { get; set; }

        public ItemsCls(QuoteItem__c item){
            this.codigoProduto = item.IdCustomer__c;
            this.vendedorRespondeu = item.LastModifiedBy.CodigoUsuario__c;//item.VendedorRespondeu__r.CodigoUsuario__c;
            this.codigoProdutoErp = item.Product__r.ProductCode;
            this.bu = String.isBlank(item.Categoria__c) ? '' : item.Categoria__c;
            this.mesa = '';
        }
	}

	public class CustomerCls {
		public String cnpj { get; set; }

        public CustomerCls(Account acc){
            if(acc != null){
                this.cnpj = acc.CNPJ__c;
            }
        }
	}
}
