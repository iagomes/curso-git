@isTest
public with sharing class ReservationRecipientTriggerTest {
    
    @TestSetup
    static void makeData(){

        Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
        insert fornecedor;

        Product2 product = TestUtility.createProduct();
        product.ExternalId__c = '1234';
        product.UnidadeMedida__c = 'F';
        product.fornecedor__c = fornecedor.Id;
        product.CategoriaComercial__c = 'G';
        insert product;

        GrupoCliente__c grupo = new GrupoCliente__c();
        grupo.CodigoGrupo__c = '5';
        insert grupo;
        
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '61182609000113';
        acc.GrupoCliente__c = grupo.Id;
        insert acc;

        Reserva__c reservation = TestUtility.createReservation();
        reservation.RecordTypeId = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaCliente').getRecordTypeId();
        insert reservation;      

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;

        ProdutoReserva__c reservationProd2 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd2.Armazem__c = '20';
        insert reservationProd2;        

        ProdutoReserva__c reservationProd3 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd3.Armazem__c = '30';
        insert reservationProd3;      
        
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, acc.Id);
        reservationDest.CodigoRegiao__c = '';
        reservationDest.Cliente__c = null;
        reservationDest.GrupoClientes__c = grupo.id;
        insert reservationDest;

        DestinatarioReserva__c reservationDest2 = TestUtility.createReservationDest(reservation.Id, acc.Id);
        reservationDest2.CodigoRegiao__c = '';
        reservationDest2.GrupoClientes__c = null;
        reservationDest2.Cliente__c = acc.id;
        try {
            
        insert reservationDest2;            
        } catch (Exception ex) {
            

        System.debug(ex.getMessage());
            Boolean expectedExceptionThrown =  ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);

        } 

      

        ResponsabilidadeAprovacao__c respAprovacao = new ResponsabilidadeAprovacao__c();
        respAprovacao.UsuarioAprovador__c = UserInfo.getUserId();
        respAprovacao.Categorias__c = 'M';
        respAprovacao.CodigoMesa__c = 'TESTE';
        respAprovacao.Regiao__c ='ABCDE';
        respAprovacao.Categorias__c ='';
        respAprovacao.RecordTypeId =Schema.SObjectType.ResponsabilidadeAprovacao__c.getRecordTypeInfosByDeveloperName().get('AprovacaoReserva').getRecordTypeId();

        insert respAprovacao;

        ResponsabilidadeAprovacao__c respAprovacao2 = new ResponsabilidadeAprovacao__c();
        respAprovacao2.UsuarioAprovador__c = UserInfo.getUserId();
        respAprovacao2.Categorias__c = 'M';
        respAprovacao2.CodigoMesa__c = 'TESTE';
        respAprovacao2.Regiao__c ='ABCDE';
        respAprovacao2.Categorias__c ='G';
        respAprovacao2.RecordTypeId =Schema.SObjectType.ResponsabilidadeAprovacao__c.getRecordTypeInfosByDeveloperName().get('AprovacaoReserva').getRecordTypeId();

        insert respAprovacao2;
    }

    @isTest
    public static void ReservationRecipientTriggerTest() {

        ReservationRecipientTriggerHelper desti = new ReservationRecipientTriggerHelper();

        List<DestinatarioReserva__c> lstDestinatarioReserva = [SELECT id FROM DestinatarioReserva__c];      

        ReservationRecipientTriggerHandler.disableTrigger();
        ReservationRecipientTriggerHandler.enableTrigger();        
        ReservationRecipientTriggerHandler.isTriggerEnabled();

        Test.startTest();
        
        delete lstDestinatarioReserva[1];

        update lstDestinatarioReserva[0];



        Test.stopTest();

    }
}
