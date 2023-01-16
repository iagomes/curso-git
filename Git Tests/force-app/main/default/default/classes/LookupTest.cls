@IsTest
public with sharing class LookupTest {
    @IsTest
    public static void getRecordsTest() {
        Account account = TestUtility.createAccount();
        insert account;
        Order order = TestUtility.createOrder(account);
        insert order;
        String str = '{"searchFields" : ["OrderItemNumber"], "targetObject" : "OrderItem", "relations" : [{"parentRelationField" : "OrderId", "parentRecordId" : "' + order.Id + '"}]}';

        System.assertNotEquals(null, Lookup.getRecords(str), 'getRecordsTest');
    }
}