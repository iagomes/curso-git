public with sharing class GetFinancialBalanceApiFromERPMock implements HttpCalloutMock{
    private Boolean isSuccess;
    private String body;

    public GetFinancialBalanceApiFromERPMock(Boolean isSuccess, String body) {
        this.isSuccess = isSuccess;
        this.body = body;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (this.isSuccess) {
            response.setStatusCode(200);
            response.setStatus('success');
            response.setBody(this.body);
        }
        else {
            response.setStatusCode(400);
            response.setStatus('error');
            response.setBody(this.body);
        }

        return response;
    }
}
