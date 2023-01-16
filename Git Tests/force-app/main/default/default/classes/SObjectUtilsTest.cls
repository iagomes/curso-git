@IsTest
public with sharing class SObjectUtilsTest {

    
    @TestSetup
    public static void init() {
        // createAccount(1);
        
        // result.Name = 'Account-' + i;
        // result.NumberOfEmployees = 0;
        Account acc = TestUtility.createAccPJ();
        acc.Name = 'Account-1';
        acc.NumberOfEmployees = 0;
        acc.DescontoCliente__c = 2;
        acc.CNPJ__c = '47782743000124';
        acc.ExternalId__c = '47782743000124';
        insert acc;

        Account acc3 = TestUtility.createAccPJ();
        acc3.Name = 'Account-2';
        acc3.NumberOfEmployees = 0;
        acc3.ParentId = acc.Id;
        acc3.DescontoCliente__c = 2;
        acc.CNPJ__c = '34349677000151';
        acc.ExternalId__c = '34349677000151';
        insert acc3;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;
        
        Contact contact3 = TestUtility.createContact(acc3.Id);
        contact3.Email = 'teste'+Integer.valueof((Math.random() * 100)) +'@test.com';
        insert contact3;
    }
    @IsTest
    public static void testAllMethods() {


        SObjectUtils obj = new SObjectUtils();
        SObject acc =[SELECT Id, Name FROM Account where name ='Account-1'];
        List<SObject> lstRecords = new List<SObject>{acc};
        Map<Id, SObject> mapObject = new Map<Id, SObject>{acc.id => acc};
        Map<String,String> mapFields = new Map<String,String>{'Id' => acc.id};
        Set<String> fieldNames = new Set<String>{'Name'};
        SObjectUtils.hasChangedFields(acc, mapObject, 'Name');
        SObjectUtils.copyFieldValues(acc, acc, 'Name');
        SObjectUtils.copyFieldValues(acc, acc, 'Name', true);
        SObjectUtils.copyFieldValues(acc, acc, fieldNames);
        SObjectUtils.copyFieldValues(acc, acc, fieldNames, true);
        SObjectUtils.copyFieldValues(acc, acc, fieldNames, true, true);
        SObjectUtils.mapObjectsByField(lstRecords, 'Name');
        SObjectUtils.mapObjectsByField(lstRecords, 'Name', true);
        SObjectUtils.mapObjectsByField(lstRecords, fieldNames);
        SObjectUtils.getLookupIds(lstRecords, 'id', true);
        SObjectUtils.getObjectNameById(acc.id);
        SObjectUtils.hasSObjectField('Name', acc);
        SObjectUtils.getPickListValuesList('Account', 'Rating');
        SObjectUtils.getPickListValuesMap('Account', 'Rating');
        SObjectUtils.getFieldType('Account', 'Name');
        SObjectUtils.copyFieldValues(new Account(), acc, new Map<String,String>{'Name' => 'Name'}, false, true);
        SObjectUtils.validateSObjectType(acc, 'Account');
        SObjectUtils.getDependentPicklistValues('Opportunity','TabulacaoN2__c');
        List<Account> accountListTest = new List<Account>{new Account(Name= 'name')};
        SObjectUtils.filterLists(accountListTest, accountListTest[0]);
        SObjectUtils.filterAttrEq(accountListTest, new List<String>{'Name'}, new List<String>{'name'});
        SObjectUtils.filterAttrEq(accountListTest, 'Name', 'notName');
        SObjectUtils.filterAttrNeq(accountListTest, new List<String>{'Name'}, new List<String>{'name'});
        SObjectUtils.filterAttrNeq(accountListTest, 'Name', 'notName');
    }
}
