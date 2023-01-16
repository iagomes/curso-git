@IsTest
global with sharing class IntegrationPortalVinculoOUTTest {

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
            opportunity.ExternalPortal__c = 'IntegrationPortalVinculoOUT13052022';
            opportunity.Integradora__c = '45612387643713';
            opportunity.IdPortal__c = '32443';
            opportunity.IdIntegrator__c = '45612387643713';
            opportunity.CDsBloqueado__c = '52202744000788;';
            opportunity.CNPJCD__c = '62938773000170';

            Opportunity opportunity2                = TestUtility.createOpportunity(selfUser);
            opportunity2.PrazoEntrega__c            = 14;
            opportunity2.PrazoValidade__c            = 14;
            opportunity2.AccountId = acc.Id;
            opportunity2.ExternalPortal__c = '456123876437131';
            opportunity2.Integradora__c = '456123876437131';
            opportunity2.IdPortal__c = '32444';
            opportunity2.IdIntegrator__c = '456123876437131';
            opportunity2.CNPJCD__c = '62938773000170';


            
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
            insert set1;

            OpportunityTeamMember teamMember = TestUtility.createOpportunityTeamMember(opportunity);
            OpportunityTeamMember teamMember2 = TestUtility.createOpportunityTeamMember(opportunity2);
            insert new List<OpportunityTeamMember>{teamMember, teamMember2};

            

            PricebookEntry pricebookEntry          = [SELECT Id, UnitPrice FROM PricebookEntry][0];
            pricebookEntry.UnitPrice               = 1.00;
            pricebookEntry.IsActive                = true;
            update pricebookEntry;
    
            OpportunityLineItem opportunityLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pricebookEntry);
            opportunityLineItem.CNPJCD__c = '52202744000788';
            

            OpportunityLineItem opportunityLineItem2 = TestUtility.createOpportunityLineItem(opportunity2, product, pricebookEntry);
            opportunityLineItem2.CNPJCD__c = '52202744000788';
            insert new List<OpportunityLineItem>{opportunityLineItem, OpportunityLineItem2};

            QuoteItem__c quoteitem = TestUtility.createQuoteItem(opportunity, selfUser);
            quoteitem.Status__c = 'Aguardando Integração';
            quoteitem.OpportunityLineItem__c = opportunityLineItem.Id;
            quoteitem.Product__c = product.Id;
            quoteitem.idportal__C = '32443';
            QuoteItem__c quoteitem1 = TestUtility.createQuoteItem(opportunity2, selfUser);
            quoteitem1.Status__c = 'Aprovado';
            quoteitem1.Product__c = product.Id;
            quoteitem1.idportal__C = '32444';
            insert new List<QuoteItem__c> {quoteitem, quoteitem1};
    
            Integracoes__c integration =  new Integracoes__c(
                Name        = 'InformaticaAtualizarVinculo',
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

        global MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CgcCli": "","CgcEmp": "","TpInteg": "","laboratorio": "","regra": "","PedidoIntegrador": "","CondicaoPagamento": "","TabelaPreco": "","TipoFrete": "CIF","observacoes": "","ObservacoesNF": "","itens": [{"produto": "","TpOper": "","ShelfLife": "AAAAMMDD","preco": 1,"lote": "","quantidade": 0.00}]}');
            res.setStatusCode(this.isSuccess? 200 : 500);

            if (res.getStatusCode() == 200){
                res.setBody('{"result": "Pedido incluido na fila de processamento!!","incluido": true}');
            } else {
                res.setBody('{"result": "Pedido não incluido na fila de processamento!!","incluido": false}');
            }
            return res;
        }
    }

    @isTest
    global static void test_one_send(){
        Map<Id,QuoteItem__c> mapItems = new Map<Id,QuoteItem__c>([SELECT Id FROM QuoteItem__c LIMIT 2]);

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
            StandardResponse response = IntegrationPortalVinculoOUT.send(mapItems.keySet());
            IntegrationPortalVinculoOUT.sendAsync(mapItems.keySet());

            System.assertEquals(response.code, '200');
    
        Test.stopTest();
    }

    @isTest
    global static void test_error(){
        Map<Id,QuoteItem__c> mapItems = new Map<Id,QuoteItem__c>([SELECT Id FROM QuoteItem__c LIMIT 2]);

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
            StandardResponse response = IntegrationPortalVinculoOUT.send(mapItems.keySet());
            // IntegrationPortalVinculoOUT.send(listOpportunity[1].id);
            System.assertEquals(response.code, '500');
    
        Test.stopTest();
    }
}