public class BatchContentDocumentSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchContentDocument(), 200);
    }

    public static void scheduleBatch() {
        BatchContentDocumentSchedule s = new BatchContentDocumentSchedule();
        System.schedule(Test.isRunningTest() ? 'Content Doc Job Test' : 'Content Document Job', '0 0 0 * * ?', s);
    }

}
