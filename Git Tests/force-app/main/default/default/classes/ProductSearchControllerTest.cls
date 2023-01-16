@IsTest
public with sharing class ProductSearchControllerTest {

    @IsTest
    public static void testgetLookupRecords() {
        try {
            Pricebook2 pricebook = new Pricebook2(
                Name = 'Pricebook Test',
                ExternalId__c = 'B01'
            );
            insert pricebook;
    
            Product2 product = TestUtility.createProduct();
            product.FatorConversao__c = '1';
            product.CategoriaComercial__c = 'teste';
            product.Description = 'teste';
            product.Name = 'teste';
            product.UnidadeMedida__c = 'un';
            product.ProductCode = 'teste';
            insert product;
    
            PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
            pricebookEntry.PrecoFabrica__c = 123;
            pricebookEntry.ExternalId__c = 'teste';
            pricebookEntry.UnitPrice = 123;
            insert pricebookEntry;
    
            Account account = TestUtility.createAccPJ();
            account.CodigoCliente__c = '0168444';
            account.CodigoGrupoClientes__c = '000001';
            insert account;
    
            Opportunity opportunity = new Opportunity(
                Name = 'Opportunity Test',
                StageName = 'Novo',
                CloseDate = Date.today().addDays(10),
                AccountId = account.Id,
                Pricebook2Id = pricebook.Id
            );
            insert opportunity;
    
    
            Test.startTest();
    
                String[] fieldNames = new String[]{'Name', 'BillingCity'};
                String[] lookupSelectFields = new String[]{'GrupoCliente__c', 'BillingCity'};
                pricebookEntry.Product2 = product;
                ProductSearchController.Product prod = new ProductSearchController.Product(pricebookEntry, 12);
                
                ProductSearchController.getLookupRecords('Lectrum', opportunity.Id);
            Test.stopTest();
        } catch(Exception e) {
            System.debug(e);
        }
        
    }

    
}