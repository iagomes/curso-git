public with sharing class BatchDeleteAssociateUsersTerritory implements Database.Batchable<SObject> {
    
    public Boolean callNextProcess = false;
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT
                Id
            FROM UserTerritory2Association
        ]);
    }

    public void execute(Database.BatchableContext BC, List<UserTerritory2Association> scope) {

        if (scope.size() > 0) {
            
            System.debug(scope);
            Database.delete(scope, false);
        }

    }

    public void finish(Database.BatchableContext BC) {
        if (callNextProcess) {
            Eventbus.publish(new ProcessActingTable__e(
                Type__c = 'associate_users',
                ExecuteNextProcesses__c = true
            ));
        }
    }
}
