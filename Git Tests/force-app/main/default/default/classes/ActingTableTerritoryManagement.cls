/**
 * @description Hello World
 */
public with sharing class ActingTableTerritoryManagement {

    /**
     * @description Bar
     * @return Bar
     */
    public static Territory2Model getTerritory2Model(String developerName) {
        return [SELECT Id FROM Territory2Model WHERE DeveloperName =: developerName LIMIT 1];
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Territory2Type getTerritory2Type(String developerName) {
        return [SELECT Id FROM Territory2Type WHERE DeveloperName =: developerName LIMIT 1];
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Map<String, Territory2> getAllParentTerritoriesDeveloperNameMap() {
        Map<String, Territory2> territoriesMap = new Map<String, Territory2>();
        
        List<Territory2> territoriesList = [
            SELECT
                Id,
                DeveloperName,
                CodigoMesa__c,
                Categoria__c
            FROM Territory2
            WHERE Regiao__c = NULL
        ];

        for (Territory2 territory : territoriesList) {
            territoriesMap.put(territory.DeveloperName, territory);
        }

        return territoriesMap;
    }
    
    /**
     * @description Bar
     * @return Bar
     */
    public static Map<String, Territory2> getAllTerritoriesDeveloperNameMap() {
        Map<String, Territory2> territoriesByDaveloperNamesMap = new Map<String, Territory2>(); 
        
        List<Territory2> territories = [
            SELECT
                Id,
                DeveloperName,
                CodigoMesa__c,
                Categoria__c,
                Regiao__c
            FROM Territory2
        ];

        for (Territory2 currTerritory : territories) {
            territoriesByDaveloperNamesMap.put(
                currTerritory.DeveloperName,
                currTerritory
            );
        }

        return territoriesByDaveloperNamesMap;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Map<String, Territory2> getThirdLayerTerritoriesDeveloperNameMap() {
        Map<String, Territory2> territoriesByDaveloperNamesMap = new Map<String, Territory2>(); 
        
        List<Territory2> territories = [
            SELECT
                Id,
                DeveloperName,
                CodigoMesa__c,
                Categoria__c,
                Regiao__c
            FROM Territory2
            WHERE Regiao__c != NULL
        ];

        for (Territory2 currTerritory : territories) {
            territoriesByDaveloperNamesMap.put(
                currTerritory.DeveloperName,
                currTerritory
            );
        }

        return territoriesByDaveloperNamesMap;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Territory2 createFirstLayerTerritoryObject(
        Territory2Model territoryModel, 
        Territory2Type territoryType, 
        Setorizacao__c sectorization
    ) {
        Territory2 territory = createBasicTerritoryForSectorization(territoryModel, territoryType);

        territory.DeveloperName += sectorization.CodigoMesa__c;
        territory.Name = sectorization.CodigoMesa__c + ' | ' + sectorization.Mesa__c;
        territory.CodigoMesa__c = sectorization.CodigoMesa__c;

        return territory;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Territory2 createSecondLayerTerritoryObject(
        Territory2Model territoryModel, 
        Territory2Type territoryType, 
        Setorizacao__c sectorization
    ) {
        Territory2 territory = createBasicTerritoryForSectorization(territoryModel, territoryType);

        String developerName = sectorization.CodigoMesa__c + '_' + sectorization.Categoria__c;

        String categoryLabel = sectorization.get('CategoriaLabel') != null 
            ? (String) sectorization.get('CategoriaLabel')
            : sectorization.Categoria__c;

        territory.DeveloperName += developerName;
        territory.Name = categoryLabel;
        territory.CodigoMesa__c = sectorization.CodigoMesa__c;
        territory.Categoria__c  = sectorization.Categoria__c;

        return territory;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static Territory2 createThirdLayerTerritoryObject(
        Territory2Model territoryModel, 
        Territory2Type territoryType,
        Setorizacao__c sectorization
    ) {
        Territory2 territory = createBasicTerritoryForSectorization(territoryModel, territoryType);

        String developerName = sectorization.CodigoMesa__c + '_' + sectorization.Categoria__c + '_' + sectorization.Regiao__c;
            
        territory.DeveloperName += developerName;
        territory.AccountAccessLevel = 'Edit';
        territory.OpportunityAccessLevel = 'Edit';
        territory.CaseAccessLevel = 'Read';
        territory.Name = sectorization.Regiao__c;
        territory.CodigoMesa__c = sectorization.CodigoMesa__c;
        territory.Categoria__c = sectorization.Categoria__c;
        territory.Regiao__c = sectorization.Regiao__c;

        return territory;
    }


    /**
     * @description Bar
     * @return Bar
     */
    private static Territory2 createBasicTerritoryForSectorization(
        Territory2Model territoryModel, 
        Territory2Type territoryType
    ) {
        String developerNamePrefix = 'M';
        Territory2 territory = new Territory2(
            DeveloperName = developerNamePrefix,
            Territory2ModelId = territoryModel.Id,
            Territory2TypeId = territoryType.Id
        );

        return territory;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static UserTerritory2Association createUserAssociationForActingTableTerritory(
        Territory2 territory,
        Id userId,
        String roleInTerritory
    ) {
        UserTerritory2Association userAssociation = new UserTerritory2Association(
            Territory2Id = territory.Id,
            UserId = userId
        );

        if (roleInTerritory != null) {
            userAssociation.RoleInTerritory2 = roleInTerritory;
        }

        return userAssociation;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static GroupMember createUserAssociationForActingTableGroup(
        Id groupId,
        Id userId
    ) {
        GroupMember userAssociation = new GroupMember(
            GroupId = groupId,
            UserOrGroupId = userId
        );

        return userAssociation;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static List<UserTerritory2Association> getAllUsersAssociationsByUserIds(
        Set<Id> userIds
    ) {
        return [
            SELECT
                Id,
                UserId,
                Territory2Id,
                Territory2.DeveloperName,
                RoleInTerritory2
            FROM UserTerritory2Association
            WHERE UserId IN: userIds
        ];
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static ObjectTerritory2Association createAccountAssociationForActingTableTerritory(Territory2 territory, Id accountId) {
        ObjectTerritory2Association accAssociation = new ObjectTerritory2Association(
            Territory2Id = territory.Id,
            ObjectId = accountId,
            AssociationCause = 'Territory2Manual'
        );

        return accAssociation;
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static List<ObjectTerritory2Association> getAllObjectAssociationsByAccountIds(Set<Id> accountIds) {
        return [
            SELECT
                Id,
                ObjectId,
                SobjectType,
                Territory2Id,
                Territory2.DeveloperName
            FROM ObjectTerritory2Association
            WHERE ObjectId IN: accountIds
        ];
    }

    /**
     * @description Bar
     * @return Bar
     */
    public static String getDeveloperNameKey(Setorizacao__c sectorizationData, Boolean withPrefix) {
        String developerNameKey = withPrefix ? 'M' : '';

        if (sectorizationData.CodigoMesa__c != null) {
            developerNameKey += sectorizationData.CodigoMesa__c;
        }

        if (sectorizationData.Categoria__c != null) {
            developerNameKey += '_' + sectorizationData.Categoria__c;
        }

        if (sectorizationData.Regiao__c != null) {
            developerNameKey += '_' + sectorizationData.Regiao__c;
        }

        return developerNameKey;
    }
}
