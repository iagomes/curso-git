global class BatchResendOrder implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    
    public static void executeBatch(Order ord) {
        Boolean approvalError = false;
        Boolean cancellingError = false;
        Boolean confirmingError = false;
        Boolean rejectionError = false;
        Set<String> invalidIntegrationStatus = new Set<String>{'Bloqueado ERP', 'Liberado ERP', 'Aguardando separação', 'Separado', 'Faturado', 'Cancelado','Aguardando envio de cancelamento'};
        System.debug('ord: '+ord);
        List<Order> orderList = new List<Order>{ord};
        Id ordId = null;
        for (Order o : orderList){
            ordId = o.id;
            if (o.ErroIntegracaoConfirmacao__c && o.ExternalId__c == null) {
                System.debug('entrou ErroIntegracaoConfirmacao');
                confirmingError = true;
            } else if (o.ErroIntegracaoAprovacao__c && o.ExternalId__c != null && !invalidIntegrationStatus.contains(o.Status)) {
                System.debug('entrou ErroIntegracaoAprovacao');
                approvalError = true;
            } else if (o.ErroIntegracaoCancelamento__c && !invalidIntegrationStatus.contains(o.Status)) {
                System.debug('entrou ErroIntegracaoCancelamento');
                cancellingError = true;
            } else if (o.ErroIntegracaoRejeitado__c && o.ExternalId__c != null && !invalidIntegrationStatus.contains(o.Status)) {
                System.debug('entrou ErroIntegracaoRejeitado');
                rejectionError = true;
            }
        }
        if (ordId != null) {
            if (approvalError || rejectionError) {
                IntegrationApprovalOrderOUT.sendApprovalOrderToERP(ordId);
            } else if (cancellingError) {
                IntegrationCancelOrderOUT.FlowInputs flowInput = new IntegrationCancelOrderOUT.FlowInputs();
                flowInput.orderId = ordId;
                flowInput.reason = null;
                flowInput.subReason = null;
                flowInput.commentary = null;
                IntegrationCancelOrderOUT.sendCancelledOrder(new List<IntegrationCancelOrderOUT.FlowInputs>{flowInput});
            } else if (confirmingError) {
                IntegrationOrderOUT.sendOrderToERP(ordId);
            } 
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, ErroIntegracaoAprovacao__c, ErroIntegracaoCancelamento__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, ExternalId__c, StatusIntegracao__c, Status, CodigoIntegradora__c 
                                         FROM Order WHERE RecordTypeId != :OrderHelper.MOTHERORDER_RECORDTYPE AND CodigoIntegradora__c != null
                                                       AND (ErroIntegracaoAprovacao__c  = true 
                                                       OR ErroIntegracaoCancelamento__c = true 
                                                       OR ErroIntegracaoConfirmacao__c  = true
                                                       OR ErroIntegracaoRejeitado__c    = true
                                                       OR StatusIntegracao__c           = 'Não integrado')]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {        
        List<Order> orderList = (List<Order>) scope;
        executeBatch(orderList[0]);
    }
    
    global void finish(Database.BatchableContext BC) {
		
	}
}