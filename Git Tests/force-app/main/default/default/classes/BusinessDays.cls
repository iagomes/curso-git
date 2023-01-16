/**
 * BusinessDays Class
 * Use this class to operate only on business days 
 * and easily skip weekends and holidays from your logic
 * @author - Manish Choudhari
 * */
public class BusinessDays
{
    public BusinessHours bHours;
    /**
     * Constructor to set business hours name
     * */
    private BusinessDays(String name) {
        //get business hours
        bHours = [SELECT Id FROM BusinessHours WHERE Name =: name];
    }

    private static final BusinessDays instance = new BusinessDays(Test.isRunningTest() ? 'workingDays' : 'Atendimento ao Cliente');    

    public static BusinessDays getInstance() {
        return instance;
    }    
   

    /**
     * Add number of working days in a date
     * @param - startDate - date to operate on
     * @param - days - number of days to add
     * @author - Manish Choudhari
     * */
    public Datetime addDays(Datetime startDate, Integer days)
    {
        //If startdate is not within working days, take next working day
        startDate = BusinessHours.nextStartDate(bHours.Id, startDate);
		
        for (Integer elapsed = 0; elapsed < days; elapsed++)
        {
            //Add 1 day
            startDate = startDate.addDays(1);
            
            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHours.Id, startDate))
            { 
                //If new date is not within working days, get new working day
                startDate = BusinessHours.nextStartDate(bHours.Id, startDate);
            }
        }
        return startDate;
    }
    
    /**
     * Subtract number of working days in a date
     * @param - startDate - date to operate on
     * @param - days - number of days to subtract
     * @author - Manish Choudhari
     * */
    public Datetime subtractDays(Datetime startDate, Integer days)
    {
        //If startdate is not within working days, take previous working day
        startDate = getPreviousWorkingDay(startDate);
        for (Integer elapsed = 0; elapsed < days; elapsed++)
        {
            //Subtract 1 day
            startDate = startDate.addDays(-1);
            //Check if new date is within working days
            if (!BusinessHours.isWithin(bHours.Id, startDate))
            { 
                //If new date is not within working days, get previous working day
            	startDate = getPreviousWorkingDay(startDate);
            }
        }
        return startDate;
    }
    
    /**
     * Recursive function to get previous working day
     * If date passed to this function is on a working day, this will return same date
     * If date passed to this function is not on a working day, this will return previous working day
     * *********************
     * For Example, if day passed to this function is Monday, this will return Monday
     * but if day passed to the function is Sunday, then this will return Friday
     * *********************
     * @param - d - Date to operate on
     * @author - Manish Choudhari
     * */
    public Datetime getPreviousWorkingDay(Datetime d){
        
        
         //Check if new date is within working days
        if (!BusinessHours.isWithin(bHours.Id, d))
        {
            //New date is not within working days, recursively call same function to get previous date by subtracting 1 day
            d = d.addDays(-1);
            return getPreviousWorkingDay(d);
        } else{
            //New date is within working days, return this date
            return d;
        }
    }
    
    /**
     * Function to get next working day
     * If date passed to this function is on a working day, this will return same date
     * If date passed to this function is not on a working day, this will return next working day
     * *********************
     * For Example, if day passed to this function is Monday, this will return Monday
     * but if day passed to the function is Sunday, then this will return Monday
     * *********************
     * @param - d - Date to operate on
     * @author - Manish Choudhari
     * */
    public Datetime getNextWorkingDay(Datetime d){
        return BusinessHours.nextStartDate(bHours.Id, d);
    }
    
    
    /**
     * Check if supplied date is working day or not
     * @author - Manish Choudhari
     * */
    public Boolean isWorkingDay(Datetime d){
        return BusinessHours.isWithin(bHours.Id, d);
    }
    
    /*
     * Get numbe of business days between two dates
	 * @author - Manish Choudhari
	 * */
    public Integer getNoOfBusinessDaysBetweenDates(DateTime startDate, DateTime endDate){
        Integer count = 0;
        while(startDate <= endDate){
            if(isWorkingDay(startDate)) {
                count++;
            }
            startDate = startDate.addDays(1);
        }
        return count;
    }

    /*
     * Get numbe of business days between two dates
	 * @author - Manish Choudhari
	 * */
    public Datetime getDateConsideringOnlyBusinessDays(DateTime startDate, DateTime endDate) {
        Datetime aux = startDate;

        while(!startDate.isSameDay(endDate)) {
                if (isWorkingDay(startDate)) {
                    aux = aux.addDays(1);
                }

            startDate = startDate.addDays(1);
        }

        aux = Datetime.newInstance(     aux.year(),
                                        aux.month(),
                                        aux.day(),
                                        endDate.hour(),
                                        endDate.minute(),
                                        endDate.second());

        return aux;
    }    

    @AuraEnabled
    public static Map<String, Long> calculateTimeBetweenDates(DateTime startDate, DateTime endDate) {

        BusinessDays businessDays = BusinessDays.getInstance();
        Long secondsInADay = 60 * 60 * 1000 * 24, secondsInAHour = 60 * 60 * 1000;

        Datetime now = endDate == null ? System.now() : endDate;

        Long eplasedDate = BusinessHours.diff(businessDays.bHours.Id, startDate, now);
        
        Long milliseconds = eplasedDate;
        Long seconds = (Long)Math.floor(Math.mod(Math.mod(Math.mod(milliseconds, secondsInADay), secondsInAHour), (60 * 1000)) / 1000 * 1);
        Long minutes = (Long)Math.floor(Math.mod(Math.mod(milliseconds, secondsInADay), secondsInAHour) / (60 * 1000) * 1);
        Long hours = (Long)Math.floor(Math.mod(milliseconds, secondsInADay) / secondsInAHour * 1);
        Long days = (Long)Math.floor(milliseconds / secondsInADay * 1);
        Long years = (Long)Math.floor(days / 365);

        if (years > 1){ 
            days = days - (years * 365);
        }

        return new Map<String, Long> {
            'seconds' => seconds < 0 ? 0 : seconds,
            'minutes' => minutes < 0 ? 0 : minutes,
            'hours' => hours < 0 ? 0 : hours,
            'days' => days < 0 ? 0 : days,
            'years' => years < 0 ? 0 : years
        };

    }   
}