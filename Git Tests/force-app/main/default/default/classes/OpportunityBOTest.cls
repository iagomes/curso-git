@IsTest
public with sharing class OpportunityBOTest {
    @isTest
    public static void createStandardEntriesTest() {
        OpportunityBO bo = new OpportunityBO();
        List<SObject> listToInsert = new List<SObject>();
        List<SObject> listToInsert2 = new List<SObject>();
        Account account                 = TestUtility.createAccPJ();
        listToInsert.add(account);
        Contact contact                 = TestUtility.createContact(account);
        listToInsert.add(contact);
        CondicaoPagamento__c conditionP = TestUtility.createConditionPayment();
        listToInsert.add(conditionP);
        Product2 product                = TestUtility.createProduct();
        product.CategoriaComercial__c = 'M';
        Product2 product2                = TestUtility.createProduct();
        product.CategoriaComercial__c = 'E';
        listToInsert.add(product);
        listToInsert.add(product2);
        
        // List<String> devNameGroupList = new List<String>{
        //     'DiretorNacional',
        //     'DiretorNacional_E',
        //     'GerenteNacional_M',
        //     'Pricing',
        //     'Pricing_M',
        //     'Pricing_E',
        //     'GerenteNacional',
        //     'Coordenador',
        //     'Coordenador_E',
        //     'Coordenador_M'
        // };
        // List<Group> groupIdList = [SELECT RelatedId, DeveloperName FROM Group WHERE DeveloperName IN:devNameGroupList];
        
        // List<User> userList = new List<User>();
        // Integer i = 3423;
        // for(Group devGroup : groupIdList){
        //     String s = 'adsipajnfjvcx';
        //     User us = TestUtility.createUser(s+i);
        //     us.userRoleId = devGroup.RelatedId;
        //     userList.add(us);
        //     i++;
        // }  
        // insert userList;

         insert listToInsert;
		PricebookEntry pricebookEntry   = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id][0];
        pricebookEntry.IsActive         = true;
        update pricebookEntry;


        List<ParametroScore__c> paramList = new List<ParametroScore__c>();
        paramList.add(new ParametroScore__c(Name = 'A', Score__c = 90));
        paramList.add(new ParametroScore__c(Name = 'B', Score__c = 80));
        paramList.add(new ParametroScore__c(Name = 'C', Score__c = 70));
        paramList.add(new ParametroScore__c(Name = 'D', Score__c = 60));
        insert paramList;

        User user2 = TestUtility.createUserTwo();
        insert user2;


        List<Opportunity> opportunityList                       = new List<Opportunity>();
        List<Opportunity> opportunityUpdateList                 = new List<Opportunity>();
        List<OpportunityLineItem> opportunityLineItemList       = new List<OpportunityLineItem>();
        List<OpportunityLineItem> opportunityLineItemUpdateList = new List<OpportunityLineItem>();
        


        Opportunity opportunity  = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity);
        Opportunity opportunity2 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity2);
        Opportunity opportunity3 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity3);
        Opportunity opportunity4 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity4);
        Opportunity opportunity5 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity5);
        Opportunity opportunity6 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity6);
        Opportunity opportunity7 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity7);
        Opportunity opportunity8 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity8);
        Opportunity opportunity9 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity9);
        Opportunity opportunity10 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunityList.add(opportunity10);
        Opportunity opportunity11 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunity11.Score__c = 100;
        opportunityList.add(opportunity11);
        Opportunity opportunity12 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunity12.Score__c = 100;
        opportunityList.add(opportunity12);
        Opportunity opportunity13 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunity13.Score__c = 100;
        opportunityList.add(opportunity13);
        Opportunity opportunity14 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunity14.Score__c = 100;
        opportunity14.RepresentanteVDELookup__c = UserInfo.getUserId();
        opportunity14.RepresentanteVDILookup__c = UserInfo.getUserId();
        opportunity14.VendedorSuporte__c = UserInfo.getUserId();
        opportunity14.Vendedor__c = UserInfo.getUserId();
        opportunityList.add(opportunity14);
        Opportunity opportunity15 = TestUtility.createOpportunity(account, contact, conditionP);
        opportunity15.EnviarAprovacao__c = false;
        opportunityList.add(opportunity15);
        insert opportunityList;


        OpportunityLineItem opportunityLineItem = TestUtility.createOpportunityLineItem(opportunity5, product, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem);
        OpportunityLineItem opportunityLineItem2 = TestUtility.createOpportunityLineItem(opportunity6, product2, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem2);
        OpportunityLineItem opportunityLineItem3 = TestUtility.createOpportunityLineItem(opportunity7, product, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem3);
        OpportunityLineItem opportunityLineItem4 = TestUtility.createOpportunityLineItem(opportunity8, product2, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem4);
        OpportunityLineItem opportunityLineItem5 = TestUtility.createOpportunityLineItem(opportunity9, product, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem5);
        OpportunityLineItem opportunityLineItem6 = TestUtility.createOpportunityLineItem(opportunity10, product2, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem6);
        OpportunityLineItem opportunityLineItem7 = TestUtility.createOpportunityLineItem(opportunity11, product, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem7);
        OpportunityLineItem opportunityLineItem8 = TestUtility.createOpportunityLineItem(opportunity11, product, pricebookEntry);
        opportunityLineItem8.BloqueadoRegionalizacao__c = true;
        opportunityLineItemList.add(opportunityLineItem8);

        OpportunityLineItem opportunityLineItem9 = TestUtility.createOpportunityLineItem(opportunity11, product2, pricebookEntry);
        opportunityLineItemList.add(opportunityLineItem9);
        insert opportunityLineItemList;


        opportunityLineItem2.ScoreBU__c = 80;
        opportunityLineItemUpdateList.add(opportunityLineItem2);
        opportunityLineItem3.ScoreBU__c = 70;
        opportunityLineItemUpdateList.add(opportunityLineItem3);
        opportunityLineItem4.ScoreBU__c = 60;
        opportunityLineItemUpdateList.add(opportunityLineItem4);
        opportunityLineItem5.ScoreBU__c = 90;
        opportunityLineItemUpdateList.add(opportunityLineItem5);
        opportunityLineItem6.ScoreBU__c = 100;
        opportunityLineItemUpdateList.add(opportunityLineItem6);
        opportunityLineItem7.foraMalha__c = true;
        opportunityLineItem6.ScoreBU__c = 100;
        opportunityLineItemUpdateList.add(opportunityLineItem7);
        update opportunityLineItemUpdateList;


        opportunity.RejeicaoProcesso__c   = true;
        opportunityUpdateList.add(opportunity);

        opportunity2.RecallProcesso__c    = true;
        opportunityUpdateList.add(opportunity2);

        opportunity3.AprovadoComercial__c = true;
        opportunity3.AprovadoPricing__c   = true;
        opportunity3.EnviarAprovacao__c   = true;
        opportunityUpdateList.add(opportunity3);

        opportunity4.SolicitacaoAprovada__c = true;
        opportunityUpdateList.add(opportunity4);

        opportunity5.EnviarAprovacao__c = true;
        opportunityUpdateList.add(opportunity5);

        opportunity6.EnviarAprovacao__c = true;
        opportunityUpdateList.add(opportunity6);

        opportunity7.EnviarAprovacao__c = true;
        opportunityUpdateList.add(opportunity7);

        opportunity8.EnviarAprovacao__c = true;
        opportunityUpdateList.add(opportunity8);

        opportunity9.EnviarAprovacao__c = true;
        opportunityUpdateList.add(opportunity9);

        opportunity10.EnviarAprovacao__c = true;

        opportunity11.EnviarAprovacao__c = true;
        opportunity11.AprovadoPricing__c = true;
        
        opportunityUpdateList.add(opportunity11);

        opportunity12.EnviarAprovacao__c = false;
        opportunity12.RecallProcesso__c = true;
        opportunityUpdateList.add(opportunity12);
        opportunity15.EnviarAprovacao__c = true;
        opportunity15.SolicitacaoAprovada__c = true;
        opportunity15.UltimaAprovacao__c = 'Oportunidade_AprovacaoComercial';
        opportunityUpdateList.add(opportunity15);


        update opportunity10;
        update opportunityUpdateList;
        system.debug(opportunityUpdateList);
        opportunity2.RecallProcesso__c    = false;
        opportunity2.FretePicklist__c    = 'CIF';
        update opportunity2;

        opportunity2.TipoFrete__c    = 'CIF';
        update opportunity2;      


        Map<Id, Opportunity> oldRecordMap = new Map<Id, Opportunity>{opportunity2.Id => opportunity2};
        bo.setFretePicklist(opportunity2,oldRecordMap);
        bo.setVendedorOnLookupChange(oldRecordMap, new List<Opportunity>{opportunity2});

        opportunity14.Vendedor__c = user2.id;
        opportunity14.RepresentanteVDELookup__c = user2.id;
        opportunity14.RepresentanteVDILookup__c = user2.id;
        update opportunity14;
        bo.setVendedorOnLookupChange(null, new List<Opportunity>{opportunity14} );

        // opportunity14.Vendedor__c = UserInfo.getUserId();
        
        // update opportunity14;
        //bo.setVendedorOnLookupChange(null, new List<Opportunity>{opportunity14} );
        Setorizacao__c setor = TestUtility.createSetorizacaoWithValidData(account, user2);
        setor.CodigoMesa__c = 'Sul';
        setor.Categoria__c = 'E';
        setor.Regiao__c = 'S';
        insert setor;


        delete opportunity;
    }

    @IsTest
    public static void createStandardEntriesTest2() {
        try{
            OpportunityBO bo = new OpportunityBO();
            List<SObject> listToInsert = new List<SObject>();
            List<SObject> listToInsert2 = new List<SObject>();
            Account account                 = TestUtility.createAccPJ();
            listToInsert.add(account);
            Contact contact                 = TestUtility.createContact(account);
            listToInsert.add(contact);
            CondicaoPagamento__c conditionP = TestUtility.createConditionPayment();
            listToInsert.add(conditionP);
            Product2 product                = TestUtility.createProduct();
            product.CategoriaComercial__c = 'M';
            Product2 product2                = TestUtility.createProduct();
            product.CategoriaComercial__c = 'E';
            listToInsert.add(product);
            listToInsert.add(product2);
            
          
    
             insert listToInsert;
            PricebookEntry pricebookEntry   = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id][0];
            pricebookEntry.IsActive         = true;
            update pricebookEntry;
    
    
            List<ParametroScore__c> paramList = new List<ParametroScore__c>();
            paramList.add(new ParametroScore__c(Name = 'A', Score__c = 90));
            paramList.add(new ParametroScore__c(Name = 'B', Score__c = 80));
            paramList.add(new ParametroScore__c(Name = 'C', Score__c = 70));
            paramList.add(new ParametroScore__c(Name = 'D', Score__c = 60));
            insert paramList;
    
            User user2 = TestUtility.createUserTwo();
            insert user2;
    
    
            List<Opportunity> opportunityList                       = new List<Opportunity>();
            List<Opportunity> opportunityUpdateList                 = new List<Opportunity>();
            List<OpportunityLineItem> opportunityLineItemList       = new List<OpportunityLineItem>();
            List<OpportunityLineItem> opportunityLineItemUpdateList = new List<OpportunityLineItem>();        
    
    
            Opportunity opportunity  = TestUtility.createOpportunity(account, contact, conditionP);
            opportunityList.add(opportunity);
         
            
            opportunity.VendedorSuporte__c = UserInfo.getUserId();   
            opportunity.Vendedor__c = UserInfo.getUserId();   
            opportunity.RepresentanteVDELookup__c = UserInfo.getUserId();
            opportunity.RepresentanteVDILookup__c = UserInfo.getUserId();
    
            insert opportunityList;
    
          
            Map<Id, Opportunity> oldRecordMap = new Map<Id, Opportunity>{opportunity.Id => opportunity};    
            bo.setVendedorOnLookupChange(oldRecordMap, new List<Opportunity>{opportunity});
    
            opportunity.VendedorSuporte__c = user2.id;   
            opportunity.Vendedor__c = UserInfo.getUserId();   
            opportunity.RepresentanteVDELookup__c = user2.id;
            opportunity.RepresentanteVDILookup__c = user2.id;
            bo.setVendedorOnLookupChange(oldRecordMap, new List<Opportunity>{opportunity} );
            OpportunityBO.validaAprovacao(oldRecordMap, oldRecordMap, oldRecordMap.values());

        } catch(Exception e) {
            system.debug(e);
        }
    }

    public static void preencherNomeOportunidadeTest(){
        Account acc = new Account();
        insert acc;
        Opportunity opp = new Opportunity(AccountId = acc.Id);
        new OpportunityBO().preencherNomeOportunidade(new List<Opportunity>{opp});
    }

    @IsTest
    public static void checkDueDateUpdatesTest() {
        try {
            Account account = TestUtility.createAccPJ();
            Contact contact = TestUtility.createContact(account);
            CondicaoPagamento__c conditionP = TestUtility.createConditionPayment();
    
            List<SObject> listToInsert = new List<SObject>();
            listToInsert.add(account);
            listToInsert.add(contact);
            listToInsert.add(conditionP);
            insert listToInsert;
    
            Opportunity opportunity  = TestUtility.createOpportunity(account, contact, conditionP);
            opportunity.DataVencimento__c = Datetime.now();
            insert opportunity;
    
            OpportunityBO obo = new OpportunityBO();
            Test.startTest();
            opportunity.DataVencimento__c = Datetime.now().addDays(3);
            opportunity.TabulacaoN1__c  = 'Recusa';
            opportunity.TabulacaoN2__c  = 'Cotação Vencida';
            update opportunity;
            Test.stopTest();
    
            List<Opportunity> resultList = [
                SELECT Id, TabulacaoN1__c, TabulacaoN2__c
                FROM Opportunity
                WHERE DataVencimento__c = :opportunity.DataVencimento__c
                LIMIT 1
            ];
            Boolean isTabulacaoCleared = false;
            if ((resultList[0].TabulacaoN1__c == null) && (resultList[0].TabulacaoN2__c == null)) {
                isTabulacaoCleared = true;
            }
            system.debug(resultList[0].Id +' | '+resultList[0].TabulacaoN1__c +' | '+resultList[0].TabulacaoN2__c);
        } catch(Exception e) {
            system.debug(e);
        }
        
        //System.assertEquals(true, isTabulacaoCleared);
    }

    @IsTest
    public static void OpportunityBOTest() {
        system.debug(OpportunityTH.disableTrigger());
        system.debug(OpportunityTH.enableTrigger());
        System.assertEquals(false, OpportunityTH.disableTrigger());
        System.assertEquals(true, OpportunityTH.enableTrigger());
    }
}
