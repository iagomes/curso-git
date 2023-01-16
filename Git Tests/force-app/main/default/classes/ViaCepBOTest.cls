@isTest
global with sharing class ViaCepBOTest {
    @isTest
    public static void ViaCepBOTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        ViaCepBO.flowCEP(new List<String>{'15945970'});
        Test.stopTest();
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
}
