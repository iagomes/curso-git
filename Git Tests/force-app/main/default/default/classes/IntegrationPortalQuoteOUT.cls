global without sharing class IntegrationPortalQuoteOUT {
    // public static final String STATUS_NOT_INTEGRATED = 'Não Integrado';
    public static final String STATUS_ERROR = 'Falha na Integração';
    public static final String STATUS_INTEGRATED = 'Integrado';
    public static final Integer MAX_ROWS = 100;

    @future(callout=true)
    public static void sendAsync(Id oppId) {
        send(oppId);
    }

    public static StandardResponse send(Id oppId) {
        OpportunityRequest opportunityReq;
        Opportunity oppData;
        List<Setorizacao__c> setorizacao;
        List<QuoteItem__c> quoteItems;
        List<OpportunityTeamMember> oppTeamMemberListToUpdate = new List<OpportunityTeamMember>();
        HttpRequest req                     = new HttpRequest();
        HttpResponse resp                   = new HttpResponse();
        StandardResponse response           = new StandardResponse();
        Integracoes__c apiSettings          = Integracoes__c.getValues('InformaticaAtualizarCotacao');
        String method                       = apiSettings.Method__c;
        String endpoint                     = apiSettings.Endpoint__c;
        String authorizationHeader          = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiSettings.User__c + ':' + apiSettings.Password__c));

        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setTimeout(120000);
        
        try {
            
            oppData = OpportunitySelector.getInstance().getOpportunityByIdForIntegrationPortalQuoteOUT(oppId);
            setorizacao = [
                SELECT Id, Categoria__c, VendedorSuporte__c, VendedorSuporte__r.Name,
                Vendedor__r.Name, Vendedor__c, Vendedor__r.Email
                FROM Setorizacao__c
                WHERE Conta__c = :oppData.AccountId
                AND Vendedor__r.IsActive = true
                AND VendedorSuporte__r.IsActive = true
            ];
            quoteItems = (List<QuoteItem__c>) getQuoteItemsQuery(oppData).setLimit(MAX_ROWS).toList();
            Boolean lastPage = !(quoteItems.size() == MAX_ROWS && getQuoteItemsQuery(oppData).toCount() > MAX_ROWS);

            opportunityReq = new OpportunityRequest(oppData, setorizacao, quoteItems, lastPage);
            
            String body = JSON.serialize(opportunityReq);
            
            req.setBody(body);
            resp = new Http().send(req);
            
            response.setData('response', resp.getBody());
            
            Boolean hasError = false;
            Opportunity opp = new Opportunity(Id = oppId);

            List<QuoteItem__c> quoteItemToUpdate = new List<QuoteItem__c>();

            if(resp.getStatusCode() != 200 && resp.getStatusCode() != 201){
                
                hasError = true;
                opp.StatusIntegracaoPortalCotacoes__c = STATUS_ERROR;
                opp.MensagemErroIntegracaoPortalCotacoes__c = 'Ocorreu um erro durante o envio da resposta da Cotação para o Portal';
                opp.StageName = STATUS_ERROR;

            } else {

                System.debug('lastPage:::' + JSON.serializePretty(lastPage));
                opp.StageName = 'Aguardando Integração';
                opp.HasChangesUnsync__c = false;
                if(!lastPage){
                    if(!quoteItems.isEmpty()){
                        opp.LastIntegratedItem__c = quoteItems[quoteItems.size() - 1].Id;
                    }
                } else {
                    opp.StatusIntegracaoPortalCotacoes__c = STATUS_INTEGRATED;
                    opp.MensagemErroIntegracaoPortalCotacoes__c = null;
                    opp.LastIntegratedItem__c = null;
                }

                for(OpportunityTeamMember oppTM : oppData.OpportunityTeamMembers){
                    oppTeamMemberListToUpdate.add(new OpportunityTeamMember(Id = oppTM.Id, HasChangesUnsync__c = false));
                }

                Boolean semOferta = true;
                for(QuoteItem__c item: quoteItems){
                    if(item.TabulacaoN1__c == 'Cotado'){
                        semOferta = false;
                        quoteItemToUpdate.add(new QuoteItem__c(Id = item.Id, StatusIntegrationResponse__c = 'Não Integrado'));
                    }else{
                        quoteItemToUpdate.add(new QuoteItem__c(Id = item.Id, StatusIntegrationResponse__c = 'Integrado'));
                    }
                }
                
                if(semOferta){
                    List<QuoteItem__c> qItemCot = [
                        SELECT Id
                        FROM QuoteItem__c 
                        WHERE TabulacaoN1__c = 'Cotado' 
                        AND OpportunityId__c = :opp.Id
                        LIMIT 1
                    ];
                    if(qItemCot.isEmpty()){
                        opp.StageName = 'Respondida';
                    }
                }
            }

            System.debug('opp.LastIntegratedItem__c:::' + opp.LastIntegratedItem__c);
            System.debug('quoteItems:::' + JSON.serializePretty(quoteItems));

            update quoteItemToUpdate;
            update oppTeamMemberListToUpdate;

            response.hasError = hasError;
            
            IntegrationUtils.WSLog('Cotação', 'Outbound', body, resp.getBody(), hasError);

            OpportunityTH.disableTrigger();
            update opp;
            OpportunityTH.enableTrigger();

            if(opp.LastIntegratedItem__c != null){
                System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(0, new List<Id>{opp.Id}));
            }
            sendEmailVDE(oppData, quoteItems, setorizacao);
        } catch (Exception e) {
            response.addError(e);
        }
        return response;
    }

    public static final List<String> quoteItemFields = new List<String>{
        'Id',
        //'IdArtigo__c',
        'IdCustomer__c',
        'IdPortal__c',
        'FatorConversao__c',
        'IdIntegrator__c',
        'Categoria__c',
        'TabulacaoN1__c',
        'TipoConversao__c',
        'Product__r.ExternalId__c',
        'Vendedor__r.CodigoUsuario__c',
        'Status__c',
        'VendedorRespondeu__r.CodigoUsuario__c',
        'Vendedor__r.Name',
        'VendedorRespondeu__r.Name',
        'OpportunityLineItem__c',
        'OpportunityLineItem__r.Id',
        'OpportunityLineItem__r.IdPortal__c',
        'OpportunityLineItem__r.IdArtigo__c',
        'OpportunityLineItem__r.CNPJCD__c',
        'OpportunityLineItem__r.ForaMalha__c',
        'OpportunityLineItem__r.Quantity',
        'OpportunityLineItem__r.UnitPrice',
        'OpportunityLineItem__r.ValorPortal__c',
        'OpportunityLineItem__r.ListPrice',
        'OpportunityLineItem__r.CodigoRastreio__c',
        'OpportunityLineItem__r.Comentarios__c',
        'OpportunityLineItem__r.TabulacaoN1__c',
        'OpportunityLineItem__r.Product2.CategoriaComercial__c',
        'OpportunityLineItem__r.Product2.ExternalId__c',
        'OpportunityLineItem__r.Product2.Fabricante__c',
        'OpportunityLineItem__r.Product2.Fornecedor__c',
        'OpportunityLineItem__r.Product2.Fornecedor__r.ExternalId__c',
        'OpportunityLineItem__r.Product2.Fornecedor__r.Name',
        'OpportunityLineItem__r.Product2.Name',
        'OpportunityLineItem__r.Product2.UnidadeMedida__c',
        'OpportunityLineItem__r.Vendedor__r.CodigoUsuario__c'
    };

    public static QueryBuilder getQuoteItemsQuery(Opportunity opp){
        return new QueryBuilder('QuoteItem__c')
            .addFields(quoteItemFields)
            .addConditions()
            .add(
                new QueryBuilder.ComplexCondition()
                    .andCondition(new QueryBuilder.CompareCondition('OpportunityId__c').eq(opp.Id))
                    .andCondition(new QueryBuilder.InCondition('Status__c').inCollection(new List<String>{'Não Vinculado','Vinculado', 'Respondido', 'Falha na Integração','Aguardando Integração'}))
                    .andCondition(new QueryBuilder.NullCondition('TabulacaoN1__c').notNull())
                    .andCondition(new QueryBuilder.CompareCondition('Id').ignoreConditionsForNullValues().lt(opp.LastIntegratedItem__c))
            )
            .endConditions()
            .addOrderDesc('Id');
    }

    public static void sendEmailVDE(Opportunity opp,List<QuoteItem__c> quoteItems, List<Setorizacao__c> setorizacao){
        try {

            List<Messaging.SingleEmailMessage> emailList  = new List<Messaging.SingleEmailMessage>();
            List<String> subjectValues = new List<String>{    
                opp.CanalEntrada__c,
                opp.idIntegrator__c,
                UserInfo.getName(),
                Datetime.now().format()
            };
            String subjectPattern = 'A cotação {0} - ID {1} foi respondida por {2} em {3}' ;
            String emailSubject = String.format(subjectPattern, subjectValues);
            
            String emailHtmlBody = createEmailTemplateBody(opp, setorizacao, quoteItems);
            List<Messaging.EmailFileAttachment> attachment = BudgetPortalPDFController.buildEmailAttachment(opp.Id, opp.Name);
            for(Setorizacao__c idVds : setorizacao){
                if(idVds.VendedorSuporte__c != UserInfo.getUserId()){
                    continue;
                }
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setSenderDisplayName('Salesforce');
                email.setFileAttachments(attachment);
                email.setBccSender(false);
                email.setTargetObjectId(idVds.Vendedor__c);
                email.setSubject(emailSubject);
                email.setHtmlBody(emailHtmlBody);
                email.saveAsActivity = false;
                emailList.add(email);
            }
            Messaging.reserveSingleEmailCapacity(emailList.size()); 

            if(!Test.isRunningTest()) {
                Messaging.sendEmail(emailList, false);
            }
            
        }  catch (Exception e) {
            ExceptionUtils.debug(e);
        }
    }

    public static String createEmailTemplateBody(Opportunity opp, List<Setorizacao__c> setorizacao, List<QuoteItem__c> quoteItems){
        List<String> Bus = new List<String>();
        List<Object> emailVDESetorFields = new List<Object>{
            String.valueOf(opp.CanalEntrada__c),
            String.valueOf(opp.idIntegrator__c),
            String.valueOf(opp.Account.Name),
            String.valueOf(opp.DataVencimento__c.format()),
            String.valueOf(UserInfo.getName()),
            String.valueOf(Datetime.now().format()),
            String.valueOf(URL.getSalesforceBaseUrl().toExternalForm()),
            String.valueOf(opp.Id)
        };
        String emailBody = String.format(System.Label.EmailVDESetorizado, emailVDESetorFields);
        for(QuoteItem__c qItem : quoteItems){
            Bus.add(qItem.Categoria__c);
        }
        
        for(Setorizacao__c setoriz : setorizacao){
            
            if(setoriz.VendedorSuporte__c == UserInfo.getUserId()){
                emailVDESetorFields[3] = String.valueOf(opp.DataVencimento__c.format());
                emailBody = String.format(System.Label.EmailVDESetorizado, emailVDESetorFields);
                break;
            }else if(Bus.contains(setoriz.Categoria__c)){
                emailVDESetorFields[3] = String.valueOf(opp.DataVencimento__c.format())+' de '+String.valueOf(setoriz.VendedorSuporte__r.Name);
                emailBody = String.format(System.Label.EmailVDESetorizado, emailVDESetorFields);
            }
        }

        return emailBody;
    }

    global class OpportunityRequest{
        public String id;	//621a3853d2568958f9ba7df7 //idportal__C
        public String integradora;	//bionexo
        public String integradoraId;	//180507231 idIntegrator__c
        public Customer cliente; 
        public List<cdItemRequest> cds;
        public List<Tab> tabulacaoByVds;
        public List<OpportunityItemRequest> items;
        public Boolean lastPage = false;

        global OpportunityRequest(Opportunity opp, List<Setorizacao__c> setorizacao, List<QuoteItem__c> quoteItems, Boolean lastPage){
            this.id             = opp.ExternalPortal__c;
            this.integradora    = opp.Integradora__c;
            this.integradoraId  = opp.IdIntegrator__c;
            this.lastPage       = lastPage;
            this.cliente        = new Customer(opp.CNPJ__c);

            this.cds = new List<cdItemRequest>();

            //System.debug('\n\n opp:::\n' + JSON.serializePretty(opp));
            //System.debug('\n\n opp.Condicespagamentospor_CD__r:::\n' + JSON.serializePretty(opp.Condicespagamentospor_CD__r));
            if(!opp.Condicespagamentospor_CD__r.isEmpty()){
                for(CondicaoPagamentoPorCD__c payCon : opp.Condicespagamentospor_CD__r){
                    this.cds.add(new cdItemRequest(payCon));
                }
            }

            this.tabulacaoByVds = new List<Tab>();
            if(!opp.OpportunityTeamMembers.isEmpty()){
                for(OpportunityTeamMember tMember : opp.OpportunityTeamMembers){
                    this.tabulacaoByVds.add(new Tab(tMember));
                }
            }
   
            this.items = new List<OpportunityItemRequest>();

            if(!quoteItems.isEmpty()){
                Map<String,List<QuoteItem__c>> mapItemsByIdPortal = (Map<String,List<QuoteItem__c>>) SObjectUtils.mapObjectsByField(quoteItems, 'IdPortal__c', true);

                for(String idPortal: mapItemsByIdPortal.keySet()){
                    this.items.add(new OpportunityItemRequest(mapItemsByIdPortal.get(idPortal)[0], mapItemsByIdPortal.get(idPortal), opp, setorizacao));
                }
            }
        }
    }    
    
    global class Tab {
        public String tabulacaoN1;	//Respondida
        public String tabulacaoN2;	//Parcialmente
        public String vds;
        public String nome;

        global Tab(OpportunityTeamMember tMember){
            this.tabulacaoN1 = tMember.TabulacaoN1__c != null ? tMember.TabulacaoN1__c : '';
            this.tabulacaoN2 = tMember.TabulacaoN2__c != null ? tMember.TabulacaoN2__c : '';
            this.vds         = tMember.User.CodigoUsuario__c != null ? tMember.User.CodigoUsuario__c : '';
            this.nome        = tMember.User.Name != null ? tMember.User.Name : '';
        }
    }
    
    
    global class Customer {
        public String cnpj;	//34.551.422/0001-77
        
        global Customer(String cnpj){
            this.cnpj = cnpj;
        }
    }
    
    
    global class cdItemRequest {//CondicaoPagamentoPorCD__c
        public Integer faturamentoMinimo;	//10
        public Integer prazoEntrega;	//2
        public String validadeProposta;	//31/09/2008
        public String idFormaPagamento;	//295
        public String frete;	//CIF
        public String observacoes;	//item cotado
        public String cnpjCD;
        
        global CdItemRequest(CondicaoPagamentoPorCD__c cdp){
            this.faturamentoMinimo  = Integer.valueOf(cdp.MinimumBilling__c);
            this.prazoEntrega       = Integer.valueOf(cdp.PrazoEntrega__c);
            this.idFormaPagamento   = cdp.CondicaoPagamento__r?.ExternalId__c;
            this.frete              = cdp.FretePicklist__c != null ? cdp.FretePicklist__c : '';
            this.observacoes        = cdp.ObservacoesLongText__c != null ? cdp.ObservacoesLongText__c : '';
            this.cnpjCD             = cdp.CNPJCD__c != null ? cdp.CNPJCD__c : '';

            this.validadeProposta   = DateTime.newInstance(
                cdp.CloseDate__c.year(),
                cdp.CloseDate__c.month(),
                cdp.CloseDate__c.day()
            ).format('dd/MM/yyyy');
        }
    }
    
    
    global class OpportunityItemRequest {
        public String id;	//621a3853d2568958f9ba7dfe
        public String idArtigo;	//129211014
        public String codigoProduto;	//5138
        public List<OpportunityReplyRequest> respostas;
        
        global OpportunityItemRequest(QuoteItem__c qitem, List<QuoteItem__c> itemsRespostas, Opportunity opp, List<Setorizacao__c> setorizacao){
            System.debug('\n\n qitem:::' + JSON.serializePretty(qitem));
            this.id             = qitem.IdPortal__c;
            this.idArtigo       = qitem.IdIntegrator__c;//qitem.IdArtigo__c; //não tem IdArtigo__c no quoteItem__c
            this.codigoProduto  = qitem.IdCustomer__c;

            this.respostas = new List<OpportunityReplyRequest>();
            if(itemsRespostas != null && !itemsRespostas.isEmpty()){
                for(QuoteItem__c resp : itemsRespostas){
                    this.respostas.add(new OpportunityReplyRequest(resp, opp, setorizacao));
                }  
            }
        }
        
    }
    
    global class OpportunityReplyRequest {
        public String idSalesforce;	//1
        public String cnpjCD;	//52202744000788
        public String vendedorResponsavel;	//123
        public String nomeVendedorResponsavel;
        public String vendedorRespondeu;	//541
        public String nomeVendedorRespondeu;
        public String codigoProdutoErp;	//5432
        public Double precoUnitario;	//0.2
        public String fabricante;	//A
        public String embalagem;	//Caixa
        public Integer quantidadeEmbalagem;	//10
        public String bu;
        public String mesa;	//especialidade
        public String comentario;	//teste
        public Double precoUnitarioLiquido;	//0.2
        public String codigoRastreabilidade;	//33194933
        public String tabulacaoN1;	//COM OFERTA
        public Double precoTabela; // 0.2
        public Boolean foraMalha; // 0.2
        public String cnpjFaturamento ;
        public Double fatorConversao ;// 0
        public String tipoConversaoUnidadeMedida ;//MULTIPLICAR
        

        global OpportunityReplyRequest(QuoteItem__c itemResp, Opportunity opp, List<Setorizacao__c> setorizacao){
            this.idSalesforce            = itemResp.Id != null ? itemResp.Id : '';//or IdPortal__c!= null ?
            this.mesa                    = '';
            this.tabulacaoN1             = itemResp.TabulacaoN1__c != null ? itemResp.TabulacaoN1__c : '';
            
            // List<String> cds = String.isNotBlank(opp.CDsBloqueado__c) ? opp.CDsBloqueado__c.split(';') : new List<String>();
            // this.cnpjFaturamento = cds.isEmpty() ? '' : cds[0];

            this.foraMalha = false;
            this.cnpjCD = '';
            this.quantidadeEmbalagem = 0;
            this.bu = '';
            this.precoUnitario = 0;
            this.precoUnitarioLiquido = 0;
            this.precoTabela = 0;
            this.codigoRastreabilidade = '';
            this.comentario = '';
            this.codigoProdutoErp = '';
            this.fabricante = '-';
            this.embalagem = '';
            this.fatorConversao = 1;
            this.tipoConversaoUnidadeMedida = 'NENHUMA';

            if(itemResp.OpportunityLineItem__r != null){

                if(itemResp.OpportunityLineItem__r.CNPJCD__c != null){
                    this.cnpjCD = itemResp.OpportunityLineItem__r.CNPJCD__c;
                    this.cnpjFaturamento = itemResp.OpportunityLineItem__r.CNPJCD__c;
                }
                if(itemResp.FatorConversao__c != null){
                    this.quantidadeEmbalagem     = Integer.valueOf(itemResp.FatorConversao__c.round());
                }
                
                if(itemResp.OpportunityLineItem__r.ValorPortal__c != null){
                    this.precoUnitario = itemResp.OpportunityLineItem__r.ValorPortal__c;
                }
                if(itemResp.OpportunityLineItem__r.ValorPortal__c != null){
                    this.precoUnitarioLiquido = itemResp.OpportunityLineItem__r.ValorPortal__c;
                }
                if(itemResp.OpportunityLineItem__r.ListPrice != null){
                    this.precoTabela = itemResp.OpportunityLineItem__r.ListPrice;
                }
                if(String.isNotEmpty(itemResp.OpportunityLineItem__r.CodigoRastreio__c)){
                    this.codigoRastreabilidade = itemResp.OpportunityLineItem__r.CodigoRastreio__c;
                }
                if(String.isNotEmpty(itemResp.OpportunityLineItem__r.Comentarios__c)){
                    this.comentario = itemResp.OpportunityLineItem__r.Comentarios__c;
                }
                if(itemResp.OpportunityLineItem__r.Product2?.ExternalId__c != null){
                    
                    this.codigoProdutoErp = itemResp.OpportunityLineItem__r.Product2.ExternalId__c;
                    this.fabricante = itemResp.OpportunityLineItem__r.Product2.Name;
                    if(itemResp.OpportunityLineItem__r.Product2.Fornecedor__r?.Name != null){
                        this.fabricante += ' - '+ itemResp.OpportunityLineItem__r.Product2.Fornecedor__r.Name;
                    }else if(itemResp.OpportunityLineItem__r.Product2.Fabricante__c != null){
                        this.fabricante += ' - '+ itemResp.OpportunityLineItem__r.Product2.Fabricante__c;
                    }
                    
                    if(itemResp.OpportunityLineItem__r.Product2.UnidadeMedida__c != null){
                        this.embalagem = itemResp.OpportunityLineItem__r.Product2.UnidadeMedida__c;
                    }
                }
                this.foraMalha = itemResp.OpportunityLineItem__r.ForaMalha__c;

                if(itemResp.FatorConversao__c != null){
                    this.fatorConversao = itemResp.FatorConversao__c;
                }

                if(String.isNotEmpty(itemResp.TipoConversao__c)){
                    this.tipoConversaoUnidadeMedida = itemResp.TipoConversao__c;
                }
            }

            if(itemResp.Categoria__c != null){
                this.bu = itemResp.Categoria__c; 
            }

            this.vendedorResponsavel     = itemResp.Vendedor__r?.CodigoUsuario__c != null ? itemResp.Vendedor__r?.CodigoUsuario__c : '';
            this.nomeVendedorResponsavel = itemResp.Vendedor__r?.Name != null ? itemResp.Vendedor__r?.Name : '';
            this.vendedorRespondeu       = itemResp.VendedorRespondeu__r?.CodigoUsuario__c != null ? itemResp.VendedorRespondeu__r?.CodigoUsuario__c : '';
            this.nomeVendedorRespondeu   = itemResp.VendedorRespondeu__r?.Name != null ? itemResp.VendedorRespondeu__r?.Name : '';
                
        }
       
    }

}
/*
{
    "id": "621a3853d2568958f9ba7df7",               //Opportunity.ExternalPortal__c
    "integradora": "bionexo",                       //Opportunity.Integradora__c
    "integradoraId": "180507231",                   //Opportunity.IdIntegrator__c
    "cliente": {
        "cnpj": "34.551.422/0001-77"                //Opportunity.CNPJ__c
    },
    "cds": [
        { //por cd
            "faturamentoMinimo": 10.0,              //CondicaoPagamentoPorCD__c.MinimumBilling__c;
            "prazoEntrega": 2,                      //CondicaoPagamentoPorCD__c.PrazoEntrega__c;
            "validadeProposta": "31/09/2008",       //CondicaoPagamentoPorCD__c.PrazoValidade__c;
            "idFormaPagamento": 295,                //CondicaoPagamentoPorCD__c.CondicaoPagamento__r.ExternalId__c;
            "frete": "CIF",                         //CondicaoPagamentoPorCD__c.FretePicklist__c;
            "observacoes": "item cotado",           //CondicaoPagamentoPorCD__c.ObservacoesLongText__c;
            "cnpjCD": "52202744000788"              //CondicaoPagamentoPorCD__c.CNPJCD__c;
        },
        {
            "faturamentoMinimo": 10.0,              //CondicaoPagamentoPorCD__c.MinimumBilling__c
            "prazoEntrega": 2,                      //CondicaoPagamentoPorCD__c.PrazoEntrega__c
            "validadeProposta": "31/09/2008",       //CondicaoPagamentoPorCD__c.PrazoValidade__c
            "idFormaPagamento": 295,                //CondicaoPagamentoPorCD__c.CondicaoPagamento__r.ExternalId__c;
            "frete": "CIF",                         //CondicaoPagamentoPorCD__c.FretePicklist__c;
            "observacoes": "item cotado",           //CondicaoPagamentoPorCD__c.ObservacoesLongText__c
            "cnpjCD": "52202744000354"              //CondicaoPagamentoPorCD__c.CNPJCD__c
        }
    ],
    "tabulacaoByVds": [
        {
            "tabulacaoN1": "Respondida",            ?
            "tabulacaoN2": "Parcialmente",          ?
            "vds": "541"                            ?
        },
        {
            "tabulacaoN1": "Recusada",              ?OpportuinityTeamMember.TabulacaoN1__c
            "tabulacaoN2": "To",                    ?OpportuinityTeamMember.TabulacaoN2__c
            "vds": "546"                            ?OpportuinityTeamMember.User.CodigoUsuario__c
        }
    ],
    "items": [
        {
            "id": "621a3853d2568958f9ba7dfe",                       //quoteItem.IdPortal__c
            "idArtigo": "129211014",                                //quoteItem.IdArtigo__c;
            "codigoProduto": "5138",                                //quoteItem.Product2.ExternalId__c;
            "respostas": [
                {
                    "idSalesforce": "1",                            OpportunityLineItem.Id
                    "cnpjCD": "52202744000788",                     OpportunityLineItem.CNPJCD__c
                    "vendedorResponsavel": "123",                   OpportunityLineItem.OpportunityLineItem__r.Vendedor__r.CodigoUsuario__c;
                    "vendedorRespondeu": "541",                     '1';//          user.CodigoUsuario__c;//
                    "codigoProdutoErp": "5432",                     OpportunityLineItem.Product__r.ExternalId__c;
                    "precoUnitario": 0.2,                           OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "fabricante": "A",                              OpportunityLineItem.Product__r.Fornecedor__r.Name;
                    "embalagem": "Caixa",                           OpportunityLineItem.Product__r.UnidadeMedida__c;
                    "quantidadeEmbalagem": 10,                      OpportunityLineItem.OpportunityLineItem__r.Quantity
                    "bu": "especialidade",                          '1';
                    "comentario": "teste",                          OpportunityLineItem.OpportunityLineItem__r
                    "precoUnitarioLiquido": 0.2,                    OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "codigoRastreabilidade": "33194933",            OpportunityLineItem.OpportunityLineItem__r.CodigoRastreio__c
                    "codigoProdutoFornecedor": "7774567891012",     OpportunityLineItem.Product__r.Fornecedor__r.ExternalId__c;
                    "tabulacaoN1": "COM OFERTA"                     OpportunityLineItem.TabulacaoN1__c
                },
                {
                    "idSalesforce": "2",                            //OpportunityLineItem.Id
                    "cnpjCD": "52202744000354",                     //OpportunityLineItem.CNPJCD__c
                    "vendedorResponsavel": "123",                   //OpportunityLineItem.OpportunityLineItem__r.Vendedor__r.CodigoUsuario__c;
                    "vendedorRespondeu": "543",                     //'1';//          user.CodigoUsuario__c;//
                    "codigoProdutoErp": "543201",                   //OpportunityLineItem.Product__r.ExternalId__c;
                    "precoUnitario": 0.1,                           //OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "bu": "generico",                               //OpportunityLineItem.Product__r.Fornecedor__r.Name;
                    "fabricante": "B",                              //OpportunityLineItem.Product__r.UnidadeMedida__c;
                    "embalagem": "Caixa",                           //OpportunityLineItem.OpportunityLineItem__r.Quantity
                    "quantidadeEmbalagem": 10,                      //'1';
                    "comentario": "teste",                          //OpportunityLineItem.OpportunityLineItem__r
                    "precoUnitarioLiquido": 1,                      //OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "codigoRastreabilidade": "33194933",            //OpportunityLineItem.OpportunityLineItem__r.CodigoRastreio__c
                    "codigoProdutoFornecedor": "7774567891012",     //OpportunityLineItem.Product__r.Fornecedor__r.ExternalId__c;
                    "tabulacaoN1": "COM OFERTA"                     //OpportunityLineItem.TabulacaoN1__c
                },
                {
                    "idSalesforce": "3",                            //OpportunityLineItem.Id
                    "cnpjCD": "",                                   //OpportunityLineItem.CNPJCD__c
                    "vendedorResponsavel": "",                      //OpportunityLineItem.OpportunityLineItem__r.Vendedor__r.CodigoUsuario__c;
                    "vendedorRespondeu": "",                        //'1';            //user.CodigoUsuario__c;//
                    "codigoProdutoErp": "",                         //OpportunityLineItem.Product__r.ExternalId__c;
                    "precoUnitario": null,                          //OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "bu": "",                                       //OpportunityLineItem.Product__r.Fornecedor__r.Name;
                    "fabricante": "",                               //OpportunityLineItem.Product__r.UnidadeMedida__c;
                    "embalagem": "",                                //OpportunityLineItem.OpportunityLineItem__r.Quantity
                    "quantidadeEmbalagem": null,                    //'1';
                    "comentario": "",                               //OpportunityLineItem.OpportunityLineItem__r
                    "precoUnitarioLiquido": null,                   //OpportunityLineItem.OpportunityLineItem__r.UnitPrice;
                    "codigoRastreabilidade": "",                    //OpportunityLineItem.OpportunityLineItem__r.CodigoRastreio__c
                    "codigoProdutoFornecedor": "",                  //OpportunityLineItem.Product__r.Fornecedor__r.ExternalId__c;
                    "tabulacaoN1": "NAO TRABALHAMOS"                //OpportunityLineItem.TabulacaoN1__c
                }
            ]
        }
    ]
}
*/ 