@IsTest
private class AutomationsControllerTest {

    private static testmethod void test_one(){

        Account acc = TestUtility.createAccPJ();
        insert acc;

        AutomationsController.restart('test_one');
        AutomationsController.restart('test_one', new Set<Id>{acc.Id});

        AutomationsController.stop('test_one');
        AutomationsController.stop('test_one', acc.Id);
        AutomationsController.stop('test_one', new Set<Id>{acc.Id});
        
        AutomationsController.restartAll('test_one');
        AutomationsController.restartAll('test_one', new Set<Id>{acc.Id});
        
        AutomationsController.isRunning('test_one');
        AutomationsController.isRunning('test_one', acc.Id);
        AutomationsController.isRunning('test_one', new Set<Id>{acc.Id});

        AutomationsController.executeOnce('test_one');
        AutomationsController.executeOnce('test_one', acc.Id);
        AutomationsController.executeOnce('test_one', new Set<Id>{acc.Id});
    }
}