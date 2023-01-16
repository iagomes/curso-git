public  without sharing class BudgetDetailController {

    public static final List<String> VIEW_ONLY_STAGENAME = new List<String>{'Cancelada', 'Sem Retorno', 'Não Respondida', 'Não Ganha'};

    @AuraEnabled /* carregamento da tela inicial */
    public static StandardResponse getBudgetDataWithItens(String oppId){
        StandardResponse response = new StandardResponse();
        try {
            BudgetData budgetData = getBudgetData(oppId);
            response.setData('budgetData', JSON.serialize(budgetData));
            if(budgetData.statusIntegracaoPortal != 'Recebendo dados'){

                List<BudgetItemData> BudgetItemDataList = getBudgetItemDataList(oppId, budgetData.accountId);
                response.setData('itemDataList', JSON.serialize(BudgetItemDataList));
            }
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static BudgetData getBudgetData(String oppId){
        BudgetData budgetData;

        Opportunity opp = BudgetDetailSelector.getOpportunity(oppId);
        OpportunityTeamMember oppTeamMember = BudgetDetailSelector.getOpportunityTeamMember(oppId);
        List<Setorizacao__c> SetorizacaoList = BudgetDetailSelector.getSetorizacaoList(opp.AccountId);
        budgetData = new BudgetData(opp, oppTeamMember, SetorizacaoList);

        return budgetData;
    }

    public static List<BudgetItemData> getBudgetItemDataList(String oppId,String accountId){
        List<BudgetItemData> budgetItemDataList = new List<BudgetItemData>();
        Set<Id> productIdSet = new Set<Id>();

        List<QuoteItem__c> qItemList = BudgetDetailSelector.getAllQuoteItemList(oppId);
        Map<String, List<QuoteItem__c>> qItemMapByIdPortal = processQItemList(qItemList, productIdSet);
        List<AggregateResult> estoqueAggregatedList = BudgetDetailSelector.getEstoqueAggregated(accountId, productIdSet);
        Map<String, Decimal> saldoEstoqueMap = processEstoqueAggregated(estoqueAggregatedList);

        for(String idPortal : qItemMapByIdPortal.keySet()){
            budgetItemDataList.add(new BudgetItemData(qItemMapByIdPortal.get(idPortal), saldoEstoqueMap));
        }
        budgetItemDataList.sort();
        return budgetItemDataList;
    }

    public static Map<String, List<QuoteItem__c>> processQItemList(List<QuoteItem__c> qItemList, Set<Id> productIdSet){
        /**
         * 1. separa os QuoteItem__c por IdPortal
         * 2. seta o limite de IdPortal pelo listSize
         * 3. preenche a lista de produtos com o que há nos QuoteItem__c
         */
        
        Map<String, List<QuoteItem__c>> qItemMapByIdPortal = new Map<String, List<QuoteItem__c>>();
        for(QuoteItem__c qItem : qItemList){
            if(!qItemMapByIdPortal.containsKey(qItem.IdPortal__c)){
                qItemMapByIdPortal.put(qItem.IdPortal__c, new List<QuoteItem__c>());
            }
            qItemMapByIdPortal.get(qItem.IdPortal__c).add(qItem);
            if(String.isNotEmpty(qItem.Product__c)) productIdSet.add(qItem.Product__c);
        }
        return qItemMapByIdPortal;
    }

    public static Map<String, Decimal> processEstoqueAggregated(List<AggregateResult> estoqueAggregatedList){
        Map<String, Decimal> saldoEstoqueMap = new Map<String, Decimal>();
        for(AggregateResult aggrResult : estoqueAggregatedList){
            String prodId = (String)aggrResult.get('NomeProduto__c');
            Decimal saldo = (Decimal)aggrResult.get('Saldo');
            saldoEstoqueMap.put(prodId, saldo);
        }
        return saldoEstoqueMap;
    }

    @AuraEnabled /* multiplaTabulação */
    public static StandardResponse setItemTabulacaoN1(List<String> quoteItemIdsPortal, String oppId, String accId, List<String> categorias, String tabulacaoN1){
        StandardResponse response = new StandardResponse();
        try {

            Id userId = UserInfo.getUserId();
            List<QuoteItem__c> quoteItensUpsertList = new List<QuoteItem__c>();
            Map<String, List<String>> idPortalMapByCategory = new Map<String, List<String>>();
            for(String category : categorias){
                idPortalMapByCategory.put(category, new List<String>(quoteItemIdsPortal));
            }

            List<QuoteItem__c> quoteItems = BudgetDetailSelector.getQuoteItemsFromIdPortalUserBu(
                quoteItemIdsPortal,
                oppId,
                userId,
                categorias
            );
            
            for(QuoteItem__c qItem: quoteItems){
                List<String> categoryList = idPortalMapByCategory.get(qItem.Categoria__c);
                Integer indexCategoty = categoryList.indexOf(qItem.IdPortal__c);
                qItem.Status__c = tabulacaoN1 == 'Não tem no portifólio' ? 'Não Vinculado' : 'Vinculado';
                qItem.TabulacaoN1__c = tabulacaoN1;
                qItem.DataHoraResposta__c = system.now();
                qItem.VendedorRespondeu__c = userInfo.getUserId();
                quoteItensUpsertList.add(qItem);
                //removendo da lista do mapa de idportal por categoria.
                if(indexCategoty >= 0)categoryList.remove(indexCategoty);
            }
            Set<String> idPortalQueryList = new Set<String>();
            for(List<String> idportalList : idPortalMapByCategory.values()){
                idPortalQueryList.addAll(idportalList);
            }
            if(!idPortalQueryList.isEmpty()){
                List<QuoteItem__c> quoteItemsListToCopy = BudgetDetailSelector.getQuoteItemListToCopy(idPortalQueryList, oppId);

                Map<String, QuoteItem__c> qItemMapToCopyByIdPortal = new Map<String, QuoteItem__c>();
                for(QuoteItem__c qItem : quoteItemsListToCopy){
                    qItemMapToCopyByIdPortal.put(qItem.IdPortal__c, qItem);
                }
    
                for(String category : idPortalMapByCategory.keySet()){
                    for(String idPortal : idPortalMapByCategory.get(category)){
                        QuoteItem__c qItemToCopy = qItemMapToCopyByIdPortal.get(idPortal);
                        QuoteItem__c newQi = qItemToCopy.clone(false, false, false, false);
                        newQi.Vendedor__c = UserInfo.getUserId();
                        newQi.Categoria__c = category;
                        newQi.CNPJCD__c = null;
                        newQi.ExternalId__c = qItemToCopy.OpportunityId__r?.ExternalPortal__c + category + newQi.IdPortal__c + newQi.Vendedor__c + Datetime.now();
                        newQi.Status__c = tabulacaoN1 == 'Não tem no portifólio' ? 'Não Vinculado' : 'Vinculado';
                        newQi.TabulacaoN1__c = tabulacaoN1;
                        newQi.Product__c = null;
                        newQi.DataHoraResposta__c = system.now();
                        quoteItensUpsertList.add(newQi);
                    }
                }
            }

            AutomationsController.stop('QuoteItemTH.statusAndProductReset');
            upsert quoteItensUpsertList;
            system.debug(JSON.serializePretty(quoteItensUpsertList));
            if(!quoteItensUpsertList.isEmpty() && quoteItensUpsertList[0].OpportunityId__r.StageName == 'Novo'){
                update new Opportunity(Id= oppId, StageName = 'Em digitação');
            }
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @AuraEnabled /* carrega informações do modal de programação de entrega */
    public static List<BudgetCtrl.ProgramacaoEntrega> getProgramacaoEntrega(String quoteIdPortal){
        
        List<QuoteItem__c> qItemList = BudgetDetailSelector.getQuoteItemProgramacaoEntrega(quoteIdPortal);
        List<BudgetCtrl.ProgramacaoEntrega> lprgEntrada = new List<BudgetCtrl.ProgramacaoEntrega>();
        for(QuoteItem__c qItem : qItemList){
            if(String.isNotEmpty(qitem.ProgramacaoEntrega__c) && qitem.ProgramacaoEntrega__c != '[]'){
                lprgEntrada = (List<BudgetCtrl.ProgramacaoEntrega>)JSON.deserialize(qItem.ProgramacaoEntrega__c, List<BudgetCtrl.ProgramacaoEntrega>.class);
                break;
            }
        }
        return lprgEntrada;
    }

    @AuraEnabled(cacheable=true) /* filtro de categorias da tabela (desativado) */
    public static String getCustomerCategory(String oppId){
        List<BudgetCtrl.PicklistOption> categoriaList = new List<BudgetCtrl.PicklistOption>();
        try{
            List<AggregateResult> quoteItemList = BudgetDetailSelector.getQuoteItemCategoryAggregate(oppId);
            categoriaList.add(new BudgetCtrl.PicklistOption(true,'all', 'Todas as categorias'));
            for(AggregateResult qItem : quoteItemList){
                categoriaList.add(new BudgetCtrl.PicklistOption(false, (String)qItem.get('CategoriaCliente__c'), (String)qItem.get('CategoriaCliente__c')));
            }
            return JSON.serialize(categoriaList);
        }catch(Exception e){
            System.debug(e.getMessage());
            return e.getMessage();
        }
    }

    @AuraEnabled /* botão de enviar/salvar no final do orçamento */
    public static StandardResponse saveBudget(Opportunity opp, Boolean sendBudgetToPortal, String cdValues){
        Savepoint sp;
        StandardResponse response = new StandardResponse();
        try {
            
            saveConditionPayment(response, cdValues, opp.Id);
            if(response.hasError){
                return response;
            }
            
            Opportunity currentOpp = BudgetDetailSelector.getOpportunity(opp.Id);
            OpportunityTeamMember oppTeamMember = BudgetDetailSelector.getOpportunityTeamMember(opp.Id);
            
            if(oppTeamMember != null){
                if(opp.TabulacaoN1__c != null){
                    oppTeamMember.TabulacaoN1__c = opp.TabulacaoN1__c;
                }
                if(opp.TabulacaoN2__c != null){
                    oppTeamMember.TabulacaoN2__c = opp.TabulacaoN2__c;
                }
                update oppTeamMember;
            }
        
            if(sendBudgetToPortal){
                // else if(oppTeamMember != null && oppTeamMember.TabulacaoN1__c == 'Aceite') {
                    // List<QuoteItem__c> lstQuoteItems = [
                    //     SELECT Id, 
                    //         Categoria__c,
                    //         CustomerDescription__c,
                    //         IdPortal__c,
                    //         OpportunityId__r.DataVencimento__c, 
                    //         TabulacaoN1__c, 
                    //         Vendedor__c,
                    //         VendedorRespondeu__c,
                    //         Status__c
                    //     FROM
                    //         QuoteItem__c 
                    //     WHERE 
                    //         OpportunityId__c =: opp.Id
                    // ];
                    // for(QuoteItem__c item : lstQuoteItems){
                    //     if( (item.Vendedor__c == UserInfo.getUserId()) && (String.isBlank(item.TabulacaoN1__c)) ){
                    //         return response.addError('Antes de enviar cotação você deve responder todos os produtos que estão em sua BU: O item "' +
                    //             item.CustomerDescription__c + '" não foi respondido corretamente.'
                    //         );
                    //     }
                    // }
                // }
                //NÃO APAGAR COMENTÁRIO ACIMA
            
                if(oppTeamMember != null && opp.TabulacaoN2__c != 'Cotação Vencida' && currentOpp.DataVencimento__c <= Datetime.now()){
                    return response.addError('Não é permitido responder um orçamento vencido.');
                }
                if(String.isBlank(opp.TabulacaoN1__c) || String.isBlank(opp.TabulacaoN2__c)){
                    return response.addError('Os campos de "TabulaçãoN1" e "TabulaçãoN2" da cotação são obrigatórios para preenchimento');
                }
                
                if(!Test.isRunningTest()){
                    System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(0, new List<Id>{opp.Id}));
                }
                opp.LastIntegratedItem__c = null;
                opp.StageName = 'Aguardando Integração';
                update opp;
            } else if(currentOpp.StageName == 'Novo'){
                opp.StageName = 'Em digitação';
                update opp;
            }
            
        } catch(Exception ex) {
            if(sp != null){
                Database.rollback(sp);
            }
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse saveConditionPayment(StandardResponse response, String jsonRequest, String oppId){
        //System.debug('\n\n inital: '+jsonRequest);
        List<CondicaoPagamentoPorCD__c> listCondPagCD = new List<CondicaoPagamentoPorCD__c>();
        List<String> condPagCDIds = new List<String>();
        List<String> condPagNameList = new List<String>();
        try {
            if(String.isNotEmpty(jsonRequest)){

                List<BudgetCtrl.DistCenterDTO> distCenterList = (List<BudgetCtrl.DistCenterDTO>)JSON.deserialize(jsonRequest, List<BudgetCtrl.DistCenterDTO>.class);
                for(BudgetCtrl.DistCenterDTO distCenter : distCenterList){
                    CondicaoPagamentoPorCD__c condPag = distCenter.build();
                    condPagNameList.add(condPag.CondicaoPagamentoPL__c);
                    if(validateConditionPayment(condPag) && !response.hasError){
                        response.addError('Preencha todos os campos dos CDs.');
                    }
                    listCondPagCD.add(condPag);
                    condPagCDIds.add(condPag.Id);
                }
    
                List<CondicaoPagamento__c> conditionPaymentList = BudgetDetailSelector.getConditionPaymentByName(condPagNameList);
    
                Map<String, String> conditionPaymentMap = new Map<String, String>();
                for(CondicaoPagamento__c cp : conditionPaymentList){
                    conditionPaymentMap.put(cp.Name, cp.Id);
                }
    
                for(CondicaoPagamentoPorCD__c condPagCD : listCondPagCD){
                    condPagCD.CondicaoPagamento__c = conditionPaymentMap.get(condPagCD.CondicaoPagamentoPL__c);
                    if(condPagCD.CondicaoPagamento__c == null  && !response.hasError){
                        response.addError('Condição de pagamento mal cadastrada, selecione outra para continuar.');
                    }
                }
    
                Database.update(listCondPagCD);
            }
            
            if(!BudgetDetailSelector.getUnfilledConditionPayment(oppId, condPagCDIds).isEmpty()){
                response.addError('Preencha todos os campos dos CDs.');
            }
            
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static Boolean validateConditionPayment(CondicaoPagamentoPorCD__c cd){
        return (
            cd.MinimumBilling__c        == null ||
            cd.CloseDate__c             == null ||
            cd.PrazoEntrega__c          == null ||
            cd.PrazoValidade__c         == null ||
            cd.CondicaoPagamentoPL__c   == null ||
            cd.CNPJCD__c                == null ||
            cd.FretePicklist__c         == null ||
            cd.CondicaoPagamentoPL__c   == ''   ||
            cd.CNPJCD__c                == ''   ||
            cd.FretePicklist__c         == ''   ||
            cd.MinimumBilling__c        <= 0    ||
            cd.PrazoEntrega__c          <= 0    ||
            cd.PrazoValidade__c         <= 0    
        ); 
    }

    /* budgetDetailSelectBU */
    @AuraEnabled
    public static StandardResponse getUserCategories(Id opportunityId) {
        StandardResponse response = new StandardResponse();
        List<BudgetCtrl.PicklistOption> options = new List<BudgetCtrl.PicklistOption>();
        try {
            List<AggregateResult> userSetorizationList = BudgetDetailSelector.getUserCategoriesAggregated(opportunityId);
            Map<String, String> categoriesLabels = getSectorizationCategoriesLabels();
            for(AggregateResult userSetorization : userSetorizationList){

                String categoryValue = (String)userSetorization.get('Categoria__c');
                String categoryLabel = categoriesLabels.get(categoryValue);

                if(categoryLabel != null){

                    options.add(new BudgetCtrl.PicklistOption(false, categoryValue, categoryLabel));
                }
            }
            if(!options.isEmpty()){
                response.setData(JSON.serialize(options));
            }
        } catch (Exception ex){
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static Map<String,String> getSectorizationCategoriesLabels() {
        Map<String,String> mapCategories = new Map<String,String>();
        List<Schema.PicklistEntry> pickListEntries = Schema.SObjectType.Setorizacao__c.fields.Categoria__c.getPicklistValues();
        for (Schema.PicklistEntry  pickListEntry: pickListEntries) {
            mapCategories.put(pickListEntry.getValue(), pickListEntry.getLabel());
        }
        return mapCategories;
    }

    @AuraEnabled
    public static StandardResponse getPdfPage(String oppId){
        StandardResponse response = new StandardResponse();
        try {
            System.debug(oppId);
            PageReference pdf = Page.BudgetPortalPDF;
            pdf.getParameters().put('Id', oppId);
            
            response.setData(URL.getSalesforceBaseUrl().toExternalForm()+pdf.getUrl());

        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        System.debug(response.data);

        return response;
    }

    public class BudgetData {
        public Id oppId {get;set;}
        public String accountId {get;set;}
        public String accountType {get;set;}
        public Set<String> categorias {get;set;}
        public String CDsBloqueado {get;set;}
        public String ClienteEmissorId {get;set;}
        public String ClienteEmissorCGC {get;set;}
        public String ClienteEmissorUF {get;set;}
        public String CondicaoPagamento {get;set;}
        public List<Object> consolidadas {get;set;}
        public Datetime dataVencimento {get;set;}
        public String MensagemErroIntegracaoPortalCotacoes {get;set;}
        public String StageName {get;set;}
        public String statusIntegracaoPortal {get;set;}
        public String TabelaPrecoExternalId {get;set;}
        public String tabulacaoN1 {get;set;}
        public String tabulacaoN2 {get;set;}
        public String userTeamMemberId {get;set;}
        public Boolean viewOnly {get;set;}

        public BudgetData(){}

        public BudgetData(Opportunity opp, OpportunityTeamMember oppTeamMember, List<setorizacao__c> setorizacaoList){
            this.oppId = opp.Id;
            this.accountId = opp.AccountId;
            this.accountType = opp.Account?.RecordType?.DeveloperName;
            this.categorias = getCategoriesFromList(setorizacaoList);
            this.CDsBloqueado = opp.CDsBloqueado__c != null ? opp.CDsBloqueado__c : '';
            this.ClienteEmissorId = opp.AccountId;
            this.ClienteEmissorCGC = opp.CNPJ__c == null ? opp.CPF__c : opp.CNPJ__c; 
            this.ClienteEmissorUF = opp.Account?.ShippingState; 
            this.CondicaoPagamento = opp.CondicaoPagamento__c;
            if(String.isNotEmpty(opp.CotacoesConsolidadas__c) && opp.CotacoesConsolidadas__c != '[]'){
                this.consolidadas = (List<Object>)JSON.deserializeUntyped(opp.CotacoesConsolidadas__c);
            }
            this.dataVencimento = opp.DataVencimento__c;
            this.MensagemErroIntegracaoPortalCotacoes = opp.MensagemErroIntegracaoPortalCotacoes__c;
            this.StageName = opp.StageName;
            this.statusIntegracaoPortal = opp.StatusIntegracaoPortalCotacoes__c;
            this.TabelaPrecoExternalId = 'B01';
            
            if(oppTeamMember != null && opp.TabulacaoN1__c != 'Envio Automático' && opp.TabulacaoN1__c != 'Recusa'){
                this.tabulacaoN1 = oppTeamMember.TabulacaoN1__c;
                this.tabulacaoN2 = oppTeamMember.TabulacaoN2__c;
                this.userTeamMemberId = oppTeamMember.Id;
            } else{
                this.tabulacaoN1 = opp.TabulacaoN1__c;
                this.tabulacaoN2 = opp.TabulacaoN2__c;
            }
            
            this.viewOnly = (opp.orcamentoTravado__c || VIEW_ONLY_STAGENAME.contains(opp.StageName));
        }
        
    }

    public static Set<String> getCategoriesFromList(List<Setorizacao__c> setorizacaoList){
        Set<String> categories = new Set<String>();
        for(Setorizacao__c setor : setorizacaoList){
            categories.add(setor.Categoria__c);
        }
        return categories;
    }

    public class BudgetItemData implements Comparable {
        public string idPortal {get;set;}
        public string categoriaCliente {get;set;}
        public string customerDescription {get;set;}
        public string customerMeasurementUnit {get;set;}
        public string dynamicIcon {get;set;}
        public string estoqueStr {get; set;}
        public string favoriteBrands {get;set;}
        public string idCustomer {get;set;}
        public Boolean isEntrega {get; set;}
        public Decimal quantidadeSolicitada {get;set;}
        public String quoteitemUrl {get;set;}
        public Integer sequencia {get;set;}
        public String statusItem {get;set;}
        public String style2Class {get;set;}
        public String styleStatus2Class {get;set;}
        public Boolean tabulatedNotOffered {get;set;}

        public BudgetItemData(){}

        public BudgetItemData(List<QuoteItem__c> qItemList, Map<String, Decimal> saldoEstoqueMap){
            this.idPortal = qItemList[0].IdPortal__c;
            this.categoriaCliente = String.isNotBlank(qItemList[0].CategoriaCliente__c) ? qItemList[0].CategoriaCliente__c : 'Informação não disponível';
            this.customerDescription = qItemList[0].CustomerDescription__c;
            this.customerMeasurementUnit = qItemList[0].CustomerMeasurementUnit__c;
            this.estoqueStr = getEstoqueStr(qItemList, saldoEstoqueMap);
            this.favoriteBrands = qItemList[0].FavoriteBrands__c;
            this.idCustomer = qItemList[0].IdCustomer__c;
            this.isEntrega = validateDeliver(qItemList);
            this.quantidadeSolicitada = qItemList[0].Quantity__c;
            this.quoteitemUrl = '/' + qItemList[0].Id;
            this.sequencia = String.isNotEmpty(qItemList[0].SequenciaOC__c) ? Integer.valueOf(qItemList[0].SequenciaOC__c) : 0;
            putStatusItemAndStyle(this, qItemList);
        }

        public Integer compareTo(Object compareTo) {

            BudgetItemData compareToBudgetItem = (BudgetItemData)compareTo;
            Integer returnValue = 0;

            if ((this.sequencia) > (compareToBudgetItem.sequencia)) {

                returnValue = 1;
            } else if ((this.sequencia) < (compareToBudgetItem.sequencia)) {

                returnValue = -1;
            }

    
            return returnValue;
        }
    }

    public static String getEstoqueStr(List<QuoteItem__c> qItemList, Map<String, Decimal> saldoEstoqueMap){
        /**
         * pode retornar três valores distintos:
         * 1. "Produto não vinculado" (quando não há nenhum produto na resposta)
         * 2. "Informação não disponível" (quando não há informações de estoque para o produtos vinculados)
         * 3. a quantidade(saldo) disponível em estoque para o primeiro produto vinculado com estoque
         */
        String estoqueStr = 'Produto não vinculado';
        for(QuoteItem__c qItem : qItemList){
            if(String.isBlank(qItem.Product__c)){
                continue;
            }
            if(saldoEstoqueMap.containsKey(qItem.Product__c)){
                estoqueStr = String.valueOf(saldoEstoqueMap.get(qItem.Product__c));
                break;
            }else{
                estoqueStr = 'Informação não disponível';
            }
        }
        return estoqueStr;
    }

    public static Boolean validateDeliver(List<QuoteItem__c> qItemList){
        for(QuoteItem__c qItem : qItemList){
            if(String.isNotEmpty(qitem.ProgramacaoEntrega__c) && qitem.ProgramacaoEntrega__c != '[]'){
                return true;
            }
        }
        return false;
    }
    
    public static void putStatusItemAndStyle(BudgetItemData budgetItemData, List<QuoteItem__c> qItemList){
        Integer answeredItems = 0;
        Boolean answeredBySeller = false;
        Boolean hasOffer = false;
        Boolean tabulatedNotOffered = false;
        String resultStyle = '';
        for(QuoteItem__c qItem : qItemList){
            if(String.isNotBlank(qItem.TabulacaoN1__c) && qItem.TabulacaoN1__c != 'SEM OFERTA'){
                answeredItems++;
                if(qItem.Vendedor__c == UserInfo.getUserId()){
                    answeredBySeller = true;
                }
                
                if(!hasOffer){
                    tabulatedNotOffered = true;
                }
            }

            if(qItem.TabulacaoN1__c == 'Cotado'){
                hasOffer = true;
                tabulatedNotOffered = false;
            }
        }

        resultStyle += answeredBySeller ? 'gBack' : 'wBack';
        budgetItemData.style2Class = resultStyle;
        if(answeredItems == qItemList.size()){
            budgetItemData.statusItem = 'TOTALMENTE RESPONDIDO';
            resultStyle += 'gText';
        }else if(answeredItems > 0){
            budgetItemData.statusItem = 'PARCIALMENTE RESPONDIDO';
            resultStyle += 'yText';
        }else{
            budgetItemData.statusItem = 'NENHUMA RESPOSTA';
            resultStyle += 'wText';
        }

        budgetItemData.dynamicIcon = hasOffer ? 'utility:quote' : null;
        budgetItemData.tabulatedNotOffered = tabulatedNotOffered;
        budgetItemData.styleStatus2Class = resultStyle;
    }
}