@IsTest
public with sharing class BatchSendApprovalOrderTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Order order = TestUtility.createOrder(acc);
        insert order;
        
        Integracoes__c integration = TestUtility.createCustomSettingApproval();
        insert integration;
    }
    
    @isTest
    public static void BatchSendApprovalOrder() {
        Set<Id> orderIdSet = new Set<Id>();
        for (Order order : [SELECT Id FROM Order]) {
            orderIdSet.add(order.Id);
        }

        BatchSendApprovalOrder.run(orderIdSet);
    }
}