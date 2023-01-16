public inherited sharing class BudgetCtrl {
    public inherited sharing class ParamsMalha {
        public String cnpj              {get; set;}
        public String UF                {get; set;}
        public String productCode       {get; set;}
        public Boolean calcMargem       {get; set;}
        public String pricebookExternalId {get; set;}      
        public String condPagamento     {get; set;}
        public Boolean isForaMalha      {get; set;}
    }

    public inherited sharing class ParamsProd {
        public String unidadePrincipal  {get; set;}
        public Decimal quantidadeSolicitada {get; set;}
        public String cdsBloqueados     {get; set;}
        public String accountId         {get; set;}
        public String accountType       {get; set;}
        public String unidadeSecundaria {get; set;}
        public String tipoConversao     {get; set;}
        public String fatorConversao    {get; set;}
    }

    public inherited sharing class Malha {
        public List<MalhaData> cds      {get; set;}
        public String code              {get; set;}
        public String msgErro           {get; set;}
        public String codprotheus       {get; set;}
        public String ean               {get; set;}
    }
    
    public inherited sharing class MalhaData {
        public String TipoIntegradora   {get; set;}
        public Decimal pf               {get; set;}
        public String laboratorio       {get; set;}
        public Boolean EnviaIntegrador  {get; set;}
        public List<Range> range        {get; set;}
        public Boolean BloqRegionalizacao {get; set;}
        public Decimal preco            {get; set;}
        public String tipopreco         {get; set;}
        public String filial            {get; set;}
        public String cd                {get; set;}
        public Decimal custo            {get; set;}
        public Decimal saldo            {get; set;}
        public String cnpj              {get; set;}
        public String prioridade        {get; set;}
        public Boolean foramalha        {get; set;}
        public Decimal aliquota         {get; set;}
    }

    public inherited sharing class Range {}


    public inherited sharing class DistCenter {
        public String id                {get; set;}
        public String nome              {get; set;}
        public String cnpj              {get; set;}
        public Decimal custo            {get; set;}
        public Decimal preco            {get; set;}
        public Decimal aliquota         {get; set;}
        public Decimal precoFabrica     {get; set;}
        public Decimal estoque          {get; set;}
        public String prioridade        {get; set;}
        public Boolean foramalha        {get; set;}
        public String unidadePrincipal  {get; set;}
        public Decimal quantidadeElfa   {get; set;}
        public Decimal valorElfa        {get; set;}
        public Decimal desconto         {get; set;}
        public String validadeMin       {get; set;}
        public Decimal score            {get; set;}
        public Decimal margem           {get; set;}
        public Decimal margemAlvo       {get; set;}
        public Decimal quantidadePortal {get; set;}
        public Decimal valorPortal      {get; set;}
        public Decimal valorTotal       {get; set;}
        public Boolean cdBloqueado      {get; set;}
        public Boolean bloqueioRegional {get; set;}
        public String dataGanho         {get; set;}
        public Decimal valorGanho       {get; set;}
        public String dataPerdido       {get; set;}
        public Decimal valorPerdido     {get; set;}
        public String previsaoEntrada   {get; set;}
        public Decimal quantPrevista    {get; set;}
        public List<Badge> badges       {get; set;}
        public String unidadeSecundaria {get; set;}
        public String conversaoUnidadeTexto {get; set;}
        public Decimal estoqueSecundario {get; set;}
        public Decimal precoSecundario  {get; set;}
        public Decimal precoFabricaSecundario {get; set;}
    }

    public inherited sharing class Badge {
        public String name              {get; set;}
        public Decimal price            {get; set;}
        public String style             {get{
            return 'slds-badge_inverse badge-portal ' + this.name + 'Css';
        }}
        public String label             {get{
            Map<String, String> labelMap = new Map<String, String>{
                'O' => 'Produto OL',
                'A' => 'Acordo Comercial',
                'ContratoShelfLife' => 'Produto Shelflife',
                'Campanha' => 'Campanha Produto',
                'CampanhaVendedor' => 'Campanha Vendedor',
                'ProdutoConsignado' => 'Produto Consignado',
                'ProdutoReservado' => 'Produto Reservado'
            };
                
            return labelMap.get(this.name);
        }}

        public Badge(String name, Decimal price){
            this.name = name;
            this.price = price;
        }
    }

    public inherited sharing class ExtraFields {
        public String oppId             {get;set;}
        public Boolean foraMalha        {get; set;}
        public Decimal fatorConversaoProd {get; set;}
        public String tipoConversaoProd {get; set;}
        public String comentario        {get; set;}
    }

    public inherited sharing class CampaignData {
        public Set<String> cdCodeSet    {get; set;}
        public Decimal price            {get; set;}

        public CampaignData(){
            this.cdCodeSet = new Set<String>();
        }
    }

    public class PicklistOption {
        public Boolean selected {get; set;}
        public String value {get; set;}
        public String label {get; set;}
        
        public PicklistOption(Boolean slc,String param1, String param2 ){
            this.selected = slc;
            this.value = param1;
            this.label = param2;
        }
    }

    public class ProgramacaoEntrega {
        @AuraEnabled public String data;
        @AuraEnabled public String quantidade;
    }

    public class DistCenterDTO {
        public Decimal resp {get;set;}
        public Decimal totItem {get;set;}
        public Double qtdItensTotal {get;set;}
        public String Id {get;set;}
        public String CentroDistribuicao {get;set;}
        public String CNPJCD {get;set;}
        public String FretePicklist {get;set;}
        public String CondicaoPagamentoPL {get;set;}
        public String ObservacoesLongText {get;set;}
        public Date CloseDate {get; set;}
        public Decimal PrazoValidade {get;set;}
        public Decimal PrazoEntrega {get;set;}
        public Decimal MinimumBilling {get;set;}

        public DistCenterDTO(SomatoriaDTO sum, CondicaoPagamentoPorCD__c cd){
            this.resp = sum.resp;
            this.totItem = sum.totItem;
            this.qtdItensTotal = sum.qtdItensTotal;

            this.Id = cd.Id;
            this.CentroDistribuicao = cd.CentroDistribuicao__c;
            this.CNPJCD = cd.CNPJCD__c;
            this.FretePicklist = cd.FretePicklist__c;
            this.CondicaoPagamentoPL = cd.CondicaoPagamentoPL__c;
            this.ObservacoesLongText = cd.ObservacoesLongText__c;
            this.CloseDate = cd.CloseDate__c;
            this.PrazoValidade = cd.PrazoValidade__c;
            this.PrazoEntrega = cd.PrazoEntrega__c;
            this.MinimumBilling = cd.MinimumBilling__c;
        }

        public CondicaoPagamentoPorCD__c build(){
            return new CondicaoPagamentoPorCD__c(
                Id = this.Id,
                CentroDistribuicao__c = this.CentroDistribuicao,
                CNPJCD__c = this.CNPJCD,
                FretePicklist__c = this.FretePicklist,
                CondicaoPagamentoPL__c = this.CondicaoPagamentoPL,
                ObservacoesLongText__c = this.ObservacoesLongText,
                CloseDate__c = this.CloseDate,
                PrazoValidade__c = this.PrazoValidade,
                PrazoEntrega__c = this.PrazoEntrega,
                MinimumBilling__c = this.MinimumBilling
            );
        }
    }
    
    public class SomatoriaDTO  {
        @AuraEnabled
        public Decimal resp             {get; set;}
        @AuraEnabled
        public Decimal totItem          {get; set;}
        @AuraEnabled
        public Double qtdItensTotal      {get; set;}
        
        public SomatoriaDTO(){
            this.resp = 0;
            this.totItem = 0;
            this.qtdItensTotal = 0;
        }
    }
}