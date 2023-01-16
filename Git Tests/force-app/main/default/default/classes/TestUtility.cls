/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 12-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
@isTest
public class TestUtility {

	private static final Double DEFAULT_EPSILON = 0.0001;
	public static final String PRODUCT_TESTNAME = 'Lectrum';
	public static final String PRODUCT_TESTCODE = '123456';
	public static final String CONTRACT_TESTNAME = '001';

	static Integer counter = 1;

	public static String getTestId(Schema.SObjectType sot) {
		String numberString = String.valueOf(counter++);
		String prefix = sot.getDescribe().getKeyPrefix();
		return prefix + '0'.repeat(12 - numberString.length()) + numberString;
	}

	public static Account createAccPJ() {
		return new Account(
			Name = 'Teste 1',
			CNPJ__c = '04585497000108',
			ExternalId__c = '04585497000108'
		);
	}

	public static Account createAccount() {
		return new Account (
			Name = 'Classe de teste da Account',
			BillingState = 'RJ'
		);
	}

	public static Account createInsertAccount() {
		Account acc = new Account (
			Name = 'Classe de teste da Account',
			BillingState = 'RJ'
		);

		insert acc;

		return acc;
	}

	public static Contact createContact(Id accountId) {
		return new Contact (
			FirstName = 'Teste',
			LastName  = 'Classe de teste de ContactHelper',
			Padrao__c = true,
			Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
			AccountId = accountId
			
		);
	}

	public static Contact createContactFromCNPJ(String accountCNPJ) {
		Account accountEx = new Account(CNPJ__c = accountCNPJ);
		return new Contact (
			FirstName = 'Teste',
			LastName  = 'Classe de teste de ContactHelper',
			Padrao__c = true,
			Email	  = 'teste@test.com',
			MobilePhone = '11971773331',
			Account = accountEx
		);
	}

	public static EnderecoEntrega__c createAddress(Id accountId) {
		return new EnderecoEntrega__c (
			Name  	   			   = 'Classe de teste de EnderecoEntregaHelper',
			Cliente__c 			   = accountId
		);
	}

	public static User createUser() {
		Profile p = [SELECT Id FROM Profile WHERE Name='Administrador do sistema' OR Name='System Administrator']; 
        return new User(
			FirstName         ='Test',
			LastName          ='Start', 
			Alias             = 'ADM', 
			Email             ='adminuser@testorg.com.a', 
            EmailEncodingKey  ='UTF-8', 
			LanguageLocaleKey ='pt_BR', 
            LocaleSidKey      ='pt_BR', 
			ProfileId         = p.Id, 
            TimeZoneSidKey    ='America/Los_Angeles', 
			UserName          ='amdinuser@testorg.com'
		);
	}

	public static User createUser(String userName1) {
		Profile p = [SELECT Id FROM Profile WHERE Name='Administrador do sistema' OR Name='System Administrator']; 
        return new User(
			FirstName         = userName1,
			LastName          = userName1, 
			Alias             = 'ADM'+userName1.right(1), 
			Email             = userName1+'@testorg.com', 
            EmailEncodingKey  ='UTF-8', 
			LanguageLocaleKey ='pt_BR', 
            LocaleSidKey      ='pt_BR', 
			ProfileId         = p.Id, 
            TimeZoneSidKey    ='America/Los_Angeles', 
			UserName          = userName1+'@test.test.com.test'
		);
	}

	public static User createUserTwo() {
		Profile p = [SELECT Id FROM Profile WHERE Name='Administrador do sistema' OR Name='System Administrator']; 
        return new User(
			FirstName         ='Test Two',
			LastName          ='Start', 
			Alias             = 'ADMi', 
			Email             ='adminuser@testorg.com.b', 
            EmailEncodingKey  ='UTF-8', 
			LanguageLocaleKey ='pt_BR', 
            LocaleSidKey      ='pt_BR', 
			ProfileId         = p.Id, 
            TimeZoneSidKey    ='America/Los_Angeles', 
			UserName          ='amdinuser2@testorg.com'
		);
	}

	public static User createUserThree() {
		Profile p = [SELECT Id FROM Profile WHERE Name='Administrador do sistema']; 
        return new User(
			FirstName         ='Test',
			LastName          ='Start', 
			Alias             = 'ADMn', 
			Email             ='adminuser@testorg.com.c', 
            EmailEncodingKey  ='UTF-8', 
			LanguageLocaleKey ='pt_BR', 
            LocaleSidKey      ='pt_BR', 
			ProfileId         = p.Id, 
            TimeZoneSidKey    ='America/Los_Angeles', 
			UserName          ='amdinuser3@testorg.com.c'
		);
	}

