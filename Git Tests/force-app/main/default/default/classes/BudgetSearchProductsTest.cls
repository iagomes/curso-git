@IsTest()
public with sharing class BudgetSearchProductsTest {
    @TestSetup
    static void makeData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Usuário Padrão' OR Name='Standard User' LIMIT 1]; 
        User user = new User(
            FirstName = 'Usuário',
            LastName = 'Teste',
            Email = 'usuario.teste@exemple.com',
            UserName = 'usuario.teste@exemple.com.org',
            Alias = 'utes',
            FilialPreferencial__c = '01001',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'pt_BR',
            LanguageLocaleKey = 'en_US', 
            ProfileId = profile.Id, 
            TimeZoneSidKey = 'America/Sao_Paulo'
        );
        insert user;

        ListaCentroDistribuicao__c deliveryCenter = new ListaCentroDistribuicao__c(
            Name = 'RIBEIRAO PRETO (MATRIZ)',
            NomeCD__c = 'NACIONAL - RIBEIRAO PRETO (MATRIZ)',
            CNPJCD__c = '52202744000192',
            CodigoCD__c = '01001',
            IsActive__c = true
        );
        insert deliveryCenter;

        Account account = new Account(
            Name = 'UNIMED SAO PAULO', 
            BillingState = 'SP',
            ShippingState = 'SP'
        );
        insert account;

        Fornecedor__c producer = new Fornecedor__c(
            Name = 'DESCARPACK'
        );
        insert producer;

        Product2 product = new Product2(
            Name = 'LUVA DESCARTAVEL',
            ProductCode = '00000255',
            Description = 'LUVA DESCARTAVEL',
            Fornecedor__c = producer.Id,
            IsActive = true
        );
        insert product;

        Pricebook2 pricebook = new pricebook2(
            Name = 'BO01 BIOHOSP',
            CodigoTabela__c = 'B01',
            CodigoCentroDistribuicao__c = '01001'
        );
        insert pricebook;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = pricebook.Id, 
            Product2Id = product.Id,
            unitprice = 1.0, 
            isActive = true,
            PrecoGeral__c = 100,
            SP__c = 98
        );
        insert pricebookEntry;

        Estoque__c stock = new Estoque__c(
            NomeProduto__c = product.Id,
            CNPJCD__c = '52202744000192',
            Saldo__c = 200
        );
        insert stock;
    }

    @IsTest
    static void itShouldGetUserDefaultCompany() {
        List<User> user = [
            SELECT FilialPreferencial__c 
            FROM User 
            WHERE Username = 'usuario.teste@exemple.com.org' 
            LIMIT 1
        ];

        String defaultCompany;

        Test.startTest();
        System.runAs(user[0]) {
            defaultCompany = BudgetSearchProducts.getDefaultUserDeliveryCenter();
        }
        Test.stopTest();

        System.assertEquals(
            '01001', 
            defaultCompany,
            'Usuário não possui uma filial de preferência.'
        );
    }

    @IsTest
    static void itShouldGetDeliveryCenters() {
        Test.startTest();
        String serializedOptions = BudgetSearchProducts.getDeliveryCenterOptions();

        List<BudgetSearchProducts.DeliveryCenterOption> options = 
            (List<BudgetSearchProducts.DeliveryCenterOption>) JSON.deserialize(
                serializedOptions, 
                List<BudgetSearchProducts.DeliveryCenterOption>.class
            );
        Test.stopTest();

        System.assertEquals(
            1, 
            options.size(),
            'Nenhum centro de distribuição encontrado.'
        );
    }

    @IsTest
    static void itShouldGetProducts() {
        List<Account> account = [
            SELECT Id, BillingState 
            FROM Account 
            WHERE Name = 'UNIMED SAO PAULO' LIMIT 1
        ];

        BudgetSearchProducts.SearchToAnswerRequest request = new BudgetSearchProducts.SearchToAnswerRequest();
        request.producer = 'DES';
        request.product = 'LUVA';

        request.priceParams = new BudgetSearchProducts.PricebookBaseParams();
        request.priceParams.accountId = account[0].Id;
        request.priceParams.state = account[0].BillingState;
        request.priceParams.companyCode = '01001';
        request.priceParams.pricebookCode = 'B01';

        Test.startTest();
        String queryFilter = JSON.serialize(request);
        String response = BudgetSearchProducts.searchProductsToAnswer(queryFilter);

        BudgetSearchProducts.SearchResultData resultData =
            (BudgetSearchProducts.SearchResultData) JSON.deserialize(
                response,
                BudgetSearchProducts.SearchResultData.class
            );
        Test.stopTest();

        System.assertEquals(
            1, 
            resultData.products.size(), 
            'É esperado que retorne 1 produto.'
        );
    }

    @IsTest
    static void itShouldGetProductsWithStatePriceList() {
        List<Account> account = [
            SELECT Id, BillingState 
            FROM Account 
            WHERE Name = 'UNIMED SAO PAULO' LIMIT 1
        ];

        BudgetSearchProducts.SearchToAnswerRequest request = new BudgetSearchProducts.SearchToAnswerRequest();
        request.producer = 'DES';
        request.product = 'LUVA';

        request.priceParams = new BudgetSearchProducts.PricebookBaseParams();
        request.priceParams.accountId = account[0].Id;
        request.priceParams.state = account[0].BillingState;
        request.priceParams.companyCode = '01001';
        request.priceParams.pricebookCode = 'B01';

        Test.startTest();
        String queryFilter = JSON.serialize(request);
        String response = BudgetSearchProducts.searchProductsToAnswer(queryFilter);

        BudgetSearchProducts.SearchResultData resultData =
            (BudgetSearchProducts.SearchResultData) JSON.deserialize(
                response,
                BudgetSearchProducts.SearchResultData.class
            );
        Test.stopTest();

        Map<Id, BudgetSearchProducts.ProductPrice> mapProductsPrices = resultData.productsPrices;
        BudgetSearchProducts.ProductPrice productPrice = mapProductsPrices.get(resultData.products[0].Id);
        
        System.assertEquals(
            98, 
            productPrice.priceList, 
            'É esperado que o valor deste produto para o estado SP seja 98.'
        );
    }

    @IsTest
    static void itShouldGetProductsWithGeneralPriceList() {
        List<Account> account = [
            SELECT Id, BillingState 
            FROM Account 
            WHERE Name = 'UNIMED SAO PAULO' LIMIT 1
        ];

        BudgetSearchProducts.SearchToAnswerRequest request = new BudgetSearchProducts.SearchToAnswerRequest();
        request.producer = 'DES';
        request.product = 'LUVA';

        request.priceParams = new BudgetSearchProducts.PricebookBaseParams();
        request.priceParams.accountId = account[0].Id;
        request.priceParams.state = 'RJ'; // pegar preço geral.
        request.priceParams.companyCode = '01001';
        request.priceParams.pricebookCode = 'B01';

        Test.startTest();
        String queryFilter = JSON.serialize(request);
        String response = BudgetSearchProducts.searchProductsToAnswer(queryFilter);

        BudgetSearchProducts.SearchResultData resultData =
            (BudgetSearchProducts.SearchResultData) JSON.deserialize(
                response,
                BudgetSearchProducts.SearchResultData.class
            );
        Test.stopTest();

        Map<Id, BudgetSearchProducts.ProductPrice> mapProductsPrices = resultData.productsPrices;
        BudgetSearchProducts.ProductPrice productPrice = mapProductsPrices.get(resultData.products[0].Id);
        
        System.assertEquals(
            100, 
            productPrice.priceList, 
            'É esperado que o valor deste produto seja 100 (Preço geral).'
        );
    }

    @IsTest
    static void itShouldRefreshValues() {
        List<Account> account = [
            SELECT Id, BillingState 
            FROM Account 
            WHERE Name = 'UNIMED SAO PAULO' LIMIT 1
        ];

        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = '00000255' LIMIT 1];

        BudgetSearchProducts.RefreshPricesRequest request = new BudgetSearchProducts.RefreshPricesRequest();
        request.productsIds = new List<Id>{ product.Id };
        
        request.priceParams = new BudgetSearchProducts.PricebookBaseParams();
        request.priceParams.accountId = account[0].Id;
        request.priceParams.state = 'SP';
        request.priceParams.companyCode = '01001';
        request.priceParams.pricebookCode = 'B01';

        Test.startTest();
        String queryFilter = JSON.serialize(request);
        String response = BudgetSearchProducts.refreshProductsPricesAndStocks(queryFilter);

        BudgetSearchProducts.RefreshProductsResultData resultData =
            (BudgetSearchProducts.RefreshProductsResultData) JSON.deserialize(
                response,
                BudgetSearchProducts.RefreshProductsResultData.class
            );
        Test.stopTest();

        Map<Id, BudgetSearchProducts.ProductPrice> mapProductsPrices = resultData.productsPrices;
        BudgetSearchProducts.ProductPrice productPrice = mapProductsPrices.get(product.Id);
        
        System.assertEquals(
            98, 
            productPrice.priceList, 
            'É esperado que o valor deste produto para o estado SP seja 98.'
        );
    }
}
