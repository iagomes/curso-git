public class BatchExpiredContractItemSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchExpiredContractItem());
    }

    public static void scheduleBatch() {
        BatchExpiredContractItemSchedule s = new BatchExpiredContractItemSchedule();
        System.schedule(Test.isRunningTest() ? 'Contrato Item Job Test' : 'Contrato Item Job', '0 0 0 * * ?', s);
    }
}
