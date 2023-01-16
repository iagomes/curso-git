@isTest
global with sharing class IntegrationGETAttachmentTest {

    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Order ord = TestUtility.createOrder(acc);
        insert ord;

        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        insert nf;
        
        TitulosAbertos__c tit = TestUtility.createTituloAberto(acc, nf);
        insert tit;
        
        Integracoes__c integrationGetAttPDF = TestUtility.createCustomSettingGetAttPDF();
        Integracoes__c integrationGetAttXML = TestUtility.createCustomSettingGetAttXML();
        Integracoes__c integrationGetAtt = TestUtility.createCustomSettingGetAtt();

        List<Integracoes__c> listIntegracoes = new List<Integracoes__c>{integrationGetAttPDF, integrationGetAttXML, integrationGetAtt};

        insert listIntegracoes;
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        public MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CgcCli": "","CgcEmp": "","TpInteg": "","laboratorio": "","regra": "","PedidoIntegrador": "","CondicaoPagamento": "","TabelaPreco": "","TipoFrete": "CIF","observacoes": "","ObservacoesNF": "","itens": [{"produto": "","TpOper": "","ShelfLife": "AAAAMMDD","preco": 1,"lote": "","quantidade": 0.00}]}');
            res.setStatusCode(this.isSuccess? 201 : 500);

            if (res.getStatusCode() == 201){
                res.setBody('{"result": "Pedido incluido na fila de processamento!!","incluido": true}');
            } else {
                res.setBody('{"result": "Pedido não incluido na fila de processamento!!","incluido": false}');
            }
            return res;
        }
    }

    @isTest
    public static void flowHandlerTest() {
        IntegrationGETAttachmentNFPDF getAttchNFPDF = new IntegrationGETAttachmentNFPDF();
        IntegrationGETAttachmentNFXML getAttchNFXML = new IntegrationGETAttachmentNFXML();

        List<String> listNFId = new List<String>{[SELECT Id, ExternalId__c, Conta__c FROM NotasFiscais__c][0].Id};
        List<String> listTitId = new List<String>{[SELECT Id FROM TitulosAbertos__c][0].Id};
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationGetAttachment.flowHandler(listTitId);       
        IntegrationGETAttachmentNFPDF.flowHandlerXML(listNFId);
        IntegrationGETAttachmentNFXML.flowHandlerPDF(listNFId);

        Test.stopTest();    

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        IntegrationGetAttachment.flowHandler(listTitId);
        IntegrationGETAttachmentNFPDF.flowHandlerXML(listNFId);
        IntegrationGETAttachmentNFXML.flowHandlerPDF(listNFId);


    }
}
