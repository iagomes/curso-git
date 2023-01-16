public without sharing class MixClientController {
    @AuraEnabled(cacheable=true)
    public static List<ProductData> getClientProdData(String accId, Decimal offSetValue, String searchGenericValue, String searchFabricanteValue) {
        
        searchGenericValue = searchGenericValue.replaceAll(' ', '%');
        searchFabricanteValue = searchFabricanteValue.replaceAll(' ', '%');
        searchGenericValue = '%' + searchGenericValue + '%';
        searchFabricanteValue = '%' + searchFabricanteValue + '%';

        Map<Id, OrderItem> mapIdToOrderItem = new Map<Id, OrderItem>();

        for (OrderItem ordItem: [SELECT Product2Id, CreatedDate FROM OrderItem WHERE Order.AccountId =: accId AND (Order.Status = 'Faturado' OR Order.Status = 'Faturado (Histórico)') Order by CreatedDate DESC LIMIT 30000]) {
            if (!mapIdToOrderItem.containsKey(ordItem.Product2Id)) {
                mapIdToOrderItem.put(ordItem.Product2Id, ordItem);
            } else {
                if (mapIdToOrderItem.get(ordItem.Product2Id).CreatedDate < ordItem.CreatedDate) {
                    mapIdToOrderItem.put(ordItem.Product2Id, ordItem);
                }
            }
        }

        List<ProductData> prodDataList = new List<ProductData>();
        for (Product2 prod : [SELECT Id, Name, ProductCode, Fornecedor__c, Fornecedor__r.Name, Description FROM Product2 WHERE Id IN :mapIdToOrderItem.keySet()
                              AND (Name like :searchGenericValue OR Description like :searchGenericValue OR ProductCode like :searchGenericValue)
                              AND (Fornecedor__r.Name like :searchFabricanteValue) LIMIT 20 OFFSET :Integer.valueOf(offSetValue)]) {
            prodDataList.add(new ProductData(prod, mapIdToOrderItem));
        }
        return prodDataList;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderData> getClientOrderData(String accId, String prodId) {

        List<OrderData> ordDataList = new List<OrderData>();
        for (OrderItem ordItem : [SELECT Id, Quantity, ValorCx__c, OrderId, ScoreItem__c, Order.Score__c, Order.OrderNumber, CentroDistribuicao__c , FORMAT(Order.CreatedDate), Order.EffectiveDate FROM OrderItem WHERE Product2Id =: prodId AND Order.AccountId =:accId AND (Order.Status = 'Faturado' OR Order.Status = 'Faturado (Histórico)') Order by Order.EffectiveDate DESC LIMIT 30000]) {
            ordDataList.add(new OrderData(ordItem));
        }
        return ordDataList;
    }

    public static String formatDate(Datetime dt) {
        List<String> splittedDate = String.valueOf(dt).split(' ')[0].split('-');
        return splittedDate[2] + '/' + splittedDate[1] + '/' + splittedDate[0];
    }

    public class ProductData {
        @auraEnabled public String id         {get;set;}
        @auraEnabled public String name       {get;set;}
        @auraEnabled public String code       {get;set;}
        @auraEnabled public String fornecedor {get;set;}
        @auraEnabled public String pAtivo     {get;set;}
        @auraEnabled public String createdDt  {get;set;}
        @auraEnabled public Boolean show      {get;set;}

        public ProductData(Product2 prod, Map<Id, OrderItem> mapProdIdToOrdItem) {
            this.id         = prod.Id;
            this.name       = prod.Name;
            this.code       = prod.ProductCode;
            this.fornecedor = prod.Fornecedor__r.Name;
            this.pAtivo     = prod.Description;
            this.createdDt  = String.valueOf(mapProdIdToOrdItem.get(prod.Id).CreatedDate);
            this.show       = false;
        }
    }

    public class OrderData {
        @auraEnabled public String ordId            {get;set;}
        @auraEnabled public String ordNumber        {get;set;}
        @auraEnabled public String ordCreatedDate   {get;set;}
        @auraEnabled public String ordItemCd        {get;set;}
        @auraEnabled public Decimal ordScore        {get;set;}
        @auraEnabled public Decimal ordItemScore    {get;set;}
        @auraEnabled public Decimal ordItemQuantity {get;set;}
        @auraEnabled public Decimal ordItemPrice    {get;set;}

        public OrderData(OrderItem ordItem) {
            this.ordId           = ordItem.OrderId;
            this.ordNumber       = ordItem.Order.OrderNumber;
            this.ordCreatedDate  = formatDate(ordItem.Order.EffectiveDate.addDays(1)); // changed CreatedDate to EffectiveDate
            this.ordItemCd       = ordItem.CentroDistribuicao__c;
            this.ordScore        = ordItem.Order.Score__c;
            this.ordItemScore    = ordItem.ScoreItem__c;
            this.ordItemQuantity = ordItem.Quantity;
            this.ordItemPrice    = ordItem.ValorCx__C;
        }
    }
}
