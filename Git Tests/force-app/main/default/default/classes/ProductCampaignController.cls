public with sharing class ProductCampaignController {

    @AuraEnabled
    public static List<OrderScreenController.ProductData> getProductCampaign(String pricebook, String clienteId, String offSetValue, String searchGenericValue, String searchFabricanteValue, String condPag) {
        system.debug('getProductCampaign');
        List<String> listProdCode = new List<String>();

        Set<String> setCodCampanha = new Set<String>();
        Set<Id> setGroupId = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, String> mapCodCampaignToIdCampaign = new Map<Id, String>();

        fillProdCampaignInfo(setCodCampanha, setGroupId, setAccountId, mapCodCampaignToIdCampaign, condPag);

        system.debug('setCodCampanha: ' + setCodCampanha);
        system.debug('setGroupId: ' + setGroupId);
        system.debug('setAccountId: ' + setAccountId);
        system.debug('mapCodCampaignToIdCampaign: ' + mapCodCampaignToIdCampaign);

        for (ItemCampanha__c campanha : [SELECT Id , NomeProduto__c, NomeProduto__r.ProductCode, PrecoUnitario__c, PrecoMinimo__c, Campanha__r.RecordType.DeveloperName, TipoGatilho__c, VigenciaFinal__c, CNPJCD__c, Campanha__r.EndDate, Lote__c, Campanha__r.Validade__c,
                                Campanha__r.InicioRecorrencia__c, Campanha__r.FimRecorrencia__c, Campanha__r.CondicaoPagamento__c, Campanha__r.Type, Campanha__r.CNPJCD__c, Desconto__c, Campanha__r.CodigoCD__c, Campanha__r.RegrasCampanha__c
                                FROM ItemCampanha__c 
                                WHERE Campanha__r.RecordType.DeveloperName IN ('ContratoShelfLife','Campanha', 'CampanhaVendedor')
                                AND ((Campanha__r.StartDate <= TODAY AND Campanha__r.EndDate >= TODAY)
                                OR (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY))
                                ORDER BY Campanha__r.RecordType.DeveloperName DESC]) {
            system.debug('campanha: ' + campanha);
            if(campanha.Campanha__r.RecordType.DeveloperName == 'ContratoShelfLife'){
                listProdCode.add(campanha.NomeProduto__c);
            }
            if(campanha.Campanha__r.RecordType.DeveloperName == 'Campanha'){
                listProdCode.add(campanha.NomeProduto__c);
            }
            if(campanha.Campanha__r.RecordType.DeveloperName == 'CampanhaVendedor'){
                listProdCode.add(campanha.NomeProduto__c);
            }

        }

        system.debug(listProdCode);

        List<OrderScreenController.ProductData> listProd = OrderScreenController.getProduct(pricebook, clienteId, offSetValue, searchGenericValue, searchFabricanteValue, condPag, true, listProdCode).productDataList;

        List<OrderScreenController.ProductData> listProdCampaign = new List<OrderScreenController.ProductData>();

        system.debug('listProd: ' + listProd);

        for (OrderScreenController.ProductData prod : listProd) {
            system.debug('prod: ' + prod);
            if (prod != null) {
                system.debug('prod.showBadgeCampanha: ' + prod.showBadgeCampanha);
                system.debug('prod.showBadgeCampanhaVendedor: ' + prod.showBadgeCampanhaVendedor);
                system.debug('prod.showBadgeshelflife: ' + prod.showBadgeshelflife);
                prod.showBadgeCampanha         = prod.showBadgeCampanha == null ? false : prod.showBadgeCampanha;
                prod.showBadgeCampanhaVendedor = prod.showBadgeCampanhaVendedor == null ? false : prod.showBadgeCampanhaVendedor;
                prod.showBadgeshelflife        = prod.showBadgeshelflife == null ? false : prod.showBadgeshelflife;
                if (prod.showBadgeCampanha || prod.showBadgeCampanhaVendedor || prod.showBadgeshelflife) {
                    listProdCampaign.add(prod);
                }
            }
        }
        
        for (OrderScreenController.ProductData prod: listProdCampaign) {
            system.debug(prod.nome);
            system.debug(prod.principioAtivo);
        }
        system.debug('listProdCampaign: ' + listProdCampaign);
        return listProdCampaign;
    }

    public static void fillProdCampaignInfo(Set<String> setCodCampanha, Set<Id> setGroupId, Set<Id> setAccountId, Map<Id, String> mapCodCampaignToIdCampaign, String condPag) {
        for (Campaign camp: [SELECT GrupoCliente__c, Cliente__c FROM Campaign WHERE RecordType.DeveloperName = 'Campanha' AND GrupoCliente__c != null]) {
            setCodCampanha.add(camp.GrupoCliente__c);
            if (camp.Cliente__c != null) {
                setAccountId.add(camp.Cliente__c);
            }
        }
        for (CondicaoPagamento__c condPagamento : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id =: condPag]) {
            if (condPagamento.ExternalId__c != null) {
                mapCodCampaignToIdCampaign.put(condPagamento.Id, condPagamento.ExternalId__c);
            }
        }
        if (!setCodCampanha.isEmpty()) {
            for (GrupoCliente__c gpCli : [SELECT Id, Name, CodigoGrupo__c FROM GrupoCliente__c WHERE CodigoGrupo__c IN: setCodCampanha]) {
                system.debug(gpCli.Name);
                setGroupId.add(gpCli.Id);
            }
            for (Account acc : [SELECT Id FROM Account WHERE GrupoCliente__c IN: setGroupId]) {
                system.debug(acc.Id);
                setAccountId.add(acc.Id);
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MixClientController.OrderData> getClientOrderData(String accId, String prodId) {

        List<MixClientController.OrderData> ordDataList = new List<MixClientController.OrderData>();
        for (OrderItem ordItem : [SELECT Id, Quantity, ValorCx__c, OrderId, ScoreItem__c, Order.Score__c, Order.OrderNumber, CentroDistribuicao__c , FORMAT(Order.CreatedDate), Order.EffectiveDate FROM OrderItem WHERE Product2Id =: prodId AND Order.AccountId =:accId /*AND (Order.Status = 'Faturado' OR Order.Status = 'Faturado (Histórico)')*/ Order by Order.EffectiveDate DESC LIMIT 30000]) {
            ordDataList.add(new MixClientController.OrderData(ordItem));
        }
        return ordDataList;
    }

}