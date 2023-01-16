@isTest
public with sharing class BatchReprocessPurchasesTest {
    @TestSetup
    static void makeData(){
        Account accountPJ = TestUtility.createAccPJ();
        insert accountPJ;
        Order order = TestUtility.createOrder(accountPJ);
        order.PedidoPendente__c = true;
        insert order;
        SolicitacaoCompras__c purchases = TestUtility.createPurchases(order);
        purchases.StatusIntegracao__c = 'Erro';
        insert purchases;
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaPurchaseReqAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-AcaoComercialSincrono',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;
        GeneralParameters__c parameters = new GeneralParameters__c();
        parameters.Name = 'Parametro geral';
        parameters.Email__c = 'thomas.anderson@nescara.com';
        parameters.StockNotification__c = 4;
        parameters.CentroCusto__c = '4';
        insert parameters;
    }
    
    @isTest
    public static void BatchReprocessPurchases() {
        BatchReprocessPurchasesSchedule batchSchedule = new BatchReprocessPurchasesSchedule();
        batchSchedule.execute(null);
        BatchReprocessPurchasesSchedule.scheduleBatch();
    }
}
