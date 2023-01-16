global without sharing class IntegrationPaymentAttachment {
    public static final String STATUS_INTEGRATED = 'Ok';
    public static final String STATUS_ERROR = 'Erro';

    global class OrderRequest {
        public String CgcEmp;
        public String NumPedido;
        public String comprovante;

        public OrderRequest (Order order, String attachment) {
            this.comprovante = attachment;
            this.NumPedido   = order.PedidoProtheusResumido__c;
            this.CgcEmp      = order.CNPJCD__c;
        }
    }

    @AuraEnabled
    public static void updatePayment(Id orderId, String documentId) {
        Order orderToUpdate;
        for (Order ord : [SELECT Id, AttachmentId__c, ComprovanteAnexado__c FROM Order WHERE Id = :orderId]) {
            orderToUpdate = ord;
        }
        if (orderToUpdate != null) {
            orderToUpdate.AttachmentId__c = documentId;
            orderToUpdate.ComprovanteAnexado__c = true;
            OrderHandler.disableTrigger();
            update orderToUpdate;
            OrderHandler.enableTrigger();
        }
    }
    
    @AuraEnabled
    public static String sendAttachment(Id orderId) {
        String statusIntegracao = STATUS_INTEGRATED;
        Integracoes__c integrationPayment = Integracoes__c.getValues('GetPaymentAttachment');

        String method   = integrationPayment.Method__c;
        String endpoint = integrationPayment.Endpoint__c;
        String username = integrationPayment.User__c;
        String password = integrationPayment.Password__c;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setMethod(method);
        request.setTimeout(120000);

        System.debug('Username : password =>');
        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));

        Order orderToIntegration = [SELECT Id, AttachmentId__c, PedidoProtheusResumido__c, CNPJCD__c FROM Order WHERE Id = :orderId][0];
        ContentDocument document = [SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.VersionData FROM ContentDocument WHERE Id = :orderToIntegration.AttachmentId__c][0];

        OrderRequest orderRequest = new OrderRequest(orderToIntegration, EncodingUtil.base64Encode(document.LatestPublishedVersion.VersionData));
        System.debug('OrderRequest =>');
        System.debug(orderRequest);
        
        String body;
        body = JSON.serialize(orderRequest);
        System.debug('Body: ' + body);

        String resultString = '';
        HttpResponse response = new HttpResponse();
        try {
            request.setBody(body);
            response = new Http().send(request);
            
            System.debug(response);
            System.debug(response.getStatusCode());
            
            resultString = response.getBody();
            System.debug('Response: ' + resultString);

            if (response.getStatusCode() == 200) {
                resultString = response.getBody();
                IntegrationUtils.WSLog('Envio do comprovante de pagamento', 'Outbound', body, resultString, false);
            } else {
                resultString = response.getBody();
                IntegrationUtils.WSLog('Envio do comprovante de pagamento', 'Outbound', body, resultString, true);
                statusIntegracao = STATUS_ERROR;
            }

            String integrationMessage = statusIntegracao == STATUS_ERROR ? 'Erro no envio do comprovante de para o Protheus, será reenviado novamente em 1 hora.' : 'Comprovante anexado ao pedido de venda com sucesso!!';
            Boolean hasError          = statusIntegracao == STATUS_ERROR;

            Order orderUpdate;
            if (statusIntegracao == STATUS_INTEGRATED) {
                orderUpdate = new Order(
                    Id = orderId,
                    Status = 'Aguardando aprovação RA',
                    FileIntegrationStatus__c    = statusIntegracao,
                    MessageIntegrationStatus__c = integrationMessage
                );
            } else {
                orderUpdate = new Order(
                    Id = orderId,
                    FileIntegrationStatus__c    = statusIntegracao,
                    MessageIntegrationStatus__c = integrationMessage
                );
            }

            OrderHandler.disableTrigger();
            update orderUpdate;
            OrderHandler.enableTrigger();

            System.debug('Status: ' + statusIntegracao);
        } catch (Exception e) {
            resultString = e.getMessage();
            IntegrationUtils.WSLog('Envio do comprovante de pagamento', 'Outbound', body, resultString, true);
        }
        return statusIntegracao;
    }

    @InvocableMethod(label='Send Order Attachment to Protheus' 
                    description='Send Order Attachment to Protheus')
    public static void flowSendAttachment(List<Id> orderIdList) {
        
        sendAttachment(orderIdList[0]);
    }
}