	public static AccountTeamMember createAccountTeamMember(Setorizacao__c setorizacao) {
		return new AccountTeamMember(
			AccountId = setorizacao.Conta__c,
			UserId = setorizacao.Vendedor__c,
			Setorizacao__c = setorizacao.Id,
			AccountAccessLevel = 'Read'
		);
	}



	public static OpportunityTeamMember createOpportunityTeamMember(Opportunity opp){
		
 
		return new OpportunityTeamMember(
			OpportunityId = opp.Id,
			UserId = UserInfo.getUserId(),
			TabulacaoN1__c = 'Aceite', 
			TabulacaoN2__c = 'Cotação Enviada Parcial'
		);
	}

	
	public static OpportunityTeamMember createOpportunityTeamMember(string oppEID, string userEID){
		Opportunity opp = new Opportunity(IdIntegrator__c = oppEID);
		User user = new User(CodigoUsuario__c = userEID);
 
		return new OpportunityTeamMember(
			Opportunity = opp,
			User = user,
			TabulacaoN1__c = 'Aceite', 
			TabulacaoN2__c = 'Cotação Enviada Parcial'
		);

	}

	public static Setorizacao__c createSetorizacaoWithValidData(Account acc, User us) {
		return new Setorizacao__c(
			ExternalId__c  = '001',
			Conta__c       = acc.Id,
			Vendedor__c    = us.Id,
			DataInicial__C = Date.Today().addDays(-1),
			DataFinal__c   = Date.Today().addDays(1),
			CodigoMesa__c  = '2131'
		);
	}

	public static Setorizacao__c createSetorizacaoWithValidDataAndCodigoMesa(Account acc, User us) {
		return new Setorizacao__c(
			ExternalId__c  = '001',
			Conta__c       = acc.Id,
			Vendedor__c    = us.Id,
			DataInicial__C = Date.Today().addDays(-1),
			DataFinal__c   = Date.Today().addDays(1),
			CodigoMesa__c  = '000024'
		);
	}

	public static Setorizacao__c createSetorizacaoWithInvalidData(Account acc, User us) {
		return new Setorizacao__c(
			ExternalId__c  = '001',
			Conta__c       = acc.Id,
			Vendedor__c    = us.Id,
			DataInicial__C = Date.Today().addDays(-5),
			DataFinal__c   = Date.Today().addDays(-2)
		);
	}

	public static Product2 createProduct() {
		return new Product2(
			Name = PRODUCT_TESTNAME, 
            Family = 'Medicine',
			ProductCode =PRODUCT_TESTCODE
		);
	}

	public static Product2 createAndInsertProduct() {
		Product2 product2 = new Product2(
			Name = 'Lectrum', 
            Family = 'Medicine'
		);

		ProductHandler.disableTrigger();
		insert product2;
		ProductHandler.enableTrigger();

		return product2;
	}

	public static Opportunity createOpportunity(User user) {
		return new Opportunity(
			OwnerId = user.Id,
			Name = 'Opportunity 1',
			StageName = 'Novo',
			CloseDate = Date.today()
		);
	}

	public static Opportunity createOpportunityTwo(User user) {
		return new Opportunity(
			OwnerId = user.Id,
			Name = 'Opportunity 2',
			StageName = 'Novo',
			CloseDate = Date.today().addDays(1)
		);
	}

	public static CondicaoPagamento__c createPaymentCondition() {
		return new CondicaoPagamento__c(
			ExternalId__c = 'condPag001',
			Name = 'Cond Pag 1',
			Descricao__c = '3x',
			TipoCondicaoPagamento__c = 'Cartão'
		);
	}

	public static CondicaoPagamento__c createPaymentCondition2() {
		return new CondicaoPagamento__c(
			ExternalId__c = '043',
			Name = '043/A VISTA',
			Descricao__c = '043',
			TipoCondicaoPagamento__c = 'Cartão'
		);
	}

	public static CondicaoPagamentoPorCD__c createCondicaoPagamentoPorCD(CondicaoPagamento__c payCon) {
		CondicaoPagamento__c pc = new CondicaoPagamento__c(ExternalId__c = payCon.ExternalId__c);
		
		return new CondicaoPagamentoPorCD__c(
			CentroDistribuicao__c = 'Test1',
			CNPJCD__c = '41829288000199',
			CondicaoPagamento__r = pc
		);
	}

