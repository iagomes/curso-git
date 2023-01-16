@isTest
global class PaymentSlipCalloutMock implements HttpCalloutMock{
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"EMPRESA":"ATRIAL"}');
        res.setStatusCode(200);
        return res;
    }
}