public without sharing class ResponsabilidadeAprovacaoHelper {

    public static final String ROLE_IN_TERRITORY = 'Responsabilidade Aprovação';
    
    public static void createUserTerritoryAssiciation(Map<Id, ResponsabilidadeAprovacao__c> newMap) {
        Set<Id> responsibleUsersIds = new Set<Id>();
        
        for (ResponsabilidadeAprovacao__c currResponsibleUser : newMap.values()) {
            responsibleUsersIds.add(currResponsibleUser.UsuarioAprovador__c);
        }
        
        revalidateAssociationsAsync(responsibleUsersIds);
    }

    public static void deleteUserTerritoryAssiciation(List<ResponsabilidadeAprovacao__c> oldRecords) {
        Set<Id> responsibleUsersIds = new Set<Id>();
        
        for (ResponsabilidadeAprovacao__c currResponsibleUser : oldRecords) {
            responsibleUsersIds.add(currResponsibleUser.UsuarioAprovador__c);
        }
        
        revalidateAssociationsAsync(responsibleUsersIds);
    }

    @future()
    public static void revalidateAssociationsAsync(Set<Id> responsibleUsersIds) {
        List<ResponsabilidadeAprovacao__c> newRecords = [
            SELECT 
                UsuarioAprovador__c,
                CodigoMesa__c,
                Regiao__c,
                Categorias__c
            FROM ResponsabilidadeAprovacao__c
            WHERE UsuarioAprovador__c IN: responsibleUsersIds
        ];

        // Reset user territory associations (only for approvers)
        delete [
            SELECT Id
            FROM UserTerritory2Association
            WHERE UserId IN: responsibleUsersIds
            AND RoleInTerritory2 =: ROLE_IN_TERRITORY
        ];
        
        Map<String, Territory2> mapAllTerritories =
            ActingTableTerritoryManagement.getThirdLayerTerritoriesDeveloperNameMap();

        system.debug(mapAllTerritories);
        Map<Id, Set<String>> mapUserAssociations = new Map<Id, Set<String>>();

        List<UserTerritory2Association> responsibleUsersAssociations =
            ActingTableTerritoryManagement.getAllUsersAssociationsByUserIds(responsibleUsersIds);

        for (UserTerritory2Association currAssociation : responsibleUsersAssociations) {
            if (!mapUserAssociations.containsKey(currAssociation.UserId)) {
                mapUserAssociations.put(
                    currAssociation.UserId,
                    new Set<String>()
                );
            }
            
            mapUserAssociations
                .get(currAssociation.UserId)
                .add(currAssociation.Territory2.DeveloperName);
        }

        List<UserTerritory2Association> newAssociations = new List<UserTerritory2Association>();

        for (ResponsabilidadeAprovacao__c currResponsibleUser : newRecords) {
            Id userId = currResponsibleUser.UsuarioAprovador__c;
            String actingTable = currResponsibleUser.CodigoMesa__c;
            String region = currResponsibleUser.Regiao__c;
            List<String> categories = 
                currResponsibleUser.Categorias__c != null
                ? currResponsibleUser.Categorias__c.split(';')
                : null;
            
            for (Territory2 currTerritory : mapAllTerritories.values()) {

                if (!mapUserAssociations.containsKey(userId)) {
                    mapUserAssociations.put(
                        userId,
                        new Set<String>()
                    );
                }

                if (mapUserAssociations.get(userId).contains(currTerritory.DeveloperName)) {
                    continue;
                }

                if (actingTable == null && categories == null && region == null) {
                    UserTerritory2Association userAssociation = 
                        ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                            currTerritory,
                            userId,
                            ROLE_IN_TERRITORY
                        );
                    if (userId != null) {
                        newAssociations.add(userAssociation);
                    }
                    
                    mapUserAssociations
                        .get(userId)
                        .add(currTerritory.DeveloperName);

                } else if (actingTable != null && categories != null && region != null) {
                    if (
                        currTerritory.CodigoMesa__c == actingTable &&
                        categories.contains(currTerritory.Categoria__c) &&
                        currTerritory.Regiao__c == region
                    ) {
                        UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                    }
                } else if (actingTable != null && categories != null && region == null) {
                    if (
                        currTerritory.CodigoMesa__c == actingTable &&
                        categories.contains(currTerritory.Categoria__c)
                    ) {
                        UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                    }
                } else if (actingTable != null && categories == null && region != null) {
                    if (
                        currTerritory.CodigoMesa__c == actingTable &&
                        currTerritory.Regiao__c == region
                    ) {
                        UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                    }
                } else if (actingTable == null && categories != null && region != null) {
                    if (
                        categories.contains(currTerritory.Categoria__c) &&
                        currTerritory.Regiao__c == region
                    ) {
                        UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                    }
                } else if (actingTable != null && currTerritory.CodigoMesa__c == actingTable) {
                    UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                } else if (categories != null && categories.contains(currTerritory.Categoria__c)) {
                    UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                } else if (region != null && currTerritory.Regiao__c == region) {
                    UserTerritory2Association userAssociation = 
                            ActingTableTerritoryManagement.createUserAssociationForActingTableTerritory(
                                currTerritory,
                                userId,
                                ROLE_IN_TERRITORY
                            );
                        if (userId != null) {
                            newAssociations.add(userAssociation);
                        }
                        
                        mapUserAssociations
                            .get(userId)
                            .add(currTerritory.DeveloperName);
                }
            }
        }

        system.debug(newAssociations);
        if (!newAssociations.isEmpty()) {
            insert newAssociations;
        }
    }
}
