public class BatchCancelOldOrderSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCancelOldOrder(), 1);
    }

    public static void scheduleBatch() {
        BatchCancelOldOrderSchedule sch = new BatchCancelOldOrderSchedule();
        System.schedule(Test.isRunningTest() ? 'Cancel Order Job Test 1' : 'Cancel Order Job 1', '0 0 8 * * ?', sch);
    }

}
