public class BatchPendingOrderSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPendingOrder());
    }

    public static void scheduleBatch() {
        BatchPendingOrderSchedule batch = new BatchPendingOrderSchedule();
        String jobScheduled = '0 0 8 1/3 * ?';

        System.schedule(Test.isRunningTest() ? 'Pedido pendente test' : 'Pedido pendente', jobScheduled, batch);
    }

}