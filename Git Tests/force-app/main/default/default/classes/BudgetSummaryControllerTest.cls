@isTest
public with sharing class BudgetSummaryControllerTest {
    
    @isTest
    public static void testBudgetController() {
        Account account = TestUtility.createAccPJ();
        insert account;

        User user = TestUtility.createUser();
        insert user;

        Opportunity opportunity;

        System.runAs(user) {
            opportunity = new Opportunity(
                Name = 'Opportunity Test',
                StageName = 'Novo',
                CloseDate = Date.today().addDays(10),
                AccountId = account.Id
            );
            insert opportunity;
        }


        opportunity.StageName = 'Em digitação';

        update opportunity;

        BudgetSummaryController.getBudgetList(user.Id, account.Id, 'open', true);

        Test.startTest();

        BudgetSummaryController.getBudgetList(user.Id, account.Id, 'closed', false);

        Test.stopTest();

    }
}
