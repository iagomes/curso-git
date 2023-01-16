@isTest
public class CaseControllerTest {
    
    @testSetup
    public static void setup() {
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Order ord = TestUtility.createOrder(acc);
        insert ord;        
        
        NotasFiscais__c nf = TestUtility.createNotaFiscal(ord, acc);
        nf.Conta__c = acc.Id;
        insert nf;     
        
        Group queue = [SELECT Id FROM Group WHERE DeveloperName ='AtendimentoAoClienteQueue'];
        
        Case c = TestUtility.createCase(acc, ctt);
        c.NotaFiscal__c = nf.Id;
        c.OwnerId = queue.Id;
        insert c;          
    }
    
    @isTest
    public static void changeOwner() {
        
        Case record = [SELECT Id, OwnerDeveloperName__c FROM Case];
        
        System.assertEquals('AtendimentoAoClienteQueue', record.OwnerDeveloperName__c);
        
        record = new Case ( Id = record.Id);
        record.ResponsavelAtendimento__c = UserInfo.getUserId();
        record.Type = 'Incidente';
        record.Razao__c = 'Devolução';
        record.Motivo__c = 'Cadastro';
        record.FormatoDeDevolucao__c = 'Virtual';
        record.Submotivo__c = 'Cadastro do Cliente';        
        record.DevolucaoAtoOuPosEntrega__c = 'No Ato';
        record.ProdutoTermolabil__c = 'Sim';
        update record;
        
        CaseController.changeOwner(record.Id);
        
        record = [SELECT Id, OwnerDeveloperName__c FROM Case];
        
        System.assertEquals('Registration', record.OwnerDeveloperName__c);        
    }    
    
    @isTest
    public static void changeOwnerUnexpectedError() {
        
        try {
            CaseController.changeOwner(UserInfo.getUserId());
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }
        
    }
    
    @isTest
    public static void closeCaseDMLError() {
        
        try {
            CaseController.closeCase(UserInfo.getUserId());  
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }
        
        Case record = [SELECT Id FROM Case];
        try {
            CaseController.closeCase(record.Id);  
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        }        
        
    }      
    
    @isTest
    public static void closeCase() {
        
        Case record = [SELECT Motivo__c, Submotivo__c, Type, Razao__c, Status FROM Case];
        record.Status = 'Em Andamento';       
        record.Type = 'Solicitação';
        record.Razao__c = 'Cadastro';
        record.Motivo__c = 'Atualização de Cadastro';
        record.Submotivo__c = 'Cadastro do Cliente';
        update record;
        
        CaseController.closeCase(record.Id);
        
        record = [SELECT Status FROM Case]; 
        System.assertEquals('Closed', record.Status);
        
        try {
            CaseController.closeCase(record.Id);
        } catch (Exception ex) {
            System.assert(ex instanceof DMLException);
        }        
        
    }          
    
}