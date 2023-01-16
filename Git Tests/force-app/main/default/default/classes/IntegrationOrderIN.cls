@RestResource(urlMapping='/upsertOrder/*')
global without sharing class IntegrationOrderIN {
    @HttpPost
    global static ResponseModel upsertOrder(TemplateDataIntegrationFields.ContadorINData request) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Order> listOrderToUpsert = new List<Order>();
        Map<String, List<TemplateDataIntegrationFields.OrderItemINData>> mapKeyOrdToOrdItem = new Map<String, List<TemplateDataIntegrationFields.OrderItemINData>>();
        Map<String, List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>> mapKeyOrdToSeller = new Map<String, List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>>();

        Set<String> setPaymentConditionKey = new Set<String>();
        Set<String> setAccountKey = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();
        Set<String> setSellerKey = new Set<String>();

        for (TemplateDataIntegrationFields.OrderINData ord : request.Pedidos) {
            setPaymentConditionKey.add(ord.CondicaoPagamento?.trim());
            setAccountKey.add(ord.Conta?.trim());
            setPricebookKey.add(ord.CatalogoPreco?.trim());
            // setSellerKey.add(ord.Vendedor);
            if(ord.ItensPedido != null){
                for (TemplateDataIntegrationFields.OrderItemINData ordItem : ord.ItensPedido) {
                    if (!mapKeyOrdToOrdItem.containsKey(ord.CodigoPedido)) {
                        mapKeyOrdToOrdItem.put(ord.CodigoPedido, new List<TemplateDataIntegrationFields.OrderItemINData>{ordItem});
                    } else {
                        mapKeyOrdToOrdItem.get(ord.CodigoPedido).add(ordItem);
                    }
                }
            }
            if (ord.Vendedor != null) {
                for (TemplateDataIntegrationFields.UsuariosCompartilhadosINData vend : ord.Vendedor) {
                    if (!mapKeyOrdToSeller.containsKey(ord.CodigoPedido)) {
                        mapKeyOrdToSeller.put(ord.CodigoPedido, new List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>{vend});
                    } else {
                        mapKeyOrdToSeller.get(ord.CodigoPedido).add(vend);
                    }
                }
            }
        }

        // Lookup para Conta (Cliente)
        for(Account acc : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c IN:setAccountKey]){
            lookups.put('Conta' + acc.ExternalId__c, acc.Id);
        }

        // Lookup para Condição de Pagamento
        for(CondicaoPagamento__c condPag : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE ExternalId__c IN:setPaymentConditionKey]){
            lookups.put('CondicaoPagamento' + condPag.ExternalId__c, condPag.Id);
        }
        
        // Lookup para Tabela de Preço
        for(Pricebook2 pb : [SELECT Id, ExternalId__c, IsStandard FROM Pricebook2 WHERE ExternalId__c IN:setPricebookKey OR IsStandard = true]){
            if(pb.isStandard){
                lookups.put('CatalogoPrecoPadrao', pb.Id);
                lookups.put('CatalogoPreco' + pb.ExternalId__c, pb.Id);
            }else{
                lookups.put('CatalogoPreco' + pb.ExternalId__c, pb.Id);
            }
            system.debug(lookups);
        }
        FactoryDataIntegration.convertSObject(new Order(), 'IN', request.Pedidos, responseList, listOrderToUpsert, lookups);
        
        system.debug(listOrderToUpsert);
		Boolean hasError = IntegrationUtils.upsertRecords(
            Database.upsert(listOrderToUpsert, Order.ExternalId__c, false), 
            responseList, 
            listOrderToUpsert, 
            Order.ExternalId__c
        );
        
        system.debug(mapKeyOrdToOrdItem);
        if (!mapKeyOrdToOrdItem.keySet().isEmpty()) {
            system.debug('mapKeyOrdToOrdItem: ' + mapKeyOrdToOrdItem);
            responseList.addAll(IntegrationOrderItemIN.upsertOrderItem(mapKeyOrdToOrdItem));
        }
        system.debug(mapKeyOrdToSeller);
        if (!mapKeyOrdToSeller.keySet().isEmpty()) {
            system.debug('mapKeyOrdToSeller: ' + mapKeyOrdToSeller);
            responseList.addAll(IntegrationSellerIN.upsertSeller(mapKeyOrdToSeller));
        }

        for(TemplateDataIntegrationFields.Response res : responseList){
            if(res.status == false) hasError = true;
        }
		
        IntegrationUtils.WSLog('Order', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
}
