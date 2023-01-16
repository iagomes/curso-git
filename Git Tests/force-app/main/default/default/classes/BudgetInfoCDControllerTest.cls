@isTest
public with sharing class BudgetInfoCDControllerTest {
    @TestSetup
    static void makeData(){
        Integracoes__c integrationConfigPortal = new Integracoes__c(
			Name        = 'InformaticaGetMalhaPortal',
			Method__c   = 'POST',
			Endpoint__c = 'undefined',
			User__c     = 'sample@grupoelfa.com.br',
			Password__c = 'samplePassword'
		);
        insert integrationConfigPortal;
        Account account = TestUtility.createAccPJ();
        account.CNPJ__c = '60495624000159';
        insert account;
        
        Contact contact = TestUtility.createContact(account);

        CondicaoPagamento__c conPay = TestUtility.createPaymentCondition2();
        conPay.ExternalId__c = '043';
        insert conPay;

        Opportunity oppWon = TestUtility.createOpportunity(account, contact, conPay);
        oppWon.StageName = 'Gerar Pedido';
        Opportunity oppLost = TestUtility.createOpportunity(account, contact, conPay);
        oppLost.StageName = 'Sem Retorno';
        insert new List<Opportunity>{oppWon, oppLost};

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        product.ProductCode = '1001';
        insert product;
        
        PricebookEntry pricebookEntry = [
            SELECT Id 
            FROM PricebookEntry 
            WHERE Product2Id = :product.Id 
            AND PriceBook2Id = :Test.getStandardPricebookId() 
            LIMIT 1
        ];

        OpportunityLineItem oppLineItemWon = TestUtility.createOpportunityLineItem(oppWon, product, pricebookEntry);
        oppLineItemWon.ValorPortal__c = 10;
        OpportunityLineItem oppLineItemLost = TestUtility.createOpportunityLineItem(oppLost, product, pricebookEntry);
        oppLineItemLost.ValorPortal__c = 10;
        insert new List<OpportunityLineItem>{oppLineItemWon, oppLineItemLost};

        Estoque__c estoque = TestUtility.createStock('getDistCenterTest', product.Id);
        estoque.ExternalId__c = 'getDistCenterTest';
        estoque.CNPJCD__c = '52202744000788';
        insert estoque;

        Campaign campanha = TestUtility.createCampaign();
        Campaign campanhaComCd = TestUtility.createCampaign();
        campanhaComCd.CodigoCD__c = '0101007';
        insert new List<Campaign>{campanha, campanhaComCd};

        ItemCampanha__c itemCamp = TestUtility.createItemCampanha(campanha.Id, product.Id);
        ItemCampanha__c itemCampComCd = TestUtility.createItemCampanha(campanhaComCd.Id, product.Id);

        insert new List<ItemCampanha__c>{itemCamp, itemCampComCd};

        Contract contractTypeA = TestUtility.createContract(account);
        insert contractTypeA;

        ItemContrato__c itemContrato = TestUtility.createContractItem(contractTypeA, product);
        //itemContrato.Status__c = 'Aprovado';
        itemContrato.VigenciaFinal__c = Date.today().addDays(1);
        insert itemContrato;

        QuoteItem__c qItem = TestUtility.createQuoteItem(oppWon);
        qItem.IdPortal__c = 'setItemCd';
        qItem.Categoria__c = 'M';
        qItem.OpportunityLineItem__c = oppLineItemWon.Id;
        qItem.Product__c = product.Id;
        insert qItem;
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
    static void getGroupTest(){
        StandardResponse response = BudgetInfoCDController.getGroup();
        System.assertEquals(false, response.hasError);
    }

    @isTest
    static void getDistCenterTest(){
        CondicaoPagamento__c conPay = [SELECT Id FROM CondicaoPagamento__c WHERE ExternalId__c = '043' LIMIT 1];
        Account acc = [SELECT Id, RecordType.Name FROM Account WHERE CNPJ__c = '60495624000159'];
        BudgetCtrl.ParamsMalha paramsMalha = new BudgetCtrl.ParamsMalha();
        paramsMalha.cnpj = '60495624000159';
        paramsMalha.UF = 'SP';
        paramsMalha.productCode = '1001';
        paramsMalha.calcMargem = true;
        paramsMalha.pricebookExternalId = '043';
        paramsMalha.condPagamento = conPay.Id;
        paramsMalha.isForaMalha = false;
        String paramsMalhaJSON = JSON.serialize(paramsMalha);

        BudgetCtrl.ParamsProd paramsProd = new BudgetCtrl.ParamsProd();
        paramsProd.quantidadeSolicitada = 1;
        paramsProd.cdsBloqueados = '52202744000192;';
        paramsProd.accountId = acc.Id;
        paramsProd.accountType = acc.RecordType.Name;
        paramsProd.tipoConversao = 'M';
        paramsProd.fatorConversao = '10';
        paramsProd.unidadePrincipal = 'UN';
        paramsProd.unidadeSecundaria = 'CX';
        String paramsProdJSON = JSON.serialize(paramsProd);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true, 'Malha'));
        BudgetInfoCDController.getDistCenter(paramsMalhaJSON, paramsProdJSON);
        Test.stopTest();
    }

    @isTest
    static void getConversaoUnidadeTexto(){
        BudgetInfoCDController.getConversaoUnidadeTexto(
            'D', '1', 'CX', 'UN'
        );
        BudgetInfoCDController.getConversaoUnidadeTexto(
            'M', '1', 'CX', 'UN'
        );
        BudgetInfoCDController.getConversaoUnidadeTexto(
            'N', '1', 'CX', 'UN'
        );
        BudgetInfoCDController.getConversaoUnidadeTexto(
            'M', '', 'CX', 'UN'
        );
    }

    @isTest
    static void setItemCdTest(){
        QuoteItem__c qItem = [
            SELECT Id,
            OpportunityLineItem__c, OpportunityId__c,
            Product__c, Product__r.ProductCode 
            FROM QuoteItem__c 
            WHERE IdPortal__c = 'setItemCd'
        ];
        BudgetDetailEditItemController.BudgetResposta item = new BudgetDetailEditItemController.BudgetResposta();
        item.id = qItem.Id;
        item.categoria = 'String';
        item.categoriaDesc = 'String';
        item.categoriaVendedor = 'M';
        item.categoriaVendedorDesc = 'String';
        item.comentario = 'String';
        item.cnpjCd = '52202744000192';
        item.dataHoraResposta = String.valueOf(System.now());
        item.fatorConversao = 1;
        item.idPortal = 'setItemCd';
        item.itemId = qItem.OpportunityLineItem__c;
        item.marcaProdOfertado = 'String';
        item.nome = 'String';
        item.nomeCd = 'String';
        item.nomeVendedor = 'String';
        item.principioAtivo = 'String';
        item.prodCode = qItem.Product__r.ProductCode;
        item.prodId = qItem.Product__c;
        item.productURL = 'String';
        item.SequenciaOC = 'String';
        item.status = 'Vinculado';
        item.tabulacaoN1 = 'Cotado';
        item.temperatura = 'String';
        item.tipoConversao = 'M';
        item.unidadePrincipal = 'String';
        item.unidadeSecundaria = 'String';
        item.unitarioPortal = 1;
        item.valorBloqueado = false;
        item.vendedorId = UserInfo.getUserId();

        String budgetRespostaJSON = JSON.serialize(item);

        BudgetCtrl.DistCenter dCenter = new BudgetCtrl.DistCenter();
        dCenter.id = 'String';
        dCenter.nome = 'String';
        dCenter.cnpj = 'String';
        dCenter.custo = 1;
        dCenter.preco = 1;
        dCenter.aliquota = 1;
        dCenter.precoFabrica = 1;
        dCenter.estoque = 1;
        dCenter.prioridade = 'String';
        dCenter.foramalha = false;
        dCenter.unidadePrincipal = 'String';
        dCenter.quantidadeElfa = 1;
        dCenter.valorElfa = 1;
        dCenter.desconto = 1;
        dCenter.validadeMin = null;
        dCenter.score = 1;
        dCenter.margem = 1;
        dCenter.margemAlvo = 1;
        dCenter.quantidadePortal = 1;
        dCenter.valorPortal = 1;
        dCenter.valorTotal = 1;
        dCenter.cdBloqueado = false;
        dCenter.bloqueioRegional = false;
        dCenter.dataGanho = 'String';
        dCenter.valorGanho = 1;
        dCenter.dataPerdido = 'String';
        dCenter.valorPerdido = 1;
        dCenter.previsaoEntrada = 'String';
        dCenter.quantPrevista = 1;
        dCenter.unidadeSecundaria = 'String';
        dCenter.conversaoUnidadeTexto = 'String';
        dCenter.estoqueSecundario = 1;
        dCenter.precoSecundario = 1;
        dCenter.precoFabricaSecundario = 1;

        String dCenterJSON = JSON.serialize(dCenter);
        
        BudgetCtrl.ExtraFields extraFields = new BudgetCtrl.ExtraFields();
        extraFields.oppId = qItem.OpportunityId__c;
        extraFields.foraMalha = false;
        extraFields.fatorConversaoProd = 1;
        extraFields.tipoConversaoProd = 'M';
        extraFields.comentario  = 'String';

        String extraFieldsJSON = JSON.serialize(extraFields);

        BudgetInfoCDController.setItemCd(budgetRespostaJSON, dCenterJSON, extraFieldsJSON);

        item.itemId = null;
        budgetRespostaJSON = JSON.serialize(item);
        BudgetInfoCDController.setItemCd(budgetRespostaJSON, dCenterJSON, extraFieldsJSON);

    }

    @isTest
    static void getFatorProdutoTest(){
        QuoteItem__c qItem = [
            SELECT Id,
            Product__c
            FROM QuoteItem__c 
            WHERE IdPortal__c = 'setItemCd'
        ];
        Product2 updateProduct = new Product2(Id = qItem.Product__c);
        updateProduct.TipoConversao__c = 'M';
        update updateProduct;
        BudgetInfoCDController.getFatorProduto(qItem.Product__c, qItem.Id);
        updateProduct.TipoConversao__c = 'D';
        update updateProduct;
        BudgetInfoCDController.getFatorProduto(qItem.Product__c, qItem.Id);
    }
    
    @isTest
    static void updateProductTest(){
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        prod.FatorConversaoPortal__c = '1';
        prod.TipoConversaoPortal__c = 'M';
        String prodJSON = JSON.serialize(prod);

        OpportunityLineItem oppLineItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oppLineItem.Comentarios__c = 'test';
        String oppLineItemJSON = JSON.serialize(oppLineItem);
        BudgetInfoCDController.updateProduct(prodJSON, oppLineItemJSON);
    }
}