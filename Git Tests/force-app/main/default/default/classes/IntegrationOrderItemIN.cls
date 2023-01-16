public without sharing class IntegrationOrderItemIN {
    public static List<TemplateDataIntegrationFields.Response> upsertOrderItem(Map<String, List<TemplateDataIntegrationFields.OrderItemINData>> mapOrdKeyToOrderItem) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.OrderItemINData> listOrderItemINData = new List<TemplateDataIntegrationFields.OrderItemINData>();
        List<OrderItem> listOrderItem = new List<OrderItem>();

        Set<String> setOrderExternalId = new Set<String>();
        Set<String> setOrderItemExternalId = new Set<String>();
        Set<String> setUserExternalId = new Set<String>();
        Set<String> setPbEntryExternalId = new Set<String>();
        Set<String> descProdExternalId = new Set<String>();

        for (String key : mapOrdKeyToOrderItem.keySet()) {
            setOrderExternalId.add(key.trim());
            for (TemplateDataIntegrationFields.OrderItemINData ordItem : mapOrdKeyToOrderItem.get(key)) {
                ordItem.CodigoItemPedido = ordItem.CodigoItemPedido + ordItem.CodigoPedido;
                ordItem.EntradaTabelaPreco = ordItem.EntradaTabelaPreco.trim();
                setOrderItemExternalId.add(ordItem.CodigoItemPedido.trim());
                if(ordItem.Vendedor != null) setUserExternalId.add(ordItem.Vendedor.trim());
                setPbEntryExternalId.add(ordItem.EntradaTabelaPreco.trim());
                descProdExternalId.add(getProdCode(ordItem.EntradaTabelaPreco));
                descProdExternalId.add(ordItem.EntradaTabelaPreco);
            }
        }

        // lookup para Pedido
        for(Order ord : [SELECT Id, ExternalId__c, Pricebook2Id FROM Order WHERE ExternalId__c IN: setOrderExternalId]){
            lookups.put('Pedido' + ord.ExternalId__c.trim(), ord.Id);
            lookups.put('CatalogoPedido'+ord.ExternalId__c.trim(), ord.Pricebook2Id);
        }

        // lookup para Item do Pedido
        for(Product2 prod : [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN: descProdExternalId]){
            lookups.put('Produto' + prod.ProductCode, prod.Id);
        }

        // lookup para Item do Pedido
        for(OrderItem ord : [SELECT Id, ExternalId__c, PricebookEntryId FROM OrderItem WHERE ExternalId__c IN: setOrderItemExternalId]){
            lookups.put('ItemPedido' + ord.ExternalId__c.trim(), ord.Id);
            lookups.put('ItemPedidoPrice' + ord.ExternalId__c.trim(), ord.PricebookEntryId);
        }

        // lookup para Vendedor
        for(User us : [SELECT Id, CodigoUsuario__c FROM User WHERE CodigoUsuario__c IN: setUserExternalId AND CodigoUsuario__c != null]){
            lookups.put('Vendedor' + us.CodigoUsuario__c.trim(), us.Id);
        }

        checkPriceBook(mapOrdKeyToOrderItem, lookups);

        Map<String, Decimal> mapPbEntryKeyToUnitPrice = new Map<String, Decimal>();

        // lookup para Entrada da Tabela de Preço
        for(PricebookEntry pbEntry : [SELECT Id, ExternalId__c, Product2.ProductCode, UnitPrice, Pricebook2.isStandard, Product2.Name, Pricebook2Id 
                                    FROM PricebookEntry 
                                    WHERE (Pricebook2Id IN:lookups.values())
                                    AND Product2ID IN :lookups.values()]){            
            lookups.put('TabelaPreco' + pbEntry.Product2.ProductCode.trim()+pbEntry.Pricebook2Id, pbEntry.Id);
            mapPbEntryKeyToUnitPrice.put(pbEntry.Product2.ProductCode.trim()+pbEntry.Pricebook2Id, pbEntry.UnitPrice);
        }

        for (String key : mapOrdKeyToOrderItem.keySet()) {
            for (TemplateDataIntegrationFields.OrderItemINData ordItem : mapOrdKeyToOrderItem.get(key)) {
                system.debug('ordItem.PrecoTabela: ' + ordItem.PrecoTabela);
                String key1 = getProdCode(ordItem.EntradaTabelaPreco)+''+lookups.get('CatalogoPedido'+key);
                String key2 = ordItem.EntradaTabelaPreco+''+lookups.get('CatalogoPedido'+key);
                ordItem.PrecoTabela =  mapPbEntryKeyToUnitPrice.containsKey(key1) ? mapPbEntryKeyToUnitPrice.get(key1): mapPbEntryKeyToUnitPrice.get(key2);
                system.debug('ordItem.PrecoTabela: ' + ordItem.PrecoTabela);
                listOrderItemINData.add(ordItem);
            }
        }

        system.debug(listOrderItemINData);
        FactoryDataIntegration.convertSObject(new OrderItem(), 'IN', listOrderItemINData, responseList, listOrderItem, lookups);
        
        IntegrationUtils.upsertRecords(
            Database.upsert(listOrderItem, OrderItem.ExternalId__c, false), 
            responseList, 
            listOrderItem, 
            OrderItem.ExternalId__c
        );

        system.debug(responseList);

        return responseList;
    }
    public static String getProdCode(String val){
        return val.trim().substring(3, val.length());
    }
    public static void checkPriceBook(Map<String, List<TemplateDataIntegrationFields.OrderItemINData>> mapOrdKeyToOrderItem, Map<String, Id> lookups){
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>();
        for(String ordKey : mapOrdKeyToOrderItem.keySet()){
            String priceId = lookups.get('CatalogoPedido'+ordKey.trim());
            for(TemplateDataIntegrationFields.OrderItemINData ordItemIn : mapOrdKeyToOrderItem.get(ordKey)){
                String key1 = 'Produto'+getProdCode(ordItemIn.EntradaTabelaPreco);
                String key2 = 'Produto'+ordItemIn.EntradaTabelaPreco;
                Id prodId = lookups.containsKey(key1) ? lookups.get(key1) : (lookups.containsKey(key2) ? lookups.get(key2) : null); 
                if(prodId != null && priceID != null){
                    pricebookEntryMap.put(
                        priceId+'_'+prodId,
                        new PriceBookEntry(
                            pricebook2Id = priceId, 
                            product2Id = prodId,
                            unitPrice = 0,
                            isActive = false
                        )
                    );
                }
            }
        }
        for(PricebookEntry pbEntry : [SELECT Id, ExternalId__c, UnitPrice, Pricebook2.isStandard, Product2Id, Product2.Name, Pricebook2Id 
                                        FROM PricebookEntry 
                                        WHERE Pricebook2Id IN: lookups.values()
                                        AND Product2Id IN :lookups.values()]){
            String key = pbEntry.Pricebook2Id+'_'+pbEntry.Product2Id;
            if(pricebookEntryMap.containsKey(key)){
                pricebookEntryMap.remove(key);
            }
        }
        if(!pricebookEntryMap.values().isEmpty()){
            insert pricebookEntryMap.values();
        }
    }
}