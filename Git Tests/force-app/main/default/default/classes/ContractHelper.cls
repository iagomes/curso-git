public without sharing class ContractHelper {    

    // BEFORE INSERT, AFTER INSERT
    public static void replicateContractNumber(Contract[] newRecordList) {
        Set<Id> setContractId = new Set<Id>();
        system.debug('newRecordList: '+ newRecordList);
        for(Contract con : newRecordList){
            setContractId.add(con.Id);
        }

        // se for o valor do ContractNumber, rodar no AFTER
        if (!setContractId.isEmpty()) {
            List<Contract> listContract = new List<Contract>();
            for (Contract con : [SELECT Id, ContractNumber, Name FROM Contract WHERE Id IN: setContractId]) {
                if (!String.isEmpty(con.ContractNumber)) {
                    con.Name = con.ContractNumber;
                    con.CodigoContrato__c = con.id;
                    listContract.add(con);
                }            
            }
    
            if (!listContract.isEmpty()) {
                ContractHandler.disableTrigger();
                update listContract;
                ContractHandler.enableTrigger();
            }
        }
    }

    public static void validateStatusFieldUpdate(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Set<Id> setAccId = new Set<Id>();
        Set<String> setContractType = new Set<String>();

        Map<Id, String> mapAccIdToContractType = new Map<Id, String>();
        Map<Id, Id> mapAccIdToContractId       = new Map<Id, Id>();
        for(Contract Contract : newMap.values()){
            setContractType.add(Contract.TipoRegra__c);
            setAccId.add(Contract.AccountId);
            mapAccIdToContractType.put(Contract.AccountId, Contract.TipoRegra__c);
            mapAccIdToContractId.put(Contract.AccountId, Contract.Id);
        }

        Set<String> setDuplicateContract = new Set<String>();

        for (Contract con : [SELECT Id, AccountId, TipoRegra__c FROM Contract WHERE AccountId IN: setAccId AND TipoRegra__c IN: setContractType]) {
            if (mapAccIdToContractId.get(con.AccountId) != con.Id) {
                if (mapAccIdToContractType.get(con.AccountId) == con.TipoRegra__c) {
                    setDuplicateContract.add(con.AccountId + '_' + con.TipoRegra__c);
                } 
            }   
        }

        for (Contract con : newMap.values()) {
            system.debug('con.isApprovalProcess__c: ' + con.isApprovalProcess__c);
            system.debug('con.Status: ' + con.Status);
            if (oldMap.get(con.Id).Status != newMap.get(con.Id).Status && !con.isApprovalProcess__c) {
                con.Status.addError('Não é possível atualizar o Status do Contrato manualmente.');
            } else if (setDuplicateContract.contains(con.AccountId + '_' + con.TipoRegra__c)) {
                System.debug('Não é possível ter contratos repetidos');
                con.addError('Não é possível ter dois contratos do mesmo tipo para o mesmo cliente');
            }
            if (con.isApprovalProcess__c) {
                con.isApprovalProcess__c = false;                
            }
        }
    }

    public static void validateStatusFieldInsert(Contract[] newRecordList) {
        Set<Id> setAccId = new Set<Id>();
        Set<String> setContractType = new Set<String>();

        Map<Id, String> mapAccIdToContractType = new Map<Id, String>();
        Map<Id, Id> mapAccIdToContractId       = new Map<Id, Id>();
        for(Contract Contract : newRecordList){
            setContractType.add(Contract.TipoRegra__c);
            setAccId.add(Contract.AccountId);
            mapAccIdToContractType.put(Contract.AccountId, Contract.TipoRegra__c);
            mapAccIdToContractId.put(Contract.AccountId, Contract.Id);
        }

        Set<String> setDuplicateContract = new Set<String>();

        for (Contract con : [SELECT Id, AccountId, TipoRegra__c FROM Contract WHERE AccountId IN: setAccId AND TipoRegra__c IN: setContractType]) {
            if (mapAccIdToContractId.get(con.AccountId) != con.Id) {
                if (mapAccIdToContractType.get(con.AccountId) == con.TipoRegra__c) {
                    setDuplicateContract.add(con.AccountId + '_' + con.TipoRegra__c);
                } 
            }   
        }

        for (Contract con : newRecordList) {
            system.debug('con.isApprovalProcess__c: ' + con.isApprovalProcess__c);
            system.debug('con.Status: ' + con.Status);
            if (setDuplicateContract.contains(con.AccountId + '_' + con.TipoRegra__c)) {
                System.debug('Não é possível criar contratos repetidos');
                con.addError('Não é possível criar dois contratos do mesmo tipo para o mesmo cliente');
            } else if (!con.isApprovalProcess__c && con.Status != 'Rascunho') {
                con.Status.addError('Não é possível inserir um Contrato com Status diferente de "Rascunho".');
            } else if (setDuplicateContract.contains(con.AccountId + '_' + con.TipoRegra__c)) {
                System.debug('Não é possível ter contratos repetidos');
                con.addError('Não é possível ter dois contratos do mesmo tipo para o mesmo cliente');
            }
            if (con.isApprovalProcess__c) {
                con.isApprovalProcess__c = false;                
            }
        }
    }

    // BEFORE INSERT, BEFORE UPDATE
    public static void checkContractType(Contract[] newRecordList) {
        Set<Id> setAccId = new Set<Id>();
        Set<String> setContractType = new Set<String>();

        Map<Id, String> mapAccIdToContractType = new Map<Id, String>();
        for(Contract Contract : newRecordList){
            if (Contract.Status == 'Aprovado') {
                setContractType.add(Contract.TipoRegra__c);
                setAccId.add(Contract.AccountId);
                mapAccIdToContractType.put(Contract.AccountId, Contract.TipoRegra__c);
            }
        }

        Set<String> setDuplicateContract = new Set<String>();
        system.debug(setAccId);
        system.debug(setContractType);

        for (Contract con : [SELECT Id, AccountId, TipoRegra__c FROM Contract WHERE AccountId IN: setAccId AND TipoRegra__c IN: setContractType AND Status = 'Aprovado']) {
            if (mapAccIdToContractType.get(con.AccountId) == con.TipoRegra__c) {
                setDuplicateContract.add(con.AccountId + '_' + con.TipoRegra__c);
            }    
        }

        Set<Id> contIdSet = new Set<Id>();
        for (Contract con : newRecordList) {
            if (con.Status == 'Aprovado' && setDuplicateContract.contains(con.AccountId + '_' + con.TipoRegra__c) && con.TipoRegra__c != 'O') {
                con.addError('Não é possível ter dois contratos aprovados do mesmo tipo para o mesmo cliente');
            }else if(con.Status == 'Aprovado'){
                contIdSet.add(con.id);
            }
        }
        if(!contIdSet.isEmpty()){            
            System.enqueueJob(new IntegrationContractOUTQueueable(0, new List<Id>(contIdSet)));
        }
    }

    // before update quando um contrato for aprovado ou recusado
    public static void updateContractItensStatus(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Set<Id> setApprovedContractId = new Set<Id>();
        Set<Id> setReprovedContractId = new Set<Id>();
        for (Id conId : oldMap.keySet()) {
            system.debug('new Contract isApprovalProcess__c: ' + newMap.get(conId).isApprovalProcess__c);
            if (oldMap.get(conId).Status != newMap.get(conId).Status && newMap.get(conId).Status == 'Aprovado' && newMap.get(conId).isApprovalProcess__c) {
                setApprovedContractId.add(conId);
            } else if (oldMap.get(conId).Status != newMap.get(conId).Status && newMap.get(conId).Status == 'Reprovado' && newMap.get(conId).isApprovalProcess__c) {
                setReprovedContractId.add(conId);
            }
        }
        system.debug('setApprovedContractId: ' + setApprovedContractId);
        system.debug('setReprovedContractId: ' + setReprovedContractId);

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        
        Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE (TargetObjectId IN: setApprovedContractId OR TargetObjectId IN: setReprovedContractId)]);

        for(ProcessInstanceWorkItem workItem : [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet()]){
            system.debug('workItem: ' + workItem);
            // if there's a work item, set the action to 'removed' and execute
            system.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            if (!setApprovedContractId.isEmpty()) {
                if (setApprovedContractId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                    req.setAction('Approve');
                }
            }
            if (!setReprovedContractId.isEmpty()) {
                if (setReprovedContractId.contains(mapIdToProcessInstance.get(workItem.ProcessInstanceId).TargetObjectId)) {
                    req.setAction('Reject');
                }
            }
            req.setWorkitemId(workItem.Id);
            requests.add(req);
        }

        system.debug('requests: ' + requests);

        Approval.ProcessResult[] processResults = Approval.process(requests, true);

        List<ItemContrato__c> listItemContrato = new List<ItemContrato__c>();

        Set<Id> setApprovedContractItemId = new Set<Id>();
        Set<Id> setReprovedContractItemId = new Set<Id>();

        for (ItemContrato__c itemContract : [SELECT Id, NumeroContrato__c, Status__c FROM ItemContrato__c WHERE (NumeroContrato__c IN: setApprovedContractId OR NumeroContrato__c IN: setReprovedContractId) AND Status__c = 'Em aprovação']) {
            if (setApprovedContractId.contains(itemContract.NumeroContrato__c)) {
                itemContract.Status__c = 'Aprovado';
                setApprovedContractItemId.add(itemContract.Id);
            } else if (setReprovedContractId.contains(itemContract.NumeroContrato__c)) {
                itemContract.Status__c = 'Reprovado';
                setReprovedContractItemId.add(itemContract.Id);
            }

            listItemContrato.add(itemContract);
        }

        if (!listItemContrato.isEmpty()) {
            ContractItemHandler.disableTrigger();
            update listItemContrato;
            ContractItemHandler.enableTrigger();
        }

        if (!setApprovedContractId.isEmpty())
            sendNotificationContract(setApprovedContractId, true, setApprovedContractItemId, processResults);
        if (!setReprovedContractId.isEmpty())
            sendNotificationContract(setReprovedContractId, false, setReprovedContractItemId, processResults);
    }

    public static void sendNotificationContract(Set<Id> setContractId, Boolean wasApproved, Set<Id> setContractItemId, List<Approval.ProcessResult> processResultList) {
        System.debug('Entrou na Notificação/Email de Contrato');
        // Emails
        Messaging.reserveSingleEmailCapacity(2);
        Set<String> toAddresses = new Set<String>{};
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        // Custom Notification
        CustomNotificationType notificationType   = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'ContractNotification'];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationType.Id);
        
        Map<Id, List<Setorizacao__c>> contractToSectorizationMap = new Map<Id, List<Setorizacao__c>>();
        Set<String> setCategory = new Set<String>();
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> setNotifUsersId = new Set<Id>();

        List<Contract> contractList =   [
                                            SELECT  
                                                Id,
                                                CreatedBy.Email,
                                                ContractNumber,
                                                Account.Name
                                                FROM Contract
                                                WHERE Id IN: setContractId
                                        ];
        
        List<ItemContrato__c> contractItemList =   [
                                                        SELECT 
                                                            Id, 
                                                            Name, 
                                                            CreatedById, 
                                                            NumeroContrato__c, 
                                                            NumeroContrato__r.AccountId,
                                                            NumeroContrato__r.Account.Name,
                                                            NomeProduto__r.Name, 
                                                            NomeProduto__r.CategoriaComercial__c 
                                                        FROM ItemContrato__c 
                                                        WHERE NumeroContrato__c IN: setContractId
                                                    ];
        for (ItemContrato__c contractItem : contractItemList) {
            setCategory.add(contractItem.NomeProduto__r.CategoriaComercial__c);
            setAccountId.add(contractItem.NumeroContrato__r.AccountId);
        }

        List<Setorizacao__c> sectorizationList =    [
                                                        SELECT 
                                                            Id, 
                                                            Vendedor__c, 
                                                            Vendedor__r.Email, 
                                                            Conta__c, 
                                                            Conta__r.Name, 
                                                            Categoria__c 
                                                        FROM Setorizacao__c 
                                                        WHERE Conta__c IN: setAccountId AND 
                                                            Categoria__c IN: setCategory
                                                    ];
        System.debug(sectorizationList);
        for (ItemContrato__c contractItem : contractItemList) {
            for (Setorizacao__c sectorization : sectorizationList) {
                if (contractItem.NomeProduto__r.CategoriaComercial__c == sectorization.Categoria__c && contractItem.NumeroContrato__r.AccountId == sectorization.Conta__c) {
                    setNotifUsersId.add(sectorization.Vendedor__c);
                    if (!contractToSectorizationMap.containsKey(contractItem.NumeroContrato__c)) {
                        contractToSectorizationMap.put(contractItem.NumeroContrato__c, new List<Setorizacao__c>{});
                    }
                    contractToSectorizationMap.get(contractItem.NumeroContrato__c).add(sectorization);
                }
            }
        }

        Set<Id> setProcessInstanceId = new Set<Id>();
        for (Contract contract : contractList) {
            for (Approval.ProcessResult processResult : processResultList) {
                if (processResult.getEntityId() == contract.Id)
                    setProcessInstanceId.add(processResult.getInstanceId());
            }
        }

        List<ProcessInstanceStep> processInstanceStepList = new List<ProcessInstanceStep>();
        if (!setProcessInstanceId.isEmpty()) {
            processInstanceStepList = [SELECT Id, Comments, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceStep WHERE ProcessInstanceId IN: setProcessInstanceId ORDER BY CreatedDate DESC];
        }

        for (Contract contract : contractList) {
            String comments = '';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String tituloNotification = 'Notificação de contrato ' + (wasApproved ? 'aprovado' : 'reprovado' + '!');
            
            if (contract.CreatedBy.Email != null)
                toAddresses.add(contract.CreatedBy.Email);
            if (contractToSectorizationMap.get(contract.Id) != null) {
                for (Setorizacao__c sectorization : contractToSectorizationMap.get(contract.Id)) {
                    if (sectorization.Vendedor__r.Email != null && toAddresses.size() < 150)
                        toAddresses.add(sectorization.Vendedor__r.Email);
                }
            }

            if (!processInstanceStepList.isEmpty()) {
                for (ProcessInstanceStep processInstanceStep : processInstanceStepList) {
                    if (processInstanceStep.ProcessInstance.TargetObjectId == contract.Id) {
                        if (comments == '' || comments == null) {
                            comments = processInstanceStep.Comments;
                        }
                    }
                }
            }

            String bodyEmail = 'O contrato <b>' + contract.ContractNumber + '</b> do cliente <b>' + contract.Account.Name + '</b> foi <b>' + (wasApproved ? 'aprovado' : 'reprovado') + '.</b><br/>';
            String bodyNotification = 'O contrato ' + contract.ContractNumber + ' do cliente ' + contract.Account.Name + ' foi ' + (wasApproved ? 'aprovado' : 'reprovado') + '.\n';
            if (!wasApproved){
                bodyEmail += 'Motivo da reprovação: ' + (comments == '' ? '' : comments) + '<br/><br/>Itens reprovados:<br/>';
                bodyNotification += 'Motivo da reprovação: ' + comments + '\n\nItens reprovados:\n';
            }
            else {
                bodyEmail += '<br/>Itens aprovados:<br/>';
                bodyNotification += '\nItens aprovados:\n';
            }

            for (ItemContrato__c contractItem : contractItemList) {
                if (contractItem.NumeroContrato__c == contract.Id) {
                    bodyEmail += '<b>' + contractItem.Name + ': ' + contractItem.NomeProduto__r.Name + '.</b><br/>';
                    bodyNotification += contractItem.Name + ': ' + contractItem.NomeProduto__r.Name + '.\n';
                }
            }

            // Emails
            mail.setToAddresses(new List<String>(toAddresses));
            mail.setSaveAsActivity(false);
            mail.setSubject(tituloNotification);
            mail.setHtmlBody(bodyEmail);
            emailList.add(mail);

            // Custom Notification
            notification.setTitle(tituloNotification);
            notification.setBody(bodyNotification);
            notification.setTargetId(contract.Id);

            try {
                Set<String> recipientsIds = new Set<String>();
                setNotifUsersId.add(contract.CreatedById);
                for (Id userId : setNotifUsersId) {
                    recipientsIds.add(userId);
                }
                notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug('Erro na notificação de sininho de contrato aprovado/reprovado' + e.getMessage());
            }
        }

        if (!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
            System.debug('Email de contrato aprovado/reprovado enviado com sucesso para:');
            System.debug(toAddresses);
            System.debug('Results =>');
            System.debug(results);
        }
    }

    public static void unlockContract(Contract[] newRecordList) {
        List<Id> listContractId = new List<Id>();
        for (Contract con : newRecordList) {
            system.debug(con.Status);
            if (con.Status == 'Em aprovacao' && (Test.isRunningTest() || Approval.isLocked(con.Id))) {
                listContractId.add(con.Id);                
                Approval.unlock(con.Id);
            }
        }
        
        for (Id contId : listContractId) {
            system.debug('Contract with Id ' + contId + ' is ' + Approval.isLocked(contId));
        }
    }

    public static void checkUserRoleBeforeDelete(Contract[] oldRecordList) {
        Boolean suportSellerUser = false;
        for (PermissionSetAssignment pmSetAssignment : [SELECT Id, AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'VendedorSuporte' AND AssigneeId =: UserInfo.getUserId() LIMIT 1]) {
            suportSellerUser = true;
        }
        for (Contract con : oldRecordList) {
            if (suportSellerUser) {
                con.addError('Usuário sem acesso para excluir contrato! Favor contatar administrador!');
            }
        }
    }

    public static void changeStatusActive(Contract[] newRecordList) {      
        List<Contract> contractUpdateList = new List<Contract>();  
        for (Contract con : newRecordList) {
            if (con.Status == 'Aprovado' || con.Status == 'Reprovado') {
                contractUpdateList.add(new Contract(Id = con.Id, Status = 'Ativo'));
            }
        }
        if (!contractUpdateList.isEmpty()) {
            ContractHandler.disableTrigger();
            update contractUpdateList;
            ContractHandler.enableTrigger();
        }
    }
}