@isTest
global class IntegrationReservationOUTTest {
    @isTest
    global static void testIncIntegration() {
        
        Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
        insert fornecedor;

        Product2 product = TestUtility.createProduct();
        product.ExternalId__c = '1234';
        product.UnidadeMedida__c = 'F';
        product.fornecedor__c = fornecedor.Id;
        insert product;
        
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '61182609000113';

        Reserva__c reservation = TestUtility.createReservation();
        insert reservation;

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;

        ProdutoReserva__c reservationProd2 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd2.Armazem__c = '20';
        insert reservationProd2;        
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest;

        DestinatarioReserva__c reservationDest2 = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest2;

        List<Id> reservationsList = new List<Id>();
        reservationsList.add(reservation.Id);

        Integracoes__c opp = new Integracoes__c();
        opp.Name = 'ElfaReservationINCAPI';
        opp.EndPoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reservas';
        opp.Method__c = 'POST';
        opp.Password__c = 'Elf@Cloud';
        opp.User__c = 'cloud.dev@grupoelfa.com.br';
        insert opp;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
            IntegrationReservationOUT.sendToProtheus(reservationsList);
        Test.stopTest();
        
        List<Reserva__c> resLis = new List<Reserva__c>([SELECT CodigoReserva__c FROM Reserva__c WHERE Id IN :reservationsList AND CodigoReserva__c != '']);
        System.assertEquals(1, resLis.size());
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        global MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Cadastro realizado com Sucesso !!!","detailMessage":"000001"}');
            return res;
        }
    }

    @isTest
    global static void testAltIntegration() {
        
        Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
        insert fornecedor;

        Product2 product = TestUtility.createProduct();
        product.ExternalId__c = '1234';
        product.UnidadeMedida__c = 'F';
        product.fornecedor__c = fornecedor.Id;
        insert product;
        
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '61182609000113';

        Reserva__c reservation = TestUtility.createReservation();
        insert reservation;

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest;

        reservation.CodigoReserva__c = '000001';
        update reservation;

        List<Id> reservationsList = new List<Id>();
        reservationsList.add(reservation.Id);
        
        Integracoes__c oppAlt = new Integracoes__c();
        oppAlt.Name = 'ElfaReservationDelAPI';
        oppAlt.EndPoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reservas';
        oppAlt.Method__c = 'DELETE';
        oppAlt.Password__c = 'Elf@Cloud';
        oppAlt.User__c = 'cloud.dev@grupoelfa.com.br';
        insert oppAlt;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
            IntegrationReservationOUT.sendToProtheus(reservationsList);
        Test.stopTest();

        List<Reserva__c> resLis = new List<Reserva__c>([SELECT CodigoReserva__c FROM Reserva__c WHERE Id IN :reservationsList AND CodigoReserva__c != '']);
        System.assertEquals(1, resLis.size());
    }

}
