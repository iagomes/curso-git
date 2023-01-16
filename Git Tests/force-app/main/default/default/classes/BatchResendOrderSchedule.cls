public class BatchResendOrderSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchResendOrder(), 1);
    }

    public static void scheduleBatch() {
        BatchResendOrderSchedule sch = new BatchResendOrderSchedule();
        System.schedule(Test.isRunningTest() ? 'Order Job Test 1' : 'Order Job 1', '0 0 * * * ?', sch);
        System.schedule(Test.isRunningTest() ? 'Order Job Test 2' : 'Order Job 2', '0 30 * * * ?', sch);
    }

}