	public static CondicaoPagamentoPorCD__c createCondicaoPagamentoPorCD(Id payConId) {
		
		return new CondicaoPagamentoPorCD__c(
			CentroDistribuicao__c = 'Test1',
			CNPJCD__c = '41829288000199',
			CondicaoPagamento__c = payConId
		);
	}
	

	public static PricebookEntry createPricebookEntry(Id pbId, Id prodId) {		
		return new PricebookEntry(
			Pricebook2Id = pbId,
			Product2Id = prodId,
			unitPrice = 100,
			IsActive = true
		);
	}

	public static PricebookEntry createPricebookEntry(pricebook2 pbId, product2 prod) {
				
		return new PricebookEntry(
			Pricebook2 = new Pricebook2(ExternalId__c = pbId.ExternalId__c),
			Product2 = new Product2(ExternalId__c = prod.ExternalId__c),
			unitPrice = 100,
			IsActive = true
		);
	}

	public static ContentVersion createContentVersion() {
		return new ContentVersion(
			Description = '001',
			Title = 'PDF Sample.pdf',
			PathOnClient = 'PDF Sample.pdf',
			VersionData = Blob.valueOf('JVBERi0xLg10cmFpbGVyPDwvUm9vdDw8L1BhZ2VzPDwvS2lkc1s8PC9NZWRpYUJveFswIDAgMyAzXT4+XT4+Pj4+Pg==')
		);
	}

	public static ContentVersion createAndInsertContentVersion() {
		ContentVersion contentVersion = new ContentVersion(
			Description = '001',
			Title = 'PDF Sample.pdf',
			PathOnClient = 'PDF Sample.pdf',
			VersionData = Blob.valueOf('JVBERi0xLg10cmFpbGVyPDwvUm9vdDw8L1BhZ2VzPDwvS2lkc1s8PC9NZWRpYUJveFswIDAgMyAzXT4+XT4+Pj4+Pg==')
		);

		insert contentVersion;
		return contentVersion;
	}

	public static Pricebook2 createPricebook2(Product2 product) {
		return new Pricebook2(
			Name 	   	     = 'Test Pricebook2',
			CodigoTabela__c = 'teste'
			//PricebookEntryId = createPricebookEntry(Test.getStandardPricebookId(), product.Id)
		);
	}
	public static Pricebook2 createPricebook2() {
		return new Pricebook2(
			Name 	   	     = 'Test Pricebook2',
			CodigoTabela__c = 'teste'
			//PricebookEntryId = createPricebookEntry(Test.getStandardPricebookId(), product.Id)
		);
	}

	public static Opportunity createOpportunity(Account acc, Contact contact, CondicaoPagamento__c conditionPayment) {
		return new Opportunity(
			Name 				 = 'Test Opportunity',
			StageName			 = 'Em digitação',
			AccountId 			 = acc.id,
			ContatoOrcamento__c  = contact.Id,
			CanalEntrada__c 	 = 'Humma', 
			CloseDate			 = Date.today() + 5,
			CondicaoPagamento__c = conditionPayment.Id,
			Pricebook2Id 		 = Test.getStandardPricebookId()
		);
	}

	public static OpportunityLineItem createOpportunityLineItem(Opportunity opportunity, Product2 product, PricebookEntry pricebookEntry) {
		return new OpportunityLineItem(
			Product2Id 	  	 = product.Id,
			IdCustomer__c 	 = product.Id,
			IdIntegrator__c	 = product.Id,
			IdPortal__c 	 = product.Id,
			OpportunityId 	 = opportunity.Id,
			Quantity  	  	 = 10,
			UnitPrice	  	 = 1,
			PricebookEntryId = pricebookEntry.Id
		);
	}

	public static OpportunityLineItem createOpportunityLineItem(string oppIdIntegrator, string prodExternalId, string pbExternalId){

		Opportunity opp = new Opportunity(IdIntegrator__c = oppIdIntegrator);
		product2 prod = new product2(ExternalId__c = prodExternalId);
		PricebookEntry pbentry = new PricebookEntry(ExternalId__c = pbExternalId);

		return new OpportunityLineItem(
			Product2 	  	 = prod,
			IdCustomer__c 	 = prod.ExternalId__c,
			IdIntegrator__c	 = prod.ExternalId__c,
			IdPortal__c 	 = prod.ExternalId__c,
			Opportunity	 	 = opp,
			Quantity  	  	 = 10,
			UnitPrice	  	 = 1,
			PricebookEntry = pbentry
		);
	}

