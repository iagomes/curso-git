public class BatchReservationIncAltScheduled implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchReservationIncAlt());
    }

    public static void scheduleBatch() {
        BatchReservationIncAltScheduled batch = new BatchReservationIncAltScheduled();
        String jobScheduled = '0 0 8 * * ?';

        System.schedule(Test.isRunningTest() ? 'Envio de reservas para o Protheus' : 'Envio de reservas para o Protheus', jobScheduled, batch);
    }
}