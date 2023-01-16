@IsTest
public with sharing class IntegrationUtilsTest {
    @IsTest
    public static void convertEmptyStringTest() {
        String str = '';
        System.assertEquals(true, IntegrationUtils.convertEmptyString(str), 'convertEmptyStringTest');
    }

    @IsTest
    public static void createAttachmentTest() {
        Account account = TestUtility.createAccPJ();
        insert account;

        String recordId = String.valueOf(account.Id);
        String integrationName = 'Test';
        String inOrOut = 'IN';
        String logName = '';
        String timeAsString = '00';
        String payload = 'payload Test';

        System.assertNotEquals(null, IntegrationUtils.createAttachment(recordId, integrationName, inOrOut, logName, timeAsString, payload), 'createAttachmentTest');
    }

    @IsTest
    public static void getTotvsAccessTokenTest() {
        Integracoes__c integration = TestUtility.createTotvsAccessToken();
        insert integration;

        System.assertNotEquals(null, IntegrationUtils.getTotvsAccessToken(), 'getTotvsAccessTokenTest');
    }
}
