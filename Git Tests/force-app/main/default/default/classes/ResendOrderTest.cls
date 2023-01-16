@IsTest
public with sharing class ResendOrderTest {
    @IsTest
    public static void resendOrderToTOTVSTest() {
        List<Id> orderIdList    = new List<Id>();
        
        Account account = TestUtility.createAccPJ();
        insert account;
        Order order     = TestUtility.createOrder(account);
        insert order;

        orderIdList.add(order.Id);

        System.assertEquals(null, ResendOrder.resendOrderToTOTVS(orderIdList), 'resendOrderToTOTVSTest');
    }
}