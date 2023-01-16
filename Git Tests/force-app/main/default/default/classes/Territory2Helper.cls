public with sharing class Territory2Helper {
    public Territory2Helper() {}

    public static void associateParentTerritories(List<Territory2> newRecords) {
        Territory2Model territoryModel = ActingTableTerritoryManagement.getTerritory2Model('Mesas');
        Territory2Type territoryType = ActingTableTerritoryManagement.getTerritory2Type('Mesas');

        List<Territory2> territoriesToAssociateParents = new List<Territory2>();
        
        for (Territory2 territory : newRecords) {
            // Only territories that should be associate with parents.
            // Should have at least the field "category" different of null to be a child territory.
            if (
                territory.Territory2ModelId == territoryModel.Id &&
                territory.Territory2TypeId == territoryType.Id &&
                territory.Categoria__c != null
            ) {
                territoriesToAssociateParents.add(territory);
            }
        }

        if (territoriesToAssociateParents.size() > 0) {
            Map<String, Territory2> existingTerritories = ActingTableTerritoryManagement.getAllParentTerritoriesDeveloperNameMap();
            
            for (Territory2 territoryToAssociate : territoriesToAssociateParents) {
                // for 2nd leyer
                String parentDeveloperName = 'M' + territoryToAssociate.CodigoMesa__c;
                
                if (territoryToAssociate.Regiao__c != null) {
                    // for 3rd leyer
                    parentDeveloperName += '_' + territoryToAssociate.Categoria__c; 
                }

                if (existingTerritories.containsKey(parentDeveloperName)) {
                    Territory2 parentTerritory = existingTerritories.get(parentDeveloperName);
                    territoryToAssociate.ParentTerritory2Id = parentTerritory.Id;
                }
            }
        }
    }
}
