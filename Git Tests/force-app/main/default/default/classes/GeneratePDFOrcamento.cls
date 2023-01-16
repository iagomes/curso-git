public class GeneratePDFOrcamento /*implements IGenerateDocument*/{

    public Orcamento orcamento {get; set;}
    
    public GeneratePDFOrcamento(){}

    public GeneratePDFOrcamento(ApexPages.StandardController stdController) {
        // try {
            List<Opportunity> oppList = [
                SELECT Id, Name, FormaPagamento__c, CondicaoPagamento__r.Name, CloseDate, CNPJ__c, Description, CreatedBy.Name, CodigoLoja__c,Amount,Filtro_PDF__c,
                ContatoOrcamento__r.Name ,ContatoOrcamento__r.Email,ContatoOrcamento__r.Phone, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode,
                Account.ShippingStreet, Account.ShippingCity,Account.ShippingCountry, Account.ShippingPostalCode,Phone__c, Account.CNPJ__c, Account.CPF__c, Pricebook2.ExternalId__c, CondicaoPagamento__r.ExternalId__c, Observacoes__c
                FROM Opportunity
                WHERE Id = :stdController.getRecord().Id
            ];

            Opportunity opp = oppList[0];
            String prdCode  = Apexpages.currentPage().getParameters().get('prdCode');
            Boolean landScape  = Apexpages.currentPage().getParameters().get('landScape') == 'true';
            
            this.orcamento = new Orcamento(opp, prdCode, landScape);
            System.debug('=================== this.orcamento'+ this.orcamento);          
           
        // } catch (Exception e) {
        //     ExceptionUtils.debug(e);
        // } 
    }
    
    public static void execute(String recordId , String prodCode, Boolean landScape) {

        PageReference pdf;

        if (!landScape) {
            pdf = Page.PDFOrcamento;
            
        }else{
            pdf = Page.PDFOrcamentoPaisagem;

        }

        pdf.getParameters().put('Id', recordId);
        pdf.getParameters().put('prdCode', prodCode);
        pdf.getParameters().put('landScape', landScape ? 'true' : 'false');
        pdf.setRedirect(true);

        Blob blobValue;// = pdf.getContentAsPDF();

        if(Test.isRunningTest()) { 
            blobValue = blob.valueOf('Unit.Test');
        } else {
            blobValue = pdf.getContentAsPDF();
        }

        String base64 = EncodingUtil.base64Encode(blobValue);
        insertPDF(recordId, base64);


    }

    @future
    public static void insertPDF(String recordId , String base64) {

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.versionData = EncodingUtil.base64Decode(base64);
        contentVersion.title = 'Orçamento'+recordId+'.pdf';
        contentVersion.pathOnClient ='orcamento.pdf';
        insert contentVersion;

        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = recordId;
        cDe.ShareType = 'I';
        cDe.Visibility = 'AllUsers';
        insert cDe;  

        ContentVersion cv = [select id from contentversion where contentdocumentid =:conDoc];
        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'ORCAMENTOPDF';
        cd.ContentVersionId =  cv.id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;

        insert cd;
    }

    public class Orcamento {
        
        public String Nome {get; set;}      
        public String DataVencimento {get; set;}
    
        public String Cliente {get; set;}
        public String CNPJ {get; set;}
        public String CodigoCliente {get; set;}
        public String Telefone {get; set;}
        public String FormaPagamento {get; set;}
        public String CondicaoPagamento {get; set;}
    
        public Contact Contato {get; set;}
        public String EnderecoEntrega {get; set;}
        public String EnderecoCobranca {get; set;}
        public String ObservacoesCliente {get; set;}
        public String CriadoPor {get; set;}
        public Decimal total {get; set;}
        public Account conta {get; set;}
        public List<OpportunityLineItem> lstOppItens {get; set;}
        public List<Recommendation> lstOppRecommendation {get; set;}
        public Boolean hasRecommendation {get; set;}
        public FlagFields flags {get; set;}
        public String observacoes {get; set;}
        public String Status {get; set;}

        public Orcamento(Opportunity opp, String prodCode, Boolean landScape) {
            if(opp != null){

                FlagFields flagsAux = new FlagFields();
           
                this.Nome = opp.Name != null ? opp.Name : '';
                this.FormaPagamento = opp.FormaPagamento__c != null ? opp.FormaPagamento__c : '';               
                this.CondicaoPagamento = opp.CondicaoPagamento__r.Name != null ? opp.CondicaoPagamento__r.Name : '';
                this.Contato = opp.ContatoOrcamento__r;
                this.Telefone = opp.Phone__c != null ? opp.Phone__c : '';
                this.DataVencimento = opp.CloseDate != null ?  opp.CloseDate.day() + '/' +  opp.CloseDate.month()  + '/' + opp.CloseDate.year()  /*.format('dd/MM/yyyy hh:mm')*/ : '';
                this.Cliente = opp.Account != null ? opp.Account.Name : '';
                this.CNPJ = opp.CNPJ__c != null ? opp.CNPJ__c : '';
                this.CodigoCliente = opp.CodigoLoja__c != null ? opp.CodigoLoja__c : '';
                this.EnderecoCobranca = !landScape  ? opp.Account.BillingStreet +' '+ opp.Account.BillingCity +' '+  opp.Account.BillingPostalCode : opp.Account.BillingStreet +' '+ opp.Account.BillingCity +' '+  opp.Account.BillingPostalCode;
                this.EnderecoEntrega = !landScape ? opp.Account.ShippingStreet +' '+ opp.Account.ShippingCity +''+  opp.Account.ShippingPostalCode : opp.Account.ShippingStreet +' '+ opp.Account.ShippingCity +' '+  opp.Account.ShippingPostalCode ;
                this.ObservacoesCliente = opp.Description != null ? opp.Description : '';
                this.conta = opp.Account;
                this.CriadoPor = opp.CreatedBy.Name;
                this.total = opp.Amount;
                this.lstOppItens = getItems(opp , flagsAux);
                this.lstOppRecommendation = getRecommmendation(opp, prodCode);
                this.hasRecommendation = this.lstOppRecommendation.size() > 0 ? true : false;
                this.flags = flagsAux;
                this.observacoes = opp.Observacoes__c;
             
            }
        }
    }

    public class Recommendation {

        public String Name {get; set;}      
        public Decimal Estoque {get; set;}      
        public Decimal ValorUnitario {get; set;} 
        public String CentroDistribuicao {get; set;} 
        public String Produto {get; set;}                      
        public String UnidadeMedida {get; set;} 

        public Recommendation(MalhaObject malhaObj,  CdObject cdObj, Map<String, Product2> prodCodeToIdMap) {

            this.Name = malhaObj.codprotheus;
            this.Estoque = cdObj.saldo.setScale(0);
            this.ValorUnitario = cdObj.preco;
            this.CentroDistribuicao = cdObj.filial;
            this.Produto = prodCodeToIdMap.containsKey(malhaObj.codprotheus) ? prodCodeToIdMap.get(malhaObj.codprotheus).ExternalId__c : null;                        
            this.UnidadeMedida = prodCodeToIdMap.containsKey(malhaObj.codprotheus) ? prodCodeToIdMap.get(malhaObj.codprotheus).UnidadeMedida__c : null; 
        }
    }

    public class MalhaObject {
    
        public List<CdObject> cds;
        public String codprotheus;
        public String ean;
    }

    public class CdObject {
    
        public Decimal aliquota;
        public String  foramalha;
        public String  prioridade;
        public String  cnpj;
        public Decimal saldo;
        public Decimal custo;
        public String  cd;
        public String  filial;
        public String  tipopreco;
        public Decimal preco;
        public String  BloqRegionalizacao;
        public String  laboratorio;
        // public List<Object> range;
    }

    public class FlagFields {

        public Boolean PrincipioAtivo {get; set;}    
        public Boolean NumeroAnvisa {get; set;}    
        public Boolean Fornecedor {get; set;}    
        public Boolean ObservacoesComercial {get; set;}  

        public FlagFields(){

            this.PrincipioAtivo = false; 
            this.NumeroAnvisa = false;    
            this.Fornecedor = false;    
            this.ObservacoesComercial = false;  
        }

    }

     public static List<OpportunityLineItem> getItems(Opportunity opp , FlagFields flags){

        String filter = '';

        if(opp.Filtro_PDF__c.equals('Ordem alfabética')){

            filter = 'Product2.name';

        }else if(opp.Filtro_PDF__c.equals('Ordem de inserção')){

            filter = 'CreatedDate';

        }else{

            filter = 'CentroDistribuicao__c';
        }
        
        List<OpportunityLineItem> lstItems = Database.query('SELECT Id, CategoriaComercial__c, CentroDistribuicao__c, ProductCode, ServiceDate, Discount, Description, ForaMalha__c, Fornecedor__c, ItemCampanha__c, JustificativaDesconto__c, Lote__c, MargemAlvo__c, MargemAtual__c, Name, NumeroAnvisa__c, OpportunityId, ListPrice, UnitPrice, TotalPrice, PrincipioAtivo__c, Product2.Description, Product2Id, Quantity, QuantidadeUn__c, ScoreAlvo__c, ScoreAtual__c, Subtotal, Temperatura__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, ValorTotal__c, Vendedor__c, Product2.FatorConversao__c, Product2.Fornecedor__r.Name, Product2.ProductCode, Product2.UnidadeMedida__c, Product2.Name, PricebookEntryId, CNPJCD__c, Product2.CategoriaComercial__c,ObservacoesComercial__c,UnidadeMedidaPDF__c,QuantidadePDF__c, PrecoPDF__c FROM OpportunityLineItem WHERE OpportunityId =  \'' + opp.Id + '\'  ORDER BY '+ filter);

        System.debug('lstItems '+ lstItems);
        for (OpportunityLineItem item : lstItems) {

            if (item.PrincipioAtivo__c != null) {
                flags.PrincipioAtivo = true;
            }

            if (item.NumeroAnvisa__c != null) {
                flags.NumeroAnvisa = true;
            }

            if (item.Product2.Fornecedor__r.Name != null) {
                
                flags.Fornecedor = true;
            }

            if (item.ObservacoesComercial__c != null) {
                
                flags.ObservacoesComercial = true;
            }        
            
            if (!String.isBlank(item.Product2.name) && item.Product2.name.length() > 10) {
                item.Product2.name = breakLineString(item.Product2.name);
            }

            if (!String.isBlank(item.ObservacoesComercial__c) && item.ObservacoesComercial__c.length() > 10) {
                item.ObservacoesComercial__c = breakLineString(item.ObservacoesComercial__c);
            }

            if (!String.isBlank(item.Product2.Description) && item.Product2.Description.length() > 10) {
                item.Product2.Description = breakLineString(item.Product2.Description);
            }
        }
        return lstItems;

     }

     public static List<Recommendation> getRecommmendation(Opportunity opp, String prodCode){


        List<Recommendation> recommendationList = new List<Recommendation>();
        List<String> prodCodeList = prodCode.split(',');
        Map<String, Product2> prodCodeToIdMap = new Map<String, Product2>();

        for (Product2 prod : [SELECT Id, ExternalId__c, Description, CategoriaComercial__c, UnidadeMedida__c FROM Product2 WHERE ExternalId__c IN: prodCodeList]) {
            prodCodeToIdMap.put(prod.ExternalId__c, prod);
        }
        System.debug(prodCodeToIdMap);
        Boolean hasPermissionERB = false;

        for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
            hasPermissionERB = true;
        }

        List<Object> malhaResult = null;
        if (hasPermissionERB) {
            malhaResult = OrderScreenController.getMalha(opp.Account.CNPJ__c != null ? opp.Account.CNPJ__c : opp.Account.CPF__c, prodCode, true, opp.Pricebook2.ExternalId__c, opp.CondicaoPagamento__r.ExternalId__c, false);
        }

      
        if (hasPermissionERB) {
            for (Object obj: malhaResult) {
                MalhaObject malhaObj = (MalhaObject) JSON.deserialize(JSON.serialize(obj), MalhaObject.class);
                System.debug('malhaObj: ' + malhaObj);
                if (malhaObj != null && malhaObj.cds != null) {
                    for (CdObject cdObj : malhaObj.cds) {
                        if (cdObj.saldo == 0) 
                            continue;
                            recommendationList.add(new Recommendation(malhaObj, cdObj, prodCodeToIdMap)); 
                        break;
                    }                    
                }
            }
           
        }

        return recommendationList;
        // return [SELECT Id, Name, Produto__r.ProductCode, Produto__r.Description, Produto__r.FatorConversao__c, Produto__r.Fornecedor__r.Name,
        //         Produto__r.UnidadeMedida__c, Produto__r.Name,  Produto__r.CategoriaComercial__c
        //         FROM AnaliseERB__c WHERE Orcamento__c = :oppId];
     }

     public static String breakLineString(String field){
       
        String out      = '';
        Integer aux     = 0;
        Integer index   = 0;
        system.debug(field);
        do{
            if(index < field.length()){
               
                if (aux == 11) {
                    out +=  field.substring(index,index+1)+'\n\n';
                    system.debug('if'+field.substring(index,index+1));
                    aux = 0;
                }else{
                    system.debug('else'+field.substring(index,index+1));
                    out += field.substring(index,index+1);
                }
                index   = index+1;
                aux     = aux+1;
                system.debug('===== '+out);
            }
            
        }while(index < field.length());
       

        return out;
     }
}