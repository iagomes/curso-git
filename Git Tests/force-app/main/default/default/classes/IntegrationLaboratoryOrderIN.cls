@RestResource(urlMapping='/upsertLabOrder/*')
global without sharing class IntegrationLaboratoryOrderIN {
    @HttpPost
    global static ResponseModelOrder upsertLabOrder(List<TemplateDataIntegrationFields.LabOrderINData> Pedidos) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Order> listOrderToUpsert = new List<Order>();
        List<PedidoIntegradora__c> listPedidoIntegradora = new List<PedidoIntegradora__c>();
        Map<String, List<TemplateDataIntegrationFields.ItensINData>> mapItens = new Map<String, List<TemplateDataIntegrationFields.ItensINData>>();
        Map<String, List<TemplateDataIntegrationFields.LabSonOrderINData>> mapLabSonOrder = new Map<String, List<TemplateDataIntegrationFields.LabSonOrderINData>>();
        Map<String, List<TemplateDataIntegrationFields.LabSonOrderItemINData>> mapLabSonOrderItem = new Map<String, List<TemplateDataIntegrationFields.LabSonOrderItemINData>>();

        Map<String, String> mapOrdKeyToPricebookKey = new Map<String, String>();
        Map<String, String> mapCampToRule = new Map<String, String>();
        Set<String> setAccountKey = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();
        Set<String> setPaymentConditionKey = new Set<String>();

        system.debug('Pedidos: ');
        system.debug(Pedidos);
        system.debug(JSON.serialize(Pedidos));

        Map<String, TemplateDataIntegrationFields.ApprovalINData> mapOrderToApproval = new Map<String, TemplateDataIntegrationFields.ApprovalINData>();

        for (TemplateDataIntegrationFields.LabOrderINData ord : Pedidos) {            
            // 20 => bonificação - PedidoBonificacao
            // 01 => venda - PedidoVenda
            // 09 e 30 => contaeordem - PedidoContaOrdem
            mapOrdKeyToPricebookKey.put(ord.PedidoIntegrador?.trim(), ord.Tabela?.trim());
            setAccountKey.add(ord.CgcCli?.trim());
            setPricebookKey.add(ord.Tabela?.trim());
            setPaymentConditionKey.add(ord.CondicaoPagamento?.trim());
            String tipoOperacao = '';
            if (ord.Itens != null) {
                if (ord.Aprovacoes != null) {
                    mapOrderToApproval.put(ord.PedidoIntegrador, ord.Aprovacoes);
                }
                for (TemplateDataIntegrationFields.ItensINData itens : ord.Itens) {
                    itens.TpOper    = itens.TpOper == '20' ? 'PedidoBonificacao' : itens.TpOper == '01' ? 'PedidoVenda' : (itens.TpOper == '09' || itens.TpOper == '30') ? 'PedidoContaOrdem' : itens.TpOper;
                    tipoOperacao    = itens.TpOper;
                    itens.PedidoPai = ord.PedidoIntegrador;
                    itens.Tabela    = ord.Tabela;
                    itens.CondPag   = ord.CondicaoPagamento?.trim();
                    if (!mapItens.containsKey(ord.PedidoIntegrador)) {
                        mapItens.put(ord.PedidoIntegrador, new List<TemplateDataIntegrationFields.ItensINData>{itens});
                    } else {
                        mapItens.get(ord.PedidoIntegrador).add(itens);
                    }
                }
            }
            if (ord.Inconsistencias == null) {
                PedidoIntegradora__c pedInt = new PedidoIntegradora__c();
                pedInt.CodigoIntegradora__c = ord.PedidoIntegrador;
                pedInt.CNPJCliente__c     = ord.CgcCli;
                pedInt.TipoIntegradora__c = ord.TpInteg;
                pedInt.Laboratorio__c = ord.Laboratorio;
                pedInt.Inconsistencias__c = ord.Inconsistencias;
                pedInt.RecordTypeId       = Schema.SObjectType.PedidoIntegradora__c.getRecordTypeInfosByDeveloperName().get('PedidoFluxoAutomatico').getRecordTypeId();
                pedInt.StatusAprovacao__c = 'Aprovado';

                listPedidoIntegradora.add(pedInt);
                if (ord.Filhos != null) {
                    for (TemplateDataIntegrationFields.LabSonOrderINData labSonOrder : ord.Filhos) {
                        labSonOrder.PedidoPai = ord.PedidoIntegrador;
                        labSonOrder.Tabela = ord.Tabela;
                        labSonOrder.CgcCli = ord.CgcCli;
                        labSonOrder.TpOper = tipoOperacao;
                        if (!mapLabSonOrder.containsKey(labSonOrder.PedidoIntegrador)) {
                            mapLabSonOrder.put(labSonOrder.PedidoIntegrador, new List<TemplateDataIntegrationFields.LabSonOrderINData>{labSonOrder});
                        } else {
                            mapLabSonOrder.get(labSonOrder.PedidoIntegrador).add(labSonOrder);
                        }
                        if (labSonOrder.Itens != null) {
                            for (TemplateDataIntegrationFields.LabSonOrderItemINData labSonOrderItem : labSonOrder.Itens) {
                                labSonOrderItem.PedidoFilho = labSonOrder.Pedido;
                                labSonOrderItem.PedidoPai   = labSonOrder.PedidoPai;
                                labSonOrderItem.Tabela      = labSonOrder.Tabela;
                                labSonOrderItem.Cnpj_CD     = labSonOrder.Cnpj_CD;
                                if (!mapLabSonOrderItem.containsKey(labSonOrder.Pedido)) {
                                    mapLabSonOrderItem.put(labSonOrder.Pedido + '_' + labSonOrder.PedidoIntegrador + '_' + labSonOrderItem.Produto, new List<TemplateDataIntegrationFields.LabSonOrderItemINData>{labSonOrderItem});
                                } else {
                                    mapLabSonOrderItem.get(labSonOrder.Pedido + '_' + labSonOrder.PedidoIntegrador + '_' + labSonOrderItem.Produto).add(labSonOrderItem);
                                }
                            }
                        }
                    }
                }
            } else {
                PedidoIntegradora__c pedInt = new PedidoIntegradora__c();
                pedInt.CodigoIntegradora__c = ord.PedidoIntegrador;
                pedInt.CNPJCliente__c     = ord.CgcCli;
                pedInt.TipoIntegradora__c = ord.TpInteg;
                pedInt.Laboratorio__c = ord.Laboratorio;
                pedInt.Inconsistencias__c = ord.Inconsistencias;
                pedInt.StatusAprovacao__c = null;
                pedInt.RecordTypeId       = Schema.SObjectType.PedidoIntegradora__c.getRecordTypeInfosByDeveloperName().get('PedidoFluxoAutomatico').getRecordTypeId();
                pedInt.Status__c          = ord.Inconsistencias != null ? 'Aguardando análise' : 'Aguardando aprovação comercial';
    
                listPedidoIntegradora.add(pedInt);
            }
        }

        Set<Id> setOrderFatherId = new Set<Id>();
        // Lookup para Pedido (Order)
        for (Order ord : [SELECT Id, Pricebook2.ExternalId__c, CodigoIntegradora__c FROM Order WHERE CodigoIntegradora__c IN: mapOrdKeyToPricebookKey.keySet()]) {
            if (ord.Pricebook2.ExternalId__c != mapOrdKeyToPricebookKey.get(ord.CodigoIntegradora__c)) {
                setOrderFatherId.add(ord.Id);
            }
        }

        system.debug(setOrderFatherId);
        if (!setOrderFatherId.isEmpty()) {
            delete [SELECT Id FROM OrderItem WHERE OrderId IN: setOrderFatherId];
        }

        Boolean hasAccount = false;
        // Lookup para Conta (Cliente)
        for(Account acc : [SELECT Id, ExternalId__c, CondicaoPagamento__c FROM Account WHERE ExternalId__c IN:setAccountKey]){
            lookups.put('Conta' + acc.ExternalId__c, acc.Id);
            lookups.put('CondicaoPagamentoCliente', acc.CondicaoPagamento__c);
            hasAccount = true;
        }
        
        if (!hasAccount) {
            Id PreAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PreConta').getRecordTypeId();
            List<Account> accToInsert = new List<Account>();
            for (String cnpj : setAccountKey) {
                Account acc = new Account(
                    Name = 'Pré cliente - ' + cnpj,
                    ExternalId__c = cnpj,
                    CNPJ__c = cnpj,
                    RecordTypeId = PreAccountRecTypeId
                );
                accToInsert.add(acc);
            }
            
            if (!accToInsert.isEmpty()) {
                insert accToInsert;
                for (Account acc : accToInsert) {
                    lookups.put('Conta' + acc.ExternalId__c, acc.Id);
                }
            }
        }

        // Lookup para Conta (Cliente)
        for(CondicaoPagamento__c acc : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE ExternalId__c IN:setPaymentConditionKey]){
            lookups.put('CondicaoPagamento' + acc.ExternalId__c, acc.Id);
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
        
        FactoryDataIntegration.convertSObject(new Order(), 'IN', Pedidos, responseList, listOrderToUpsert, lookups);

        system.debug(listOrderToUpsert);
		Boolean hasError = IntegrationUtils.upsertRecords(
            Database.upsert(listOrderToUpsert, Order.CodigoIntegradora__c, false), 
            responseList, 
            listOrderToUpsert, 
            Order.CodigoIntegradora__c
        );

        system.debug(listOrderToUpsert);
        Set<Id> ordIdSet = new Set<Id>();
        if(!hasError) {
            for (Order ord : listOrderToUpsert) {
                ordIdSet.add(ord.Id);
                for (PedidoIntegradora__c pedInt : listPedidoIntegradora) {
                    if (ord.CodigoIntegradora__c == pedInt.CodigoIntegradora__c) {
                        system.debug(ord.AccountId);
                        system.debug(ord.Id);
                        system.debug(pedInt.Inconsistencias__c);
                        pedInt.Cliente__c = ord.AccountId;
                        pedInt.Pedido__c = ord.Id;
                    }
                }
            }
        }

        List<TemplateDataIntegrationFields.Response> listPedIntegradoraResp = new List<TemplateDataIntegrationFields.Response>();
        Set<Id> pedidoIntegradoraIdSet = new Set<Id>();        
        system.debug(listPedidoIntegradora);
        if (!listPedidoIntegradora.isEmpty()) {
            Database.upsert(listPedidoIntegradora, PedidoIntegradora__c.CodigoIntegradora__c, true);
            system.debug('Pedidos integradores atualizados: ' + listPedidoIntegradora);
            
            for (PedidoIntegradora__c pInt : listPedidoIntegradora) {
                pedidoIntegradoraIdSet.add(pInt.Id);                
                TemplateDataIntegrationFields.Response pedIntegradoraResp = new TemplateDataIntegrationFields.Response();
                pedIntegradoraResp.status = true;
                pedIntegradoraResp.sObjectType = 'PedidoIntegradora__c';
                pedIntegradoraResp.idSalesforce = pInt.Id;
                pedIntegradoraResp.externalCode = pInt.CodigoIntegradora__c;
                pedIntegradoraResp.errorMessage = null;
                listPedIntegradoraResp.add(pedIntegradoraResp);
            }
        }
        
        system.debug(pedidoIntegradoraIdSet);

        system.debug(mapItens);
        if (!mapItens.keySet().isEmpty()) {
            system.debug('mapItens: ' + mapItens);
            system.debug('mapItens.KeySet(): ' + mapItens.keySet());
            system.debug('mapItens.values().size(): ' + mapItens.values().size());
            responseList.addAll(IntegrationLaboratoryOrderItemIN.upsertLabOrderItem(mapItens, lookups, mapCampToRule));
            for (String key : mapItens.keySet()) {
                for (TemplateDataIntegrationFields.ItensINData ordItem : mapItens.get(key)) {
                    system.debug(ordItem);
                    system.debug(ordItem.EntradaTabelaPreco);
                }
            }
        }
        System.debug('responseList 1 ==> ' + JSON.serialize(responseList));
        system.debug(mapLabSonOrder);
        if (!mapLabSonOrder.keySet().isEmpty()) {
            system.debug('mapLabSonOrder: ' + mapLabSonOrder);
            system.debug('mapLabSonOrder.values().size(): ' + mapLabSonOrder.values().size());
            responseList.addAll(IntegrationLabSonOrderIN.upsertLabSonOrder(mapLabSonOrder, lookups));
        }
        System.debug('responseList 2 ==> ' + JSON.serialize(responseList));
        system.debug(mapLabSonOrderItem);
        system.debug(mapCampToRule);
        if (!mapLabSonOrderItem.keySet().isEmpty()) {
            system.debug('mapLabSonOrderItem: ' + mapLabSonOrderItem);
            system.debug('mapLabSonOrderItem.values().size(): ' + mapLabSonOrderItem.values().size());
            responseList.addAll(IntegrationLabSonOrderItemIN.upsertLabSonOrderItem(mapLabSonOrderItem, lookups, mapCampToRule));
        }

        System.debug('responseList 3 ==> ' + JSON.serialize(responseList));

        Set<Id> setAccountId = new Set<Id>();

        Set<Id> allIdSet = new Set<Id>();
        for (TemplateDataIntegrationFields.Response resp : responseList) {
            allIdSet.add(resp.idSalesforce);
        }        

        Map<Id, Order> idToOrdMap = new Map<Id, Order>();
        for (Order ord : [SELECT Id, OrderNumber, AccountId, PedidoPai__c, CodigoIntegradora__c FROM Order WHERE Id IN :allIdSet]) {
            idToOrdMap.put(ord.Id, ord);
            setAccountId.add(ord.AccountId);
        }

        Map<String, Set<String>> mapRecTypeToCategories = new Map<String, Set<String>>();
        Map<String, Set<Id>> mapApprovalProcessToUserIdSet =  new Map<String, Set<Id>>();
        for (OrderItem oi : [SELECT Id, Product2.CategoriaComercial__c, OrderID FROM OrderItem WHERE OrderID IN: ordIdSet]) {
            String categoria = oi.Product2.CategoriaComercial__c == 'R' ? 'S' : oi.Product2.CategoriaComercial__c;
            if (!mapRecTypeToCategories.containsKey(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/)) {
                mapRecTypeToCategories.put(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
            } else {
                mapRecTypeToCategories.get(oi.OrderId + '----' + 'Pedido_AprovacaoComercial' /*+ categoria*/).add(categoria);
            }
        }

        mapApprovalProcessToUserIdSet = ApprovalProcessManagement.getApprovalUsers(setAccountId, mapRecTypeToCategories);

        system.debug('mapRecTypeToCategories: ' + mapRecTypeToCategories);
        system.debug('mapApprovalProcessToUserIdSet: ' + mapApprovalProcessToUserIdSet);

        system.debug(ordIdSet);
        system.debug(pedidoIntegradoraIdSet);
        Set<Id> objAlreadyInProcessSet = new Set<Id>();
        for (ProcessInstanceWorkitem process : [SELECT Id, Actor.Name, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN: ordIdSet OR ProcessInstance.TargetObjectId IN: pedidoIntegradoraIdSet]) {
            objAlreadyInProcessSet.add(process.ProcessInstance.TargetObjectId);
        }

        List<PedidoIntegradora__c> listPIntegradoraStatusUpdate = new List<PedidoIntegradora__c>();
        List<Approval.ProcessSubmitRequest> listToSendToApprovalProcess = new List<Approval.ProcessSubmitRequest>();
        system.debug('listPedidoIntegradora: ' + listPedidoIntegradora);

        Set<Id> setOrderIdToUpdate = new Set<Id>();

        for (PedidoIntegradora__c pedIntegradora : listPedidoIntegradora) {
            for (String chave : mapRecTypeToCategories.keySet()) {
                string [] arrChave = chave.split('----');
                for (String approvalRecType : mapApprovalProcessToUserIdSet.keySet()) {
                    system.debug('approvalRecType: ' + approvalRecType);
                    system.debug('arrChave[1]: ' + arrChave[1]);
                    system.debug('mapApprovalProcessToUserIdSet.get(approvalRecType): ' + mapApprovalProcessToUserIdSet.get(approvalRecType));
                    if (approvalRecType.contains(arrChave[1])) {
                        for (Id userId : mapApprovalProcessToUserIdSet.get(approvalRecType)) {
                            if (pedIntegradora.Inconsistencias__c != null && !objAlreadyInProcessSet.contains(pedIntegradora.Id)) {
                                listToSendToApprovalProcess.add(getProcessRequest(pedIntegradora.Id, userId, 'PedidoIntegradoraInconsistencias'));
                            } else if (pedIntegradora.Pedido__c != null && pedIntegradora.Inconsistencias__c == null && !objAlreadyInProcessSet.contains(pedIntegradora.Pedido__c)) {
                                listToSendToApprovalProcess.add(getProcessRequest(pedIntegradora.Pedido__c, userId, approvalRecType));
                                pedIntegradora.Status__c = 'Aguardando aprovação comercial';
                                setOrderIdToUpdate.add(pedIntegradora.Pedido__c);
                                if (!listPIntegradoraStatusUpdate.contains(pedIntegradora)) {
                                    listPIntegradoraStatusUpdate.add(pedIntegradora);
                                }
                            }
                        }
                    }
                }
            }
        }

        List<Order> listOrderToUpdate = new List<Order>();
        if (!setOrderIdToUpdate.isEmpty()) {
            for (Id ordId : setOrderIdToUpdate) {                
                listOrderToUpdate.add(new Order (
                    id = ordId,
                    EnviarAprovacao__c = true,
                    NecessitaAprovacaoComercial__c = true
                ));
            }
        }

        if (!listOrderToUpdate.isEmpty()) {            
            OrderHandler.disableTrigger();
            update listOrderToUpdate;
            OrderHandler.enableTrigger();
        }
        
        if (!listPedIntegradoraResp.isEmpty()) {
            responseList.addAll(listPedIntegradoraResp);
        }        

        for(TemplateDataIntegrationFields.Response res : responseList){
            if(res.status == false) hasError = true;
        }

        system.debug('listPIntegradoraStatusUpdate: ' + listPIntegradoraStatusUpdate);
        if (!listPIntegradoraStatusUpdate.isEmpty()) {
            PedidoIntegradoraHandler.disableTrigger();
            update listPIntegradoraStatusUpdate;
            PedidoIntegradoraHandler.enableTrigger();
        }

        system.debug(listToSendToApprovalProcess);
        
        if (!listToSendToApprovalProcess.isEmpty()) {
            for(Approval.ProcessSubmitRequest op : listToSendToApprovalProcess){
                system.debug('OBJETO '+op.getObjectId());
                system.debug('PROCESSO '+op.getProcessDefinitionNameOrId());
                system.debug('USUÁRIO '+op.getNextApproverIds());
            }
            // Submit the approval request for the Contract
            List<Approval.ProcessResult> listResult = Approval.process(listToSendToApprovalProcess);
            system.debug(listResult);
            updateOrderStatusApprovalProcess(listResult, listOrderToUpdate);
        }

        List<ResponseOrder> resOrderList = new List<ResponseOrder>();
        for (TemplateDataIntegrationFields.Response res : responseList) {
            ResponseOrder resOrder = new ResponseOrder(res);
            if (idToOrdMap.containsKey(res.idSalesforce)) {
                if (idToOrdMap.get(res.idSalesforce).PedidoPai__c != null) {
                    resOrder.orderNumber = idToOrdMap.get(res.idSalesforce).orderNumber;
                }
            }
            resOrderList.add(resOrder);
        }
        
        IntegrationUtils.WSLog('Laboratory Order', 'Inbound', JSON.serialize(Pedidos), JSON.serialize(resOrderList), hasError);
        
        ResponseModelOrder modelo = new ResponseModelOrder();
        modelo.response = resOrderList;
        return modelo;
    }

    public static void updateOrderStatusApprovalProcess(List<Approval.ProcessResult> listResultApprovalProcess, List<Order> orderList) {
        Set<Id> orderIdToUpdateSet = new Set<Id>();
        List<Order> orderToUpdateList = new List<Order>();

        for(Approval.ProcessResult iApprovalProcessResult : listResultApprovalProcess) {
            if(iApprovalProcessResult.isSuccess()) {
                orderIdToUpdateSet.add(iApprovalProcessResult.getEntityId());
            }
        }

        for(Order iOrder : orderList) {
            if(orderIdToUpdateSet.contains(iOrder.Id)) {
                iOrder.Status = 'Aguardando aprovação';
                orderToUpdateList.add(iOrder);
            }
        }

        if(!orderToUpdateList.isEmpty()) {
            OrderHandler.disableTrigger();
            update orderToUpdateList;
            OrderHandler.enableTrigger();
        }
    }

    public static Approval.ProcessSubmitRequest getProcessRequest(Id objId, Id userId, String process) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        system.debug('objId: ' + objId);
        system.debug('userId: ' + userId);
        system.debug('process: ' + process);
        req.setComments('Envio do pedido de integradora para aprovação');
        req.setObjectId(objId);
        req.setProcessDefinitionNameOrId(process);
        // req.setNextApproverIds(lUserId);
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }

    global class ResponseOrder {
        public String  idSalesforce;
        public String  externalCode;
        public String  errorMessage;
        public String  orderNumber;
        public Boolean status;
        public String  sObjectType;
        
        public ResponseOrder(TemplateDataIntegrationFields.Response res){
            this.idSalesforce = res.idSalesforce;
            this.externalCode = res.externalCode;
            this.errorMessage = res.errorMessage;
            this.status       = res.status;
            this.SObjectType  = res.sObjectType;
        }
    }

    global class ResponseModelOrder {
        List<ResponseOrder> response;
    }
}