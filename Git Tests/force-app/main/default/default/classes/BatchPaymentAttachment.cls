global class BatchPaymentAttachment implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, OrderNumber, PedidoPai__r.Status, AttachmentId__c, FileIntegrationStatus__c, ComprovanteAnexado__c, StatusIntegracao__c, Status FROM Order WHERE AttachmentId__c != NULL AND FileIntegrationStatus__c != 'Ok' AND ComprovanteAnexado__c = true AND PedidoPai__r.Status = 'Aprovado' AND StatusIntegracao__c = 'Pedido aguardando envio/processamento do comprovante de pagamento RA' AND Status = 'Aguardando comprovante']);
    }

    global void execute(Database.BatchableContext BC, List<Order> scope) {
        Map<Id, Id> documentToOrder = new Map<Id, Id>();
        List<ContentDocument> attachmentList = new List<ContentDocument>();

        for (Order order : scope) {
            documentToOrder.put(order.AttachmentId__c, order.Id);
        }

        for (ContentDocument document : [SELECT Id, Title FROM ContentDocument WHERE Id IN: documentToOrder.keySet()]) {
            attachmentList.add(document);
        }

        if (!attachmentList.isEmpty()) {
            for (ContentDocument document : attachmentList) {
                String statusIntegration = IntegrationPaymentAttachment.sendAttachment(documentToOrder.get(document.Id));
                System.debug('Status Envio de Comprovante: ' + statusIntegration);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
