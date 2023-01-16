@IsTest
public without sharing class OrderCreatePDFTest {
    @IsTest
    public static void flowCreateOrderPDFTest() {
        TemplatePDF__c template = new TemplatePDF__c(Name = 'ElfaQuoteOrderTemplate', Id = null);
        insert template;
        Account account  = TestUtility.createAccPJ();
        insert account;
        Order order      = TestUtility.createOrder(account);
        order.DataEntrega__c = Date.today();
        insert order;
        Product2 product = TestUtility.createProduct();
        insert product;
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry][0];
        pricebookEntry.IsActive       = true;
        update pricebookEntry;
        OrderItem orderItem  = TestUtility.createorderItem(order, product, pricebookEntry);
        orderItem.UnitPrice = 10;
        orderItem.ValorCx__c = 10;
        insert orderItem;

        OrderCreatePDF.FlowInputs flowInput = new OrderCreatePDF.FlowInputs();
        flowInput.orderId = order.id;
        flowInput.pdfChoice = 'ElfaQuoteOrderTemplate';

        OrderCreatePDF.flowCreateOrderPDF(new List<OrderCreatePDF.FlowInputs>{flowInput});
    }
}