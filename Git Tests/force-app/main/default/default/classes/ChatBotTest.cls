@isTest
public class ChatBotTest {
    
    @testSetup
    public static void setup() {
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Order ordParent = TestUtility.createOrder(acc);
        insert ordParent;      

        Order ord = TestUtility.createOrder(acc);
        ord.NumeroPedidoCliente__c = '0001';
        ord.PedidoPai__c = ordParent.Id;
        insert ord;        
        
        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        nf.Conta__c = acc.Id;
        insert nf;     
        
        Case c = TestUtility.createCase(acc, ctt);
        c.NotaFiscal__c = nf.Id;  
        insert c;             
    }
    
    @isTest
    public static void createCase() {
        
        List<Case> records = [SELECT Id FROM Case WHERE Origin = 'Chatbot'];
        System.assertEquals(0, records.size());
        
        Test.startTest();
        ChatBot.createCase(new List<String> {'04585497000108'});
        Test.stopTest();
        
        records = [SELECT Id FROM Case WHERE Origin = 'Chatbot'];
        System.assertEquals(1, records.size());
    }      
    
    @isTest
    public static void createCaseError() {
        
        List<Case> records = [SELECT Id FROM Case WHERE Origin = 'Chatbot'];
        System.assertEquals(0, records.size());
        
        Test.startTest();
        ChatBot.createCase(new List<String> {});
        Test.stopTest();
        
        records = [SELECT Id FROM Case WHERE Origin = 'Chatbot'];
        System.assertEquals(0, records.size());
    }    
    
    @isTest
    public static void fetchInvoiceBase64File() {
        
        Test.startTest();
        
        Map<String, String> params = new Map<String, String> {
                'invoiceNumber' => 'nf0000000000001',
                'documentType' => 'invoice'
                };   
                    
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"danfe":"document"}', null));
        String response = ChatBot.fetchBase64File(params);
        System.assertEquals('document', response);
        
        Test.stopTest();
    }
    
    @isTest
    public static void fetchPaymentSlipBase64File() {
        
        Test.startTest();
        
        Map<String, String> params = new Map<String, String> {
            'customerId' => '04585497000108',
                'orderNumber' => '0001',
                'documentType' => 'paymentSlip'
                };   
                    
                    Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"TituloAberto" : [{"PEDIDO":"0001","NUM":"0002", "CGC_CD":"", "PREFIXO":"", "TIPO":"", "PARCELA":""}], "boleto":"document"}', null));
        String response = ChatBot.fetchBase64File(params);
        System.assertEquals('document', response);
        
        Test.stopTest();
    }     
    
    @isTest
    public static void fetchBase64FileError() {
        
        Test.startTest();
        
        Map<String, String> params = new Map<String, String> {
            'customerId' => '02643718000121',
                'invoiceNumber' => '000758215',
                'documentType' => 'invoice'
                };   
                    
		Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{"error":""}', null));
        String response = ChatBot.fetchBase64File(params);
        System.assertEquals(true, response instanceof Id);  
        
        Test.stopTest();
    }
    
    @isTest
    public static void fetchBase64FileUnknownError() {
        
        Test.startTest();
        
        Map<String, String> params = new Map<String, String> {
            'customerId' => '02643718000121',
                'invoiceNumber' => '000758215',
                'documentType' => 'invoice'
                };   
                    
		Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'NOK', '', null));
        String response = ChatBot.fetchBase64File(params);
        System.assertEquals(true, response instanceof Id);    
        
        Test.stopTest();
    }      
    
}