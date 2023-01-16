@IsTest
public with sharing class UtilitiesControllerTest {

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
    public static void testgetPickListValuesList() {
        
        UtilitiesController.getPickListValuesList('Account.Rating');
    }

    @IsTest
    public static void testgetLookupRecords() {

        String[] fieldNames = new String[]{'Name', 'BillingCity'};
        String[] lookupSelectFields = new String[]{'GrupoCliente__c', 'BillingCity'};
        
        UtilitiesController.getLookupRecords('Account-', 'Account', fieldNames, lookupSelectFields,'');
        UtilitiesController.getLookupRecords('Account-', 'Account', fieldNames, lookupSelectFields,'BillingCity');
    }

    @IsTest
    public static void testgetRecordTypeByName() {

        StandardResponse response = new StandardResponse();
        
        response = UtilitiesController.getRecordTypeByName('Pessoa física', 'Account');

        response = UtilitiesController.getRecordTypeByName('', 'Account');
        System.assertEquals(response.hasError, true);

        response = UtilitiesController.getRecordTypeByName('Name', 'Account4');
        System.assertEquals(response.hasError, true);
        
        
    }

    
}
