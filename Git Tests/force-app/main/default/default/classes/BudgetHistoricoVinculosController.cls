public with sharing class BudgetHistoricoVinculosController {
    @AuraEnabled
    public static StandardResponse getHistoricoVinculos(String idPortalItem, String oppId){
        StandardResponse response = new StandardResponse();
        
        if(String.isBlank(idPortalItem)){
            return response.addError('É necessário o IdPortal__c do item para consultar o histórico de vínculos.');
        }
        try {

            List<VinculoData> historicoList = new List<VinculoData>();
            QuoteItem__c qItem = BudgetDetailSelector.getQuoteitemWithHistory(idPortalItem, oppId);
            if(
                qItem != null &&
                String.isNotEmpty(qItem.ProdutosVinculadosAnteriormente__c) &&
                qItem.ProdutosVinculadosAnteriormente__c != '[]'
            ){
                List<VinculoDataDTO> vinculoList = (List<VinculoDataDTO>)JSON.deserialize(qItem.ProdutosVinculadosAnteriormente__c, List<VinculoDataDTO>.class);
                Map<String, VinculoDataDTO> vinculoByProdCodeMap = new Map<String, VinculoDataDTO>(); 
                for(VinculoDataDTO vinculo : vinculoList){
                    vinculoByProdCodeMap.put(vinculo.codigoProdutoERP, vinculo);
                }
                Map<Id, Product2> productMap = BudgetDetailSelector.getProductMapFromCode(vinculoByProdCodeMap.keySet());
                Map<String, Product2> productMapByCode = new Map<String, Product2>();
                for(Product2 prod : productMap.values()){
                    productMapByCode.put(prod.ProductCode, prod);
                }

                List<AggregateResult> estoqueAggregateList = BudgetDetailSelector.getEstoqueAggregated(
                    qItem.OpportunityId__r.AccountId,
                    productMap.keySet()
                );
                Map<String, Decimal> estoqueMap = BudgetDetailController.processEstoqueAggregated(estoqueAggregateList);
                    system.debug(qItem.OpportunityId__r.AccountId);
                    system.debug(productMap.keySet());
                    
                List<AggregateResult> oppLineItemAggrList = BudgetDetailSelector.getLastOpportunityLineItemAggr(qItem.OpportunityId__r.AccountId, productMap.keySet());
                Map<String, String> mapLastOLIByProdCode = processOppLineItemAggregated(oppLineItemAggrList);
                Map<Id, OpportunityLineItem> oppLineItemMap = BudgetDetailSelector.getLastOpportunityLineItemMap(mapLastOLIByProdCode.values());
                
                for(Product2 product : productMapByCode.values()){
                    OpportunityLineItem oppLineItem = mapLastOLIByProdCode.get(product.ProductCode) != null ? oppLineItemMap.get(mapLastOLIByProdCode.get(product.ProductCode)) : null;
                    historicoList.add(new VinculoData(
                        vinculoByProdCodeMap.get(product.ProductCode),
                        product,
                        estoqueMap.get(product.ProductCode),
                        oppLineItem
                    ));
                }
            }
            response.setData('vinculos', historicoList);

        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static Map<String, String> processOppLineItemAggregated(List<AggregateResult> oppLineItemAggrList){
        Map<String, String> oppLineItemMap = new Map<String, String>();
        for(AggregateResult aggrResult : oppLineItemAggrList){
            oppLineItemMap.put((String)aggrResult.get('ProductCode'), (String)aggrResult.get('id'));
        }
        return oppLineItemMap;
    }

    public class VinculoDataDTO {
        public String codigoProdutoERP;	//123
        public String bu;	//Materiais
        public String mesa;	//A
        public String vendedor;	//001234
        public String createdAt;	//2021-11-11T12:14:19.000Z
        public String updateAt;
        public Decimal fatorConversao;
        public String tipoConversaoUnidadeMedida;
    }

    public class VinculoData {
        @AuraEnabled public String idCustomer;
        @AuraEnabled public String nome;
        @AuraEnabled public String id;
        @AuraEnabled public String estoque;
        @AuraEnabled public String prodCode;
        @AuraEnabled public String unidadePrincipal;
        //@AuraEnabled public Decimal quantidadeCx; ainda não foi decidido
        @AuraEnabled public String principioAtivo;
        @AuraEnabled public String fornecedor;
        @AuraEnabled public String lastOferDate;
        @AuraEnabled public String lastOferStage;
        @AuraEnabled public Decimal lastOferAmount;
        @AuraEnabled public String tipoConversao;
        @AuraEnabled public Decimal fatorConversao;
        @AuraEnabled public String CategoriaComercial;
        @AuraEnabled public String createdAt;
        @AuraEnabled public String updateAt;

        // usado para mostrar os valores de um único item solicitado, getHistoricoVinculos
        public VinculoData(VinculoDataDTO vinculo, Product2 prod, Decimal estoqueValue, OpportunityLineItem lastItem) {
            
            this.nome               = prod.Name;
            this.id                 = prod.Id;
            this.prodCode           = prod.ProductCode;
            this.unidadePrincipal   = prod.UnidadeMedida__c;
            this.principioAtivo     = prod.Description;
            this.fornecedor         = prod.Fornecedor__r?.Name;
            this.CategoriaComercial = prod.CategoriaComercial__c;
            this.estoque = estoqueValue == null ? 'Informação não disponível' : String.valueOf(estoqueValue);
            
            if(vinculo != null){
                this.fatorConversao     = vinculo.fatorConversao;
                this.tipoConversao      = vinculo.tipoConversaoUnidadeMedida;
                this.createdAt = String.isNotBlank(vinculo.createdAt) ? vinculo.createdAt : null;
                this.updateAt = String.isNotBlank(vinculo.updateAt) ? vinculo.updateAt : null;
            }

            if(lastItem != null){
                
                this.fatorConversao         = lastItem.FatorConversao__c;
                this.tipoConversao          = lastItem.TipoConversao__c;
                this.lastOferDate           = lastItem.CreatedDate.formatGMT('dd/MM/yyyy');
                this.lastOferAmount         = lastItem.ValorTotal__c > 0 ? lastItem.ValorTotal__c : lastItem.UnitPrice;
                this.lastOferStage          = lastItem.Opportunity.Probability == 100 ? 'Ganha' : 'Perdida';
            }

        }
    }
}
