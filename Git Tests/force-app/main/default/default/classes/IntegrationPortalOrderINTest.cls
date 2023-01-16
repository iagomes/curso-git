@isTest
global class IntegrationPortalOrderINTest {

    @TestSetup
    static void createData(){

        User user1 = new User(Id = UserInfo.getUserid());
        user1.codigoUsuario__c = 'POI_TEST_user1';
        try{
            update user1;
        }catch(Exception ex){}
        
        System.runAs(user1){

            CondicaoPagamento__c conditionMakeData = TestUtility.createConditionPayment();
            insert conditionMakeData;
    
            Account acc = TestUtility.createAccount();
            acc.CNPJ__c = '00012698000246';
            acc.CondicaoPagamento__c = conditionMakeData.id;
            insert acc;
            Product2 product = TestUtility.createProduct();
            product.ProductCode ='0001920';
            product.ExternalId__c = 'POI_TEST_180507232';
            product.CategoriaComercial__c = 'M';
            insert product;
            CondicaoPagamento__c condPag = TestUtility.createConditionPayment();
            condPag.ExternalId__c = '003';
            insert condPag;

            Opportunity opportunity = TestUtility.createOpportunity(new User(Id=UserInfo.getUserId()));
            opportunity.AccountId = acc.id;
            opportunity.CloseDate = Date.today().addDays(-1);
            opportunity.StageName = 'Em digitação';
            opportunity.IdPortal__c = 'POI_TEST_180507232';
            opportunity.ExternalPortal__c = 'POI_TEST_180507232';
            opportunity.IdIntegrator__c = '001';
            opportunity.CondicaoPagamento__c = condPag.Id;
            insert opportunity;
    
            OpportunityTeamMember members = new OpportunityTeamMember(
                                        TeamMemberRole = 'Sales Rep',
                                        UserId = user1.id, 
                                        OpportunityId = opportunity.Id,
                                        OpportunityAccessLevel = 'EDIT'
                                    );
            insert members;
          
            
            PricebookEntry pbEntry = [SELECT ID, IsActive FROM PricebookEntry WHERE Product2Id =: product.Id LIMIT 1];
            pbEntry.IsActive = true;
            update pbEntry;
    
            OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opportunity, product, pbEntry);
            oppLineItem.Vendedor__r = new User(CodigoUsuario__c = 'POI_TEST_user1');
            insert oppLineItem;    
    
            Integracoes__c integration =  new Integracoes__c(
                Name        = 'InformaticaGetMalhaPortal',
                Method__c   = 'POST',
                Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-SFDC-Malha-Fiscal',
                User__c     = 'cloud.dev@grupoelfa.com.br',
                Password__c = 'Elf@Cloud'
            );
            insert integration;
    
            QuoteItem__c quoteItem1 = TestUtility.createQuoteItem(opportunity.IdIntegrator__c, user1.CodigoUsuario__c);
            quoteItem1.IdPortal__c = '001quoteItem';
            quoteItem1.IdCustomer__c = '001quoteItem';
            quoteItem1.IdERP__c = '001quoteItem';
            quoteItem1.ExternalId__c = '001quoteItem';
            quoteItem1.CNPJCD__c = '79231541000180';
            quoteItem1.ProgramacaoEntrega__c = '[{"quantidade":"8000","data":"16/02/2022"},{"quantidade":"9000","data":"03/03/2022"}]';
            quoteItem1.Quantity__c = 1;
            quoteItem1.UnitPrice__c = 1;
            quoteItem1.OpportunityLineItem__c = oppLineItem.Id;
    
            insert quoteItem1;
        }
    }

    @isTest
    public static void test_one_upsertOrder_OrderItem_success(){    
        
        Opportunity opp = [
            SELECT Id, CanalEntrada__c, IdIntegrator__c, ExternalPortal__c, Account.CNPJ__c, CondicaoPagamento__r.ExternalId__c,
            (SELECT Id, IdPortal__c, CNPJCD__c, OpportunityLineItem__r.Quantity  FROM QuoteItems__r) 
            FROM Opportunity LIMIT 1
        ];
    
        Test.startTest();

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = 'https://test.salesforce.com/services/apexrest/upsertPortalOrder/v1/';
            req.httpMethod = 'POST';

            String itensJSON = buildItemObject(
                opp.QuoteItems__r[0].IdPortal__c,
                opp.QuoteItems__r[0].CNPJCD__c, 
                opp.QuoteItems__r[0].Id, 
                opp.QuoteItems__r[0].OpportunityLineItem__r.Quantity
            );

            String orderDataJSON = buildOrderObject(
                opp.CanalEntrada__c, 
                opp.IdIntegrator__c, 
                opp.ExternalPortal__c, 
                opp.Account.CNPJ__c, 
                opp.CondicaoPagamento__r.ExternalId__c, 
                itensJSON
            );

            req.requestBody = Blob.valueOf(orderDataJSON);
               
            RestContext.request = req;
            RestContext.response = res;
        
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Malha'));
            IntegrationPortalOrderIN.getOpportunity('POI_TEST_180507232');
            IntegrationPortalOrderIN intPortalOrder = new IntegrationPortalOrderIN();
            IntegrationPortalOrderIN.upsertOrder();

        Test.stopTest();
    }

    @isTest
    public static void test_two_upsertOrder_OrderItem_failItem(){    
        
        Opportunity opp = [
            SELECT Id, CanalEntrada__c, IdIntegrator__c, ExternalPortal__c, Account.CNPJ__c, CondicaoPagamento__r.ExternalId__c,
            (SELECT Id, IdPortal__c, CNPJCD__c, OpportunityLineItem__r.Quantity  FROM QuoteItems__r) 
            FROM Opportunity LIMIT 1
        ];
    
        Test.startTest();

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestUri = 'https://test.salesforce.com/services/apexrest/upsertPortalOrder/v1/';
            req.httpMethod = 'POST';

            String itensJSON = '{'+
            '    "idPortal": "'+opp.QuoteItems__r[0].IdPortal__c+'",'+
            '    "cnpjCd": "'+opp.QuoteItems__r[0].CNPJCD__c+'",'+
            '    "idItemConfirmado": "",'+
            '    "idSalesforce": "'+opp.QuoteItems__r[0].Id+'",'+
            '    "quantidade": "'+opp.QuoteItems__r[0].OpportunityLineItem__r.Quantity+'",'+
            '    "campoExtra": [';
            for(Integer i = 0; i<300; i++){
                itensJSON += 
                '        {'+
                '            "nome": "Valor_Unitario",'+
                '            "valor": "0.9602"'+
                '        },';
            }
            itensJSON += 
            '        {'+
            '            "nome": "Id_Unidade_Medida",'+
            '            "valor": "29"'+
            '        }'+
            '    ],'+
            '    "programacaoEntrega": ['+
            '        {'+
            '            "data": "12/08/2022",'+
            '            "quantidade": "160"'+
            '        }'+
            '    ]'+
            '}';

            String orderDataJSON = buildOrderObject(
                opp.CanalEntrada__c, 
                opp.IdIntegrator__c, 
                opp.ExternalPortal__c, 
                opp.Account.CNPJ__c, 
                opp.CondicaoPagamento__r.ExternalId__c, 
                itensJSON
            );

            req.requestBody = Blob.valueOf(orderDataJSON);
               
            RestContext.request = req;
            RestContext.response = res;
        
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Malha'));
            IntegrationPortalOrderIN.getOpportunity('POI_TEST_180507232');
            IntegrationPortalOrderIN intPortalOrder = new IntegrationPortalOrderIN();
            IntegrationPortalOrderIN.upsertOrder();

        Test.stopTest();
    }

    public static String buildItemObject(List<String> idPortal, List<String> cnpjCd, List<String> idSalesforce, List<Decimal> quantity, Integer size){
        String result = '';
        for(Integer i=0; i< size;i++){
            result += 
            '{'+
            '    "idPortal": "'+idPortal[i]+'",'+
            '    "cnpjCd": "'+cnpjCd[i]+'",'+
            '    "idItemConfirmado": "",'+
            '    "idSalesforce": "'+idSalesforce[i]+'",'+
            '    "quantidade": "'+quantity[i]+'",'+
            '    "campoExtra": ['+
            '        {'+
            '            "nome": "Valor_Unitario",'+
            '            "valor": "0.9602"'+
            '        },'+
            '        {'+
            '            "nome": "Id_Unidade_Medida",'+
            '            "valor": "29"'+
            '        }'+
            '    ],'+
            '    "programacaoEntrega": ['+
            '        {'+
            '            "data": "12/08/2022",'+
            '            "quantidade": "160"'+
            '        }'+
            '    ]'+
            '}';
            if(size-1 > i) result +=',';
        }
        return result;
    }
    public static String buildItemObject(String idPortal, String cnpjCd, String idSalesforce, Decimal quantity){
        return buildItemObject(
            new List<String>{idPortal},
            new List<String>{cnpjCd},
            new List<String>{idSalesforce},
            new List<Decimal>{quantity},
            1
        );
    }

    public static String buildOrderObject(String integradora, String integradoraId, String idPortal, String cnpj, String condicaoPagamento, String itens){
        return 
        '{'+
        '    "integradora": "'+integradora+'",'+
        '    "integradoraId": "'+integradoraId+'",'+
        '    "idPortal": "'+idPortal+'",'+
        '    "cliente": {'+
        '        "cnpj": "'+cnpj+'"'+
        '    },'+
        '    "nomeContato": "Claudio  De Andrade Avelino",'+
        '    "condicaoPagamento": {'+
        '        "id": "'+condicaoPagamento+'",'+
        '        "nome": "30 D"'+
        '    },'+
        '    "observacao": "-",'+
        '    "termosCondicoes": "---",'+
        '    "enderecoEntrega": "Lad Dos Guararapes, 263 - Cosme Velho,RIO DE JANEIRO,RJ",'+
        '    "campoExtra": [],'+
        '    "itensConfirmados": ['+itens+']'+
        '}';
    }
}