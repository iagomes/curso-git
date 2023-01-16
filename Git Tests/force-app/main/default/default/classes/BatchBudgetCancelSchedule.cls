public class BatchBudgetCancelSchedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchBudgetCancel());
    }

    public static void scheduleBatch() {
        BatchBudgetCancelSchedule batch = new BatchBudgetCancelSchedule();
        String jobScheduled = '0 0 7 * * ?';

        System.schedule(Test.isRunningTest() ? 'Cancelamento de orçamento vencido test 1' : 'Cancelamento de orçamento vencido', jobScheduled, batch);
    }
}
