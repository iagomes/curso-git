@isTest
global class IntegrationPortalQuoteINTest {

        @TestSetup
        static void createData(){
            User user1 = TestUtility.createUser(); 
            User user2 = TestUtility.createUserTwo(); 
            System.runAs(new User(Id = UserInfo.getUserId())){
                
                user1.CodigoUsuario__c = '001059';
                user2.CodigoUsuario__c = '2266';
                try {
                    insert new List<User>{user1, user2};
                } catch (Exception e) {}
            }

            Account acc = TestUtility.createAccount();
            acc.CNPJ__c = '47782743000124';
            Account acc1 = TestUtility.createAccount();
            acc1.CNPJ__c = '92685833000151';
            insert new List<Account>{acc, acc1};
            Setorizacao__c set1 = TestUtility.createSetorizacaoWithValidData(acc, user1);
            // Setorizacao__c set2 = TestUtility.createSetorizacaoWithValidData(acc1, user2);
            insert new List<Setorizacao__c>{set1};//, set2
            Product2 product = TestUtility.createProduct();
            product.ExternalId__c = 'PQITEST1074';
            //product.ProductCodeElfa__c = 'PQITEST1074';
            insert product;
            CondicaoPagamento__c condPag = TestUtility.createPaymentCondition2();
            insert condPag;
            CondicaoPagamentoPorCD__c condpagCD = TestUtility.createCondicaoPagamentoPorCD(condPag.Id);
            //condpagCD.ExternalId__c ='622f8823d2568958f9dc85aa';
            condpagCD.CNPJCD__c = '09053134000900';
            CondicaoPagamentoPorCD__c condpagCD2 = TestUtility.createCondicaoPagamentoPorCD(condPag.Id);
            //condpagCD.ExternalId__c = '622f8823d2568958f9dc85ab';
            condpagCD.CNPJCD__c = '25211499000107';
            insert new List<CondicaoPagamentoPorCD__c>{condpagCD, condpagCD2};

            Opportunity opportunity = TestUtility.createOpportunity(new User(Id=UserInfo.getUserId()));
            opportunity.CloseDate = Date.today().addDays(-1);
            opportunity.StageName = 'Em digitação';
            opportunity.IdPortal__c = 'IDPORTAL';
            PricebookEntry pricebookEntry   = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id][0];
            pricebookEntry.IsActive         = true;
            update pricebookEntry;
            OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opportunity.Id, product.Id, pricebookEntry.Id);
            insert opportunity;

            
            PricebookEntry pbEntry = [SELECT ID, IsActive FROM PricebookEntry WHERE Product2Id =: product.Id LIMIT 1];
            pbEntry.IsActive = true;
            update pbEntry;
    
            Integracoes__c integration =  new Integracoes__c(
                Name        = 'InformaticaAtualizarCotacao',
                Method__c   = 'POST',
                Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/',
                User__c     = 'cloud.dev@grupoelfa.com.br',
                Password__c = 'Elf@Cloud'
            );
            insert integration;
        }    
    
        global class MockHttpResponseGenerator implements HttpCalloutMock {
            private Boolean isSuccess;
    
            public MockHttpResponseGenerator(Boolean isSuccess){
                this.isSuccess = isSuccess;
            }

            global HTTPResponse respond(HTTPRequest req) {
                
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody(
                    '{' +
                    '    "messages": ["Ocorreu um erro interno."],' +
                    '    "hasError": true,' +
                    '    "code": "500"' +
                    '}'
                );
                res.setStatusCode(this.isSuccess? 201 : 500);
    
                if (res.getStatusCode() == 201){
                    res.setBody(
                        '{' +
                        '    "messages": [],' +
                        '    "hasError": true,' +
                        '    "data": {' +
                        '        "quoteId": "0062100000EhD8oAAF",' +
                        '        "result": [' +
                        '            {' +
                        '                "success": true,' +
                        '                "status": "status",' +
                        '                "sObjectType": "OpportunityLineItem",' +
                        '                "sfProductId": "01t21000006Jw3ZAAS",' +
                        '                "sfPbEntryId": "01u21000008psJWAAY",' +
                        '                "sfItemId": "00k21000009JanRAAS",' +
                        '                "record": null,' +
                        '                "idPortal": "idPortal3",' +
                        '                "idIntegrator": "id do artigo3",' +
                        '                "idERP": "0000005",' +
                        '                "idCustomer": "codigo_produto3",' +
                        '                "errors": [],' +
                        '                "created": false' +
                        '            },' +
                        '            {' +
                        '                "success": true,' +
                        '                "status": "status",' +
                        '                "sObjectType": "QuoteItem__c",' +
                        '                "sfProductId": "01t21000006eNq8AAE",' +
                        '                "sfPbEntryId": null,' +
                        '                "sfItemId": "a0d210000177jRQAAY",' +
                        '                "record": null,' +
                        '                "idPortal": "idPortal1",' +
                        '                "idIntegrator": "id do artigo1",' +
                        '                "idERP": "0009618",' +
                        '                "idCustomer": "codigo_produto1",' +
                        '                "errors": [],' +
                        '                "created": false' +
                        '            },' +
                        '            {' +
                        '                "success": true,' +
                        '                "status": "status",' +
                        '                "sObjectType": "QuoteItem__c",' +
                        '                "sfProductId": null,' +
                        '                "sfPbEntryId": null,' +
                        '                "sfItemId": "a0d210000177jRRAAY",' +
                        '                "record": null,' +
                        '                "idPortal": "idPortal2",' +
                        '                "idIntegrator": "id do artigo2",' +
                        '                "idERP": "idERP12",' +
                        '                "idCustomer": "codigo_produto2",' +
                        '                "errors": [],' +
                        '                "created": false' +
                        '            },' +
                        '            {' +
                        '                "success": false,' +
                        '                "status": "status",' +
                        '                "sObjectType": "QuoteItem__c",' +
                        '                "sfProductId": null,' +
                        '                "sfPbEntryId": null,' +
                        '                "sfItemId": null,' +
                        '                "record": null,' +
                        '                "idPortal": "idPortal4",' +
                        '                "idIntegrator": "id do artigo4",' +
                        '                "idERP": "idERP12aefeafeafeafeafeafefaaefeafeafeafeaffaefeafeafeaffeaf",' +
                        '                "idCustomer": "codigo_produto4",' +
                        '                "errors": [' +
                        '                    {' +
                        '                        "statusCode": "STRING_TOO_LONG",' +
                        '                        "message": "Id do ERP: valor de dados grande demais: idERP12aefeafeafeafeafeafefaaefeafeafeafeaffaefeafeafeaffeaf (max length=32)",' +
                        '                        "fields": [' +
                        '                            "IdERP__c"' +
                        '                        ]' +
                        '                    }' +
                        '                ],' +
                        '                "created": true' +
                        '            }' +
                        '        ]' +
                        '    },' +
                        '    "code": "200"' +
                        '}'
                    );
                } else {
                    res.setBody(
                        '{' +
                        '    "messages": ["Ocorreu um erro interno."],' +
                        '    "hasError": true,' +
                        '    "code": "500"' +
                        '}'
                    );
                }
                return res;
            }
        }
    
        @isTest
        public static void test_one_upsertQuote_error(){
            List<Opportunity> listOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 2];
    
            Test.startTest();
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                RestContext.response = res;
                req.requestUri = 'https://test.salesforce.com/services/apexrest/upsertPortalQuote/v1/';
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueOf(
                    '{'+
                    '    "idPortal": "TEST Class 2022-03-14 001",'+
                    '    "idIntegrator": "TEST Class 2022-03-14 001",'+
                    '    "name": "Pedido de Cotação",'+
                    '    "condicaoPagamento": {'+
                    '        "name": "a vista",'+
                    '        "id": "043"'+
                    '    },'+
                    '    "closeDate": "2022-03-19T19:15:00.000Z",'+
                    '    "customerObservations": "teste",'+
                    '    "vendedor": "001059",'+
                    '    "vendedorSuporte": "2266",'+
                    '    "mesa": "sul",'+
                    '    "quoteType": "Pedido de Cotação",'+
                    '    "frete": "",'+
                    '    "minimumBilling": 0,'+
                    '    "method":"insert",'+
                    '    "category": "",'+
                    '    "contact": "Teste unico",'+
                    '    "status": "Respondida",'+
                    '    "integrator": "bionexo",'+
                    '    "termosCondicoes": "teste",'+
                    '    "enderecoEntrega": "R RAMIRO BARCELOS 910,PORTO ALEGRE,RS",'+
                    '    "consolidador": [],'+
                    '    "customer": {'+
                    '        "idPortal": "622b6b67d2568958f9d83ca6",'+
                    '        "cnpj": "234234",'+
                    '        "name": "Associação Hospitalar Moinhos de Vento",'+
                    '        "phone": "",'+
                    '        "cidade": "PORTO ALEGRE",'+
                    '        "estado": "",'+
                    '        "terms": "",'+
                    '        "observations": ""'+
                    '    },'+
                    '    "extraFields": [],'+
                    '    "cds": [{'+
                    '            "id": "622f8823d2568958f9dc85aa",'+
                    '            "cnpj": "09053134000900"'+
                    '        },'+
                    '        {'+
                    '            "id": "622f8823d2568958f9dc85ab",'+
                    '            "cnpj": "25211499000107"'+
                    '        }'+
                    '    ],'+
                    '    "products": [{'+
                    '        "idCustomer": "PQITEST1074",'+
                    '        "idIntegrator": "135198458",'+
                    '        "idPortal": "622f8823d2568958f9dc85b0",'+
                    '        "quantity": 150,'+
                    '        "sequence": 1,'+
                    '        "customerDescription": "AAS AD 500MG CP - COMPRIMIDO",'+
                    '        "customerMeasurementUnit": "Comprimido",'+
                    '        "integratorMeasurementUnit": "29",'+
                    '        "status": "initial",'+
                    '        "cdLogin": "",'+
                    '        "programacaoEntrega": [],'+
                    '        "produtosVinculados": [{'+
                    '            "codigoProdutoERP": "PQITEST1074",'+
                    '            "idERP": "PQITEST1074",'+
                    '            "bu": "M",'+
                    '            "mesa": "sul",'+
                    '            "vendedor": "001059",'+
                    '            "createdAt": "2022-03-13T19:15:00.000Z",'+
                    '            "updateAt": "2022-03-14T19:15:00.000Z",'+
                    '            "fatorConversao": 10,'+
                    '            "tipoConversaoUnidadeMedida": "DIVIDIR"'+
                    '        }],'+
                    '        "itemConsolidador": "",'+
                    '        "favoriteBrands": "BAYER",'+
                    '        "brands": []'+
                    '    }]'+
                    '}'
                );
                RestContext.request = req;
                
                IntegrationPortalQuoteIN.upsertQuote();
                System.assertEquals(500, res.statusCode);
        
            Test.stopTest();
        }
    
        @isTest
        public static void test_one_upsertQuote_QuoteItem_success(){
            List<Opportunity> listOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 2];
    
            Test.startTest();
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                RestContext.response = res;
                req.requestUri = 'https://test.salesforce.com/services/apexrest/upsertPortalQuote/v1/';
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueOf(
                    '{'+
                    '    "idPortal": "TEST Class 2022-03-14 001",'+
                    '    "idIntegrator": "TEST Class 2022-03-14 001",'+
                    '    "name": "Pedido de Cotação",'+
                    '    "condicaoPagamento": {'+
                    '        "name": "a vista",'+
                    '        "id": "043"'+
                    '    },'+
                    '    "closeDate": "2022-03-19T19:15:00.000Z",'+
                    '    "customerObservations": "teste",'+
                    '    "vendedor": "001059",'+
                    '    "vendedorSuporte": "2266",'+
                    '    "mesa": "sul",'+
                    '    "quoteType": "Pedido de Cotação",'+
                    '    "frete": "",'+
                    '    "minimumBilling": 0,'+
                    '    "method":"insert",'+
                    '    "category": "",'+
                    '    "contact": "Teste unico",'+
                    '    "status": "Respondida",'+
                    '    "integrator": "bionexo",'+
                    '    "termosCondicoes": "teste",'+
                    '    "enderecoEntrega": "R RAMIRO BARCELOS 910,PORTO ALEGRE,RS",'+
                    '    "consolidador": [],'+
                    '    "customer": {'+
                    '        "idPortal": "622b6b67d2568958f9d83ca6",'+
                    '        "cnpj": "47782743000124",'+
                    '        "name": "Associação Hospitalar Moinhos de Vento",'+
                    '        "phone": "",'+
                    '        "cidade": "PORTO ALEGRE",'+
                    '        "estado": "",'+
                    '        "terms": "",'+
                    '        "observations": ""'+
                    '    },'+
                    '    "extraFields": [],'+
                    '    "cds": [{'+
                    '            "id": "622f8823d2568958f9dc85aa",'+
                    '            "cnpj": "09053134000900"'+
                    '        },'+
                    '        {'+
                    '            "id": "622f8823d2568958f9dc85ab",'+
                    '            "cnpj": "25211499000107"'+
                    '        }'+
                    '    ],'+
                    '    "products": [{'+
                    '        "idCustomer": "PQITEST1074",'+
                    '        "idIntegrator": "135198458",'+
                    '        "idPortal": "622f8823d2568958f9dc85b0",'+
                    '        "quantity": 150,'+
                    '        "sequence": 1,'+
                    '        "customerDescription": "AAS AD 500MG CP - COMPRIMIDO",'+
                    '        "customerMeasurementUnit": "Comprimido",'+
                    '        "integratorMeasurementUnit": "29",'+
                    '        "status": "initial",'+
                    '        "cdLogin": "",'+
                    '        "programacaoEntrega": [],'+
                    '        "produtosVinculados": [{'+
                    '            "codigoProdutoERP": "PQITEST1074",'+
                    '            "idERP": "PQITEST1074",'+
                    '            "bu": "M",'+
                    '            "mesa": "sul",'+
                    '            "vendedor": "001059",'+
                    '            "createdAt": "2022-03-13T19:15:00.000Z",'+
                    '            "updateAt": "2022-03-14T19:15:00.000Z",'+
                    '            "fatorConversao": 10,'+
                    '            "tipoConversaoUnidadeMedida": "DIVIDIR"'+
                    '        }],'+
                    '        "itemConsolidador": "",'+
                    '        "favoriteBrands": "BAYER",'+
                    '        "brands": []'+
                    '    }]'+
                    '}'
                );
                RestContext.request = req;
                
                IntegrationPortalQuoteIN.upsertQuote();
                //System.assertEquals(201, res.statusCode);
        
            Test.stopTest();
        }
    
        @isTest
        public static void test_one_upsertQuote_OpportunityLineItem_success(){
            List<Opportunity> listOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 2];
    
            Test.startTest();
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                RestContext.response = res;
                req.requestUri = 'https://test.salesforce.com/services/apexrest/upsertPortalQuote/v1/';
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueOf(
                    '{'+
                        '"idPortal": "TEST Class 2022-03-14 001",'+
                        '"idIntegrator": "TEST Class 2022-03-14 001",'+
                        '"name": "Pedido de Cotação - Raniere - Teste 105",' +
                        '"condicaoPagamento": {' +
                            '"name": "a vista",' +
                            '"id": "043"' +
                        '},' +
                        '"closeDate": "2022-04-04T17:59:00.000Z",' +
                        '"customerObservations": "Cotação Teste - Raniere - 105",' +
                        '"vendedor": "001059",' +
                        '"vendedorSuporte": "2266",' +
                        '"mesa": "sul",' +
                        '"quoteType": "Pedido de Cotação - Raniere - Teste 105",' +
                        '"frete": "",' +
                        '"minimumBilling": 0,' +
                        '"category": "",' +
                        '"contact": "Web Services",' +
                        '"status": "Aguardando Retorno",' +
                        '"integrator": "bionexo",' +
                        '"termosCondicoes": "",' +
                        '"enderecoEntrega": "",' +
                        '"consolidador": [],' +
                        '"customer": {' +
                            '"idPortal": "622b6b67d2568958f9d83ca6",' +
                            '"cnpj": "92685833000151",' +
                            '"name": "Associação Hospitalar Moinhos de Vento",' +
                            '"phone": " ",' +
                            '"cidade": "PORTO ALEGRE",' +
                            '"estado": "RS",' +
                            '"terms": "",' +
                            '"observations": ""' +
                        '},    ' +
                        '"extraFields": [],' +
                        '"cds": [        ' +
                                '{' +
                                    '"id": "624b53fed2568958f9f4c3ae",' +
                                    '"cnpj": "25211499000298"' +
                                '},{' +
                                    '"id": "624b53fed2568958f9f4c3af",' +
                                    '"cnpj": "25211499000107"' +
                                '},{' +
                                    '"id": "624b53fed2568958f9f4c3b0",' +
                                    '"cnpj": "25211499000379"' +
                                '},{' +
                                    '"id": "624b53fed2568958f9f4c3b1",' +
                                    '"cnpj": "09053134000900"' +
                                '}        ' +
                        '],' +
                        '"products": [' +
                            '{' +
                                '"idCustomer": "252",' +
                                '"idIntegrator": "1352108402",' +
                                '"idPortal": "624b53fed2568958f9f4c3d02",' +
                                '"quantity": 400,' +
                                '"sequence": 16,' +
                                '"customerDescription": "ACICLOVIR 250MG 10ML INJ",' +
                                '"customerMeasurementUnit": "Frasco/Ampola",' +
                                '"integratorMeasurementUnit": "49",' +
                                '"status": "initial",' +
                                '"cdLogin": "",' +
                                '"programacaoEntrega": [],' +
                                '"produtosVinculados": [],' +
                                '"itemConsolidador": "",' +
                                '"favoriteBrands": "-",' +
                                '"brands": []' +
                            '}' +
                        ']' +
                    '}'
                );
                RestContext.request = req;
                
                IntegrationPortalQuoteIN.upsertQuote();
                System.debug('res.statusCode:::' + res.statusCode);
                // System.assertEquals(200, res.statusCode);
        
            Test.stopTest();
        }
    }