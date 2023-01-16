@isTest
public with sharing class ContactHelperTest {
    @isTest
    public static void createStandarContactTest() {
        Account account       = TestUtility.createAccount();
        insert account;

        Contact contact       = TestUtility.createContact(account.Id);
        Contact contactUpdate = TestUtility.createContact(account);
        insert contact;
        insert contactUpdate;

        contact.Padrao__c = true;
        update contact;

        //delete contact;
    }

    @isTest
    public static void ContactHelperTest() {
        system.debug(ContactHandler.disableTrigger());
        system.debug(ContactHandler.enableTrigger());
        System.assertEquals(false, ContactHandler.disableTrigger());
        System.assertEquals(true, ContactHandler.enableTrigger());
    }
}