global without sharing class TemplateDataIntegrationFields {

    public interface FieldData {
        List<String> getRequiredFields();
        String getFieldKey();
        String getFieldId();
        SObject serialize(Map<String, Id> lookups);
    }
    
    public interface FieldDataChild {
        List<String> getRequiredFields();
        String getFieldKey();
        String getFieldExternal();
        SObject serialize(Map<String, String> lookups);
        String getParentKey();
    }

    global class ContadorINData {
        public String Contador;
        public List<AccountINData> Clientes;
        public List<OrderINData> Pedidos;
    }

    //Account input structure -> Implementing FieldData
    global class AccountINData implements FieldData {

        public String  NomeCliente;
        public String  CodigoCliente;
        public String  Loja;
        public String  NomeFantasia;
        public String  CGC;
        public String  TipoCliente; // Público | Privado | Misto
        public String  TipoConselho;
        public String  UFRegistroMedico;
        public String  CodigoEspecialidadeMedico;
        public String  EspecialidadeMedico;
        public String  Area;
        public String  Tipo; // Física / Jurídica
        public String  InscricaoEstadual;
        public String  InscricaoMunicipal;
        public String  Contribuinte;
        public String  Telefone;
        public String  OutroTelefone;
        public String  Email;
        public String  SiteWeb;
        public String  KeyAccount;
        public String  Bloqueado;
        public String  ProprietarioConta;
        public String  ContaPai;
        public String  GrupoEconomico;
        public String  SegmentoCliente;
        public String  Observacoes;
        public String  EnderecoCobranca;
        public String  CidadeCobranca;
        public String  EstadoCobranca;
        public String  PaisCobranca;
        public String  CEPCobranca;
        public String  EnderecoEntrega;
        public String  CidadeEntrega;
        public String  EstadoEntrega;
        public String  PaisEntrega;
        public String  CEPEntrega;
        public String  ComplementoEndereco;
        public String  ContatoRecebimento;
        public String  Transportadora;
        public String  TipoFrete;
        public String  CondicaoPagamento;
        public String  FormaPagamento;
        public Decimal DescontoCliente;
        public String  GrauRiscoCliente;
        public String  SaldoFinanceiro;
        public String  GeraBoleto;
        public Decimal LimiteCredito;
        public Date    VencimentoLimiteCredito;
        public String  TabelaPrecoCliente;
        public String  ClasseCreditoCliente;
        public Date    DataCadastro;
        public String  NomeGrupoCliente;
        public String  CodigoGrupoCliente;
        public String  Armazem;
        public String  RegistroMedico;
        public String  Deletado;
        public String  TipoRegistro;
        public String CodigoRegiao;
        public String Cnae;
        public String Classe;
        public List<ContactINData> Contatos;

        public Account serialize(Map<String, Id> lookups){

            // Returning Object with Fields.
            Account acc = new Account();
            if (lookups.get('Usuario' + this.ProprietarioConta) != null) {
                acc.OwnerId                = lookups.get('Usuario' + this.ProprietarioConta);
            }
            if (lookups.get('GrupoCliente' + this.CodigoGrupoCliente) != null) {
                acc.GrupoCliente__c        = lookups.get('GrupoCliente' + this.CodigoGrupoCliente);
            }
            acc.ParentId                   = lookups.get('ContaPai' + this.ContaPai);
            acc.Name                       = this.NomeCliente;
            acc.CodigoCliente__c           = this.CodigoCliente;
            acc.LojaCliente__c             = this.Loja;
            acc.NomeFantasia__c            = this.NomeFantasia;

            if(String.isNotBlank(this.CGC)){
                this.CGC = StringUtils.removeNonNumericCharacters(this.CGC);
                if(this.CGC.length() >= 14){
                    this.Tipo = 'Jurídica';
                    acc.CNPJ__c = this.CGC;
                } else if(this.CGC.length() >= 11){
                    this.Tipo = 'Física';
                    acc.CPF__c = this.CGC;
                }
            }

            acc.ExternalID__c              = this.CGC;
            acc.TipoCliente__c             = this.TipoCliente;
            acc.TipoConselho__c            = this.TipoConselho;
            acc.UFRegistroMedico__c        = this.UFRegistroMedico;
            acc.CodigoEspecialidadeMedico__c = this.CodigoEspecialidadeMedico;
            acc.EspecialidadeMedico__c     = this.EspecialidadeMedico;
            acc.Area__c                    = this.Area;
            acc.InscricaoEstadual__c       = this.InscricaoEstadual;
            acc.InscricaoMunicipal__c      = this.InscricaoMunicipal;
            acc.Contribuinte__c            = this.Contribuinte;
            acc.Phone                      = this.Telefone;
            acc.OutroTelefone__c           = this.OutroTelefone;
            acc.Email__c                   = this.Email;
            acc.Website                    = this.SiteWeb;
            acc.KeyAccount__c              = this.KeyAccount;
            acc.Bloqueado__c               = this.Bloqueado;
            //acc.GrupoEconomico__c          = this.GrupoEconômico;
            acc.SegmentoCliente__c         = this.SegmentoCliente;
            acc.Observacoes__c             = this.Observacoes;
            acc.BillingStreet              = this.EnderecoCobranca;
            acc.BillingCity                = this.CidadeCobranca;
            acc.BillingState               = this.EstadoCobranca;
            acc.BillingCountry             = this.PaisCobranca;
            acc.BillingPostalCode          = this.CEPCobranca;
            acc.ShippingStreet             = this.EnderecoEntrega;
            acc.ShippingCity               = this.CidadeEntrega;
            acc.ShippingState              = this.EstadoEntrega;
            acc.ShippingCountry            = this.PaisEntrega;
            acc.ShippingPostalCode         = this.CEPEntrega;
            acc.ComplementoEndereco__c     = this.ComplementoEndereco;
            acc.ContatoRecebimento__c      = lookups.get('ContatoRecebimento' + this.ContatoRecebimento);
            acc.Transportadora__c          = this.Transportadora;
            acc.TipoFrete__c               = this.TipoFrete;
            acc.CondicaoPagamento__c       = lookups.get('CondicaoPagamento' + this.CondicaoPagamento);
            acc.FormaPagamento__c          = this.FormaPagamento;
            acc.DescontoCliente__c         = this.DescontoCliente;
            acc.GrauRisco__c               = this.GrauRiscoCliente;
            acc.Titulos__c                 = this.SaldoFinanceiro;
            // acc.SaldoFinanceiroAberto__c   = this.SaldoFinanceiro;
            acc.LimiteCredito__c           = this.LimiteCredito;
            acc.VencimentoLimiteCredito__c = this.VencimentoLimiteCredito;
            acc.TabelaPrecos__c            = lookups.get('TabelaPreco' + this.TabelaPrecoCliente);
            acc.ClasseCredito__c           = this.ClasseCreditoCliente;
            acc.DataCadastro__c            = this.DataCadastro;
            acc.NomeGrupoClientes__c       = this.NomeGrupoCliente;
            acc.CodigoGrupoClientes__c     = this.CodigoGrupoCliente;
            acc.Armazem__c                 = this.Armazem;
            acc.NumeroRegistro__c          = this.RegistroMedico;
            acc.Deletado__c                = this.Deletado == 'true' ? true : false;
            acc.GeraBoleto__c              = this.GeraBoleto == 'S' ? true : false;
            acc.CodigoRegiao__c            = this.CodigoRegiao;
            acc.CNAE__c                    = this.Cnae;
            acc.Classe__c                  = this.Classe;

            if (String.isNotEmpty(this.TipoRegistro)) {

                acc.RecordTypeID           = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PreConta').getRecordTypeId();

            } else {
                
                if(this.RegistroMedico != null && this.RegistroMedico != ''){
                    acc.RecordTypeID           = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Medico').getRecordTypeId();
                    acc.ExternalID__c          = this.RegistroMedico + '_' + this.TipoConselho + '_' + this.UFRegistroMedico;
                }else{
                    acc.RecordTypeID           = this.Tipo == 'Física' ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PessoaFisica').getRecordTypeId() : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PessoaJuridica').getRecordTypeId();
                }
            }

           

            return acc;
        }

        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'Name',
                'ExternalId__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class ContactINData implements FieldData {

        public String ExternalId;
        public String Nome; 
        public String Sobrenome;
        public String NomeConta;
        public String Cargo;
        public String QualCargo;
        public String Departamento;
        public String QualDepartamento;
        public Date   DataAniversario;
        public String Observacoes;
        public String GrauInfluencia;
        public String Celular;
        public String Telefone;
        public String TipoTelefone;
        public String Skype;
        public String Email;
        public String RedeSocial;

        public Contact serialize(Map<String, Id> lookups){

            // Returning Object with Fields.
            return new Contact(      
                ExternalId__c       = this.ExternalId,
                FirstName           = this.Nome,
                LastName            = this.Sobrenome,
                AccountId           = lookups.get('Conta'+this.NomeConta),
                Cargo__c            = this.Cargo,
                Title               = this.QualCargo,
                Departamento__c     = this.Departamento,
                Department          = this.QualDepartamento,
                Birthdate           = this.DataAniversario,
                Description         = this.Observacoes,
                //GrauInfluencia__c   = this.GrauInfluencia,
                MobilePhone         = this.Celular,
                Phone               = this.Telefone,
                TipoTelefone__c     = this.TipoTelefone,
                Skype__c            = this.Skype,
                Email               = this.Email,
                RedeSocial__c       = this.RedeSocial
            );
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'LastName'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class LabOrderINData implements FieldData {
        public String CgcCli;
        public String PedidoIntegrador;
        public String TpInteg;
        public String Laboratorio;
        public String Tabela;
        public String Inconsistencias;
        public String CondicaoPagamento;
        public String Obs_NF;
        public List<ItensINData> Itens;
        public List<LabSonOrderINData> Filhos;
        public ApprovalINData Aprovacoes;
        
        public Order serialize(Map<String, Id> lookups){
            // Returning Object with Fields.
            Order ord = new Order();
            ord.CodigoIntegradora__c = this.PedidoIntegrador;
            ord.ExternalId__c        = this.PedidoIntegrador;
            ord.AccountId            = lookups.get('Conta' + this.CgcCli?.trim());
            ord.Pricebook2Id         = Test.isRunningTest() ? Test.getStandardPricebookId() : (lookups.containsKey('CatalogoPreco' + this.Tabela?.trim()) ? lookups.get('CatalogoPreco' + this.Tabela?.trim()) : lookups.get('CatalogoPrecoPadrao'));
            ord.Pricebook2Id         = ord.Pricebook2Id == null ? lookups.get('CatalogoPrecoPadrao') : ord.Pricebook2Id;
            ord.TipoIntegradora__c   = this.TpInteg;
            ord.Type                 = this.Itens[0].TpOper;
            ord.Laboratorio__c       = this.Laboratorio;
            ord.MensagemNF__c        = this.Obs_NF;
            ord.EffectiveDate        = date.today();
            ord.CondicaoPagamento__c = lookups.get('CondicaoPagamento' + this.CondicaoPagamento?.trim()) != null ? lookups.get('CondicaoPagamento' + this.CondicaoPagamento?.trim()) : lookups.get('CondicaoPagamentoCliente');
            ord.Status               = 'Pedido com inconsistências';
            ord.RecordTypeId         = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();
            return ord;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'CodigoIntegradora__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'CodigoIntegradora__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class ItensINData implements FieldData {
        public String Tabela;
        public String PedidoPai;
        public String Produto;
        public String TpOper;
        public Decimal Quantidade;
        public Decimal PrecoTabela;
        public String  EntradaTabelaPreco;
        public String  CondPag;

        public OrderItem serialize(Map<String, Id> lookups){
            Id priceId = lookups.get('CatalogoPedido' + this.PedidoPai.trim());

            OrderItem ordItem = new OrderItem();
            ordItem.OrderId          = lookups.get('PedidoPai' + this.PedidoPai);
            ordItem.ExternalId__c    = this.PedidoPai + this.Produto;
            system.debug('Produto: ' + this.Produto);
            system.debug('this.Produto get: ' + lookups.get('Produto' + this.Produto));
            //ordItem.Product2Id       = lookups.get('Produto' + this.Produto);
            ordItem.PricebookEntryId = lookups.containsKey('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)+priceId) ? lookups.get('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)+priceId) : lookups.get('TabelaPreco' +this.EntradaTabelaPreco+priceId) ;            
            if (lookups.get('ItemPedido' + this.PedidoPai + this.Produto) == null) {
                ordItem.Product2Id       = lookups.containsKey('Produto' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)) ? lookups.get('Produto' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)) : lookups.get('Produto' + this.EntradaTabelaPreco) ;
                //ordItem.ListPrice        = this.PrecoTabela;
            }else{ 
                ordItem.PricebookEntryId = lookups.get('ItemPedidoPrice' + (this.PedidoPai + this.Produto).trim());  
            }
            ordItem.unitPrice        = 0;   
            ordItem.ValorCx__c       = 0;
            ordItem.ValorUN__c       = 0;
            ordItem.Quantity         = this.Quantidade;
            return ordItem;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'ExternalId__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class LabSonOrderINData implements FieldData {
        public String PedidoIntegrador;
        public String Pedido;
        public String PedidoPai;
        public String Cnpj_CD;
        public String NomeCD;
        public String CgcCli;
        public String TpOper;
        public String CondicaoPagamento;
        public String Tabela;
        public String Laboratorio;
        public String Tipo;
        public List<LabSonOrderItemINData> Itens;
        
        public Order serialize(Map<String, Id> lookups){
            // Returning Object with Fields.
            Order ord = new Order();
            ord.CodigoIntegradora__c = this.Pedido + '_' + this.PedidoIntegrador;
            ord.ExternalId__c        = this.Pedido;
            ord.AccountId            = lookups.get('Conta' + this.CgcCli?.trim());
            ord.Pricebook2Id         = Test.isRunningTest() ? Test.getStandardPricebookId() : (lookups.containsKey('CatalogoPreco' + this.Tabela?.trim()) ? lookups.get('CatalogoPreco' + this.Tabela?.trim()) : lookups.get('CatalogoPrecoPadrao'));
            ord.Pricebook2Id         = ord.Pricebook2Id == null ? lookups.get('CatalogoPrecoPadrao') : ord.Pricebook2Id;
            ord.CNPJCD__c            = this.Cnpj_CD;
            ord.CentroDistribuicao__c= this.NomeCD;
            ord.Type                 = this.TpOper;
            ord.CondicaoPagamento__c = lookups.get('CondicaoPagamento' + this.CondicaoPagamento?.trim()) != null ? lookups.get('CondicaoPagamento' + this.CondicaoPagamento?.trim()) : lookups.get('CondicaoPagamentoCliente');
            ord.EffectiveDate        = date.today();
            ord.PedidoPai__c         = lookups.get('PedidoPai' + this.PedidoPai?.trim());
            ord.Laboratorio__c       = this.Laboratorio; // lab pedido pai
            ord.Status               = 'Pai - Em aprovação';
            ord.RecordTypeId         = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId();
            return ord;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'CodigoIntegradora__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'CodigoIntegradora__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class LabSonOrderItemINData implements FieldData {
        public String Chave;
        public String Produto;
        public String PedidoPai;
        public Decimal QtdAtendida;
        public Decimal Preco;
        public Decimal PrecoTabela;
        public String Tabela;
        public String PedidoFilho;
        public String Cnpj_CD;
        public String EntradaTabelaPreco;
        
        public OrderItem serialize(Map<String, Id> lookups){
            Id priceId = lookups.get('CatalogoPedido' + this.PedidoPai.trim());     
            OrderItem ordItem = new OrderItem();
            system.debug(this.PedidoFilho);
            ordItem.CNPJCD__c        = this.Cnpj_CD;
            ordItem.OrderId          = lookups.get('PedidoFilho' + this.PedidoFilho);
            ordItem.ExternalId__c    = 'Filho_' + this.Chave;
            ordItem.PricebookEntryId = lookups.containsKey('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.Produto)+priceId) ? lookups.get('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.Produto)+priceId) : lookups.get('TabelaPreco' +this.Produto+priceId) ;            
            if (lookups.get('ItemPedido' + this.PedidoPai + this.Produto) == null) {
                ordItem.Product2Id       = lookups.containsKey('Produto' + IntegrationOrderItemIN.getProdCode(this.Produto)) ? lookups.get('Produto' + IntegrationOrderItemIN.getProdCode(this.Produto)) : lookups.get('Produto' + this.Produto) ;
                //ordItem.ListPrice        = this.PrecoTabela;
            }else{ 
                ordItem.PricebookEntryId = lookups.get('ItemPedidoPrice' + (this.PedidoPai + this.Produto).trim());  
            }
            ordItem.unitPrice        = this.Preco;            
            ordItem.ValorCx__c       = this.Preco;
            ordItem.ValorUN__c       = this.Preco;
            ordItem.Quantity         = this.QtdAtendida;
            return ordItem;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'ExternalId__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class ApprovalINData {
        public Boolean Comercial;
        public Boolean Pricing;
    }

    global class OrderINData implements FieldData {
        
        public String  CodigoPedido;
        public Date    DataEmissao;
        public Date    DataEntrega;
        public String  Conta;
        public String  EnderecoEntrega;
        public String  TipoFrete;
        public String  TipoOperacao;
        public String  CondicaoPagamento;
        public String  CatalogoPreco;
        public Decimal ValorTotal;
        public Decimal Margem;
        public String  NomePaciente;
        public String  OrigemPedido;
        public String  Status;
        public String  StatusIntegracao;
        public String  GeraBoleto;
        public String  Observacao;
        public String  CanalEntrada;
        public String  NotaFiscal;
        public String  MensagemNF;
        public List<OrderITemINData> ItensPedido;
        public List<UsuariosCompartilhadosINData> Vendedor;

        public Order serialize(Map<String, Id> lookups){

            // Returning Object with Fields.
            Order ord = new Order();
            ord.ExternalId__c        = this.CodigoPedido;
            ord.EffectiveDate        = this.DataEmissao;
            ord.DataEntrega__c       = this.DataEntrega;
            ord.AccountId            = lookups.get('Conta' + this.Conta?.trim());
            ord.EnderecoEntrega__c   = this.EnderecoEntrega;
            ord.TipoFrete__c         = this.TipoFrete;
            ord.TipoOperacao__c      = this.TipoOperacao;
            ord.CondicaoPagamento__c = lookups.get('CondicaoPagamento' + this.CondicaoPagamento?.trim());
            ord.Pricebook2Id         = Test.isRunningTest() ? Test.getStandardPricebookId() : (lookups.containsKey('CatalogoPreco' + this.CatalogoPreco?.trim()) ? lookups.get('CatalogoPreco' + this.CatalogoPreco?.trim()) : lookups.get('CatalogoPrecoPadrao'));
            ord.Pricebook2Id         = ord.Pricebook2Id == null ? lookups.get('CatalogoPrecoPadrao') : ord.Pricebook2Id ;
            ord.ValorTotal__c        = this.ValorTotal;
            ord.Margem__c            = this.Margem;
            ord.NomePaciente__c      = this.NomePaciente;
            ord.Origem__c            = this.OrigemPedido;
            ord.Status               = this.Status + ' (Histórico)';
            ord.StatusIntegracao__c  = this.StatusIntegracao;
            ord.GerarBoleto__c       = this.GeraBoleto;
            ord.Description          = this.Observacao;
            ord.CanalEntrada__c      = this.CanalEntrada;
            ord.NumeroNotaFiscal__c  = this.NotaFiscal;
            ord.MensagemNF__c        = this.MensagemNF;
            ord.RecordTypeId         = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoHistorico').getRecordTypeId();
            return ord;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'ExternalId__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class OrderItemINData implements FieldData {

        public String  CodigoPedido;
        public String  CodigoItemPedido;
        public String  DescricaoProduto;
        public Decimal Quantidade;
        public Decimal PrecoTabela;
        public Decimal PrecoUnitario;
        public Decimal Margem;
        public String  Vendedor;
        public Decimal PrecoTotal;
        public String  EntradaTabelaPreco;

        public OrderItem serialize(Map<String, Id> lookups){

            Id priceId = lookups.get('CatalogoPedido' + this.CodigoPedido.trim());
            // Returning Object with Fields.
            OrderItem ordItem = new OrderItem();
            ordItem.OrderId          = lookups.get('Pedido' + this.CodigoPedido.trim());
            ordItem.ExternalId__c    = this.CodigoItemPedido;
            ordItem.Quantity         = this.Quantidade;
            ordItem.UnitPrice        = this.PrecoUnitario;
            ordItem.Margem__c        = this.Margem;
            ordItem.Vendedor__c      = lookups.get('Vendedor' + this.Vendedor);
            ordItem.PrecoTotal__c    = this.PrecoTotal;
            ordItem.PricebookEntryId = lookups.containsKey('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)+priceId) ? lookups.get('TabelaPreco' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)+priceId) : lookups.get('TabelaPreco' +this.EntradaTabelaPreco+priceId) ;            
            if (lookups.get('ItemPedido' + this.CodigoItemPedido) == null) {
                ordItem.Product2Id       = lookups.containsKey('Produto' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)) ? lookups.get('Produto' + IntegrationOrderItemIN.getProdCode(this.EntradaTabelaPreco)) : lookups.get('Produto' + this.EntradaTabelaPreco) ;
                ordItem.ListPrice        = this.PrecoTabela;
            }else{ 
                ordItem.PricebookEntryId = lookups.get('ItemPedidoPrice' + this.CodigoItemPedido.trim());  
            }
            return ordItem;
        }
        
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'OrderId'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }

    global class UsuariosCompartilhadosINData implements FieldData {
        public String CodigoPedido;
        public String Vendedor;

        public UsuariosCompartilhados__c serialize(Map<String, Id> lookups){

            // Returning Object with Fields.
            UsuariosCompartilhados__c sharedUsers = new UsuariosCompartilhados__c();
            // return new OrderItem(
            sharedUsers.Pedido__c = lookups.get('Pedido' + this.CodigoPedido);
            sharedUsers.Usuario__c = lookups.get('Vendedor' + this.Vendedor);
            sharedUsers.ExternalId__c = this.CodigoPedido + '_' + this.Vendedor;
            // );
            return sharedUsers;
        }
        //Required fields for integration
        public List<String> getRequiredFields(){
            //Example
            return new List<String>{
                'Pedido__c',
                'Usuario__c'
            };
        }

        //ExternalId field
        public String getFieldKey(){
            return 'ExternalId__c';
        }
        
        //Id field
        public String getFieldId() {
            return 'Id';
        }
    }



    //Response structure
    global virtual class Response {
        public String  idSalesforce;
        public String  externalCode;
        public String  errorMessage;
        public Boolean status;
        public String  sObjectType;
        
        public void success(String idSalesforce, String externalCode, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalCode = externalCode;
            this.status       = true;
            this.SObjectType  = sObjectType;
        }
        
        public void error(String externalCode, String errorMessage, String sObjectType){
            this.externalCode = externalCode;
            this.status       = false;
            this.errorMessage = errorMessage;
            this.SObjectType  = sObjectType;
        }

        public void error(String idSalesforce, String externalCode, String errorMessage, String sObjectType){
            this.idSalesforce = idSalesforce;
            this.externalCode = externalCode;
            this.status       = false;
            this.errorMessage = errorMessage;
            this.SObjectType  = sObjectType;
        }
    }
    
    //Response structure for integration of parent and child objects
    global class ResponseParent extends Response {
        public List<TemplateDataIntegrationFields.Response> items;
    }

}