/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.soares@apllos.com
 * @linkedin          : https://www.linkedin.com/in/raphaelsoares95/
 * @company           : Apllos Solutions
 * @last modified on  : 30-06-2021
 * @last modified by  : raphael.soares@apllos.com
 * Modifications Log 
 * Ver   Date         Author                      Modification
 * 1.0   30-06-2021   raphael.soares@apllos.com   Initial Version
**/
@isTest
public class PageLayoutControllerTest {

    @isTest
    public static void pageLayoutControllerTest() {

        Test.startTest();

            StandardResponse response = PageLayoutController.getLayoutByName('Opportunity-Opportunity Layout');
            System.assertEquals('200', response.code);
            

            StandardResponse response2 = PageLayoutController.getLayoutByName('');
            System.assertEquals('500', response2.code);

            StandardResponse response3 = PageLayoutController.getLayoutByName('Layout not found');
            System.assertEquals('500', response3.code);

        Test.stopTest();
    }
}