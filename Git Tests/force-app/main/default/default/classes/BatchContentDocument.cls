global class BatchContentDocument implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date checkDate = Test.isRunningTest() ? Date.today().addDays(1) : Date.today().addDays(-1);
        return Database.getQueryLocator([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Description != null AND CreatedDate <: checkDate]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {        
        List<ContentVersion> listCtVersion = (List<ContentVersion>) scope;
        
        Set<Id> setCtDocumentId = new Set<Id>();

        for (ContentVersion ctVersion : listCtVersion) {
            setCtDocumentId.add(ctVersion.ContentDocumentId);
        }

        List<ContentDocument> listCtDocumentToDelete = new List<ContentDocument>();

        for (ContentDocument ctDocument : [SELECT Id, createdDate FROM ContentDocument WHERE Id IN: setCtDocumentId]) {
            listCtDocumentToDelete.add(ctDocument);
        }

        if (!listCtDocumentToDelete.isEmpty()) {
            delete listCtDocumentToDelete;
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
