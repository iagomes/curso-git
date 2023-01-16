public without sharing class IntegrationSellerIN {
    public static List<TemplateDataIntegrationFields.Response> upsertSeller(Map<String, List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>> mapOrdKeyToSeller) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData> listUsuariosCompartilhadosINData = new List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>();
        List<UsuariosCompartilhados__c> listSharedUsers = new List<UsuariosCompartilhados__c>();

        Set<String> setSellerKey = new Set<String>();

        for (String key : mapOrdKeyToSeller.keySet()) {
            for (TemplateDataIntegrationFields.UsuariosCompartilhadosINData seller : mapOrdKeyToSeller.get(key)) {
                setSellerKey.add(seller.Vendedor);
                listUsuariosCompartilhadosINData.add(seller);
            }
        }

        // lookup para Pedido
        for(Order ord : [SELECT Id, ExternalId__c FROM Order WHERE ExternalId__c IN: mapOrdKeyToSeller.keySet()]){
            lookups.put('Pedido' + ord.ExternalId__c, ord.Id);
        }        
        
        // Lookup para Vendedor
        for(User us : [SELECT Id, CodigoUsuario__c FROM User WHERE CodigoUsuario__c IN:setSellerKey AND IsActive = true]){
            lookups.put('Vendedor' + us.CodigoUsuario__c, us.Id);
        }

        List<UsuariosCompartilhados__c> listSharedUsersToDelete = deleteUsuariosCompartilhados(mapOrdKeyToSeller);
        system.debug(lookups);

        FactoryDataIntegration.convertSObject(new UsuariosCompartilhados__c(), 'IN', listUsuariosCompartilhadosINData, responseList, listSharedUsers, lookups);
        
        system.debug(listUsuariosCompartilhadosINData);

        IntegrationUtils.upsertRecords(
            Database.upsert(listSharedUsers, UsuariosCompartilhados__c.ExternalId__c, false), 
            responseList, 
            listSharedUsers, 
            UsuariosCompartilhados__c.ExternalId__c
        );

        system.debug(listSharedUsersToDelete);
        if (!listSharedUsersToDelete.isEmpty()) {
            delete listSharedUsersToDelete;
        }

        Map<Id, Set<Id>> mapOrderToUser = new Map<Id, Set<Id>>();

        for (String ordKey : mapOrdKeyToSeller.keySet()) {
            for (TemplateDataIntegrationFields.UsuariosCompartilhadosINData sellerKey : mapOrdKeyToSeller.get(ordKey)) {
                if (!mapOrderToUser.containsKey(lookups.get('Pedido' + ordKey))) {
                    mapOrderToUser.put(lookups.get('Pedido' + ordKey), new Set<Id>{lookups.get('Vendedor' + sellerKey.Vendedor)});
                } else {
                    mapOrderToUser.get(lookups.get('Pedido' + ordKey)).add(lookups.get('Vendedor' + sellerKey.Vendedor));
                }
            }
        }

        system.debug(mapOrderToUser);

        // createShareHist(mapOrderToUser);

        system.debug(responseList);

        return responseList;
    }

    public static List<UsuariosCompartilhados__c> deleteUsuariosCompartilhados(Map<String, List<TemplateDataIntegrationFields.UsuariosCompartilhadosINData>> mapOrdKeyToSeller) {
        List<UsuariosCompartilhados__c> listSharedUsersToDelete = new List<UsuariosCompartilhados__c>();

        Set<String> setSellersCode = new Set<String>(); 

        for (String ordKey : mapOrdKeyToSeller.keySet()) {
            for (TemplateDataIntegrationFields.UsuariosCompartilhadosINData seller : mapOrdKeyToSeller.get(ordKey)) {
                setSellersCode.add(seller.Vendedor);
            }
        }

        system.debug(setSellersCode);

        for (UsuariosCompartilhados__c sharedUsers : [SELECT Id, Pedido__c, Pedido__r.ExternalId__c, Usuario__c, Usuario__r.CodigoUsuario__c FROM UsuariosCompartilhados__c WHERE Pedido__r.ExternalId__c IN: mapOrdKeyToSeller.keySet()]) {           
            system.debug(sharedUsers.Usuario__c);
            system.debug(sharedUsers.Usuario__r.CodigoUsuario__c);
            if (!setSellersCode.contains(sharedUsers.Usuario__r.CodigoUsuario__c)) {
                listSharedUsersToDelete.add(sharedUsers);
            }
        }

        return listSharedUsersToDelete;
    }
    
    // public static void createShareHist(Map<Id, Set<Id>> mapOrderToUser){        
    //     system.debug(mapOrderToUser);

    //     List<Id> ordIdSet = Collection.of([SELECT id FROM Order WHERE id IN :mapOrderToUser.keySet() AND CompartilhamentoRealizado__c = false AND RecordType.DeveloperName = 'PedidoHistorico']).pluckIds();
        
    //     system.debug(ordIdSet);

    //     if(ordIdSet.isEmpty()) return;

    //     createShare(ordIdSet, mapOrderToUser);
    // }

    //ordIdSet = mapOrderToUser.keySet()
    // public static void createShare(List<Id> ordIdSet, Map<Id, Set<Id>> mapOrderToUser){
    //     List<OrderShare> ordShareList = new List<OrderShare>();
    //     List<Order> ordList = new List<Order>();
    //     Set<Id> setUsId = new Set<Id>();
        
    //     for(Id ordId : mapOrderToUser.keySet()){
    //         for (String userId : mapOrderToUser.get(ordId)) {
    //             system.debug(userId);
    //             setUsId.add(userId);
    //         }
    //     }

    //     Set<String> setOrderShare = new Set<String>();
    //     for (OrderShare ordShare : [SELECT Id, OrderId, UserOrGroupId FROM OrderShare WHERE OrderId IN: mapOrderToUser.keySet() AND UserOrGroupId IN: setUsId]) {
    //         setOrderShare.add(ordShare.OrderId + '_' + ordShare.UserOrGroupId);
    //     }

    //     system.debug(setOrderShare);

    //     for(Id ordId : mapOrderToUser.keySet()){
    //         if(ordIdSet.contains(ordId)){
    //             for(Id usId : mapOrderToUser.get(ordId)){
    //                 if (!setOrderShare.contains(ordId + '_' + usId) && usId != null) {
    //                     ordShareList.add(getNewShare(ordId, usId));
    //                 }
    //             }
    //             ordList.add(new Order(Id = ordId, CompartilhamentoRealizado__c = true));
    //         }
    //     }

    //     system.debug(ordShareList);
    //     if(!ordShareList.isEmpty()){
    //         insert ordShareList;
    //     }
    //     system.debug(ordList);
    //     if(!ordList.isEmpty()){
    //         update ordList;
    //     }
    // }

    // public static OrderShare getNewShare(Id OrdId, Id userId){
    //     return new OrderShare(OrderAccessLevel = 'Read', OrderId = ordId, UserOrGroupId = userId);
    // }  
}