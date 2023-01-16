@isTest
public with sharing class ReservationProductTriggerTest {
   
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
        
        Account acc = TestUtility.createAccount();
        acc.CNPJ__c = '61182609000113';
       
        Reserva__c reservation = TestUtility.createReservation();
        reservation.RecordTypeId = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaRegional').getRecordTypeId();
        insert reservation;

        Reserva__c reservation2 = TestUtility.createReservation();
        reservation2.RecordTypeId = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaRegional').getRecordTypeId();
        reservation2.CodigoReserva__c = '5';
        insert reservation2;

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;

        ProdutoReserva__c reservationProd2 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd2.Armazem__c = '20';
        insert reservationProd2;        

        ProdutoReserva__c reservationProd3 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd3.Armazem__c = '30';
        insert reservationProd3;              
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest;

        DestinatarioReserva__c reservationDest2 = TestUtility.createReservationDest(reservation.Id, acc.Id);
        insert reservationDest2;

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
    public static void ReservationProductTest() {

        ReservationProductTriggerHelper reserva = new ReservationProductTriggerHelper();

        List<Reserva__c> lstReserva = [SELECT id FROM Reserva__c];      
        List<ProdutoReserva__c> lstProdutoReserva = [SELECT id,ReservaRecebedora__c,Produto__c,QuantidadeTransferida__c, Armazem__c, Preco__c FROM ProdutoReserva__c];      
        List<ResponsabilidadeAprovacao__c> lstResponsabilidadeAprovacao = [SELECT id,Regiao__c,Categorias__c,UsuarioAprovador__c FROM ResponsabilidadeAprovacao__c];      

        System.debug(lstResponsabilidadeAprovacao);
        System.debug([
            SELECT id, Regiao__c, Categorias__c, UsuarioAprovador__c
            FROM
            ResponsabilidadeAprovacao__c
            WHERE
            Regiao__c IN('ABCDE')
            AND RecordTypeId IN('012q0000000BnOQAA0')
            AND (Categorias__c INCLUDES('G') 
            OR Categorias__c = null)                                                               
        ]);
        ReservationProductTriggerHandler.disableTrigger();
        ReservationProductTriggerHandler.enableTrigger();        
        ReservationProductTriggerHandler.isTriggerEnabled();

        Test.startTest();

        ReservationProductTriggerHelper.createInstanceReservationProduct(lstProdutoReserva[1]);
        
        delete lstProdutoReserva[1];

        lstProdutoReserva[2].ReservaRecebedora__c = lstReserva[0].Id;
        lstProdutoReserva[2].StatusReserva__c = 'Aguardando Integração';
        update  lstProdutoReserva[2];

        lstProdutoReserva[0].StatusReserva__c = 'Aguardando aprovação';
        lstProdutoReserva[0].QuantidadeConsumida__c = 4;
        update lstProdutoReserva[0];

        List<ProcessInstanceWorkitem> lstProcessInstanceWorkitem =  [SELECT p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId,
                                                                    p.ProcessInstanceId,
                                                                    p.OriginalActorId,
                                                                    p.Id,
                                                                    p.ActorId FROM ProcessInstanceWorkitem p
                                                                    WHERE p.ProcessInstance.TargetObjectId = : lstProdutoReserva[0].Id];


        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

        // Use the ID from the newly created item to specify the item to be worked
        req2.setWorkitemId(lstProcessInstanceWorkitem[0].Id);

        // Submit the request for approval
        Approval.ProcessResult result2 = Approval.process(req2);


        lstProdutoReserva[0].StatusReserva__c = 'Ativa';
        update lstProdutoReserva[0];

        Test.stopTest();

    }
}