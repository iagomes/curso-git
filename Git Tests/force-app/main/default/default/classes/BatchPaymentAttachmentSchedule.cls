public class BatchPaymentAttachmentSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPaymentAttachment(), 1);
    }

    public static void scheduleBatch() {
        BatchPaymentAttachmentSchedule batch = new BatchPaymentAttachmentSchedule();
        String jobScheduled = '0 0 * * * ?';

        System.schedule(Test.isRunningTest() ? 'Comprovante de pagamento test' : 'Comprovante de pagamento', jobScheduled, batch);
    }
}
