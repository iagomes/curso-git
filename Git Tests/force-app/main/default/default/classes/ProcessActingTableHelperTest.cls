@isTest
public with sharing class ProcessActingTableHelperTest {

    @isTest
    public static void ProcessActingTableHelperTest() {
        ProcessActingTable__e pCreateTerritory = new ProcessActingTable__e(
            Type__c = 'create_territory',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pCreateTerritory);
        Test.stopTest();
    }
    @isTest
    public static void ProcessAssociateAccTest() {
        ProcessActingTable__e pAssociateAcc = new ProcessActingTable__e(
            Type__c = 'associate_accounts',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pAssociateAcc);
        Test.stopTest();
    }
    @isTest
    public static void ProcessDelAssociateUsersTest() {
        ProcessActingTable__e pDelAssociateUsers = new ProcessActingTable__e(
            Type__c = 'delete_associate_users',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pDelAssociateUsers);
        Test.stopTest();
    }
    @isTest
    public static void ProcessAssociateUsersTest() {
        ProcessActingTable__e pAssociateUsers = new ProcessActingTable__e(
            Type__c = 'associate_users',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pAssociateUsers);
        Test.stopTest();
    }
    @isTest
    public static void ProcessAssociateUsersWithoutATTest() {
        ProcessActingTable__e pAssociateUsersWithoutAT = new ProcessActingTable__e(
            Type__c = 'associate_users_without_acting_table',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pAssociateUsersWithoutAT);
        Test.stopTest();
    }
    @isTest
    public static void ProcessAssociateUsersWithoutSTTest() {
        ProcessActingTable__e pAssociateUsersWithoutST = new ProcessActingTable__e(
            Type__c = 'associate_account_without_setorizacao',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pAssociateUsersWithoutST);
        Test.stopTest();
    }
    @isTest
    public static void ProcessRevalidateApprovalAssTest() {
        ProcessActingTable__e pRevalidateApprovalAss = new ProcessActingTable__e(
            Type__c = 'revalidate_approval_associations',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pRevalidateApprovalAss);
        Test.stopTest();
    }
    @isTest
    public static void ProcessNoTypeTest() {
        ProcessActingTable__e pNoType = new ProcessActingTable__e(
            Type__c = '',
            ExecuteNextProcesses__c = false
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(pNoType);
        Test.stopTest();
    }
}
