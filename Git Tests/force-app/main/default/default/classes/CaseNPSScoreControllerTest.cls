@isTest
public with sharing class CaseNPSScoreControllerTest {

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
    public static void getNPSScoreOk() {
        
        Test.startTest();
     
        Case record = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '[{ "rating" :{"value":"7"}}]', null));
        
        Map<String, Object> response = CaseNPSScoreController.getNPSScore(record.Id);
        System.assertEquals('7', (String)response.get('value'));
        
        Test.stopTest();
    }

    @isTest
    public static void getNPSScoreNoData() {
        
        Test.startTest();
     
        Case record = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '[]', null));
        
        Map<String, Object> response = CaseNPSScoreController.getNPSScore(record.Id);
        System.assertEquals('nodata', (String)response.get('nodata'));
        
        Test.stopTest();
    }
    
    @isTest
    public static void getNPSScoreNok() {
        
        Test.startTest();
        
 		Case record = [SELECT Id FROM Case LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'OK', '[]', null));
        try {
        	CaseNPSScoreController.getNPSScore(record.Id);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Script'));
        }
       
        Test.stopTest();
    }

}