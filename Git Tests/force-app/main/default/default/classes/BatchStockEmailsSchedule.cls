public class BatchStockEmailsSchedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchStockEmails(), 1);
    }

    public static void scheduleBatch() {
        BatchStockEmailsSchedule batch = new BatchStockEmailsSchedule();
        String jobScheduled1 = '0 0 9 * * ?';
        String jobScheduled2 = '0 0 14 * * ?';

        System.schedule(Test.isRunningTest() ? 'Email dos pedido pendente test 1' : 'Email dos pedido pendente 1', jobScheduled1, batch);
        System.schedule(Test.isRunningTest() ? 'Email dos pedido pendente test 2' : 'Email dos pedido pendente 2', jobScheduled2, batch);
    }
}
