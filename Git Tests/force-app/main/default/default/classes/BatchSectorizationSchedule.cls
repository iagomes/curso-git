
public class BatchSectorizationSchedule implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchSectorization(), 200);
    }

    public static void scheduleBatch() {
        BatchSectorizationSchedule s = new BatchSectorizationSchedule();
        System.schedule(Test.isRunningTest() ? 'Setorização Job Test' : 'Setorização Job', '0 0 0 * * ?', s);
    }

}
