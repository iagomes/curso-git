public without sharing class SetorizacaoHelper {
    public SetorizacaoHelper() {}

    public static void fillEmptyActingTable(List<Setorizacao__c> newRecords) {

        for (Setorizacao__c currentSectorization : newRecords) {
            if (currentSectorization.CodigoMesa__c == null){
                currentSectorization.CodigoMesa__c = '000000';
                currentSectorization.Mesa__c = 'Geral';
            }
        }
    }

    public static void addAccTeamMemberBySectorization(Setorizacao__c[] newRecords) {
        system.debug('newRecords: ' + newRecords);

        Set<String> setAccId = new Set<String>();
        Set<String> setVendedorId = new Set<String>();

        List<AccountTeamMember> listAccTeamMember = new List<AccountTeamMember>();
        Map<Id, Setorizacao__c> mapIdToSetorizacao = new Map<Id, Setorizacao__c>();

        for (Setorizacao__c setorizacao : newRecords) {
            system.debug('inicial: ' + setorizacao.DataInicial__c);
            system.debug('atual: ' + Date.today());
            system.debug('final: ' + setorizacao.DataFinal__c);
            if (setorizacao.DataInicial__c <= Date.today() && (setorizacao.DataFinal__c >= Date.today() || setorizacao.DataFinal__c == null)) {
                setAccId.add(setorizacao.Conta__c);
                if(setorizacao.Vendedor__c != null)
                    setVendedorId.add(setorizacao.Vendedor__c);
                if(setorizacao.Gerente__c != null)
                    setVendedorId.add(setorizacao.Gerente__c);
                mapIdToSetorizacao.put(setorizacao.Id, setorizacao);
            }
        }

        system.debug('mapIdToSetorizacao: ' + mapIdToSetorizacao);

        Set<String> setAccUserKeyAlreadyExists = new Set<String>();
        for (AccountTeamMember accTM : [SELECT Id, AccountId, UserId, Setorizacao__c FROM AccountTeamMember WHERE AccountId IN : setAccId AND UserId IN: setVendedorId]) {
            setAccUserKeyAlreadyExists.add(accTM.AccountId + '_' + accTM.UserId); 
        }

        system.debug('setAccUserKeyAlreadyExists: ' + setAccUserKeyAlreadyExists);

        Set<Id> setAllUserId = new Set<Id>();
        Set<Id> setActiveUserId = new Set<Id>();
        for (Id setorizacaoId : mapIdToSetorizacao.keySet()) {
            setAllUserId.add(mapIdToSetorizacao.get(setorizacaoId).Vendedor__c);
            setAllUserId.add(mapIdToSetorizacao.get(setorizacaoId).Gerente__c);
        }

        for (User us : [SELECT Id FROM User WHERE Id IN: setAllUserId AND IsActive = true]) {
            setActiveUserId.add(us.Id);
        }

        List<AccountTeamMember> listAccTeamMemberToInsert = new List<AccountTeamMember>();
        for (Id setorizacaoId : mapIdToSetorizacao.keySet()) {
            Setorizacao__c setorizacao = mapIdToSetorizacao.get(setorizacaoId);
            if (!setAccUserKeyAlreadyExists.contains(setorizacao.Conta__c + '_' + setorizacao.Vendedor__c)) {
                if(mapIdToSetorizacao.get(setorizacaoId).Vendedor__c != null && setActiveUserId.contains(mapIdToSetorizacao.get(setorizacaoId).Vendedor__c))
                    listAccTeamMemberToInsert.add(SetorizacaoHelper.fillAccTeamMember(mapIdToSetorizacao, setorizacaoId));
                if(mapIdToSetorizacao.get(setorizacaoId).Gerente__c != null && setActiveUserId.contains(mapIdToSetorizacao.get(setorizacaoId).Gerente__c))
                    listAccTeamMemberToInsert.add(SetorizacaoHelper.fillAccTeamMemberGP(mapIdToSetorizacao, setorizacaoId));
            }
        }

        system.debug('listAccTeamMemberToInsert: ' + listAccTeamMemberToInsert);

        if (!listAccTeamMemberToInsert.isEmpty()) {
            insert listAccTeamMemberToInsert;
        }
    }

    // public static void upAccTeamMemberBySectorization(Map<Id, Setorizacao__c> newMap, Map<Id, Setorizacao__c> oldMap, Setorizacao__c[] newRecords) {

    //     system.debug('newMap: ' + newMap);
    //     system.debug('oldMap: ' + oldMap);

    //     Set<Id> setSetorizacaoId = new Set<Id>();
        
    //     Set<Id> setIdSetorizacaoToDelete = new Set<Id>();        
    //     Set<Id> setIdSetorizacaoToUpdate = new Set<Id>();
    //     Set<Id> setIdSetorizacaoToInsert = new Set<Id>();

    //     Set<Id> setIdSetorizacaoWithAccTM = new Set<Id>();
    //     Set<String> setAccId = new Set<String>();
    //     Set<String> setVendedorId = new Set<String>();
    //     Set<String> setAllUserId  = new Set<String>();
    //     Set<String> setActiveUserId = new Set<String>();
    //     Map<Id, Setorizacao__c> mapIdToSetorizacao = new Map<Id, Setorizacao__c>();

    //     for (Setorizacao__c setorizacao : newRecords) {
    //         setAllUserId.add(setorizacao.Vendedor__c);
    //         setAllUserId.add(setorizacao.Gerente__c);
    //         if (oldMap.get(setorizacao.Id).DataInicial__c != setorizacao.DataInicial__c && setorizacao.DataInicial__c == null) {
    //             setorizacao.addError('Não é possível remover a Data Inicial para atualizar uma setorização');
    //         } else if (setorizacao.DataInicial__c <= Date.today() && (setorizacao.DataFinal__c >= Date.today() || setorizacao.DataFinal__c == null)) {
    //             setAccId.add(setorizacao.Conta__c);
    //             if(setorizacao.Vendedor__c != null)
    //                 setVendedorId.add(setorizacao.Vendedor__c);
    //             if(setorizacao.Gerente__c != null)
    //                 setVendedorId.add(setorizacao.Gerente__c);
    //             mapIdToSetorizacao.put(setorizacao.Id, setorizacao);
    //         }
    //     }

    //     for (Id setorizacaoId : oldMap.keySet()) {
    //         Setorizacao__c oldSetorizacao = oldMap.get(setorizacaoId);
    //         Setorizacao__c newSetorizacao = newMap.get(setorizacaoId);
    //         if(newSetorizacao.NumeroRegistro__c != oldSetorizacao.NumeroRegistro__c && newSetorizacao.NumeroRegistro__c != null ){
    //             setIdSetorizacaoWithAccTM.add(setorizacaoId);
    //         }
    //         if (oldSetorizacao.DataInicial__c <= Date.today() && (oldSetorizacao.DataFinal__c >= Date.today() || oldSetorizacao.DataFinal__c == null)) {
    //             setIdSetorizacaoWithAccTM.add(setorizacaoId);
    //             if (newSetorizacao.DataInicial__c <= Date.today() && (newSetorizacao.DataFinal__c >= Date.today() || newSetorizacao.DataFinal__c == null)) {
    //                 setIdSetorizacaoToUpdate.add(setorizacaoId);
    //             } else {
    //                 setIdSetorizacaoToDelete.add(setorizacaoId);
    //             }
    //         } else {
    //             if (newSetorizacao.DataInicial__c <= Date.today() && (newSetorizacao.DataFinal__c >= Date.today() || newSetorizacao.DataFinal__c == null)) {
    //                 setIdSetorizacaoToInsert.add(setorizacaoId);
    //             }
    //         }
    //     }
        
    //     List<AccountTeamMember> listAccTeamMemberToUpdate = new List<AccountTeamMember>();
    //     List<AccountTeamMember> listAccTeamMemberToInsert = new List<AccountTeamMember>();
    //     List<AccountTeamMember> listAccTeamMemberToDelete = new List<AccountTeamMember>();
                
    //     for (AccountTeamMember accTeamMember : [SELECT Id, AccountId, UserId, Setorizacao__c FROM AccountTeamMember WHERE Setorizacao__c IN: setIdSetorizacaoWithAccTM FOR UPDATE]) {
    //         system.debug(accTeamMember);
    //         if (setIdSetorizacaoToDelete.contains(accTeamMember.Setorizacao__c)) {
    //             listAccTeamMemberToDelete.add(accTeamMember);
    //         } else if (setIdSetorizacaoToUpdate.contains(accTeamMember.Setorizacao__c)) {
    //             listAccTeamMemberToUpdate.add(accTeamMember);
    //             setAllUserId.add(accTeamMember.UserId);
    //         }
    //     }

    //     for (User u : [SELECT Id FROM User WHERE Id IN: setAllUserId AND IsActive = true]) {
    //         setActiveUserId.add(u.Id);
    //     }

    //     if (!listAccTeamMemberToUpdate.isEmpty()) {
    //         for (AccountTeamMember accTM : listAccTeamMemberToUpdate) {
    //             if (newMap.get(accTM.Setorizacao__c).Vendedor__c != null && setActiveUserId.contains(newMap.get(accTM.Setorizacao__c).Vendedor__c)) {
    //                 listAccTeamMemberToInsert.add(fillAccTeamMember(newMap, accTM.Setorizacao__c));
    //             }
    //             if (newMap.get(accTM.Setorizacao__c).Gerente__c != null && setActiveUserId.contains(newMap.get(accTM.Setorizacao__c).Gerente__c)) {
    //                 listAccTeamMemberToInsert.add(fillAccTeamMemberGP(newMap, accTM.Setorizacao__c));
    //             }
    //         }
    //     }

    //     for (Id setorizacaoId : newMap.KeySet()) {
    //         if (setIdSetorizacaoToInsert.contains(setorizacaoId)) {
    //             if (newMap.get(setorizacaoId).Vendedor__c != null && setActiveUserId.contains(newMap.get(setorizacaoId).Vendedor__c)) {
    //                 listAccTeamMemberToInsert.add(fillAccTeamMember(newMap, setorizacaoId));
    //             }
    //             if (newMap.get(setorizacaoId).Gerente__c != null && setActiveUserId.contains(newMap.get(setorizacaoId).Gerente__c)) {
    //                 listAccTeamMemberToInsert.add(fillAccTeamMemberGP(newMap, setorizacaoId));
    //             }
    //         }
    //     }

    //     Set<String> setAccUserKeyAlreadyExists = new Set<String>();
    //     for (AccountTeamMember accTM : [SELECT Id, AccountId, UserId, Setorizacao__c FROM AccountTeamMember WHERE AccountId IN : setAccId AND UserId IN: setVendedorId]) {
    //         setAccUserKeyAlreadyExists.add(accTM.AccountId + '_' + accTM.UserId); 
    //     }

    //     system.debug('setAccUserKeyAlreadyExists: ' + setAccUserKeyAlreadyExists);

    //     for (Id setorizacaoId : mapIdToSetorizacao.keySet()) {
    //         Setorizacao__c setorizacao = mapIdToSetorizacao.get(setorizacaoId);
    //         if (!setAccUserKeyAlreadyExists.contains(setorizacao.Conta__c + '_' + setorizacao.Vendedor__c)) {
    //             if(setorizacao.Vendedor__c != null && setActiveUserId.contains(setorizacao.Vendedor__c))
    //                 listAccTeamMemberToInsert.add(fillAccTeamMember(mapIdToSetorizacao, setorizacaoId));
    //         } else if (!setAccUserKeyAlreadyExists.contains(setorizacao.Conta__c + '_' + setorizacao.Gerente__c)){                
    //             if(setorizacao.Gerente__c != null && setActiveUserId.contains(setorizacao.Gerente__c))
    //                 listAccTeamMemberToInsert.add(fillAccTeamMemberGP(mapIdToSetorizacao, setorizacaoId));
    //         }
    //     }

    //     system.debug('listAccTeamMemberToInsert: ' + listAccTeamMemberToInsert);
    //     system.debug('listAccTeamMemberToUpdate: ' + listAccTeamMemberToUpdate);
    //     system.debug('listAccTeamMemberToDelete: ' + listAccTeamMemberToDelete);

    //     if (!listAccTeamMemberToInsert.isEmpty()) {
    //         insert listAccTeamMemberToInsert;
    //     }

    //     if (!listAccTeamMemberToUpdate.isEmpty()) {
    //         update listAccTeamMemberToUpdate;
    //     }

    //     if (!listAccTeamMemberToDelete.isEmpty()) {
    //         //delete listAccTeamMemberToDelete;
    //     }

    // }

    public static void delAccTeamMemberBySectorization(Setorizacao__c[] oldRecords) {
        system.debug('oldRecords: ' + oldRecords);
        
        Set<Id> setSetorizacaoId = new Set<Id>();
        for (Setorizacao__c setorizacao : oldRecords) {
            setSetorizacaoId.add(setorizacao.Id);
        }

        List<AccountTeamMember> listAccTeamMemberToDelete = new List<AccountTeamMember>();

        for (AccountTeamMember accTeamMember : [SELECT Id, Setorizacao__c FROM AccountTeamMember WHERE Setorizacao__c IN: setSetorizacaoId]) {
            listAccTeamMemberToDelete.add(accTeamMember);
        }

        system.debug('listAccTeamMemberToDelete: ' + listAccTeamMemberToDelete);

        if (!listAccTeamMemberToDelete.isEmpty()) {
            //delete listAccTeamMemberToDelete;
        }
    }

    public static AccountTeamMember fillAccTeamMember(Map<Id, Setorizacao__c> mapIdToSetorizacao, Id setorizacaoId) {
        return new AccountTeamMember(
            AccountId          = mapIdToSetorizacao.get(setorizacaoId).Conta__c,
            UserId             = mapIdToSetorizacao.get(setorizacaoId).Vendedor__c,
            Setorizacao__c     = setorizacaoId,
            AccountAccessLevel = 'Read'
        );
    }
    public static AccountTeamMember fillAccTeamMemberGP(Map<Id, Setorizacao__c> mapIdToSetorizacao, Id setorizacaoId) {
        return new AccountTeamMember(
            AccountId          = mapIdToSetorizacao.get(setorizacaoId).Conta__c,
            UserId             = mapIdToSetorizacao.get(setorizacaoId).Gerente__c,
            Setorizacao__c     = setorizacaoId,
            AccountAccessLevel = 'Read'
        );
    }


}