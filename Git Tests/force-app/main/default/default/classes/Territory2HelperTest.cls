@isTest
public with sharing class Territory2HelperTest {

    @isTest
    public static void Territory2HelperTest() {

        Territory2Model tModel = ActingTableTerritoryManagement.getTerritory2Model('Mesas');
        Territory2Type tType = ActingTableTerritoryManagement.getTerritory2Type('Mesas');
        
        Test.startTest();
        Territory2 t = TestUtility.createTerritory2(tModel.Id, tType.Id);
        insert t;
        Test.stopTest();

        Territory2Helper tClass = new Territory2Helper();

        Territory2Handler.enableTrigger();
        Territory2Handler.disableTrigger();
    }
}
