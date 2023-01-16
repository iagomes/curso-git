@isTest
public with sharing class BatchContentDocumentTest {

    @TestSetup
    static void makeData(){
        ContentVersion ctVersion = TestUtility.createContentVersion();
        insert ctVersion;
    }
    
    @isTest
    public static void BatchContentDocument() {
        BatchContentDocumentSchedule batchSchedule = new BatchContentDocumentSchedule();
        batchSchedule.execute(null);
        BatchContentDocumentSchedule.scheduleBatch();
    }
}
