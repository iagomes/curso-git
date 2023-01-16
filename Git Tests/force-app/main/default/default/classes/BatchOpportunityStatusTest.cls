@isTest
public with sharing class BatchOpportunityStatusTest {

    @TestSetup
    static void makeData(){
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();

        Account acc = TestUtility.createAccPJ();
        insert acc;
        User us = TestUtility.createUser();
        insert us;
        Setorizacao__c setorizacao = TestUtility.createSetorizacaoWithValidData(acc, us);
        insert setorizacao;
        Opportunity opportunity    = TestUtility.createOpportunity(us);
        opportunity.StageName = 'Novo';
        opportunity.DataVencimento__c = Datetime.now().addDays(-1);
        opportunity.RecordTypeId = recordTypeId;
        insert opportunity;
        Opportunity opportunity2   = TestUtility.createOpportunityTwo(us);
        opportunity2.StageName = 'Respondida';
        opportunity2.DataVencimento__c = Datetime.now().addDays(-11);
        
        opportunity.RecordTypeId = recordTypeId;
        insert opportunity2; 
    }
    
    @isTest
    public static void BatchOpportunityStatus() {
        BatchOpportunityStatusSchedule batchSchedule = new BatchOpportunityStatusSchedule();
        Test.startTest();
        batchSchedule.execute(null);
        BatchOpportunityStatusSchedule.scheduleBatch();
        BatchOpportunityStatus batchStatus = new BatchOpportunityStatus();
        Database.executeBatch(batchStatus);
        Test.stopTest();
    }
}