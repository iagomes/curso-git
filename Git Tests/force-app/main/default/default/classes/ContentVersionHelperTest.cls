@isTest
public with sharing class ContentVersionHelperTest {
    
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
    public static void updateCtDocumentDescriptionTest() {
        ContentDocumentHelper ctDocumentHelper = new ContentDocumentHelper();
        ContentVersionHelper ctVersionHelper = new ContentVersionHelper();

        List<ContentVersion> listCtVersion = [SELECT Id, Description, ContentDocumentId, VersionData FROM ContentVersion LIMIT 2];

        ContentVersionHelper.updateCtDocumentDescription(listCtVersion);

        ContentVersionHandler.enableTrigger();
        ContentVersionHandler.disableTrigger();
    }

}
