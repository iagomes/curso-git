@isTest
public with sharing class ContentDocumentHelperTest {
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
    }

    @isTest
    public static void deletePaymentAttachmentTest() {
        List<ContentDocument> contentDocumentList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        List<Order> order = [SELECT Id FROM Order];

        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = order[0].Id;
        link.ContentDocumentId = contentDocumentList[0].Id;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';
        insert link;

        delete contentDocumentList;
    }
    
    @isTest
    public static void ContentDocumentHelperTest() {
        ContentDocumentHandler.disableTrigger();
        ContentDocumentHandler.enableTrigger();
    }
}
