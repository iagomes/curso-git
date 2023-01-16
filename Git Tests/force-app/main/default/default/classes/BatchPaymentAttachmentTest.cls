@isTest
public with sharing class BatchPaymentAttachmentTest {
    @TestSetup
    static void makeData(){
        ContentVersion ctVersionNf = TestUtility.createContentVersion();
        ctVersionNf.Description = 'nf001';
        insert ctVersionNf;
        ContentVersion ctVersionTit = TestUtility.createContentVersion();
        ctVersionTit.Description = 'tit001';
        insert ctVersionTit;
        Account acc = TestUtility.createAccPJ();
        insert acc;
        Order ord = TestUtility.createOrder(acc);
        insert ord;
        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        insert nf;
        TitulosAbertos__c tit = TestUtility.createTituloAberto(acc, nf);
        insert tit;

        Integracoes__c integration =  new Integracoes__c(
			Name        = 'GetPaymentAttachment',
			Method__c   = 'POST',
			Endpoint__c = 'https://teste.com/',
			User__c     = 'test@test.com.br',
			Password__c = 'test'
		);
        insert integration;
    }
    
    @isTest
    public static void BatchPaymentAttachment() {
        List<ContentDocument> contentDocumentList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        List<Order> orderList = [SELECT Id, AttachmentId__c, ComprovanteAnexado__c, FileIntegrationStatus__c FROM Order];
        
        orderList[0].AttachmentId__c = contentDocumentList[0].Id;
        orderList[0].ComprovanteAnexado__c = true;
        orderList[0].FileIntegrationStatus__c = 'Erro';
        OrderHandler.disableTrigger();
        update orderList;
        OrderHandler.enableTrigger();

        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = orderList[0].Id;
        link.ContentDocumentId = contentDocumentList[0].Id;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';
        insert link;

        BatchPaymentAttachmentSchedule batchSchedule = new BatchPaymentAttachmentSchedule();
        batchSchedule.execute(null);
        BatchPaymentAttachment batchPA = new BatchPaymentAttachment();
        batchPA.execute(null, orderList);
        BatchPaymentAttachmentSchedule.scheduleBatch();
    }
}
