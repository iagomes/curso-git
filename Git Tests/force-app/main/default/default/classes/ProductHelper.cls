public without sharing class ProductHelper {    

    public static Id STANDARD_PRICEBOOK_ID = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE isStandard = true limit 1].Id;

    public static void createStandardEntries(List<Product2> newRecordList){
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();

        for(Product2 product2 : newRecordList){
            pricebookEntryList.add(buildNewPricebookEntry(STANDARD_PRICEBOOK_ID, product2.id, 0));
        }

        if(!pricebookEntryList.isEmpty()){
            insert pricebookEntryList;
        }
    }

    public static PricebookEntry buildNewPricebookEntry(Id pricebook2Id, Id product2Id, Decimal unitPrice){
        return new PriceBookEntry(
            pricebook2Id = pricebook2Id,
            product2Id = product2Id,
            unitPrice = unitPrice,
            isActive = true
        );
    }

    public static Map<Id, Decimal> getMapEstoqueByProductId(Set<Id> setProductId, Id accId){
        Map<Id, Decimal> mapEstoques = new Map<Id, Decimal>();
        for (List<Estoque__c> estoques : [SELECT Id, NomeProduto__c, Saldo__c FROM Estoque__c WHERE NomeProduto__c IN :setProductId AND (NomeCliente__c = NULL OR NomeCliente__c	=: accId)]) {
            for (Estoque__c e : estoques) {
                if (!mapEstoques.containsKey(e.NomeProduto__c)) {
                    mapEstoques.put(e.NomeProduto__c, 0);
                }
                Decimal balance = mapEstoques.get(e.NomeProduto__c) + e.Saldo__c;
                mapEstoques.put(e.NomeProduto__c, balance);
            }
        }
        return mapEstoques;
    }

    public static Map<String, Decimal> getMapEstoqueByProductCode(Set<String> setProductCode, Id accId){
        Map<String, Decimal> mapEstoques = new Map<String, Decimal>();
        for (List<Estoque__c> estoques : [SELECT Id, NomeProduto__r.ProductCode, Saldo__c FROM Estoque__c WHERE NomeProduto__r.ProductCode IN :setProductCode AND (NomeCliente__c = NULL OR NomeCliente__c	=: accId)]) {
            for (Estoque__c e : estoques) {
                if (!mapEstoques.containsKey(e.NomeProduto__r.ProductCode)) {
                    mapEstoques.put(e.NomeProduto__r.ProductCode, 0);
                }
                Decimal balance = mapEstoques.get(e.NomeProduto__r.ProductCode) + e.Saldo__c;
                mapEstoques.put(e.NomeProduto__r.ProductCode, balance);
            }
        }
        return mapEstoques;
    }
}
