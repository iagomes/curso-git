global without sharing class ErbStockFilter {
	@InvocableMethod(label='ERB Stock Filter' description='Test')
    global static List<List<Recommendation>> flowErbStockFilter(List<DataContainer> inputData) {
        System.debug('inputData => ');
        System.debug(inputData);
        List<Recommendation> recList = inputData[0].recommendations != null ? inputData[0].recommendations : new List<Recommendation>();
        Map<String, Recommendation> mapStringToRecommendation = new Map<String, Recommendation>();
        Map<Id, Decimal> mapProductToStock = new Map<Id, Decimal>();

        if (!recList.isEmpty()) {
            for (Recommendation rec : recList) {
                Id productId = rec.ExternalId;
                mapStringToRecommendation.put(productId, rec);
            }
        }
        System.debug('mapStringToRecommendation => ');
        System.debug(mapStringToRecommendation);

        List<Estoque__c> stockList = [SELECT Id, NomeProduto__c, NomeProduto__r.ProductCode, Saldo__c FROM Estoque__c WHERE NomeProduto__c IN: mapStringToRecommendation.keySet()];
        Map<String, Decimal> mapStockTotal = new Map<String, Decimal>();
        System.debug('stockList => ');
        System.debug(stockList);

        for (Estoque__c stock : stockList) {
            if (!mapStockTotal.containsKey(stock.NomeProduto__r.ProductCode)) {
                mapStockTotal.put(stock.NomeProduto__r.ProductCode, 0);
            }
            Decimal valueStock = mapStockTotal.get(stock.NomeProduto__r.ProductCode) + stock.Saldo__c;
            mapStockTotal.put(stock.NomeProduto__r.ProductCode, valueStock);
        }

        Set<Id> setProduct2StockIds = new Set<Id>();
        for (Estoque__c stock : stockList) {
            if (stock.Saldo__c > 0) {
                setProduct2StockIds.add(stock.NomeProduto__c);
                mapProductToStock.put(stock.NomeProduto__c, mapStockTotal.get(stock.NomeProduto__r.ProductCode));
            }
        }

        List<Product2> productList = [SELECT Id, Description, Fornecedor__r.Name FROM Product2 WHERE Id IN: setProduct2StockIds];

        List<Recommendation> returnedRecommendations = new List<Recommendation>();
        List<List<Recommendation>> output = new List<List<Recommendation>>();
        System.debug('mapStringToRecommendation => ');
        System.debug(mapStringToRecommendation);
        for (Product2 product : productList) {
            List<String> stockValue = String.valueOf(mapProductToStock.get(product.Id)).split('\\.');
            Recommendation rec = mapStringToRecommendation.get(product.Id);
            rec.Description = (product.Description != null ? ('Descrição: ' + product.Description + ' - ') : '') + (product.Fornecedor__r.Name != null ? ('Fornecedor: ' + product.Fornecedor__r.Name + ' - ') : '') + (stockValue[0] != null ? ('Saldo: ' + stockValue[0]) : '');
            returnedRecommendations.add(rec);
        }
        output.add(returnedRecommendations);

        System.debug(returnedRecommendations);
        System.debug(output);
        
        return output;
    }
    
    global class DataContainer{
        @InvocableVariable public String orderId;
        @InvocableVariable public List<Recommendation> recommendations;
    }
}