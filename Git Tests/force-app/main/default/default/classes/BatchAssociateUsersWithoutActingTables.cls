public with sharing class BatchAssociateUsersWithoutActingTables implements Database.Batchable<SObject> {
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
            WHERE CodigoMesa__c = NULL
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Setorizacao__c> scope) {
        // identificar usuarios do escopo
        Set<Id> userIdsToCheckInExistingAssociations = new Set<Id>();

        for (Setorizacao__c sectorization : scope) {if (sectorization.Vendedor__c != null && sectorization.Vendedor__r.IsActive) {userIdsToCheckInExistingAssociations.add(sectorization.Vendedor__c);}if (sectorization.VendedorSuporte__c != null && sectorization.VendedorSuporte__r.IsActive) {userIdsToCheckInExistingAssociations.add(sectorization.VendedorSuporte__c);}if (sectorization.Gerente__c != null && sectorization.Gerente__r.IsActive) {userIdsToCheckInExistingAssociations.add(sectorization.Gerente__c);}if (sectorization.Coordenador__c != null && sectorization.Coordenador__r.IsActive) {userIdsToCheckInExistingAssociations.add(sectorization.Coordenador__c);}}
        // buscar associações existentes
        List<UserTerritory2Association> existingAssociationsList = 
        ActingTableTerritoryManagement.getAllUsersAssociationsByUserIds(userIdsToCheckInExistingAssociations);
        
        // criar mapa de { DEVELOPERNAME_TERRI => Set<Id> userIds } (mapTerritoriesWithUsers)
        Map<String, Set<Id>> mapTerritoryToUserIds = new Map<String, Set<Id>>();
        for (UserTerritory2Association association : existingAssociationsList) {
            if (!mapTerritoryToUserIds.containsKey(association.Territory2.DeveloperName)) {mapTerritoryToUserIds.put(association.Territory2.DeveloperName,new Set<Id>());}
            mapTerritoryToUserIds.get(association.Territory2.DeveloperName).add(association.UserId);
        }

        // buscar todas os territórios de 3ª camada
        Map<String, Territory2> mapThirdLayerTerritories = ActingTableTerritoryManagement.getThirdLayerTerritoriesDeveloperNameMap();

        List<UserTerritory2Association> associationsToCreate = new List<UserTerritory2Association>();
        
        //for no escopo
        for (Setorizacao__c sectorization : scope) {
            // for nos territorios de 3ª camada
            for (Territory2 thirdLayerTerritory : mapThirdLayerTerritories.values()) {
                // comparar categoria e regiao -> scope x thirdLayer
                if (sectorization.Categoria__c == thirdLayerTerritory.Categoria__c && sectorization.Regiao__c == thirdLayerTerritory.Regiao__c) {
                    // verificar se existe chave em mapTerritoryToUserIds (thirdLayerTerritory.developerName)
                    if (mapTerritoryToUserIds.containsKey(thirdLayerTerritory.DeveloperName)) {
                        // verificar se esse usuário já foi adicionado contains in mapTerritoryToUserIds
                        Set<Id> usersIdsInTerritory = mapTerritoryToUserIds.get(thirdLayerTerritory.DeveloperName);
                        
                        if (sectorization.Vendedor__c != null && sectorization.Vendedor__r.IsActive && !usersIdsInTerritory.contains(sectorization.Vendedor__c)) {
                            // (ñ) criar associação com o territorio
                            associationsToCreate.add(ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(thirdLayerTerritory,sectorization.Vendedor__c,'Vendedor'));
                            usersIdsInTerritory.add(sectorization.Vendedor__c);
                        }

                        if (sectorization.Gerente__c != null && sectorization.Gerente__r.IsActive && !usersIdsInTerritory.contains(sectorization.Gerente__c)) {
                            // (ñ) criar associação com o territorio
                            associationsToCreate.add(ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(thirdLayerTerritory,sectorization.Gerente__c,'Gerente'));
                            usersIdsInTerritory.add(sectorization.Gerente__c);
                        }
                        
                        if (sectorization.Coordenador__c != null && sectorization.Coordenador__r.IsActive && !usersIdsInTerritory.contains(sectorization.Coordenador__c)) {
                            // (ñ) criar associação com o territorio
                            associationsToCreate.add(ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(thirdLayerTerritory,sectorization.Coordenador__c,'Coordenador'));
                            usersIdsInTerritory.add(sectorization.Coordenador__c); 
                        }

                        if (sectorization.VendedorSuporte__c != null && sectorization.VendedorSuporte__r.IsActive != null && !usersIdsInTerritory.contains(sectorization.VendedorSuporte__c)) {
                            // (ñ) criar associação com o territorio
                            associationsToCreate.add(ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(thirdLayerTerritory,sectorization.VendedorSuporte__c,'Vendedor Suporte'));
                            usersIdsInTerritory.add(sectorization.VendedorSuporte__c);
                        }

                        mapTerritoryToUserIds.get(thirdLayerTerritory.DeveloperName).addAll(usersIdsInTerritory);
                    }
                }
            }
        }

        if (associationsToCreate.size() > 0) {Database.insert(associationsToCreate, false);}
    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {Eventbus.publish(new ProcessActingTable__e(Type__c = 'associate_account_without_setorizacao',ExecuteNextProcesses__c = true));}
    }
}
