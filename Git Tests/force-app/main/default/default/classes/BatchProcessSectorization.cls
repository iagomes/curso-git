public class BatchProcessSectorization implements Database.Batchable<SObject> {
    public Boolean callNextProcess = false;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT 
                Id,
                Conta__c,
                Vendedor__c,
                CodigoMesa__c,
                Mesa__c,
                Regiao__c,
                Categoria__c,
                TOLABEL(Categoria__c) CategoriaLabel
            FROM Setorizacao__c WHERE CodigoMesa__c != null AND Regiao__c != null AND Categoria__c != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Setorizacao__c> scope) {
        Territory2Model territoryModel = ActingTableTerritoryManagement.getTerritory2Model('Mesas');
        Territory2Type territoryType = ActingTableTerritoryManagement.getTerritory2Type('Mesas');

        if (territoryModel != null || territoryType != null) {
            Set<String> existingTerritoriesSet = new Set<String>();
            existingTerritoriesSet.addAll(ActingTableTerritoryManagement.getAllTerritoriesDeveloperNameMap().keySet());

            List<Territory2> firstLayerTerritories = new List<Territory2>();
            List<Territory2> secondLayerTerritories = new List<Territory2>();
            List<Territory2> thirdLayerTerritories = new List<Territory2>();
        
            for (Setorizacao__c currSectorization : scope) {
                String firstLayerKey = 'M'+ currSectorization.CodigoMesa__c;
                String secondLayerKey = firstLayerKey + '_' + currSectorization.Categoria__c;
                String thirdLayerLayerKey = secondLayerKey + '_' + currSectorization.Regiao__c;

                // create 1st layer
                if (!existingTerritoriesSet.contains(firstLayerKey) && currSectorization.CodigoMesa__c != null) {
                    Territory2 firstLayerObject = ActingTableTerritoryManagement.createFirstLayerTerritoryObject(
                        territoryModel,
                        territoryType,
                        currSectorization
                    );

                    firstLayerTerritories.add(firstLayerObject);
                    existingTerritoriesSet.add(firstLayerObject.DeveloperName);
                }

                // create 2nd layer
                if (!existingTerritoriesSet.contains(secondLayerKey) && currSectorization.Categoria__c != null) {
                    Territory2 secondLayerObject = ActingTableTerritoryManagement.createSecondLayerTerritoryObject(
                        territoryModel,
                        territoryType,
                        currSectorization
                    );

                    secondLayerTerritories.add(secondLayerObject);
                    existingTerritoriesSet.add(secondLayerObject.DeveloperName);
                }

                // create 3rd layer
                if (!existingTerritoriesSet.contains(thirdLayerLayerKey) && currSectorization.Regiao__c != null) {
                    Territory2 thirdLayerObject = ActingTableTerritoryManagement.createThirdLayerTerritoryObject(
                        territoryModel,
                        territoryType,
                        currSectorization
                    );

                    thirdLayerTerritories.add(thirdLayerObject);
                    existingTerritoriesSet.add(thirdLayerObject.DeveloperName);
                } 
            }

            // three inserts for same object, because "upsert" doesn't exists for territory2 object.
            // and parents territories MUST exist before to insert children, for association purpose.
            if (firstLayerTerritories.size() > 0) {
                insert firstLayerTerritories;
            }

            if (secondLayerTerritories.size() > 0) {
                insert secondLayerTerritories;
            }
            
            if (thirdLayerTerritories.size() > 0) {
                insert thirdLayerTerritories;
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {
            Eventbus.publish(new ProcessActingTable__e(
                Type__c = 'associate_accounts',
                ExecuteNextProcesses__c = true
            ));
        }
    }
}