@isTest
public with sharing class ProductHelperTest {

    @isTest
    public static void createStandardEntriesTest() {
        Product2 prod = TestUtility.createProduct();
        insert prod;

        prod.Name = 'Test Name';
        
        update prod;

        delete prod;
    }
    
    @isTest
    public static void ProductHelperTest() {
        system.debug(ProductHandler.enableTrigger());
        system.debug(ProductHandler.disableTrigger());
        System.assertEquals(true, ProductHandler.enableTrigger());
        System.assertEquals(false, ProductHandler.disableTrigger());
    }
}
