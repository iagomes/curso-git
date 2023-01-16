@isTest
public with sharing class EstoqueHelperTest {
    @isTest
    public static void EstoqueHelperTest() {
        
        GeneralParameters__c parameters = new GeneralParameters__c();
        parameters.Name = 'Parametro geral';
        parameters.Email__c = 'thomas.anderson@nescara.com';
        parameters.StockNotification__c = 4;
        insert parameters;
        
        Fornecedor__c provider = new Fornecedor__c(
            Name = 'Provider Test'
        );
        insert provider;

        Account account = TestUtility.createAccPJ();
        account.CodigoCliente__c = '0168444';
        account.CodigoGrupoClientes__c = '000001';
        insert account;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        order.Status = 'Em digitação';
        insert order;
        
        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.Fornecedor__c = provider.Id;
        product.Description = 'Lectrum';
        product.ProductCode = '55801';
        product.IsActive = true;
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10,
            ItemPendente__c = true
        );
        insert orderItem;

        Estoque__c inventory = new Estoque__c(
            NomeProduto__c = product.Id,
            Saldo__c = 5
        );
        insert inventory;

        inventory.Saldo__c = 10;
        update inventory;

        inventory = [SELECT Id, Saldo__c FROM Estoque__c LIMIT 1];
        System.assertEquals(inventory.Saldo__c, 10);
    }
}
