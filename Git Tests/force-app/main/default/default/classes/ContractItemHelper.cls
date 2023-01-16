public without sharing class ContractItemHelper {

    // before update, before insert
    public static void validateStatusField(ItemContrato__c[] newRecordList, Map<Id, ItemContrato__c> oldMap, Map<Id, ItemContrato__c> newMap) {
        for (ItemContrato__c con : newRecordList) {
            system.debug('oldMap: ' + oldMap);
            system.debug('oldMap != null: ' + oldMap != null);
            system.debug('con.Status: ' + con.Status__c);
            system.debug('Approval.isLocked(con.NumeroContrato__c):' + Approval.isLocked(con.NumeroContrato__c));
            System.debug('Preço unitario: ' + con.PrecoUnitario__c);
            if (oldMap != null) {
                if (oldMap.get(con.Id).Status__c != newMap.get(con.Id).Status__c) {
                    con.Status__c.addError('Não é possível atualizar o Status do Item de Contrato manualmente.');
                }
                if (newMap.get(con.Id).PrecoUnitario__c <= 0 || newMap.get(con.Id).PrecoUnitario__c == null) {
                    con.PrecoUnitario__c.addError('Não é possível atualizar o Preço unitário para o valor escolhido.');
                }
            } else if (con.Status__c != 'Rascunho') {
                con.Status__c.addError('Não é possível inserir um Item de Contrato com Status diferente de "Rascunho".');
            } else {
                if (con.PrecoUnitario__c <= 0 || con.PrecoUnitario__c == null) {
                    con.PrecoUnitario__c.addError('Não é possível criar o produto com o valor escolhido.');
                }
            }
        }
    }
    
    // before update, before insert
    public static void updateContractItemStatus(ItemContrato__c[] newRecordList) {
        for (ItemContrato__c contractItem : newRecordList) {
            if (contractItem.Status__c != 'Em aprovação' && UserInfo.getUserEmail() != 'demo@nescara.com') {
                contractItem.Status__c = 'Em aprovação';
            }
        }
    }

    // after update, after insert
    public static void submitContractToApproval(ItemContrato__c[] newRecordList) {
        Set<Id> setContractId = new Set<Id>();
        
        for (ItemContrato__c contractItem : newRecordList) {
            if (UserInfo.getUserEmail() != 'demo@nescara.com') {
                setContractId.add(contractItem.NumeroContrato__c);
            }
        }

        List<Approval.ProcessSubmitRequest> listReq = new List<Approval.ProcessSubmitRequest>();
        Set<Id> setContractIdToCheck = new Set<Id>();

        for (Contract con : [SELECT Id, Status FROM Contract WHERE Id IN: setContractId AND Status != 'Em aprovacao']) {
            setContractIdToCheck.add(con.Id);
        }

        Set<Id> setGpOrUserId = new Set<Id>();

        if (UserInfo.getUserEmail() != 'demo@nescara.com') {
            for (GroupMember gpm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Pricing']) {
                setGpOrUserId.add(gpm.UserOrGroupId);
            }
        }

        for (User us : [SELECT Id, Name, IsActive FROM User WHERE Id IN: setGpOrUserId]) {
            if (!us.isActive) {
                setGpOrUserId.remove(us.Id);
            }
        }
        
        for (Id conId : setContractIdToCheck) {
            // Create an approval request for the Contract
            for (Id usId : setGpOrUserId) {
                listReq.add(getProcessRequest(conId, usId));
            }
        }
        system.debug(listReq);

        if (!listReq.isEmpty()) {
            // Submit the approval request for the Contract
            List<Approval.ProcessResult> listResult = Approval.process(listReq);
        }
    }    

    public static Approval.ProcessSubmitRequest getProcessRequest(Id contractId, Id userId) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Envio automático do contrato para processo de aprovação do Pricing.');
        req.setObjectId(contractId);
        req.setProcessDefinitionNameOrId('Contrato_AprovacaoPricing');
        req.setNextApproverIds(new Id[] {userId});

        return req;
    }

}