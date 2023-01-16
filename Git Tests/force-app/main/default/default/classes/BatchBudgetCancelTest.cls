@isTest
public with sharing class BatchBudgetCancelTest {
    @TestSetup
    static void makeData(){
        User user = TestUtility.createUser();
        insert user;
        Product2 product = TestUtility.createProduct();
        insert product;
        Opportunity opportunity = TestUtility.createOpportunity(user);
        opportunity.CloseDate = Date.today().addDays(-1);
        opportunity.StageName = 'Em digitação';
        insert opportunity;
        PricebookEntry pricebookEntry = [SELECT Id, Product2Id, IsActive FROM PricebookEntry WHERE Product2Id =: product.Id][0];
        pricebookEntry.IsActive = true;
        update pricebookEntry;
        OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pricebookEntry);
        insert oppLineItem;
    }
    
    @isTest
    public static void BatchBudgetCancel() {
        BatchBudgetCancelSchedule batchSchedule = new BatchBudgetCancelSchedule();
        batchSchedule.execute(null);
        BatchBudgetCancelSchedule.scheduleBatch();
    }
}
