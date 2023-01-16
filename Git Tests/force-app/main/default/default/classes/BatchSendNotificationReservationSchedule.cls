public class BatchSendNotificationReservationSchedule implements Schedulable{

    public void execute(SchedulableContext sc) {

        Database.executeBatch(new BatchSendNotificationReservation());
    }

    public static void scheduleBatch() {
        BatchSendNotificationReservationSchedule s = new BatchSendNotificationReservationSchedule();
        System.schedule(Test.isRunningTest() ? 'Reserva Job Test' : 'Reserva Job', '0 0 0 * * ?', s);
    }

}
