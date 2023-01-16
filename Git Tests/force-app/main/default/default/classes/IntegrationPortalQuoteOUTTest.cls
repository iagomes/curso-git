@isTest
global class IntegrationPortalQuoteOUTTest {

        @TestSetup
        static void createData(){
            User selfUser = new User(Id = UserInfo.getUserid());
            selfUser.codigoUsuario__c = '1234';
            try{
                update selfUser;
            }catch(Exception ex){}
            System.runAs(selfUser){

                Fornecedor__c fornecedor = new Fornecedor__c(Name = 'testfor', ExternalId__c = '12345');
                insert fornecedor;

                Product2 product                       = TestUtility.createProduct();
                product.ExternalId__c = '1234';
                product.UnidadeMedida__c = 'F';
                product.fornecedor__c = fornecedor.Id;
                insert product;
                Account acc                            = TestUtility.createAccount();
                acc.CNPJ__c = '61182609000113';
                insert acc;
                Order order                            = TestUtility.createOrderTwo(acc);
                insert order;
                Opportunity opportunity                = TestUtility.createOpportunity(selfUser);
                opportunity.PrazoEntrega__c            = 14;
                opportunity.PrazoValidade__c            = 14;
                opportunity.AccountId = acc.Id;
                opportunity.ExternalPortal__c = '45612387643713';
                opportunity.Integradora__c = 'Bionexo';
                opportunity.IdPortal__c = '32443';
                opportunity.IdIntegrator__c = '45612387643713';
                opportunity.CDsBloqueado__c = '52202744000788;';
                opportunity.CNPJCD__c = '62938773000170';
                opportunity.DataVencimento__c = Datetime.now().addDays(5);

                Opportunity opportunity2                = TestUtility.createOpportunity(selfUser);
                opportunity2.PrazoEntrega__c            = 14;
                opportunity2.PrazoValidade__c            = 14;
                opportunity2.AccountId = acc.Id;
                opportunity2.ExternalPortal__c = '456123876437131';
                opportunity2.Integradora__c = 'Bionexo';
                opportunity2.IdPortal__c = '32444';
                opportunity2.IdIntegrator__c = '456123876437131';
                opportunity2.CNPJCD__c = '62938773000170';
                opportunity2.DataVencimento__c = Datetime.now().addDays(5);


                
                insert new List<Opportunity>{opportunity, opportunity2};
    
                CondicaoPagamento__c condPag = TestUtility.createPaymentCondition2();
                insert condPag;
                CondicaoPagamentoPorCD__c condpagCD = TestUtility.createCondicaoPagamentoPorCD(condPag.Id);
                //condpagCD.ExternalId__c ='622f8823d2568958f9dc85aa';
                condpagCD.CNPJCD__c = '09053134000900';
                condpagCD.Orcamento__c = opportunity.Id;
                condpagCD.CloseDate__c = Date.newInstance(2022, 11, 01);
                CondicaoPagamentoPorCD__c condpagCD2 = TestUtility.createCondicaoPagamentoPorCD(condPag.Id);
                //condpagCD.ExternalId__c = '622f8823d2568958f9dc85ab';
                condpagCD2.CNPJCD__c = '25211499000107';
                condpagCD2.Orcamento__c = opportunity2.Id;
                condpagCD2.CloseDate__c = Date.newInstance(2022, 11, 01);
                insert new List<CondicaoPagamentoPorCD__c>{condpagCD, condpagCD2};
    
                Setorizacao__c set1 = TestUtility.createSetorizacaoWithValidData(acc, selfUser);
                set1.Categoria__c = 'M';
                set1.VendedorSuporte__c = UserInfo.getUserId();
                insert set1;
    
                OpportunityTeamMember teamMember = TestUtility.createOpportunityTeamMember(opportunity);
                OpportunityTeamMember teamMember2 = TestUtility.createOpportunityTeamMember(opportunity2);
                insert new List<OpportunityTeamMember>{teamMember, teamMember2};
    
               
                Pricebook2 pb2 = TestUtility.createPricebook2();
                pb2.ExternalId__c = 'B01';
                pb2.isActive = true;
                upsert pb2 Pricebook2.ExternalId__c;

                PricebookEntry pricebookEntry          = new PriceBookEntry(
                    pricebook2Id = pb2.Id, 
                    product2Id = product.Id,
                    unitPrice = 10,
                    isActive = true
                );
                insert pricebookEntry;
        
                OpportunityLineItem opportunityLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pricebookEntry);
                opportunityLineItem.Status__c = 'Aguardando Integração';
                opportunityLineItem.CNPJCD__c = '52202744000788';
                opportunityLineItem.Comentarios__c = '12313';
                opportunityLineItem.CodigoRastreio__c = '12313';
                opportunityLineItem.ValorPortal__c = 12313;
                

                OpportunityLineItem opportunityLineItem2 = TestUtility.createOpportunityLineItem(opportunity2, product, pricebookEntry);
                opportunityLineItem2.CNPJCD__c = '52202744000788';
                opportunityLineItem2.Status__c = 'Respondido';
                insert new List<OpportunityLineItem>{opportunityLineItem, OpportunityLineItem2};

                QuoteItem__c quoteitem = TestUtility.createQuoteItem(opportunity, selfUser);
                quoteitem.OpportunityLineItem__c = opportunityLineItem.Id;
                quoteitem.OpportunityId__c = opportunity.Id;
                quoteitem.Product__c = product.Id;
                quoteitem.idportal__C = '32443';
                quoteitem.Status__c = 'Vinculado';
                quoteitem.TabulacaoN1__c = 'Cotado';
                quoteitem.Categoria__c = 'M';
                quoteitem.FatorConversao__c = 2;
                QuoteItem__c quoteitem1 = TestUtility.createQuoteItem(opportunity2, selfUser);
                quoteitem1.OpportunityLineItem__c = opportunityLineItem2.Id;
                quoteitem1.Status__c = 'Aprovado';
                quoteitem1.idportal__C = '32444';
                quoteitem1.OpportunityId__c = opportunity2.Id;
                quoteitem1.Product__c = product.Id;
                insert new List<QuoteItem__c> {quoteitem, quoteitem1};
        
                Integracoes__c integration =  new Integracoes__c(
                    Name        = 'InformaticaAtualizarCotacao',
                    Method__c   = 'POST',
                    Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/',
                    User__c     = 'test123@grupoelfa.com.br',
                    Password__c = 'test123'
                );
                insert integration;
            }
            
        }

        global class MockHttpResponseGenerator implements HttpCalloutMock {
            private Boolean isSuccess;

            public MockHttpResponseGenerator(Boolean isSuccess){
                this.isSuccess = isSuccess;
            }
            // Implement this interface method
            global HTTPResponse respond(HTTPRequest req) {
                // Create a fake response
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('');
                res.setStatusCode(this.isSuccess? 201 : 500);

                if (res.getStatusCode() == 201){
                    res.setBody('{"result": "Pedido incluido na fila de processamento!!","incluido": true}');
                } else {
                    res.setBody('{"result": "Pedido não incluido na fila de processamento!!","incluido": false}');
                }
                return res;
            }
        }

        @isTest
        public static void test_one_sendQuoteToPortal(){

            Opportunity opp = OpportunitySelector.getInstance().getOpportunityByIdForIntegrationPortalQuoteOUT([SELECT Id FROM Opportunity WHERE IdPortal__c = '32443'].Id);

            Test.startTest();

                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
                IntegrationPortalQuoteOUT.send(opp.id);
                // IntegrationPortalQuoteOUT.send(listOpportunity[1].id);
        
            Test.stopTest();
        }

        @isTest
        public static void test_two_sendQuoteToPortalQueueable(){        
            Opportunity opp = OpportunitySelector.getInstance().getOpportunityByIdForIntegrationPortalQuoteOUT([SELECT Id FROM Opportunity WHERE IdPortal__c = '32444'].Id);
            List<QuoteItem__c> quoteItems = (List<QuoteItem__c>) IntegrationPortalQuoteOUT.getQuoteItemsQuery(opp).setLimit(1000).toList();
            Test.startTest();

                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
                System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(0, new List<Id>{opp.id}));
                new IntegrationPortalQuoteOUT.OpportunityRequest(opp, new List<Setorizacao__c>(), quoteItems, true);
        
            Test.stopTest();
        }

        @isTest
        public static void test_OpportunityItemRequest(){        
            Opportunity opp = OpportunitySelector.getInstance().getOpportunityByIdForIntegrationPortalQuoteOUT([SELECT Id FROM Opportunity WHERE IdPortal__c = '32444'].Id);
            List<QuoteItem__c> quoteItems = [
                SELECT 
                    Id,
                    FatorConversao__c,
                    TipoConversao__c,
                    Categoria__c,
                    Vendedor__r.CodigoUsuario__c,
                    VendedorRespondeu__r.CodigoUsuario__c,
                    Vendedor__r.Name,
                    VendedorRespondeu__r.Name,
                    IdPortal__c,
                    IdIntegrator__c,
                    IdCustomer__c,
                    TabulacaoN1__c,  
                    Product__r.Name,
                    OpportunityLineItem__r.CNPJCD__c,
                    OpportunityLineItem__r.ValorPortal__c,
                    OpportunityLineItem__r.ForaMalha__c,
                    OpportunityLineItem__r.ListPrice,
                    OpportunityLineItem__r.CodigoRastreio__c,
                    OpportunityLineItem__r.Comentarios__c,
                    OpportunityLineItem__r.Product2.ExternalId__c,
                    OpportunityLineItem__r.Product2.Fornecedor__c,
                    OpportunityLineItem__r.Product2.Fornecedor__r.Name,
                    OpportunityLineItem__r.Product2.Fabricante__c,
                    OpportunityLineItem__r.Product2.UnidadeMedida__c,
                    OpportunityLineItem__r.Product2.Name
                FROM QuoteItem__c WHERE OpportunityId__c =: opp.Id];
            Test.startTest();

                IntegrationPortalQuoteOUT.OpportunityRequest oppReq = new IntegrationPortalQuoteOUT.OpportunityRequest(opp, new List<Setorizacao__c>(), quoteItems, true);
                IntegrationPortalQuoteOUT.OpportunityItemRequest oppItemReq = new IntegrationPortalQuoteOUT.OpportunityItemRequest(quoteItems[0], quoteItems, opp, new List<Setorizacao__c>());
        
            Test.stopTest();
        }
    }