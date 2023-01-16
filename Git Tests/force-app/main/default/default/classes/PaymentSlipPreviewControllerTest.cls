@isTest
private class PaymentSlipPreviewControllerTest {
    @isTest
    static void testGetPaymentSlip(){
        Test.setMock(HttpCalloutMock.class, new PaymentSlipCalloutMock());

        Integracoes__c integracao = new Integracoes__c(
			Name        = 'ElfaTitulosAbertosAPI',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integracao;

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Pessoa jurídica').getRecordTypeId();
        System.debug('recordTypeId: ' + recordTypeId);
        Account acc = new Account(
            name ='Test Account',
            recordTypeId = recordTypeId
        );
        insert acc;

        Order order = TestUtility.createOrder(acc);
        insert order;
        NotasFiscais__c nf = new NotasFiscais__c(
            Pedido__c = order.Id,
            Name = 'Test Nf',
            Conta__c = acc.id
        );
        insert nf;

        Test.startTest();
        String json  = PaymentSlipPreviewController.getPaymentSlip(nf.id);
        String json2 = PaymentSlipPreviewController.getPaymentTitle(acc.id);
        Test.stopTest();
        
        System.debug('Json2: ' + json2);
        System.assertEquals('{"EMPRESA":"ATRIAL"}', json);
    }
}