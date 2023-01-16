global without sharing class IntegrationVansOrderOUT {

    global class VansOrderRequest {
        public List<OrderRequest> pedidos;

        public VansOrderRequest() {
            this.pedidos = new List<OrderRequest>();
        }
    }
    
    global class OrderRequest {
        public String filial;
        public String NumeroPedido;
        public String CondicaoPagamento;
        public String Obs_NF;

        public OrderRequest(Order ord) {
            this.filial            = '';
            this.NumeroPedido      = ord.ExternalId__c;
            this.CondicaoPagamento = ord.CondicaoPagamento__r?.ExternalId__c;
            this.Obs_NF            = ord.MensagemNF__c;
        }
    }

    global class ResultClass{
        public String  result   { get; set; }
        public Boolean incluido { get; set; }
    }

    public static void sendVansOrderToERP(Id ordId) {
        
        Integracoes__c integration = Integracoes__c.getValues('ElfaVansOrderAPI');        
        String method              = integration.Method__c;
        String endpoint            = integration.Endpoint__c;
        String username            = integration.User__c;
        String password            = integration.Password__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setMethod(method);
        req.setTimeout(120000);

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));

        VansOrderRequest labReq = new VansOrderRequest();

        for (Order ord : [
                            SELECT 
                                Id, 
                                ExternalId__c, 
                                CondicaoPagamento__r.ExternalId__c, 
                                MensagemNF__c
                            FROM Order 
                            WHERE Id = :ordId
                        ]) {
            labReq.pedidos.add(new OrderRequest(ord));
        }

        System.debug('labReq: ' + labReq);

        String body;
        body = Json.serialize(labReq);
        System.debug('Body: '+ body);

        String resultString = '';
        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            System.debug(resp);
            System.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            System.debug('resp' + resultString);
            Boolean hasError = false;

            if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {        
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Pedido Vans', 'Outbound', body, resultString, false);
            } else {
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Pedido Vans', 'Outbound', body, resultString, true);
                hasError = true;
            }

            ResultClass resClass = null;
            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);                
            } catch (Exception e) {
                hasError = true;
                System.debug(e.getMessage());
            }

        } catch (Exception e) {
            resultString = e.getMessage();
            System.debug(resultString);
        }
    }

    @InvocableMethod(label='update laboratory order' description='Method to update laboratory order')
    public static List<String> updateLabOrder(List<FlowInputs> flowInputs){
        Id labId          = null;
        for (FlowInputs flowInput : flowInputs) {
            labId     = flowInput.labId;
        }
        PedidoIntegradora__c labOrd = new PedidoIntegradora__c();
        for (PedidoIntegradora__c lab : [SELECT Id, Status__c FROM PedidoIntegradora__c WHERE Id = :labId]) {
            lab.Status__c = 'Aguardando confirmação de cancelamento';
            labOrd = lab;
        }
        PedidoIntegradoraHandler.disableTrigger();
        update labOrd;
        PedidoIntegradoraHandler.enableTrigger();

        return null;
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String labId;
    }
}
