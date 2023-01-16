public class BudgetPortalPDFController {

    public Orcamento orcamento {get; set;}
    public Map<String, List<Resposta>> Respostas {get; set;}
    public Map<String, TeamMember> membrosTime {get; set;}
    public List<CentroDistribuicao> CentrosDistribuicao {get; set;}
    public String FileName {get; set;}

    public BudgetPortalPDFController(ApexPages.StandardController stdController) {
        try {           

            Integer respI = 0;
            Set<String> quantTotal = new Set<String>();
            Map<String, Set<String>> quantRespondidos = new Map<String, Set<String>>();
            Map<String, List<Decimal>> valorTotal = new Map<String, List<Decimal>>();
            Map<String, List<Resposta>> respWrapper = new Map<String, List<Resposta>>();
            Map<String, TeamMember> teamWrapper = new Map<String, TeamMember>();

            Map<String, String> categoriaMap = Utils.getPicklistApi(Product2.CategoriaComercial__c);

            List<Opportunity> oppList = [
                SELECT Name, Integradora__c,NameFormula__c,NumeroOrcamento__c, IdIntegrator__c, ExternalPortal__c, Regiao__c,
                    Category__c, DataVencimento__c, Account.Name, CNPJ__c, ContactName__c,
                    QuantidadeItensTotal__c, Mesa__c, CondicaoPagamento__r.Name, TabulacaoN1__c, TabulacaoN2__c,
                    EnderecoEntregaPedido__c, TermosCliente__c, ObservacoesCliente__c, TotalPortal__c, StageName
                FROM Opportunity
                WHERE Id = :stdController.getRecord().Id
            ];
            Opportunity opp = !oppList.isEmpty() ? oppList[0] : null;
            this.FileName = opp.IdIntegrator__c;
            Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + this.FileName+'.pdf' );

            List<QuoteItem__c> qItemList = [
                SELECT Name, CustomerDescription__c,SequenciaOC__c, Product__r.Name, Product__r.Nomefornecedor__c, Product__r.ExternalId__c, Status__c,
                    Categoria__c, OpportunityLineItem__r.CNPJCD__c, CustomerMeasurementUnit__c, Quantity__c,
                    TabulacaoN1__c, OpportunityLineItem__r.ValorPortal__c, Vendedor__c, Vendedor__r.Name, IdCustomer__c
                FROM QuoteItem__c
                WHERE OpportunityId__c = :stdController.getRecord().Id
                AND TabulacaoN1__c != null
                AND Vendedor__r.IsActive = true
                ORDER BY IdCustomer__c
            ];

            List<CondicaoPagamentoPorCD__c> conPagCDList = [
                SELECT CentroDistribuicao__c, CNPJCD__c, CloseDate__c, PrazoValidade__c, PrazoEntrega__c,
                CondicaoPagamentoPL__c, MinimumBilling__c, FretePicklist__c, ObservacoesLongText__c
                FROM CondicaoPagamentoPorCD__c
                WHERE Orcamento__c = :stdController.getRecord().Id
            ];

            Map<String, OpportunityTeamMember> oppTeamMapByUser = new Map<String, OpportunityTeamMember>();
            List<OpportunityTeamMember> oppTeamMemberList = [
                SELECT UserId, User.Name, TabulacaoN1__c, TabulacaoN2__c
                FROM OpportunityTeamMember
                WHERE OpportunityId = :stdController.getRecord().Id
                AND User.IsActive = true
                
            ];
            for(OpportunityTeamMember opptm : oppTeamMemberList){
                oppTeamMapByUser.put(opptm.UserId, opptm);
            }

            this.orcamento = new Orcamento(opp);
            if(this.orcamento != null) this.orcamento.TotalValorRespostas = 0;

            for(QuoteItem__c qitem :qItemList){
                Integer qinit = quantTotal.size();
                if(respWrapper.get(qitem.Vendedor__c) == null){
                    respWrapper.put(qitem.Vendedor__c, new List<Resposta>());
                }
                quantTotal.add(qItem.IdCustomer__c);
                
                Resposta resp = new Resposta(qitem, opp);
                if(qinit < quantTotal.size()) respI++;
                if(qitem.Product__c != null && qitem.OpportunityLineItem__c != null && qitem.OpportunityLineItem__r.CNPJCD__c != null){
                    if(quantRespondidos.get(qitem.OpportunityLineItem__r.CNPJCD__c) == null){
                        
                        quantRespondidos.put(qitem.OpportunityLineItem__r.CNPJCD__c, new Set<String>());
                        valorTotal.put(qitem.OpportunityLineItem__r.CNPJCD__c, new List<Decimal>());
                    }
                    
                    quantRespondidos.get(qitem.OpportunityLineItem__r.CNPJCD__c).add(qItem.IdCustomer__c);
                    valorTotal.get(qitem.OpportunityLineItem__r.CNPJCD__c).add(resp.ValorTotal);
                }

                resp.IdItem = qItem.IdCustomer__c;
                this.orcamento.TotalValorRespostas += resp.ValorTotal;
                this.orcamento.Vendedor = qItem.Vendedor__r.Name;

                respWrapper.get(qitem.Vendedor__c).add(resp);
                if(teamWrapper.get(qitem.Vendedor__c) == null){
                    teamWrapper.put(qitem.Vendedor__c, new TeamMember(oppTeamMapByUser.get(qitem.Vendedor__c)));
                    teamWrapper.get(qitem.Vendedor__c).BUsSet.add(categoriaMap.get(qitem.Categoria__c));
                }else{
                    teamWrapper.get(qitem.Vendedor__c).BUsSet.add(categoriaMap.get(qitem.Categoria__c));
                }
                
            }
            this.Respostas = respWrapper;
            this.membrosTime = teamWrapper;

            List<CentroDistribuicao> CDWapper = new List<CentroDistribuicao>();
            for(CondicaoPagamentoPorCD__c conPagCD : conPagCDList){
                CentroDistribuicao centDisp = new CentroDistribuicao(conPagCD);
                centDisp.QuantidadeRespondidos = quantRespondidos.get(conPagCD.CnpjCd__c) != null ? quantRespondidos.get(conPagCD.CnpjCd__c).size() : 0;
                centDisp.QuantidadeTotalItens = quantTotal.size();
                centDisp.ValorTotalItens = 0;
                List<Decimal> valTotByCd = valorTotal.get(conPagCD.CnpjCd__c);
                if(valTotByCd != null){
                    for(Decimal val : valTotByCd){

                        centDisp.ValorTotalItens += val;
                    }
                }
                CDWapper.add(centDisp);
            }
            this.CentrosDistribuicao = CDWapper;
        } catch (Exception e) {
            ExceptionUtils.debug(e);
        } 
    }

    public static List<Messaging.EmailFileAttachment> buildEmailAttachment(String oppId, String fileName){
        PageReference pdf = Page.BudgetPortalPDF;

        pdf.getParameters().put('Id', oppId);
        pdf.setRedirect(true);

        Blob b = Test.isRunningTest() ? blob.valueOf('Unit.Test') : pdf.getContent();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(fileName+'.pdf');
        efa.setBody(b);
        return new List<Messaging.EmailFileAttachment>{efa};
    }

    public class Orcamento {
        
        public String Nome {get; set;}
        public String Integradora {get; set;}
        public String IdIntegrador {get; set;}
        public String IdPortal {get; set;}
        public String Regiao {get; set;}
        public String Categoria {get; set;}
        public String DataVencimento {get; set;}
        public String TituloOrcamento {get; set;}
        public String NumeroOrcamento {get; set;}
        
        public String Cliente {get; set;}
        public String CNPJ {get; set;}
        public String NomeContato {get; set;}
        public Decimal QuantidadeItens {get; set;}
        public String CondicaoPagCliente {get; set;}
    
        public String TabulacaoN1 {get; set;}
        public String TabulacaoN2 {get; set;}
    
        public String EnderecoEntrega {get; set;}
        public String TermosCliente {get; set;}
        public String ObservacoesCliente {get; set;}
        public Decimal TotalPortal {get; set;}
    
        public String Vendedor {get; set;}
        public String BU {get; set;}
        public Integer TotalQuantidadeRespostas {get; set;}
        public Decimal TotalValorRespostas {get; set;}
    
        public String Status {get; set;}

        public Orcamento(Opportunity opp) {
            if(opp != null){

                this.Nome = opp.Name != null ? opp.Name : '';
                this.Integradora = opp.Integradora__c != null ? opp.Integradora__c : '';
                this.IdIntegrador = opp.IdIntegrator__c != null ? opp.IdIntegrator__c : '';
                this.IdPortal = opp.ExternalPortal__c != null ? opp.ExternalPortal__c : '';
                this.Regiao = opp.Regiao__c != null ? opp.Regiao__c : '';
                this.Categoria = opp.Category__c != null ? opp.Category__c : '';
                this.DataVencimento = opp.DataVencimento__c != null ? opp.DataVencimento__c.format('dd/MM/yyyy hh:mm') : '';
                this.TituloOrcamento = opp.NameFormula__c != null ? opp.NameFormula__c : '';
                this.NumeroOrcamento = opp.NumeroOrcamento__c != null ? opp.NumeroOrcamento__c : '';
                this.Cliente = opp.Account != null ? opp.Account.Name : '';
                this.CNPJ = opp.CNPJ__c != null ? opp.CNPJ__c : '';
                this.NomeContato = opp.ContactName__c != null ? opp.ContactName__c : '';
                this.QuantidadeItens = opp.QuantidadeItensTotal__c != null ? opp.QuantidadeItensTotal__c : 0;
                this.CondicaoPagCliente = opp.CondicaoPagamento__c != null ? opp.CondicaoPagamento__r.Name : '';
                this.TabulacaoN1 = opp.TabulacaoN1__c != null ? opp.TabulacaoN1__c : '';
                this.TabulacaoN2 = opp.TabulacaoN2__c != null ? opp.TabulacaoN2__c : '';
                this.EnderecoEntrega = opp.EnderecoEntregaPedido__c != null ? opp.EnderecoEntregaPedido__c : '';
                this.TermosCliente = opp.TermosCliente__c != null ? opp.TermosCliente__c : '';
                this.ObservacoesCliente = opp.ObservacoesCliente__c != null ? opp.ObservacoesCliente__c : '';
                this.TotalPortal = opp.TotalPortal__c != null ? opp.TotalPortal__c : 0;
                this.Status = opp.StageName != null ? opp.StageName : '';
            }
        }
    }

    public class Resposta {

        public String IdItem {get; set;} 
        public String ProdutoSolicitado {get; set;}
        public String SequenciaOc {get; set;}
        public String CodigoElfa {get; set;}
        public String ProdutoElfa {get; set;}
        public String MarcaProdutoElfa {get; set;}
        public String UnidadedeMedida {get; set;}
        public Decimal QuantidadeSolicitada {get; set;}
        public String tabulacao {get; set;}
        public Decimal PrecoUnitario {get; set;}
        public Decimal ValorTotal {get; set;}

        public Resposta(QuoteItem__c qItem, Opportunity opp){
            this.ProdutoSolicitado = opp.StageName == 'RESPONDIDO' && qItem.Status__c == 'QUALIFICADO' ? qitem.CustomerDescription__c +' *' : qitem.CustomerDescription__c;

            if(qitem.Product__c != null){
                this.ProdutoElfa = qitem.Product__r.Name;
                this.MarcaProdutoElfa = qitem.Product__r.Nomefornecedor__c;
                this.CodigoElfa = qItem.Product__r.ExternalId__c != null ? qItem.Product__r.ExternalId__c:'';
            }
            this.SequenciaOc = qitem.SequenciaOC__c;
            this.UnidadedeMedida = qitem.CustomerMeasurementUnit__c;
            this.QuantidadeSolicitada = qitem.Quantity__c != null ? qItem.Quantity__c : 0;
            this.tabulacao = qitem.TabulacaoN1__c;
            this.PrecoUnitario =  qItem.OpportunityLineItem__r?.ValorPortal__c != null ? qItem.OpportunityLineItem__r.ValorPortal__c.setScale(6, RoundingMode.HALF_UP) : 0;
            this.ValorTotal = (this.QuantidadeSolicitada * this.PrecoUnitario).setScale(6, RoundingMode.HALF_UP);
            //Quantidade solicitada poder ser != da quantidade ofertada (Verificar com Piter)
        }
    }

    public class CentroDistribuicao {

        public String Nome {get; set;}
        public Integer QuantidadeRespondidos {get; set;}
        public Integer QuantidadeTotalItens {get; set;}
        public Decimal ValorTotalItens {get; set;}
        public Date DataValidade {get; set;}
        public Decimal PrazoValidade {get; set;} 
        public Decimal PrazoEntrega {get; set;}
        public String CondicaoPagamento {get; set;}
        public Decimal FaturamentoMinimo {get; set;}
        public String TipoFrete {get; set;}
        public String Observacoes {get; set;}

        public CentroDistribuicao(CondicaoPagamentoPorCD__c conPagCD){
            if(conPagCD != null){
                this.Nome = conPagCD.CentroDistribuicao__c != null ? conPagCD.CentroDistribuicao__c : '';
                this.DataValidade = conPagCD.CloseDate__c != null ? conPagCD.CloseDate__c : Date.newInstance(01, 01, 1971);
                this.PrazoValidade = conPagCD.PrazoValidade__c != null ? conPagCD.PrazoValidade__c : 0;
                this.PrazoEntrega = conPagCD.PrazoEntrega__c != null ? conPagCD.PrazoEntrega__c : 0;
                this.CondicaoPagamento = conPagCD.CondicaoPagamentoPL__c != null ? conPagCD.CondicaoPagamentoPL__c : '';
                this.FaturamentoMinimo = conPagCD.MinimumBilling__c != null ? conPagCD.MinimumBilling__c : 0;
                this.TipoFrete = conPagCD.FretePicklist__c != null ? conPagCD.FretePicklist__c : '';
                this.Observacoes = conPagCD.ObservacoesLongText__c != null ? conPagCD.ObservacoesLongText__c : '';
            }
        }
    }

    public class TeamMember {
        public String Id {get; set;}
        public String Name {get; set;}
        public String TabulacaoN1 {get; set;}
        public String TabulacaoN2 {get; set;}
        public Set<String> BUsSet{get; set;}
        public String BUsText {get{
            return !BUsSet.isEmpty() ? String.join((Iterable<String>)BUsSet, ', ') : '';
        }}
        public TeamMember(OpportunityTeamMember tMember){
            this.Id = tMember.UserId;
            this.Name = tMember.User.Name;
            this.TabulacaoN1 = tMember.TabulacaoN1__c != null ? tMember.TabulacaoN1__c :'Sem tabulação';
            this.TabulacaoN2 = tMember.TabulacaoN2__c != null ? tMember.TabulacaoN2__c :'Sem tabulação';
            this.BUsSet = new Set<String>();
        }
    }
}
