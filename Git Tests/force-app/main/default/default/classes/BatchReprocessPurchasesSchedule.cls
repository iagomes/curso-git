public with sharing class BatchReprocessPurchasesSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchReprocessPurchases(), 1);
    }

    public static void scheduleBatch() {
        BatchReprocessPurchasesSchedule batch = new BatchReprocessPurchasesSchedule();
        String jobScheduled = '0 0 * * * ?';

        System.schedule(Test.isRunningTest() ? 'Solicitação de compras test' : 'Solicitação de compras', jobScheduled, batch);
    }
}
