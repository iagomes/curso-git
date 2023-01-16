@isTest
global with sharing class BatchReservationIncAltTest {
    @TestSetup
    static void makeData(){
        
        Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
        insert fornecedor;

        Product2 product = TestUtility.createProduct();
        product.ExternalId__c = '1234';
        product.UnidadeMedida__c = 'F';
        product.fornecedor__c = fornecedor.Id;
        insert product;

        Product2 product2 = TestUtility.createProduct();
        product2.ExternalId__c = '1934';
        product2.UnidadeMedida__c = 'F';
        product2.fornecedor__c = fornecedor.Id;
        insert product2;
        
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '61182609000113';

        Reserva__c reservation = TestUtility.createReservation();
        reservation.CodigoReserva__c = '12345623456';
        insert reservation;

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;

        ProdutoReserva__c reservationProd2 = TestUtility.createReservationProduct(reservation.Id, product2.Id);
        reservationProd2.Armazem__c = '20';
        reservationProd2.StatusReserva__c ='Erro de integração';
        insert reservationProd2;        
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest;

        DestinatarioReserva__c reservationDest2 = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest2;
        
        // reservation.StatusReserva__c = IntegrationConstants.STATUS_INTEGRATION_ERROR;
        // update reservation;

        List<Id> reservationsList = new List<Id>();
        reservationsList.add(reservation.Id);

        Integracoes__c opp = new Integracoes__c();
        opp.Name = 'ElfaReservationINCAPI';
        opp.EndPoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Reservas';
        opp.Method__c = 'POST';
        opp.Password__c = 'Elf@Cloud';
        opp.User__c = 'cloud.dev@grupoelfa.com.br';
        insert opp;

        
        //List<ReservaProduto__c> resLis = new List<ReservaProduto__c>([SELECT CodigoReservaTOTVS__c FROM ReservaProduto__c WHERE Id IN :reservationsList AND CodigoReservaTOTVS__c != '']);
        //System.assertEquals(1, resLis.size());
    }

        
    @isTest
    public static void BatchReprocessReservation() {

        Test.startTest();
            BatchReservationIncAltScheduled sendResenvation = new BatchReservationIncAltScheduled();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
            sendResenvation.execute(null);
            BatchReservationIncAltScheduled.scheduleBatch();
        Test.stopTest();
        
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
}
