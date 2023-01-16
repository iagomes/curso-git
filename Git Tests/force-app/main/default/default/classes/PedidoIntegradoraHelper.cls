public without sharing class PedidoIntegradoraHelper {

    public static void checkLabOrder(PedidoIntegradora__c[] newRecords) {
        Map<Id, Boolean> mapOrdIdToBoolean = new Map<Id, Boolean>();
        for (PedidoIntegradora__c pedInt : newRecords) {            
            mapOrdIdToBoolean.put(pedInt.Pedido__c, true);
        }
        
        List<Order> listOrdToUpdate = new List<Order>();
        if (!mapOrdIdToBoolean.keySet().isEmpty()) {
            for (Order ord : [SELECT Id, PossuiPedIntegradora__c FROM Order WHERE Id IN: mapOrdIdToBoolean.keySet()]) {
                if (mapOrdIdToBoolean.get(ord.Id) && !ord.PossuiPedIntegradora__c) {
                    ord.PossuiPedIntegradora__c = mapOrdIdToBoolean.get(ord.Id);
                    listOrdToUpdate.add(ord);
                }
            }
        }

        if (!listOrdToUpdate.isEmpty()) {
            OrderHandler.disableTrigger();
            update listOrdToUpdate;
            OrderHandler.enableTrigger();
        }
    }

    public static void automaticPedidoIntegradoraApproval(Map<Id, PedidoIntegradora__c> oldMap, Map<Id, PedidoIntegradora__c> newMap) {

        Set<Id> setApprovedPedidoIntegradoraId = new Set<Id>();
        Set<Id> setRejectedPedidoIntegradoraId = new Set<Id>();
        for (Id ordId : oldMap.keySet()) {
            system.debug('oldMap.get(ordId).SolicitacaoAprovada__c: ' + oldMap.get(ordId).SolicitacaoAprovada__c);
            system.debug('newMap.get(ordId).SolicitacaoAprovada__c: ' + newMap.get(ordId).SolicitacaoAprovada__c);
            system.debug('oldMap.get(ordId).RejeicaoProcesso__c: ' + oldMap.get(ordId).RejeicaoProcesso__c);
            system.debug('newMap.get(ordId).RejeicaoProcesso__c: ' + newMap.get(ordId).RejeicaoProcesso__c);
            if (oldMap.get(ordId).SolicitacaoAprovada__c != newMap.get(ordId).SolicitacaoAprovada__c) {
                setApprovedPedidoIntegradoraId.add(ordId);
            } else if (oldMap.get(ordId).RejeicaoProcesso__c != newMap.get(ordId).RejeicaoProcesso__c) {
                setRejectedPedidoIntegradoraId.add(ordId);
            }
        }

        if (!setApprovedPedidoIntegradoraId.isEmpty() || !setRejectedPedidoIntegradoraId.isEmpty()) {    
            system.debug('setApprovedPedidoIntegradoraId: ' + setApprovedPedidoIntegradoraId);
            system.debug('setRejectedPedidoIntegradoraId: ' + setRejectedPedidoIntegradoraId);
    
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
    
            Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE (TargetObjectId IN: setApprovedPedidoIntegradoraId OR TargetObjectId IN: setRejectedPedidoIntegradoraId)]);
    
            for(ProcessInstanceWorkItem workItem : [SELECT Id, ProcessInstanceId, ActorId FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending' AND ActorId != :UserInfo.getUserId()]){
                system.debug('workItem: ' + workItem);
                system.debug('ActorId: ' + workItem.ActorId);
                system.debug('UserInfo.getUserId()' + UserInfo.getUserId());
                // if there's a work item, set the action to 'removed' and execute
                system.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (!setApprovedPedidoIntegradoraId.isEmpty()) {
                    if (setApprovedPedidoIntegradoraId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                        req.setAction('Approve');
                    }
                }
                if (!setRejectedPedidoIntegradoraId.isEmpty()) {
                    if (setRejectedPedidoIntegradoraId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                        req.setAction('Reject');
                    }
                }
                req.setWorkitemId(workItem.Id);
                requests.add(req);
            }
    
            system.debug('requests: ' + requests);
    
            Approval.ProcessResult[] processResults;
            if (!requests.isEmpty()) {
                processResults = Approval.process(requests, true);
            }
    
            Set<Id> hasApprovalPendingSet = new Set<Id>();
            List<ProcessInstanceWorkItem> allProcessInstanceWkItemList = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending' AND ActorId != :UserInfo.getUserId()];
            System.debug('allProcessInstanceWkItemList: ' + allProcessInstanceWkItemList);
            List<ProcessInstanceWorkItem> thisUserProcInstList = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending' AND ActorId = :UserInfo.getUserId()];   
            for (ProcessInstanceWorkItem wkItem : allProcessInstanceWkItemList) {
                hasApprovalPendingSet.add(wkItem.ProcessInstance.TargetObjectId);
            }
            System.debug('hasApprovalPendingSet: ' + hasApprovalPendingSet);
            Set<Id> setPedidoIntegradoraId = new Set<Id>();
            for (PedidoIntegradora__c lab : newMap.values()) {
                if ((!oldMap.get(lab.Id).SolicitacaoAprovada__c && lab.SolicitacaoAprovada__c) ||
                    (!oldMap.get(lab.Id).RejeicaoProcesso__c    && lab.RejeicaoProcesso__c)) {
                    setPedidoIntegradoraId.add(lab.Id);
                }
            }
    
            List<PedidoIntegradora__c> listToUpdate = new List<PedidoIntegradora__c>();
            Set<Id> labOrderIdSetToERP = new Set<Id>();
            for (PedidoIntegradora__c lab: [SELECT Id, StatusAprovacao__c, Status__c, SolicitacaoAprovada__c, RejeicaoProcesso__c, AprovadoParcial__c FROM PedidoIntegradora__c WHERE Id IN: setPedidoIntegradoraId]) {
                if(setRejectedPedidoIntegradoraId.contains(lab.Id)){
                    lab.StatusAprovacao__c = 'Reprovado';
                    lab.Status__c = 'Reprovado';
                } else if(setApprovedPedidoIntegradoraId.contains(lab.Id)){
                    lab.StatusAprovacao__c = 'Aprovado';
                }
                lab.RejeicaoProcesso__c = false;
                lab.SolicitacaoAprovada__c = false;
    
                if (!lab.AprovadoParcial__c) {
                    listToUpdate.add(lab);
                    labOrderIdSetToERP.add(lab.Id);
                }
                
            }
    
            if (!listToUpdate.isEmpty()) {
                PedidoIntegradoraHandler.disableTrigger();
                update listToUpdate;
                PedidoIntegradoraHandler.enableTrigger();
                if (!labOrderIdSetToERP.isEmpty()) {
                    System.enqueueJob(new IntegrationLaboratoryOrderQueueable(0, new List<Id>(labOrderIdSetToERP), 'N'));
                }
            }
            
        }

        // for (Id labId : newMap.keySet()) {
        //     PedidoIntegradora__c lab = newMap.get(labId);
        //     if ((!oldMap.get(labId).SolicitacaoAprovada__c && lab.SolicitacaoAprovada__c) ||
        //         (!oldMap.get(labId).RejeicaoProcesso__c    && lab.RejeicaoProcesso__c)) {
        //         if(setRejectedPedidoIntegradoraId.contains(labId)){
        //             lab.StatusAprovacao__c = 'Reprovado';
        //         } else if(setApprovedPedidoIntegradoraId.contains(labId)){
        //             lab.StatusAprovacao__c = 'Aprovado';
        //         }
        //         lab.SolicitacaoAprovada__c = false; 
        //         lab.RejeicaoProcesso__c = false; 
        //     }
        // }
    }

    public static void fillInconsistencyOrder(Map<Id, PedidoIntegradora__c> oldMap, Map<Id, PedidoIntegradora__c> newMap) {      

        Map<Id, String> orderIdToInconsistencyMap = new Map<Id, String>();
        List<Order> orderToUpdateList = new List<Order>();
        for (PedidoIntegradora__c labOrder : newMap.values()) {
            if (labOrder.Pedido__c != null) {
                orderIdToInconsistencyMap.put(labOrder.Pedido__c, labOrder.Inconsistencias__c);
            }
        }
        for (Order o : [SELECT Id, Inconsistencias__c FROM Order WHERE Id IN :orderIdToInconsistencyMap.keySet()]) {
            orderToUpdateList.add(new Order(Id = o.Id, Inconsistencias__c = orderIdToInconsistencyMap.get(o.Id)));
        }
        if (!orderToUpdateList.isEmpty()) {
            OrderHandler.disableTrigger();
            update orderToUpdateList;
            OrderHandler.enableTrigger();
        }
    }

    public static void cleanApprovalStatus(Map<Id, PedidoIntegradora__c> oldMap, Map<Id, PedidoIntegradora__c> newMap) {      

        for (PedidoIntegradora__c labOrder : newMap.values()) {
            PedidoIntegradora__c oldLabOrder = oldMap.get(labOrder.Id);
            if (oldLabOrder.Status__c != labOrder.Status__c && labOrder.Status__c == 'Aguardando análise') {
                labOrder.StatusAprovacao__c = null;
            }
        }
    }
    
    @InvocableMethod(label='Approve or reject laboratory order this user' description='Method to approve or reject laboratory order this user')
    public static List<String> ApproveRejectLaboratoryOrderThisUser(List<FlowInputs> flowInputs){
        Id labId          = null;
        Boolean isApprove = true;
        for (FlowInputs flowInput : flowInputs) {
            labId     = flowInput.labId;
            isApprove = flowInput.isApprove;
        }
        Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId = :labId]);
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        for(ProcessInstanceWorkItem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ActorId = :UserInfo.getUserId() AND ProcessInstance.Status = 'Pending']){
            system.debug('workItem: ' + workItem);
            // if there's a work item, set the action to 'removed' and execute
            system.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            if (isApprove) {
                req.setAction('Approve');
            } else {
                req.setAction('Reject');
            }
            req.setWorkitemId(workItem.Id);
            requests.add(req);
        }

        system.debug('requests: ' + requests);

        Approval.ProcessResult[] processResults;
        if (!requests.isEmpty()) {
            processResults = Approval.process(requests, true);
        }

        return null;
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String labId;
        
        @InvocableVariable
        public Boolean isApprove;
    }

}