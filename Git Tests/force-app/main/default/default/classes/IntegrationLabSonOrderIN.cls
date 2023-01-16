public without sharing class IntegrationLabSonOrderIN {
    public static List<TemplateDataIntegrationFields.Response> upsertLabSonOrder(Map<String, List<TemplateDataIntegrationFields.LabSonOrderINData>> mapLabSonOrder, Map<String, Id> lookups) {
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.LabSonOrderINData> listLabSonOrderINData = new List<TemplateDataIntegrationFields.LabSonOrderINData>();
        List<Order> listOrder = new List<Order>();
        Map<Id, Order> mapIdToOrder = new Map<Id, Order>();

        Set<String> setAccountKey = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();
        Set<String> setOrderExternalId = new Set<String>();
        Set<String> setOrderItemExternalId = new Set<String>();
        Set<String> setUserExternalId = new Set<String>();
        Set<String> descProdExternalId = new Set<String>();
        Map<String, String> mapCnpjToName = new Map<String, String>();

        for (String key : mapLabSonOrder.keySet()) {
            for (TemplateDataIntegrationFields.LabSonOrderINData sonOrder : mapLabSonOrder.get(key)) {
                setAccountKey.add(sonOrder.Cnpj_CD);
                setPricebookKey.add(sonOrder.Tabela);
                setOrderExternalId.add(sonOrder.PedidoPai);
            }
        }        
        
        // Lookup para Conta (Cliente) - Buscar nome do Centro de Distribuição
        for(Account acc : [SELECT Id, Name, NomeFantasia__c, ExternalId__c, CNPJ__c FROM Account WHERE ExternalId__c IN:setAccountKey]){
            lookups.put('CentroDistribuicao' + acc.ExternalId__c, acc.Id);
            mapCnpjToName.put(acc.ExternalId__c, acc.NomeFantasia__c);
            mapCnpjToName.put(acc.CNPJ__c, acc.NomeFantasia__c);
        }

        system.debug(mapCnpjToName);

        for (String key : mapLabSonOrder.keySet()) {
            for (TemplateDataIntegrationFields.LabSonOrderINData sonOrder : mapLabSonOrder.get(key)) {
                system.debug(sonOrder.Cnpj_CD);
                system.debug(mapCnpjToName.get(sonOrder.Cnpj_CD));
                sonOrder.NomeCD = mapCnpjToName.get(sonOrder.Cnpj_CD);
            }
        }     

        // // Lookup para Pedido pai (Order)
        for(Order ord : [SELECT Id, CodigoIntegradora__c FROM Order WHERE CodigoIntegradora__c IN:setOrderExternalId]){
            lookups.put('PedidoPai' + ord.CodigoIntegradora__c, ord.Id);
            system.debug('lookups - codigoINtegradora__C: ' + ord.CodigoIntegradora__c);
        }

        // // Lookup para Tabela de Preço
        // for(Pricebook2 pb : [SELECT Id, ExternalId__c, IsStandard FROM Pricebook2 WHERE ExternalId__c IN:setPricebookKey OR IsStandard = true]){
        //     if(pb.isStandard){
        //         lookups.put('CatalogoPrecoPadrao', pb.Id);
        //         lookups.put('CatalogoPreco' + pb.ExternalId__c, pb.Id);
        //     }else{
        //         lookups.put('CatalogoPreco' + pb.ExternalId__c, pb.Id);
        //     }
        //     system.debug(lookups);
        // }

        Map<String, Decimal> mapPbEntryKeyToUnitPrice = new Map<String, Decimal>();

        for (String key : mapLabSonOrder.keySet()) {
            for (TemplateDataIntegrationFields.LabSonOrderINData ordItem : mapLabSonOrder.get(key)) {
                listLabSonOrderINData.add(ordItem);
            }
        }

        system.debug(listLabSonOrderINData);
        FactoryDataIntegration.convertSObject(new Order(), 'IN', listLabSonOrderINData, responseList, listOrder, lookups);

        for (Order ord : listOrder) {
            if (mapIdToOrder.containsKey(ord.PedidoPai__c)) {
                ord.TipoIntegradora__c   = mapIdToOrder.get(ord.PedidoPai__c).TipoIntegradora__c;
                ord.Laboratorio__c       = mapIdToOrder.get(ord.PedidoPai__c).Laboratorio__c;
                ord.Pricebook2Id         = mapIdToOrder.get(ord.PedidoPai__c).Pricebook2Id;
                ord.Type                 = mapIdToOrder.get(ord.PedidoPai__c).Type;
            }
        }
        
        IntegrationUtils.upsertRecords(
            Database.upsert(listOrder, Order.CodigoIntegradora__c, false), 
            responseList, 
            listOrder, 
            Order.CodigoIntegradora__c
        );

        system.debug(responseList);

        return responseList;
    }
}
