@IsTest
public with sharing class CalcBusinessDaysTest {
    @IsTest
    public static void flowCalcDaysTest() {
        User newUser = TestUtility.createUser();
        insert newUser;
        Opportunity newOpportunity = TestUtility.createOpportunity(newUser);
        insert newOpportunity;

        List<String> stringList = new List<String>();
        stringList.add(String.valueOf(newOpportunity));

        List<String> successList = new List<String>{'Sucesso!!'};
        System.assertEquals(successList, CalcBusinessDays.flowCalcDays(stringList), 'flowCalcDaysTest');
    }

    @IsTest
    public static void IsWeekendTest() {
        Date newDate      = Date.today();
        String dateString = Datetime.newInstance(newDate.year(), newDate.month(), newDate.day()).format('EEE');

        System.assertEquals((dateString.equals('Sat') || dateString.equals('Sun')), CalcBusinessDays.IsWeekend(newDate), 'IsWeekendTest');
    }

    @IsTest
    public static void calcDaysTest() {
        Date newDate  = Date.today();

        System.assertNotEquals(null, CalcBusinessDays.calcDays(newDate, 10), 'calcDaysTest');
    }
}