public without sharing class ProductShelfLifeController {

    @AuraEnabled(cacheable=true)
    public static List<LoteResponse> getLotes(String clienteCGC, String productCode) {
		Integracoes__c customSettingsGetLotes = Integracoes__c.getValues('InformaticaConsultaLotes');
        Blob headerValue = Blob.valueOf(customSettingsGetLotes.User__c + ':' + customSettingsGetLotes.Password__c);
        Map<String, ItemCampanha__c> mapItemCampanhaLoteNameToCampanha = getMapLoteNameItemCampanhaToCampanha(productCode);
        Map<String, LoteResponse> mapLoteNameToLote = new Map<String, LoteResponse>();
        List<LoteResponse> loteList = new List<LoteResponse>();
        HttpResponse response = new HttpResponse();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(customSettingsGetLotes.Endpoint__c);
        request.setMethod(customSettingsGetLotes.Method__c);
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', '*/*');
        request.setTimeout(120000);
        request.setBody(JSON.serializePretty(new LoteRequest(clienteCGC, productCode)));

        try {
            String resultResponseString = '';
            response = new Http().send(request);
            resultResponseString = response.getBody();
            
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201) {        
                LoteResponseList responseFromIntegration = (LoteResponseList) JSON.deserialize(resultResponseString, LoteResponseList.class);
                loteList = responseFromIntegration.estoque;
                
                if(!mapItemCampanhaLoteNameToCampanha.isEmpty()) {
                    for(LoteResponse iLoteResponse : loteList) {
                        if(mapItemCampanhaLoteNameToCampanha.containsKey(iLoteResponse.lote)) {
                            iLoteResponse.setFields(true, mapItemCampanhaLoteNameToCampanha.get(iLoteResponse.lote).PrecoUnitario__c, mapItemCampanhaLoteNameToCampanha.get(iLoteResponse.lote).PrecoMinimo__c);
                            mapLoteNameToLote = getMapLoteNameToLote(iLoteResponse, mapLoteNameToLote);
                        } else {
                            iLoteResponse.setFields(false, 0.0, 0.0);
                            mapLoteNameToLote = getMapLoteNameToLote(iLoteResponse, mapLoteNameToLote);
                        }
                    }
                } else {
                    for(LoteResponse iLoteResponse : loteList) {
                        iLoteResponse.setFields(false, 0.0, 0.0);
                        mapLoteNameToLote = getMapLoteNameToLote(iLoteResponse, mapLoteNameToLote);
                    }
                }
            }

            System.debug(resultResponseString);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        if(!mapLoteNameToLote.isEmpty()) {
            return mapLoteNameToLote.values();
        } else {
            if(!loteList.isEmpty()) return loteList;
            else return null;
        }
    }

    private static Map<String, ItemCampanha__c> getMapLoteNameItemCampanhaToCampanha(String productCode) {
        Map<String, ItemCampanha__c> mapItemCampanhaLoteNameToCampanha = new Map<String, ItemCampanha__c>();

        for(ItemCampanha__c iItemCampanha : [
            SELECT Id, CodigoProduto__c, Lote__c, PrecoMinimo__c, PrecoUnitario__c 
            FROM ItemCampanha__c 
            WHERE CodigoProduto__c =: productCode
            AND RecordType.Name = 'Item de campanha de shelf life'
        ]) {
            mapItemCampanhaLoteNameToCampanha.put(iItemCampanha.Lote__c, iItemCampanha);
        }

        return mapItemCampanhaLoteNameToCampanha;
    }

    private static Map<String, LoteResponse> getMapLoteNameToLote(LoteResponse iLoteResponse, Map<String, LoteResponse> mapLoteNameToLote) {
        if(mapLoteNameToLote.containsKey(iLoteResponse.lote)) {
            mapLoteNameToLote.get(iLoteResponse.lote).estoque = String.valueOf(Decimal.valueOf(mapLoteNameToLote.get(iLoteResponse.lote).estoque) + Decimal.valueOf(iLoteResponse.estoque));
        } else {
            mapLoteNameToLote.put(iLoteResponse.lote, iLoteResponse);
        }

        return mapLoteNameToLote;
    }

    @TestVisible
    private class LoteRequest {
        public String cnpj;
        public String produto;
        
        public LoteRequest (String clienteCgc, String productCode) {
            cnpj    = clienteCgc;
            produto = productCode;
        }
    }

    @TestVisible
    private class LoteResponseList {
        public List<LoteResponse> estoque;
    }

    @TestVisible
    private class LoteResponse {
        @AuraEnabled public String cod_produto;
        @AuraEnabled public String cod_produto_polo;
        @AuraEnabled public String descricao;
        @AuraEnabled public String lote;
        @AuraEnabled public String validade;
        @AuraEnabled public String cod_operacao_logistica;
        @AuraEnabled public String cod_operacao_logistica_polo;
        @AuraEnabled public String id_endereco;
        @AuraEnabled public String endereco;
        @AuraEnabled public String endereco_completo;
        @AuraEnabled public String ean13;
        @AuraEnabled public String id_lote_classificacao;
        @AuraEnabled public String id_lote_classificacao_polo;
        @AuraEnabled public String estoque;
        @AuraEnabled public String retido;
        @AuraEnabled public String cod_situacao;
        @AuraEnabled public String divergencia;
        @AuraEnabled public String cod_distribuicao;
        @AuraEnabled public String data_fabricacao;
        @AuraEnabled public Boolean is_shelflife = false;
        @AuraEnabled public Decimal minimum_price = 0.0;
        @AuraEnabled public Decimal maximum_price = 0.0;

        private void setFields(Boolean isShelfLife, Decimal maximumPrice, Decimal minimumPrice) {
            this.is_shelflife  = isShelfLife;
            this.minimum_price = minimumPrice;
            this.maximum_price = maximumPrice;
        }
    }
}