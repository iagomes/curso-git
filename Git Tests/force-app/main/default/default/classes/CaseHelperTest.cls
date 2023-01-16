/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 18-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
@isTest
    public class CaseHelperTest {
    @isTest
    public static void markReopenedField_test() {
        
        
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        insert c;
        
        c.Status = 'Em Andamento';
        update c;
        
        CaseTH.disableTrigger();
        c.BypassValidationRules__c = true;
        c.Status = 'Finalizado';
        update c;
        CaseTH.enableTrigger();
        
        Test.startTest();
        
        c.Status = 'Atrasado';
        update c;
        c = [SELECT CasoReaberto__c FROM Case WHERE Id =: c.Id];
        
        c.BypassValidationRules__c = false;
        c.Status = 'Finalizado';
        update c;
        System.assert(c.CasoReaberto__c);
        Test.stopTest();
    }
    
    @isTest
    public static void closeCase() {
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        insert c;
        
        c.Status = 'Em Andamento';
        update c;
        
        Test.startTest();
        CaseController.closeCase(c.Id);
        Test.stopTest();
    }    
    
    @isTest
    public static void closeCaseWithError() {
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        insert c;
        
        Test.startTest();
        try {
            CaseController.closeCase(c.Id);
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }
       
        Test.stopTest();
    } 
    
    @isTest
    public static void changeCaseOwner() {
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        c.ResponsavelAtendimento__c = UserInfo.getUserId();
        insert c;
        
        Test.startTest();
        CaseController.changeOwner(c.Id);

        c = [SELECT Id, OwnerId, Status, BypassValidationRules__c FROM Case WHERE Id =: c.Id];

        c.Status = 'Atrasado';
        update c;        

        c.Status = 'Encerrado';
        c.BypassValidationRules__c = true;
        update c;

        try {
            CaseController.changeOwner(c.Id);
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }

        Test.stopTest();
    }    

    @isTest
    public static void changeCaseOwnerWithError() {

        try {
            CaseController.changeOwner(UserInfo.getUserId());
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }

    }        
    
    @isTest
    public static void checkDuplicatedIncoiceAssignment() {

        Case c1;
        Account acc = TestUtility.createAccount();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;

        Order ord = TestUtility.createOrder(acc);
        insert ord;
        
        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        nf.Conta__c = acc.Id;
        insert nf;
        
        c1 = TestUtility.createCase(acc, ctt);
        c1.NotaFiscal__c = nf.Id;
        insert c1;     

        Test.startTest();
    
        try {

            c1 = [SELECT CaseNumber, NotaFiscal__c FROM Case WHERE Id =: c1.Id];

            Case c2 = TestUtility.createCase(acc, ctt);
            insert c2;  
            
            c2.NotaFiscal__c = nf.Id;
            update c2;
            
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            String label = Label.CannotSaveNewCaseWhenOngoingCaseWithSameInvoiceNumber.replace('__CASENUMBER__', c1.CaseNumber);
            System.assert(ex.getMessage().contains(label));
        }

        Test.stopTest();
    } 
           
}