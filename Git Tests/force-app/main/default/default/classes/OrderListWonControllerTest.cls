@IsTest
public class OrderListWonControllerTest {
    @IsTest
    static void getOrdersListWonFromCurrentUserTest(){
        StandardResponse stdResponse = OrderListWonController.getOrdersListWonFromCurrentUser();
        System.assert(stdResponse != null, 'Not null');
    }
}