@isTest
public with sharing class BatchOpportunityTest {

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;
        User us = TestUtility.createUser();
        insert us;
        Setorizacao__c setorizacao = TestUtility.createSetorizacaoWithValidData(acc, us);
        insert setorizacao;
        Opportunity opportunity    = TestUtility.createOpportunity(us);
        insert opportunity;
        Opportunity opportunity2   = TestUtility.createOpportunityTwo(us);
        insert opportunity2; 
    }
    
    @isTest
    public static void BatchOpportunity() {
        BatchOpportunitySchedule batchSchedule = new BatchOpportunitySchedule();
        batchSchedule.execute(null);
        BatchOpportunitySchedule.scheduleBatch();
    }
}