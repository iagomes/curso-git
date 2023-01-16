@isTest
public class EmailMessageTest {
    
    @testSetup
    static void testSetup() {
        
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        insert c;
        
        c.Status = 'Em Andamento';
        update c;
       
  
    }

    @isTest
    static void setCaseEmailMessageSubject() {
        
        Case cs = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@testService.com';
        email.Incoming = true;
        email.ToAddress= 'totest@testService.com';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = cs.Id; 
        insert email;

        email = [SELECT Subject FROM EmailMessage LIMIT 1];
        
        System.assert(email.Subject.contains(cs.CaseNumber));
    }
    
    @isTest
    static void emailMessageTriggerHandler() {
        
        EmailMessageTriggerHandler handler = new EmailMessageTriggerHandler(null, null, null, null, null);
        
        handler.afterDelete();
        handler.afterInsert();
        handler.afterUpdate();
        handler.beforeDelete();
        handler.beforeUpdate();
        EmailMessageTriggerHandler.disableTrigger();
        EmailMessageTriggerHandler.enableTrigger();
    }
    
}