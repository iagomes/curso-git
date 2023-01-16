@IsTest
public with sharing class BatchResendOrderTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Order order = TestUtility.createOrder(acc);
        insert order;

        order.ErroIntegracaoRejeitado__c = true;
        update order;

        Integracoes__c integration = TestUtility.createCustomSettingApproval();
        insert integration;
    }
    
    @isTest
    public static void BatchResendOrder() {
        BatchResendOrderSchedule batchSchedule = new BatchResendOrderSchedule();
        batchSchedule.execute(null);
        BatchResendOrderSchedule.scheduleBatch();
    }
}