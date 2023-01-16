@isTest
public class TimelineTest {
        
    @testSetup
    public static void setup() {
        Account acc = TestUtility.createAccPJ();
        insert acc;
        
        Contact ctt = TestUtility.createContact(acc.Id);
        insert ctt;
        
        Case c = TestUtility.createCase(acc, ctt);
        insert c;          
    }
    
    @isTest
    public static void createCase() {
                
        Case c = [SELECT Id FROM Case];
        
        Timeline__c tm = new Timeline__c(
            Name = 'Test',
			Case__c = c.Id
		);
        insert tm;
        
        tm = [SELECT Id, CreatedDate FROM Timeline__c ORDER BY CreatedDate DESC LIMIT 1];
            
        List<Timeline__c> timelines = Timeline.calculateElapsedTime(new List<Timeline__c> { tm });
        
        System.assertNotEquals(null, timelines[0].Elapsed_milisenconds__c);
    }

}