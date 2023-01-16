@isTest
public with sharing class BudgetDetailSelectorTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;

        Setorizacao__c setor = TestUtility.createSetorizacaoWithValidData(acc, new User(Id = UserInfo.getUserId()));
        setor.Categoria__c = 'S';
        setor.VendedorSuporte__c = UserInfo.getUserId();
        insert setor;

        ListaCentroDistribuicao__c cdlist = TestUtility.createListaCentroDistribuicao();

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition();
        insert condPag;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, condPag);
        opp.ExternalPortal__c = '786876876';
        opp.StatusIntegracaoPortalCotacoes__c = 'Integrado';
        insert opp;


        Product2 prod = TestUtility.createProduct();
        insert prod;

        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.IdPortal__c = '012131231';
        qItem.Categoria__c = 'categTest';
        qItem.Product__c = prod.Id;
        insert qItem;
    }

    @isTest
    static void getCondicaoPagamentoPorCDTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<CondicaoPagamentoPorCD__c> result = BudgetDetailSelector.getCondicaoPagamentoPorCD(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 1);
    }

    @isTest
    static void getEstoqueAggregatedTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        Account acc = [SELECT Id FROM Account][0];
        List<Product2> productList = [SELECT Id FROM Product2];
        Set<Id> idSet = (new Map<Id,Product2>(productList)).keySet();

        Test.startTest();
        List<AggregateResult> result = BudgetDetailSelector.getEstoqueAggregated(String.valueOf(acc.Id), idSet);
        Test.stopTest();

        System.assertEquals(true, result.size() == 0 );
    }

    @isTest
    static void getOpportunityTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        Opportunity result = BudgetDetailSelector.getOpportunity(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(true, result != null);
    }

    @isTest
    static void getOpportunityTeamMemberTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        OpportunityTeamMember result = BudgetDetailSelector.getOpportunityTeamMember(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(true, result != null);
    }

    @isTest
    static void getAllQuoteItemListTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getAllQuoteItemList(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(true, result.size() > 0);
    }

    @isTest
    static void getQuoteItemMapTest(){
        QuoteItem__c quote = [SELECT Id FROM QuoteItem__c][0];
        List<String> qItemIdList = new List<String>();
        qItemIdList.add(String.valueOf(quote.Id));

        Test.startTest();
        Map<Id, QuoteItem__c> result = BudgetDetailSelector.getQuoteItemMap(qItemIdList);
        Test.stopTest();

        System.assertEquals(true, result.size() > 0);
    }

    @isTest
    static void getSetorizacaoListTest(){
        Account acc = [SELECT Id FROM Account][0];

        Test.startTest();
        List<Setorizacao__c> result = BudgetDetailSelector.getSetorizacaoList(String.valueOf(acc.Id));
        Test.stopTest();

        System.assertEquals(true, result.size() > 0);
    }

    @isTest
    static void getUniqueQuoteItemByIdPortalTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        QuoteItem__c result = BudgetDetailSelector.getUniqueQuoteItemByIdPortal('123123123', String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result != null);
    }
    
    @isTest
    static void getQuoteItemsByIdPortalTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemsByIdPortal('123123123', String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemTest(){
        QuoteItem__c quote = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        QuoteItem__c result = BudgetDetailSelector.getQuoteItem(String.valueOf(quote.Id));
        Test.stopTest();

        System.assertEquals(true, result != null);
    }

    @isTest
    static void getPricebookEntryListTest(){
        Product2 prod = [SELECT Id FROM Product2][0];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry][0];

        Test.startTest();
        List<PricebookEntry> result = BudgetDetailSelector.getPricebookEntryList(String.valueOf(prod.Id), String.valueOf(pbEntry.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getConditionPaymentByCDTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<CondicaoPagamentoPorCD__c> result = BudgetDetailSelector.getConditionPaymentByCD(String.valueOf(opp.Id), '45456789000132');
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getCurrentUserGroupTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        Group result = BudgetDetailSelector.getCurrentUserGroup();
        Test.stopTest();

        System.assertEquals(true, result != null);
    }

    @isTest
    static void getCurrentUserGroupListTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<Group> result = BudgetDetailSelector.getCurrentUserGroupList();
        Test.stopTest();

        System.assertEquals(true, result.size() > 0);
    }

    @isTest
    static void getEstoqueListByProdCodeTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<Estoque__c> result = BudgetDetailSelector.getEstoqueListByProdCode('BHGF34256');
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getLastOppLineItemWonTest(){
        Account acc = [SELECT Id FROM Account][0];

        Test.startTest();
        OpportunityLineItem result = BudgetDetailSelector.getLastOppLineItemWon('BHGF34256', String.valueOf(acc.Id));
        Test.stopTest();

        System.assertEquals(false, result != null);
    }

    @isTest
    static void getLastOppLineItemLostTest(){
        Account acc = [SELECT Id FROM Account][0];

        Test.startTest();
        OpportunityLineItem result = BudgetDetailSelector.getLastOppLineItemLost('BHGF34256', String.valueOf(acc.Id));
        Test.stopTest();

        System.assertEquals(false, result != null);
    }

    @isTest
    static void getQuoteItemsWithCNPJCDTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemsWithCNPJCD(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getConditionPaymentListTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<CondicaoPagamentoPorCD__c> result = BudgetDetailSelector.getConditionPaymentList(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getUserCategoriesAggregatedTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<AggregateResult> result = BudgetDetailSelector.getUserCategoriesAggregated(String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(true, result.size() > 0);
    }

    @isTest
    static void getQuoteItemForSetItemCdTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        QuoteItem__c quote = [SELECT Id FROM QuoteItem__c][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemForSetItemCd(String.valueOf(opp.Id), '35467656000132', String.valueOf(quote.Id), '012131231');
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getItemCampaignByCDTest(){
        Account acc = [SELECT Id FROM Account][0];
        Product2 prod = [SELECT ProductCode FROM Product2][0];
        QuoteItem__c quote = [SELECT Id FROM QuoteItem__c][0];
        List<String> cdCodeList = new List<String>();
        ListaCentroDistribuicao__c cd = [SELECT CodigoCD__c FROM ListaCentroDistribuicao__c][0];
        cdCodeList.add(cd.CodigoCD__c);

        Test.startTest();
        List<ItemCampanha__c> result = BudgetDetailSelector.getItemCampaignByCD(cdCodeList,String.valueOf(prod.ProductCode), String.valueOf(acc.Id) );
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getContractByProductTest(){
        Account acc = [SELECT Id FROM Account][0];
        Product2 prod = [SELECT ProductCode FROM Product2][0];

        Test.startTest();
        List<ItemContrato__c> result = BudgetDetailSelector.getContractByProduct(String.valueOf(acc.Id), String.valueOf(prod.ProductCode));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemsFromIdPortalUserBuTest(){

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemsFromIdPortalUserBu(new List<String>(),'2131232131', '21312312321', new List<String>() );
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemListToCopyTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemListToCopy(new Set<String>(), String.valueOf(opp.Id));
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemProgramacaoEntregaTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<QuoteItem__c> result = BudgetDetailSelector.getQuoteItemProgramacaoEntrega('324242342');
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemCategoryAggregateTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<AggregateResult> result = BudgetDetailSelector.getQuoteItemCategoryAggregate('324242342');
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getConditionPaymentByNameTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<CondicaoPagamento__c> result = BudgetDetailSelector.getConditionPaymentByName(new List<String>());
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getQuoteItemWithHistoryTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        QuoteItem__c result = BudgetDetailSelector.getQuoteItemWithHistory('21312312312', String.valueOf(opp.Id));
        Test.stopTest();
 
        System.assertEquals(false, result != null);
    }
    
    @isTest
    static void getProductListFromCodeTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        List<Product2> result = BudgetDetailSelector.getProductListFromCode(new Set<String>());
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }
    
    @isTest
    static void getProductMapFromCodeTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];

        Test.startTest();
        Map<Id, Product2> result = BudgetDetailSelector.getProductMapFromCode(new Set<String>());
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }
    
    @isTest
    static void getLastOpportunityLineItemAggrTest(){
        Opportunity opp = [SELECT Id FROM Opportunity][0];
        Account acc = [SELECT Id FROM Account][0];

        Test.startTest();
        List<AggregateResult> result = BudgetDetailSelector.getLastOpportunityLineItemAggr(String.valueOf(acc.Id), new Set<Id>());
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }
    
    @isTest
    static void getLastOpportunityLineItemMapTest(){
        Test.startTest();
        Map<Id, OpportunityLineItem> result = BudgetDetailSelector.getLastOpportunityLineItemMap(new List<String>());
        Test.stopTest();

        System.assertEquals(false, result.size() > 0);
    }

    @isTest
    static void getUnfilledConditionPaymentTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        CondicaoPagamento__c condPag = [SELECT Id FROM CondicaoPagamento__c LIMIT 1];
        CondicaoPagamentoPorCD__c conpagcd = TestUtility.createCondicaoPagamentoPorCD(condPag.Id);
        conpagcd.orcamento__c = opp.Id;
        insert conpagcd;
        Test.startTest();
        BudgetDetailSelector.getUnfilledConditionPayment(opp.Id, new List<String>());
        Test.stopTest();

    }

}
