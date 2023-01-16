public virtual without sharing class OpportunityBO {


    public static void uncheckApproval(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){
        if(AutomationsController.isRunning('OpportunityBO.uncheckApproval')){
            List<Opportunity> ordList = new List<Opportunity>();
            for (Opportunity oppUpdt : [SELECT id, AprovadoComercial__c, EnviarAprovacao__c, StageName, AprovadoPricing__c, NecessitaAprovacaoPricing__c, NecessitaAprovacaoComercial__c, AprovadoMalha__c, AprovadoRegionalizacao__c, NecessitaAprovacaoMalha__c, NecessitaAprovacaoRegionalizacao__c FROM Opportunity WHERE Id IN :newMap.keySet()]) {
                Opportunity o = newMap.get(oppUpdt.Id);
                Opportunity oldOpportunity = oldMap.get(o.Id);
                boolean approvedByComercial = !oppUpdt.NecessitaAprovacaoPricing__c && !oppUpdt.NecessitaAprovacaoMalha__c && !oppUpdt.NecessitaAprovacaoRegionalizacao__c;
                boolean approvedByPricing = !oppUpdt.NecessitaAprovacaoComercial__c && !oppUpdt.NecessitaAprovacaoMalha__c && !oppUpdt.NecessitaAprovacaoRegionalizacao__c;
                boolean approvedByMalha = !oppUpdt.NecessitaAprovacaoPricing__c && !oppUpdt.NecessitaAprovacaoComercial__c && !oppUpdt.NecessitaAprovacaoRegionalizacao__c;
                boolean approvedByRegionalizacao = !oppUpdt.NecessitaAprovacaoPricing__c && !oppUpdt.NecessitaAprovacaoMalha__c && !oppUpdt.NecessitaAprovacaoComercial__c;
                if (o.EnviarAprovacao__c && !oldOpportunity.EnviarAprovacao__c ){
                    if ( (oppUpdt.AprovadoComercial__c && approvedByComercial) ||  
                        (oppUpdt.AprovadoPricing__c && approvedByPricing) ||
                        (oppUpdt.AprovadoMalha__c && approvedByMalha) ||
                        (oppUpdt.AprovadoRegionalizacao__c && approvedByRegionalizacao) ||
                        (oppUpdt.AprovadoComercial__c && oppUpdt.AprovadoPricing__c && oppUpdt.AprovadoMalha__c && oppUpdt.AprovadoRegionalizacao__c)) {
                        oppUpdt.StageName = 'Aprovado';
                    } else {
                        oppUpdt.StageName = 'Aprovado';
                    }
                    oppUpdt.EnviarAprovacao__c = false;
                    ordList.add(oppUpdt);
                }
                
                if (!oldOpportunity.SolicitacaoAprovada__C && o.SolicitacaoAprovada__C) {
                    oppUpdt.SolicitacaoAprovada__C = false;
                    ordList.add(oppUpdt);
                }
                if (!oldOpportunity.RejeicaoProcesso__c && o.RejeicaoProcesso__c) {
                    oppUpdt.RejeicaoProcesso__c = false;
                    ordList.add(oppUpdt);
                }
                if (!oldOpportunity.RecallProcesso__c && o.RecallProcesso__c) {
                    oppUpdt.RecallProcesso__c = false;
                    ordList.add(oppUpdt);
                }
            }
            if(!ordList.isEmpty() && !Test.isRunningTest()){
                OpportunityTH.disableTrigger();
                update ordList;
                OpportunityTH.enableTrigger();
            }
        }
    }
    public static void validaAprovacao(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, List<Opportunity> newRecordList){
        if(AutomationsController.isRunning('OpportunityBO.validaAprovacao')){
            set<Id> setPedido = new set<Id>();
            Set<Id> setAccountId = new Set<Id>();
            for (Opportunity o : newRecordList) {
                Opportunity oldOpportunity = oldMap.get(o.Id);
                if (o.EnviarAprovacao__c && !oldOpportunity.EnviarAprovacao__c ){
                    system.debug('valida id ' + o.Id);
                    system.debug('valida id o.EnviarAprovacao__c ' + o.EnviarAprovacao__c);
                    setPedido.add(o.Id);
                    setAccountId.add(o.AccountId);
                }
            }
            map<String,String> mapGroup = new map<String,String>();
            map<Id,String> mapGroupId = new map<Id,String>();
            set<String> setGrop = new set<String>();
            list<Id> setUserId = new list<Id>();
            map<String,list<Id>> mapUserId =  new map<String,list<Id>>();
            Map<String, Set<Id>> mapApprovalProcessToUserIdSet =  new Map<String, Set<Id>>();
            Map<String, Set<String>> mapRecTypeToCategories = new Map<String, Set<String>>();
            if(!setPedido.isEmpty()){
                Map<String, ParametroScore__c> mapParm = ParametroScore__c.getAll();
                map<String,set<Id>> mapOpportunityId =  new map<String,set<Id>>();
                list<OpportunityLineItem> loi = new list<OpportunityLineItem>();
                loi = [SELECT Id, OpportunityId,  Opportunity.EnviarAprovacao__c , Opportunity.Score__c ,Opportunity.RecordTypeId, CampanhaShelfLife__c, CampanhaShelfLifeAux__c,
                                            Opportunity.AccountId, Opportunity.ClienteRecebedor__c, CNPJCD__c,ScoreBU__c, BloqueadoRegionalizacao__c,
                                            CentroDistribuicao__c, ServiceDate, Description, ForaMalha__c, Opportunity.NecessitaAprovacaoComercial__c, Opportunity.AprovadoPricing__c, Opportunity.AprovadoComercial__c, Opportunity.NecessitaAprovacaoPricing__c, //NumeroItemPedido__c,
                                            ItemCampanha__c, ListPrice, TotalPrice, UnitPrice, Product2Id, Product2.ProductCode, Product2.CategoriaComercial__c, Quantity, Vendedor__r.UserRole.ParentRoleId, ScoreItem__c
                                    FROM OpportunityLineItem WHERE OpportunityId = : setPedido ORDER BY OpportunityId , Product2.CategoriaComercial__c ];
                set<Id> setIdUser = new set<Id>();
    
                for(OpportunityLineItem oi : loi ){
                    String categoria = oi.Product2.CategoriaComercial__c == 'R' ? 'S' : oi.Product2.CategoriaComercial__c;
                    if(oi.Opportunity.Score__c == null){
                        oi.Opportunity.Score__c = 0;
                    }
                    if(oi.ScoreBU__c == null){
                        oi.ScoreBU__c = 0;
                    }
                    if (oi.Opportunity.Score__c < mapParm.get('A').Score__c) {
                        system.debug('oi.ScoreBU__c ' + oi.ScoreBU__c);
                        if (oi.ScoreBU__c <= mapParm.get('D').Score__c) {
                            system.debug('D');
                            if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoPricing' /*+ categoria*/)) {
                                mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoPricing' /*+ categoria*/, new Set<String>{categoria});
                            } else {
                                mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoPricing' /*+ categoria*/).add(categoria);
                            }
                        } else {
                            if (oi.ScoreBU__c <= mapParm.get('C').Score__c ) {
                                system.debug('C');
                                if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/)) {
                                    mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                                } else {
                                    mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/).add(categoria);
                                }
                            } else {
                                if (oi.ScoreBU__c <= mapParm.get('B').Score__c ) {
                                    system.debug('B');
                                    if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/)) {
                                        mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                                    } else {
                                        mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/).add(categoria);
                                    }
                                } else {
                                    if (oi.Opportunity.Score__c < mapParm.get('A').Score__c) {
                                        system.debug('A');
                                        if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/)) {
                                            mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                                        } else {
                                            mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/).add(categoria);
                                        }
                                    }
                                }
                                if (setIdUser == null) {
                                    setIdUser = new Set<Id>();
                                }
                                mapOpportunityId.put(oi.OpportunityId + '----C' ,setIdUser);
                            }
                        }
                    }
    
                    if (oi.BloqueadoRegionalizacao__c) {
                        if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoRegionalizacao' /*+ categoria*/)) {
                            mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoRegionalizacao' /*+ categoria*/, new Set<String>{categoria});
                        } else {
                            mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoRegionalizacao' /*+ categoria*/).add(categoria);
                        }
                    }
    
                    if (oi.ForaMalha__c) {
                        if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoMalha' /*+ categoria*/)) {
                            mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoMalha' /*+ categoria*/, new Set<String>{categoria});
                        } else {
                            mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoMalha' /*+ categoria*/).add(categoria);
                        }
                    }

                    if (oi.CampanhaShelfLifeAux__c && !oi.CampanhaShelfLife__c) {
                        if (!mapRecTypeToCategories.containsKey(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/)) {
                            mapRecTypeToCategories.put(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/, new Set<String>{categoria});
                        } else {
                            mapRecTypeToCategories.get(oi.OpportunityId + '----' + 'Oportunidade_AprovacaoComercial' /*+ categoria*/).add(categoria);
                        }
                    }
                }
                
                system.debug('setUserId: ' + setUserId);
    
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
    
                if(!lstAprovalRequest.isEmpty()){
                    list<Opportunity> lo = new list<Opportunity>();
                    for (Opportunity o : newRecordList) {
                        if (setPedido.contains(o.Id)){
                            Opportunity oNew = new Opportunity();
                            oNew.Id = o.Id;
                            oNew.NecessitaAprovacaoComercial__c      = mapRecTypeToCategories.containsKey(o.Id + '----Oportunidade_AprovacaoComercial');
                            oNew.NecessitaAprovacaoPricing__c        = mapRecTypeToCategories.containsKey(o.Id + '----Oportunidade_AprovacaoPricing');
                            oNew.NecessitaAprovacaoMalha__c          = mapRecTypeToCategories.containsKey(o.Id + '----Oportunidade_AprovacaoMalha');
                            oNew.NecessitaAprovacaoRegionalizacao__c = mapRecTypeToCategories.containsKey(o.Id + '----Oportunidade_AprovacaoRegionalizacao');
    
                            if (!oNew.NecessitaAprovacaoComercial__c && !oNew.NecessitaAprovacaoPricing__c && !oNew.NecessitaAprovacaoMalha__c && !oNew.NecessitaAprovacaoRegionalizacao__c) {
                                oNew.AprovadoComercial__c      = true;
                                oNew.AprovadoPricing__c        = true;
                                oNew.AprovadoRegionalizacao__c = true;
                                oNew.AprovadoMalha__c          = true;
                                oNew.solicitacaoAprovada__c    = true;
                                oNew.RejeicaoProcesso__c       = false;
                            }
                            lo.add(oNew);
                        }
                    }
                    OpportunityTH.disableTrigger();
                    system.debug('fazerDml ' + lo);
                    if(!lo.isEmpty()){
                        update (List<Opportunity>)JSON.deserialize(JSON.serialize(lo), List<Opportunity>.class);
                    }
                    system.debug('lo ' + lo);
                    for(Approval.ProcessSubmitRequest op : lstAprovalRequest){
                        system.debug('OBJETO'+op.getObjectId());
                        system.debug('PROCESSO'+op.getProcessDefinitionNameOrId());
                        system.debug('USUÁRIO '+op.getNextApproverIds());
                    }
                    List<Approval.ProcessResult> lstResult = Approval.process( lstAprovalRequest );
                    for (Opportunity o : newRecordList) {
                        if (setPedido.contains(o.Id)) {
                            if(!Approval.isLocked(o)){
                                system.debug('não bloqueia ' + o);
                                //o.AprovadoComercial__c = true;
                                //o.AprovadoPricing__c = true;
                            }
                        }
                    }
                    OpportunityTH.enableTrigger();
                }else{
                    List<Opportunity> lpedido = new list<Opportunity>();
    
                    for (Opportunity o : newRecordList) {
                        Opportunity oNew = new Opportunity();
                        if (setPedido.contains(o.Id)) {
                            oNew.Id = o.Id;
                            oNew.AprovadoComercial__c = true;
                            oNew.AprovadoPricing__c = true;
                            oNew.AprovadoMalha__c = true;
                            oNew.AprovadoRegionalizacao__c = true;
                            oNew.solicitacaoAprovada__c = true;
                            oNew.RejeicaoProcesso__c = false;
                            oNew.NecessitaAprovacaoComercial__c = false;
                            oNew.NecessitaAprovacaoPricing__c = false;
                            oNew.NecessitaAprovacaoMalha__c = false;
                            oNew.NecessitaAprovacaoRegionalizacao__c = false;
                            lpedido.add(oNew);
                        }
                    }
                    if(!lpedido.isEmpty()){
                        Update lpedido;
                    }
                }
            }
        }
    }
    
    public void checkDueDateUpdates(Map<Id, Opportunity> newRecordMap, Map<Id, Opportunity> oldRecordMap) {
        
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
        for (Opportunity newRecord : newRecordMap.values()) {
            if (newRecord.DataVencimento__c > oldRecordMap.get(newRecord.Id).DataVencimento__c && newRecord.RecordTypeId == recordTypeId) {
                newRecord.TabulacaoN1__c = '';
                newRecord.TabulacaoN2__c = '';
            }
        }
    }

    public static Approval.ProcessSubmitRequest getProcessRequest(Id OpportunityId, Id userId, String processoDef) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Envio automático do pedido');
        req.setObjectId(OpportunityId);
        req.setProcessDefinitionNameOrId(processoDef);
        // req.setNextApproverIds(lUserId);
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }

    public void preencherNomeOportunidade(List<Opportunity> lstOpportunity) {

        List<String> lstAccountId = new List<String>();

        for(Opportunity oppNew : lstOpportunity) {
            lstAccountId.add(oppNew.AccountId);
        }

        List<Opportunity> lstOpp = new List<Opportunity>();
        
        for(Opportunity oppNew : lstOpportunity) {
            string nome = oppNew.NumeroOrcamento__c;
            Opportunity opp = new Opportunity();
            opp.Id = oppNew.Id;
            if(nome.length() > 80){
                opp.Name = nome.substring(0, 80);
            }else{
                opp.Name = nome;
            }
            lstOpp.add(opp);
        }
        if(!lstOpp.isEmpty()){
            OpportunityTH.disableTrigger();
            update lstOpp;
            OpportunityTH.enableTrigger();
        }   

    }

    public static void automaticOpportunityApproval(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        if(AutomationsController.isRunning('OpportunityBO.automaticOpportunityApproval')){
            Set<Id> approvedOpportunityIds = new Set<Id>();
            Set<Id> rejectedOpportunityIds = new Set<Id>();
            
            Map<Id, Set<String>> mapOpportunityIdToPIDeveloperNames = new Map<Id, Set<String>>();
        
            for (Opportunity currOpportunity : newMap.values()) {
                if (
                    oldMap.get(currOpportunity.Id).SolicitacaoAprovada__c != currOpportunity.SolicitacaoAprovada__c &&
                    currOpportunity.SolicitacaoAprovada__c &&
                    currOpportunity.UltimaAprovacao__c != null
                ) { 
                    approvedOpportunityIds.add(currOpportunity.Id);
                    
                    if (!mapOpportunityIdToPIDeveloperNames.containsKey(currOpportunity.Id)) {
                        mapOpportunityIdToPIDeveloperNames.put(currOpportunity.Id, new Set<String>());
                    }
    
                    mapOpportunityIdToPIDeveloperNames
                        .get(currOpportunity.Id)
                        .add(currOpportunity.UltimaAprovacao__c);
                } else if (
                    oldMap.get(currOpportunity.Id).RejeicaoProcesso__c != currOpportunity.RejeicaoProcesso__c &&
                    currOpportunity.RejeicaoProcesso__c &&
                    currOpportunity.UltimaAprovacao__c != null
                ) {
                    rejectedOpportunityIds.add(currOpportunity.Id);
                }
            }
    
            if (!approvedOpportunityIds.isEmpty() || !rejectedOpportunityIds.isEmpty()) {
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
                    WHERE TargetObjectId IN: approvedOpportunityIds
                    OR TargetObjectId IN: rejectedOpportunityIds
                ]);
    
                for (ProcessInstance currProcessInstance : processInstancesMap.values()) {
                    Id opportunityId = currProcessInstance.TargetObjectId;
                    String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;
                    String lastApproval = newMap.get(opportunityId).UltimaAprovacao__c;
                    
                    for (ProcessInstanceWorkItem currWorkItem : currProcessInstance.WorkItems) {
                        if (
                            rejectedOpportunityIds.contains(opportunityId) &&
                            currWorkItem.ActorId == UserInfo.getUserId() &&
                            currDeveloperName != lastApproval
                        ) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Reject');
                            workItemsRequests.add(request);
                        } else if (
                            rejectedOpportunityIds.contains(opportunityId) &&
                            currWorkItem.ActorId != UserInfo.getUserId()
                        ) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Reject');
                            workItemsRequests.add(request);
                        }
    
                        // current user's pending work items
                        if (
                            !rejectedOpportunityIds.contains(opportunityId) &&
                            currWorkItem.ActorId == UserInfo.getUserId() &&
                            currDeveloperName != lastApproval
                        ) {
                            system.debug('Aprovado');
                            system.debug('currWorkItem.ActorId: ' + currWorkItem.ActorId);
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(currWorkItem.Id);
                            request.setAction('Approve');
                            workItemsRequests.add(request);
    
                            mapOpportunityIdToPIDeveloperNames
                                .get(opportunityId)
                                .add(currDeveloperName);
                        }
                    }
                }
    
                // rotina para adicionar workitems que deverão ser aprovados por developerName
                for (ProcessInstance currProcessInstance : processInstancesMap.values()) {
                    Id opportunityId = currProcessInstance.TargetObjectId;
                    String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;
    
                    if (!rejectedOpportunityIds.contains(opportunityId)) {
                        if (mapOpportunityIdToPIDeveloperNames.get(opportunityId).contains(currDeveloperName)) {
        
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
                    WHERE TargetObjectId IN: approvedOpportunityIds
                ]);
    
                Set<Id> opportunitiesWithPendingApproval = new Set<Id>();
    
                for (ProcessInstance currProcessInstance: checkProcessInstances.values()) {
                    System.debug('Pedido: ' + currProcessInstance.TargetObjectId);
                    System.debug(currProcessInstance.WorkItems.size());
    
                    Id opportunityId = currProcessInstance.TargetObjectId;
                    String currDeveloperName = currProcessInstance.ProcessDefinition.DeveloperName;
                    String lastApproval = newMap.get(opportunityId).UltimaAprovacao__c;

                    system.debug('currDeveloperName: ' + currDeveloperName);
                    system.debug('lastApproval: ' + lastApproval);
    
                    if (currProcessInstance.WorkItems.size() > 0) {
                        for (ProcessInstanceWorkItem currWorkItem : currProcessInstance.WorkItems) {
                            if (currWorkItem.ActorId != UserInfo.getUserId()) {
                                opportunitiesWithPendingApproval.add(opportunityId);
                            }
                        }
                    }
                }
    
                List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    
                for (Opportunity currOpportunity : newMap.values()) {
                    Opportunity opportunityToUpdate = new Opportunity(Id = currOpportunity.Id);
                    
                    opportunityToUpdate.UltimaAprovacao__c = null;
    
                    if (rejectedOpportunityIds.contains(currOpportunity.Id)) {
                        opportunityToUpdate.StageName = 'Reprovado';
                    } else {
                        if (!opportunitiesWithPendingApproval.contains(currOpportunity.Id)) {
                            opportunityToUpdate.StageName = 'Aprovado';
                            opportunityToUpdate.AprovadoComercial__c                 = true;
                            opportunityToUpdate.AprovadoMalha__c                     = true;
                            opportunityToUpdate.AprovadoPricing__c                   = true;
                            opportunityToUpdate.AprovadoRegionalizacao__c            = true;
                            opportunityToUpdate.NecessitaAprovacaoComercial__c       = false;
                            opportunityToUpdate.NecessitaAprovacaoMalha__c           = false;
                            opportunityToUpdate.NecessitaAprovacaoPricing__c         = false;
                            opportunityToUpdate.NecessitaAprovacaoRegionalizacao__c  = false;
                            opportunityToUpdate.solicitacaoAprovada__c               = true;
                            opportunityToUpdate.RejeicaoProcesso__c                  = false;
                        } else {
                            opportunityToUpdate.SolicitacaoAprovada__c = false;
                        }
                    }
    
                    opportunitiesToUpdate.add(opportunityToUpdate);
                }
                
                update opportunitiesToUpdate;
            }
        }
    }

    public void recallApprovalProcess(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        if(AutomationsController.isRunning('OpportunityBO.recallApprovalProcess')){
            Set<Id> setRecallOpportunityId = new Set<Id>();
            for (Id oppId : oldMap.keySet()) {
                Opportunity opp = newMap.get(oppId);
                if (!oldMap.get(oppId).RecallProcesso__c && opp.RecallProcesso__c) {
                    setRecallOpportunityId.add(oppId);
    
                    opp.RecallProcesso__c = false;
                    opp.StageName         = 'Em digitação';
                }
            }
            System.debug('setRecallOpportunityId: ' + setRecallOpportunityId);
            System.debug('newMap.values(): ' + newMap.values());
    
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
            
            Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE (TargetObjectId IN :setRecallOpportunityId)]);
    
            List<ProcessInstanceWorkItem> processInstanceWkItemList = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending'];
            for(ProcessInstanceWorkItem workItem : processInstanceWkItemList){
                System.debug('workItem: ' + workItem);
                // if there's a work item, set the action to 'removed' and execute
                System.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if (!setRecallOpportunityId.isEmpty()) {
                    if (setRecallOpportunityId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
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

    public static void deleteQuoteItems(Set<Id> oppIds){
        List<QuoteItem__c> items = [SELECT Id FROM QuoteItem__c WHERE OpportunityId__c IN: oppIds];
        delete items;
    }

    public void setStandardValues(Opportunity opp, Map<Id,Opportunity> oldMap){
        if(opp.Id == null && opp.StageName == null){
            opp.StageName = 'Novo';
        }
    }

    public void setFretePicklist(Opportunity opp, Map<Id,Opportunity> oldMap){
        if(SObjectUtils.hasChangedFields(opp, oldMap, 'FretePicklist__c')){
            opp.TipoFrete__c = opp.FretePicklist__c;
        } else if(SObjectUtils.hasChangedFields(opp, oldMap, 'TipoFrete__c')){
            opp.FretePicklist__c = opp.TipoFrete__c;
        }
    }

    public void setVendedorOnLookupChange(Map<Id,Opportunity> oldMap, List<Opportunity> newRecordList){
        Set<Id> idVendedores = new Set<Id>();
        Set<String> codigoVendedores = new Set<String>();
        for(Opportunity opp: newRecordList){
            if(opp.RepresentanteVDELookup__c != null){
                idVendedores.add(opp.RepresentanteVDELookup__c);
            }
            if(opp.RepresentanteVDILookup__c != null){
                idVendedores.add(opp.RepresentanteVDILookup__c);
            }
            if(opp.Vendedor__c != null){
                codigoVendedores.add(opp.Vendedor__c);
            }
            if(opp.VendedorSuporte__c != null){
                codigoVendedores.add(opp.VendedorSuporte__c);
            }
        }

        Map<Id,User> mapVendedores = new Map<Id,User>([SELECT Id, CodigoUsuario__c FROM User WHERE ID IN: idVendedores OR CodigoUsuario__c IN: codigoVendedores ]);
        Map<String,User> mapVendedoresByCodigoUsuario = new Map<String,User>();
        if(!mapVendedores.isEmpty()){
            for(User u: mapVendedores.values()){
                mapVendedoresByCodigoUsuario.put(u.CodigoUsuario__c, u);
            }

            for(Opportunity opp: newRecordList){
                if(opp.RepresentanteVDELookup__c != null && (oldMap == null || SObjectUtils.hasChangedFields(opp, oldMap, 'RepresentanteVDELookup__c'))){
                    if(mapVendedores.containsKey(opp.RepresentanteVDELookup__c)){
                        opp.Vendedor__c = mapVendedores.get(opp.RepresentanteVDELookup__c).CodigoUsuario__c;
                    } else {
                        opp.Vendedor__c = null;
                    }
                }
                if(opp.RepresentanteVDILookup__c != null && (oldMap == null || SObjectUtils.hasChangedFields(opp, oldMap, 'RepresentanteVDILookup__c'))){
                    if(mapVendedores.containsKey(opp.RepresentanteVDILookup__c)){
                        opp.VendedorSuporte__c = mapVendedores.get(opp.RepresentanteVDILookup__c).CodigoUsuario__c;
                    } else {
                        opp.VendedorSuporte__c = null;
                    }
                }
                if(String.isNotBlank(opp.Vendedor__c) && (oldMap == null || SObjectUtils.hasChangedFields(opp, oldMap, 'Vendedor__c'))){
                    if(mapVendedoresByCodigoUsuario.containsKey(opp.Vendedor__c)){
                        opp.RepresentanteVDELookup__c = mapVendedoresByCodigoUsuario.get(opp.Vendedor__c).Id;
                    } else {
                        opp.RepresentanteVDELookup__c = null;
                    }
                }
                if(String.isNotBlank(opp.VendedorSuporte__c) && (oldMap == null || SObjectUtils.hasChangedFields(opp, oldMap, 'VendedorSuporte__c'))){
                    if(mapVendedoresByCodigoUsuario.containsKey(opp.VendedorSuporte__c)){
                        opp.RepresentanteVDILookup__c = mapVendedoresByCodigoUsuario.get(opp.VendedorSuporte__c).Id;
                    } else {
                        opp.RepresentanteVDILookup__c = null;
                    }
                }
            }
        }
        
    }
    //Ajuste H-1078
	public void updateNameOrcamento(List<Opportunity> newRecordList, Map<Id,Opportunity> oldMap){
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();
		
		for(Opportunity opp: newRecordList){
            setFretePicklist(opp, oldMap);            
            if( opp.RecordTypeId != recordTypeId){               
                opp.Name = opp.NumeroOrcamento__c;
            }
        }
	}
}