public class BatchReprocessOrderSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchReprocessOrder(), 1);
    }

    public static void scheduleBatch() {
        BatchReprocessOrderSchedule sch = new BatchReprocessOrderSchedule();
        System.schedule(Test.isRunningTest() ? 'Reprocess Order Job Test 1' : 'Reprocess Order Job 1', '0 0 */3 * * ?', sch);
    }
}