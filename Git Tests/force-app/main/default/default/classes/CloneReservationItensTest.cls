@isTest
public with sharing class CloneReservationItensTest {
    @TestSetup
    static void makeData() {

        ListaCentroDistribuicao__c listCentroDistribuicao = TestUtility.createListaCentroDistribuicao();

        Account cliente = TestUtility.createInsertAccount();
        Reserva__c reserve = TestUtility.createAndInsertReservation();
        Product2 product2 = TestUtility.createAndInsertProduct();
        Product2 product2_2 = TestUtility.createAndInsertProduct();
        Product2 product2_3 = TestUtility.createAndInsertProduct();
        ProdutoReserva__c productResevation = TestUtility.createAndInsertReservationProduct(reserve.Id, product2.Id);
        ProdutoReserva__c productResevation_2 = TestUtility.createAndInsertReservationProduct(reserve.Id, product2_3.Id);
        // DestinatarioReserva__c reserveDestination = TestUtility.createReservationDest(reserve.Id, cliente.Id);
        Reserva__c reserveGetItens = TestUtility.createAndInsertReservation('30912842');
      
        Estoque__c inventory = TestUtility.createInsertStock('498324239', product2_2.Id);
        Estoque__c inventory_2 = TestUtility.createInsertStock('498324238', product2.Id);
        Estoque__c inventory_3 = TestUtility.createInsertStock('498324237', product2_3.Id);

        ProdutoReserva__c productResevationGetItens = TestUtility.createAndInsertReservationProduct(reserveGetItens.Id, product2_2.Id);

        System.debug('reserve ===> ' + reserve);
    }

    @isTest
    static void test_cloneReservationItens() {
       
        Reserva__c reserve = [SELECT id, Name FROM Reserva__c Limit 1];

        ProdutoReserva__c[] productResevationList = [SELECT Id, Reserva__c, Name, Produto__c, Produto__r.Name, Armazem__c, Reserva__r.CodigoCD__c, QuantidadeReservada__c, UltimaAprovacao__c, StatusReserva__c, QuantidadeAtiva__c, QuantidadeConsumida__c, Preco__c
        FROM ProdutoReserva__c 
        WHERE Reserva__c =: reserve.Id
        AND Reserva__r.CodigoCD__c != NULL 
        AND Armazem__c != NULL 
        AND Produto__c != NULL];

        System.debug('productResevationList.size() ==> ' + productResevationList.size());

        CloneReservationItens.FlowInputs flowInputs = new CloneReservationItens.FlowInputs();
        flowInputs.reservationToGetItens = reserve.Name;//'30912842';
        flowInputs.currentReservationId = reserve.Id;

        CloneReservationItens.FlowInputs[] flowInputsList = new CloneReservationItens.FlowInputs[]{};
        flowInputsList.add(flowInputs);

        CloneReservationItens.flowCloneReservationItens(flowInputsList);
    }
}