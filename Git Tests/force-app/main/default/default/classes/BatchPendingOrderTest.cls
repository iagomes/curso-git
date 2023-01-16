@isTest
public with sharing class BatchPendingOrderTest {

    @TestSetup
    static void makeData(){
        Account account = TestUtility.createAccPJ();
        insert account;
        Product2 product = TestUtility.createProduct();
        insert product;
        Order order = TestUtility.createOrder(account);
        order.PedidoPendente__c = true;
        order.Status            = 'Em digitação';
        insert order;
    }
    
    @isTest
    public static void BatchPendingOrder() {
        BatchPendingOrderSchedule batchSchedule = new BatchPendingOrderSchedule();
        batchSchedule.execute(null);
        BatchPendingOrderSchedule.scheduleBatch();
    }
}