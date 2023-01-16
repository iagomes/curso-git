/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 08-12-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
@RestResource(urlMapping='/upsertPortalQuote/v1/*')
global without sharing class IntegrationPortalQuoteIN {

    public static final Id rtOrcamentosPortalId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Orçamento do Portal').getRecordTypeId();

    @HttpPost
    global static void upsertQuote() {
        StandardResponse resp = new StandardResponse();
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        RestResponse res = RestContext.response;
        String responseBody;
        
        try{

            RequestData newQuote = validateRequestBody(requestBody);

            Boolean isAlterada = checkOrcamento(newQuote.idPortal);
            List<SaveResult> lstResults = new List<SaveResult>();
            Set<String> portalIdsWithError = new Set<String>();
            Map<String, OpportunityLineItem> mapOppLineItems = new Map<String, OpportunityLineItem>();
            Map<String, QuoteItem__c> mapQuoteItems = new Map<String, QuoteItem__c>();
            Map<String,QuoteItem> setERPIds = new Map<String,QuoteItem>();

            List<OpportunityTeamMember> teamMembersToInsert = new List<OpportunityTeamMember>();
            Set<String> IdsVDS = new Set<String>();
            Set<String> recipientsEmail = new Set<String>();

            Account acc = AccountSelector.getInstance().getAccountByDocument(String.valueOf(newQuote.customer.cnpj));
            if(acc == null){
                throw new CustomException('O CNPJ enviado não existe no Salesforce.');
            }


            Id pricebookId = acc.TabelaPrecos__c;
            if(pricebookId == null){
                if(Test.isRunningTest()){
                    pricebookId = Test.getStandardPricebookId();
                } else {
                    List<Pricebook2> pBooks = [SELECT Id FROM Pricebook2 WHERE ExternalId__c = 'B01'];
                    if(!pBooks.isEmpty()){
                        pricebookId = pBooks[0].Id;
                    } else if(!Test.isRunningTest()){
                        throw new CustomException('Tabela de preços não encontrada.');
                    }
                }
            }

            Opportunity opp = newQuote.buildOpportunity(acc, pricebookId);
            AutomationsController.stop('OpportunityBO.automaticOpportunityApproval');
            AutomationsController.stop('OpportunityBO.recallApprovalProcess');
            AutomationsController.stop('OpportunityBO.validaAprovacao');
            AutomationsController.stop('OpportunityBO.uncheckApproval');
            upsert opp Opportunity.ExternalPortal__c;
            newQuote.id = opp.Id;

            Opportunity oppUpdated = [SELECT NumeroOrcamento__c, StageName FROM Opportunity WHERE Id =: newQuote.Id LIMIT 1 FOR UPDATE];
            if(oppUpdated.StageName == 'Sem Retorno'){
                oppUpdated.StageName = 'Em digitação';
            }else if(oppUpdated.StageName == 'Não Respondida'){
                oppUpdated.StageName = 'Novo';
            }
            update oppUpdated;


            for(QuoteItem product: newQuote.products){
                if(product.produtosVinculados != null){
                    for(VinculadosAnteriormente oldLink: product.produtosVinculados){
                        if(oldLink.codigoProdutoERP != null){
                            setERPIds.put(oldLink.codigoProdutoERP, product);
                        }
                    }
                }
            }

            Map<String,List<Product2>> mapProduct2s = (Map<String,List<Product2>>) SObjectUtils.mapObjectsByField([
                SELECT  Id, CategoriaComercial__c, ExternalId__c,
                    (
                        SELECT Id, UnitPrice
                        FROM PricebookEntries
                        WHERE IsActive = TRUE
                        AND Pricebook2Id =: pricebookId
                        LIMIT 1
                    ),
                    (
                        SELECT VendedorSuporte__c, VendedorSuporte__r.Name, Produto__c, Categoria__c,Vendedor__r.Email
                        FROM Setorizacao__r
                        WHERE VendedorSuporte__r.IsActive = true
                        AND Conta__c =: acc.Id
                        AND Deletado__c = FALSE
                        AND Categoria__C IN ('M', 'G', 'S')
                    )
                FROM Product2 
                WHERE ExternalId__c 
                    IN: setERPIds.keySet()
            ], 'ExternalId__c', true);

            List<Setorizacao__c> lstAccSetorizacao = [
                SELECT VendedorSuporte__c, VendedorSuporte__r.Name, Produto__c, Categoria__c,Vendedor__r.Email
                FROM Setorizacao__c
                WHERE 
                    Produto__c = NULL
                    AND VendedorSuporte__c != null
                    AND VendedorSuporte__r.IsActive = true
                    AND Conta__c =: acc.Id
                    AND Deletado__c = FALSE
                    AND Categoria__C IN ('M', 'G', 'S')
            ];

            Map<String, List<Setorizacao__c>> mapSetorByCategoria = (Map<String, List<Setorizacao__c>>) SObjectUtils.mapObjectsByField(lstAccSetorizacao, 'Categoria__c', true);

            Map<String,OpportunityTeamMember> mapTeamMembers = new Map<String,OpportunityTeamMember>();

            StandardSeller__mdt vendedorStandard = StandardSeller__mdt.getInstance('VendedorZero');

            if(newQuote.method == 'insert' || newQuote.method == null || newQuote.method == ''){
                for(QuoteItem qItem: newQuote.products){
                    Product2 p;
                    List<Setorizacao__c> setorizacao;
                    if(qItem.produtosVinculados != null){
                        setorizacao = new List<Setorizacao__c>();
                        for(VinculadosAnteriormente oldLink: qItem.produtosVinculados){
                            Product2 prod;
                            if(String.isNotBlank(oldLink.codigoProdutoERP)){
                                if(mapProduct2s.containsKey(oldLink.codigoProdutoERP) && mapProduct2s.get(oldLink.codigoProdutoERP) != null && !mapProduct2s.get(oldLink.codigoProdutoERP).isEmpty()){
                                    prod = mapProduct2s.get(oldLink.codigoProdutoERP)[0];
                                    if(p == null){
                                        p = prod;
                                    }
                                }
                            }
    
                            if(prod != null){
                                if(!prod.Setorizacao__r.isEmpty()){
                                    setorizacao.addAll(prod.Setorizacao__r);
                                } else if(String.isNotBlank(oldLink.bu)){
    
                                    if(oldLink.bu != 'G' && oldLink.bu != 'S' && mapSetorByCategoria.containsKey(oldLink.bu)){
                                        setorizacao.addAll(mapSetorByCategoria.get(oldLink.bu));
                                    } else {
                                        if(mapSetorByCategoria.containsKey('G')){
                                            setorizacao.addAll(mapSetorByCategoria.get('G'));
                                        }
                                        if(mapSetorByCategoria.containsKey('S')){
                                            setorizacao.addAll(mapSetorByCategoria.get('S'));
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if((setorizacao == null || setorizacao.isEmpty()) && !lstAccSetorizacao.isEmpty()){
                        setorizacao = lstAccSetorizacao;
                    }
    
                    if(setorizacao != null && !setorizacao.isEmpty()){
                        
                        Set<String> isCreated = new Set<String>();
    
                        for(Setorizacao__c setor: setorizacao){
    
                            String uniqueTeamMemberKey = (opp.Id + '_' + setor.VendedorSuporte__c + '_' + setor.Categoria__c);
                            if(!mapTeamMembers.containsKey(uniqueTeamMemberKey)){
                                mapTeamMembers.put(
                                    uniqueTeamMemberKey, 
                                    new OpportunityTeamMember(
                                        TeamMemberRole = 'Sales Rep',
                                        UserId = setor.VendedorSuporte__c, 
                                        OpportunityId = opp.Id,
                                        OpportunityAccessLevel = 'EDIT'
                                    )
                                );
                            }
    
                            IdsVDS.add(setor.VendedorSuporte__c);
    
                            String externalId = newQuote.idPortal + '_' + qItem.idPortal + '_' + setor.VendedorSuporte__c + '_' + setor.Categoria__c;
                            if(!isCreated.contains(externalId)){
                                
                                QuoteItem__c item = qItem.buildQuoteItem(newQuote.idPortal, opp.Id, p, '_' + setor.VendedorSuporte__c + '_' + setor.Categoria__c);
                                item.Vendedor__c = setor.VendedorSuporte__c;
                                item.Categoria__c = setor.Categoria__c;
    
                                mapQuoteItems.put(item.ExternalId__c, item);
                                isCreated.add(externalId);
                            }
                        }
                    } else {
    
                        IdsVDS.add(userInfo.getUserId());
                        
                        String uniqueTeamMemberKey = (opp.Id + '_' + userInfo.getUserId());
                        if(!mapTeamMembers.containsKey(uniqueTeamMemberKey)){
                            mapTeamMembers.put(
                                uniqueTeamMemberKey,
                                new OpportunityTeamMember(
                                    TeamMemberRole = 'Sales Rep',
                                    UserId = userInfo.getUserId(),
                                    OpportunityId = opp.Id,
                                    OpportunityAccessLevel = 'EDIT'
                                )
                            );
                        }
    
                        QuoteItem__c item = qItem.buildQuoteItem(newQuote.idPortal, opp.Id, p, '');
                        mapQuoteItems.put(item.ExternalId__c, item);
                    }
                }
            }

            List<CondicaoPagamentoPorCD__c> condicoesVinculadas = [
                SELECT id, CloseDate__c, PrazoValidade__c 
                FROM CondicaoPagamentoPorCD__c 
                WHERE Orcamento__c = :opp.Id
            ];
            if(!condicoesVinculadas.isEmpty()){
                for(CondicaoPagamentoPorCD__c conpayCD : condicoesVinculadas){     
                    conpayCD.CloseDate__c = opp.CloseDate;
                    conpayCD.PrazoValidade__c = opp.PrazoValidade__c;
                }
                update condicoesVinculadas;
            }

            Database.insert(mapTeamMembers.values(), false);


            if(newQuote.method == 'insert' || newQuote.method == null || newQuote.method == ''){
                Database.UpsertResult[] quoteItemsResult = Database.upsert(mapQuoteItems.values(), QuoteItem__c.ExternalId__c, false);
                for(Integer i=0; i < quoteItemsResult.size() ; i++){
                    if(!quoteItemsResult[i].success){
                        resp.hasError = true;
                        resp.code = '201';
                    }
                    lstResults.add(
                        new SaveResult(
                            quoteItemsResult[i],
                            mapQuoteItems.values()[i]
                        )
                    );
                }
            }
            
            OpportunityTH.disableTrigger();
                opp.QuantidadeItensTotal__c = [SELECT IdPortal__c, count(id) FROM QuoteItem__c WHERE OpportunityId__c =: opp.Id GROUP BY IdPortal__c ]?.size();
                if(String.isNotBlank(newQuote.status) && newQuote.status != 'Enviando' && newQuote.status != 'Cancelada'){
                    opp.StatusIntegracaoPortalCotacoes__c = 'Recebida';
                }
                update opp;
            OpportunityTH.enableTrigger();

            resp.setData('result', lstResults);
            resp.setData('quoteId', opp.Id);

            Set<Id> permissionSetIds = new Set<Id>();
            for (SetupEntityAccess access : [
                SELECT ParentId 
                FROM SetupEntityAccess 
                WHERE SetupEntityId IN (
                    SELECT Id 
                    FROM CustomPermission 
                    WHERE DeveloperName = 'ReceberEmailsDoPortal'
                )
            ]){
                permissionSetIds.add(access.ParentId);
            }

            Set<String> idsToNotificate = new Set<String>();
            List<User> usuariosTime = permissionSetIds.isEmpty() ? new List<User>() : [
                SELECT Id,Email,Username FROM User WHERE Id IN: IdsVDS AND Id IN (
                    SELECT AssigneeId FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permissionSetIds
                )
            ];
           
            for(User u: usuariosTime){
                recipientsEmail.add(u.Email);
                idsToNotificate.add(u.Id);
            }

            if(!idsToNotificate.isEmpty()){
                EnviarNotificaoVDS(idsToNotificate, opp, newQuote.idIntegrator, isAlterada);
            }
          
            if(!recipientsEmail.isEmpty()){
                EnviaEmailVDS(recipientsEmail, newQuote.idIntegrator, opp, isAlterada, acc);
            }
        }
        catch(Exception ex){
            resp.addError(ExceptionUtils.debug(ex));
        }

        res.statuscode = Integer.valueOf(resp.code);
        res.headers.put('Content-Type', 'application/json;charset=UTF-8');
        responseBody = resp.toJSON();
        res.responseBody = Blob.valueOf(responseBody);
        
        IntegrationUtils.WSLog('Cotação', 'Inbound', requestBody.normalizeSpace(), responseBody, resp.code != '200' && resp.code != '201', '/upsertPortalQuote/v1/*', resp.code);
    }
    

    private static RequestData validateRequestBody(String requestBody){
        RequestData rData;
        if(String.isBlank(requestBody)){
            throw new CustomException('Dados não enviados.');
        } else {
            rData = (RequestData)JSON.deserialize(requestBody, RequestData.class);
        }
        if(rData.customer == null || String.isBlank(rData.customer.cnpj)){
            throw new CustomException('O CNPJ do cliente é um campo obrigatório!');
        } else {
            if(String.valueOf(rData.customer.cnpj).length() < 14){
                throw new CustomException('CNPJ inválido!');
            }
        }
        return rData;
    }
    

    global class RequestData {
        global String id { get; set; }
        global String idPortal { get; set; }
        global String idIntegrator { get; set; }
        global String name { get; set; }
        global String status { get; set; }
        global String method { get; set; }
        global CondicaoPagamento condicaoPagamento { get; set; }
        global String formaPagamento { get; set; }
        global Datetime closeDate { get; set; }
        global String supplierObservations { get; set; }
        global String vendedor { get; set; }
        global String vendedorSuporte { get; set; }
        global String mesa { get; set; }
        global String quoteType { get; set; }
        global String frete { get; set; }
        global Decimal minimumBilling { get; set; }
        global String category { get; set; }
        global String termosCondicoes { get; set; }
        global String customerObservations { get; set; }
        global String contact { get; set; }
        global String enderecoEntrega {get; set;}
        global List<Consolidador> consolidador { get; set; }
        global Customer customer { get; set; }
        global List<Taxes> taxes { get; set; }
        global List<QuoteItem> products { get; set; }
        global List<ExtraFields> extraFields { get; set; } 
        global List<CdData> cds { get; set; }
        global Map<Id,User> mapVendedores { get; set; }

        //novos campos 
        global String integradora { get; set; }
        global String integrator { get; set; }
        global Datetime dataVencimento {get; set;}

        global Opportunity buildOpportunity(Account acc, Id pricebookId) {
            Opportunity newQuote = new Opportunity();
                newQuote.OrcamentoTravado__c = false;
                newQuote.RecordTypeId = rtOrcamentosPortalId;
                newQuote.Pricebook2Id = pricebookId;
                newQuote.ExternalPortal__c = this.idPortal;
                newQuote.IdIntegrator__c = this.idIntegrator;
                newQuote.Name = this.name != null ? this.name.left(120) : null;
                newQuote.ContactName__c = this.contact;
                // newQuote.CanalVendas__c = this.quotePortals;
                newQuote.AccountId = acc.Id;
                newQuote.FormaPagamento__c = this.formaPagamento;
                Datetime nextDate =  this.closeDate.addHours(3);
                newQuote.DataVencimento__c = nextDate;
                newQuote.CloseDate = Date.valueOf(this.closeDate).addDays(3);
                newQuote.PrazoValidade__c = Date.valueOf(this.closeDate).daysBetween(Date.valueOf(newQuote.CloseDate));
                newQuote.Category__c = this.category;
                newQuote.TermosCliente__c = this.termosCondicoes;
                newQuote.ObservacoesCliente__c = this.customerObservations;
                newQuote.ObservacoesLongText__c = this.supplierObservations;


                if(this.consolidador != null){
                    newQuote.CotacoesConsolidadas__c = JSON.serialize(this.consolidador);

                }

                newQuote.EnderecoEntregaPedido__c = this.enderecoEntrega;

                if(this.minimumBilling != null){
                    newQuote.MinimumBilling__c = this.minimumBilling;
                }

                if(String.isNotBlank(this.frete)){
                    newQuote.FretePicklist__c = this.frete;
                }

                if(String.isNotBlank(this.mesa)){
                    newQuote.Mesa__c = this.mesa;
                }

                if(String.isNotBlank(this.quoteType)){
                    newQuote.QuoteType__c = this.quoteType;
                }
            
                if(String.isBlank(this.integradora)){
                    this.integradora = this.integrator;
                }
                
                if(String.isNotBlank(this.integradora)){
                    newQuote.Integradora__c = this.integradora;
                    newQuote.CanalEntrada__c = this.integradora != null ? this.integradora.toLowerCase().capitalize(): null;
                }

                List<String> cnpjCDs = new List<String>();
                for(CdData cd : this.cds){
                    cnpjCDs.add(cd.cnpj);
                }
                newQuote.CDsBloqueado__c = cnpjCDs.size() > 0 ? String.join(cnpjCDs, ';') : '';

                if(this.condicaoPagamento != null && (this.condicaoPagamento.id != null || this.condicaoPagamento.name != null)){
                    List<CondicaoPagamento__c> condicoes  = [
                        SELECT ID 
                        FROM CondicaoPagamento__c
                        WHERE Name LIKE :('%/' + this.condicaoPagamento.name) 
                        ORDER BY CREATEDDATE DESC 
                        LIMIT 1
                    ];
                    if(condicoes.isEmpty()){

                        throw new CustomException('Condição de pagamento não identificada.');
                    }
                    newQuote.CondicaoPagamento__c = condicoes[0].Id;
                }

                Set<String> codigoUsuarios = new Set<String>();
                
                if(String.isNotBlank(this.vendedor)){
                    codigoUsuarios.add(this.vendedor);
                }

                if(String.isNotBlank(this.vendedorSuporte)){
                    codigoUsuarios.add(this.vendedorSuporte);
                }

                if(!codigoUsuarios.isEmpty()){
                    this.mapVendedores = new Map<Id,User>([SELECT Id, CodigoUsuario__c FROM User WHERE CodigoUsuario__c IN: codigoUsuarios]);
                    for(User u: mapVendedores.values()){
                        if(String.isNotBlank(u.CodigoUsuario__c)){
                            if(u.CodigoUsuario__c == this.vendedor){
                                newQuote.Vendedor__c = this.vendedor;
                            } else if(u.CodigoUsuario__c == this.vendedorSuporte){
                                newQuote.VendedorSuporte__c = this.vendedorSuporte;
                            }
                        }
                    }
                }
            
                if (this.status == 'Cancelada') {
                    newQuote.StatusIntegracaoPortalCotacoes__c = 'Integrado';
                    newQuote.StageName = this.status;
                    DateTime dt = DateTime.now();
                    String dateStr = dt.format('dd/MM/yyyy hh:mm:ss');
                    newQuote.OrcamentoCancelado__c = 'Por ação do cliente na integradora em '+ dateStr;
                } else if(this.status == 'Enviando'){
                    newQuote.StatusIntegracaoPortalCotacoes__c = 'Recebendo dados';
                }

            return newQuote;
        }
    }

    global class VinculadosAnteriormente {
        global String codigoProdutoERP { get; set; }
        global String idERP { get; set; }
        global String bu { get; set; }
        global String mesa { get; set; }
        global String vendedor { get; set; }
        global String createdAt { get; set; }
        global String updateAt { get; set; }
        global Double fatorConversao { get; set; }
        global String tipoConversaoUnidadeMedida { get; set; }
    }

    global class CdData {
        global String id { get; set; }
        global String cnpj { get; set; }
    }
    

    global class Customer {
        global String cnpj { get; set; }
    }
    

    global class Brands {
        global String id { get; set; }
        global String name { get; set; }
    }

    global class CondicaoPagamento {
        global String id { get; set; }
        global String name { get; set; }
    }

    global class Taxes {
        global String id { get; set; }
        global String description { get; set; }
    }

    global class ExtraFields {
        global String name { get; set; }
        global String valor { get; set; }
    }

    global class QuoteItem {
        global String id { get; set; }
        global String idCustomer { get; set; }
        global String idIntegrator { get; set; }
        global String idPortal { get; set; }
        global String idERP { get; set; }
        global Decimal quantity { get; set; }
        global Decimal unitPrice { get; set; }
        global Integer sequence { get; set; }
        global String customerDescription { get; set; }
        global String customerMeasurementUnit { get; set; }
        global String integratorMeasurementUnit { get; set; }
        global String favoriteBrands { get; set; }
        global List<Brands> brands { get; set; }
        global String status { get; set; }
        global String categoriaProduto { get; set; }
        global List<ProgramacaoEntregaRequest> programacaoEntrega { get; set; }
        global List<VinculadosAnteriormente> produtosVinculados { get; set; }

        
        global OpportunityLineItem buildOpportunityLineItem(String quotePortalId, Id oppId, Product2 product, String vendedor) {

            OpportunityLineItem item = new OpportunityLineItem(
                IdCustomer__c = this.idCustomer,
                IdIntegrator__c = this.idIntegrator,
                IdPortal__c = this.idPortal,
                ExternalId__c = quotePortalId + '_' + this.idPortal + vendedor,
                OpportunityId = oppId,
                Product2Id = product?.Id,
                Product2 = product
            );

            if(product != null && !product.PricebookEntries.isEmpty()){
                item.PricebookEntryId = product.PricebookEntries[0].Id;
                item.UnitPrice = product.PricebookEntries[0].UnitPrice;
            }

            if(this.quantity != null){
                item.Quantity = this.quantity.setScale(2, RoundingMode.HALF_UP);
            }

            if(String.isNotBlank(this.status)){
                item.Status__c = this.status;
            }

            if(this.sequence != null){
                item.SequenciaOC__c = String.valueOf(this.sequence);
            }

            item.ProgramacaoEntrega__c = this.programacaoEntrega != null ? JSON.serialize(this.programacaoEntrega) : null;

            return item;
        }

        
        global QuoteItem__c buildQuoteItem(String quotePortalId, Id oppId, Product2 product, String vendedor) {
            String externalId = quotePortalId + '_' + this.idPortal + vendedor;
            QuoteItem__c item = new QuoteItem__c(
                OpportunityId__c = oppId,
                IdCustomer__c = this.idCustomer,
                IdERP__c = this.idERP,
                IdIntegrator__c = this.idIntegrator,
                IdPortal__c = this.idPortal,
                ExternalId__c = externalId
            );
            
            if(this.categoriaProduto != null){
                item.CategoriaCliente__c = this.categoriaProduto.left(255);
            }

            if(product != null){
                item.Product__c = product.Id;
            }

            if(this.quantity != null){
                item.Quantity__c = this.quantity.setScale(2, RoundingMode.HALF_UP);
            }

            if(String.isNotBlank(this.customerDescription)){
                item.CustomerDescription__c = this.customerDescription;
            }

            if(String.isNotBlank(this.customerMeasurementUnit)){
                item.CustomerMeasurementUnit__c = this.customerMeasurementUnit;
            }

            if(String.isNotBlank(this.integratorMeasurementUnit)){
                item.IntegratorMeasurementUnit__c = this.integratorMeasurementUnit;
            }

            if(String.isNotBlank(this.favoriteBrands) && this.favoriteBrands.toUpperCase() != 'NULL'){
                item.FavoriteBrands__c = this.favoriteBrands;
            }

            if(this.sequence != null){
                item.SequenciaOC__c = String.valueOf(this.sequence);
            }

            item.ProdutosVinculadosAnteriormente__c = this.produtosVinculados != null ? JSON.serialize(this.produtosVinculados) : null;
            item.ProgramacaoEntrega__c = this.programacaoEntrega != null ? JSON.serialize(this.programacaoEntrega) : null;

            return item;
        }
    }

    global class Consolidador {
        global String idPdcConsolidador {get; set;}
        global String nomeHospitalConsolidador {get; set;}
        global String cnpjConsolidador {get; set;}
        global String uf {get; set;}
        global String cidade {get; set;}
    }

    global class ProgramacaoEntregaRequest {
         global String data { get; set; }
         global String quantidade { get; set; }
     }

    global class SaveResult {
        global String id { get; set; }
        global Boolean success { get; set; }
        global List<Database.Error> errors { get; set; }

        public SaveResult(Database.UpsertResult result, QuoteItem__c qItem){
            this.success = result.isSuccess();
            this.id = qItem.IdPortal__c;
            this.errors = result.errors;
        }
    }

    public static void EnviarNotificaoVDS(Set<String> IdsVDS, Opportunity opp, String idIntegrador,Boolean isAlterada){

        Set<String> recipientsIds = IdsVDS;
        String targetId =  opp.Id;
        String statusOrcamento =  isAlterada ? 'alterada'  : 'aberta' ;
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM  CustomNotificationType
            WHERE  DeveloperName = 'NotificaoCasoEncerrado'
        ];       
      
       
        notification.setTitle('A cotação '+ opp.CanalEntrada__c + ' - ' + idIntegrador + 'foi ' + statusOrcamento + ' com o vencimento para ' + opp.DataVencimento__c);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        try {
            notification.send(recipientsIds);
        } catch (Exception e) {
            ExceptionUtils.debug(e);
        }

    }

    public static void enviaEmailVDS(Set<String> recipientsEmail,String idIntegrador, Opportunity opp, Boolean isAlterada, Account acc){

        // String statusOrcamento =  isAlterada ? 'alterada'  : 'aberta' ;
        // Messaging.reserveSingleEmailCapacity(recipientsEmail.size());      
        // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // List<String> toAddresses = new List<String>(recipientsEmail);
        // mail.setToAddresses(toAddresses);
        // mail.setSenderDisplayName('Salesforce');
        // mail.setSubject('A cotação '+ opp.CanalEntrada__c + ' - ID ' + idIntegrador + 'foi ' + statusOrcamento + ' com o vencimento para ' + opp.DataVencimento__c);
        // mail.setBccSender(false);
        // mail.setHtmlBody('A cotação '+ opp.CanalEntrada__c + ' - ID ' + idIntegrador + ' - <b> ' + acc.Name +'</b>'+
        // ' com vencimento  ' + opp.DataVencimento__c +
        // ' foi ' + statusOrcamento + ' em '+ Datetime.now() +
        // '<p><a href=' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.Id + '>Link do Orçamento.</a>');


        // try {
        //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        // }  catch (Exception e) {
        //     ExceptionUtils.debug(e);
        // }
    }

    public static Boolean checkOrcamento(String externalId){
        return !(([SELECT id FROM Opportunity WHERE ExternalPortal__c =: externalId ]).isEmpty());
    }
 
}