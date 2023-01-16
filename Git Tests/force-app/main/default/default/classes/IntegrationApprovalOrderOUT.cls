global without sharing class IntegrationApprovalOrderOUT {
    public static final String STATUS_INTEGRATED = 'Integrado';
    public static final String STATUS_APPROVAL_ERROR = 'Erro de aprovação/rejeição';

    global class OrderRequest {
        public String  BranchCGC;//CgcEmp;
        public String  InternalOrderNumber;//NumPedido;
        public String  ExternalOrderNumber;//NumPedInte;
        public Boolean Approved;//liberado;
        
        public OrderRequest(Order ord, String cnpjCD) {
            this.BranchCGC     = cnpjCD;
            this.InternalOrderNumber  = ord.ExternalId__c == null ? '000000' : getExternalId(ord.ExternalId__c);
            this.ExternalOrderNumber = ord.OrderNumber;
            this.Approved   = ord.StatusIntegracao__c == 'Pedido rejeitado na alçada financeira' ? false : ord.PedidoPai__r.Status == 'Aprovado';
        }
    }

    public class ResultClass {
        public String  result   { get; set; }
        public String incluido { get; set; }
    }

    // IntegrationApprovalOrderOUT.sendApprovalOrderToERP('801q0000001DUQdAAO');

    public static void sendApprovalOrderToERP(Id ordId) {
        
        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaApprovalOrderAPI');
        
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

        OrderRequest orderReq;

        String cnpjCD = '';

        for (OrderItem orderItem : [SELECT Id, Quantity, TipoOperacao__c, CodigoProduto__c, Lote__c, PrecoTotal__c, ValidadeMinima__c, CNPJCD__c FROM OrderItem WHERE OrderId = :ordId]) {
            cnpjCD = orderItem.CNPJCD__c;
        }
        Boolean shouldSend = true;
        for (Order order : [SELECT Id, ExternalId__c, PedidoPai__r.Status, Status, StatusIntegracao__c, StatusAprovacao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c,
                                   PedidoPai__r.RejeicaoProcesso__c, PedidoPai__r.RecallProcesso__c, RecallProcesso__c FROM Order WHERE Id = :ordId]) {
            if (cnpjCD == null || cnpjCD == '') cnpjCD = order.CNPJCD__c;
            orderReq = new OrderRequest(order, cnpjCD);
            //if (order.PedidoPai__r.Status != 'Aprovado' && order.PedidoPai__r.Status != 'Reprovado') shouldSend = false;
            if (order.PedidoPai__r.Status == 'Aprovado' && order.ExternalId__c == null) shouldSend = false;
        }

        System.debug('contractReq: ' + orderReq);

        String body;
        body = Json.serialize(orderReq);
        System.debug('Body: '+ body);

        if (shouldSend) {
            String resultString = '';
            HttpResponse resp = new HttpResponse();
            try {
                req.setBody(body);
                resp = new Http().send(req);
                
                System.debug(resp);
                System.debug(resp.getStatusCode());
                
                resultString = resp.getBody();
                System.debug('resp' + resultString);            
                String statusIntegration = null;
                if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {        
                    resultString = resp.getBody();
                    IntegrationUtils.WSLog('Pedido Aprovação/Rejeição', 'Outbound', body, resultString, false);
                } else {
                    resultString = resp.getBody();
                    IntegrationUtils.WSLog('Pedido Aprovação/Rejeição', 'Outbound', body, resultString, true);
                    statusIntegration = STATUS_APPROVAL_ERROR;
                }
    
                ResultClass resClass = null;
    
                try {
                    resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
                } catch (Exception e) {
                    system.debug(e.getMessage());
                }
                Boolean hasError    = statusIntegration == STATUS_APPROVAL_ERROR ? true : false;
                String errorMessage = statusIntegration == STATUS_APPROVAL_ERROR ? 'Erro de integração do pedido aprovado/rejeitado! Aguardar o tempo de reenvio automático. (Pedido já integrado/reservado).' : null;
                
                Order ord = new Order(Id = ordId);
                if (statusIntegration != null) {
                    ord.StatusIntegracao__c = statusIntegration;
                }
                
                if (orderReq.Approved) {
                    ord.MensagemErroIntegracao__c  = errorMessage;
                    ord.Status                     = hasError ? 'ErroIntegracao' : 'Pai - Aprovado';
                    ord.ErroIntegracaoAprovacao__c = hasError;
                } else {
                    ord.MensagemErroIntegracao__c  = errorMessage;
                    ord.Status                     = hasError ? 'ErroIntegracao' : 'Aguardando envio de rejeição';
                    ord.ErroIntegracaoRejeitado__c = hasError;
                }
    
                OrderHandler.disableTrigger();
                update ord;
                OrderHandler.enableTrigger();

                if (ord.Status == 'Aguardando envio de rejeição') {
                    ord.Status = 'Cancelado';
                    OrderHandler.disableTrigger();
                    update ord;
                    OrderHandler.enableTrigger();
                }
    
            } catch (Exception e) {
                System.debug(e.getMessage() +''+e.getStackTraceString());
                resultString = e.getMessage();
            }
        }        
    }
    
    public static String getExternalId(String val){
        return val.trim().substring(5, val.length());
    }
}