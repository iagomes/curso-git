public with sharing class BatchAssociateUsersInActingTables implements Database.Batchable<SObject> {
    public Boolean callNextProcess = false;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT
                Id,
                CodigoMesa__c,
                Categoria__c,
                Regiao__c,
                Vendedor__c,
                Vendedor__r.IsActive,
                VendedorSuporte__c,
                VendedorSuporte__r.IsActive,
                Gerente__c,
                Gerente__r.IsActive,
                Coordenador__c,
                Coordenador__r.IsActive
            FROM Setorizacao__c
            WHERE CodigoMesa__c != NULL
            AND DataFinal__c >: System.Today()
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Setorizacao__c> scope) {
        
        // check if association x territory already exists.
        Set<String> scopeUsersAlreadyAddedInTerritory = new Set<String>();
        Set<Id> userIdsToCheckInExistingAssociations = new Set<Id>();

        for (Setorizacao__c sectorization : scope) {
            if (sectorization.Vendedor__c != null && sectorization.Vendedor__r.IsActive) {
                userIdsToCheckInExistingAssociations.add(sectorization.Vendedor__c);
            }

            if (sectorization.VendedorSuporte__c != null && sectorization.VendedorSuporte__r.IsActive) {
                userIdsToCheckInExistingAssociations.add(sectorization.VendedorSuporte__c);
            }

            if (sectorization.Gerente__c != null && sectorization.Gerente__r.IsActive) {
                userIdsToCheckInExistingAssociations.add(sectorization.Gerente__c);
            }

            if (sectorization.Coordenador__c != null && sectorization.Coordenador__r.IsActive) {
                userIdsToCheckInExistingAssociations.add(sectorization.Coordenador__c);
            }
        }
        
        List<UserTerritory2Association> existingAssociationsList = 
            ActingTableTerritoryManagement.getAllUsersAssociationsByUserIds(userIdsToCheckInExistingAssociations);
        
        for (UserTerritory2Association existingAssociation : existingAssociationsList) {
            String customKey = 
                existingAssociation.Territory2.DeveloperName + 
                existingAssociation.UserId;

            if (!scopeUsersAlreadyAddedInTerritory.contains(customKey)) {
                scopeUsersAlreadyAddedInTerritory.add(customKey);
            }
        }

        List<UserTerritory2Association> usersToAssociate = new List<UserTerritory2Association>();
        
        Map<String, Territory2> allTerritoriesDeveloperNameMap = 
            ActingTableTerritoryManagement.getAllTerritoriesDeveloperNameMap();

        // primeira etapa, assumindo que temos a chave completa (Mesa, Categoria, Regiao)        
        for (Setorizacao__c sectorization : scope) {
            String developerNameKey = ActingTableTerritoryManagement.getDeveloperNameKey(sectorization, true);
            Territory2 territoryForAssociation;

            if (!allTerritoriesDeveloperNameMap.containsKey(developerNameKey)) {
                continue;
            } else {
                territoryForAssociation = allTerritoriesDeveloperNameMap.get(developerNameKey);
            }

            if (
                sectorization.Vendedor__r.IsActive &&
                !scopeUsersAlreadyAddedInTerritory.contains(developerNameKey+sectorization.Vendedor__c)
            ) {
                usersToAssociate.add(
                    ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                        territoryForAssociation,
                        sectorization.Vendedor__c,
                        'Vendedor'
                    )
                );
                scopeUsersAlreadyAddedInTerritory.add(developerNameKey+sectorization.Vendedor__c);
            }

            if (
                sectorization.VendedorSuporte__r.IsActive &&
                !scopeUsersAlreadyAddedInTerritory.contains(developerNameKey+sectorization.VendedorSuporte__c)
            ) {
                usersToAssociate.add(
                    ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                        territoryForAssociation,
                        sectorization.VendedorSuporte__c,
                        'Vendedor Suporte'
                    )
                );
                scopeUsersAlreadyAddedInTerritory.add(developerNameKey+sectorization.VendedorSuporte__c);
            }

            if (
                sectorization.Gerente__r.IsActive &&
                !scopeUsersAlreadyAddedInTerritory.contains(developerNameKey+sectorization.Gerente__c)
            ) {
                usersToAssociate.add(
                    ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                        territoryForAssociation,
                        sectorization.Gerente__c,
                        'Gerente'
                    )
                );
                scopeUsersAlreadyAddedInTerritory.add(developerNameKey+sectorization.Gerente__c);
            }

            if (
                sectorization.Coordenador__r.IsActive &&
                !scopeUsersAlreadyAddedInTerritory.contains(developerNameKey+sectorization.Coordenador__c)
            ) {
                usersToAssociate.add(
                    ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                        territoryForAssociation,
                        sectorization.Coordenador__c,
                        'Coordenador'
                    )
                );
                scopeUsersAlreadyAddedInTerritory.add(developerNameKey+sectorization.Coordenador__c);
            }
        }

        System.debug(usersToAssociate.size());
        if (usersToAssociate.size() > 0) {
            System.debug(usersToAssociate);
            Database.insert(usersToAssociate, false);
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {
            Eventbus.publish(new ProcessActingTable__e(
                Type__c = 'associate_users_without_acting_table',
                ExecuteNextProcesses__c = true
            ));
        }
    }
}