global without sharing class IntegrationLaboratoryOrderOUT {

    global class LaboratoryRequest {
        public String  TpInteg;
        public String  PedidoIntegrador;
        public Boolean aprovado;
        public String  CondicaoPagamento;
        public String  ObsNF;
        public String  FaturaParcial;
        public String  Laboratorio;

        public LaboratoryRequest(PedidoIntegradora__c lab, String partialInvoice) {
            this.TpInteg            = lab.TipoIntegradora__c;
            this.Laboratorio        = lab.Laboratorio__c;
            this.PedidoIntegrador   = lab.CodigoIntegradora__c;
            this.aprovado           = lab.StatusAprovacao__c == 'Aprovado';
            this.CondicaoPagamento  = lab.Pedido__r?.CondicaoPagamento__r?.ExternalId__c == null ? '' : lab.Pedido__r?.CondicaoPagamento__r?.ExternalId__c;
            this.ObsNF              = lab.Pedido__r?.MensagemNF__c == null ? '' : lab.Pedido__r?.MensagemNF__c;
            this.FaturaParcial      = partialInvoice;
        }
    }

    global class ResultClass{
        public String  result   { get; set; }
    }

    @InvocableMethod(label='Approve or reject laboratory order' description=' Method to approve or reject laboratory order')
    public static List<String> ApproveRejectLaboratoryOrder(List<FlowInputs> flowInputs){
        Id labId          = null;
        Boolean isApprove = true;
        String partialInvoice = '';
        for (FlowInputs flowInput : flowInputs) {
            labId     = flowInput.labId;
            isApprove = flowInput.isApprove;
            partialInvoice = flowInput.partialInvoice;
        }

        PedidoIntegradora__c lab = new PedidoIntegradora__c(
            Id                 = labId,
            StatusAprovacao__c = isApprove ? 'Aprovado' : 'Reprovado',
            AprovadoParcial__c = partialInvoice == 'S' ? true : false
        );

        if (validateUserApprover(labId)) {

            PedidoIntegradoraHandler.disableTrigger();
            update lab;
            PedidoIntegradoraHandler.enableTrigger();
            System.enqueueJob(new IntegrationLaboratoryOrderQueueable(0, new List<Id>{labId}, partialInvoice));

            return new List<String>{'Success'};

        }else{
            
            return null;
        }
        
        //return null;
    }

    public static void sendLaboratoryToERP(Id labId, String partialInvoice) {
        
        Integracoes__c integration = Integracoes__c.getValues('ElfaLaboratoryOrderAPI');        
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

        LaboratoryRequest labReq;

        for (PedidoIntegradora__c lab : [
                                            SELECT 
                                                Id, 
                                                CodigoIntegradora__c, 
                                                TipoIntegradora__c, 
                                                Laboratorio__c,
                                                Status__c, 
                                                StatusAprovacao__c,
                                                Pedido__r.CondicaoPagamento__r.ExternalId__c,
                                                Pedido__r.MensagemNF__c
                                            FROM PedidoIntegradora__c 
                                            WHERE Id = :labId
                                        ]) {
            labReq = new LaboratoryRequest(lab, partialInvoice);
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
                IntegrationUtils.WSLog('Pedido Integradora', 'Outbound', body, resultString, false);
            } else {
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Pedido Integradora', 'Outbound', body, resultString, true);
                hasError = true;
            }

            ResultClass resClass = null;
            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);                
            } catch (Exception e) {
                hasError = true;
                System.debug(e.getMessage());
            }            

            PedidoIntegradora__c lab = new PedidoIntegradora__c(
                Id        = labId,
                EnviadoAprovacao__c = true,
                Status__c = hasError ? 'Erro de integração' : (labReq.aprovado ? 'Aguardando confirmação do Protheus' : 'Reprovado')
            );
            // if (labReq.aprovado) {
            //     lab.SolicitacaoAprovada__c = true;
            // } else {
            //     lab.RejeicaoProcesso__c = true;
            // }
            PedidoIntegradoraHandler.disableTrigger();
            update lab;
            PedidoIntegradoraHandler.enableTrigger();

        } catch (Exception e) {
            resultString = e.getMessage();
            System.debug(resultString);
        }
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String labId;
        
        @InvocableVariable
        public Boolean isApprove;
        
        @InvocableVariable
        public String partialInvoice;
    }

    public static Boolean validateUserApprover(Id labId) {

        Boolean isApprover = false;
        List<ProcessInstance> lstApp = [SELECT Id, (SELECT Id, Actor.name, ActorId, ProcessInstanceId FROM Workitems)
        FROM ProcessInstance  WHERE TargetObjectId =:labId];

        if (lstApp.size() > 0) {

            for (ProcessInstance processInstance : lstApp) {

                if (processInstance.Workitems.size() > 0) {

                    for (ProcessInstanceWorkitem  workItems : processInstance.Workitems) {

                        if (UserInfo.getUserId().equals(workItems.ActorId)) {
                            
                            isApprover = true;
                            break;
                        }
                        
                    }

                    if (isApprover) {
                        break;
                    }                    
                }                
            }            
        }

        return isApprover; 
     }
}
