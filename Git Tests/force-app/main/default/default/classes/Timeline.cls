public with sharing class Timeline {
    
    @InvocableMethod(label='Calculate elapsed time' description='Calculate eplased time when closing a timeline' category='Timeline__c')
    public static List<Timeline__c> calculateElapsedTime(List<Timeline__c> timelines) {

        BusinessDays businessDays = BusinessDays.getInstance();
        for (Timeline__c timeline : timelines) {
            
            timeline.End_date__c = System.now();

            Long eplasedDate = BusinessHours.diff(businessDays.bHours.Id, timeline.CreatedDate, timeline.End_date__c);
            Long milliseconds = eplasedDate;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;
            Long years = days / 365;
 
            timeline.Elapsed_milisenconds__c = milliseconds;
            timeline.Elapsed_minutes__c = minutes;
            timeline.Elapsed_seconds__c = seconds;   
            timeline.Elapsed_hours__c = hours;
            timeline.Elapsed_days__c = days;
            timeline.Elapsed_years__c = years;
            
        }

        return timelines;
    }
}