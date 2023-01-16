@isTest
public with sharing class budgetCtrlTest {
    @isTest
    public static void testBudgetCtrl(){
        BudgetCtrl.ParamsMalha paramsMalha = new BudgetCtrl.ParamsMalha();
        paramsMalha.cnpj = null;
        paramsMalha.UF = null;
        paramsMalha.productCode = null;
        paramsMalha.calcMargem = null;
        paramsMalha.pricebookExternalId = null;
        paramsMalha.condPagamento = null;
        paramsMalha.isForaMalha = null;

        BudgetCtrl.ParamsProd paramsProd = new BudgetCtrl.ParamsProd();
        paramsProd.unidadePrincipal = null;
        paramsProd.quantidadeSolicitada = null;
        paramsProd.cdsBloqueados = null;
        paramsProd.accountId = null;
        paramsProd.accountType = null;
        paramsProd.unidadeSecundaria = null;
        paramsProd.tipoConversao = null;
        paramsProd.fatorConversao = null;

        BudgetCtrl.Malha malha = new BudgetCtrl.Malha();
        malha.cds = null;
        malha.code = null;
        malha.msgErro = null;
        malha.codprotheus = null;
        malha.ean = null;

        BudgetCtrl.MalhaData malhaData = new BudgetCtrl.MalhaData();
        malhaData.TipoIntegradora = null;
        malhaData.pf = null;
        malhaData.laboratorio = null;
        malhaData.EnviaIntegrador = null;
        malhaData.range = null;
        malhaData.BloqRegionalizacao = null;
        malhaData.preco = null;
        malhaData.tipopreco = null;
        malhaData.filial = null;
        malhaData.cd = null;
        malhaData.custo = null;
        malhaData.saldo = null;
        malhaData.cnpj = null;
        malhaData.prioridade = null;
        malhaData.foramalha = null;
        malhaData.aliquota = null;
    
        BudgetCtrl.Range range = new BudgetCtrl.Range();
        BudgetCtrl.DistCenter distCenter = new BudgetCtrl.DistCenter();
        distCenter.id = null;
        distCenter.nome = null;
        distCenter.cnpj = null;
        distCenter.custo = null;
        distCenter.preco = null;
        distCenter.aliquota = null;
        distCenter.precoFabrica = null;
        distCenter.estoque = null;
        distCenter.prioridade = null;
        distCenter.foramalha = null;
        distCenter.unidadePrincipal = null;
        distCenter.quantidadeElfa = null;
        distCenter.valorElfa = null;
        distCenter.desconto = null;
        distCenter.validadeMin = null;
        distCenter.score = null;
        distCenter.margem = null;
        distCenter.margemAlvo = null;
        distCenter.quantidadePortal = null;
        distCenter.valorPortal = null;
        distCenter.valorTotal = null;
        distCenter.cdBloqueado = null;
        distCenter.dataGanho = null;
        distCenter.valorGanho = null;
        distCenter.dataPerdido = null;
        distCenter.valorPerdido = null;
        distCenter.bloqueioRegional = false;
        distCenter.quantPrevista = null;
        distCenter.previsaoEntrada = null;
        distCenter.badges = null;
        distCenter.unidadeSecundaria = null;
        distCenter.conversaoUnidadeTexto = null;
        distCenter.estoqueSecundario = null;
        distCenter.precoSecundario = null;
        distCenter.precoFabricaSecundario = null;

        BudgetCtrl.ExtraFields extraFields = new BudgetCtrl.ExtraFields();
        extraFields.oppId = null;
        extraFields.foraMalha = null;
        extraFields.fatorConversaoProd = null;
        extraFields.tipoConversaoProd = null;
        extraFields.comentario = null;

        BudgetCtrl.Badge b1 = new BudgetCtrl.Badge('O', 0);
        String labelb1 = b1.label;
        String b1a = b1.style;
        BudgetCtrl.Badge b2 = new BudgetCtrl.Badge('A', 0);
        String labelb2 = b2.label;
        BudgetCtrl.Badge b3 = new BudgetCtrl.Badge('ContratoShelfLife', 0);
        String labelb3 = b3.label;
        BudgetCtrl.Badge b4 = new BudgetCtrl.Badge('Campanha', 0);
        String labelb4 = b4.label;
        BudgetCtrl.Badge b5 = new BudgetCtrl.Badge('CampanhaVendedor', 0);
        String labelb5 = b5.label;
        BudgetCtrl.Badge b6 = new BudgetCtrl.Badge('ProdutoConsignado', 0);
        String labelb6 = b6.label;
        BudgetCtrl.Badge b7 = new BudgetCtrl.Badge('ProdutoReservado', 0);
        String labelb7 = b7.label;
        BudgetCtrl.Badge b8 = new BudgetCtrl.Badge('nada', 0);
        String labelb8 = b8.label;

        BudgetCtrl.CampaignData camp = new BudgetCtrl.CampaignData();
        camp.price = 1;

        BudgetCtrl.PicklistOption picklist = new BudgetCtrl.PicklistOption(false, '', '');

        BudgetCtrl.SomatoriaDTO somatoria = new BudgetCtrl.SomatoriaDTO();
        
        CondicaoPagamentoPorCD__c condPagCD = new CondicaoPagamentoPorCD__c(
            CentroDistribuicao__c = '',
            CNPJCD__c = '',
            FretePicklist__c = '',
            CondicaoPagamentoPL__c = '002/28 D',
            ObservacoesLongText__c = '',
            CloseDate__c = System.today(),
            PrazoValidade__c = 0,
            PrazoEntrega__c = 0,
            MinimumBilling__c = 0
        );
        BudgetCtrl.DistCenterDTO distCenterDTO = new BudgetCtrl.DistCenterDTO(somatoria, condPagCD);
        distCenterDTO.build();
    }
}
