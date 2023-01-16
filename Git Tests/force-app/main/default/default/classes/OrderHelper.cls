public without sharing class OrderHelper{
    public OrderHelper() {}

    public static final Id MOTHERORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();

    // public static void checkError(Map<Id, Order> oldMap, Map<Id, Order> newMap){
    //     for(Order ord : newMap.values()){
    //         Order oldOrd = oldMap.get(ord.id);
    //         if(ord.MensagemErroIntegracao__c != null && oldOrd.MensagemErroIntegracao__c == null){
    //             ord.Status = 'ErroIntegracao';
    //         }
    //     }
    // }
    public static void sendOrderToERP(Map<Id, Order> oldMap, Map<Id, Order> newMap){

        Set<Id> parentOrderSet = new Set<Id>();
        Set<Id> ordIdSet = new Set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.id);  
            if (!oldOrder.EnviarAprovacao__c && o.EnviarAprovacao__c) {
                if (o.RecordTypeId == MOTHERORDER_RECORDTYPE) {
                    parentOrderSet.add(o.Id);
                } else if (o.PedidoPai__c == null) {
                    if(o.CodigoIntegradora__c == null ){
                        ordIdSet.add(o.Id);
                    }
                }
            }
        }

        if (!parentOrderSet.isEmpty()) {
            for (Order o : [SELECT Id, StatusIntegracao__c, CodigoIntegradora__c, PedidoPai__r.Status, Laboratorio__c, ExternalId__c FROM Order WHERE PedidoPai__c IN :parentOrderSet]) {
                if (o.CodigoIntegradora__c != null && (o.PedidoPai__r.Status == 'Aprovado' || o.PedidoPai__r.Status == 'Reprovado')) {
                    // if (o.StatusIntegracao__c == 'Aprovado na integradora' && o.PedidoPai__r.Status == 'Reprovado') {
                    //     ordIdSet.add(o.Id);
                    // }
                } else {
                    if((o.CodigoIntegradora__c == null && o.ExternalId__c == null) ){ //||  o.PedidoPai__r.Status == 'Reprovado'){
                        ordIdSet.add(o.Id);
                    }
                }
            }
        }

        if (!ordIdSet.isEmpty()) {     
            if (ordIdSet.size() < 50){
                System.enqueueJob(new IntegrationOrderOUTQueueable(0, new List<Id>(ordIdSet)));      
            } else {
                BatchSendOrder.run(ordIdSet);
            }              
        }
    }    

    public static void updateOrderSon(List<Order> newRecordList, Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Map<Id, Order> mapOrderIdToOrderSon = new Map<Id, Order>();
        Map<Id, String> mapOrderIdToCondicaoPagamento = new Map<Id, String>();
        for (Id ordId : newMap.keySet()) {
            Order newOrd = newMap.get(ordId);
            Order oldOrd = oldMap.get(ordId);
            if (newOrd.RecordTypeId == MOTHERORDER_RECORDTYPE && newOrd.CodigoIntegradora__c != null && 
                newOrd.Status != 'Reprovado' && newOrd.Status != 'Aprovado' && newOrd.Status != 'Cancelado') {
                mapOrderIdToOrderSon.put(newOrd.Id, newOrd);
                
                if (oldOrd.CondicaoPagamento__c != newOrd.CondicaoPagamento__c) {
                    mapOrderIdToCondicaoPagamento.put(newOrd.CondicaoPagamento__c, '');
                }
            }
        }

        system.debug('mapOrderIdToOrderSon: ' + mapOrderIdToOrderSon);

        if (!mapOrderIdToCondicaoPagamento.isEmpty()) {

            for (CondicaoPagamento__c cond : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id IN: mapOrderIdToCondicaoPagamento.keySet()]) {

                mapOrderIdToCondicaoPagamento.put(cond.Id, cond.ExternalId__c);
            }

        }

        if(!mapOrderIdToOrderSon.isEmpty()) {
            Map<Id, Decimal> mapProdIdToPrice = new Map<Id, Decimal>();

            for (OrderItem ordItem : [SELECT Id, Product2Id, UnitPrice, ValorCx__c FROM OrderItem WHERE OrderId IN: mapOrderIdToOrderSon.keySet()]) {
                system.debug(ordItem.UnitPrice);
                mapProdIdToPrice.put(ordItem.Product2Id, ordItem.UnitPrice);
            }
            
            Set<Id> setLabSonOrdId = new Set<Id>();
            List<Order> listOrderSon = new List<Order>();
            if (!mapOrderIdToOrderSon.isEmpty()) {
                for (Order ord : [SELECT Id, FormaPagamento__c, CondicaoPagamento__c,CondicaoPagamento__r.ExternalId__c, PedidoPai__c, ObservacoesPedido__c, MensagemNF__c, NecessarioComprovante__c FROM Order WHERE PedidoPai__c IN: mapOrderIdToOrderSon.keySet()]) {
                    ord.FormaPagamento__c    = mapOrderIdToOrderSon.get(ord.PedidoPai__c).FormaPagamento__c;
                    ord.CondicaoPagamento__c = mapOrderIdToOrderSon.get(ord.PedidoPai__c).CondicaoPagamento__c;
                    ord.ObservacoesPedido__c = mapOrderIdToOrderSon.get(ord.PedidoPai__c).ObservacoesPedido__c;
                    ord.MensagemNF__c        = mapOrderIdToOrderSon.get(ord.PedidoPai__c).MensagemNF__c;
    
                    if (!mapOrderIdToCondicaoPagamento.isEmpty()) {
                        ord.NecessarioComprovante__c = mapOrderIdToCondicaoPagamento.get(ord.CondicaoPagamento__c) == 'RA' ? True : False;
                    }
    
                    listOrderSon.add(ord);
                    setLabSonOrdId.add(ord.Id);
                }
            }
            
            system.debug('mapOrderIdToOrderSon: ' + mapOrderIdToOrderSon);
            system.debug('setLabSonOrdId: ' + setLabSonOrdId);
            system.debug('listOrderSon: ' + listOrderSon);
    
            List<OrderItem> listOrderItem = new List<OrderItem>();
            if (!setLabSonOrdId.isEmpty()) {
                for (OrderItem ordItem: [SELECT Id, ValorCx__c, UnitPrice, Product2Id FROM OrderItem WHERE OrderId IN: setLabSonOrdId]) {
                    if (mapProdIdToPrice.containsKey(ordItem.Product2Id)) {
                        
                        Decimal price = mapProdIdToPrice.get(ordItem.Product2Id);
                        if (price != 0) {
                            ordItem.ValorCx__c = price;
                            ordItem.UnitPrice = price;
                            listOrderItem.add(ordItem);
                        }  
                    }
                                 
                }
            }
    
            system.debug(listOrderItem);
            if (!listOrderItem.isEmpty()) {
                OrderHandler.disableTrigger();
                update listOrderItem;
                OrderHandler.enableTrigger();
            }
    
            if (!listOrderSon.isEmpty()) {
                OrderHandler.disableTrigger();
                update listOrderSon;
                OrderHandler.enableTrigger();
                if (!setLabSonOrdId.isEmpty()) {
                    if (setLabSonOrdId.size() < 50){System.enqueueJob(new IntegrationAutLabOrderOUTQueueable(0, new List<Id>(setLabSonOrdId)));}
                }
            }
        }
    }

    public static void returningApprovalToERP(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Set<Id> setOrderId = new Set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.StatusIntegracao__c != oldOrder.StatusIntegracao__c && o.StatusIntegracao__c == 'Pedido rejeitado na alçada financeira' && o.PedidoPai__c != null && o.PedidoProtheus__c != null) {
                setOrderId.add(o.Id);
            }
        }

        if (!setOrderId.isEmpty()) {
            if (setOrderId.size() < 50) {System.enqueueJob(new IntegrationCancelOrderQueueable(0, new List<Id>(setOrderId)));}
        }
    }

    public static void sendApprovalOrderIntegradoraToERP(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Set<Id> parentOrderSet              = new Set<Id>();
        Set<Id> ordIdSet                    = new Set<Id>();
        Set<Id> cancelOrderSet              = new Set<Id>();
        Map<String, Boolean> ordIdStatusMap = new Map<String, Boolean>();
        Boolean isLaboratoryOrder = false;
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.id);
            system.debug('seiji deu ruim ' );
            system.debug('o.PedidoPai__c ' + o.PedidoPai__c);
            system.debug('o.Status ' + o.Status);
            system.debug('oldOrder.Status ' + oldOrder.Status);
            system.debug('o.PedidoPaiStatus__c ' + o.PedidoPaiStatus__c);

            if (o.PedidoPai__c != null && o.CodigoIntegradora__c != null && (o.PedidoPaiStatus__c == 'Aprovado' || o.PedidoPaiStatus__c == 'Reprovado')) {
                isLaboratoryOrder = true;
                if (o.Status != 'Aguardando processamento na integradora') {
                    ordIdStatusMap.put(o.PedidoPai__c, true);
                } else {ordIdStatusMap.put(o.PedidoPai__c, false);}
            } else if (oldOrder.Status != o.Status && (o.Status == 'Aprovado' || o.Status == 'Reprovado')) {
                if (o.Status != 'Aguardando processamento na integradora') {
                    ordIdStatusMap.put(o.Id, true);
                } else {ordIdStatusMap.put(o.Id, false);}
            }
        }
        for (Order o : [SELECT Id, Status, PedidoPai__c, CodigoIntegradora__c FROM Order WHERE CodigoIntegradora__c != null 
                        AND (PedidoPai__c IN :ordIdStatusMap.keySet() OR Id IN :newMap.keySet())]) {
            isLaboratoryOrder = true;
            if (o.Status == 'Aguardando processamento na integradora' || o.Status == 'Aguardando aprovação') {
                ordIdStatusMap.put(o.PedidoPai__c, false);
            }
        }
        if (isLaboratoryOrder) {
            system.debug('ordIdStatusMap ' + ordIdStatusMap);
            for (Order o : newMap.values()) {
                Order oldOrder = oldMap.get(o.id);
                if (o.RecordTypeId == MOTHERORDER_RECORDTYPE && ordIdStatusMap.containsKey(o.Id) && ordIdStatusMap.get(o.Id)) {
                    system.debug('ENTROU 1');
                    parentOrderSet.add(o.Id);
                } else if (o.CodigoIntegradora__c != null && ordIdStatusMap.containsKey(o.Id) && ordIdStatusMap.get(o.Id) && 
                            o.externalId__c != null && (o.PedidoPaiStatus__c == 'Aprovado' || o.PedidoPaiStatus__c == 'Reprovado')) {
                    system.debug('ENTROU 2');
                    ordIdSet.add(o.Id);
                } else if (o.CodigoIntegradora__c != null && ordIdStatusMap.containsKey(o.Id) && ordIdStatusMap.get(o.Id) && 
                            o.externalId__c != null && (o.Status == 'Aguardando envio de cancelamento' || o.Status == 'Cancelado')) {
                    cancelOrderSet.add(o.Id);
                    system.debug('ENTROU 3');
                }
            }
        }
        system.debug('parentOrderSet ' + parentOrderSet);
        if (!parentOrderSet.isEmpty()) {
            for (Order o : [SELECT Id, externalId__c, AccountId,  CondicaoPagamento__c, StatusIntegracao__c, Status, PedidoPaiStatus__c, Laboratorio__c, CodigoIntegradora__c  FROM Order WHERE PedidoPai__c IN :parentOrderSet                             
                             AND externalId__c != null]) {
                                // AND CodigoIntegradora__c != null AND externalId__c != null]) {

                system.debug('o.Status ' + o.Status);
                system.debug('o.PedidoPaiStatus__c ' + o.PedidoPaiStatus__c);
                system.debug('o.CodigoIntegradora__c ' + o.CodigoIntegradora__c);

                if (o.Status != 'Aguardando envio de cancelamento' && o.Status != 'Cancelado') {
                    if(o.PedidoPaiStatus__c != 'Aguardando aprovação' && ((o.CodigoIntegradora__c != null && o.Laboratorio__c != null ) || (o.CodigoIntegradora__c == null && o.Laboratorio__c == null )) ){
                        ordIdSet.add(o.Id);
                    }
                } else { cancelOrderSet.add(o.Id);}
            }
        }
        system.debug('ordIdSet ' + ordIdSet);
        if (!ordIdSet.isEmpty()) {
            if (ordIdSet.size() < 50){ System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>(ordIdSet)));
            } else { BatchSendApprovalOrder.run(ordIdSet);}
        }
        if (!cancelOrderSet.isEmpty()) {System.enqueueJob(new IntegrationCancelOrderQueueable(0, new List<Id>(cancelOrderSet)));}
    }

    public static void sendApprovalOrderToERP(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        List<Order> ordToUpdateList = new List<Order>();
        String BLANK_EXTERNALID = 'Este pedido ainda não possui o código TOTVS.';
        Set<Id> parentOrderSet = new Set<Id>();
        Set<Id> ordIdSet = new Set<Id>();
        Set<Id> ordIdCancelSet = new Set<Id>();
        Set<Id> ordIdErrorSet = new Set<Id>();
        Set<Id> conditionIds = new Set<Id>();
        Set<Id> sendAttachmentSet = new Set<Id>();
        for (CondicaoPagamento__c condicaoPagamento : [SELECT Id, Name, ExternalId__c FROM CondicaoPagamento__c WHERE Name = 'RA' OR ExternalId__c = 'RA']) {
            conditionIds.add(condicaoPagamento.Id);
        }

        // Map<String, Boolean> ordIdStatusMap = new Map<String, Boolean>();
        // for (Order o : newMap.values()) {
        //     if (o.Status != 'Aguardando processamento na integradora') {
        //         ordIdStatusMap.put(o.PedidoPai__c, true);
        //     } else {
        //         ordIdStatusMap.put(o.PedidoPai__c, false);
        //     }
        // }
        // for (Order o : [SELECT Id, Status, PedidoPai__c FROM Order WHERE PedidoPai__c IN :Collection.of(newMap.values()).pluckIds(Order.PedidoPai__c)]) {
        //     if (o.Status == 'Aguardando processamento na integradora') {
        //         ordIdStatusMap.put(o.PedidoPai__c, false);
        //     }
        // }

        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.id);
            // if ((o.PedidoPai__c != null && ordIdStatusMap.get(o.PedidoPai__c)) || o.PedidoPai__c == null) {
                boolean approvedByComercial = !o.NecessitaAprovacaoPricing__c && !o.NecessitaAprovacaoMalha__c && !o.NecessitaAprovacaoRegionalizacao__c && !o.NecessitaAprovacaoBonificacao__c;
                boolean approvedByPricing = !o.NecessitaAprovacaoComercial__c && !o.NecessitaAprovacaoMalha__c && !o.NecessitaAprovacaoRegionalizacao__c && !o.NecessitaAprovacaoBonificacao__c;
                boolean approvedByMalha = !o.NecessitaAprovacaoPricing__c && !o.NecessitaAprovacaoComercial__c && !o.NecessitaAprovacaoRegionalizacao__c && !o.NecessitaAprovacaoBonificacao__c;
                boolean approvedByRegionalizacao = !o.NecessitaAprovacaoPricing__c && !o.NecessitaAprovacaoMalha__c && !o.NecessitaAprovacaoComercial__c && !o.NecessitaAprovacaoBonificacao__c;
                boolean approvedByBonificacao = !o.NecessitaAprovacaoPricing__c && !o.NecessitaAprovacaoMalha__c && !o.NecessitaAprovacaoComercial__c && !o.NecessitaAprovacaoRegionalizacao__c;
                
                system.debug(approvedByComercial);
                system.debug(approvedByPricing);
                system.debug(approvedByMalha);
                system.debug(approvedByRegionalizacao);
                if ((!oldOrder.AprovadoComercial__c && o.AprovadoComercial__c && approvedByComercial) || 
                    (!oldOrder.AprovadoPricing__c && o.AprovadoPricing__c && approvedByPricing) || 
                    (!oldOrder.AprovadoMalha__c && o.AprovadoMalha__c && approvedByMalha) || 
                    (!oldOrder.AprovadoRegionalizacao__c && o.AprovadoRegionalizacao__c && approvedByRegionalizacao) || 
                    (!oldOrder.AprovadoBonificacao__c && o.AprovadoBonificacao__c && approvedByBonificacao) || 
                    (!oldOrder.AprovadoComercial__c && o.AprovadoComercial__c && !oldOrder.AprovadoPricing__c && o.AprovadoPricing__c && !oldOrder.AprovadoMalha__c && o.AprovadoMalha__c && !oldOrder.AprovadoRegionalizacao__c && o.AprovadoRegionalizacao__c && !oldOrder.AprovadoBonificacao__c && o.AprovadoBonificacao__c) ||
                    (!oldOrder.RejeicaoProcesso__c && o.RejeicaoProcesso__c) || 
                    (!oldOrder.RecallProcesso__c && o.RecallProcesso__c) || 
                    (oldOrder.ExternalId__c == null && o.ExternalId__c != null) || 
                    
                    (((o.AprovadoComercial__c && approvedByComercial) || 
                    (o.AprovadoPricing__c && approvedByPricing) || 
                    (o.AprovadoMalha__c && approvedByMalha) || 
                    (o.AprovadoRegionalizacao__c && approvedByRegionalizacao) || 
                    (o.AprovadoBonificacao__c && approvedByBonificacao) || 
                    (o.AprovadoComercial__c && o.AprovadoPricing__c && o.AprovadoMalha__c && o.AprovadoRegionalizacao__c && o.AprovadoBonificacao__c)) && 
                    (!oldOrder.EnviarAprovacao__c && o.EnviarAprovacao__c) ) ||
                    o.ErroIntegracaoAprovacao__c || o.ErroIntegracaoRejeitado__c ||
                    (o.StatusIntegracao__c != oldOrder.StatusIntegracao__c) ) {
                        System.debug(o.id);
                        System.debug('seiji ok 111');
                        System.debug('o.RecordTypeId ' + o.RecordTypeId);
                        System.debug('MOTHERORDER_RECORDTYPE ' + MOTHERORDER_RECORDTYPE);
                        System.debug('o.PedidoPendente__c ' + o.PedidoPendente__c);

                    if (o.RecordTypeId == MOTHERORDER_RECORDTYPE && !o.PedidoPendente__c) {
                        parentOrderSet.add(o.Id);
                    } else if(o.externalId__c != null && (o.Status == 'Pai - Aprovado' || o.Status == 'Aguardando envio de rejeição' || o.Status == 'Aguardando comprovante')){
                        if (conditionIds.contains(o.CondicaoPagamento__c) && o.AccountId == o.ClientePedidoPai__c) {
                            if (o.ComprovanteAnexado__c && o.Status == 'Aguardando comprovante') {
                                sendAttachmentSet.add(o.Id);
                            }
                        } else {
                            ordIdSet.add(o.Id);
                        }
                    } else if((o.Status == 'Aguardando envio de cancelamento' && oldOrder.ExternalId__c == null && o.ExternalId__c != null) || (oldOrder.ExternalId__c == null && o.ExternalId__c != null && o.Status == 'Cancelado')){
                        ordIdCancelSet.add(o.Id);
                    } else if (o.externalId__c == null && (o.PedidoPai__r.RejeicaoProcesso__c || o.PedidoPai__r.RecallProcesso__c || (oldOrder.Status != 'Pai - Aprovado' && o.Status == 'Pai - Aprovado'))) {
                        ordIdErrorSet.add(o.Id);
                    }
                }
            // }
        }
        Map<Id, Boolean> mapHasVansOrder = getVansOrderMap(newMap.values());
        System.debug(parentOrderSet);
        if (!parentOrderSet.isEmpty()) {
            for (Order o : [SELECT Id, externalId__c, AccountId, ClientePedidoPai__c, PedidoPai__r.RecallProcesso__c, ComprovanteAnexado__c, CondicaoPagamento__c, StatusIntegracao__c, PedidoPai__c FROM Order WHERE PedidoPai__c IN :parentOrderSet 
                            AND Status != 'Cancelado' AND Status != 'Aguardando envio de cancelamento' AND Status != 'Aguardando envio de rejeição']) {
                if (o.PedidoPai__r.RecallProcesso__c) {
                    ordIdCancelSet.add(o.Id);
                } else if (o.externalId__c != null) {
                    if (conditionIds.contains(o.CondicaoPagamento__c) && o.AccountId == o.ClientePedidoPai__c) {
                        if (o.ComprovanteAnexado__c && o.StatusIntegracao__c == 'Pedido aguardando envio/processamento do comprovante de pagamento RA') {
                            sendAttachmentSet.add(o.Id);
                        }
                    } else {
                        system.debug(mapHasVansOrder);
                        if (!mapHasVansOrder.get(o.PedidoPai__c)) {
                            ordIdSet.add(o.Id);
                        }
                    }
                } else {
                    ordIdErrorSet.add(o.Id);
                }
            }
        }

        if (!ordIdErrorSet.isEmpty()) {
            for (Order o : [SELECT Id, ErroIntegracaoAprovacao__c, ErroIntegracaoRejeitado__c, ErroIntegracaoCancelamento__c, PedidoPai__r.RejeicaoProcesso__c, PedidoPai__r.RecallProcesso__c 
                            FROM Order WHERE Id IN :ordIdErrorSet]) {
                // o.MensagemErroIntegracao__c  = BLANK_EXTERNALID;
                if (o.PedidoPai__r.RejeicaoProcesso__c) {
                    o.ErroIntegracaoRejeitado__c = true;
                } else if (o.PedidoPai__r.RecallProcesso__c) {
                    o.ErroIntegracaoCancelamento__c = true;
                } else {
                    o.ErroIntegracaoAprovacao__c = true;
                }
    
                ordToUpdateList.add(o);
            }
        }
        
        if (!ordToUpdateList.isEmpty()) {
            OrderHandler.disableTrigger();
            update ordToUpdateList;
            OrderHandler.enableTrigger();
        }

        if (!sendAttachmentSet.isEmpty()) {
            System.enqueueJob(new PaymentAttachmentQueueable(0, new List<Id>(sendAttachmentSet)));
        }
        if (!ordIdSet.isEmpty()) {     
            if (ordIdSet.size() < 50){
                system.debug('é aqui 2');
                System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>(ordIdSet)));    
            } else {
                BatchSendApprovalOrder.run(ordIdSet);
            }              
        } 
        if (!ordIdCancelSet.isEmpty()) {    
            System.enqueueJob(new IntegrationCancelOrderQueueable(0, new List<Id>(ordIdCancelSet)));
        }
    }

    public static void validaAprovacao(Map<Id, Order> oldMap, Map<Id, Order> newMap, List<Order> newRecordList){
        Set<Order> setOrder = new Set<Order>();
        set<Id> setPedido = new set<Id>();
        set<Id> setLabOrder = new set<Id>();
        Set<Id> setAllOrderId = new Set<Id>();
        Set<Id> orderIdWithLabItem = new Set<Id>();
        Set<Id> setOrderItemLab = new Set<Id>();
        List<Order> labOrderToUpdate = new List<Order>();

        for (Order o : [SELECT Id FROM Order WHERE Id IN: newMap.keySet() OR PedidoPai__c IN: newMap.keySet()]) {
            setAllOrderId.add(o.Id);
        }

        system.debug(setAllOrderId);

        for (OrderItem oi : [SELECT Id, Laboratorio__c, OrderId FROM OrderItem WHERE OrderId IN :setAllOrderId]) {
            if (oi.Laboratorio__c != null) {
                orderIdWithLabItem.add(oi.OrderId);
                setOrderItemLab.add(oi.Id);
            }
        }

        for (Order o : newRecordList) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.EnviarAprovacao__c && !oldOrder.EnviarAprovacao__c && (o.CodigoIntegradora__c == null && !orderIdWithLabItem.contains(o.Id))){
                system.debug('valida id ' + o.Id);
                system.debug('valida id o.EnviarAprovacao__c ' + o.EnviarAprovacao__c);
                setPedido.add(o.Id);
                setOrder.add(o);
            } else if (o.EnviarAprovacao__c && !oldOrder.EnviarAprovacao__c && (orderIdWithLabItem.contains(o.Id))) {
                setLabOrder.add(o.Id);
            }
        }
        if (!setLabOrder.isEmpty()) {
            for (Order o : [SELECT Id, Status, PedidoPai__c, OrderNumber, Laboratorio__c, AccountId FROM Order WHERE Id IN :setLabOrder OR PedidoPai__c IN :setLabOrder]) {                
                system.debug('labOrderToUpdate');
                system.debug('Pedido => ' + o.OrderNumber);
                system.debug('orderIdWithLabItem => ' + orderIdWithLabItem);
                system.debug(o.PedidoPai__c);
                system.debug(o.id);
                system.debug(o.Status);
                if (o.PedidoPai__c == null) {
                    if (o.Status == 'Em digitação') {
                        labOrderToUpdate.add(new Order(Id = o.Id, Status = 'Aguardando processamento na integradora'));
                    } else {
                        setPedido.add(o.id);
                        setOrder.add(o);
                    }
                } else {
                    if (orderIdWithLabItem.contains(o.Id)) {
                        if (!(o.Status == 'Aprovado na integradora' || o.Status == 'Rejeitado na integradora' || o.Status == 'Bloqueado por divergência de preços' || o.Status ==  'Pai - Aprovado')) {
                            labOrderToUpdate.add(new Order(Id = o.Id, Status = 'Aguardando processamento na integradora'));
                        }
                    } else {
                        labOrderToUpdate.add(new Order(Id = o.Id, Status = 'Aprovado na integradora'));
                    }
                }

                // if (!(o.PedidoPai__c == null && o.Status == 'Aguardando aprovação')) {
                //     system.debug('Pedido => ' + o.OrderNumber);
                //     system.debug(setLabOrder.contains(o.PedidoPai__c));
                //     if (setLabOrder.contains(o.PedidoPai__c) && !(o.Status == 'Aprovado na integradora' || o.Status == 'Rejeitado na integradora' || o.Status == 'Bloqueado por divergência de preços')) {
                //         system.debug(orderIdWithLabItem);
                //         system.debug(o.Id);
                //         system.debug(o.PedidoPai__c);
                //         if (orderIdWithLabItem.contains(o.PedidoPai__c)) {
                //             labOrderToUpdate.add(new Order(Id = o.Id, Status = 'Aguardando processamento na integradora'));
                //         } else {
                //             labOrderToUpdate.add(new Order(Id = o.Id, Status = 'Aprovado na integradora'));
                //         }
                //     }
                // } else {
                //     system.debug('Entrou no ELSE');
                // }
            }
        }
        map<String,String> mapGroup = new map<String,String>();
        map<Id,String> mapGroupId = new map<Id,String>();
        set<String> setGrop = new set<String>();
        Set<Id> setUserId = new Set<Id>();
        map<String,list<Id>> mapUserId =  new map<String,list<Id>>();
        if(!setPedido.isEmpty()){
            Map<String, ParametroScore__c> mapParm = ParametroScore__c.getAll();
            Map<String, Set<Id>> mapApprovalProcessToUserIdSet =  new Map<String, Set<Id>>();
            list<OrderItem> loi = new list<OrderItem>();
            Map<String, Set<String>> mapRecTypeToCategories = new Map<String, Set<String>>();
            loi = [SELECT Id, OrderId,  Order.EnviarAprovacao__c , Order.Score__c ,Order.RecordTypeId, Order.TotalAmount, Order.AccountId, Order.ClienteRecebedor__c, ExternalId__c, CNPJCD__c, Laboratorio__c,
                                        CentroDistribuicao__c, ServiceDate, EndDate, Description, ForaMalha__c, CategoriaComercial__c, //NumeroItemPedido__c,
                                        ItemCampanha__c, QuoteLineItemId, ItemContrato__c, OriginalOrderItemId, Lote__c, MargemAlvo__c, Margem__c, BloqueadoRegionalizacao__c, CampanhaShelfLife__c, CampanhaShelfLifeAux__c,
                                        ListPrice, PrecoTotal__c, TotalPrice, UnitPrice, Product2Id, Product2.ProductCode, Product2.CategoriaComercial__c, Quantity, QuantidadeUn__c, Order.Type,
                                        AvailableQuantity,ScoreBU__c, ScoreAlvo__c, ScoreAtual__c, TipoOperacao__c, UnidadeMedida__c, ValidadeMinima__c, ValorCx__c, Order.AprovadoMalha__c, Order.NecessitaAprovacaoMalha__c, Order.AprovadoRegionalizacao__c, Order.NecessitaAprovacaoRegionalizacao__c, Order.AprovadoBonificacao__c, Order.NecessitaAprovacaoBonificacao__c,
                                        ValorUn__c, Vendedor__c, Product2.Fornecedor__c, Vendedor__r.UserRole.ParentRoleId, Order.AprovadoComercial__c, Order.NecessitaAprovacaoPricing__c, Order.AprovadoPricing__c, Order.NecessitaAprovacaoComercial__c
                                FROM OrderItem WHERE OrderId = : setPedido ORDER BY OrderId, Product2.CategoriaComercial__c ];
            set<Id> setIdUser = new set<Id>();

            for(OrderItem oi : loi ){
                String categoria = oi.Product2.CategoriaComercial__c == 'R' ? 'S' : oi.Product2.CategoriaComercial__c;

                if ((oi.Order.AprovadoComercial__c && !oi.Order.NecessitaAprovacaoPricing__c) || 
                    (oi.Order.AprovadoPricing__c && !oi.Order.NecessitaAprovacaoComercial__c) || 
                    (oi.Order.AprovadoMalha__c && !oi.Order.NecessitaAprovacaoMalha__c) || 
                    (oi.Order.AprovadoRegionalizacao__c && !oi.Order.NecessitaAprovacaoRegionalizacao__c) || 
                    (oi.Order.AprovadoBonificacao__c && !oi.Order.NecessitaAprovacaoBonificacao__c) || 
                    (oi.Order.AprovadoComercial__c && oi.Order.AprovadoPricing__c && oi.Order.AprovadoMalha__c && oi.Order.AprovadoRegionalizacao__c && oi.Order.AprovadoBonificacao__c)) {
                        continue;
                }
                if (oi.Order.Score__c == null) {
                    oi.Order.Score__c = 0;
                }
                if (oi.ScoreBU__c == null) {
                    oi.ScoreBU__c = 0;
                }
                if (oi.Order.Score__c < mapParm.get('A').Score__c && !setOrderItemLab.contains(oi.Id)) {
                    system.debug('oi.ScoreBU__c ' + oi.ScoreBU__c);
                    if (oi.ScoreBU__c <= mapParm.get('D').Score__c) {
                        system.debug('D');
                        if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoPricing' /*+ categoria*/)) {
                            mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoPricing' /*+ categoria*/, new Set<String>{categoria});
                        } else {
                            mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoPricing' /*+ categoria*/).add(categoria);
                        }
                    } else {
                        if (oi.ScoreBU__c <= mapParm.get('C').Score__c ) {
                            system.debug('C');
                            if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/)) {
                                mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                            } else {
                                mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/).add(categoria);
                            }
                        } else {
                            if (oi.ScoreBU__c <= mapParm.get('B').Score__c ) {
                                system.debug('B');
                                if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/)) {
                                    mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                                } else {
                                    mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/).add(categoria);
                                }
                            } else {
                                if (oi.Order.Score__c < mapParm.get('A').Score__c) {
                                    system.debug('A');
                                    if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/)) {
                                        mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                                    } else {
                                        mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/).add(categoria);
                                    }
                                } 
                            }
                        }
                    }
                }

                if (oi.BloqueadoRegionalizacao__c) {
                    if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoRegionalizacao' /*+ categoria*/)) {
                        mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoRegionalizacao' /*+ categoria*/, new Set<String>{categoria});
                    } else {
                        mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoRegionalizacao' /*+ categoria*/).add(categoria);
                    }
                }

                if (oi.ForaMalha__c && !setOrderItemLab.contains(oi.Id)) {
                    if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoMalha' /*+ categoria*/)) {
                        mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoMalha' /*+ categoria*/, new Set<String>{categoria});
                    } else {
                        mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoMalha' /*+ categoria*/).add(categoria);
                    }
                }

                if (oi.CampanhaShelfLifeAux__c && !oi.CampanhaShelfLife__c) {
                    if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/)) {
                        mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                    } else {
                        mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/).add(categoria);
                    }
                }

                if (oi.Order.Type == 'PedidoBonificacao') {
                    if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoBonificacao' /*+ categoria*/)) {
                        mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoBonificacao' /*+ categoria*/, new Set<String>{categoria});
                    } else {
                        mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoBonificacao' /*+ categoria*/).add(categoria);
                    }
                }
            }

            system.debug('setUserId: ' + setUserId);
            Set<Id> setAccountId = new Set<Id>();
            for (Order ord : setOrder) {
                setAccountId.add(ord.AccountId);
            }

            mapApprovalProcessToUserIdSet = ApprovalProcessManagement.getApprovalUsers(setAccountId, mapRecTypeToCategories);

            system.debug('setUserId: ' + setUserId);

            list<Approval.ProcessSubmitRequest> lstAprovalRequest = new list<Approval.ProcessSubmitRequest>();

            system.debug('mapRecTypeToCategories: ' + mapRecTypeToCategories);
            system.debug('mapApprovalProcessToUserIdSet: ' + mapApprovalProcessToUserIdSet);

            for (String chave : mapRecTypeToCategories.keySet()) {
                string [] arrChave = chave.split('----');
                for (String approvalRecType : mapApprovalProcessToUserIdSet.keySet()) {
                    system.debug('approvalRecType: ' + approvalRecType);
                    system.debug('arrChave[1]: ' + arrChave[1]);
                    if (approvalRecType.contains(arrChave[1])) {
                        for (Id userId : mapApprovalProcessToUserIdSet.get(approvalRecType)) {
                            lstAprovalRequest.add(getProcessRequest(arrChave[0], userId, approvalRecType));
                        }
                    }
                }
            }


            system.debug('lstAprovalRequest: ' + lstAprovalRequest);
            if(!lstAprovalRequest.isEmpty()){
                list<Order> lo = new list<Order>();
                for (Order o : newRecordList) {
                    if (setPedido.contains(o.Id)){ 
                        Order oNew = new Order();
                        oNew.Id = o.Id;
                        oNew.NecessitaAprovacaoComercial__c      = mapRecTypeToCategories.containsKey(o.Id + '----Pedido_AprovacaoComercial');
                        oNew.NecessitaAprovacaoPricing__c        = mapRecTypeToCategories.containsKey(o.Id + '----Pedido_AprovacaoPricing');
                        oNew.NecessitaAprovacaoMalha__c          = mapRecTypeToCategories.containsKey(o.Id + '----Pedido_AprovacaoMalha');
                        oNew.NecessitaAprovacaoRegionalizacao__c = mapRecTypeToCategories.containsKey(o.Id + '----Pedido_AprovacaoRegionalizacao');
                        oNew.NecessitaAprovacaoBonificacao__c    = mapRecTypeToCategories.containsKey(o.Id + '----Pedido_AprovacaoBonificacao');

                        if (!oNew.NecessitaAprovacaoComercial__c && !oNew.NecessitaAprovacaoPricing__c && !oNew.NecessitaAprovacaoMalha__c && !oNew.NecessitaAprovacaoRegionalizacao__c && !oNew.NecessitaAprovacaoBonificacao__c) {
                            oNew.AprovadoComercial__c      = true;
                            oNew.AprovadoPricing__c        = true;
                            oNew.AprovadoRegionalizacao__c = true;
                            oNew.AprovadoBonificacao__c    = true;
                            oNew.AprovadoMalha__c          = true;
                            oNew.solicitacaoAprovada__c    = true;
                            oNew.RejeicaoProcesso__c       = false;
                        }
                        
                        if (oNew.NecessitaAprovacaoComercial__c || oNew.NecessitaAprovacaoPricing__c || oNew.NecessitaAprovacaoMalha__c || oNew.NecessitaAprovacaoRegionalizacao__c || oNew.NecessitaAprovacaoBonificacao__c) {
                            oNew.Status = 'Aguardando aprovação';
                        }
                        lo.add(oNew);
                    }
                }
                OrderHandler.disableTrigger();
                if(!lo.isEmpty()){
                    update (List<Order>)JSON.deserialize(JSON.serialize(lo), List<Order>.class);
                }
                system.debug('lo ' + lo);
                for(Approval.ProcessSubmitRequest op : lstAprovalRequest){
                    system.debug('OBJETO'+op.getObjectId());
                    system.debug('PROCESSO'+op.getProcessDefinitionNameOrId());
                    system.debug('USUÁRIO '+op.getNextApproverIds());
                }
                List<Approval.ProcessResult> lstResult = Approval.process( lstAprovalRequest );
                for (Order o : newRecordList) {
                    if(!Approval.isLocked(o)){
                        if (setPedido.contains(o.Id)) {
                            system.debug('não bloqueia ' + o);
                            o.AprovadoComercial__c      = true;
                            o.AprovadoPricing__c        = true;
                            o.AprovadoRegionalizacao__c = true;
                            o.AprovadoBonificacao__c    = true;
                            o.AprovadoMalha__c          = true;
                        }
                    }
                }
                OrderHandler.enableTrigger();
            }else{
                List<Order> lpedido = new list<Order>();
                Set<Id> parentOrderSet              = new Set<Id>();
                Set<Id> ordIdSet                    = new Set<Id>();

                for (Order o : newRecordList) {
                    Order oNew = new Order();
                    if (setPedido.contains(o.Id)) {
                        oNew.Id = o.Id;
                        oNew.AprovadoComercial__c                = true;
                        oNew.AprovadoPricing__c                  = true;
                        oNew.AprovadoRegionalizacao__c           = true;
                        oNew.AprovadoBonificacao__c              = true;
                        oNew.AprovadoMalha__c                    = true;
                        oNew.solicitacaoAprovada__c              = true;
                        oNew.RejeicaoProcesso__c                 = false;
                        oNew.NecessitaAprovacaoComercial__c      = false;
                        oNew.NecessitaAprovacaoPricing__c        = false;
                        oNew.NecessitaAprovacaoMalha__c          = false;
                        oNew.NecessitaAprovacaoRegionalizacao__c = false;
                        oNew.NecessitaAprovacaoBonificacao__c    = false;
                        oNew.Status = 'Aprovado'; 
                        lpedido.add(oNew);
                        parentOrderSet.add(o.Id);
                    }
                }
                if(!lpedido.isEmpty()){
                    OrderHandler.disableTrigger();
                    Update lpedido;
                    OrderHandler.enableTrigger();
                    for (Order o : [SELECT Id, externalId__c, AccountId,  CondicaoPagamento__c, CodigoIntegradora__c, Laboratorio__c, 
                                        StatusIntegracao__c, Status, PedidoPaiStatus__c 
                                        FROM Order WHERE PedidoPai__c IN :parentOrderSet                             
                                        AND externalId__c != null]) {
                        if (o.Status != 'Aguardando envio de cancelamento' && o.Status != 'Cancelado') {
                            if( (o.CodigoIntegradora__c != null && o.Laboratorio__c != null ) || (o.CodigoIntegradora__c == null && o.Laboratorio__c == null )){
                                ordIdSet.add(o.Id);
                            }
                        }
                    }
                    if (!ordIdSet.isEmpty()) {
                        if (ordIdSet.size() < 50){
                            System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>(ordIdSet)));
                        } else {
                            BatchSendApprovalOrder.run(ordIdSet);
                        }
                    }
                }
            }
        }
        
        system.debug(labOrderToUpdate);
        if(!labOrderToUpdate.isEmpty()){
            OrderHandler.disableTrigger();
            update labOrderToUpdate;
            OrderHandler.enableTrigger();
        }
        System.debug(labOrderToUpdate);
    }

    public static void checkLabApproval(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> approvalParentOrderIdSet  = new Set<Id>();
        List<Order> orderToUpdate = new List<Order>();
        Set<Id> rejectParentOrderIdSet    = new Set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.Status != oldOrder.Status && o.Status == 'Rejeitado na integradora') {
                rejectParentOrderIdSet.add(o.PedidoPai__c);
            }
        }
        if (!rejectParentOrderIdSet.isEmpty()) {
            for (Order ord : [SELECT Id, Status FROM Order WHERE PedidoPai__c IN :rejectParentOrderIdSet]) {
                ord.Status = 'Rejeitado na integradora';
                orderToUpdate.add(ord);
            }
        }
        if (!orderToUpdate.isEmpty()) {
            OrderHandler.disableTrigger();
            update orderToUpdate;
            OrderHandler.enableTrigger();
        }
    }

    public static void checkVansOrder(Map<Id, Order> newMap){
        Map<Id, Boolean> mapLabOrdIdToApproved = new Map<Id, Boolean>();
        Set<Id> senAutomaticdLabOrder = new Set<Id>();
        Set<Id> fatherOrdIdSet = new Set<Id>();
        Set<Id> ordIdSet = new Set<Id>();
        for (Order o : newMap.values()) {
            if (o.PedidoFilho__c && o.CodigoIntegradora__c != null && (o.Status == 'Aprovado' || o.Status == 'Reprovado')) {
                mapLabOrdIdToApproved.put(o.Id, o.Status == 'Aprovado' ? true : false);
            }
        }
        system.debug(mapLabOrdIdToApproved);

        List<PedidoIntegradora__c> listPedInt = new List<PedidoIntegradora__c>();
        for (PedidoIntegradora__c pedIntegradora : [SELECT Id, RecordType.DeveloperName, Status__c, Pedido__c FROM PedidoIntegradora__c WHERE Pedido__c IN: mapLabOrdIdToApproved.keySet()]) {
            if (pedIntegradora.RecordType.DeveloperName == 'PedidoFluxoAutomatico') {
                if (pedIntegradora.Status__c == 'Aguardando aprovação comercial') {
                    pedIntegradora.Status__c = mapLabOrdIdToApproved.get(pedIntegradora.Pedido__c) ? 'Aprovado comercial' : 'Reprovado comercial';
                    listPedInt.add(pedIntegradora);
                    fatherOrdIdSet.add(pedIntegradora.Pedido__c);
                }
            }
        }
        system.debug(listPedInt);

        if (!listPedInt.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            update listPedInt;
            PedidoIntegradoraHandler.enableTrigger();
        }
    }

    public static void sendPedidoIntegradora(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Set<Id> ordWithInconsisIdSet  = new Set<Id>();
        Set<Id> sendLabOrderIdSet  = new Set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.CodigoIntegradora__c != null && (oldOrder.CondicaoPagamento__c != o.CondicaoPagamento__c || oldOrder.MensagemNF__c != o.MensagemNF__c)) {
                ordWithInconsisIdSet.add(o.Id);
            }
        }
        if (!ordWithInconsisIdSet.isEmpty()) {
            for (PedidoIntegradora__c o : [SELECT Id, Inconsistencias__c FROM PedidoIntegradora__c WHERE Pedido__c IN :ordWithInconsisIdSet]) {
                if (o.Inconsistencias__c != null) {
                    sendLabOrderIdSet.add(o.Id);
                }
            }
        }
        if (!sendLabOrderIdSet.isEmpty()) {
            //System.enqueueJob(new IntegrationLaboratoryOrderQueueable(0, new List<Id>(sendLabOrderIdSet), 'N'));      
        }
    }

    public static Approval.ProcessSubmitRequest getProcessRequest(Id orderId, Id userId, String processoDef) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Envio automático do pedido');
        req.setObjectId(orderId);
        req.setProcessDefinitionNameOrId(processoDef);
        // req.setNextApproverIds(lUserId);
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }

    public static void deletSplitOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap){

        set<Id> setPedido = new set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.Id);
            if ((o.Status  == 'Em digitação' && oldOrder.Status == 'Aguardando aprovação' &&  o.RecordTypeId == MOTHERORDER_RECORDTYPE) ||
                (o.Status == 'Reprovado' && oldOrder.Status == 'Aguardando aprovação' && o.RecordTypeId == MOTHERORDER_RECORDTYPE) ) {
                setPedido.add(o.Id);
            }
        }
        list<Order> lOrderUpdate = new List<Order>();
        list<Order> lOrderDelete = new List<Order>();
        list<Id> lOrderId = new List<Id>();
        if (!setPedido.isEmpty()) {
            for (Order ord : [SELECT Id, Status, RecordTypeId, PedidoPai__c, PedidoPaiStatus__c, externalId__c, StatusIntegracao__c, CodigoIntegradora__c FROM Order WHERE PedidoPai__c =: setPedido]) {
                if (ord.PedidoPaiStatus__c != 'Reprovado' && ord.StatusIntegracao__c == 'Não integrado' && ord.Status == 'ErroIntegracao') {
                    lOrderDelete.add(ord);
                } else {
                    if (ord.PedidoPaiStatus__c == 'Reprovado') {
                        ord.Status = 'Aguardando envio de rejeição';
                        ord.PedidoPai__c = null;
                        if (ord.CodigoIntegradora__c != null) {
                            lOrderId.add(ord.Id);
                        }
                    } else {
                        ord.PedidoPai__c = null;
                        ord.Status = 'Aguardando envio de cancelamento';
                        ord.Description = ord.externalId__c == null ? 'Pedido aguardando o retorno do ERP para ser excluído.' : null;
                    }
                    lOrderUpdate.add(ord);
                }
                // lOrderId.add(ord.Id);
                // lOrderUpdate.add(ord);
            }
        }
        map<Id,Order> mapOrderUpdate = new map<Id,Order>();

        if (!lOrderDelete.isEmpty()) {
            delete lOrderDelete;
        }
        if(!lOrderUpdate.isEmpty()){
            /*for(Order o : lOrderUpdate){
                if(!mapOrderUpdate.containsKey(o.PedidoPai__c)){
                    Order updOrder = newMap.get(o.Id);
                    updOrder.RecordTypeId = o.RecordTypeId;
                    updOrder.Id = o.PedidoPai__c;
                    mapOrderUpdate.put(o.PedidoPai__c,updOrder);
                }
            }            
            update mapOrderUpdate.values();*/
            OrderHandler.disableTrigger();
            update lOrderUpdate;
            OrderHandler.enableTrigger();
        }
        if(!lOrderId.isEmpty()) {
            System.enqueueJob(new IntegrationApprovalOrderQueueable(0, lOrderId));  
        }
            
    }
    
    public static void splitOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap, List<Order> newRecordList){
        set<Id> setPedidos = new set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.Id);
            if (o.EnviarAprovacao__c && !oldOrder.EnviarAprovacao__c && o.RecordTypeId == MOTHERORDER_RECORDTYPE) {
                setPedidos.add(o.Id);
            }
        } 
        if (!setPedidos.isEmpty()) {
            for (Order ord : [SELECT Id, PedidoPai__c, PedidoPai__r.RecordTypeId FROM Order WHERE PedidoPai__c IN: setPedidos]) {
                if (ord.PedidoPai__r.RecordTypeId == MOTHERORDER_RECORDTYPE) {
                    setPedidos.remove(ord.PedidoPai__c);
                }
            }
        }
        if(!setPedidos.isEmpty()){
            System.debug('Entrou split 1');
            map<String,list<OrderItem>> mapNewOrder = new map<String,list<OrderItem>>();
            mapNewOrder = splitOrderRecordType(splitOrderFornecedor(splitOrderCentroDistribuicao(setPedidos)), newMap);
    
            if(mapNewOrder != null && !mapNewOrder.isEmpty()){
                splitOrderInsert(mapNewOrder, newMap, newRecordList );
            }
        }  
    }

    public static void splitOrderInsert(map<String,list<OrderItem>> mapNewOrder , Map<Id, Order> newMap, List<Order>  newRecordList){
        map<String,Order> mapOrderNew = new map<String,Order>();
        set<Id> setIdPedidos = new set<Id>();
        for(String chave : mapNewOrder.keySet()){
            string [] arrChave = chave.split('---');
            // Order o = newMap.get(arrChave[0]);
            setIdPedidos.add(arrChave[0]);
            mapOrderNew.put(chave, geraPedido( newMap.get(arrChave[0]), mapNewOrder.get(chave), arrChave ) );
        }
        insert mapOrderNew.values(); 
        list<OrderItem> loi = new list<OrderItem>();
        for(String chave : mapOrderNew.keySet()){
            string [] arrChave = chave.split('---');
            Order oNew = mapOrderNew.get(chave);
            for(OrderItem oi : mapNewOrder.get(chave)){
                loi.add(geraItemPedido(oi, oNew.Id ));
            }
        }
        OrderHandler.disableTrigger();
        insert loi;
        // OrderScreenController.insertUserShare(loi);
        OrderHandler.enableTrigger();
        /*for(Order o :newRecordList){
            if(setIdPedidos.contains(o.Id)){
                o.RecordTypeId = MOTHERORDER_RECORDTYPE;
            }
        }*/
    }
    public static OrderItem  geraItemPedido(OrderItem oi , String orderId){

        OrderItem newOrderItem = new OrderItem();
        newOrderItem.PriceBookEntryId      = oi.PriceBookEntryId;
        newOrderItem.CentroDistribuicao__c = oi.CentroDistribuicao__c;
        newOrderItem.Laboratorio__c        = oi.Laboratorio__c;
        newOrderItem.TipoIntegradora__c    = oi.TipoIntegradora__c;
        newOrderItem.ServiceDate           = oi.ServiceDate;
        newOrderItem.EndDate               = oi.EndDate;
        newOrderItem.Description           = oi.Description;
        newOrderItem.ForaMalha__c          = oi.ForaMalha__c;
        newOrderItem.ItemCampanha__c       = oi.ItemCampanha__c;
        newOrderItem.QuoteLineItemId       = oi.QuoteLineItemId;
        newOrderItem.ItemContrato__c       = oi.ItemContrato__c;
        newOrderItem.CNPJCD__c             = oi.CNPJCD__c;
        newOrderItem.OriginalOrderItemId   = oi.OriginalOrderItemId;
        newOrderItem.Lote__c               = oi.Lote__c;
        newOrderItem.MargemAlvo__c         = oi.MargemAlvo__c;
        newOrderItem.Margem__c             = oi.Margem__c;
        // newOrderItem.ExternalId__c         = oi.ExternalId__c; // não tem necessidade
        newOrderItem.OrderId               = orderId;
        newOrderItem.PrecoTotal__c         = oi.PrecoTotal__c;
        newOrderItem.UnitPrice             = oi.UnitPrice;
        newOrderItem.Desconto__c           = oi.Desconto__c;
        newOrderItem.Product2Id            = oi.Product2Id;
        newOrderItem.Quantity              = oi.Quantity;
        newOrderItem.QuantidadeUn__c       = oi.QuantidadeUn__c;
        newOrderItem.ScoreAlvo__c          = oi.ScoreAlvo__c;
        newOrderItem.ScoreAtual__c         = oi.ScoreItem__c;
        newOrderItem.ScoreBU__c            = oi.ScoreBU__c;
        newOrderItem.ScoreItem__c          = oi.ScoreItem__c;
        newOrderItem.ScoreMix__c           = oi.ScoreMix__c;
        newOrderItem.Custo__c              = oi.Custo__c;
        newOrderItem.Imposto__c            = oi.Imposto__c;
        newOrderItem.TipoOperacao__c       = oi.TipoOperacao__c;
        newOrderItem.ValidadeMinima__c     = oi.ValidadeMinima__c;
        newOrderItem.ValorCx__c            = oi.ValorCx__c;
        newOrderItem.ValorUn__c            = oi.ValorUn__c;
        newOrderItem.ValorMalha__c         = oi.ValorMalha__c;
        newOrderItem.ValorSugerido__c      = oi.ValorSugerido__c;
        newOrderItem.Range__c              = oi.Range__c;
        newOrderItem.Vendedor__c           = oi.Vendedor__c;
        newOrderItem.SequenciaOC__c        = oi.SequenciaOC__c;
        return newOrderItem;
    }
    public static Order geraPedido(Order contextOrder, list<OrderItem> loi, string [] chave){
        Id recordTypeBonif = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de bonificação').getRecordTypeId();
        Id recordTypeVendaDireta = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de venda').getRecordTypeId(); 
        Id recordTypeContaOrdem = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de conta e ordem').getRecordTypeId(); 

        Map<String, Decimal> mapCnpjCdToFreightValue = new Map<String, Decimal>();
        Map<String, String> mapCnpjCdToFreightType = new Map<String, String>();

        List<String> listSplittedCdFreighValue = new List<String>();

        Boolean unicScoreMargem = true;
        for (OrderItem ordItem : loi) {
            if (ordItem.Laboratorio__c == null || ordItem.Laboratorio__c == '') {
                unicScoreMargem = false;
            }
        }
        if (contextOrder.Frete__c != null) {
            listSplittedCdFreighValue = contextOrder.Frete__c.split(',');
        }

        for (String cdFreighValue : listSplittedCdFreighValue) {
            List<String> splittedVal = cdFreighValue.split(':');
            mapCnpjCdToFreightValue.put(splittedVal[0].trim(), Decimal.valueOf(splittedVal[1].trim()));
            mapCnpjCdToFreightType.put(splittedVal[0].trim(), splittedVal[2].trim());
        }

        Order newOrder                                 = new Order();
        if(chave.contains('Bonif')){
            newOrder.RecordTypeId                      = recordTypeBonif;
            newOrder.AccountId                         = contextOrder.AccountId;
        } else{
            if(chave.contains('conta1') || chave.contains('conta2')){
                newOrder.RecordTypeId                  = recordTypeContaOrdem;//contextOrder.RecordTypeId;
                newOrder.AccountId                     = loi[0].Order.AccountId;
            }else{
                newOrder.AccountId                     = contextOrder.AccountId;
                if(contextOrder.Type == 'PedidoContaOrdem'){
                    newOrder.RecordTypeId              = recordTypeContaOrdem;//contextOrder.RecordTypeId;
                }else{
                    if(contextOrder.Type == 'PedidoBonificacao'){
                        newOrder.RecordTypeId          = recordTypeBonif;
                    }else{
                        newOrder.RecordTypeId          = recordTypeVendaDireta;//loi[0].Order.RecordTypeId;
                    }
                }
            }
        }
        newOrder.CentroDistribuicao__c                 = loi[0].CentroDistribuicao__c;
        newOrder.AprovadoComercial__c                  = false;
        newOrder.AprovadoPricing__c                    = false;
        newOrder.AprovadoMalha__c                      = false;
        newOrder.AprovadoRegionalizacao__c             = false;
        newOrder.AprovadoBonificacao__c                = false;
        newOrder.EnviarAprovacao__c                    = false;
        newOrder.PedidoPai__c                          = contextOrder.Id;
        newOrder.CanalEntrada__c                       = contextOrder.CanalEntrada__c;
        newOrder.Pricebook2Id                          = contextOrder.Pricebook2Id;
        newOrder.CustomerAuthorizedById                = contextOrder.CustomerAuthorizedById;
        newOrder.ClienteRecebedor__c                   = contextOrder.ClienteRecebedor__c;
        newOrder.CNPJCD__c                             = loi[0].CNPJCD__c;
        newOrder.Laboratorio__c                        = loi[0].Laboratorio__c;
        newOrder.TipoIntegradora__c                    = loi[0].TipoIntegradora__c;
        newOrder.BillToContactId                       = contextOrder.BillToContactId;
        newOrder.CompartilhamentoRealizado__c          = contextOrder.CompartilhamentoRealizado__c;
        newOrder.CondicaoPagamento__c                  = contextOrder.CondicaoPagamento__c;
        newOrder.ShipToContactId                       = contextOrder.ShipToContactId;
        newOrder.ContatoOrcamento__c                   = contextOrder.ContatoOrcamento__c;
        // newOrder.QuoteId                               = contextOrder.QuoteId;
        // newOrder.CodigoPedido__c                       = contextOrder.CodigoPedido__c;
        // newOrder.ExternalId__c                         = contextOrder.ExternalId__c;
        // newOrder.ActivatedDate                         = contextOrder.ActivatedDate;
        newOrder.DataUltimaModificacao__c              = contextOrder.DataUltimaModificacao__c;
        newOrder.CompanyAuthorizedDate                 = contextOrder.CompanyAuthorizedDate;
        newOrder.CustomerAuthorizedDate                = contextOrder.CustomerAuthorizedDate;
        //newOrder.DataCriacao__c                        = contextOrder.DataCriacao__c;
        newOrder.DataDivisaoParcelas__c                = contextOrder.DataDivisaoParcelas__c;
        newOrder.DatasParcelas__c                      = contextOrder.DatasParcelas__c;
        newOrder.DiaParcelas__c                        = contextOrder.DiaParcelas__c;
        newOrder.EffectiveDate                         = contextOrder.EffectiveDate;
        newOrder.EndDate                               = contextOrder.EndDate;
        newOrder.Frete__c                              = contextOrder.Frete__c;
        newOrder.PoDate                                = contextOrder.PoDate;
        newOrder.DataEntrega__c                        = contextOrder.DataEntrega__c;
        newOrder.CompanyAuthorizedById                 = contextOrder.CompanyAuthorizedById;
        newOrder.Endereco_Entrega__c                   = contextOrder.Endereco_Entrega__c;
        newOrder.EnderecoEntrega__c                    = contextOrder.EnderecoEntrega__c;
        newOrder.EnderecoRecebedor__c                  = contextOrder.EnderecoRecebedor__c;
        newOrder.EnviarAprovacao__c                    = false;
        newOrder.ErroIntegracaoAprovacao__c            = false;
        newOrder.ErroIntegracaoCancelamento__c         = false;
        newOrder.ErroIntegracaoConfirmacao__c          = false;
        newOrder.ErroIntegracaoRejeitado__c            = false;
        newOrder.FormaPagamento__c                     = contextOrder.FormaPagamento__c;
        newOrder.GerarBoleto__c                        = contextOrder.GerarBoleto__c;
        newOrder.Margem__c                             = unicScoreMargem ? 100 : contextOrder.Margem__c;
        newOrder.MargemAlvo__c                         = contextOrder.MargemAlvo__c;
        newOrder.MensagemNF__c                         = contextOrder.MensagemNF__c;
        newOrder.MensagemErroIntegracaoAprovacao__c    = null;
        newOrder.MensagemErroIntegracaoCancelamento__c = null;
        newOrder.MensagemErroIntegracaoConfirmacao__c  = null;
        newOrder.MensagemErroIntegracaoRejeitado__c    = null;
        newOrder.ModificadoPor__c                      = contextOrder.ModificadoPor__c;
        newOrder.NecessitaAprovacaoComercial__c        = false;
        newOrder.NecessitaAprovacaoPricing__c          = false;
        newOrder.NecessitaAprovacaoMalha__c            = false;
        newOrder.NecessitaAprovacaoRegionalizacao__c   = false;
        newOrder.NecessitaAprovacaoBonificacao__c      = false;
        newOrder.NomeMedico__c                         = contextOrder.NomeMedico__c;
        newOrder.NomePaciente__c                       = contextOrder.NomePaciente__c;
        newOrder.Name                                  = contextOrder.Name;
        newOrder.NumeroNotaFiscal__c                   = contextOrder.NumeroNotaFiscal__c;
        newOrder.OrderReferenceNumber                  = contextOrder.OrderReferenceNumber;
        newOrder.ContractId                            = contextOrder.ContractId;
        newOrder.PoNumber                              = contextOrder.PoNumber;
        newOrder.NumeroPedidoCliente__c                = contextOrder.NumeroPedidoCliente__c;
        newOrder.Description                           = contextOrder.Description;
        newOrder.ObservacoesPedido__c                  = contextOrder.ObservacoesPedido__c;
        newOrder.OpportunityId                         = contextOrder.OpportunityId;
        newOrder.Origem__c                             = contextOrder.Origem__c;
        newOrder.IsReductionOrder                      = contextOrder.IsReductionOrder;
        newOrder.OriginalOrderId                       = contextOrder.OriginalOrderId;
        newOrder.RecallProcesso__c                     = false;
        newOrder.RejeicaoProcesso__c                   = contextOrder.RejeicaoProcesso__c;
        newOrder.Score__c                              = unicScoreMargem ? 100 : contextOrder.Score__c;
        newOrder.Status                                = Test.isRunningTest() ? 'Em digitação' : contextOrder.Status;
        newOrder.StatusIntegracao__c                   = contextOrder.StatusIntegracao__c;
        newOrder.StatusAprovacao__c                    = 'Em digitação';
        newOrder.TipoOperacao__c                       = contextOrder.TipoOperacao__c;
        newOrder.TipoFrete__c                          = mapCnpjCdToFreightType.get(loi[0].CNPJCD__c); //contextOrder.TipoFrete__c
        newOrder.Type                                  = contextOrder.Type;
        newOrder.ValorFrete__c                         = mapCnpjCdToFreightValue.get(loi[0].CNPJCD__c); //contextOrder.ValorFrete__c
        newOrder.ValorTotal__c                         = contextOrder.ValorTotal__c;
        newOrder.Idportalcotacoes__c                   = contextOrder.Idportalcotacoes__c;

        Boolean ra = false;
        for (CondicaoPagamento__c condicaoPag : [SELECT Id, Name FROM CondicaoPagamento__c WHERE Id = :contextOrder.CondicaoPagamento__c]) {
            System.debug('Condição de Pagamento: ' + condicaoPag.Name);
            ra = (condicaoPag.Name == 'RA' || condicaoPag.Name == 'RA/RECEB. ANTECIP.') ? true : false; 
        }
        newOrder.NecessarioComprovante__c = ra;

        return newOrder;
    }
    // public static  map<String,list<OrderItem>> splitOrderValor(map<String,list<OrderItem>> mapNewOrder, Map<Id, Order> newMap){
    //     map<String,list<OrderItem>> mapNewOrderNew = new map<String,list<OrderItem>>();
    //     List<OrderItem> litensPedidos = new List<OrderItem>();
    //     decimal totalQtdPedido = 0;
    //     Integer totalQtdPedidoInt = 0;
    //     decimal limitePedido = 1200000.00;
    //     for(String chave : mapNewOrder.keySet()){
    //         string [] arrChave = chave.split('---');
    //         Order o = newMap.get(arrChave[0]);
    //         if(o.TotalAmount > limitePedido){
    //             totalQtdPedido = o.TotalAmount  / limitePedido  ;
    //             totalQtdPedidoInt = Integer.valueOf(totalQtdPedido);
    //             if(totalQtdPedido - totalQtdPedidoInt > 0){
    //                 totalQtdPedidoInt = totalQtdPedidoInt + 1;
    //             }
    //                 for(OrderItem oi : mapNewOrder.get(chave)){
    //                     if(mapNewOrderNew.containsKey(chaveNew)){
    //                         litensPedidos = mapNewOrderNew.get(chaveNew); 
    //                     }else{
    //                         litensPedidos = new List<OrderItem>();
    //                     }
    //                     oi.Quantity = oi.Quantity / totalQtdPedidoInt;
    //                     litensPedidos.add(oi);

    //                     mapNewOrderNew.put(chaveNew, litensPedidos);
    //                 }
    //         }

    //     }
    //     return mapNewOrderNew;

    // }
    public static  map<String,list<OrderItem>> splitOrderFornecedor(map<String,list<OrderItem>> mapNewOrder){

        map<String,list<OrderItem>> mapNewOrderNew = new map<String,list<OrderItem>>();
        List<OrderItem> litensPedidos = new List<OrderItem>();

        for(String chave : mapNewOrder.keySet()){
            for(OrderItem oi : mapNewOrder.get(chave)){
                String chaveNew = ''; 
                if(oi.Product2.Fornecedor__c != null  ){
                    if(oi.Product2.Fornecedor__r.Name.contains('SANOFI')  ){
                        chaveNew = chave + '---SANOFI'; 
                    }else{
                        chaveNew = chave; 
                    }
                }else{
                        chaveNew = chave; 
                }
                if(mapNewOrderNew.containsKey(chaveNew)){
                    litensPedidos = mapNewOrderNew.get(chaveNew); 
                }else{
                    litensPedidos = new List<OrderItem>();
                }
                litensPedidos.add(oi);
                mapNewOrderNew.put(chaveNew, litensPedidos);
            }
        }
        return mapNewOrderNew;
    }

    public static  map<String,list<OrderItem>> splitOrderCentroDistribuicao(set<Id> setPedidos){
        map<String,list<OrderItem>> mapNewOrder = new map<String,list<OrderItem>>();
        List<OrderItem> litensPedidos = new List<OrderItem>();
            for(OrderItem oi : [SELECT Id, OrderId, Order.RecordTypeId, Order.TotalAmount, Order.AccountId, Order.ClienteRecebedor__c, ExternalId__c,PriceBookEntryId,CNPJCD__c,
                                    CentroDistribuicao__c, ServiceDate, EndDate, Description, ForaMalha__c, //NumeroItemPedido__c,
                                     ItemCampanha__c, QuoteLineItemId, ItemContrato__c, OriginalOrderItemId, Lote__c, MargemAlvo__c, Margem__c, Desconto__c, Laboratorio__c, TipoIntegradora__c,
                                     ListPrice, PrecoTotal__c, TotalPrice, UnitPrice, Product2Id, Quantity, QuantidadeUn__c, ScoreBU__c, ScoreMix__c, ScoreItem__c, Custo__c, Imposto__c, 
                                    AvailableQuantity, ScoreAlvo__c, ScoreAtual__c, TipoOperacao__c, UnidadeMedida__c, ValidadeMinima__c, ValorCx__c, ValorMalha__c, ValorSugerido__c, Range__c,
                                    ValorUn__c, Vendedor__c, Product2.Fornecedor__r.Name, Product2.Fornecedor__c, SequenciaOC__c
                             FROM OrderItem WHERE OrderId = : setPedidos ORDER BY OrderId, CentroDistribuicao__c, TipoIntegradora__c NULLS LAST, Product2.Fornecedor__r.Name, ItemContrato__c, ItemCampanha__c  ] ){
            system.debug('oi.TipoIntegradora__c: ' + oi.TipoIntegradora__c);
            // if (oi.TipoIntegradora__c != null) {
            //     if (!mapOrderToLab.containsKey(oi.OrderId)) {
            //         mapOrderToLab.put(oi.OrderId, true);
            //     }
            // } else {
            //     if (!mapOrderToLab.containsKey(oi.OrderId)) {
            //         mapOrderToLab.put(oi.OrderId, false);
            //     }
            // }
            if (oi.TipoIntegradora__c != null) {
                if(mapNewOrder.containsKey(oi.OrderId + '---' + oi.CentroDistribuicao__c + '---' + oi.TipoIntegradora__c)){
                    litensPedidos = mapNewOrder.get(oi.OrderId + '---' + oi.CentroDistribuicao__c + '---' + oi.TipoIntegradora__c);
                }else{
                    litensPedidos = new List<OrderItem>();
                }                
                litensPedidos.add(oi);
                mapNewOrder.put(oi.OrderId + '---' + oi.CentroDistribuicao__c + '---' + oi.TipoIntegradora__c, litensPedidos);
                system.debug('mapNewOrder: ' + mapNewOrder);
            } else {
                system.debug('mapNewOrder: ' + mapNewOrder);
                if (!mapNewOrder.keySet().isEmpty()) {
                    for (String key : mapNewOrder.keySet()) {
                        system.debug(key);
                        system.debug(oi.OrderId + '---' + oi.CentroDistribuicao__c);
                        system.debug(key.contains(oi.OrderId + '---' + oi.CentroDistribuicao__c));
                        if (key.contains(oi.OrderId + '---' + oi.CentroDistribuicao__c)) {
                            litensPedidos = mapNewOrder.get(key);
                            litensPedidos.add(oi);
                            mapNewOrder.put(key, litensPedidos);
                            system.debug('key: ' + key);
                            system.debug('SPLIT IF');
                            break;
                        } else {
                            if (mapNewOrder.keySet().contains(oi.OrderId + '---' + oi.CentroDistribuicao__c)) {
                                litensPedidos = mapNewOrder.get(oi.OrderId + '---' + oi.CentroDistribuicao__c);
                                litensPedidos.add(oi);
                            } else {
                                litensPedidos = new List<OrderItem>();
                                litensPedidos.add(oi);
                            }
                            mapNewOrder.put(oi.OrderId + '---' + oi.CentroDistribuicao__c, litensPedidos);
                            system.debug('Chave else: ' + oi.OrderId + '---' + oi.CentroDistribuicao__c);
                            system.debug('SPLIT ELSE');
                            break;
                        }
                    }
                } else {
                    if (mapNewOrder.containsKey(oi.OrderId + '---' + oi.CentroDistribuicao__c)) {
                        litensPedidos = mapNewOrder.get(oi.OrderId + '---' + oi.CentroDistribuicao__c);
                    }else{
                        litensPedidos = new List<OrderItem>();
                    }
                    
                    litensPedidos.add(oi);
                    mapNewOrder.put(oi.OrderId + '---' + oi.CentroDistribuicao__c, litensPedidos);
                    system.debug('PRIMEIRO ITEM ADD');
                    system.debug('litensPedidos: ' + litensPedidos);
                }
            }
        }        

        system.debug('litensPedidos: ' + litensPedidos);
        system.debug('mapNewOrder: ' + mapNewOrder);

        return mapNewOrder;
    }

    public static  map<String,list<OrderItem>> splitOrderRecordType(Map<String,list<OrderItem>> mapNewOrder , Map<Id, Order> newMap){

        Id recordTypeBonif = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de bonificação').getRecordTypeId(); 
        Id recordTypeContaOrdem = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de conta e ordem').getRecordTypeId(); 
        Id recordTypeVendaDireta = Schema.Sobjecttype.Order.getRecordTypeInfosByName().get('Pedido de venda').getRecordTypeId(); 
        map<String,list<OrderItem>> mapNewOrderRecordType = new map<String,list<OrderItem>>();

        // TotalAmount
        for(String chave : mapNewOrder.keySet()){
            string [] arrChave = chave.split('---');
            Order o = newMap.get(arrChave[0]);
            List<OrderItem> litensPedidos = mapNewOrder.get(chave);
           /* if(o.RecordTypeId == recordTypeBonif){
                String chavebonif = chave + '---' + 'Bonif';
                mapNewOrderRecordType.put(chavebonif, litensPedidos);
                for(OrderItem oi : litensPedidos){
                    oi.Order.RecordTypeId = recordTypeVendaDireta;
                }
                String chaveDi = chave + '---' + 'vdDireta';
                mapNewOrderRecordType.put(chaveDi, litensPedidos);
            }else if(o.RecordTypeId == recordTypeContaOrdem){

            }else */ 
            if(o.Type == 'PedidoBonificacao'){
                String chavebonif = chave + '---' + 'Bonif';
                mapNewOrderRecordType.put(chavebonif, litensPedidos);
            }else 
            if(o.Type == 'PedidoContaOrdem'){
                String conta1 = chave + '---' + 'conta1';
                mapNewOrderRecordType.put(conta1, litensPedidos);
                for(OrderItem oi : litensPedidos){
                    oi.Order.AccountId = oi.Order.ClienteRecebedor__c;
                }
                String conta2 = chave + '---' + 'conta2';
                mapNewOrderRecordType.put(chave, litensPedidos);
            }else{
                mapNewOrderRecordType.put(chave, litensPedidos);
            }
        }

        return mapNewOrderRecordType;
    }

    public static Map<Id, Boolean> getVansOrderMap(List<Order> listOrd) {
        Map<Id, Boolean> mapHasVansOrder = new Map<Id, Boolean>();

        for (Order currOrder : listOrd) {
            mapHasVansOrder.put(currOrder.id, false);
        }

        for (PedidoIntegradora__c ped: [SELECT Id, Pedido__c, Status__c FROM PedidoIntegradora__c WHERE Pedido__c IN: mapHasVansOrder.keySet()]) {
            if (ped.Status__c == 'Aprovado comercial' || ped.Status__c == 'Reprovado comercial') {
                mapHasVansOrder.put(ped.Pedido__c, true);
            }
        }

        return mapHasVansOrder;
    }

    public static void automaticOrderApproval(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Set<Id> approvedOrderIds = new Set<Id>();
        Set<Id> rejectedOrderIds = new Set<Id>();
        
        Map<Id, Set<String>> mapOrderIdToPIDeveloperNames = new Map<Id, Set<String>>();
        Map<Id, Boolean> mapHasVansOrder = new Map<Id, Boolean>();
        for (Order currOrder : newMap.values()) {
            mapHasVansOrder.put(currOrder.id, false);
        }

        for (PedidoIntegradora__c ped: [SELECT Id, Pedido__c, Status__c FROM PedidoIntegradora__c WHERE Pedido__c IN: mapHasVansOrder.keySet()]) {
            if (ped.Status__c == 'Aprovado comercial' || ped.Status__c == 'Reprovado comercial' || ped.Status__c == 'Aguardando aprovação comercial') {
                mapHasVansOrder.put(ped.Pedido__c, true);
            }
        }
    
        for (Order currOrder : newMap.values()) {
            system.debug(oldMap.get(currOrder.Id).SolicitacaoAprovada__c);
            system.debug(currOrder.SolicitacaoAprovada__c);
            system.debug(mapHasVansOrder.get(currOrder.Id));

            system.debug('RejeicaoProcesso__c old: ' + oldMap.get(currOrder.Id).RejeicaoProcesso__c);
            system.debug('RejeicaoProcesso__c new: ' + currOrder.RejeicaoProcesso__c);
            if (
                oldMap.get(currOrder.Id).SolicitacaoAprovada__c != currOrder.SolicitacaoAprovada__c &&
                currOrder.SolicitacaoAprovada__c &&
                (currOrder.UltimaAprovacao__c != null || mapHasVansOrder.get(currOrder.Id))
            ) { 
                approvedOrderIds.add(currOrder.Id);
                
                if (!mapOrderIdToPIDeveloperNames.containsKey(currOrder.Id)) {
                    mapOrderIdToPIDeveloperNames.put(currOrder.Id, new Set<String>());
                }

                mapOrderIdToPIDeveloperNames
                    .get(currOrder.Id)
                    .add(currOrder.UltimaAprovacao__c);
            } else if (
                oldMap.get(currOrder.Id).RejeicaoProcesso__c != currOrder.RejeicaoProcesso__c &&
                currOrder.RejeicaoProcesso__c &&
                (currOrder.UltimaAprovacao__c != null || mapHasVansOrder.get(currOrder.Id))
            ) {
                rejectedOrderIds.add(currOrder.Id);
            }
        }

        system.debug(approvedOrderIds);
        system.debug(rejectedOrderIds);

        Set<Id> setOrderId = new Set<Id>();
        
        boolean hasPending = false;

        if (!approvedOrderIds.isEmpty() || !rejectedOrderIds.isEmpty()) {
            List<Approval.ProcessWorkItemRequest> workItemsRequests = new List<Approval.ProcessWorkItemRequest>();

            Map<Id, ProcessInstance> processInstancesMap = new Map<Id, ProcessInstance>([
                SELECT 
                    Id, 
                    TargetObjectId,
                    Status,
                    ProcessDefinition.DeveloperName,
                    LastActorId,
                    (SELECT Id, ActorId FROM WorkItems)
                FROM ProcessInstance 
                WHERE TargetObjectId IN: approvedOrderIds
                OR TargetObjectId IN: rejectedOrderIds
            ]);

            system.debug(processInstancesMap);
            for (ProcessInstance currProcessInstance : processInstancesMap.values()) {
                Id orderId = currProcessInstance.TargetObjectId;
                String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;
                String lastApproval = newMap.get(orderId).UltimaAprovacao__c;

                system.debug('orderId: ' + orderId);
                system.debug('currDeveloperName: ' + currDeveloperName);
                system.debug('lastApproval: ' + lastApproval);
                
                for (ProcessInstanceWorkItem currWorkItem : currProcessInstance.WorkItems) {
                    setOrderId.add(orderId);
                    if (mapHasVansOrder.get(orderId)) {
                        setOrderId.add(orderId);
                        system.debug('Fluxo de aprovação de pedido integradora');
                        if (rejectedOrderIds.contains(orderId) && currWorkItem.ActorId != UserInfo.getUserId()) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Reject');
                            workItemsRequests.add(request);
                        } else if (approvedOrderIds.contains(orderId) && currWorkItem.ActorId != UserInfo.getUserId()) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Approve');
                            workItemsRequests.add(request);
                        }
                    } else {
                        if (
                            rejectedOrderIds.contains(orderId) &&
                            currWorkItem.ActorId == UserInfo.getUserId() &&
                            currDeveloperName != lastApproval
                        ) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Reject');
                            workItemsRequests.add(request);
                        } else if (
                            rejectedOrderIds.contains(orderId) &&
                            currWorkItem.ActorId != UserInfo.getUserId()
                        ) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Reject');
                            workItemsRequests.add(request);
                        }
    
                        // current user's pending work items
                        if (
                            !rejectedOrderIds.contains(orderId) &&
                            currWorkItem.ActorId == UserInfo.getUserId() &&
                            currDeveloperName != lastApproval
                        ) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Approve');
                            workItemsRequests.add(request);
    
                            mapOrderIdToPIDeveloperNames
                                .get(orderId)
                                .add(currDeveloperName);
                        }
                    }
                }
            }

            // rotina para adicionar workitems que deverão ser aprovados por developerName
            for (ProcessInstance currProcessInstance : processInstancesMap.values()) {
                Id orderId = currProcessInstance.TargetObjectId;
                String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;

                if (!rejectedOrderIds.contains(orderId)) {
                    if (mapOrderIdToPIDeveloperNames.get(orderId).contains(currDeveloperName)) {
    
                        for (ProcessInstanceWorkItem currWorkItem : currProcessInstance.WorkItems) {
                            // user's pending work items by developer name
                            if (currWorkItem.ActorId != UserInfo.getUserId()) {
                                Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                                request.setWorkitemId(currWorkItem.Id);
                                request.setAction('Approve');
                                workItemsRequests.add(request);
                            }
                        }
                    }
                }
            }

            Approval.process(workItemsRequests, true);

            Map<Id, ProcessInstance> checkProcessInstances = new Map<Id, ProcessInstance>([
                SELECT 
                    Id, 
                    TargetObjectId,
                    Status,
                    ProcessDefinition.DeveloperName,
                    LastActorId,
                    (SELECT Id, ActorId FROM WorkItems)
                FROM ProcessInstance 
                WHERE TargetObjectId IN: approvedOrderIds
            ]);

            Set<Id> ordersWithPendingApproval = new Set<Id>();

            for (ProcessInstance currProcessInstance: checkProcessInstances.values()) {
                System.debug('Pedido: ' + currProcessInstance.TargetObjectId);
                System.debug(currProcessInstance.WorkItems.size());

                Id orderId = currProcessInstance.TargetObjectId;
                String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;
                String lastApproval = newMap.get(orderId).UltimaAprovacao__c;

                if (currProcessInstance.WorkItems.size() > 0) {
                    for (ProcessInstanceWorkItem currWorkItem : currProcessInstance.WorkItems) {
                        if (currWorkItem.ActorId != UserInfo.getUserId()) {
                            ordersWithPendingApproval.add(orderId);
                        }
                    }
                }
            }

            List<Order> ordersToUpdate = new List<Order>();

            for (Order currOrder : newMap.values()) {
                Order orderToUpdate = new Order(Id = currOrder.Id);
                
                orderToUpdate.UltimaAprovacao__c = null;

                if (rejectedOrderIds.contains(currOrder.Id)) {
                    system.debug('entrou aqui 2');
                    orderToUpdate.Status = 'Reprovado';
                } else {
                    if (!ordersWithPendingApproval.contains(currOrder.Id)) {
                        orderToUpdate.Status = 'Aprovado';
                        orderToUpdate.AprovadoComercial__c                 = true;
                        orderToUpdate.AprovadoMalha__c                     = true;
                        orderToUpdate.AprovadoPricing__c                   = true;
                        orderToUpdate.AprovadoRegionalizacao__c            = true;
                        orderToUpdate.AprovadoBonificacao__c               = true;
                        orderToUpdate.NecessitaAprovacaoComercial__c       = false;
                        orderToUpdate.NecessitaAprovacaoMalha__c           = false;
                        orderToUpdate.NecessitaAprovacaoPricing__c         = false;
                        orderToUpdate.NecessitaAprovacaoRegionalizacao__c  = false;
                        orderToUpdate.NecessitaAprovacaoBonificacao__c     = false;
                        orderToUpdate.solicitacaoAprovada__c               = true;
                        orderToUpdate.RejeicaoProcesso__c                  = false;
                    } else {
                        orderToUpdate.SolicitacaoAprovada__c = false;
                        hasPending = true;
                    }
                }

                ordersToUpdate.add(orderToUpdate);
            }
            
            OrderHandler.disableTrigger();
            update ordersToUpdate;
            OrderHandler.enableTrigger();
        }

        if (!setOrderId.isEmpty() && !hasPending) {
            Set<Id> setSonOrderId = new Set<Id>();
            for (Order ord: [SELECT Id, PedidoPai__c FROM Order WHERE PedidoPai__c IN: setOrderId]) {
                if (!rejectedOrderIds.contains(ord.PedidoPai__c)) {
                    setSonOrderId.add(ord.Id);
                }
            }
            if (!setSonOrderId.isEmpty()) {
                if (setSonOrderId.size() < 50){
                    System.enqueueJob(new IntegrationApprovalOrderQueueable(0, new List<Id>(setSonOrderId)));
                } else {
                    BatchSendApprovalOrder.run(setSonOrderId);
                }
            }
        }
    }

    public static void recallApprovalProcess(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Set<Id> setRecallOrderId = new Set<Id>();
        for (Id ordId : oldMap.keySet()) {
            Order ord = newMap.get(ordId);
            if (!oldMap.get(ordId).RecallProcesso__c && ord.RecallProcesso__c) {
                setRecallOrderId.add(ordId);

                // ord.RecallProcesso__c = false;
                ord.Status            = 'Em digitação';
            }
        }
        System.debug('setRecallOrderId: ' + setRecallOrderId);
        System.debug('newMap.values(): ' + newMap.values());

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        
        if (!setRecallOrderId.isEmpty()) {
            Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE (TargetObjectId IN :setRecallOrderId)]);

            List<ProcessInstanceWorkItem> processInstanceWkItemList = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending'];
            for(ProcessInstanceWorkItem workItem : processInstanceWkItemList){
                System.debug('workItem: ' + workItem);
                // if there's a work item, set the action to 'removed' and execute
                System.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (!setRecallOrderId.isEmpty()) {
                    if (setRecallOrderId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                        req.setAction('Removed');
                    }
                }
                req.setWorkitemId(workItem.Id);
                requests.add(req);
            }

            Approval.ProcessResult[] processResults;
            if (!requests.isEmpty()) {
                processResults = Approval.process(requests, true);
            }
        }
    }

    public static void fillOrderCode(Order[] newRecords) {

        Set<Id> ordIdSet = new Set<Id>();
        for (Order ord : newRecords) {
            ordIdSet.add(ord.Id);
        }
        if (!ordIdSet.isEmpty()) {
            List<Order> ordList = new List<Order>();
            for (Order o : [SELECT Id, OrderNumber, CodigoPedido__c FROM Order WHERE Id IN :ordIdSet]) {
                o.CodigoPedido__c = o.OrderNumber;
                ordList.add(o);
            }
            if (!ordList.isEmpty()) {
                OrderHandler.disableTrigger();
                update ordList;
                OrderHandler.enableTrigger();
            }
        }
    }

    public static void removeSendApproval(Map<Id, Order> oldMap, Map<Id, Order> newMap) {

        List<Order> ordList = new List<Order>();
        for (Order orderUpdt :[SELECT id, AprovadoComercial__c, EnviarAprovacao__c, Status, AprovadoPricing__c, NecessitaAprovacaoPricing__c, Dataaprovacao__c, NecessitaAprovacaoComercial__c, AprovadoMalha__c, AprovadoRegionalizacao__c, NecessitaAprovacaoMalha__c, NecessitaAprovacaoRegionalizacao__c, AprovadoBonificacao__c, NecessitaAprovacaoBonificacao__c FROM Order WHERE ID IN :newMap.keySet()]) {
            Order o = newMap.get(orderUpdt.id);
            Order oldOrder = oldMap.get(o.id);
            if (!oldOrder.EnviarAprovacao__c && o.EnviarAprovacao__c) {
                if ( (orderUpdt.AprovadoComercial__c && !orderUpdt.NecessitaAprovacaoPricing__c) || 
                    (orderUpdt.AprovadoPricing__c && !orderUpdt.NecessitaAprovacaoComercial__c) || 
                    (orderUpdt.AprovadoMalha__c && !orderUpdt.NecessitaAprovacaoMalha__c) || 
                    (orderUpdt.AprovadoRegionalizacao__c && !orderUpdt.NecessitaAprovacaoRegionalizacao__c) || 
                    (orderUpdt.AprovadoBonificacao__c && !orderUpdt.NecessitaAprovacaoBonificacao__c) || 
                    (orderUpdt.AprovadoComercial__c && orderUpdt.AprovadoPricing__c && orderUpdt.AprovadoMalha__c && orderUpdt.AprovadoRegionalizacao__c && orderUpdt.AprovadoBonificacao__c)) {
                    orderUpdt.Status = 'Aprovado';
                    orderUpdt.Dataaprovacao__c = datetime.now();
                } else if (orderUpdt.Status != 'Aguardando processamento na integradora') {
                    orderUpdt.Status = 'Aguardando aprovação';
                }
                orderUpdt.EnviarAprovacao__c = false;
                ordList.add(orderUpdt);
            }
            if (!oldOrder.SolicitacaoAprovada__C && o.SolicitacaoAprovada__C) {
                orderUpdt.SolicitacaoAprovada__C = false;
                ordList.add(orderUpdt);
            }
            if (!oldOrder.RejeicaoProcesso__c && o.RejeicaoProcesso__c) {
                orderUpdt.RejeicaoProcesso__c = false;
                ordList.add(orderUpdt);
            }
            if (!oldOrder.RecallProcesso__c && o.RecallProcesso__c) {
                orderUpdt.RecallProcesso__c = false;
                ordList.add(orderUpdt);
            }
        }
        
        if (!ordList.isEmpty()) {
            OrderHandler.disableTrigger();
            update ordList;
            OrderHandler.enableTrigger();
        }
    }
    public static void checkStatusOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        List<Order> ordList = new List<Order>();
        Set<String> nonUpdateStatusSet = new Set<String>{'Aguardando integração', 'ErroIntegracao', 'Bloqueado ERP', 'Liberado ERP', 'Aguardando separação', 'Separado', 'Faturado', 'Cancelado', 'Aguardando envio de cancelamento'};
        for(Order ord : [SELECT id, Status, PedidoPai__r.Status, PedidoPai__c, ExternalId__c FROM Order WHERE PedidoPai__c IN :newMap.keySet()]){
            if(ord.PedidoPai__r.Status == 'Aguardando aprovação' && !nonUpdateStatusSet.contains(ord.Status)){
                if(newMap.get(ord.PedidoPai__c).Status == 'Aguardando aprovação' ){
                    ord.Status = 'Pai - Em aprovação';
                }
            }else if(ord.PedidoPai__r.Status == 'Aprovado' && !nonUpdateStatusSet.contains(ord.Status)){
                ord.Status = 'Pai - Aprovado';
            }
            ordList.add(ord);
        }
        if(!ordList.isEmpty()){
            OrderHandler.disableTrigger();
            update ordList;
            OrderHandler.enableTrigger();
        }

    }

    public static void checkStatusUpdate(List<Order> newRecordList, List<Order> oldRecordList) {
        Map<Id, Order> mapOrder = new Map<Id, Order>();

        for (Order order : oldRecordList) {
            if (order.Status != 'Em digitação' || order.StatusIntegracao__c == 'Integrado') {
                mapOrder.put(order.Id, order);
            }
        }

        for (Order order : newRecordList) {
            if (mapOrder.containsKey(order.Id)) {
                order.addError('Só é possível atualizar pedidos no status "Em digitação" ou status de integração "Integrado"');
            }
        }
    }

    public static void checkBilledStatus(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Map<Id, Order> ordMapToUpdate = new Map<Id, Order>();
        Set<String> statusToUpdate  = new Set<String>{'Faturado'};

        for (Order ord : newMap.values()) {
            if (ord.RecordTypeId != MOTHERORDER_RECORDTYPE && statusToUpdate.contains(ord.Status) && ord.PedidoPai__c != null) {
                ordMapToUpdate.put(ord.PedidoPai__c, new Order(Id = ord.PedidoPai__c, PedidoFilhoFaturado__c = true));
            }
        }
        if (!ordMapToUpdate.isEmpty()) {
            OrderHandler.disableTrigger();
            update ordMapToUpdate.values();
            OrderHandler.enableTrigger();
        }
    }

    public static void updateOrderStatusIntegration(Map<Id, Order> oldMap, List<Order> newRecordList) {

        List<Order> notificationOrdList = new List<Order>();
        Set<String> integradoraStatus   = new Set<String>{'Aguardando processamento na integradora', 'Aprovado na integradora', 'Rejeitado na integradora', 'Bloqueado por divergência de preços'};
        Set<String> errorIntegration    = new Set<String>{'Não integrado', 'Erro integração (Envio ao Protheus)', 'Erro integração (geração do pedido no Protheus)'};
        Set<String> reservedIntegration = new Set<String>{'Pedido em aberto', 'Pedido com SC', 'Pedido aguardando saldo'};
        Set<String> waitingIntegration  = new Set<String>{'Pedido aguardando separação', 'Pedido em separação'};
        Set<String> billedIntegration   = new Set<String>{'Pedido faturado', 'Pedido com resíduo eliminado (com faturamento)'};
        Set<String> canceledIntegration = new Set<String>{'Pedido cancelado', 'Pedido com resíduo eliminado (sem faturamento)', 'Pedido rejeitado na alçada financeira', 'Pedido rejeitado na alçada de aprovação de pagamento RA'};
        String waitingApproval          = 'Pedido aguardando aprovação de pagamento RA';
        String waitingProof             = 'Pedido aguardando envio/processamento do comprovante de pagamento RA';
        String blockedIntegration       = 'bloqueado';
        String erpIntegration           = 'Pedido liberado';
        String separateIntegration      = 'Pedido separado/aguardando faturamento';
        Map<Id, Boolean> ordIdToLabMap  = new Map<Id, Boolean>();
        for (OrderItem oi : [SELECT Id, OrderId, Laboratorio__c FROM OrderItem WHERE OrderId IN :oldMap.keySet()]) {
            if (!ordIdToLabMap.containsKey(oi.OrderId)) {
                if (oi.Laboratorio__c != null) {
                    ordIdToLabMap.put(oi.OrderId, true);
                } else {
                    ordIdToLabMap.put(oi.OrderId, false);
                }
            } else {
                if (!ordIdToLabMap.get(oi.OrderId) && oi.Laboratorio__c != null) {
                    ordIdToLabMap.put(oi.OrderId, true);
                }
            }
        }
        for (Order o : newRecordList) {
            Order oldOrd = oldMap.get(o.Id);
            if (o.RecordTypeId != MOTHERORDER_RECORDTYPE) {
                if (oldOrd.StatusIntegracao__c != o.StatusIntegracao__c && integradoraStatus.contains(o.StatusIntegracao__c)) {
                    o.Status = o.StatusIntegracao__c;
                }
                if ((errorIntegration.contains(o.StatusIntegracao__c)) && o.Status != 'Cancelado' && o.Status != 'Aguardando envio de cancelamento') { // Aprovado na integradora - coloquei para não mudar
                    o.Status = 'ErroIntegracao';
                } else if (o.ExternalId__c == null && o.Status != 'Cancelado' && o.Status != 'Aguardando envio de cancelamento' && o.Status != 'Aprovado na integradora') {
                    system.debug('Trocou para aguardando integração');
                    o.Status = 'Aguardando integração';
                } else if (o.Status != 'Cancelado' && o.Status != 'Aguardando envio de cancelamento') {
                    clearErrorMessages(o);
    
                    if (reservedIntegration.contains(o.StatusIntegracao__c)) {
                        if (o.PedidoPaiStatus__c == 'Aguardando aprovação') {
                            o.Status = 'Pai - Em aprovação';
                        } else if (o.PedidoPaiStatus__c == 'Aprovado') {
                            o.Status = 'Pai - Aprovado';
                        } else if (o.ExternalId__c != null) {
                            if (ordIdToLabMap.get(o.Id)) {
                                o.Status = 'Aguardando processamento na integradora';
                            } else {
                                o.Status = 'Pai - Em aprovação';
                            }
                        }
                    } else if (o.StatusIntegracao__c != null && o.StatusIntegracao__c.contains(waitingProof)) {
                        o.Status = 'Aguardando comprovante';
                    } else if (o.StatusIntegracao__c != null && o.StatusIntegracao__c.contains(waitingApproval)) {
                        o.Status = 'Aguardando aprovação RA';
                    } else if (o.StatusIntegracao__c != null && o.StatusIntegracao__c.contains(blockedIntegration)) {
                        o.Status = 'Bloqueado ERP';
                    } else if (o.StatusIntegracao__c != null && o.StatusIntegracao__c.contains(erpIntegration)) {
                        o.Status = 'Liberado ERP';
                    } else if (waitingIntegration.contains(o.StatusIntegracao__c)) {
                        o.Status = 'Aguardando separação';
                    } else if (o.StatusIntegracao__c != null && o.StatusIntegracao__c.contains(separateIntegration)) {
                        o.Status = 'Separado';
                    } else if (billedIntegration.contains(o.StatusIntegracao__c)) {
                        o.Status = 'Faturado';
                    } else if (canceledIntegration.contains(o.StatusIntegracao__c)) {
                        o.Status = 'Cancelado';
                        clearErrors(o);
                        clearErrorMessages(o);
                    }
                } else if (o.Status == 'Aguardando envio de cancelamento') {
                    if (canceledIntegration.contains(o.StatusIntegracao__c)) {
                        o.Status = 'Cancelado';
                        clearErrors(o);
                        clearErrorMessages(o);
                    } else if (billedIntegration.contains(o.StatusIntegracao__c)) {
                        o.Status = 'Faturado';
                        notificationOrdList.add(o);
                    }
                } else if (o.Status == 'Cancelado' && canceledIntegration.contains(o.StatusIntegracao__c)) {
                    clearErrors(o);
                    clearErrorMessages(o);
                }
            }
        }
        // SEND ALL NOTIFICATIONS
        if (!notificationOrdList.isEmpty()) {
            sendMessageNotification(notificationOrdList);
            sendChatterNotification(notificationOrdList);
            sendEmailMessage(notificationOrdList);
        }
    }

    public static void updateCancelledLaboratoryOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        List<PedidoIntegradora__c> laboratoryOrderList = new List<PedidoIntegradora__c>();
        Set<String> labParentOrderSet                  = new Set<String>();
        Set<String> labOrderSet                        = new Set<String>();
        Set<String> labParentCancelOrderSet            = new Set<String>();
        Set<String> labCancelOrderSet                  = new Set<String>();
        Set<String> labParentGeneratedOrderSet         = new Set<String>();
        Set<String> labGeneratedOrderSet               = new Set<String>();

        for (Order o : newMap.values()) {
            Order oldOrd = oldMap.get(o.Id);
            if (oldOrd.StatusIntegracao__c != o.StatusIntegracao__c && o.StatusIntegracao__c == 'Pedido cancelado') {
                labParentOrderSet.add(o.PedidoPai__c);
            } else if (oldOrd.StatusIntegracao__c != o.StatusIntegracao__c && o.StatusIntegracao__c == 'Rejeitado na integradora') {
                labParentCancelOrderSet.add(o.PedidoPai__c);
            } else if (oldOrd.StatusIntegracao__c != o.StatusIntegracao__c && (o.StatusIntegracao__c == 'Pedido liberado' || o.StatusIntegracao__c == 'Pedido aguardando separação' || o.StatusIntegracao__c == 'Pedido em separação')) {
                // labParentGeneratedOrderSet.add(o.PedidoPai__c);                                                                                     
                labParentGeneratedOrderSet.add(o.Id);
            }
        }
        if (!labParentOrderSet.isEmpty()) {
            for (Order ord : [SELECT Id, CodigoIntegradora__c FROM Order WHERE Id IN :labParentOrderSet AND CodigoIntegradora__c != null]) {
                labOrderSet.add(ord.CodigoIntegradora__c); 
            }
            if (!labOrderSet.isEmpty()) {
                for (PedidoIntegradora__c labOrder : [SELECT Id, CodigoIntegradora__c, Status__c FROM PedidoIntegradora__c WHERE CodigoIntegradora__c IN :labOrderSet]) {
                    labOrder.Status__c = 'Cancelado';
                    laboratoryOrderList.add(labOrder);
                }
            }
        }
        if (!labParentCancelOrderSet.isEmpty()) {
            for (Order ord : [SELECT Id, CodigoIntegradora__c FROM Order WHERE Id IN :labParentOrderSet AND CodigoIntegradora__c != null]) {
                labCancelOrderSet.add(ord.CodigoIntegradora__c); 
            }
            if (!labCancelOrderSet.isEmpty()) {
                for (PedidoIntegradora__c labOrder : [SELECT Id, CodigoIntegradora__c, Status__c FROM PedidoIntegradora__c WHERE CodigoIntegradora__c IN :labCancelOrderSet]) {
                    labOrder.Status__c = 'Aguardando envio de cancelamento';
                    laboratoryOrderList.add(labOrder);
                }
            }
        }
        if (!labParentGeneratedOrderSet.isEmpty()) {
            // for (Order ord : [SELECT Id, CodigoIntegradora__c FROM Order WHERE Id IN :labParentOrderSet AND CodigoIntegradora__c != null]) {
            for (Order ord : [SELECT Id, CodigoIntegradora__c FROM Order WHERE Id IN :labParentGeneratedOrderSet AND CodigoIntegradora__c != null]) {
                labGeneratedOrderSet.add(ord.CodigoIntegradora__c); 
            }
            if (!labGeneratedOrderSet.isEmpty()) {
                for (PedidoIntegradora__c labOrder : [SELECT Id, CodigoIntegradora__c, Status__c FROM PedidoIntegradora__c WHERE Pedido__c IN: labParentGeneratedOrderSet AND CodigoIntegradora__c IN :labGeneratedOrderSet]) {
                    labOrder.Status__c = 'Pedido gerado';
                    laboratoryOrderList.add(labOrder);
                }
            }
        }
        if (!laboratoryOrderList.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            update laboratoryOrderList;
            PedidoIntegradoraHandler.enableTrigger();
        }
    }

    public static void updateLaboratoryChildOrders(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        List<Order> laboratoryOrderList = new List<Order>();
        Set<String> labOrderSet         = new Set<String>();

        for (Order o : newMap.values()) {
            Order oldOrd = oldMap.get(o.Id);
            if (o.RecordTypeId == MOTHERORDER_RECORDTYPE && oldOrd.Status != o.Status && o.Status == 'Em Aprovação') {
                labOrderSet.add(o.Id);
            }
        }
        if (!labOrderSet.isEmpty()) {
            for (Order labOrder : [SELECT Id, CodigoIntegradora__c, Status FROM Order WHERE PedidoPai__c IN :labOrderSet]) {
                labOrder.Status = 'Pai - Em aprovação';
                laboratoryOrderList.add(labOrder);
            }
        }
        if (!laboratoryOrderList.isEmpty()) {
            update laboratoryOrderList;
        }
    }

    public static void createManualLaboratoryOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap, Order[] newRecords) {
        List<PedidoIntegradora__c> laboratoryOrderList = new List<PedidoIntegradora__c>();   
        Map<Id, String> ordIdToLabMap                  = new Map<Id, String>();
        Map<Id, String> ordIdToTpIntMap                = new Map<Id, String>();
        for (OrderItem oi : [SELECT Id, Laboratorio__c, OrderId/*, TipoIntegradora__c*/ FROM OrderItem WHERE OrderId IN :newMap.keySet()]) {
            if (oi.Laboratorio__c != null) {
                ordIdToLabMap.put(oi.OrderId, oi.Laboratorio__c);
                // ordIdToTpIntMap.put(oi.OrderId, oi.TipoIntegradora__c);
            }
        }

        Set<Id> setOrderId = new Set<Id>();
        for (Order o : newMap.values()) {
            Order oldOrd = oldMap.get(o.Id);
            if (o.CodigoIntegradora__c != null && oldOrd.StatusIntegracao__c != o.StatusIntegracao__c &&
                (o.StatusIntegracao__c == 'Aprovado na integradora') ) {
                laboratoryOrderList.add(new PedidoIntegradora__c(
                    RecordTypeId         = Schema.SObjectType.PedidoIntegradora__c.getRecordTypeInfosByDeveloperName().get('PedidoFluxoManual').getRecordTypeId(),
                    Pedido__c            = o.Id,
                    Laboratorio__c       = ordIdToLabMap.containsKey(o.Id) ? ordIdToLabMap.get(o.Id) : null,
                    Cliente__c           = o.AccountId,
                    CodigoIntegradora__c = o.CodigoIntegradora__c,
                    // TipoIntegradora__c   = ordIdToTpIntMap.containsKey(o.Id) ? ordIdToTpIntMap.get(o.Id) : null,
                    Status__c            = 'Aprovado na integradora'
                ));
                setOrderId.add(o.Id);
            } else if (o.CodigoIntegradora__c != null && oldOrd.StatusIntegracao__c != o.StatusIntegracao__c &&
                        (o.StatusIntegracao__c == 'Rejeitado na integradora' || o.StatusIntegracao__c == 'Bloqueado por divergência de preços') ) {
                laboratoryOrderList.add(new PedidoIntegradora__c(
                    RecordTypeId         = Schema.SObjectType.PedidoIntegradora__c.getRecordTypeInfosByDeveloperName().get('PedidoFluxoManual').getRecordTypeId(),
                    Pedido__c            = o.Id,
                    Laboratorio__c       = ordIdToLabMap.containsKey(o.Id) ? ordIdToLabMap.get(o.Id) : null,
                    Cliente__c           = o.AccountId,
                    CodigoIntegradora__c = o.CodigoIntegradora__c,
                    // TipoIntegradora__c   = ordIdToTpIntMap.containsKey(o.Id) ? ordIdToTpIntMap.get(o.Id) : null,
                    Status__c            = 'Aguardando envio de cancelamento'
                ));
                setOrderId.add(o.Id);
            }
        }

        for (Order ord : newRecords) {
            if (setOrderId.contains(ord.Id)) {
                ord.PossuiPedIntegradora__c = true;
            }
        }

        if (!laboratoryOrderList.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            upsert laboratoryOrderList CodigoIntegradora__c;
            PedidoIntegradoraHandler.enableTrigger();
        }
    }

    public static void updateParentLabOrder(Map<Id, Order> oldMap, Map<Id, Order> newMap) {
        Set<String> labOrderSet                        = new Set<String>();
        Id ordId                                       = null;
        Map<String, String> parentIdMap                = new Map<String, String>();
        Map<String, boolean> PedidoIntegra             = new Map<String, boolean>();
        Map<String, String> PedidoIntegraStatus        = new Map<String, String>();
        List<PedidoIntegradora__c> laboratoryOrderList = new List<PedidoIntegradora__c>();        
        for (Order o : newMap.values()) {
            Order oldOrd = oldMap.get(o.Id);
            system.debug('o.CodigoIntegradora__c ' + o.CodigoIntegradora__c);
            system.debug('oldOrd.StatusIntegracao__c ' + oldOrd.StatusIntegracao__c);
            system.debug('o.StatusIntegracao__c '+ o.StatusIntegracao__c);
            system.debug('o.StatusIntegracao__c ' + o.StatusIntegracao__c);
            if (o.CodigoIntegradora__c != null && o.PedidoPai__c != null && oldOrd.StatusIntegracao__c != o.StatusIntegracao__c && 
                (o.StatusIntegracao__c == 'Aprovado na integradora' || o.StatusIntegracao__c == 'Rejeitado na integradora' || o.StatusIntegracao__c == 'Pedido liberado') ) {
                labOrderSet.add(o.CodigoIntegradora__c);                                         
                parentIdMap.put(o.Id, o.PedidoPai__c);
            }
        }
        Boolean shouldSend = false;
        system.debug('labOrderSet: ' + labOrderSet);
        if (!labOrderSet.isEmpty()) {
            for (PedidoIntegradora__c labOrder : [SELECT Id, CodigoIntegradora__c, Status__c, Pedido__c, Pedido__r.PedidoPai__c, Pedido__r.StatusIntegracao__c FROM PedidoIntegradora__c WHERE CodigoIntegradora__c IN :labOrderSet AND CodigoIntegradora__c != null]) {
                if (labOrder.Status__c == 'Aprovado na integradora') {
                    shouldSend = true;
                    ordId = labOrder.Pedido__c;
                } else if (labOrder.Status__c == 'Aguardando processamento na integradora') {
                    if (ordId == labOrder.Pedido__c) {
                        shouldSend = false;
                        ordId = null;
                    }
                }
                if (labOrder.Pedido__r.PedidoPai__c != null && labOrder.Pedido__r.StatusIntegracao__c == 'Pedido liberado') {
                    labOrder.Status__c = 'Pedido gerado';
                    laboratoryOrderList.add(labOrder);
                }
            }
        }
        Id parentOrdId = parentIdMap.get(ordId);
        Boolean allOrdersAnswered = true;
        // if (parentOrdId != null) {
            // for (Order ord : [SELECT Id, StatusIntegracao__c FROM Order WHERE PedidoPai__c =: parentOrdId]) {
            for (Order ord : [SELECT Id, StatusIntegracao__c, PedidoPai__c FROM Order WHERE PedidoPai__c =: parentIdMap.values() and Laboratorio__c != null]) {
                system.debug(!(ord.StatusIntegracao__c == 'Aprovado na integradora' || ord.StatusIntegracao__c == 'Rejeitado na integradora' || ord.StatusIntegracao__c == 'Bloqueado por divergência de preços'));
                if (!(ord.StatusIntegracao__c == 'Aprovado na integradora' || ord.StatusIntegracao__c == 'Rejeitado na integradora' || ord.StatusIntegracao__c == 'Bloqueado por divergência de preços')) {
                    PedidoIntegra.put(ord.PedidoPai__c,false);
                }else{
                    if(!PedidoIntegra.containsKey(ord.PedidoPai__c)){
                        PedidoIntegra.put(ord.PedidoPai__c,true);
                        PedidoIntegraStatus.put(ord.PedidoPai__c,ord.StatusIntegracao__c );
                    }
                }
            }
        // }
        system.debug('PedidoIntegra ' + PedidoIntegra);
        list<Order> lpedido = new list<Order>();
        for (Order ord : [SELECT Id, Status, EnviarAprovacao__c FROM Order WHERE Id = :parentIdMap.values() AND PedidoPai__c = null]) {
            if(PedidoIntegra.containsKey(ord.Id) && PedidoIntegra.get(ord.Id)){
                if(PedidoIntegraStatus.get(ord.Id) ==  'Aprovado na integradora'  ) {
                    ord.Status = 'Aguardando aprovação';
                    ord.EnviarAprovacao__c = true;
                    lpedido.add(ord);
                }else{
                    system.debug('entrou aqui');
                    ord.Status = 'Reprovado';
                    lpedido.add(ord);
                }
            }
        }
        if(!lpedido.isEmpty()) update lpedido;

        // if (ordId != null && shouldSend && allOrdersAnswered) {
        //     Order contextOrd = new Order();
        //     system.debug('parentOrdId: ' + parentOrdId);
        //     for (Order ord : [SELECT Id, Status, EnviarAprovacao__c FROM Order WHERE Id = :parentOrdId AND PedidoPai__c = null]) {
        //         contextOrd = ord;
        //         contextOrd.Status = 'Aguardando aprovação';
        //         contextOrd.EnviarAprovacao__c = true;
        //     }
        //     if (contextOrd != null) {
        //         update contextOrd;
        //     }
        // }

        system.debug(laboratoryOrderList);
        if (!laboratoryOrderList.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            update laboratoryOrderList;
            PedidoIntegradoraHandler.enableTrigger();
        }
    }

    public static void updateLabOrderStatusWhenParentOrderWasApproved(Map<Id, Order> mapIdToOldOrder, Map<Id, Order> mapIdToNewOrder) {
        Set<String> codigoIntegradoraSet = new Set<String>();
        List<PedidoIntegradora__c> pedidoIntegradoraToUpdateList = new List<PedidoIntegradora__c>();
        
        for(Order iOrder : mapIdToNewOrder.values()) {
            Order oldOrder = mapIdToOldOrder.get(iOrder.Id);
            Order newOrder = mapIdToNewOrder.get(iOrder.Id);
            if(hasSObjectField('UltimaAprovacao__c', newOrder)) {
                System.debug(JSON.serialize(oldOrder));
                System.debug(JSON.serialize(newOrder));
                if(oldOrder.Status == 'Aguardando aprovação' && newOrder.CodigoIntegradora__c != null && newOrder.SolicitacaoAprovada__c && newOrder.UltimaAprovacao__c.contains('Pedido_Aprovacao')) {
                    codigoIntegradoraSet.add(newOrder.CodigoIntegradora__c);
                }
            }
        }

        for (PedidoIntegradora__c iPedidoIntegradora : [
            SELECT Id, CodigoIntegradora__c, Status__c, Pedido__c, Pedido__r.PedidoPai__c, Pedido__r.StatusIntegracao__c 
            FROM PedidoIntegradora__c 
            WHERE CodigoIntegradora__c 
            IN :codigoIntegradoraSet 
            AND CodigoIntegradora__c != null]) {
            if(iPedidoIntegradora.Status__c == 'Aguardando aprovação comercial') {
                iPedidoIntegradora.Status__c = 'Aprovado comercial';
                pedidoIntegradoraToUpdateList.add(iPedidoIntegradora);
            }
        }

        if (!pedidoIntegradoraToUpdateList.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            update pedidoIntegradoraToUpdateList;
            PedidoIntegradoraHandler.enableTrigger();
        }
    }
    
    public static boolean hasSObjectField(String fieldName, SObject so){
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
    }

    public static void clearErrors(Order ord){
        ord.ErroIntegracaoCancelamento__c         = false;
        ord.ErroIntegracaoAprovacao__c            = false;
        ord.ErroIntegracaoConfirmacao__c          = false;
        ord.ErroIntegracaoRejeitado__c            = false;
    }

    public static void clearErrorMessages(Order ord){
        ord.MensagemErroIntegracao__c             = null;
        ord.MensagemErroIntegracaoAprovacao__c    = null;
        ord.MensagemErroIntegracaoCancelamento__c = null;
        ord.MensagemErroIntegracaoConfirmacao__c  = null;
        ord.MensagemErroIntegracaoRejeitado__c    = null;
    }

    public static void sendMessageNotification(List<Order> scope) {
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NotificationNotAbleToCancel'];
        
        for (Order order : scope) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();

            notification.setTitle(System.Label.UnableToCancelOrderTitle);
            notification.setBody(System.Label.UnableToCancelOrder);

            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(order.Id);

            try {
                Set<String> recipientsIds = new Set<String>();
                recipientsIds.add(order.CreatedById);
                notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug(System.Label.NotificationOrderError + e.getMessage());
            }
        }
    }

    public static void sendChatterNotification(List<Order> scope) {
        List<FeedItem> postList = new List<FeedItem>();

        FeedItem post = new FeedItem();
        for (Order order : scope) {
            post.ParentId = order.AccountId;
            post.Body     = 'O pedido ' + order.OrderNumber + ' não pode ser cancelado pois já foi faturado no ERP.';
            postList.add(post);
        }

        if (!postList.isEmpty()) {
            insert postList;
        }
    }

    public static void sendEmailMessage(List<Order> scope) {

        Map<Id, String> idToOrdNameMap = new Map<Id, String>();
        for (Order ord : scope) {
            idToOrdNameMap.put(ord.Id, ord.OrderNumber);
        }
        List<Id> ordIdList = Collection.of(scope).pluckIds();
        Map<Id, Id> ordIdToCancelUserMap = new Map<Id, Id>();
        for (OrderHistory ordHistory : [SELECT Id, OrderId, CreatedById, Field, OldValue, NewValue FROM OrderHistory WHERE OrderId IN :ordIdList]) {
            if (ordHistory.Field == 'Status' && ordHistory.NewValue == 'Aguardando envio de cancelamento') {
                ordIdToCancelUserMap.put(ordHistory.OrderId, ordHistory.CreatedById);
            }
        }
        Map<Id, User> idToUserMap = new Map<Id, User>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        if (!ordIdToCancelUserMap.isEmpty()) {
            for (User us : [SELECT Id, Name, Email FROM User WHERE Id IN :ordIdToCancelUserMap.values()]) {
                idToUserMap.put(us.Id, us);
            }
    
            Messaging.reserveSingleEmailCapacity(10);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
            Id templateEmailId;
            for (EmailTemplate template : [SELECT Id, Name, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'EmailUnableToCancelOrder' LIMIT 1]) {
                templateEmailId = template.Id;
            }
    
            for (Id ordId : ordIdToCancelUserMap.keySet()) {
                User us;
                if (idToUserMap.containsKey(ordIdToCancelUserMap.get(ordId))) {
                    us = idToUserMap.get(ordIdToCancelUserMap.get(ordId));
    
                    List<String> toAddresses = new List<String> {us.Email};
                    mail.setToAddresses(toAddresses);
            
                    mail.setTemplateId(templateEmailId);
                    mail.setTargetObjectId(us.Id);
                    mail.setSaveAsActivity(false);
                    mail.setSubject('Alerta de pedido não cancelado');
                    mail.setHtmlBody('Olá ' + us.Name + '.<br/><br/>O pedido ' + idToOrdNameMap.get(ordId) + ' não pode ser cancelado pois já foi faturado no ERP.');
                    emailList.add(mail);
                }
            }
        }

        if (!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
            System.debug(results);
        }
    }
    
    public static void sendCancelledOrderEmail(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        
        List<Order> listCancelledOrders = new List<Order>();
        for (Order ord : newMap.values()){
            Order oldOrder = oldMap.get(ord.Id);

            if (
                (ord.ExternalId__c == null && 
                oldOrder.MotivoCancelamento__c != ord.MotivoCancelamento__c) ||
                (ord.ExternalId__c != null && 
                (ord.StatusIntegracao__c == 'Pedido cancelado' || 
                ord.StatusIntegracao__c == 'Pedido com resíduo eliminado (sem faturamento)' || 
                ord.StatusIntegracao__c == 'Pedido rejeitado na alçada financeira' || 
                ord.StatusIntegracao__c == 'Pedido rejeitado na alçada de aprovação de pagamento RA'))
                ){
                listCancelledOrders.add(ord);                
            }
        }
        System.debug(listCancelledOrders);
        if(!listCancelledOrders.isEmpty()){
            SendEmailMessage.sendEmailMessageCancelledOrder(listCancelledOrders);
        }
    }

    public static void fillProtheusCode(Map<Id, Order> oldMap, Map<Id, Order> newMap){

        for (Order o : newMap.values()) {
            Order oldOrder = oldMap.get(o.id);  
            if (o.PedidoProtheusResumido__c == null && o.ExternalId__c != null) {
               o.PedidoProtheusResumido__c = o.ExternalId__c.trim().length() > 5 ? o.ExternalId__c.trim().substring(5, o.ExternalId__c.length()) : o.ExternalId__c.trim();
            }
        }
    }

    public static void cancelRelatedNF(Order[] newRecordList) {
        Set<Id> setOrdId = new Set<Id>();
        for (Order ord : newRecordList) {
            if (ord.StatusIntegracao__c == 'Nota fiscal cancelada') {
                ord.Status = 'Separado';
                setOrdId.add(ord.Id);
            }
        }

        Map<Id, NotasFiscais__c> mapNfIdToNF = new Map<Id, NotasFiscais__c>();
        List<NotasFiscais__c> listNfToUpdate = new List<NotasFiscais__c>();

        for (NotasFiscais__c nf : [SELECT Id, Pedido__c, Status__c FROM NotasFiscais__c WHERE Pedido__c IN: setOrdId AND Status__c != 'Cancelado' ORDER BY CreatedDate ASC]) {
            nf.Status__c = 'Cancelado';
            if (!mapNfIdToNF.containsKey(nf.Pedido__c)) {
                listNfToUpdate.add(nf);
            }
            mapNfIdToNF.put(nf.Pedido__c, nf);
        }

        if (!listNfToUpdate.isEmpty()) {
            update listNfToUpdate;
        }
    }

        
    public static void dispatchOrderCountEvent(Map<Id, Order> newMap){
        dispatchOrderCountEvent(new Map<Id, Order>(),  newMap);
    }

    public static void dispatchOrderCountEvent(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        Map<String, OrderCount__e> orderCountMap = new Map<String, OrderCount__e>();
        Map<String, List<Order>> newOrdersByOppMap = (Map<String, List<Order>>)SObjectUtils.mapObjectsByField(newMap.values(), 'OpportunityId', true);
        Map<String, List<String>> userIdsByOppMap = new Map<String, List<String>>();

        for(List<OpportunityTeamMember> oppTMList : [SELECT OpportunityId, UserId FROM OpportunityTeamMember WHERE OpportunityId IN :newOrdersByOppMap.keySet()]){
            for(OpportunityTeamMember teamMember : oppTMList){

                if(userIdsByOppMap.get(teamMember.OpportunityId) == null){
                    userIdsByOppMap.put(teamMember.OpportunityId, new List<String>());
                }
                userIdsByOppMap.get(teamMember.OpportunityId).add(teamMember.UserId);
            }
        }

        for(Order newOrd : newMap.values()){
            Order oldOrd = oldMap.get(newOrd.Id);
  
            if(newOrdersByOppMap.get(newOrd.OpportunityId) == null || userIdsByOppMap.get(newOrd.OpportunityId) == null){
                continue;
            }
            
            String owners = String.join(userIdsByOppMap.get(newOrd.OpportunityId),';');
            //insert com status 'Em digitação' ou mudança de status outro => 'Em digitação'
            if((oldOrd == null || oldOrd.Status != 'Em digitação') && newOrd.Status == 'Em digitação'){
                if(orderCountMap.get(owners) == null){
                    orderCountMap.put(owners, new OrderCount__e(User__c = owners,OrderQuant__c = 0));
                }

                orderCountMap.get(owners).OrderQuant__c++;
            }
            //mudança de status 'Em digitação' => outro
            if(oldOrd != null && oldOrd.Status == 'Em digitação' && newOrd.Status != 'Em digitação'){
                if(orderCountMap.get(owners) == null){
                    orderCountMap.put(owners, new OrderCount__e(User__c = owners,OrderQuant__c = 0));
                }

                orderCountMap.get(owners).OrderQuant__c--;
            }

        }
        //despacha evento para ser capturado na budgetTab.js
        if(!orderCountMap.isEmpty()) EventBus.publish(orderCountMap.values());

    }
    
    // public static void enviaNoticacaoCartaTrocaAprovacao(List<Order> lstOrder){

    //     Messaging.CustomNotification notification = new Messaging.CustomNotification();
    //     CustomNotificationType notificationType = [SELECT
    //                                                     Id,
    //                                                     DeveloperName
    //                                                 FROM
    //                                                     CustomNotificationType
    //                                                 WHERE
    //                                                     DeveloperName = 'NotificacaoCartaTroca'];

    //     for (Order o : lstOrder) {

    //         Set<String> recipientsIds = new Set<String>{o.OwnerId};
           
    //         notification.setTitle('Carta de Troca '+o.StatusCartaTroca__c);

    //         if (o.StatusCartaTroca__c == 'Reprovada') {

    //             notification.setBody('Motivo '+o.MotivoRejeicaoCartaTroca__c);                
    //         }
            
    //         notification.setNotificationTypeId(notificationType.Id);
    //         notification.setTargetId(o.id);

    //         try {
    //             notification.send(recipientsIds);
    //         }
    //         catch (Exception e) {
    //             ExceptionUtils.debug(e);
    //         }
               
    //     }
    // }

    // public static void atualizaStatusPedidoPai(Map<Id, Order> oldMap, Map<Id, Order> newMap){

    //     Boolean isAprovado = false;
    //     Boolean isReporvado = false;
    //     List<Order> lstOrderPai = new List<Order>();
    //     Order orderPai = new Order();
    //     Map<String, List<Order>> mapOrderPaixFilhos = new Map<String, List<Order>>();
    //     Map<String, Boolean> mapOrderFilhosxAprovadoRejeitado = new Map<String, Boolean>();
    //     Set<String> setIdsFilho  = new Set<String> ();
    //     Set<String> setStatus  = new Set<String> ();

    //     for (Order o : newMap.values()) {

    //         Order oldOrder = oldMap.get(o.id);  

    //         if (o.StatusCartaTroca__c != null && o.StatusCartaTroca__c != oldOrder.StatusCartaTroca__c && o.PedidoFilho__c) {

    //             setIdsFilho.add(o.Id);

    //             if (mapOrderPaixFilhos.containsKey(o.PedidoPai__c)) {
                    
    //                 mapOrderPaixFilhos.get(o.PedidoPai__c).add(o);

    //             } else {

    //                  mapOrderPaixFilhos.put(o.PedidoPai__c, new List<Order>{o});                     
    //             }
               
    //         }
    //     }

    //     if (mapOrderPaixFilhos.size() > 0 ) {

    //         List<Order> lstFilhos = [SELECT id, StatusCartaTroca__c, OwnerId, MotivoRejeicaoCartaTroca__c From Order where PedidoPai__c IN: mapOrderPaixFilhos.keySet() AND Id NOT IN:setIdsFilho];

    //         if(lstFilhos.size() > 0 ){

    //             for(Order filho : lstFilhos){

    //                 if (mapOrderPaixFilhos.containsKey(filho.PedidoPai__c)) {
                        
    //                     mapOrderPaixFilhos.get(o.PedidoPai__c).add(filho);
    //                 }                    

    //             }

    //             for (String ids : mapOrderPaixFilhos) {
                    
    //                 setStatus  = new Set<String> ();

    //                 for(Order orderpai : mapOrderPaixFilhos.get(ids)){
                    
    //                     setStatus.add(orderPai.StatusCartaTroca__c);
    //                 } 
                    
    //                 if(setStatus.size() == 1){

    //                     orderPai = new Order();
    //                     orderPai.Id = orderPai;
    //                     orderPai.StatusCartaTroca__c =  (new list<string>(setStatus) )[0];
    //                     lstOrderPai.add(orderPai);
    //                 }                
    //             }   
                
    //             if(lstOrderPai.size() > 0){

    //                 update lstOrderPai;

    //                 // enviaNoticacaoCartaTrocaAprovacao(lstOrderPai);
                    
    //             }            
    //         }
    //     }
    // }
}