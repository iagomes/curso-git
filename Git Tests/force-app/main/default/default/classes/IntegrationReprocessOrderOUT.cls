public without sharing class IntegrationReprocessOrderOUT {

    public class OrderRequest {
        public String  PedidoIntegrador;
        
        public OrderRequest(Order ord) {
            this.PedidoIntegrador = ord.OrderNumber;
        }
    }

    public class ResultClass {
        public String  result   { get; set; }
        public Boolean atualizado { get; set; }
    }

    @InvocableMethod(label='Reprocess order' description='Reprocess order and send to TOTVS')
    public static List<String> sendReprocessOrder(List<Id> ordIdList){
        Order contextOrd = null;
        Set<Id> ordIdSet = new Set<Id>();
        for (Order order : [SELECT Id, ExternalId__c, Status, StatusIntegracao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c, RecordTypeId,
                                PedidoOriginal__c, PedidoPendente__c, PedidoPai__c, ErroIntegracaoCancelamento__c, MensagemErroIntegracao__c,
                                Description, ErroIntegracaoAprovacao__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c 
                            FROM Order WHERE Id IN :ordIdList AND Status != 'Cancelado']) {
            if (order.Status == 'ErroIntegracao' && (order.StatusIntegracao__c == 'Erro integração (Envio ao Protheus)' || order.StatusIntegracao__c == 'Erro integração (geração do pedido no Protheus)')) {
                contextOrd = order;
            } 
        }
        if (contextOrd != null) {
            sendReprocessOrderToERP(contextOrd);
        }
        return null;
    }

    public static void sendReprocessOrderToERP(Order contextOrd) {
        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaReprocessOrderAPI');
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setTimeout(120000);

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        OrderRequest orderReq = new OrderRequest(contextOrd);
        System.debug('contractReq: ' + orderReq);

        String body;
        body = Json.serialize(orderReq);
        System.debug('Body: '+ body);

        String resultString = '';
        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            System.debug(resp);
            System.debug(resp.getStatusCode());
            Boolean hasError = false;
            resultString = resp.getBody();
            System.debug('resp' + resultString);            
            String statusIntegration = null;
            if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {        
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Reprocessamento Pedido', 'Outbound', body, resultString, hasError);
            } else {
                hasError = true;
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Reprocessamento Pedido', 'Outbound', body, resultString, hasError);
            }
            ResultClass resClass = null;
            String errorMessage  = null;
            
            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
                hasError = !resClass.atualizado;
                errorMessage = hasError ? resClass.result : null;
            } catch (Exception e) {
                system.debug(e.getMessage());
                hasError = true;
                errorMessage = 'Erro de integração do reprocessamento do pedido.';
            }           
            
            if (!hasError)  {
                contextOrd.Status                    = 'Aguardando integração';
                contextOrd.StatusIntegracao__c       = null;
                contextOrd.MensagemErroIntegracao__c = errorMessage;
                
                OrderHandler.disableTrigger();
                update contextOrd;
                OrderHandler.enableTrigger();
            }
        } catch (Exception e) {
            resultString = e.getMessage();
        }
    }
}