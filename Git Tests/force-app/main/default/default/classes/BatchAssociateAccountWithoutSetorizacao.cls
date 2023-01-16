public with sharing class BatchAssociateAccountWithoutSetorizacao implements Database.Batchable<SObject> {
    
    
    public Boolean callNextProcess = false;
    public Set<String> setRecorType = new Set<String>{'PessoaFisica', 'PessoaJuridica'};
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT 
                Id, 
                CodigoRegiao__c 
                FROM Account 
                WHERE RecordType.DeveloperName IN:setRecorType 
                AND Id NOT IN (SELECT Conta__c FROM Setorizacao__c)
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
     
        Set<String> setCodigoRegiao = new Set<String>();
        Map<String,List<Account>> mapAccxRegiao = new Map<String,List<Account>>();
        List<ObjectTerritory2Association> associationsToCreate = new List<ObjectTerritory2Association>();

        for (Account acc : scope) {

            if (acc.CodigoRegiao__c != null) {
                
                setCodigoRegiao.add(acc.CodigoRegiao__c);

                if (!mapAccxRegiao.containsKey(acc.CodigoRegiao__c)) {                    
                    mapAccxRegiao.put(acc.CodigoRegiao__c, new List<Account>{acc});

                }else{
                    mapAccxRegiao.get(acc.CodigoRegiao__c).add(acc);
                }
            }
          
        }

        if (setCodigoRegiao.size() > 0) {

            List<Territory2> lstTerritory2 = [SELECT Id,Regiao__c FROM Territory2 WHERE Regiao__c IN: setCodigoRegiao];
          
            if (lstTerritory2.size() > 0) {

                for (Territory2 territory : lstTerritory2) {

                    if (mapAccxRegiao.containsKey(territory.Regiao__c)) {
                        
                        for(Account acc : mapAccxRegiao.get(territory.Regiao__c)){
                            ObjectTerritory2Association accAssociation = new ObjectTerritory2Association(
                                Territory2Id = territory.Id,
                                ObjectId = acc.Id,
                                AssociationCause = 'Territory2Manual'
                            );
                            associationsToCreate.add(accAssociation);
                        }                        
                        
                    }                    
                }
                
            }
            
        }
        
        System.debug(associationsToCreate.size());
        if (associationsToCreate.size() > 0) {
            System.debug(associationsToCreate);
            Database.insert(associationsToCreate, false);
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {
            Eventbus.publish(new ProcessActingTable__e(
                Type__c = 'revalidate_approval_associations',
                ExecuteNextProcesses__c = true
            ));
        }
    }

}