	public static QuoteItem__c createQuoteItem(Opportunity opp){
		return createQuoteItem(opp, new User(Id = UserInfo.getUserId()));
	}

	public static QuoteItem__c createQuoteItem(Opportunity opp, User user){
		

		return new QuoteItem__c(
			OpportunityId__c = opp.Id,
			Vendedor__c = user.Id,
			name = 'TestQuoteItem',
			Status__c = 'Não Vinculado',
			SequenciaOC__c = '1'
		);
	}

	public static QuoteItem__c createQuoteItem(String oppEID, String userEID){
		Opportunity opp = new Opportunity(IdIntegrator__c = oppEID);
		User user = new User(CodigoUsuario__c = userEID);

		return new QuoteItem__c(
			Vendedor__r = user,
			OpportunityId__r = opp,
			name = 'TestQuoteItem',
			Status__c = 'Não Vinculado',
			SequenciaOC__c = '1'
		);
	}

	
	public static Contact createContact(Account acc) {
		return new Contact(
			FirstName = 'Second',
			LastName  = 'Test Contact',
			Email	  = 'teste@test2.com',
			MobilePhone = '11933317177',
			AccountId = acc.id
		);
	}

	public static CondicaoPagamento__c createConditionPayment() {
		return new CondicaoPagamento__c(
			Name 	 = 'Test Condition Payment',
			Ativo__c = true
		);
	} 

	public static Product2 createProductToStock() {
		return new Product2(
			Name = 'Lectrum', 
            Family = 'Medicine'
		);
	}

	public static Estoque__c createStock(String externalId, Id productId) {
		return new Estoque__c(
			NomeProduto__c = productId,
			ExternalId__c = externalId + '        01',
			Name = externalId + '        01',
			Saldo__c = 100
		);
	}

	public static Estoque__c createInsertStock(String externalId, Id productId) {
		Estoque__c inventory = new Estoque__c(
			NomeProduto__c = productId,
			ExternalId__c = externalId + '        01',
			Name = externalId + '        01',
			Saldo__c = 100,
			PrecoMedio__c = 1233,
			Armazem__c = '01',
			CNPJCD__c = '18269125000187'
		);

		EstoqueHandler.disableTrigger();
		insert inventory;
		EstoqueHandler.enableTrigger();

		return inventory;
	}
	
	public static OrderItem createOrderItem(Order order, Product2 product, PricebookEntry pricebookEntry) {
		return new OrderItem(
			Product2Id 		 = product.Id,
			OrderId    		 = Order.Id,
			PricebookEntryId = pricebookEntry.Id,
			Quantity		 = 1,
			Unitprice		 = 1.00
		);
	}

	public static Order createOrder(Account acc) {
		return new Order(
			Name = 'Test Order ',
			Status = 'Draft',
			EffectiveDate = system.today(),
			EndDate = system.today() + 4,
			AccountId = acc.id,
			Pricebook2Id = Test.getStandardPricebookId()
		);
	}

	public static Order createOrderTwo(Account acc) {
		return new Order(
			Name = 'Test Order 2',
			Status = 'Draft',
			EffectiveDate = system.today(),
			EndDate = system.today() + 4,
			AccountId = acc.id,
			Pricebook2Id = Test.getStandardPricebookId()
		);
	}

	public static SolicitacaoCompras__c createPurchases(Order order) {
		return new SolicitacaoCompras__c(
			Pedido__c = order.Id
		);
	}

	public static NotasFiscais__c createNotaFiscal(Order ord, Account acc) {
		return new NotasFiscais__c(
			ExternalId__c = 'nf0000000000001',
			Name = 'nf0000000000001',
			Pedido__c = ord.Id,
			Conta__c = acc.Id
		);
	}

	public static TitulosAbertos__c createTituloAberto(Account acc, NotasFiscais__c nf) {
		return new TitulosAbertos__c(
			NumeroBoleto__c = 'tit001',
			Conta__c = acc.Id,
			NumeroNotaFiscal__c = nf.Id
		); 
	}

	public static Integracoes__c createCustomSettingGetAttPDF() {
		return new Integracoes__c(
			Name = 'GetFiscalAttachmentPDF',
			Method__c = 'GET',
			Endpoint__c = '172.30.0.20:1006/DEV/GetXML?cCgcEmp={{CGC}}&cNota={{externalId}}&cSerie={{nfSerieExternalId}}'
		);
	}

