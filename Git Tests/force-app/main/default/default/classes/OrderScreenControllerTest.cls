@isTest
public with sharing class OrderScreenControllerTest {
    
    @isTest
    public static void testOrderScreenController_2() {
        try {
            OrderScreenController.updatePaymentConditionAndNotesOrderSonAndSendToAutomaticIntegration('');
        } catch(Exception e) {
            System.debug(e);
        }
    }

    @isTest
    public static void testOrderScreenController() {
        OrderScreenController.translateDayOfTheWeek('Mon');
        OrderScreenController.translateDayOfTheWeek('Tue');
        OrderScreenController.translateDayOfTheWeek('Wed');
        OrderScreenController.translateDayOfTheWeek('Thu');
        OrderScreenController.translateDayOfTheWeek('Fri');

        OrderScreenController.RecommendationContextRecordData orderRecommendationContext = new OrderScreenController.RecommendationContextRecordData();
        orderRecommendationContext.contextRecordId = '';
        orderRecommendationContext.pricebookId = '';
        orderRecommendationContext.accountId = '';
        orderRecommendationContext.condPag = '';

        OrderScreenController.AccountCGCData accountCGCData = new OrderScreenController.AccountCGCData('0014x00000YAbnOAAT', '');

        OrderScreenController.EnderecoCobranca EnderecoCobranca = new OrderScreenController.EnderecoCobranca();
        EnderecoCobranca.RuaCobranca = '';
        EnderecoCobranca.CidadeCobranca = '';
        EnderecoCobranca.EstadoCobranca = '';
        EnderecoCobranca.PaisCobranca = '';
        EnderecoCobranca.CEPCobranca = '';

        OrderScreenController.RecommendationReactionData orderRecommendationRection = new OrderScreenController.RecommendationReactionData();
        orderRecommendationRection.externalId = '';
        orderRecommendationRection.targetId = '';
        orderRecommendationRection.targetActionId = '';
        orderRecommendationRection.targetActionName = '';
        orderRecommendationRection.contextRecordId = '';
        orderRecommendationRection.reaction = '';
        orderRecommendationRection.reactionMessage = '';
        orderRecommendationRection.reactionOption = '';

        OrderScreenController.ProductData product = new OrderScreenController.ProductData();
        product.pbEntryId                 = '';
		product.id                        = '';
		product.code                      = '';
		product.nome                      = '';
		product.campDesc                  = '';
		product.principioAtivo            = '';
		product.descTecnica               = '';
		product.fabricante                = '';
		product.anvisa                    = '';
		product.categoria                 = '';
		product.categoriaCompleta         = '';
		product.categoriaDesc             = '';
		product.precoFabricaCx            = 1;
		product.precoTabelaCx             = 1;
		product.temperatura               = '';
		product.ultimaCompra              = '';
		product.possuiUltimaCompra       = true;
		product.ean                       = '';
		product.regraCampanha             = '';
		product.searchCampaignField       = '';
		product.fatorConversao            = '';
		product.valorBloqueado           = true;
		product.valorZerado              = true;
		product.verMargem                = true;
		product.showBadgeOL              = true;
		product.precoBadgeOL             = 1;
		product.campanhaId                = '';
		product.showBadgeCampanha        = true;
		product.showBadgeCampanhaCD      = true;
		product.precoCNPJCampanha        = '';
		product.dataBadgeCampanha        = '';
		product.dataBadgeCampanhaVendCNPJ = '';
		product.precoBadgeCampanhaProduto = 1;
		product.showBadgeCampanhaVendedor = true;
		product.dataBadgeCampanhaVendedor = '';
		product.showBadgeConsignado      = true;
		product.precoBadgeConsignado     = 1;
		product.showBadgeReservado       = true;
		product.precoBadgeReservado      = 1;
		product.showBadgeReservadoCNPJ   = true;
		product.dataBadgeReservadoCNPJ    = '';
		product.showBadgeAcordoComercial = true;
		product.precoBadgeAcordoComercial= 1;
		product.showBadgeshelflife       = true;
		product.precoBadgeshelflife      = 1;
		product.precoCNPJShelflife       = '';
		product.precoProdShelfLife       = '';
        product.desconto                 = '';
        product.listTagByCd               = '';
		product.estoque                  = 1;
		product.possuiEstoqueArmazem     = true;
		product.estoqueArmazem            = '';
		product.regraBloqueioArmazem      = '';
		product.campoBusca                = '';
        product.campoBuscaFabricante      = '';
        product.tipoConversao             = '';
        product.unidadePrincipal          = '';
        product.unidadeSecundaria         = '';
		product.unidadeSec               = true;
        product.SequenciaOC               = '';
        product.tipoCampanha              = '';
        product.cnpjCampanhaCd            = '';
        product.unidadeMedida             = '';
        product.unidadeMedidaSeg          = '';
        product.targetId                  = '';
        product.targetActionId            = '';
        product.targetActionName          = '';

        OrderScreenController.BudgetItemData budget = new OrderScreenController.BudgetItemData();

        budget.id                        = '';
        budget.cdId                      = '';
        budget.itemId                    = '';
        budget.pbEntryId                 = '';
        budget.prodId                    = '';
        budget.prodCode                  = '';
        budget.nome                      = '';
        budget.principioAtivo            = '';
        budget.fabricante                = '';
        budget.anvisa                    = '';
        budget.categoria                 = '';
        budget.precoFabricaCx            = '';
        budget.precoFabricaUn            = '';
        budget.precoTabelaCx             = '';
        budget.precoTabelaUn             = '';
        budget.temperatura               = '';
        budget.ean                       = '';
        budget.index                     = '';
        budget.cds                       = '';
        budget.cnpjCd                    = '';
        budget.lote                      = '';
        budget.listTagByCd               = '';
        budget.estoque                  = 1;
        budget.estoqueUn                = 1;
        budget.un                        = '';
        budget.quantidade               = 1;
        budget.quantidadeCx             = 1;
        budget.unitario                  = '';
        budget.caixa                     = '';
        budget.inicialUnitario           = '';
        budget.inicialCaixa              = '';
        budget.conversaoUnidadeCx        = '';
        budget.desconto                 = 1;
        budget.valorTotalUnd            = 1;
        budget.valorTotalCx             = 1;
        budget.valorTotal               = 1;
        budget.aliquota                 = 1;
        budget.score                    = 1;
        budget.scoreBU                  = 1;
        budget.scoreMix                 = 1;
        budget.scoreItem                = 1;
        budget.indexPosition            = 1;
        budget.indexInsertPosition      = 1;
        budget.custoDif                 = 1;
        budget.custoCx                  = 1;
        budget.margem                   = 1;
        budget.margemAlvo               = 1;
        budget.margemAlvoInput          = 1;
        budget.validadeMinima            = '';
        budget.foraMalha                = true;
        budget.precoMalha               = 1;
        budget.precoSugerido            = 1;
        budget.laboratorio               = '';
        budget.tipoIntegradora           = '';
        budget.rangeStringify            = '';
        budget.bloqRegionalizacao       = true;
        budget.isInCampaign             = true;
        budget.showBadgeOL              = true;
        budget.showBadgeCampanha        = true;
        budget.showBadgeCampanhaVendedor = true;
        budget.showBadgeCampanhaCD      = true;
        budget.showBadgeConsignado      = true;
        budget.showBadgeAcordoComercial = true;
        budget.showBadgeshelflife       = true;
        budget.valorBloqueado           = true;
        budget.unidadePrincipal          = '';
        budget.verMargem                = true;
        budget.SequenciaOC               = '';
        budget.precoCNPJCampanha         = '';
        budget.precoCNPJShelflife        = '';
        budget.unidadeMedida             = '';
        budget.unidadeMedidaSeg          = '';
        budget.unidadeSecundaria         = '';
        budget.observacaoComercial = '';
    }

    @isTest
    public static void testGetContactData() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        System.assertEquals(account.Id, OrderScreenController.getContactData(contact.Id));
    }

    @isTest
    public static void testGetEnderecoEntregaData() {
        Account account = TestUtility.createAccPJ();
        insert account;

        EnderecoEntrega__c deliveryAddress = new EnderecoEntrega__c(
            Name                   = 'Delivery Address Test',
            Logradouro__c          = 'Rua Test',
            Estado__c              = 'Estado Test',
            Cidade__c              = 'City Test',
            Pais__c                = 'Country Test',
            CEP__c                 = '00000-000',
            ClientAddress__c       = true,
            EnderecoPrioritario__c = true,
            Cliente__c             = account.Id
        );
        insert deliveryAddress;

        System.assertEquals(deliveryAddress.Estado__c, OrderScreenController.getEnderecoEntregaData(deliveryAddress.Id));

    }

    @isTest
    public static void testGetAccountData() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id,
            Padrao__c = true
        );
        insert contact;

        EnderecoEntrega__c deliveryAddress = new EnderecoEntrega__c(
            Name                   = 'Delivery Address Test',
            Logradouro__c          = 'Rua Test', 
            Estado__c              = 'Estado Test',
            Cidade__c              = 'City Test',
            Pais__c                = 'Country Test',
            CEP__c                 = '000000-000',
            ClientAddress__c       = true,
            EnderecoPrioritario__c = true,
            Cliente__c             = account.Id
        );
        insert deliveryAddress;

        DocumentosRegulatorios__c document1 = new DocumentosRegulatorios__c(
            Name = 'Alvará',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        DocumentosRegulatorios__c document2 = new DocumentosRegulatorios__c(
            Name = 'CRT',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        insert new List<DocumentosRegulatorios__c>{document1, document2};

        System.assertEquals(account.Id, OrderScreenController.getAccountData(account.Id).ClienteEmissorId);
    }

    @isTest
    public static void testGetB01Pricebook() {
        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        System.assertEquals(pricebook.Id, OrderScreenController.getB01Pricebook());
    }
    
    @isTest
    public static void testGetOrderData() {
        Account account = TestUtility.createAccPJ();
        insert account;

        DocumentosRegulatorios__c document1 = new DocumentosRegulatorios__c(
            Name = 'Alvará',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        DocumentosRegulatorios__c document2 = new DocumentosRegulatorios__c(
            Name = 'CRT',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        insert new List<DocumentosRegulatorios__c>{document1, document2};

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        order.DatasParcelas__c = '02/09/2021, 07/09/2021, 14/09/2021';
        insert order;

        OrderScreenController.reformatInstallmentDates(order.DatasParcelas__c).remove('-').split(',');
        OrderScreenController.getStrDaysBetween(order.DatasParcelas__c).remove('-').split(',');

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10,
            cnpjCd__c = '52697744000192'
        );
        insert orderItem;

        Campaign campaign = new Campaign(
            Name = 'Campaign Test',
            ExternalId__c = '2186',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Campanha').getRecordTypeId()
        );
        insert campaign;

        ItemCampanha__c campaignItem = new ItemCampanha__c(
            Campanha__c = campaign.Id,
            NomeProduto__c = product.Id,
            VigenciaInicial__c = Date.today().addDays(-10),
            VigenciaFinal__c = Date.today()
        );
        insert campaignItem;

        Reserva__c reservation = TestUtility.createReservation();
        reservation.RecordTypeId = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaRegional').getRecordTypeId();
        insert reservation;

        ProdutoReserva__c reservationProd = TestUtility.createReservationProduct(reservation.Id, product.Id);
        insert reservationProd;

        ProdutoReserva__c reservationProd2 = TestUtility.createReservationProduct(reservation.Id, product.Id);
        reservationProd2.Armazem__c = '20';
        insert reservationProd2;        
        
        DestinatarioReserva__c reservationDest = TestUtility.createReservationDest(reservation.Id, account.Id);
        reservationDest.CodigoRegiao__c = '10';
        reservationDest.Cliente__c = null;
        insert reservationDest;
         
        OrderScreenController.getOrderData(order.Id, null);
        OrderScreenController.getCanEditPrice(order.Id);
        OrderScreenController.getComplementOrderSituation(order.Id);
        //System.assertEquals(order.Id, OrderScreenController.getOrderData(order.Id, null).HeaderId);
    }

    @isTest
    public static void testGetFilteredPaymentConditionData() {
        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        System.assertEquals(
            paymentCondition.Name, 
            OrderScreenController.getFilteredPaymentConditionData().MapCondIdToCondName.get(paymentCondition.Id)
        );
    }

    @isTest
    public static void testGetObjectNameFromRecId() {
        Account account = TestUtility.createAccPJ();
        insert account;

        System.assertEquals(
            'Account', 
            OrderScreenController.getObjectNameFromRecId(account.Id)
        );
    }

    @isTest
    public static void testGetUserProfileInfo() {
        System.assertEquals(true, OrderScreenController.getUserProfileInfo(UserInfo.getProfileId()));
    }

    @isTest
    public static void testGetBudgetData() {
        Account account = TestUtility.createAccPJ();
        insert account;

        DocumentosRegulatorios__c document1 = new DocumentosRegulatorios__c(
            Name = 'Alvará',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        DocumentosRegulatorios__c document2 = new DocumentosRegulatorios__c(
            Name = 'CRT',
            Conta__c = account.Id,
            DataVencimento__c = Date.today().addDays(20)
        );
        insert new List<DocumentosRegulatorios__c>{document1, document2};

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
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

        Contract contract = TestUtility.createContractOL(account);
        insert contract;

        ItemContrato__c contractItem = TestUtility.createContractItem(contract, product);
        contractItem.PrecoUnitario__c = 100;
        insert contractItem;

        System.assertEquals(account.Id, OrderScreenController.getBudgetData(opportunity.Id, null).ClienteEmissorId);
        System.assertEquals(account.Id, OrderScreenController.getBudgetData(account.Id, null).ClienteEmissorId);
    }
    
    @isTest
    public static void testSetInputExpiredReason() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
        );
        insert opportunity;

        System.assertEquals('Success!', OrderScreenController.setInputExpiredReason(opportunity.Id, 'Refuse reason'));
        OrderScreenController.setInputExpiredReason(null, 'Refuse reason');
    }

    @isTest
    public static void testGetToastInfoData() {
        System.assertEquals(
            'Erro', OrderScreenController.getToastInfoData().ToastInfoErrorRequired.Title
        );
    }

    @isTest
    public static void testGetSelectedAccountInfo() {
        Account account = TestUtility.createAccPJ();
        account.Bloqueado__c = 'Ativo';
        insert account;

        OrderScreenController.getSelectedAccountInfo(account.Id);
    }

    @isTest
    public static void testGetMalha() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.ProductCode = '1001';
        insert product;

        Integracoes__c integrationConfig = new Integracoes__c(
			Name        = 'InformaticaGetMalha',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfig;

        Integracoes__c integrationConfigPortal = new Integracoes__c(
			Name        = 'InformaticaGetMalhaPortal',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfigPortal;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Malha'));
        OrderScreenController.getMalhaPortal(account.CNPJ__c, 'SP', product.ProductCode, false, null, null, false);
        OrderScreenController.getMalha(account.CNPJ__c, product.ProductCode, true, null, null, true);
        Test.stopTest();
    }

    @isTest
    public static void testGetFirstMalha() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.ProductCode = '1001';
        insert product;

        Integracoes__c integrationConfig = new Integracoes__c(
			Name        = 'InformaticaGetMalha',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfig;

        Integracoes__c integrationConfigPortal = new Integracoes__c(
			Name        = 'InformaticaGetMalhaPortal',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfigPortal;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Malha'));
        //OrderScreenController.getMalhaPortal(account.CNPJ__c, 'SP', product.ProductCode, false, null, null, false);
        OrderScreenController.getFirstMalha(account.CNPJ__c, product.ProductCode, false, null, null, false);
        Test.stopTest();
    }

    @isTest
    public static void testGetLotes() {
        Account account = TestUtility.createAccPJ();
        insert account;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.ProductCode = '1001';
        insert product;

        Integracoes__c integrationConfig = new Integracoes__c(
			Name        = 'InformaticaConsultaLotes',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfig;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Lotes'));
        OrderScreenController.getLotes(account.CNPJ__c, product.ProductCode);
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;
        private String integration;

        public MockHttpResponseGenerator(Boolean isSuccess, String integration){
            this.isSuccess   = isSuccess;
            this.integration = integration;
        }
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.isSuccess? 200 : 500);

            if (integration == 'Malha') {
                if (res.getStatusCode() == 200){
                    res.setBody('{"output": [{"cds": [{"aliquota": 18,"foramalha": false,"prioridade": "1","cnpj": "52202744000192","saldo": 4,"custo": 174.64,"cd": "0101001","filial": "NACIONAL - RIBEIRAO PRETO (MATRIZ)"},{"aliquota": 18,"foramalha": false,"prioridade": "2","cnpj": "52202744000788","saldo": 0,"custo": 274.89,"cd": "0101007","filial": "NACIONAL - SANT. DE PARNAIBA (FILIAL 03)"}],"codprotheus": "0000310","ean": null}]}');
                }
            } else if (integration == 'Lotes') {
                if (res.getStatusCode() == 200){
                    res.setBody('{"estoque": [{"cod_distribuicao": "1","cod_operacao_logistica": "1","cod_operacao_logistica_polo": "01006","cod_produto": "27","lote": "LOTE UNICO","estoque": "20.0000","retido": "0.0000","cod_produto_polo": "0000002","validade": "2025-12-31T00:00:00-03:00"}]}');
                }
            }
            return res;
        }
    }

    @isTest
    public static void testGenerateBudget() {
        Account account = TestUtility.createAccPJ();
        insert account;

        User user = TestUtility.createUser();
        insert user;

        Setorizacao__c setorization = TestUtility.createSetorizacaoWithValidData(account, user);
        insert setorization;

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

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        ParametroScore__c scoreParameter1 = new ParametroScore__c(
            Name = 'A',
            Score__c = 60
        );
        ParametroScore__c scoreParameter2 = new ParametroScore__c(
            Name = 'B',
            Score__c = 70
        );
        ParametroScore__c scoreParameter3 = new ParametroScore__c(
            Name = 'C',
            Score__c = 80
        );
        ParametroScore__c scoreParameter4 = new ParametroScore__c(
            Name = 'D',
            Score__c = 90
        );
        insert new List<ParametroScore__c>{scoreParameter1, scoreParameter2, scoreParameter3, scoreParameter4};

        Map<String, Object> budgetMap = new Map<String, Object>{
            'itemId'            => null,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'desconto'          => 1,
            'unitario'          => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'valorTotal'        => 1000,
            'margem'            => 10,
            'margemAlvo'        => 10,
            'validadeMinima'    => 168,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 10,
            'aliquota'          => 12,
            'scoreItem'         => 50,
            'scoreBU'           => 32,
            'scoreMix'          => 5,
            'cnpjCd'            => '52586894000197',
            'foraMalha'         => false
        };

        List<Object> budgetList = new List<Object>{budgetMap};

        Map<String, Object> headerInfoMap = new Map<String, Object>{
            'numOrcamento'      => 'Opportunity Name',
            'valorTotal'        => 100,
            'score'             => 50,
            'margemAtual'       => 20,
            'clienteEmissorId'  => account.Id,
            'tabelaPreco'       => pricebook.Id,
            'canalEntrada'      => 'Chat',
            'condicaoPagamento' => paymentCondition.Id,
            'formaPagamento'    => 'Depósito',
            'contatoOrcamento'  => contact.Id,
            'prazoValidade'     => 4,
            'dtValidade'        => Date.today(),
            'observacaoCliente' => 'Account Observation Test',
            'observacao'        => 'Observation Test'
        };

        OrderScreenController.generateBudget(JSON.serialize(budgetList), JSON.serialize(headerInfoMap), true, false);

        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity WHERE AccountId = :account.Id];

        System.assertEquals(1, opportunityList.size());

        List<OpportunityLineItem> opportunityLineItemList = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityList.get(0).Id];

        System.assertEquals(1, opportunityLineItemList.size());

    }

    @isTest
    public static void testGenerateOrder() {
        Account account = TestUtility.createAccPJ();
        insert account;

        EnderecoEntrega__c deliveryAddress = new EnderecoEntrega__c(
            Name                   = 'Delivery Address Test',
            Estado__c              = 'Estado Test',
            Logradouro__c          = 'Rua Test', 
            Cidade__c              = 'City Test',
            Pais__c                = 'Country Test',
            CEP__c                 = '000000-000',
            ClientAddress__c       = true,
            EnderecoPrioritario__c = true,
            Cliente__c             = account.Id
        );
        insert deliveryAddress;

        User user = TestUtility.createUser();
        insert user;

        Setorizacao__c setorization = TestUtility.createSetorizacaoWithValidData(account, user);
        insert setorization;

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

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        CompanyParameters__c compParam = new CompanyParameters__c(
            Name = 'Atrial',
            Email__c = 'test@test.com'
        );

        insert compParam;

        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaPurchaseReqAPI',
			Method__c   = 'POST',
			Endpoint__c = 'https://test.com/test',
			User__c     = 'test@test.com.br',
			Password__c = 'test'
		);
        insert integration;

        GeneralParameters__c gParam = new GeneralParameters__c(
            Name = 'Parametro geral',    
            CentroCusto__c = '10'
        );
        insert gParam;

        Map<String, Object> jsonOrderMap = new Map<String, Object>{
            'itemId'            => null,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'lote'              => '7515-04/2021',
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'unitario'          => 100,
            'inicialCaixa'      => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'margem'            => 20,
            'margemAlvo'        => 20,
            'foraMalha'         => false,
            'validadeMinima'    => 168,
            'desconto'          => 10,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 100,
            'aliquota'          => 22,
            'scoreItem'         => 49,
            'scoreBU'           => 49,
            'scoreMix'          => 16,
            'cnpjCd'            => '52697744000192' 
        };

        List<Object> jsonOrderList = new List<Object>{jsonOrderMap};

        Map<String, Object> headerInfoMap = new Map<String, Object>{
            'score'                 => 50,
            'margemAtual'           => 20,
            'clienteEmissorId'      => account.Id,
            'medicoId'              => null,
            'tabelaPreco'           => pricebook.Id,
            'tipoFrete'             => 'CIF',
            'valorFrete'            => 30,
            'numeroPedidoCliente'   => '123',
            'condicaoPagamento'     => paymentCondition.Id,
            'contatoOrcamento'      => contact.Id,
            'canalVendas'           => 'Chat',
            'formaPagamento'        => 'Depósito',
            'clienteRecebedor'      => account.Id,
            'observacao'            => 'Observation Test',
            'observacaoNF'          => 'Observation NF Test',
            'enderecoEntrega'       => deliveryAddress.Id,
            'enderecoEntregaId'     => deliveryAddress.Id
        };

        OrderScreenController.generateOrder(JSON.serialize(jsonOrderList), JSON.serialize(headerInfoMap), false, false, null, false);

        OrderScreenController.generateComplementOrder(JSON.serialize(jsonOrderList), JSON.serialize(headerInfoMap), true, null);

        List<Order> orderList = [SELECT Id FROM Order WHERE AccountId = :account.Id];

        System.assertEquals(2, orderList.size());

        List<OrderItem> orderItemList = [SELECT Id FROM OrderItem WHERE OrderId = :orderList.get(0).Id];

        System.assertEquals(1, orderItemList.size());
    }

    @isTest
    public static void testGenerateBudgetAndOrder() {
        
        List<ParametroScore__c> paramList = new List<ParametroScore__c>();
        paramList.add(new ParametroScore__c(Name = 'A', Score__c = 90));
        paramList.add(new ParametroScore__c(Name = 'B', Score__c = 80));
        paramList.add(new ParametroScore__c(Name = 'C', Score__c = 70));
        paramList.add(new ParametroScore__c(Name = 'D', Score__c = 60));

        insert paramList;

        List<Integracoes__c> paintList = new List<Integracoes__c>();
        paintList.add(new Integracoes__c(Name = 'ElfaOrderAPI', Method__c = 'POST', Endpoint__c  = 'https://test.com', User__c  = 'test@teste.com', Password__c = '1235'));

        insert paintList;

                Account account = TestUtility.createAccPJ();
        insert account;

        EnderecoEntrega__c deliveryAddress = new EnderecoEntrega__c(
            Name                   = 'Delivery Address Test',
            Logradouro__c          = 'Rua Test', 
            Estado__c              = 'Estado Test',
            Cidade__c              = 'City Test',
            Pais__c                = 'Country Test',
            CEP__c                 = '000000-000',
            ClientAddress__c       = true,
            EnderecoPrioritario__c = true,
            Cliente__c             = account.Id
        );
        insert deliveryAddress;

        User user = TestUtility.createUser();
        insert user;

        Setorizacao__c setorization = TestUtility.createSetorizacaoWithValidData(account, user);
        insert setorization;

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

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        Map<String, Object> jsonOrderBudgetMap = new Map<String, Object>{
            'itemId'            => null,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'lote'              => '7515-04/2021',
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'unitario'          => 100,
            'inicialCaixa'      => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'margem'            => 20,
            'margemAlvo'        => 20,
            'foraMalha'         => false,
            'validadeMinima'    => 168,
            'desconto'          => 10,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 100,
            'aliquota'          => 22,
            'scoreItem'         => 49,
            'scoreBU'           => 49,
            'scoreMix'          => 16,
            'cnpjCd'            => '52697744000192' 
        };

        List<Object> jsonOrderBudgetList = new List<Object>{jsonOrderBudgetMap};

        Map<String, Object> headerInfoOpp = new Map<String, Object>{
            'numOrcamento'      => 'Opportunity Name',
            'valorTotal'        => 100,
            'score'             => 50,
            'margemAtual'       => 20,
            'clienteEmissorId'  => account.Id,
            'tabelaPreco'       => pricebook.Id,
            'canalEntrada'      => 'Chat',
            'condicaoPagamento' => paymentCondition.Id,
            'formaPagamento'    => 'Depósito',
            'contatoOrcamento'  => contact.Id,
            'prazoValidade'     => 4,
            'dtValidade'        => Date.today(),
            'observacaoCliente' => 'Account Observation Test',
            'observacao'        => 'Observation Test'
        };

        Map<String, Object> headerInfoOrd = new Map<String, Object>{
            'score'                 => 50,
            'margemAtual'           => 20,
            'clienteEmissorId'      => account.Id,
            'medicoId'              => null,
            'tabelaPreco'           => pricebook.Id,
            'tipoFrete'             => 'CIF',
            'valorFrete'            => 30,
            'numeroPedidoCliente'   => '123',
            'condicaoPagamento'     => paymentCondition.Id,
            'contatoOrcamento'      => contact.Id,
            'canalVendas'           => 'Chat',
            'formaPagamento'        => 'Depósito',
            'clienteRecebedor'      => account.Id,
            'observacao'            => 'Observation Test',
            'observacaoNF'          => 'Observation NF Test',
            'enderecoEntrega'       => deliveryAddress.Id,
            'enderecoEntregaId'     => deliveryAddress.Id
        };

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
        );
        insert opportunity;

        OrderScreenController.generateBudgetAndOrder(
            JSON.serialize(jsonOrderBudgetList), 
            JSON.serialize(headerInfoOpp),
            JSON.serialize(headerInfoOrd), 
            opportunity.Id
        );
    }

    @isTest
    public static void testEditOrder() {
        Account account = TestUtility.createAccPJ();
        insert account;

        EnderecoEntrega__c deliveryAddress = new EnderecoEntrega__c(
            Name                   = 'Delivery Address Test',
            Logradouro__c          = 'Rua Test', 
            Estado__c              = 'Estado Test',
            Cidade__c              = 'City Test',
            Pais__c                = 'Country Test',
            CEP__c                 = '000000-000',
            ClientAddress__c       = true,
            EnderecoPrioritario__c = true,
            Cliente__c             = account.Id
        );
        insert deliveryAddress;

        User user = TestUtility.createUser();
        insert user;

        Setorizacao__c setorization = TestUtility.createSetorizacaoWithValidData(account, user);
        insert setorization;

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

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        OrderScreenController.getConditionExternalId(paymentCondition.id);

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        OrderScreenController.getContactData(contact.id);
        OrderScreenController.getContactRelationData(account.Id, contact.id);
        OrderScreenController.getAccountAddress(account.Id);
        OrderScreenController.buscaCodigoLoja(account.Id);
        OrderScreenController.getTpCondPag(paymentCondition.id);
        OrderScreenController.getPricebookExternalId(pricebook.id);
        OrderScreenController.translateDayOfTheWeek('Mon');


        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        insert order;

        OrderScreenController.getApprovedOrder(order.id);

        OrderItem orderItem1 = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10
        );

        OrderItem orderItem2 = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10
        );
        insert new List<OrderItem>{orderItem1, orderItem2};

        Map<String, Object> jsonOrderMap1 = new Map<String, Object>{
            'itemId'            => null,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'lote'              => '7515-04/2021',
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'unitario'          => 100,
            'inicialCaixa'      => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'margem'            => 20,
            'margemAlvo'        => 20,
            'foraMalha'         => false,
            'validadeMinima'    => 168,
            'desconto'          => 10,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 100,
            'aliquota'          => 22,
            'scoreItem'         => 49,
            'scoreBU'           => 49,
            'scoreMix'          => 16,
            'cnpjCd'            => '52697744000192' 
        };

        Map<String, Object> jsonOrderMap2 = new Map<String, Object>{
            'itemId'            => orderItem2.Id,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'lote'              => '7515-04/2021',
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'unitario'          => 100,
            'inicialCaixa'      => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'margem'            => 20,
            'margemAlvo'        => 20,
            'foraMalha'         => false,
            'validadeMinima'    => 168,
            'desconto'          => 10,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 100,
            'aliquota'          => 22,
            'scoreItem'         => 49,
            'scoreBU'           => 49,
            'scoreMix'          => 16,
            'cnpjCd'            => '52697744000192' 
        };

        List<Object> jsonOrderList = new List<Object>{jsonOrderMap1, jsonOrderMap2};

        Map<String, Object> headerInfoMap = new Map<String, Object>{
            'score'                 => 50,
            'margemAtual'           => 20,
            'clienteEmissorId'      => account.Id,
            'medicoId'              => null,
            'tabelaPreco'           => pricebook.Id,
            'tipoFrete'             => 'CIF',
            'valorFrete'            => 30,
            'numeroPedidoCliente'   => '123',
            'condicaoPagamento'     => paymentCondition.Id,
            'contatoOrcamento'      => contact.Id,
            'canalVendas'           => 'Chat',
            'formaPagamento'        => 'Depósito',
            'clienteRecebedor'      => account.Id,
            'observacao'            => 'Observation Test',
            'observacaoNF'          => 'Observation NF Test',
            'enderecoEntrega'       => deliveryAddress.Id,
            'enderecoEntregaId'     => deliveryAddress.Id
        };

        OrderScreenController.editOrder(
            JSON.serialize(jsonOrderList), 
            JSON.serialize(headerInfoMap), 
            false, 
            order.Id,
            false,
            false
        );

        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>(
            [SELECT Id FROM OrderItem WHERE OrderId = :order.Id]
        );

        System.assertEquals(2, orderItemMap.size());
        System.assertEquals(false, orderItemMap.containsKey(orderItem1.Id));
    }

    @isTest
    public static void testEditBudget() {
        Account account = TestUtility.createAccPJ();
        insert account;

        User user = TestUtility.createUser();
        insert user;

        Setorizacao__c setorization = TestUtility.createSetorizacaoWithValidData(account, user);
        insert setorization;

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

        CondicaoPagamento__c paymentCondition = TestUtility.createPaymentCondition();
        insert paymentCondition;

        Contact contact = new Contact(
            FirstName = 'Teste', 
            LastName = 'Contate Test',
            Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
            AccountId = account.Id
        );
        insert contact;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
        );
        insert opportunity;

        OpportunityLineItem opportunityLineItem1 = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );

        OpportunityLineItem opportunityLineItem2 = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );
        insert new List<OpportunityLineItem>{opportunityLineItem1, opportunityLineItem2};

        Map<String, Object> budgetMap1 = new Map<String, Object>{
            'itemId'            => null,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'desconto'          => 1,
            'unitario'          => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'valorTotal'        => 1000,
            'margem'            => 10,
            'margemAlvo'        => 10,
            'validadeMinima'    => 168,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 10,
            'aliquota'          => 12,
            'scoreItem'         => 50,
            'scoreBU'           => 32,
            'scoreMix'          => 5,
            'cnpjCd'            => '52586894000197',
            'foraMalha'         => false
        };

        Map<String, Object> budgetMap2 = new Map<String, Object>{
            'itemId'            => opportunityLineItem2.Id,
            'id'                => pricebookEntry.Id,
            'prodId'            => product.Id,
            'quantidade'        => 10,
            'quantidadeCx'      => 10,
            'desconto'          => 1,
            'unitario'          => 100,
            'caixa'             => 100,
            'valorTotal'        => 1000,
            'valorTotal'        => 1000,
            'margem'            => 10,
            'margemAlvo'        => 10,
            'validadeMinima'    => 168,
            'cds'               => 'Distribuction Center',
            'custoCx'           => 10,
            'aliquota'          => 12,
            'scoreItem'         => 50,
            'scoreBU'           => 32,
            'scoreMix'          => 5,
            'cnpjCd'            => '52586894000197',
            'foraMalha'         => false
        };

        List<Object> budgetList = new List<Object>{budgetMap1, budgetMap2};

        Map<String, Object> headerInfoMap = new Map<String, Object>{
            'numOrcamento'      => 'Opportunity Name',
            'valorTotal'        => 100,
            'score'             => 50,
            'margemAtual'       => 20,
            'clienteEmissorId'  => account.Id,
            'tabelaPreco'       => pricebook.Id,
            'canalEntrada'      => 'Chat',
            'condicaoPagamento' => paymentCondition.Id,
            'formaPagamento'    => 'Depósito',
            'contatoOrcamento'  => contact.Id,
            'prazoValidade'     => 4,
            'dtValidade'        => Date.today(),
            'observacaoCliente' => 'Account Observation Test',
            'observacao'        => 'Observation Test'
        };

        OrderScreenController.editBudget(
            JSON.serialize(budgetList), 
            JSON.serialize(headerInfoMap), 
            false, 
            opportunity.Id,
            false
        );

        Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>(
            [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunity.Id]
        );

        System.assertEquals(2, opportunityLineItemMap.size());
        System.assertEquals(false, opportunityLineItemMap.containsKey(opportunityLineItem1.Id));
    }

    @isTest
    public static void testGetHistorico() {
        Account account = TestUtility.createAccPJ();
        account.CodigoCliente__c = '0168444';
        account.CodigoGrupoClientes__c = '000001';
        insert account;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        insert order;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10
        );
        insert orderItem;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
        );
        insert opportunity;

        OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 1,
            TotalPrice = 100,
            PricebookEntryId = pricebookEntry.Id,
            Product2Id = product.Id,
            ValorCx__c = 100
        );
        insert opportunityLineItem;

        List<OrderScreenController.HistoricData> historicDataList = OrderScreenController.getHistorico(account.Id, product.Id);

        Set<String> historicIds = new Set<String>();
        for (OrderScreenController.HistoricData historicData : historicDataList) {
            historicIds.add(historicData.Id);
        }

        System.assertEquals(true, historicIds.contains(orderitem.Id));
        System.assertEquals(true, historicIds.contains(opportunityLineItem.Id));
    }


    // @isTest
    // public static void testGetProduct() {

    //     GeneralParameters__c parameters = new GeneralParameters__c();
    //     parameters.Name = 'Parametro geral';
    //     parameters.Email__c = 'thomas.anderson@nescara.com';
    //     parameters.StockNotification__c = 4;
    //     insert parameters;

    //     Account account = TestUtility.createAccPJ();
    //     insert account;

    //     Pricebook2 pricebook = new Pricebook2(
    //         Name = 'Pricebook Test',
    //         ExternalId__c = 'B01'
    //     );
    //     insert pricebook;

    //     Fornecedor__c provider = new Fornecedor__c(
    //         Name = 'Provider Test'
    //     );
    //     insert provider;

    //     Product2 product = TestUtility.createProduct();
    //     product.FatorConversao__c = '1';
    //     product.Fornecedor__c = provider.Id;
    //     product.Description = 'Lectrum';
    //     product.ProductCode = '55801';
    //     product.IsActive = true;
    //     insert product;

    //     Estoque__c inventory = new Estoque__c(
    //         NomeProduto__c = product.Id,
    //         Saldo__c = 5
    //     );
    //     insert inventory;

    //     PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
    //     pricebookEntry.UnitPrice = 10;
    //     insert pricebookEntry;

    //     Setorizacao__c sectorization =new Setorizacao__c(
    //         Categoria__c = 'M',
    //         Produto__c = product.Id,
    //         Fornecedor__c = provider.Id,
    //         Vendedor__c = UserInfo.getUserid(),
    //         Conta__c = account.Id
    //     );
    //     insert sectorization;

    //     String pricebookId = pricebook.Id; 
    //     String clienteId = account.Id; 
    //     String offSetValue = ''; 
    //     String searchGenericValue = 'Lectrum'; 
    //     String searchFabricanteValue = 'Provider';

    //     List<OrderScreenController.ProductData> productList = OrderScreenController.getProduct(
    //         pricebookId,
    //         clienteId,
    //         offSetValue,
    //         searchGenericValue,
    //         searchFabricanteValue,
    //         null,
    //         false,
    //         new List<String>()
    //     );

    //     System.assertEquals(product.Id, productList.get(0).id);
    // }

    @isTest
    public static void testLockScreen() {
        Account account = TestUtility.createAccPJ();
        account.CodigoCliente__c = '0168444';
        account.CodigoGrupoClientes__c = '000001';
        insert account;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        insert order;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, product.Id);
        insert pricebookEntry;

        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            pricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100,
            Quantity = 10,
            ValorUn__c = 10,
            QuantidadeUn__c = 10,
            ValorCx__c = 10
        );
        insert orderItem;

        order.Status = 'Cancelado';
        update order;

        Opportunity opportunity = new Opportunity(
            Name = 'Opportunity Test',
            StageName = 'Novo',
            CloseDate = Date.today().addDays(10),
            AccountId = account.Id
        );
        insert opportunity;

        opportunity.StageName = 'Fechado/Gerado';
        update opportunity;

        System.assertEquals(
            'Não é possivel alterar um Pedido que esta com o status diferente de Em Digitação',    
            OrderScreenController.lockScreen(null, order.Id)
        );

        System.assertEquals(
            'Não é possivel alterar um Orçamento que esta com o status igual a Fechado/Gerado',    
            OrderScreenController.lockScreen(null, opportunity.Id)
        );
    }


}