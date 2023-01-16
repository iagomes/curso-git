@isTest
public with sharing class RecommendationsServiceTest {

    @isTest(SeeAllData=true)
    public static void RecommendationsServiceTest() {
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
            Name = 'Pricebook Test 123',
            ExternalId__c = 'B123123'
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

        List<RecommendationsService.RecommendationData> listRecData = new List<RecommendationsService.RecommendationData>();

        listRecData.addAll(RecommendationsService.getRecommendations(opportunity.Id, 1));

        RecommendationsService.ReactionDataInput reactDataInput = new RecommendationsService.ReactionDataInput();
        if(!listRecData.isEmpty()) {
            reactDataInput.externalId       = listRecData[0].externalId;
            reactDataInput.targetId         = listRecData[0].targetId;
            reactDataInput.targetActionId   = listRecData[0].targetActionId;
            reactDataInput.targetActionName = listRecData[0].targetActionName;
            reactDataInput.reaction         = 'Accepted';
    
            RecommendationsService.setReaction(reactDataInput);
            RecommendationsService.getRecommendationPDF(new List<String>{opportunity.Id});
        }
    }
}
