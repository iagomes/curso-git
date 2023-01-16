public class BatchBudgetCancelAlertSchedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchBudgetCancelAlert());
    }

    public static void scheduleBatch() {
        BatchBudgetCancelAlertSchedule batch = new BatchBudgetCancelAlertSchedule();
        String jobScheduled = '0 0 8 * * ?';

        System.schedule(Test.isRunningTest() ? 'Notificação de vencimento de orçamento test 1' : 'Notificação de vencimento de orçamento', jobScheduled, batch);
    }
}
