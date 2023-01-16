@isTest
public class SalesmanNotificationPortalTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccount();
        insert acc;

        Setorizacao__c setor = TestUtility.createSetorizacaoWithValidData(acc, new User(Id = UserInfo.getUserId()));
        setor.Categoria__c = 'M';
        setor.VendedorSuporte__c = UserInfo.getUserId();
        insert setor;

        Contact contact = TestUtility.createContact(acc.Id);
        insert contact;

        CondicaoPagamento__c condPag = TestUtility.createPaymentCondition2();
        insert condPag;

        Opportunity opp = TestUtility.createOpportunity(acc, contact, condPag);
        opp.CanalEntrada__c = 'Bionexo';
        opp.DataVencimento__c = System.now();
        opp.ExternalPortal__c = 'test1';
        opp.StatusIntegracaoPortalCotacoes__c = 'Integrado';
        insert opp;

        User userOne = TestUtility.createUser('user1');
        User userTwo = TestUtility.createUser('user2');
        insert new List<User>{userOne, userTwo};

        Setorizacao__c setorizacao1 = TestUtility.createSetorizacaoWithValidData(acc, userOne);
        setorizacao1.VendedorSuporte__c = userOne.Id;
        setorizacao1.Categoria__c = 'M';
        setorizacao1.ExternalId__c = '1';
        Setorizacao__c setorizacao2 = TestUtility.createSetorizacaoWithValidData(acc, userTwo);
        setorizacao2.VendedorSuporte__c = userTwo.Id;
        setorizacao2.Categoria__c = 'M';
        setorizacao2.ExternalId__c = '2';
        insert new List<Setorizacao__c>{setorizacao1, setorizacao2};

        OpportunityTeamMember oppTeamMemberOne = TestUtility.createOpportunityTeamMember(opp);
        oppTeamMemberOne.UserId = userOne.Id;
        OpportunityTeamMember oppTeamMemberTwo = TestUtility.createOpportunityTeamMember(opp);
        oppTeamMemberTwo.UserId = userTwo.Id;
        insert new List<OpportunityTeamMember>{oppTeamMemberOne,oppTeamMemberTwo};

        QuoteItem__c qItem = TestUtility.createQuoteItem(opp);
        qItem.IdPortal__c = '1';
        qItem.Categoria__c = 'M';
        qItem.Vendedor__c = userOne.Id;
        qItem.VendedorRespondeu__c = userTwo.Id;
        QuoteItem__c qItem2 = TestUtility.createQuoteItem(opp);
        qItem2.IdPortal__c = '1';
        qItem2.Categoria__c = 'M';
        qItem2.Vendedor__c = userTwo.Id;
        qItem2.VendedorRespondeu__c = userOne.Id;
        insert new List<QuoteItem__c>{qItem, qItem2};

        Order orderOne = TestUtility.createOrder(acc);
        orderOne.OpportunityId = opp.Id;
        orderOne.IdPortalCotacoes__c = '1';
        insert orderOne;
    }

    @isTest
    static void orderInNotificationTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order order = [SELECT Id FROM Order LIMIT 1];
        QuoteItem__c qItem = [SELECT Id FROM QuoteItem__c LIMIT 1];

        SalesmanNotificationPortal.orderInNotification(
            order.Id,
            opp.Id,
            new List<String>{qItem.Id},
            0
        );
    }
}
