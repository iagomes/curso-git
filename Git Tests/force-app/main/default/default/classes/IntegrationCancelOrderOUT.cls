public without sharing class IntegrationCancelOrderOUT {
    
    public static final Id MOTHERORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();

    public class OrderRequest {
        public String  BranchCGC;//CgcEmp;
        public String  InternalOrderNumber;//NumPedido;
        public String  ExternalOrderNumber;//NumPedInte;
        
        public OrderRequest(Order ord, String cnpjCD) {
            this.BranchCGC     = cnpjCD;
            this.InternalOrderNumber  = ord.ExternalId__c == null ? '000000' : getExternalId(ord.ExternalId__c);
            this.ExternalOrderNumber = ord.OrderNumber;
        }
    }

    public class ResultClass {
        public String  result   { get; set; }
        public Boolean incluido { get; set; }
    }

    @InvocableMethod(label='Cancel order' description='Cancel order and send to TOTVS')
    public static List<String> sendCancelledOrder(List<FlowInputs> flowInputs){
        Id ordId = null;
        String cancelReason = null;
        String cancelSubReason = null;
        String cancelCommentary = null;
        for (FlowInputs flowInput : flowInputs) {
            ordId = flowInput.orderId;
            cancelCommentary = flowInput.commentary;
            cancelSubReason = flowInput.subReason;
            cancelReason = flowInput.reason;
        }

        Set<Id> ordIdSet = new Set<Id>();
        Boolean isParent = false;
        List<Order> ordListToUpdate = new List<Order>();
        for (Order order : [SELECT Id, ExternalId__c, Status, StatusIntegracao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c, RecordTypeId,
                                PedidoOriginal__c, PedidoPendente__c, PedidoPai__c, ErroIntegracaoCancelamento__c, MensagemErroIntegracao__c,
                                Description, ErroIntegracaoAprovacao__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, MotivoCancelamento__c,
                                SubmotivosCancelamento__c, ComentariosCancelamento__c, OwnerId, AccountId, LastModifiedDate 
                            FROM Order WHERE Id = :ordId AND Status != 'Cancelado']) {
            cancelReasons(order, cancelReason, cancelSubReason, cancelCommentary);
            if (order.RecordTypeId == MOTHERORDER_RECORDTYPE) {
                order.Status = 'Cancelado';
                if (!order.PedidoPendente__c) {
                    isParent = true;
                }
            } else {
                if ((order.Status == 'ErroIntegracao' && order.StatusIntegracao__c == 'Não integrado') || order.Status == 'Em digitação') {
                    order.Status = 'Cancelado';
                    clearErrors(order, false);
                } else {
                    ordIdSet.add(order.Id);
                }
            }
            ordListToUpdate.add(order);
        }

        if (isParent) {
            OrderHandler.disableTrigger();
            recallApprovalProcess(ordId);
            OrderHandler.enableTrigger();
            for (Order order : [SELECT Id, ExternalId__c, Status, StatusIntegracao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c, RecordTypeId,
                                    PedidoOriginal__c, PedidoPendente__c, PedidoPai__c, ErroIntegracaoCancelamento__c, MensagemErroIntegracao__c,
                                    Description, ErroIntegracaoAprovacao__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, MotivoCancelamento__c,
                                    SubmotivosCancelamento__c, ComentariosCancelamento__c, OwnerId, AccountId, LastModifiedDate 
                                FROM Order WHERE PedidoPai__c = :ordId AND Status != 'Cancelado']) {
                cancelReasons(order, cancelReason, cancelSubReason, cancelCommentary);
                if (order.Status == 'ErroIntegracao' && order.StatusIntegracao__c == 'Não integrado') {
                    order.Status = 'Cancelado';
                    clearErrors(order, false);
                } else {
                    ordIdSet.add(order.Id);
                }
                ordListToUpdate.add(order);
            }
        }
        List<Order> sendEmailCancelledOrders = new List<Order>();

        for (Order order : [SELECT Id, ExternalId__c, Status, StatusIntegracao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c, RecordTypeId,
                                PedidoOriginal__c, PedidoPendente__c, PedidoPai__c, ErroIntegracaoCancelamento__c, MensagemErroIntegracao__c,
                                Description, ErroIntegracaoAprovacao__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, MotivoCancelamento__c,
                                SubmotivosCancelamento__c, ComentariosCancelamento__c, OwnerId, AccountId, LastModifiedDate  
                            FROM Order WHERE PedidoOriginal__c = :ordId AND Status = 'Em digitação']) {
            order.Status = 'Cancelado';
            cancelReasons(order, cancelReason, cancelSubReason, cancelCommentary);
            ordListToUpdate.add(order);
            sendEmailCancelledOrders.add(order);
        }

        if (!sendEmailCancelledOrders.isEmpty()) {            
            SendEmailMessage.sendEmailMessageCancelledOrder(sendEmailCancelledOrders);
        }

        if (!ordListToUpdate.isEmpty()) {
            OrderHandler.disableTrigger();
            update ordListToUpdate;
            OrderHandler.enableTrigger();
        }

        if (!ordIdSet.isEmpty()) {     
            if (ordIdSet.size() < 50){
                System.enqueueJob(new IntegrationCancelOrderQueueable(0, new List<Id>(ordIdSet)));      
            }            
        }
        return null;
    }

    public static void sendCancelOrderToERP(Id ordId) {

        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaCancelOrderAPI');
        
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
        Order ord;
        for (Order order : [SELECT Id, ExternalId__c, Status, StatusIntegracao__c, OrderNumber, CNPJCD__c, RejeicaoProcesso__c, ErroIntegracaoCancelamento__c, CodigoIntegradora__c,
                                    MensagemErroIntegracao__c, Description, ErroIntegracaoAprovacao__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c
                            FROM Order WHERE Id = :ordId]) {
            orderReq = new OrderRequest(order, cnpjCD);
            ord = order;
        }

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
                IntegrationUtils.WSLog('Cancelamento Pedido', 'Outbound', body, resultString, hasError);
            } else {
                hasError = true;
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Cancelamento Pedido', 'Outbound', body, resultString, hasError);
                statusIntegration = IntegrationOrderOUT.STATUS_ERROR;
            }

            ResultClass resClass = null;
            String errorMessage  = null;
            
            try {
                system.debug('resultString: ' + resultString);
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
                system.debug('resClass: ' + resClass);
                hasError = resClass?.incluido != null ? !resClass.incluido : false;
                errorMessage = hasError ? resClass.result : null;
            } catch (Exception e) {
                system.debug(e.getMessage());
                hasError = true;
                clearErrors(ord, hasError);
                if (ord.ExternalId__c == null) {
                    ord.Status = 'Cancelado';
                    ord.StatusIntegracao__c = null;
                    ord.MensagemErroIntegracao__c = null;
                    OrderHandler.disableTrigger();
                    update ord;
                    OrderHandler.enableTrigger();
                } else {
                    throw new IntegrationCancelOrderException('Erro de integração do cancelamento do pedido. Aguardar reenvio automático para o cancelamento no Protheus.');
                }
            }
            
            ord.StatusIntegracao__c           = statusIntegration;
            ord.MensagemErroIntegracao__c     = errorMessage;
            clearErrors(ord, hasError);
            
            if (!hasError)  {
                if (ord.ExternalId__c == null) {
                    ord.Status = 'Cancelado';
                } else {
                    ord.Status = 'Aguardando envio de cancelamento';
                }
                ord.StatusIntegracao__c = null;
                ord.Description         = null;
                
                OrderHandler.disableTrigger();
                update ord;
                OrderHandler.enableTrigger();

                if (ord.CodigoIntegradora__c != null) {
                    List<PedidoIntegradora__c> labOrderList = new List<PedidoIntegradora__c>();
                    for (PedidoIntegradora__c labOrd : [SELECT Id, Status__c FROM PedidoIntegradora__c WHERE CodigoIntegradora__c = :ord.CodigoIntegradora__c]) {
                        labOrd.Status__c = 'Aguardando envio de cancelamento';
                        labOrderList.add(labOrd);
                    }
                    if (!labOrderList.isEmpty()) {
                        update labOrderList;
                    }
                }
            }
        } catch (Exception e) {
            resultString = e.getMessage();
            throw new IntegrationCancelOrderException(resultString);
        }
    }

    public static String getExternalId(String val){
        return val.trim().substring(5, val.length());
    }

    public static void clearErrors(Order ord, Boolean hasError){
        ord.ErroIntegracaoCancelamento__c = hasError;
        ord.ErroIntegracaoAprovacao__c    = false;
        ord.ErroIntegracaoConfirmacao__c  = false;
        ord.ErroIntegracaoRejeitado__c    = false;
    }

    public static void cancelReasons(Order order, String reason, String subReason, String commentary) {
        order.MotivoCancelamento__c      = reason;
        order.SubmotivosCancelamento__c  = subReason;
        order.ComentariosCancelamento__c = commentary;
    }

    public static void recallApprovalProcess(Id ordId) {
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest> ();
        Map<Id, ProcessInstance> mapIdToProcessInstance = new Map<Id, ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE (TargetObjectId = :ordId)]);

        List<ProcessInstanceWorkItem> processInstanceWkItemList = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.Status FROM ProcessInstanceWorkItem WHERE ProcessInstanceId IN :mapIdToProcessInstance.keySet() AND ProcessInstance.Status = 'Pending'];
        for(ProcessInstanceWorkItem workItem : processInstanceWkItemList){
            System.debug('workItem: ' + workItem);
            // if there's a work item, set the action to 'removed' and execute
            System.debug('mapIdToProcessInstance: ' + mapIdToProcessInstance);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Removed');
            req.setWorkitemId(workItem.Id);
            requests.add(req);
        }

        Approval.ProcessResult[] processResults;
        if (!requests.isEmpty()) {
            processResults = Approval.process(requests, true);
        }
    }
    public class IntegrationCancelOrderException extends Exception {}

    public class FlowInputs{
    
        @InvocableVariable
        public String orderId;
        
        @InvocableVariable
        public String reason;

        @InvocableVariable
        public String subReason;

        @InvocableVariable
        public String commentary;
    }
}
