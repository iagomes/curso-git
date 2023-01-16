public with sharing class BatchAssociateAccountsInActingTables implements Database.Batchable<SObject> {
    public Boolean callNextProcess = false;
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT
                Id,
                Conta__c,
                CodigoMesa__c,
                Categoria__c,
                Regiao__c
            FROM Setorizacao__c WHERE CodigoMesa__c != null AND Regiao__c != null AND Categoria__c != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Setorizacao__c> scope) {
        // check if association x territory already exists.
        Set<String> scopeAccAlreadyAssociate = new Set<String>();
        Set<Id> setAccIdsToCheckInExistingAssociations = new Set<Id>();

        Map<Id, Set<Id>> mapAccIdToUserSetId = new Map<Id, Set<Id>>();

        for (Setorizacao__c sectorization : scope) {
            if (sectorization.Conta__c != null) {
                setAccIdsToCheckInExistingAssociations.add(sectorization.Conta__c);
            }
        }
        
        List<ObjectTerritory2Association> existingAssociationsList = ActingTableTerritoryManagement.getAllObjectAssociationsByAccountIds(setAccIdsToCheckInExistingAssociations);
        
        for (ObjectTerritory2Association existingAssociation : existingAssociationsList) {
            String customKey = 
                existingAssociation.Territory2.DeveloperName + 
                existingAssociation.ObjectId;

            if (!scopeAccAlreadyAssociate.contains(customKey)) {
                scopeAccAlreadyAssociate.add(customKey);
            }
        }

        List<ObjectTerritory2Association> AccountsToAssociate = new List<ObjectTerritory2Association>();
        
        Map<String, Territory2> allTerritoriesDeveloperNameMap = ActingTableTerritoryManagement.getAllTerritoriesDeveloperNameMap();

        for (Setorizacao__c sectorization : scope) {
            String developerNameKey = ActingTableTerritoryManagement.getDeveloperNameKey(sectorization, true);
            Territory2 territoryForAssociation;

            if (!allTerritoriesDeveloperNameMap.containsKey(developerNameKey)) {
                continue;
            } else {
                territoryForAssociation = allTerritoriesDeveloperNameMap.get(developerNameKey);
            }

            if (!scopeAccAlreadyAssociate.contains(developerNameKey+sectorization.Conta__c)) {
                AccountsToAssociate.add(
                    ActingTableTerritoryManagement.createAccountAssociationForActingTableTerritory(
                        territoryForAssociation,
                        sectorization.Conta__c
                    )
                );
                scopeAccAlreadyAssociate.add(developerNameKey+sectorization.Conta__c);
            }
        }

        if (AccountsToAssociate.size() > 0) {
            insert AccountsToAssociate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {
            Eventbus.publish(new ProcessActingTable__e(
                Type__c = 'delete_associate_users',
                ExecuteNextProcesses__c = true
            ));
        }
    }
}
