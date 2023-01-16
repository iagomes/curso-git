@isTest
public class ProductShelfLifeControllerTest {
    
    @isTest
    public static void testGetLotes() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.ProductCode = '1001';
        insert product;

        Integracoes__c integrationConfig = new Integracoes__c(
			Name        = 'InformaticaConsultaLotes',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        
        insert integrationConfig;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Lotes'));
        ProductShelfLifeController.getLotes(account.CNPJ__c, product.ProductCode);
        Test.stopTest();
    }
}