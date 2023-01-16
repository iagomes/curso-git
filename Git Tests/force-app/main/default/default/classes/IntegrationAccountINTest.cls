@isTest
public with sharing class IntegrationAccountINTest {
     
    @TestSetup
    static void makeData(){
        // Account acc = TestUtility.generateAccount();
        // insert acc; 
    }

    @isTest
    static void upsertAccountTest() {
        
        TemplateDataIntegrationFields.ContadorINData contadorData = new TemplateDataIntegrationFields.ContadorINData();
        List<TemplateDataIntegrationFields.AccountINData> listAccData = new List<TemplateDataIntegrationFields.AccountINData>();
        TemplateDataIntegrationFields.AccountINData accData = new TemplateDataIntegrationFields.AccountINData();

        accData.NomeCliente             = 'Teste1';
        accData.CodigoCliente           = 'Cod123';
        accData.Loja                    = 'L01';
        accData.NomeFantasia            = 'Nome Fantasia';
        accData.CGC                     = '86706701000166';
        accData.TipoCliente             = 'Cliente 1';
        accData.Tipo                    = 'Jurídica';
        accData.InscricaoEstadual       = '854701797780';
        accData.InscricaoMunicipal      = '';
        accData.Contribuinte            = 'Não';
        accData.Telefone                = '1126553539';
        accData.OutroTelefone           = '11982612282';
        accData.Email                   = 'teste@elfa.com';
        accData.SiteWeb                 = 'Site123.com';
        accData.KeyAccount              = 'Sim';
        accData.Bloqueado               = 'Inativo';
        accData.ProprietarioConta       = '';
        accData.ContaPai                = '';
        accData.GrupoEconomico          = '';
        accData.SegmentoCliente         = 'Segmento';
        accData.Observacoes             = 'Obs exemplo.';
        accData.EnderecoCobranca        = 'Praça Santo Inácio de Loyola, 956';
        accData.CidadeCobranca          = 'São Paulo';
        accData.EstadoCobranca          = 'SP';
        accData.PaisCobranca            = 'BR';
        accData.CEPCobranca             = '04756190';
        accData.EnderecoEntrega         = 'Praça Santo Inácio de Loyola, 956';
        accData.CidadeEntrega           = 'São Paulo';
        accData.EstadoEntrega           = 'SP';
        accData.PaisEntrega             = 'BR';
        accData.CEPEntrega              = '04756190';
        accData.ComplementoEndereco     = 'Comp';
        accData.ContatoRecebimento      = 'Carlos';
        accData.Transportadora          = 'SDX';
        accData.TipoFrete               = 'Frete 1';
        accData.CondicaoPagamento       = 'Cond 3';
        accData.FormaPagamento          = '3x';
        accData.DescontoCliente         = 2;
        accData.GrauRiscoCliente        = '1';
        accData.SaldoFinanceiro         = '20000';
        accData.LimiteCredito           = 100000;
        accData.VencimentoLimiteCredito = Date.valueOf('2022-10-13');
        accData.TabelaPrecoCliente      = 'pricebook1';
        accData.ClasseCreditoCliente    = '';
        accData.DataCadastro            = Date.valueOf('2016-10-09');

        List<TemplateDataIntegrationFields.ContactINData> listContactData = new List<TemplateDataIntegrationFields.ContactINData>();
        TemplateDataIntegrationFields.ContactINData contactData = new TemplateDataIntegrationFields.ContactINData();

        contactData.ExternalId       = '001';
        contactData.Nome             = 'Carlos';
        contactData.Sobrenome        = 'Andrade';
        contactData.NomeConta        = '86706701000166';
        contactData.Cargo            = 'Outros';
        contactData.QualCargo        = 'Comerciante';
        contactData.Departamento     = '13';
        contactData.QualDepartamento = '';
        contactData.DataAniversario  = Date.valueOf('1964-03-20');
        contactData.Observacoes      = 'obs teste';
        contactData.GrauInfluencia   = '13';
        contactData.Celular          = '11945234516';
        contactData.Telefone         = '1146253158';
        contactData.TipoTelefone     = 'Comercial';
        contactData.Skype            = 'carlosAndrade.skype';
        contactData.Email            = 'carlosandrade@elfa.com';
        contactData.RedeSocial       = 'Carlos Andrade FB';

        listContactData.add(contactData);

        TemplateDataIntegrationFields.ContactINData contactData2 = new TemplateDataIntegrationFields.ContactINData();

        contactData2.ExternalId       = '002';
        contactData2.Nome             = 'Antonio';
        contactData2.Sobrenome        = 'Andrade';
        contactData2.NomeConta        = '86706701000166';
        contactData2.Cargo            = 'Outros';
        contactData2.QualCargo        = 'Comerciante';
        contactData2.Departamento     = '14';
        contactData2.QualDepartamento = '';
        contactData2.DataAniversario  = Date.valueOf('1967-07-15');
        contactData2.Observacoes      = 'obs teste';
        contactData2.GrauInfluencia   = '14';
        contactData2.Celular          = '11945234544';
        contactData2.Telefone         = '1146253197';
        contactData2.TipoTelefone     = 'Comercial';
        contactData2.Skype            = 'AntonioAndrade.skype';
        contactData2.Email            = 'Antonioandrade@elfa.com';
        contactData2.RedeSocial       = 'Antonio Andrade FB';
        
        listContactData.add(contactData2);

        accData.Contatos = listContactData;

        listAccData.add(accData);
        
        contadorData.Contador = '1';
        contadorData.Clientes = listAccData;
                
        System.assertEquals(true, IntegrationAccountIN.upsertAccount(contadorData).response[0].status);
    }
}