	public static Integracoes__c createCustomSettingGetAttXML() {		
		return new Integracoes__c(
			Name = 'GetFiscalAttachmentXML',
			Method__c = 'GET',
			Endpoint__c = '172.30.0.20:1006/DEV/GetXML?cCgcEmp={{CGC}}&cNota={{externalId}}&cSerie={{nfSerieExternalId}}&cTpNF=S'
		);
	}

	public static Integracoes__c createCustomSettingGetAtt() {
		return new Integracoes__c(
			Name = 'GetFiscalAttachment',
			Method__c = 'GET',
			Endpoint__c = '172.30.0.20:1006/DEV/GetXML?cCgcEmp={{CGC}}&cNota={{externalId}}&cSerie={{nfSerieExternalId}}'
		);		
	}
	
	public static Integracoes__c createCustomSettingContract() {		
		return new Integracoes__c(
			Name        = 'ElfaContractAPI',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
	}

	public static Integracoes__c createCustomSettingOrder() {		
		return new Integracoes__c(
			Name        = 'ElfaOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
	}

	public static Integracoes__c createCustomSettingApproval() {		
		return new Integracoes__c(
			Name        = 'ElfaApprovalOrderAPI',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
	}

	public static TemplatePDF__c createTemplateOpportunityPDF(Id templateId) {		
		return new TemplatePDF__c(
			Name        = 'ElfaQuoteTemplate',
			Id			= templateId
		);
	}

	public static TemplatePDF__c createTemplateOrderPDF(Id templateId) {		
		return new TemplatePDF__c(
			Name        = 'ElfaQuoteOrderTemplate',
			Id			= templateId
		);
	}

	public static Integracoes__c createTotvsAccessToken() {		
		return new Integracoes__c(
			Name        = 'TotvsAccessTokenAPI',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
	}

	public static Contract createContract(Account acc) {
		return new Contract(
			Name = CONTRACT_TESTNAME,
			Status = 'Rascunho',
			AccountId = acc.Id,
			ContractTerm = 5,
			TipoRegra__c = 'A'
		);
	}

	public static Contract createContractOL(Account acc) {
		return new Contract(
			Name = '001',
			Status = 'Rascunho',
			AccountId = acc.Id,
			ContractTerm = 5,
			TipoRegra__c = 'O'
		);
	}

	public static ItemContrato__c createContractItem(Contract con, Product2 prod) {
		return new ItemContrato__c(
			Status__c = 'Rascunho',
			PrecoUnitario__c = 1,
			NumeroContrato__c = con.Id,
			NomeProduto__c = prod.Id,
			VigenciaFinal__c = Date.today()
		);
	}

	
	public static ItemContrato__c createContractItemInApproval(Contract con, Product2 prod) {
		return new ItemContrato__c(
			Status__c = 'Em aprovação',
			NumeroContrato__c = con.Id,
			NomeProduto__c = prod.Id,
			VigenciaFinal__c = Date.today()
		);
	}

	
	public static ItemContrato__c createContractItemApproved(Contract con, Product2 prod) {
		return new ItemContrato__c(
			Status__c = 'Aprovado',
			NumeroContrato__c = con.Id,
			NomeProduto__c = prod.Id,
			VigenciaInicial__c = Date.today(),
			VigenciaFinal__c = Date.today().addDays(1)
		);
	}
	

	public static Case createCase(Account acc, Contact c) {
		return new Case(
			AccountId = acc.Id,
			ContactId = c.Id,
			Status = 'New',
			AnaliseDoCaso__c = 'Procedente',
			Origin = 'Email',
			Priority = 'Medium',
            SuppliedEmail = 'teste@test.com',
            ToAddress__c = 'teste@test.com',
            Razao__c = 'Reclamação',
			Type = 'Reclamação',
            StatusResponsibleArea__c = 'N/A',
            BypassValidationRules__c = false
		);
	}

	public static Territory2 createTerritory2(Id tModelId, Id tTypeId) {
		return new Territory2(
			Categoria__c      = 'M',
			CodigoMesa__c     = 'TESTE',
			Regiao__c         = '99',
			DeveloperName     = 'MTESTE_M_99',
			Name		      = 'TESTE',
			Territory2ModelId = tModelId,
			Territory2TypeId  = tTypeId
		);
	}

	public static Campaign createCampaign() {
		return new Campaign(			
            Name = 'Campaign Test',
            ExternalId__c = '123',
            EndDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Campanha').getRecordTypeId()
		);
	}

	public static Campaign createCampaignShelfLife() {
		return new Campaign(			
            Name = 'Campaign Test Shelf Life',
            ExternalId__c = '123Shelf',
            EndDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('ContratoShelfLife').getRecordTypeId()
		);
	}

	public static Campaign createCampaignVendedor() {
		return new Campaign(			
            Name = 'Campaign Test Vendedor',
            ExternalId__c = '123Vendedor',
            EndDate = Date.today().addDays(30),
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('CampanhaVendedor').getRecordTypeId()
		);
	}

	public static ItemCampanha__c createItemCampanha(Id campaignId, Id productId) {
		return new ItemCampanha__c(
            Campanha__c = campaignId,
            NomeProduto__c = productId,
            VigenciaInicial__c = Date.today().addDays(-10),
            VigenciaFinal__c = Date.today()
        );
	}

	public static GrupoCliente__c createGrupoCliente() {
		return new GrupoCliente__c(
			CodigoGrupo__c = '123',
			Name = 'Cliente Test'
		);
	}

	public static Reserva__c createReservation() {
		Reserva__c reserve = new Reserva__c(
			CentroDistribuicao__c = '123456',
			CodigoCD__c = 'ABCD',
			FimReserva__c = System.Today(),
			CodigoReserva__c = '123456'
		);
		return reserve;
	}

	public static Reserva__c createAndInsertReservation() {
		Reserva__c reserve = new Reserva__c(
			CentroDistribuicao__c = '123456',
			CodigoCD__c = 'ABCD',
			FimReserva__c = System.Today(),
			CodigoReserva__c = '123456',
			CodigoSaldoFinanceiro__c = '000001',
			RecordTypeId = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaCliente').getRecordTypeId()

		);
		ReservationTriggerHandler.disableTrigger();
		insert reserve;
		ReservationTriggerHandler.enableTrigger();
		return reserve;
	}

	public static Reserva__c createAndInsertReservation(String codigo) {
		Reserva__c reserve = new Reserva__c(
			CentroDistribuicao__c = '123456',
			CodigoCD__c = 'ABCD',
			FimReserva__c = System.Today(),
			CodigoReserva__c = codigo
		);

		ReservationTriggerHandler.disableTrigger();
		insert reserve;
		ReservationTriggerHandler.enableTrigger();
		return reserve;
	}

	public static ProdutoReserva__c createReservationProduct(Id reservationId, Id productId) {
		ProdutoReserva__c productReservation = new ProdutoReserva__c(
			Produto__c = productId,
			Reserva__c = reservationId,
			QuantidadeReservada__c = 10,
			Armazem__c = '01'
		);

		return productReservation;
	}	

	public static ProdutoReserva__c createAndInsertReservationProduct(Id reservationId, Id productId) {
		ProdutoReserva__c productReservation = new ProdutoReserva__c(
			Produto__c = productId,
			Reserva__c = reservationId,
			QuantidadeReservada__c = 10,
			Armazem__c = '01'
		);

		ReservationProductTriggerHandler.disableTrigger();
		insert productReservation;
		ReservationProductTriggerHandler.enableTrigger();
		return productReservation;
	}

	public static DestinatarioReserva__c createReservationDest(Id reservationId, Id accountId) {
		DestinatarioReserva__c reservationRecipient = new DestinatarioReserva__c(
			Cliente__c = accountId,
			CodigoRegiao__c = 'ABCDE',
			Reserva__c = reservationId
		);

		System.debug('reservationRecipient ==> ' + reservationRecipient);
		
		return reservationRecipient;
	}		

	public static DestinatarioReserva__c createAndInsertReservationDest(Id reservationId, Id accountId) {
		DestinatarioReserva__c reservationRecipient = new DestinatarioReserva__c(
			Cliente__c = accountId,
			CodigoRegiao__c = 'ABCDE',
			Reserva__c = reservationId
		);

		System.debug('reservationRecipient ==> ' + reservationRecipient);

		ReservationRecipientTriggerHandler.disableTrigger();
		insert reservationRecipient;
		ReservationRecipientTriggerHandler.enableTrigger();
		return reservationRecipient;
	}	

	public static ListaCentroDistribuicao__c createListaCentroDistribuicao() {
		ListaCentroDistribuicao__c listCentroDistribuicao = new ListaCentroDistribuicao__c(
			CNPJCD__c = '18269125000187',
			CodigoCD__c = 'ABCD',
			NomeCD__c = 'CD SÃO PAULO',
			Name = '2142412'
 		);

		insert listCentroDistribuicao;

		return listCentroDistribuicao;
	}

}