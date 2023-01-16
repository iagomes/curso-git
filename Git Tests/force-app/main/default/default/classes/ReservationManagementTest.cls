@isTest
public with sharing class ReservationManagementTest {
    
    @TestSetup
    static void makeData() {

    }

    @isTest
    static void test_getProducts() {
        Account cliente = TestUtility.createInsertAccount();
        Reserva__c reserve = TestUtility.createAndInsertReservation();
        Product2 product2 = TestUtility.createAndInsertProduct();
        Product2 product2_2 = TestUtility.createAndInsertProduct();
        DestinatarioReserva__c destinatario = TestUtility.createAndInsertReservationDest(reserve.Id, cliente.Id);

        ListaCentroDistribuicao__c listCentroDistribuicao = TestUtility.createListaCentroDistribuicao();
        Estoque__c inventory = TestUtility.createInsertStock('498324239', product2_2.Id);

        ProdutoReserva__c productResevationGetItens = TestUtility.createReservationProduct(reserve.Id, product2.Id);
        productResevationGetItens.Armazem__c = '20';
        productResevationGetItens.QuantidadeAtiva__c = 10;

        insert productResevationGetItens;
        
        ReservationManagement.ProductData productData = new ReservationManagement.ProductData(productResevationGetItens);
        ReservationManagement.ProductData[] productDataList = new ReservationManagement.ProductData[]{productData};

        ReservationManagement.getProducts(reserve.Id, '', '', '', '1');
        ReservationManagement.getReservedProducts(reserve.Id, '1', false);
        ReservationManagement.getUnlimitedReservedProducts(reserve.Id);
        ReservationManagement.getUnlimitedReservedProductsModal(reserve.Id);
        ReservationManagement.getReserveInformation(reserve.Id);
        ReservationManagement.transferProducts(JSON.serialize(productDataList), reserve.Id, reserve.Id);
        
        Test.startTest();
        try{
            Test.setMock(
                HttpCalloutMock.class, 
                new GetFinancialBalanceApiFromERPMock(
                    true, '{"out_Regioes": [{"IdReservaFin": "000001","Regioes": [{"Codigo": "02","SaldoFinanceiro": 989661.05,"RegiaoEncontrada": true}]}]}'));
            ReservationManagement.upsertReserveProduct(reserve.Id, JSON.serialize(productDataList));
        } catch(Exception e) {

        }

        Test.stopTest();
    }

    @IsTest 
    static void test_ProductData() {
        Account cliente = TestUtility.createInsertAccount();
        Reserva__c reserve = TestUtility.createAndInsertReservation();
        Product2 product2 = TestUtility.createAndInsertProduct();
        Product2 product2_2 = TestUtility.createAndInsertProduct();
        Reserva__c reserveGetItens = TestUtility.createAndInsertReservation('30912842');
        ListaCentroDistribuicao__c listCentroDistribuicao = TestUtility.createListaCentroDistribuicao();
        Estoque__c inventory = TestUtility.createInsertStock('498324239', product2_2.Id);
        ProdutoReserva__c productResevationGetItens = TestUtility.createAndInsertReservationProduct(reserveGetItens.Id, product2_2.Id);
        productResevationGetItens.QuantidadeAtiva__c = 10;

        ReservationManagement.ProductData productData = new ReservationManagement.ProductData(productResevationGetItens);
        ReservationManagement.ProductData[] productDataList = new ReservationManagement.ProductData[]{productData};
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.csv';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;

        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(cvList.size(), 1);

        //Get Content Documents
        List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(cdList.size(), 1);

        ReservationManagement.createProductsReservationByCSVFile(reserve.Id, cdList[0].Id);

        Boolean hasmoreProducts = ReservationManagement.hasMoreProductsApex('0', reserve.Id);

        String totalProductsReservation = ReservationManagement.getTotalProductsReservation(String.valueOf(reserve.Id));

        String refreshedProducts = ReservationManagement.refreshProductsApex(String.valueOf(reserve.Id), JSON.serialize(productData));

        String deletedProduct = ReservationManagement.deleteProductReservation(reserve.Id, productData.id);

        String deleteReservation = Reservationmanagement.deleteReservationHeader(reserve.Id);
    }
}
