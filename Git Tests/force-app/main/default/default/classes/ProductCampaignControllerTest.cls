@isTest
public with sharing class ProductCampaignControllerTest {
    
    @isTest
    public static void testGetProduct() {

        GeneralParameters__c parameters = new GeneralParameters__c();
        parameters.Name = 'Parametro geral';
        parameters.Email__c = 'test.test@nescara.com';
        parameters.StockNotification__c = 4;
        insert parameters;

        GrupoCliente__c gCli = TestUtility.createGrupoCliente();
        insert gCli;

        Account account = TestUtility.createAccPJ();
        account.GrupoCliente__c = gCli.Id;
        insert account;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;

        Fornecedor__c provider = new Fornecedor__c(
            Name = 'Provider Test'
        );
        insert provider;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.Fornecedor__c = provider.Id;
        product.Description = 'Lectrum';
        product.ProductCode = '55801';
        product.IsActive = true;
        insert product;

        Estoque__c inventory = new Estoque__c(
            NomeProduto__c = product.Id,
            Saldo__c = 5
        );
        insert inventory;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        pricebookEntry.UnitPrice = 10;
        insert pricebookEntry;

        Setorizacao__c sectorization =new Setorizacao__c(
            Categoria__c = 'M',
            Produto__c = product.Id,
            Fornecedor__c = provider.Id,
            Vendedor__c = UserInfo.getUserid(),
            Conta__c = account.Id
        );
        insert sectorization;

        Campaign camp = TestUtility.createCampaign();
        camp.GrupoCliente__c = '123';
        Campaign camp2 = TestUtility.createCampaignShelfLife();        
        Campaign camp3 = TestUtility.createCampaignVendedor();
        
        insert new List<Campaign>{camp, camp2, camp3};

        ItemCampanha__c itemCamp = TestUtility.createItemCampanha(camp.Id, product.Id);
        ItemCampanha__c itemCamp2 = TestUtility.createItemCampanha(camp2.Id, product.Id);
        ItemCampanha__c itemCamp3 = TestUtility.createItemCampanha(camp3.Id, product.Id);

        insert new List<ItemCampanha__c>{itemCamp, itemCamp2, itemCamp3};

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        String pricebookId = pricebook.Id; 
        String clienteId = account.Id; 
        String offSetValue = ''; 
        String searchGenericValue = ''; 
        String searchFabricanteValue = '';

        List<OrderScreenController.ProductData> productList = ProductCampaignController.getProductCampaign(
            pricebookId,
            clienteId,
            offSetValue,
            searchGenericValue,
            searchFabricanteValue,
            paymentCondition.Id
        );

        ProductCampaignController.getClientOrderData(clienteId, product.Id);
    }

}
