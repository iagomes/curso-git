@IsTest
public with sharing class BaseLookupControllerTest {

    @TestSetup
    static void makeData(){
		// Cria Conta com os Campos Obrigatórios
        Account newAccount = new Account();
		newAccount.Name = 'Teste';
		insert newAccount;
    }

    @IsTest
    public static void testGetRecordsSingleSearchField() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        String str = '{\n' +
                     '    "searchFields":[\n' +
                     '       "Name"\n' +
                     '    ],\n' +
                     '	  "moreFields":[\n' +
                     '       "AccountNumber"\n' +
                     '    ],\n' +
                     '    "targetObject":"Account",\n' +
                     '    "relations":[ \n' +
                     '       { \n' +
                     '          "operator":"=",\n' +
                     '          "parentRelationField":"Name",\n' +
                     '          "parentRecord":"' + account.Name + '"\n' +
                     '       }\n' +
                     '    ],\n' +
                     '    "searchValue":\n' +
                     '       "' + account.Name +'"\n' +
                     '}';

        Test.startTest();
            BaseLookupController.getRecords(str);
        Test.stopTest();

        System.assertNotEquals(null, BaseLookupController.getRecords(str), 'getRecordsTest');
    }

    @IsTest
    public static void testGetRecordsMultiSearchField() {
        Account account = [SELECT Id, Name, AccountNumber FROM Account LIMIT 1];

        String str = '{\n' +
                     '    "searchFields":[\n' +
                     '       "Name",\n' +
					 '       "AccountNumber"\n' +
                     '    ],\n' +
                     '	  "moreFields":[\n' +
                     '       "AccountSource"\n' +
                     '    ],\n' +
                     '    "targetObject":"Account",\n' +
                     '    "relations":[ \n' +
                     '       { \n' +
                     '          "operator":"=",\n' +
                     '          "parentRelationField":"Name",\n' +
                     '          "parentRecord":"' + account.Name + '"\n' +
                     '       }\n' +
                     '    ],\n' +
                     '    "searchValue":\n' +
                     '       "' + account.Name +'"\n' +
                     '}';

        Test.startTest();
        	BaseLookupController.getRecords(str);
        Test.stopTest();

        System.assertNotEquals(null, BaseLookupController.getRecords(str), 'getRecordsTest');
    }

	@IsTest
    public static void testGetRecordsMultiSearchFieldWhereIN() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        String str = '{\n' +
                     '    "searchFields":[\n' +
                     '       "Name"\n' +
                     '    ],\n' +
                     '	  "moreFields":[\n' +
                     '       "AccountNumber"\n' +
                     '    ],\n' +
                     '    "targetObject":"Account",\n' +
                     '    "relations":[ \n' +
                     '       { \n' +
                     '          "operator":"IN",\n' +
                     '          "parentRelationField":"Name",\n' +
                     '          "parentRecordList":["' + account.Name + '","Teste2"]\n' +
                     '       }\n' +
                     '    ],\n' +
                     '    "searchValue":\n' +
                     '       "' + account.Name +'"\n' +
                     '}';

		String str1 = '{\n' +
                     '    "searchFields":[\n' +
                     '       "Name"\n' +
                     '    ],\n' +
                     '	  "moreFields":[\n' +
                     '       "AccountNumber"\n' +
                     '    ],\n' +
                     '    "targetObject":"Account",\n' +
                     '    "relations":[ \n' +
                     '       { \n' +
                     '          "operator":"IN",\n' +
                     '          "parentRelationField":"Name",\n' +
                     '          "parentRecordList":[""]\n' +
                     '       }\n' +
                     '    ],\n' +
                     '    "searchValue":\n' +
                     '       "' + account.Name +'"\n' +
                     '}';

        Test.startTest();
        	BaseLookupController.getRecords(str);
			System.assertNotEquals(null, BaseLookupController.getRecords(str), 'getRecordsTest');

        	BaseLookupController.getRecords(str1);
			System.assertNotEquals(null, BaseLookupController.getRecords(str1), 'getRecordsTest');
        Test.stopTest();

    }

	@IsTest
    public static void testGetRecordsMultiSearchFieldWhereLIKE() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        String str = '{\n' +
                     '    "searchFields":[\n' +
                     '       "Name"\n' +
                     '    ],\n' +
                     '	  "moreFields":[\n' +
                     '       "AccountNumber"\n' +
                     '    ],\n' +
                     '    "targetObject":"Account",\n' +
                     '    "relations":[ \n' +
                     '       { \n' +
                     '          "operator":"LIKE",\n' +
                     '          "parentRelationField":"Name",\n' +
                     '          "parentRecord":"%' + account.Name + '%"\n' +
                     '       }\n' +
                     '    ],\n' +
                     '    "searchValue":\n' +
                     '       "' + account.Name +'"\n' +
                     '}';

        Test.startTest();
        	BaseLookupController.getRecords(str);
        	System.assertNotEquals(null, BaseLookupController.getRecords(str), 'getRecordsTest');
        Test.stopTest();
    }
}
