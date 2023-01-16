public class MockHttpResponseGenerator implements HttpCalloutMock {
    private Boolean isSuccess;
    private String integration;

    public MockHttpResponseGenerator(Boolean isSuccess, String integration){
        this.isSuccess   = isSuccess;
        this.integration = integration;
    }
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(this.isSuccess? 200 : 500);

        if (integration == 'Malha') {
            if (res.getStatusCode() == 200){
                res.setBody('{"output": [{"cds": [{"aliquota": 18,"foramalha": false,"prioridade": "1","cnpj": "52202744000192","saldo": 4,"custo": 174.64,"cd": "0101001","filial": "NACIONAL - RIBEIRAO PRETO (MATRIZ)"},{"aliquota": 18,"foramalha": false,"prioridade": "2","cnpj": "52202744000788","saldo": 0,"custo": 274.89,"cd": "0101007","filial": "NACIONAL - SANT. DE PARNAIBA (FILIAL 03)"}],"codprotheus": "0000310","ean": null}]}');
            }
        } else if (integration == 'Lotes') {
            if (res.getStatusCode() == 200){
                res.setBody('{"estoque": [{"cod_distribuicao": "1","cod_operacao_logistica": "1","cod_operacao_logistica_polo": "01006","cod_produto": "27","lote": "LOTE UNICO","estoque": "20.0000","retido": "0.0000","cod_produto_polo": "0000002","validade": "2025-12-31T00:00:00-03:00"}]}');
            }
        }
        return res;
    }
}