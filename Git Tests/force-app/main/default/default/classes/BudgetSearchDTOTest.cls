
@IsTest
public with sharing class BudgetSearchDTOTest {

    @IsTest
    public static void test_parse_1() {
        Test.startTest();
        BudgetSearchDTO paramsDTO = BudgetSearchDTO.parse('{"notAnswered": true, "expired": true, "searchStatus":null,"statusSearch":[],"canalEntradaSelected":[],"vendedorSelected":[],"teamMember":[],"quoteIntegratorId":null,"quoteType":null,"cnpjCliente":null,"mesaSelected":null,"nomeCliente":null,"ufCliente":null,"cidadeCliente":null,"vencimentoCotacao":{},"orderBy":null,"orderDirection":null,"lastRecord":null,"itemsPerPage":null,"queryLimit":null}');
        paramsDTO.toList();
        paramsDTO.toCount();
        paramsDTO.toMap();
        
        Test.stopTest();
    }

    @IsTest
    public static void test_parse_2() {
        Test.startTest();
        BudgetSearchDTO paramsDTO = BudgetSearchDTO.parse('{"notAnswered": true, "expired": true, "searchText":"0123456789","normText":"Dipirona","searchStatus":"Novo;Em digitação","statusSearch":["Novo","Em digitação","Encerrado"],"canalEntradaSelected":["Bionexo"],"vendedorSelected":[],"teamMember":[],"quoteIntegratorId":null,"quoteType":null,"cnpjCliente":null,"mesaSelected":null,"nomeCliente":null,"ufCliente":null,"cidadeCliente":null,"vencimentoCotacao":{},"orderBy":"CanalEntrada__c","orderDirection":"DESC","lastRecord":null,"itemsPerPage":200,"queryLimit":200}');
        paramsDTO.toList();
        paramsDTO.toCount();
        paramsDTO.toMap();
        
        Test.stopTest();
    }

    @IsTest
    public static void test_DateRange_1() {
        
        BudgetSearchDTO.DateRange testDateRange1 = new BudgetSearchDTO.DateRange(false);
        testDateRange1.date1 = '2022-06-02T01:27:00.000Z';
        testDateRange1.date2 = '2022-06-02T02:27:00.000Z';
        testDateRange1.toQueryBuilderCondition('CreatedDate');
        
    }

    @IsTest
    public static void test_DateRange_2() {

        BudgetSearchDTO.DateRange testDateRange1 = new BudgetSearchDTO.DateRange(true);
        testDateRange1.toQueryBuilderCondition('CreatedDate');
        
    }

    @IsTest
    public static void test_DateRange_3() {

        BudgetSearchDTO.DateRange testDateRange1 = new BudgetSearchDTO.DateRange(false);
        testDateRange1.last_n_days = 0;
        testDateRange1.toQueryBuilderCondition('CreatedDate');
        
    }

    @IsTest
    public static void test_DateRange_4() {

        BudgetSearchDTO.DateRange testDateRange1 = new BudgetSearchDTO.DateRange(false);
        testDateRange1.last_n_days = 1;
        testDateRange1.toQueryBuilderCondition('CreatedDate');
        
    }
}

