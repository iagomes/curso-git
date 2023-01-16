@isTest
global class ErbStockFilterTest {

    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId(); 
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId(); 

    @TestSetup
    static void makeData(){
        
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Product2 prod = TestUtility.createProduct();
        insert prod;

        Estoque__c stock = new Estoque__c(
			NomeProduto__c = prod.Id,
			ExternalId__c = String.valueOf(prod.Id) + '        01',
			Name = String.valueOf(prod.Id) + '        01',
			Saldo__c = 100
		);
        insert stock;
        
        Order ord1 = TestUtility.createOrder(acc);
        ord1.RecordTypeId = MOTHERORDER_RECORDTYPE;
        ord1.AprovadoComercial__c = false;
        ord1.AprovadoPricing__c   = false;
        ord1.RejeicaoProcesso__c  = false;
        insert ord1;
        
        Order ord2 = TestUtility.createOrder(acc);
        ord2.RecordTypeId = DIRECT_ORDER_RECORDTYPE;
        ord2.AprovadoComercial__c = false;
        ord2.AprovadoPricing__c   = false;
        ord2.RejeicaoProcesso__c  = false;
        ord2.PedidoPai__c = ord1.Id;
        insert ord2;
    }

    @isTest
    public static void ErbStockFilterTest(){        
        List<Order> listOrder = [SELECT Id, Name FROM Order WHERE PedidoPai__c = null];
        List<Product2> productList = [SELECT Id FROM Product2 LIMIT 1];

        ErbStockFilter.DataContainer flowInput = new ErbStockFilter.DataContainer();
        flowInput.recommendations = new List<Recommendation>();
        Recommendation rec = new Recommendation();
        rec.externalId = String.valueOf(productList[0].Id);
        flowInput.recommendations.add(rec);
        flowInput.orderId = listOrder[0].id;

        ErbStockFilter.flowErbStockFilter(new List<ErbStockFilter.DataContainer>{flowInput});
    }
}