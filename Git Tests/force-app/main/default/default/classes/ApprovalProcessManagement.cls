public with sharing class ApprovalProcessManagement {
    public static Map<String, Set<Id>> getApprovalUsers(Set<Id> setAccountId, Map<String, Set<String>> mapRecTypeToCategories) {
        Set<Id> setUserId = new Set<Id>();
        Set<String> setKeysectorization = new Set<String>();

        Set<String> setApprovalRecTypeName = new Set<String>();
        Set<String> setProcessCategories = new Set<String>();
        Map<String, Set<Id>> mapApprovalProcessToSetUser = new Map<String, Set<Id>>(); // "Pedido_AprovacaoPricingM", Set<Id> (Usuários)

        Boolean isOrder = true;

        Map<String, Set<String>> mapApprovalProcessToCategories = new Map<String, Set<String>>();

        for (String mapKey : mapRecTypeToCategories.keySet()) {
            String approvalProcess = mapKey.split('----')[1];
            if (!approvalProcess.contains('Pedido_')) {
                isOrder = false;
            }
            String recTypeName = approvalProcess.replace('Pedido_', '').replace('Oportunidade_', '');
            mapApprovalProcessToCategories.put(approvalProcess, mapRecTypeToCategories.get(mapKey));
            system.debug('recTypeName: ' + recTypeName);
            setApprovalRecTypeName.add(recTypeName);

            for (String cat : mapRecTypeToCategories.get(mapKey)) {
                setProcessCategories.add(recTypeName + cat);
            }
        }

        system.debug('setProcessCategories: ' + setProcessCategories);

        system.debug(setApprovalRecTypeName);
        system.debug('mapApprovalProcessToCategories: ' + mapApprovalProcessToCategories);
        system.debug('setAccountId: ' + setAccountId);

        // Busca de setorizações por cliente
        for (Setorizacao__c setorizacao : [SELECT Id, CodigoMesa__c, Categoria__c, Regiao__c FROM Setorizacao__c WHERE Conta__c IN: setAccountId AND Categoria__c != null AND Regiao__c != null]) {
            if (setorizacao.CodigoMesa__c != null) {
                setKeysectorization.add(setorizacao.CodigoMesa__c);
                setKeysectorization.add(setorizacao.CodigoMesa__c + setorizacao.Regiao__c);
            }
            setKeysectorization.add(setorizacao.Regiao__c);
        }
        system.debug('Chaves setorização: ' + setKeysectorization);

        system.debug('mapRecTypeToCategories: ' + mapRecTypeToCategories);
        // BUSCA DE PRA APROVADORES
        for (ResponsabilidadeAprovacao__c resp : [SELECT Id, UsuarioAprovador__c, RecordType.DeveloperName, CodigoMesa__c, Categorias__c, Regiao__c FROM ResponsabilidadeAprovacao__c WHERE RecordType.DeveloperName IN: setApprovalRecTypeName]) {
            if (resp.CodigoMesa__c == null && resp.Categorias__c == null && resp.Regiao__c == null) {
                system.debug('RESPONSAVEL OBRIGATÓRIO DE APROVAÇÃO');
                for (String processo : mapApprovalProcessToCategories.keySet()) {
                    for (String categoria : mapApprovalProcessToCategories.get(processo)) {
                        system.debug('Caiu no IF: ' + resp.RecordType.DeveloperName + categoria);
                        system.debug(setProcessCategories.contains(resp.RecordType.DeveloperName + categoria));
                        if (setProcessCategories.contains(resp.RecordType.DeveloperName + categoria)) {
                            String mapKey = (isOrder ? 'Pedido_' : 'Oportunidade_') + resp.RecordType.DeveloperName + categoria;
                            if (!mapApprovalProcessToSetUser.containsKey(mapKey)) {
                                mapApprovalProcessToSetUser.put(mapKey, new Set<Id>{resp.UsuarioAprovador__c});
                            } else {
                                mapApprovalProcessToSetUser.get(mapKey).add(resp.UsuarioAprovador__c);
                            }
                        }
                    }
                }
            } else if (resp.Categorias__c != null) {
                system.debug(resp.UsuarioAprovador__c);
                system.debug(resp.CodigoMesa__c);
                system.debug(resp.Regiao__c);
                String key = (resp.CodigoMesa__c != null ? resp.CodigoMesa__c : '');
                key += (resp.Regiao__c != null ? resp.Regiao__c : '');
                system.debug(key);
                List<String> listCatSplit = resp.Categorias__c.split(';');
                for (String splittedCat : listCatSplit) {
                    system.debug('Caiu no ELSE IF cat: ' + resp.RecordType.DeveloperName + splittedCat);
                    system.debug(setProcessCategories.contains(resp.RecordType.DeveloperName + splittedCat));
                    if (setProcessCategories.contains(resp.RecordType.DeveloperName + splittedCat) && resp.CodigoMesa__c == null && resp.Regiao__c == null) {
                        String mapKey = (isOrder ? 'Pedido_' : 'Oportunidade_') + resp.RecordType.DeveloperName + splittedCat;
                        if (!mapApprovalProcessToSetUser.containsKey(mapKey)) {
                            mapApprovalProcessToSetUser.put(mapKey, new Set<Id>{resp.UsuarioAprovador__c});
                        } else {
                            mapApprovalProcessToSetUser.get(mapKey).add(resp.UsuarioAprovador__c);
                        }
                    } else if (setProcessCategories.contains(resp.RecordType.DeveloperName + splittedCat) && setKeysectorization.contains(key)) {
                        String mapKey = (isOrder ? 'Pedido_' : 'Oportunidade_') + resp.RecordType.DeveloperName + splittedCat;
                        if (!mapApprovalProcessToSetUser.containsKey(mapKey)) {
                            mapApprovalProcessToSetUser.put(mapKey, new Set<Id>{resp.UsuarioAprovador__c});
                        } else {
                            mapApprovalProcessToSetUser.get(mapKey).add(resp.UsuarioAprovador__c);
                        }
                    }
                }
            } else {
                system.debug(resp.UsuarioAprovador__c);
                system.debug(resp.CodigoMesa__c);
                system.debug(resp.Regiao__c);
                String key = (resp.CodigoMesa__c != null ? resp.CodigoMesa__c : '');
                key += (resp.Regiao__c != null ? resp.Regiao__c : '');
                system.debug(key);
                Boolean hasKey = key != '' ? true : false;
                system.debug(hasKey);
                for (String processo : mapApprovalProcessToCategories.keySet()) {
                    for (String categoria : mapApprovalProcessToCategories.get(processo)) {
                        system.debug('Caiu no ELSE: ' + resp.RecordType.DeveloperName + categoria);
                        system.debug(setProcessCategories.contains(resp.RecordType.DeveloperName + categoria));
                        if (setProcessCategories.contains(resp.RecordType.DeveloperName + categoria) && setKeysectorization.contains(key)) {
                            String mapKey = (isOrder ? 'Pedido_' : 'Oportunidade_') + resp.RecordType.DeveloperName + categoria;
                            system.debug(mapKey);
                            if (hasKey) {
                                if (setKeysectorization.contains(key)) {
                                    if (!mapApprovalProcessToSetUser.containsKey(mapKey)) {
                                        mapApprovalProcessToSetUser.put(mapKey, new Set<Id>{resp.UsuarioAprovador__c});
                                    } else {
                                        mapApprovalProcessToSetUser.get(mapKey).add(resp.UsuarioAprovador__c);
                                    }
                                }
                            } else {
                                if (!mapApprovalProcessToSetUser.containsKey(mapKey)) {
                                    mapApprovalProcessToSetUser.put(mapKey, new Set<Id>{resp.UsuarioAprovador__c});
                                } else {
                                    mapApprovalProcessToSetUser.get(mapKey).add(resp.UsuarioAprovador__c);
                                }
                            }
                        }
                    }
                }
            }
        }

        system.debug('Mapa de processo de aprovação para lista de usuários: ' + mapApprovalProcessToSetUser);

        for (String processo : mapApprovalProcessToSetUser.keySet()) {
            system.debug('Processo de aprovação: ' + processo);
            for (Id userId : mapApprovalProcessToSetUser.get(processo)) {
                system.debug('Usuário: ' + userId);
            }
        }

        return mapApprovalProcessToSetUser;
    }
}
