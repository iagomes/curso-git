public without sharing class ProcessActingTableHelper {
    
    public static void handleProcessType(List<ProcessActingTable__e> newRecordList) {
        // aceitando apenas uma chamada por vez.
        ProcessActingTable__e event = newRecordList[0];
        Integer batchSize = 200;

        switch on event.Type__c {
            when 'create_territory' {
                BatchProcessSectorization processSectorizationBatch = new BatchProcessSectorization();
                processSectorizationBatch.callNextProcess = event.ExecuteNextProcesses__c;

                if (!Test.isRunningTest()) {
                    Database.executeBatch(processSectorizationBatch, batchSize);
                }
            }

            when 'associate_accounts' {
                BatchAssociateAccountsInActingTables accountProcessBatch = new BatchAssociateAccountsInActingTables();
                accountProcessBatch.callNextProcess = event.ExecuteNextProcesses__c;
                
                if (!Test.isRunningTest()) {
                    Database.executeBatch(accountProcessBatch, batchSize);
                }
            }

            when 'delete_associate_users' {
                BatchDeleteAssociateUsersTerritory deleteAssociateUsersBatch = new BatchDeleteAssociateUsersTerritory();
                deleteAssociateUsersBatch.callNextProcess = event.ExecuteNextProcesses__c;
                
                if (!Test.isRunningTest()) {
                    Database.executeBatch(deleteAssociateUsersBatch, batchSize);
                }
            }

            when 'associate_users' {
                BatchAssociateUsersInActingTables associateUsersBatch = new BatchAssociateUsersInActingTables();
                associateUsersBatch.callNextProcess = event.ExecuteNextProcesses__c;
                
                if (!Test.isRunningTest()) {
                    Database.executeBatch(associateUsersBatch, batchSize);
                }
            }

            when 'associate_users_without_acting_table' {
                BatchAssociateUsersWithoutActingTables associateUsersBatch = new BatchAssociateUsersWithoutActingTables();
                associateUsersBatch.callNextProcess = event.ExecuteNextProcesses__c;
                
                if (!Test.isRunningTest()) {
                    Database.executeBatch(associateUsersBatch, batchSize);
                }
            }

            when 'associate_account_without_setorizacao' {
                BatchAssociateAccountWithoutSetorizacao associateAccountRegiaoBatch = new BatchAssociateAccountWithoutSetorizacao();
                associateAccountRegiaoBatch.callNextProcess = event.ExecuteNextProcesses__c;
                
                if (!Test.isRunningTest()) {
                    Database.executeBatch(associateAccountRegiaoBatch, batchSize);
                }
            }

            when 'revalidate_approval_associations' {
                System.enqueueJob(new QueueRevalidateUserApprovalAssociations());
            }

           

            when else {
                System.debug('No event type match.');
            }
        }
    }
}
