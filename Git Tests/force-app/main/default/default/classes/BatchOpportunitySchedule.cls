public class BatchOpportunitySchedule implements Schedulable {

    public void execute(SchedulableContext sc) {

        Database.executeBatch(new BatchOpportunity());
    }

    public static void scheduleBatch() {
        BatchOpportunitySchedule s = new BatchOpportunitySchedule();
        System.schedule(Test.isRunningTest() ? 'Orçamento Job Test' : 'Orçamento Job', '0 0 0 * * ?', s);
    }

}
