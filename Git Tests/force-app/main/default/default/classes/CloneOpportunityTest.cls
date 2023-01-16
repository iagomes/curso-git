@isTest
public with sharing class CloneOpportunityTest {
    
    @isTest
    public static void testFlowCloneOpportunity() {
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

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );
        insert opportunityLineItem;

        CloneOpportunity.FlowInputs fInputs = new CloneOpportunity.FlowInputs();
        fInputs.oppId = opportunity.Id;
        fInputs.accId = opportunity.AccountId;

        List<String> budgetNumbers = CloneOpportunity.flowCloneOpportunity(new List<CloneOpportunity.FlowInputs>{fInputs});
        System.debug(budgetNumbers);

        List<Opportunity> opportunityClonedList = [SELECT Id FROM Opportunity WHERE NumeroOrcamento__c IN :budgetNumbers];

        // System.assert(opportunityClonedList.size() == 1);

        // List<OpportunityLineItem> opportunityLineItemClonedList = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityClonedList.get(0).Id];

        // System.assert(opportunityLineItemClonedList.size() == 1);
    }
}