@isTest
public with sharing class CancelOppItemControllerTest {
    @isTest
    public static void testCancelOppItem() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoContaOrdem').getRecordTypeId(),
            PrazoValidade__c = 10
        );
        insert opportunity;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>();
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );
        OpportunityLineItem opportunityLineItem2 = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100,
            MotivoCancelamento__c = 'Desistiu da compra'
        );
        listOppLineItem.add(opportunityLineItem);
        listOppLineItem.add(opportunityLineItem2);
        insert listOppLineItem;

        CancelOppItemController.getBudgetItens(String.valueOf(opportunity.id));

        List<CancelOppItemController.ProductData> listProdData = new List<CancelOppItemController.ProductData>();
        listProdData.add(new CancelOppItemController.ProductData(opportunityLineItem));
        listProdData.add(new CancelOppItemController.ProductData(opportunityLineItem2));

        system.debug(JSON.serializePretty(listProdData));

        CancelOppItemController.cloneBudget(JSON.serialize(listProdData));

        listProdData[0].motivoCancelamento = 'Desistiu da compra';

        CancelOppItemController.cloneBudget(JSON.serialize(listProdData));
    }
}
