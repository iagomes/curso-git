public without sharing class IntegrationLaboratoryOrderItemIN {
    public static List<TemplateDataIntegrationFields.Response> upsertLabOrderItem(Map<String, List<TemplateDataIntegrationFields.ItensINData>> mapItens, Map<String, Id> lookups, Map<String, String> mapCampToRule) {
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.ItensINData> listItensINData = new List<TemplateDataIntegrationFields.ItensINData>();
        List<OrderItem> listOrderItem = new List<OrderItem>();

        Set<String> setOrderExternalId = new Set<String>();
        Set<String> setOrderItemExternalId = new Set<String>();
        Set<String> descProdExternalId = new Set<String>();
        Set<String> setProduct2Id = new Set<String>();
        Set<String> setPricebook2Id = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();

        String pricebook             = '';
        String clienteId             = '';
        String offSetValue           = '';
        String searchGenericValue    = '';
        String searchFabricanteValue = '';
        String condPag               = '';

        for (String key : mapItens.keySet()) {
            setOrderExternalId.add(key.trim());
            for (TemplateDataIntegrationFields.ItensINData item : mapItens.get(key)) {
                system.debug(item.Produto);
                descProdExternalId.add(getProdCode(item.Produto));
                descProdExternalId.add(item.Produto);
                setPricebookKey.add(item.Tabela);
                setOrderItemExternalId.add(item.PedidoPai + '_' + item.Produto);
                condPag = lookups.get('CondicaoPagamento' + item.CondPag);
            }
        }

        system.debug(condPag);

        // lookup para Pedido
        for(Order ord : [SELECT Id, CodigoIntegradora__c, Pricebook2Id, ExternalId__c, AccountId, Account.CondicaoPagamento__c FROM Order WHERE CodigoIntegradora__c IN: setOrderExternalId]){
            system.debug('CatalogoPedido'+ord.CodigoIntegradora__c.trim());
            system.debug('CatalogoPedido'+ord.ExternalId__c.trim());
            lookups.put('PedidoPai' + ord.CodigoIntegradora__c, ord.Id);
            lookups.put('PedidoPai' + ord.ExternalId__c, ord.Id);
            lookups.put('CatalogoPedido'+ord.CodigoIntegradora__c.trim(), ord.Pricebook2Id);
            lookups.put('CatalogoPedido'+ord.ExternalId__c.trim(), ord.Pricebook2Id);
            clienteId = ord.AccountId;
            if (condPag == null || condPag == '') {
                condPag = ord.Account.CondicaoPagamento__c;
            }
        }

        system.debug(condPag);

        // Lookup para Tabela de Preço
        for(Pricebook2 pb : [SELECT Id, ExternalId__c, IsStandard FROM Pricebook2 WHERE ExternalId__c IN:setPricebookKey OR IsStandard = true]){
            setPricebook2Id.add(pb.Id);
            pricebook = pb.Id;
        }
        system.debug(setPricebook2Id);

        Map<String, String> mapProdToProdCode = new Map<String, String>();

        List<String> listProdCode = new List<String>();

        // lookup para Produto
        for(Product2 prod : [SELECT Id, Name, EANProduto__c, ProductCode FROM Product2 WHERE ProductCode IN: descProdExternalId OR EANProduto__c IN: descProdExternalId]){
            system.debug(prod.ProductCode);
            system.debug(prod.EANProduto__c);
            setProduct2Id.add(prod.Id);
            mapProdToProdCode.put(prod.ProductCode, prod.ProductCode);
            mapProdToProdCode.put(prod.EANProduto__c, prod.ProductCode);
            listProdCode.add(prod.Id);
            lookups.put('Produto' + prod.ProductCode, prod.Id);
            lookups.put('Produto' + prod.EANProduto__c, prod.Id);
        }
        system.debug('lookups: ' + lookups);

        // lookup para Item do Pedido
        for(OrderItem ord : [SELECT Id, ExternalId__c, PricebookEntryId FROM OrderItem WHERE ExternalId__c IN: setOrderItemExternalId]){
            lookups.put('ItemPedido' + ord.ExternalId__c.trim(), ord.Id);
            lookups.put('ItemPedidoPrice' + ord.ExternalId__c.trim(), ord.PricebookEntryId);
        }

        Map<String, Decimal> mapPbEntryKeyToUnitPrice = new Map<String, Decimal>();

        checkPriceBook(mapItens, lookups, mapProdToProdCode);

        // lookup para Entrada da Tabela de Preço
        for(PricebookEntry pbEntry : [SELECT Id, ExternalId__c, Product2.ProductCode, UnitPrice, Pricebook2.isStandard, Product2.Name, Pricebook2Id, Pricebook2.ExternalId__c, Product2.EANProduto__c, Product2Id
                                    FROM PricebookEntry 
                                    WHERE (Pricebook2Id IN:setPricebook2Id)
                                    AND Product2ID IN :setProduct2Id]){
            system.debug('pbEntry: ' + pbEntry);
            system.debug('pbEntry.Product2.ProductCode: ' + pbEntry.Product2.ProductCode);
            system.debug('pbEntry.Pricebook2.ExternalId__c: ' + pbEntry.Pricebook2.ExternalId__c);
            if (pbEntry.Pricebook2.isStandard) {
                lookups.put('StandardPBEntry', pbEntry.Id);    
            }
            lookups.put('TabelaPreco' + pbEntry.Product2.ProductCode.trim()+pbEntry.Pricebook2Id, pbEntry.Id);
            lookups.put('TabelaPreco' + pbEntry.Product2.EANProduto__c.trim()+pbEntry.Pricebook2Id, pbEntry.Id);
            system.debug(pbEntry.Product2.ProductCode.trim()+pbEntry.Pricebook2Id);
            system.debug(pbEntry.Product2.EANProduto__c.trim()+pbEntry.Pricebook2Id);
            mapPbEntryKeyToUnitPrice.put(pbEntry.Product2.ProductCode.trim()+pbEntry.Pricebook2Id, pbEntry.UnitPrice);
            mapPbEntryKeyToUnitPrice.put(pbEntry.Product2.EANProduto__c.trim()+pbEntry.Pricebook2Id, pbEntry.UnitPrice);
        }

        for (String key : mapItens.keySet()) {
            for (TemplateDataIntegrationFields.ItensINData ordItem : mapItens.get(key)) {
                ordItem.EntradaTabelaPreco = ordItem.Produto.trim();
                String key1 = getProdCode(ordItem.Produto)+''+lookups.get('CatalogoPedido'+key);
                String key2 = ordItem.Produto+''+lookups.get('CatalogoPedido'+key);
                ordItem.PrecoTabela = mapPbEntryKeyToUnitPrice.containsKey(key1) ? mapPbEntryKeyToUnitPrice.get(key1): mapPbEntryKeyToUnitPrice.get(key2);
                listItensINData.add(ordItem);
                system.debug(ordItem.EntradaTabelaPreco);
                system.debug(key1);
                system.debug(key2);
                system.debug(ordItem.PrecoTabela);
            }
        }

        system.debug('clienteId: ' + clienteId);
        system.debug('condPag: ' + condPag);
        system.debug('pricebook: ' + pricebook);
        system.debug('listProdCode: ' + listProdCode);
        system.debug('offSetValue: ' + offSetValue);
        system.debug('searchGenericValue: ' + searchGenericValue);
        system.debug('searchFabricanteValue: ' + searchFabricanteValue);

        if (clienteId == '') {
            throw new CustomException('Cliente inexistente no SF');
        }

        List<OrderScreenController.ProductData> listProd = OrderScreenController.getProduct(pricebook, clienteId, offSetValue, searchGenericValue, searchFabricanteValue, condPag, true, listProdCode).productDataList;

        system.debug(listProd);

        Map<Id, String> mapProdIdToCampaingDesc = new Map<Id, String>();
        for (OrderScreenController.ProductData prodData : listProd) {
            system.debug(prodData.id);
            system.debug(prodData.campDesc);
            mapProdIdToCampaingDesc.put(prodData.id, prodData.campDesc);
            mapCampToRule.put('ProdCampaignRule_'+prodData.id, prodData.campDesc);
        }

        system.debug(mapProdIdToCampaingDesc);

        system.debug(listItensINData);
        FactoryDataIntegration.convertSObject(new OrderItem(), 'IN', listItensINData, responseList, listOrderItem, lookups);
        system.debug('listOrderItem: ' + listOrderItem);
        for (OrderItem ordItem : listOrderItem) {
            system.debug(ordItem.Product2Id);
            system.debug(mapProdIdToCampaingDesc.get(ordItem.Product2Id));
            ordItem.ProdutoCampanhaDesc__c = mapProdIdToCampaingDesc.get(ordItem.Product2Id);
            system.debug(ordItem.ProdutoCampanhaDesc__c);
            if (ordItem.ProdutoCampanhaDesc__c != null && ordItem.ProdutoCampanhaDesc__c != '') {
                ordItem.ProdutoCampanha__c = true;
                system.debug(ordItem.ProdutoCampanha__c);
            }
            system.debug(ordItem.Product2Id);
            system.debug(ordItem.ExternalId__c);
        }
        OrderHandler.disableTrigger();
        Boolean upsertSuccess = IntegrationUtils.upsertRecords(
            Database.upsert(listOrderItem, OrderItem.ExternalId__c, false), 
            responseList, 
            listOrderItem, 
            OrderItem.ExternalId__c
        );
        system.debug('upsertSuccess => ' + upsertSuccess);
        OrderHandler.enableTrigger();
        system.debug(responseList);

        return responseList;
    }

    public static String getProdCode(String val){
        system.debug('val: ' + val);
        return val.trim();
    }
    public static void checkPriceBook(Map<String, List<TemplateDataIntegrationFields.ItensINData>> mapItens, Map<String, Id> lookups, Map<String, String> mapProdToProdCode){
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>();
        for(String ordKey : mapItens.keySet()){
            system.debug(ordKey.trim());
            system.debug(lookups.get('CatalogoPedido'+ordKey.trim()));
            String priceId = lookups.get('CatalogoPedido'+ordKey.trim());
            for(TemplateDataIntegrationFields.ItensINData ordItemIn : mapItens.get(ordKey)){
                if (mapProdToProdCode.containsKey(ordItemIn.Produto)) {
                    String key1 = 'Produto'+getProdCode(mapProdToProdCode.get(ordItemIn.Produto));
                    String key2 = 'Produto'+ordItemIn.Produto;
                    system.debug('key1: ' + key1);
                    system.debug('key2: ' + key2);
                    Id prodId = lookups.containsKey(key1) ? lookups.get(key1) : (lookups.containsKey(key2) ? lookups.get(key2) : null); 
                    system.debug(prodId);
                    if(prodId != null && priceID != null){
                        pricebookEntryMap.put(
                            priceId+'_'+prodId,
                            new PriceBookEntry(
                                pricebook2Id = priceId, 
                                product2Id = prodId,
                                unitPrice = 0,
                                isActive = true
                            )
                        );
                    }
                }
            }
        }
        system.debug('pricebookEntryMap: ' +pricebookEntryMap);
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
            system.debug(pricebookEntryMap.values());
            insert pricebookEntryMap.values();
        }
    }
}
