@isTest
public class BusinessDaysTest {

    @isTest
    public static void addDays() {
        
        Datetime dt = Datetime.newInstance(2022, 03, 17);
        Datetime dt2 = BusinessDays.getInstance().addDays(dt, 2);
        
        System.assertEquals(dt.addDays(4), dt2);
    }
    
    @isTest
    public static void subtractDays() {
        
        Datetime dt = Datetime.newInstance(2022, 03, 14);
        Datetime dt2 = BusinessDays.getInstance().subtractDays(dt, 1);
        
        System.assertEquals(dt.addDays(-3), dt2);
    }    
    
    @isTest
    public static void getNextWorkingDay() {
        
        Datetime dt = Datetime.newInstance(2022, 03, 14);
        Datetime dt2 = BusinessDays.getInstance().getNextWorkingDay(dt);
        
        System.assertEquals(dt, dt2);
    }     
    
    @isTest
    public static void getNoOfBusinessDaysBetweenDates() {
        
        Datetime dt = Datetime.newInstance(2022, 03, 18);
        Datetime dt2 = Datetime.newInstance(2022, 03, 21);
        Integer counter = BusinessDays.getInstance().getNoOfBusinessDaysBetweenDates(dt, dt2);
        
        System.assertEquals(2, counter);
    }  

    @isTest
    public static void getElapsedTimeBetweenDates() {
        
        Datetime dt = Datetime.newInstance(2022, 08, 19);
        Datetime dt2 = Datetime.newInstance(2022, 08, 22);
        Map<String, Long> result = BusinessDays.calculateTimeBetweenDates(dt, dt2);
        System.assertEquals(0, result.get('days'));
    }      
    
}