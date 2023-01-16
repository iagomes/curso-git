@IsTest
public with sharing class CreateReservationFormControllerTest {

    @IsTest
    static void itShouldGetRecordTypeOptions() {
        Test.startTest();
        CreateReservationFormController.getRecordTypeOptions();
        Test.stopTest();
    }

    @IsTest
    static void itShouldGetDistributionCenters() {
        ListaCentroDistribuicao__c distributionCenter = new ListaCentroDistribuicao__c();
        distributionCenter.Name = 'Teste';
        distributionCenter.NomeCD__c = 'Teste';
        distributionCenter.CodigoCD__c = '001';
        insert distributionCenter;
        
        Test.startTest();
        List<CreateReservationFormController.DefaultOptions> response = CreateReservationFormController.getDeliveryCenters();
        Test.stopTest();

        System.assertEquals(1, response.size(), 'Esperado retorno de 1 centro de distribuição');
    }
}
