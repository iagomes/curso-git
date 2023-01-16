@IsTest
public with sharing class CustomLookupControllerTest {
    @TestSetup
    static void makeData(){
        CondicaoPagamento__c conditionMakeData = TestUtility.createConditionPayment();
        insert conditionMakeData;
        CustomLookupController.CondicaoData conditionData = new CustomLookupController.CondicaoData(conditionMakeData);

        Account accountMakeData = TestUtility.createAccPJ();
        insert accountMakeData;
        CustomLookupController.AccData accData         = new CustomLookupController.AccData(accountMakeData);
        CustomLookupController.AccountData accountData = new CustomLookupController.AccountData(accountMakeData);

        Contact contactMakeData = TestUtility.createContact(accountMakeData.Id);
        insert contactMakeData;
        CustomLookupController.ContactData contactData = new CustomLookupController.ContactData(contactMakeData);

        Product2 product = TestUtility.createProduct();
        insert product;
        Pricebook2 pricebook = TestUtility.createPricebook2(product);
        CustomLookupController.Pricebook2Data pricebookData = new CustomLookupController.Pricebook2Data(pricebook);
    }

    @IsTest
    public static void fetchLookupValuesTest() {
        List<Account> accountList = [SELECT Id, Name FROM Account WHERE Name LIKE: 'Teste 1' ORDER BY createdDate DESC limit 5];

        System.assertEquals(accountList, CustomLookUpController.fetchLookUpValues('Teste 1', 'Account'), 'fetchLookupValuesTest');
    }

    @IsTest
    public static void getAccountsTest() {
        List<Account> accountList = [SELECT Id, Name, ExternalId__c, TipoCliente__c, TabelaPrecos__c, CondicaoPagamento__c, CondicaoPagamento__r.Name, Bloqueado__c FROM Account WHERE Deletado__c = false LIMIT 10];

        System.assertEquals(accountList, CustomLookUpController.getAccounts(), 'getAccountsTest');
    }

    @IsTest
    public static void searchObjectTest() {
        List<String> fields = new List<String>{'Name'};

        String searchKeyword = 'Account' + '*';
        String returningQuery = '';
        returningQuery = 'Account' + ' ( Id, ' + String.join(fields, ',') + ')';
        String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING ' + returningQuery + ' LIMIT 20';
        System.debug(' query ' + query);
        List<List<sObject>> searchRecords = Search.Query(Query);
        List<Account> accountList = searchRecords.get(0);

        System.assertEquals(accountList, CustomLookUpController.searchObject('Account', fields, 'Account'), 'searchObjectTest');
    }

    @IsTest
    public static void searchTest() {
        List<Account> accountList = [SELECT Id, Name FROM Account WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5];

        //System.assertEquals(accountList, CustomLookUpController.search('Teste 1', 'Account', ''), 'searchTest');
        //System.assertEquals(accountList, CustomLookUpController.search('Teste 1', 'Account', ''), 'searchTest');
        System.assertEquals(accountList, CustomLookUpController.search('', 'Account', ''), 'searchTest');
    }

    @IsTest
    public static void getAvailableDataTest() {
        Account account = TestUtility.createAccount();
        insert account;
        CondicaoPagamento__c conditionP = TestUtility.createConditionPayment();
        insert conditionP;
        Contact contact = TestUtility.createContact(account);
        insert contact;

        System.assertEquals('[]', CustomLookUpController.getAvailableData(String.valueOf(account.Id), String.valueOf(conditionP.Id), 'Account', 'Pricebook2'), 'getAvailableDataTest 1');
        System.assertEquals('[]', CustomLookUpController.getAvailableData(String.valueOf(account.Id), String.valueOf(conditionP.Id), 'Account', 'CondicaoPagamento__c'), 'getAvailableDataTest 2');
        System.assertEquals('[]', CustomLookUpController.getAvailableData(String.valueOf(account.Id), String.valueOf(conditionP.Id), 'Account', 'Contact'), 'getAvailableDataTest 3');
        System.assertEquals('[]', CustomLookUpController.getAvailableData(String.valueOf(account.Id), String.valueOf(conditionP.Id), 'Account', ''), 'getAvailableDataTest 4');
    }

    @IsTest
    public static void getRecordsTest() {
        System.assertNotEquals(null, CustomLookUpController.getRecords('SELECT Id, Name FROM Account', 'Account'), 'getRecordsTest 1');
        System.assertNotEquals(null, CustomLookUpController.getRecords('SELECT Id, Name FROM CondicaoPagamento__c', 'CondicaoPagamento__c'), 'getRecordsTest 2');
        System.assertNotEquals(null, CustomLookUpController.getRecords('SELECT Id, Name FROM Pricebook2', 'Pricebook2'), 'getRecordsTest 3');
        System.assertEquals(null, CustomLookUpController.getRecords('', 'Contact'), 'getRecordsTest');
    }

    @IsTest
    public static void getContaOrdemTest() {
        Account account = TestUtility.createAccount();
        insert account;
        
        System.assertNotEquals(null, CustomLookUpController.getContaOrdem(account.Id, null), 'getContaOrdemTest');
    }

    @IsTest
    public static void getRecordTypeIdsTest() {
        Account account = TestUtility.createAccount();
        insert account;

        List<Account> accountList = [SELECT Id, Name FROM Account WHERE Name = 'Teste 1'];

        System.assertEquals(null, CustomLookUpController.getRecordTypeIds('', '', ''), 'getRecordTypeIdsTest');
        //System.assertEquals(accountList, CustomLookUpController.getRecordTypeIds('Account', 'Name', 'Name = 'Teste 1''), 'getRecordTypeIdsTest');
    }
}