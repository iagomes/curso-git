public without sharing class BudgetSearchProducts {
    
    @AuraEnabled
    public static String getDefaultUserDeliveryCenter() {
        try {
            User currentUser = [
                SELECT FilialPreferencial__c 
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];

            return currentUser.FilialPreferencial__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getDeliveryCenterOptions() {
        try {
            List<DeliveryCenterOption> options = new List<DeliveryCenterOption>();
            
            List<ListaCentroDistribuicao__c> deliveryCenters = [
                SELECT 
                    Id, 
                    CodigoCD__c, 
                    NomeCD__c
                FROM ListaCentroDistribuicao__c
                WHERE IsActive__c = TRUE
                ORDER BY CodigoCD__c
            ];

            for (ListaCentroDistribuicao__c currentDeliveryCenter: deliveryCenters) {
                DeliveryCenterOption option = new DeliveryCenterOption();
                option.label = currentDeliveryCenter.CodigoCD__c + ' | ' + currentDeliveryCenter.NomeCD__c;
                option.value = currentDeliveryCenter.CodigoCD__c;

                options.add(option);
            }

            return JSON.serialize(options);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String searchProductsToAnswer(String queryFilter) {
        SearchToAnswerRequest filter = (SearchToAnswerRequest) JSON.deserialize(
            queryFilter, 
            SearchToAnswerRequest.class
        );

        String conditions = getWhereClause(filter);
        
        try {
            String query = generateQueryBase(conditions);
            List<Product2> queryResult = (List<Product2>) Database.query(query);
            Map<Id, Product2> products = new Map<Id, Product2>(queryResult);
            Map<Id, Decimal> stocks = null;
            Map<Id, Decimal> companyStocks = null;
            Map<Id, ProductPrice> productsPrices = null;

            if (products.keySet().size() > 0) {
                stocks = getStockProductsAmountByProductId(products.keySet());
                companyStocks = getCompanyStockProductsAmountByProductId(
                    products.keySet(), 
                    filter.priceParams.companyCode
                );

                PricebookBaseParams basePriceParams = new PricebookBaseParams();
                basePriceParams.accountId = filter.priceParams.accountId;
                basePriceParams.companyCode = filter.priceParams.companyCode;
                basePriceParams.pricebookCode = filter.priceParams.pricebookCode;
                basePriceParams.state = filter.priceParams.state;

                productsPrices = getProductsPrices(
                    products.keySet(), 
                    basePriceParams
                );
            }

            SearchResultData searchResult = new SearchResultData();
            searchResult.stocks = stocks;
            searchResult.companyStocks = companyStocks;
            searchResult.products = products.values();
            searchResult.productsPrices = productsPrices;

            return JSON.serialize(searchResult);
        } catch (Exception e) {
            throw new AuraHandledException('Erro ao buscar produtos.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static String refreshProductsPricesAndStocks(String params) {
        RefreshPricesRequest entryData = (RefreshPricesRequest) JSON.deserialize(
            params, 
            RefreshPricesRequest.class
        );

        Map<Id, ProductPrice> productsPrices = null;
        Map<Id, Decimal> companyStocks = null;
        
        Set<Id> productsIds = new Set<Id>(entryData.productsIds);

        try {
            productsPrices = getProductsPrices(
                productsIds, 
                entryData.priceParams
            );

            companyStocks = getCompanyStockProductsAmountByProductId(
                productsIds, 
                entryData.priceParams.companyCode
            );
            
            RefreshProductsResultData resultData = new RefreshProductsResultData();
            resultData.productsPrices = productsPrices;
            resultData.companyStocks = companyStocks;

            return JSON.serialize(resultData);
        } catch (Exception e) {
            throw new AuraHandledException('Erro ao atualizar os preços dos produtos.');
        }
    }

    public static String generateQueryBase(String conditions) {
        String query = 'SELECT {0} FROM Product2 WHERE IsActive = TRUE {1} LIMIT 50';
        String queryFields = getQueryFields();
        return String.format(
            query,
            new List<String> {
                queryFields,
                conditions
            }
        );
    }

    public static String getQueryFields() {
        List<String> fields = new List<String>{
            'Id',
            'ProductCode',
            'Name',
            'CategoriaComercial__c',
            'UnidadeMedida__c',
            'SegundaUnidade__c',
            'FatorConversao__c',
            'TipoConversao__c',
            'Description',
            'NumeroAnvisa__c',
            'EANProduto__c',
            'DescricaoTecnica__c',
            'Fornecedor__r.Name'
        };

        return String.join(fields, ',');
    }

    public static String getWhereClause(SearchToAnswerRequest queryData) {
        List<String> conditions = new List<String>();
        
        if (queryData.product != null && queryData.product != '') {
            String productCondition = String.format(
                'AND (Name LIKE \'%{0}%\' OR ProductCode LIKE \'%{0}%\' OR Description LIKE \'%{0}%\')',
                new List<String>{
                    queryData.product.replaceAll(' ', '%')
                }
            );

            conditions.add(productCondition);
        }

        if (queryData.producer != null && queryData.producer != '') {
            String producerCondition = String.format(
                'AND Fornecedor__r.Name LIKE \'%{0}%\'',
                new List<String>{
                    queryData.producer.replaceAll(' ', '%')
                }
            );

            conditions.add(producerCondition);
        }

        if (conditions.size() <= 0) {
            return '';
        }
        
        return String.join(conditions, ' ');
    }

    public static Map<Id, Decimal> getStockProductsAmountByProductId(Set<Id> productsIds) {
        Map<Id, Decimal> stockProductsAmountByProductId = new Map<Id, Decimal>();
        List<AggregateResult> stocks = [
            SELECT
                NomeProduto__c,
                SUM(Saldo__c) Saldo
            FROM Estoque__c
            WHERE NomeProduto__c IN :productsIds
            GROUP BY NomeProduto__c
        ];

        for (AggregateResult currentStock : stocks) {
            stockProductsAmountByProductId.put(
                (Id) currentStock.get('NomeProduto__c'),
                (Decimal) currentStock.get('Saldo')
            );
        }

        return stockProductsAmountByProductId;
    }

    public static Map<Id, Decimal> getCompanyStockProductsAmountByProductId(
        Set<Id> productsIds, 
        String companyCode
    ) {
        Map<Id, Decimal> companyStockProductsAmountByProductId = new Map<Id, Decimal>();

        List<ListaCentroDistribuicao__c> deliveryCentersSettings = [
            SELECT CNPJCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CodigoCD__c = :companyCode
            LIMIT 1
        ];

        if (deliveryCentersSettings.size() > 0) {
            List<Estoque__c> stocks = [
                SELECT
                    NomeProduto__c,
                    Saldo__c
                FROM Estoque__c
                WHERE NomeProduto__c IN :productsIds
                AND CNPJCD__c = :deliveryCentersSettings[0].CNPJCD__c
            ];
    
            for (Estoque__c currentStock : stocks) {
                companyStockProductsAmountByProductId.put(
                    currentStock.NomeProduto__c,
                    currentStock.Saldo__c
                );
            }
        }

        return companyStockProductsAmountByProductId;
    }

    public static Map<Id, ProductPrice> getProductsPrices(
        Set<Id> productsIds, 
        PricebookBaseParams baseParams
    ) {
        Map<Id, ProductPrice> productsPrices = new Map<Id, ProductPrice>();

        // Procebook Entries
        List<SObject> productEntries = getPricebookEntries(
            baseParams.pricebookCode, 
            baseParams.companyCode, 
            productsIds
        );

        for (SObject currentEntry : productEntries) {
            String stateField = baseParams.state != null ? baseParams.state + '__c' : null;

            ProductPrice productPrice = new ProductPrice();
            productPrice.priceList = null;

            if (
                stateField != null &&
                currentEntry.get(stateField) != null && 
                (Decimal) currentEntry.get(stateField) > 0
            ) {
                productPrice.priceList = (Decimal) currentEntry.get(stateField);
            } else if (currentEntry.get('PrecoGeral__c') != null) {
                productPrice.priceList = (Decimal) currentEntry.get('PrecoGeral__c');
            }

            productsPrices.put(
                (Id) currentEntry.get('Product2Id'),
                productPrice
            );
        }

        // Contract items

        List<ItemContrato__c> contractItems = getContractItemsPrice(
            baseParams.accountId, 
            productsIds
        );

        for (ItemContrato__c currentContractItem : contractItems) {
            if (!productsPrices.containsKey(currentContractItem.NomeProduto__c)) {
                productsPrices.put(
                    currentContractItem.NomeProduto__c,
                    new ProductPrice()
                );
            }

            productsPrices
                .get(currentContractItem.NomeProduto__c)
                .contractPrice = currentContractItem.PrecoUnitario__c;
        }

        // Campaign items

        List<ItemCampanha__c> campaingItems = getCampaignItemsPrice(
            productsIds, 
            baseParams.companyCode,
            baseParams.accountId
        );

        for (ItemCampanha__c currentCampaingItem :campaingItems) {
            if (!productsPrices.containsKey(currentCampaingItem.NomeProduto__c)) {
                productsPrices.put(
                    currentCampaingItem.NomeProduto__c,
                    new ProductPrice()
                );
            }

            productsPrices
                .get(currentCampaingItem.NomeProduto__c)
                .campaignPrice = currentCampaingItem.PrecoUnitario__c;
            
            productsPrices
                .get(currentCampaingItem.NomeProduto__c)
                .campaignType = currentCampaingItem.Campanha__r.RecordType.DeveloperName;
        }

        return productsPrices;
    }

    public static List<SObject> getPricebookEntries(
        String pricebookCode, 
        String companyCode, 
        Set<Id> productsIds
    ) {
        String query = 
        'SELECT' +
            ' Id,' +
            ' Product2Id,' +
            ' PrecoGeral__c,' +
            ' AC__c, AL__c, AM__c, AP__c, BA__c, CE__c, DF__c, ES__c, GO__c, MA__c, MG__c, MS__c, MT__c, PA__c, PB__c, PE__c, PI__c, PR__c, RJ__c, RN__c, RO__c, RR__c, RS__c, SC__c, SE__c, SP__c, TO__c' +
        ' FROM PricebookEntry' +
        ' WHERE Pricebook2.CodigoTabela__c ={0}' +
        ' AND Pricebook2.CodigoCentroDistribuicao__c = {1}' +
        ' AND Product2Id IN :productsIds';

        String formattedQuery = String.format(query, new List<String>{
            '\''+pricebookCode+'\'',
            '\''+companyCode+'\''
        });

        return Database.query(formattedQuery);
    }

    public static List<ItemContrato__c> getContractItemsPrice(Id accountId, Set<Id> productsIds) {
        List<ItemContrato__c> contractItems = [
            SELECT
                NomeProduto__c, 
                PrecoUnitario__c 
            FROM ItemContrato__c 
            WHERE NumeroContrato__r.AccountId = :accountId
            AND Status__c = 'Aprovado'
            AND VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY
            AND NomeProduto__c IN :productsIds
        ];

        return contractItems;
    }

    public static List<ItemCampanha__c> getCampaignItemsPrice(
        Set<Id> productsIds,
        String companyCode, 
        Id accountId
    ) {
        String company = companyCode != null ? companyCode : '';

        String query = '' +
        'SELECT '+
            ' Campanha__r.RecordType.DeveloperName,'+
            ' NomeProduto__c,'+
            ' PrecoUnitario__c,'+
            ' Campanha__r.CodigoCD__c'+
        ' FROM ItemCampanha__c'+
        ' WHERE NomeProduto__c IN :productsIds'+
        ' AND ('+
            ' Campanha__r.Cliente__c = :accountId'+
            ' OR (Campanha__r.Cliente__c = null AND Campanha__r.GrupoCliente__c = null)'+
        ' )'+
        ' AND ('+
        ' (Campanha__r.StartDate <= TODAY AND Campanha__r.EndDate >= TODAY)'+
        ' OR (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY)'+
        ' )'+
        ' AND ('+
        ' Campanha__r.CodigoCD__c = NULL'+
        ' OR Campanha__r.CodigoCD__c LIKE \'%{0}%\''+
        ' )';

        List<ItemCampanha__c> campaignItems = (List<ItemCampanha__c>) Database.query(
            String.format(
                query, 
                new List<String>{company}
            )
        );

        return campaignItems;
    }

    public class SearchToAnswerRequest {
        @AuraEnabled public String product;
        @AuraEnabled public String producer;

        @AuraEnabled public PricebookBaseParams priceParams;
    }

    public class SearchResultData {
        public List<Product2> products;
        public Map<Id, Decimal> stocks;
        public Map<Id, Decimal> companyStocks;
        public Map<Id, ProductPrice> productsPrices;
    }

    public class RefreshPricesRequest {
        @AuraEnabled public List<Id> productsIds;
        @AuraEnabled public PricebookBaseParams priceParams;
    }

    public class RefreshProductsResultData {
        public Map<Id, Decimal> companyStocks;
        public Map<Id, ProductPrice> productsPrices;
    }

    public class PricebookBaseParams {
        @AuraEnabled public String accountId;
        @AuraEnabled public String pricebookCode;
        @AuraEnabled public String companyCode;
        @AuraEnabled public String state;
    }

    public class ProductPrice {
        @AuraEnabled public Decimal priceList;
        @AuraEnabled public Decimal contractPrice;
        @AuraEnabled public Decimal campaignPrice;
        @AuraEnabled public String campaignType;
    }

    public class DeliveryCenterOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}
