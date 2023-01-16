@isTest
public with sharing class BatchStockEmailsTest {
    @TestSetup
    static void makeData(){
        Account account = TestUtility.createAccPJ();
        insert account;
        Product2 product = TestUtility.createProductToStock();
        insert product;
        Order order = TestUtility.createOrder(account);
        order.PedidoPendente__c = true;
        order.Status = 'Em digitação';
        insert order;
        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, pricebookEntry.UnitPrice FROM PricebookEntry WHERE Product2Id =: product.Id][0];
        OrderItem orderItem = TestUtility.createOrderItem(order, product, pricebookEntry);
        orderItem.ItemPendente__c = true;
        insert orderItem;
        Estoque__c stock = TestUtility.createStock(product.ExternalId__c, product.Id);
        insert stock;
    }
    
    @isTest
    public static void BatchStockEmails() {
        BatchStockEmailsSchedule batchSchedule = new BatchStockEmailsSchedule();
        batchSchedule.execute(null);
        BatchStockEmailsSchedule.scheduleBatch();
    }
}
