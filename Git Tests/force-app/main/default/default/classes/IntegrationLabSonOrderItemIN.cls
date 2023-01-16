public without sharing class IntegrationLabSonOrderItemIN {
    public static List<TemplateDataIntegrationFields.Response> upsertLabSonOrderItem(Map<String, List<TemplateDataIntegrationFields.LabSonOrderItemINData>> mapLabSonOrderItem, Map<String, Id> lookups, Map<String, String> mapCampToRule) {
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.LabSonOrderItemINData> listLabSonOrderItemINData = new List<TemplateDataIntegrationFields.LabSonOrderItemINData>();
        List<OrderItem> listOrderItem = new List<OrderItem>();

        Set<String> setOrderExternalId = new Set<String>();
        Set<String> setOrderItemExternalId = new Set<String>();
        Set<String> descProdExternalId = new Set<String>();
        Set<String> setProduct2Id = new Set<String>();
        Set<String> setPricebook2Id = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();

        for (String key : mapLabSonOrderItem.keySet()) {
            system.debug(key);
            for (TemplateDataIntegrationFields.LabSonOrderItemINData item : mapLabSonOrderItem.get(key)) {
                item.Chave = key;
                system.debug(item.PedidoFilho);
                setOrderExternalId.add(item.PedidoFilho);
                system.debug(item.Produto);
                system.debug(item.Tabela);
                descProdExternalId.add(item.Produto);
                setPricebookKey.add(item.Tabela);
                setOrderItemExternalId.add(item.PedidoFilho + '_' + item.Produto);
            }
        }

        // lookup para Pedido
        for(Order ord : [SELECT Id, ExternalId__c, CodigoIntegradora__c, Pricebook2Id FROM Order WHERE ExternalId__c IN: setOrderExternalId]){
            system.debug('ord.ExternalId__c: ' + ord.ExternalId__c);
            system.debug('ord.CodigoIntegradora__c: ' + ord.CodigoIntegradora__c);
            lookups.put('PedidoFilho' + ord.ExternalId__c, ord.Id);
            // lookups.put('CatalogoPedido'+ord.ExternalId__c.trim(), ord.Pricebook2Id);
        }

        for (String key : mapLabSonOrderItem.keySet()) {
            for (TemplateDataIntegrationFields.LabSonOrderItemINData ordItem : mapLabSonOrderItem.get(key)) {
                listLabSonOrderItemINData.add(ordItem);
            }
        }

        system.debug(listLabSonOrderItemINData);
        FactoryDataIntegration.convertSObject(new OrderItem(), 'IN', listLabSonOrderItemINData, responseList, listOrderItem, lookups);

        if (!listOrderItem.isEmpty()) {
            for (OrderItem ordItem: listOrderItem) {
                system.debug(ordItem.Product2Id);
                ordItem.ProdutoCampanhaDesc__c = mapCampToRule.get('ProdCampaignRule_' + ordItem.Product2Id);
                if (ordItem.ProdutoCampanhaDesc__c != null && ordItem.ProdutoCampanhaDesc__c != '') {
                    ordItem.ProdutoCampanha__c = true;
                }
            }
        }
        OrderHandler.disableTrigger();
        IntegrationUtils.upsertRecords(
            Database.upsert(listOrderItem, OrderItem.ExternalId__c, false), 
            responseList, 
            listOrderItem, 
            OrderItem.ExternalId__c
        );
        OrderHandler.enableTrigger();
            
        system.debug(responseList);

        return responseList;
    }
}
