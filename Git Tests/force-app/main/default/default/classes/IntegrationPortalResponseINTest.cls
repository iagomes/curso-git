@isTest 
private class IntegrationPortalResponseINTest {

	/*@isTest
	private static void saveResponseTest() {
		IntegrationPortalResponseIN.RequestData dataRequest = new IntegrationPortalResponseIN.RequestData();

		dataRequest.success				= true;
		dataRequest.messages			= null;
		dataRequest.idPortalOrcamento	= '625da2cbd2568958f9038025';

		dataRequest.items = new List<IntegrationPortalResponseIN.ItemResult>();
		
		IntegrationPortalResponseIN.ItemResult ItemResultObj = new IntegrationPortalResponseIN.ItemResult();
		
		ItemResultObj.idSalesforce		= '625da2cbd2568958f903802d';
		ItemResultObj.messages			= 'error mensagem A;error mensagem b; abafgviauefhgeaiufeugiuagfiuaef';
		ItemResultObj.success			= true;

		dataRequest.items.add(ItemResultObj);
		
		IntegrationPortalResponseIN.saveResponse();
	}*/
	
	@isTest
        public static void saveResponseTest(){                
            
			Product2 product = TestUtility.createProduct();
            product.ExternalId__c = 'PQITEST1074';
            //product.ProductCodeElfa__c = 'PQITEST1074';
            insert product;

			Opportunity opportunity = TestUtility.createOpportunity(new User(Id=UserInfo.getUserId()));
            opportunity.CloseDate = Date.today().addDays(-1);
            opportunity.StageName = 'Em digitação';
            opportunity.IdPortal__c = 'IDPORTAL';
			opportunity.ExternalPortal__c = '625da2cbd2568958f9038025';
			opportunity.MensagemErroIntegracaoPortalCotacoes__c = 'Teste';			
            PricebookEntry pricebookEntry   = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id][0];
            pricebookEntry.IsActive         = true;
            update pricebookEntry;
            OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opportunity.Id, product.Id, pricebookEntry.Id);
            insert opportunity;

            QuoteItem__c quoteitem = TestUtility.createQuoteItem(opportunity);
            quoteitem.OpportunityLineItem__c = oppLineItem.Id;
            quoteitem.OpportunityId__c = opportunity.Id;
            quoteitem.Product__c = product.Id;
            quoteitem.idportal__C = 'IDPORTAL';
            quoteitem.Status__c = 'Aguardando Integração';
            insert quoteitem;

			OpportunityTeamMember teamMember = TestUtility.createOpportunityTeamMember(opportunity);
            //OpportunityTeamMember teamMember2 = TestUtility.createOpportunityTeamMember(opportunity2);
            insert teamMember;									

			List<Opportunity> listOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 2];
			
			Test.startTest();
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                RestContext.response = res;
                req.requestUri = 'https://test.salesforce.com/services/apexrest/integrationResponse/v1';
                req.httpMethod = 'POST';
                																
				req.requestBody = Blob.valueOf(
                    '{'+
					'	"success": true,'+
					'	"messages": "test",'+
					'	"idPortalOrcamento": "625da2cbd2568958f9038025",'+
					'	"items": ['+
					'		{'+
					'			"success": true,'+
					'			"idSalesforce": "' + quoteitem.Id + '",'+
					'			"messages": "error mensagem A;error mensagem b; abafgviauefhgeaiufeugiuagfiuaef"'+
					'		}'+
					'	]'+
					'}'
                );
                RestContext.request = req;
                
                IntegrationPortalResponseIN.saveResponse();                        
            Test.stopTest();
        }
		
		@isTest
        public static void saveResponseTestError(){                
            
			Product2 product = TestUtility.createProduct();
            product.ExternalId__c = 'PQITEST1074';
            //product.ProductCodeElfa__c = 'PQITEST1074';
            insert product;

			Opportunity opportunity = TestUtility.createOpportunity(new User(Id=UserInfo.getUserId()));
            opportunity.CloseDate = Date.today().addDays(-1);
            opportunity.StageName = 'Em digitação';
            opportunity.IdPortal__c = 'IDPORTAL';
			opportunity.ExternalPortal__c = '625da2cbd2568958f9038025';
            PricebookEntry pricebookEntry   = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product.Id][0];
            pricebookEntry.IsActive         = true;
            update pricebookEntry;
            OpportunityLineItem oppLineItem = TestUtility.createOpportunityLineItem(opportunity.Id, product.Id, pricebookEntry.Id);
            insert opportunity;

			OpportunityTeamMember teamMember = TestUtility.createOpportunityTeamMember(opportunity);
            insert teamMember;

            QuoteItem__c quoteitem = TestUtility.createQuoteItem(opportunity);
            quoteitem.OpportunityLineItem__c = oppLineItem.Id;
            quoteitem.OpportunityId__c = opportunity.Id;
            quoteitem.Product__c = product.Id;
            quoteitem.idportal__C = 'IDPORTAL';
            quoteitem.Status__c = 'Aguardando Integração';
            insert quoteitem;
			
			List<Opportunity> listOpportunity = [SELECT Id, Name FROM Opportunity LIMIT 2];
			
			Test.startTest();
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                RestContext.response = res;
                req.requestUri = 'https://test.salesforce.com/services/apexrest/integrationResponse/v1';
                req.httpMethod = 'POST';
                																
				req.requestBody = Blob.valueOf(
                    '{'+
					'	"success": false,'+
					'	"messages": "error mensagem A;error mensagem b; abafgviauefhgeaiufeugiuagfiuaef",'+
					'	"idPortalOrcamento": "625da2cbd2568958f9038025",'+
					'	"items": ['+
					'		{'+
					'			"success": false,'+
					'			"idSalesforce": "' + quoteitem.Id + '",'+
					'			"messages": "error mensagem A;error mensagem b; abafgviauefhgeaiufeugiuagfiuaef"'+
					'		}'+
					'	]'+
					'}'
                );
                RestContext.request = req;
                
                IntegrationPortalResponseIN.saveResponse();                        
            Test.stopTest();
        }	
}