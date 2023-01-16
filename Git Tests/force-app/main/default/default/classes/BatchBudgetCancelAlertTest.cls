@isTest
public with sharing class BatchBudgetCancelAlertTest {
    @TestSetup
    static void makeData(){
        User user = TestUtility.createUser();
        insert user;
        Opportunity opportunity = TestUtility.createOpportunity(user);
        opportunity.CloseDate = Date.today().addDays(2);
        opportunity.StageName = 'Em digitação';
        insert opportunity;
    }
    
    @isTest
    public static void BatchBudgetCancelAlert() {
        BatchBudgetCancelAlertSchedule batchSchedule = new BatchBudgetCancelAlertSchedule();
        batchSchedule.execute(null);
        BatchBudgetCancelAlertSchedule.scheduleBatch();
    }
}
