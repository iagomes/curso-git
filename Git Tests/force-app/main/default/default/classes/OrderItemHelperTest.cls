@isTest
public with sharing class OrderItemHelperTest {
    @TestSetup
    static void makeData(){
        
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact contact = TestUtility.createContact(acc);
        insert contact;
        
        CondicaoPagamento__c conditionPayment = TestUtility.createConditionPayment();
        insert conditionPayment;
        
        Opportunity opp = TestUtility.createOpportunity(acc, contact, conditionPayment);
        insert opp;
        
        QuoteItem__c qItem = TestUtility.createQuoteItem(opp, new User(Id = UserInfo.getUserId()));
        insert qItem;

        PriceBook2 pricebook2 = TestUtility.createPricebook2();
        insert pricebook2;
        
        Order order = TestUtility.createOrder(acc);
        order.OpportunityId = opp.Id;
        order.Pricebook2Id = pricebook2.id;
        insert order;
        
        Product2 product = TestUtility.createProduct();
        insert product;

        PricebookEntry pbEntry = TestUtility.createPricebookEntry(pricebook2.id, product.id);
        insert pbEntry;
        
        OrderItem orderItem = TestUtility.createOrderItem(order, product, pbEntry);
        insert orderItem;
        
    }
    @isTest
    public static void orderItemTriggerVerify(){
        List<OrderItem> ordItem = [SELECT Id FROM OrderItem];
        OrderItemHandler.disableTrigger();
        OrderItemHandler.enableTrigger();

        update ordItem;
    }
}
