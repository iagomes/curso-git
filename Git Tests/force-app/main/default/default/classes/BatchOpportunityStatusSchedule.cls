public class BatchOpportunityStatusSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchOpportunityStatus());
    }

    public static void scheduleBatch() {
        BatchOpportunityStatusSchedule batch = new BatchOpportunityStatusSchedule();
        String jobScheduled = '0 0 10,12,15,17 ? * *';

        System.schedule(Test.isRunningTest() ? 'OpportunityStatus test' : 'OpportunityStatus', jobScheduled, batch);
    }
}
