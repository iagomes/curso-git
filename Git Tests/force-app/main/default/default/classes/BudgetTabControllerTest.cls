@isTest
public class BudgetTabControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;
        Contact contact = TestUtility.createContact(acc);
        insert contact;
        CondicaoPagamento__c conditionPayment = TestUtility.createConditionPayment(); 
        insert conditionPayment;
        Opportunity opp = TestUtility.createOpportunity(acc, contact, conditionPayment);
        opp.DataVencimento__c = System.now().addDays(1);
        insert opp;
        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.CategoriaCliente__c = 'teste';
        insert qItem;
    }

    @isTest
    static void doSearchTest1(){
        String json1doSearch  =  
        '{'+
            '"searchStatus"     :null,'+
            '"statusSearch"     :["Encerrado"],'+
            '"vendedorSelected" :[],'+
            '"teamMember"       :["userId"],'+
            '"quoteIntegratorId":"0000123",'+
            '"quoteType"        :"Portal",'+
            '"cnpjCliente"      :"26495652000138",'+
            '"mesaSelected"     :null,'+
            '"nomeCliente"      :"Artevaldo",'+
            '"ufCliente"        :["RJ"],'+
            '"cidadeCliente"    :["Rio de Janeiro"],'+
            '"vencimentoCotacao":'+
            '{'+
                '"date1"        :"2022-03-01T12:59:00.000Z",'+
                '"date2"        :"2022-03-02T12:59:00.000Z"'+
            '},'+
            '"searchText"       :"01/06/1999",'+
            '"orderBy"          :"CreatedDate",'+
            '"orderDirection"   :"desc",'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200,'+
            '"produto"          :"0000364",'+
            '"expired"          :true,'+
            '"notAnswered"      :true'+
        '}';


        BudgetTabController.doSearch(json1doSearch);

    }
    
    @isTest
    static void doSearchTestError(){
        try{
            BudgetTabController.doSearch('Error');

        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
    

    @isTest
    static void doSearchTest2(){
        String json2doSearch  =  
            '{'+
            '"searchText"        :"lul",'+
            '"vencimentoCotacao":{},'+
            '"orderBy"          :"CreatedDate",'+
            '"orderDirection"   :"desc",'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200,'+
            '"notAnswered"      :true,'+
            '"last_n_days"       :1'+
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest
    static void doSearchTest3(){
        String json2doSearch  =  
            '{'+
            '"searchText"        :"01/06/1999",'+
            '"vencimentoCotacao" :{},'+
            '"lastRecord"        :null,'+
            '"itemsPerPage"      :200,'+
            '"mesaSelected"      :["sul"],'+
            '"last_n_days"       :0'+
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest
    static void doSearchTest4(){
        String json2doSearch  =  
            '{'+
            '"searchText"        :"01/06/1999 09",'+
            '"vencimentoCotacao":{},'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200,'+
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest
    static void doSearchTest5(){
        String json2doSearch  =  
            '{'+
            '"searchText"        :"01/06/1999 09:15",'+
            '"vencimentoCotacao":{},'+
            '"orderBy"          :"CreatedDate",'+
            '"orderDirection"   :"desc",'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200'+
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest
    static void doSearchTest6(){
        String json2doSearch  =  
            '{'+
            '"searchText"        :"126,12",'+
            '"vencimentoCotacao":{},'+
            '"orderBy"          :"CreatedDate",'+
            '"orderDirection"   :"desc",'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200,'+
            '"yesterday"       :true'+
            
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest
    static void doSearchTest7(){
        String json2doSearch  =  
            '{'+
            '"produto"        :"0000364",'+
            '"vencimentoCotacao":{},'+
            '"orderBy"          :"CreatedDate",'+
            '"orderDirection"   :"desc",'+
            '"lastRecord"       :null,'+
            '"itemsPerPage"     :200'+
        '}';

        BudgetTabController.doSearch(json2doSearch);

    }

    @isTest 
    static void getUsersSetorTest1(){

        BudgetTabController.getUsersPicklist();

    }

    @isTest 
    static void test_fixedFilters_success(){
        String json2doSave  = '{"searchStatus":null,"vendedorSelected":[],"teamMember":[],"quoteIntegratorId":null,"quoteType":"Portal","cnpjCliente":null,"mesaSelected":null,"nomeCliente":null,"ufCliente":null,"cidadeCliente":null,"vencimentoCotacao":{},"orderBy":"CreatedDate","orderDirection":"desc","lastRecord":null,"itemsPerPage":200}';
        BudgetTabController.saveFixFilter('filterName', json2doSave);
        BudgetTabController.getFixedFilters();
        UserCustomization__c userCustom = [SELECT Id FROM UserCustomization__c LIMIT 1];
        BudgetTabController.deleteFixedFilters(new List<String>{userCustom.Id});
    }
    
    @isTest
    static void test_deleteFixFilters_error(){
        BudgetTabController.deleteFixedFilters(new List<String>{'asd'});
    }

    @isTest
    static void test_fixedFilters_errorJson(){
        BudgetTabController.saveFixFilter('filterName', '{"asd":asd"asd}');
        BudgetTabController.getFixedFilters();
    }

    @isTest 
    static void test_fixedFilters_error_empty(){
        BudgetTabController.saveFixFilter(null, 'filterParams');

    }

    @isTest 
    static void test_fixedFilters_error_toolong(){

        BudgetTabController.saveFixFilter('afhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafeaafhaefeafeafaefaefeffaefaefeafea', 'filterParams');

    }

    @isTest 
    static void test_getVendedor(){

        BudgetTabController.getVendedor(new List<String>{'filterName'});

    }
    
    @isTest 
    static void test_getCategoria(){
        BudgetTabController.getCategoria();
    }

    @isTest 
    static void test_getMesa(){

        BudgetTabController.getMesa();

    }

    @isTest 
    static void test_getUserOrders(){

        BudgetTabController.getUserOrders();
    }
}
