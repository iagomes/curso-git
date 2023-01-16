@IsTest
public with sharing class TriggerHandlerV2Test {


     @TestSetup
    public static void init() {
        
        Account acc = TestUtility.createAccPJ();
        acc.Name = 'Account-1';
        acc.NumberOfEmployees = 0;
        acc.DescontoCliente__c = 2;
        acc.CNPJ__c = '47782743000124';
        acc.ExternalId__c = '47782743000124';
        insert acc;

        Account acc3 = TestUtility.createAccPJ();
        acc3.Name = 'Account-2';
        acc3.NumberOfEmployees = 0;
        acc3.ParentId = acc.Id;
        acc3.DescontoCliente__c = 2;
        acc.CNPJ__c = '34349677000151';
        acc.ExternalId__c = '34349677000151';
        insert acc3;

        Contact contact = TestUtility.createContact(acc.Id);
        contact.FirstName = 'contact1';
        insert contact;
        
        Contact contact3 = TestUtility.createContact(acc3.Id);
        contact3.LastName  = 'Class ContactHelper';
        contact3.Email	  = 'teste12213123@test.com';

        insert contact3;
    }

    @IsTest
    public static void testContructor() {
        
        TriggerHandlerV2 trg = new TriggerHandlerV2();
        TriggerHandlerV2.LoopCount trgLoop = new TriggerHandlerV2.LoopCount();
        trg.stopFixNewDataBeforeInsertOrUpdate();
        trg.restartFixNewDataBeforeInsertOrUpdate();
        trg.stopDoImportantAutomationsAfterInsertOrUpdate();
        trg.restartDoImportantAutomationsAfterInsertOrUpdate();
        trg.fixNewDataBeforeInsertOrUpdate();
        trg.doImportantAutomationsAfterInsertOrUpdate();
        trg.setMaxLoopCount(2);
        trg.clearMaxLoopCount();
        TriggerHandlerV2.bypass('OrderHandler');
        TriggerHandlerV2.clearBypass('OrderHandler');
        TriggerHandlerV2.isBypassed('OrderHandler');
        trg.addToLoopCount();
        trg.beforeInsert();
        trg.beforeUpdate();
        trg.beforeDelete();
        trg.afterInsert();
        trg.afterUpdate();
        trg.afterDelete();
        trg.afterUndelete();
        trg.validateBeforeInsert();
        trg.validateBeforeUpdate();
        trgLoop.getMax();
        trgLoop.getCount();
        trg.setTriggerContext('before insert',true);
        trg.setTriggerContext('before update',true);
        trg.setTriggerContext('before delete',true);
        trg.setTriggerContext('after insert',true);
        trg.setTriggerContext('after update',true);
        trg.setTriggerContext('after delete',true);
        trg.setTriggerContext('after undelete',true);
        trg.validateRun();
        trg.run();
       
        
    }
}
