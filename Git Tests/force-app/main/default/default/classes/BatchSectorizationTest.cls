@isTest
public with sharing class BatchSectorizationTest {

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;
        User us = TestUtility.createUser();
        insert us;
        Setorizacao__c setorizacao = TestUtility.createSetorizacaoWithInvalidData(acc, us);
        insert setorizacao;
    } 
    
    @isTest
    public static void BatchSectorization() {
        BatchSectorizationSchedule batchSchedule = new BatchSectorizationSchedule();
        batchSchedule.execute(null);
        BatchSectorizationSchedule.scheduleBatch();
    }
}