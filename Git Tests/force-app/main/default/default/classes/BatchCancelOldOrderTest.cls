@isTest
public with sharing class BatchCancelOldOrderTest {

    @TestSetup
    static void makeData(){
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaCancelOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			// Endpoint__c = 'https://use4-cai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reprocessamento-Pedido',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
       
    }
    
    @isTest
    public static void BatchCancelOldOrder() {

        Account account = TestUtility.createAccPJ();
        insert account;
        Product2 product = TestUtility.createProduct();
        insert product;
        Order order = TestUtility.createOrder(account);
        order.PedidoPendente__c   = true;
        order.Status              = 'ErroIntegracao';
        order.StatusIntegracao__c = 'Erro integração (Envio ao Protheus)';
        insert order;
        
        Datetime fourDaysAgo = Datetime.now().addDays(-4);
        Test.setCreatedDate(order.Id, fourDaysAgo);
        Test.startTest();
        Order newOrd = [SELECT Id, CreatedDate FROM Order LIMIT 1]; 
        BatchCancelOldOrderSchedule batchSchedule = new BatchCancelOldOrderSchedule();
        batchSchedule.execute(null);
        BatchCancelOldOrderSchedule.scheduleBatch();
        Test.stopTest();
    }
}