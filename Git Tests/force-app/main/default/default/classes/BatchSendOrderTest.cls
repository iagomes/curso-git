@IsTest
public with sharing class BatchSendOrderTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Order order = TestUtility.createOrder(acc);
        insert order;

        Product2 product = TestUtility.createProduct();
        insert product;

        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id =: product.Id];
        OrderItem orderItem = TestUtility.createOrderItem(order, product, pricebookEntry);
        orderItem.PrecoTotal__c = 100;
        insert orderItem;
        
        Integracoes__c integration = TestUtility.createCustomSettingOrder();
        insert integration;
    }
    
    @isTest
    public static void BatchSendOrder() {
        Set<Id> orderIdSet = new Set<Id>();
        for (Order order : [SELECT Id FROM Order]) {
            orderIdSet.add(order.Id);
        }

        BatchSendOrder.run(orderIdSet);
    }
}