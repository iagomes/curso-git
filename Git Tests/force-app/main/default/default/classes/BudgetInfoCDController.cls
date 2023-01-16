public without sharing class BudgetInfoCDController {
    
    public static final List<String> PAPEIS_QUE_PODEM_VER_MARGEM = new List<String>{ 'Pricing', 'Coordenador'};

    /* budgetDetailInfoCDContent */
    @AuraEnabled
    public static StandardResponse getGroup(){
       StandardResponse response = new StandardResponse();
        try {
            Boolean verMargem = PAPEIS_QUE_PODEM_VER_MARGEM.contains(
                BudgetDetailSelector.getCurrentUserGroup()?.DeveloperName
            );
            response.setData(verMargem);
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
       return response;
    }

    @AuraEnabled
    public static StandardResponse getDistCenter(String malha, String produto){
        StandardResponse response = new StandardResponse();
        List<BudgetCtrl.DistCenter> distCenterList = new List<BudgetCtrl.DistCenter>();
        try {
            BudgetCtrl.ParamsMalha paramsMalha = (BudgetCtrl.ParamsMalha)JSON.deserialize(malha, BudgetCtrl.ParamsMalha.class);
            BudgetCtrl.ParamsProd paramsProd = (BudgetCtrl.ParamsProd)JSON.deserialize(produto, BudgetCtrl.ParamsProd.class);
            String cnpj = paramsProd.accountType == 'PreConta' ? null : paramsMalha.cnpj;
            String uf = paramsMalha.UF?.length() > 2 ? StringUtils.getSiglaEstado(paramsMalha.UF) : paramsMalha.UF;
            List<Object> malhaCrude = (List<Object>)OrderScreenController.getMalhaApi(
                'InformaticaGetMalhaPortal',
                cnpj,
                uf,
                paramsMalha.productCode,
                paramsMalha.calcMargem,
                paramsMalha.pricebookExternalId,
                paramsMalha.condPagamento,
                paramsMalha.isForaMalha
            );

            List<Estoque__c> estoqueList = BudgetDetailSelector.getEstoqueListByProdCode(paramsMalha.productCode);
            Map<String, List<Estoque__c>> estoqueMapByCNPJCD = (Map<String, List<Estoque__c>>)SObjectUtils.mapObjectsByField(estoqueList, 'CNPJCD__c', true);

            OpportunityLineItem oliWon = BudgetDetailSelector.getLastOppLineItemWon(paramsMalha.productCode, paramsProd.accountId);
            OpportunityLineItem oliLost = BudgetDetailSelector.getLastOppLineItemLost(paramsMalha.productCode, paramsProd.accountId);

            String conversaoUnidadeTexto = getConversaoUnidadeTexto(
                paramsProd.tipoConversao,
                paramsProd.fatorConversao,
                paramsProd.unidadePrincipal,
                paramsProd.unidadeSecundaria
            );

            List<BudgetCtrl.Malha>  malhaList = (List<BudgetCtrl.Malha>)JSON.deserialize((JSON.serialize(malhaCrude)), List<BudgetCtrl.Malha>.class);

            if(malhaList != null && !malhaList.isEmpty()){

                if( malhaList[0].cds != null && !malhaList[0].cds.isEmpty()){

                    List<BudgetCtrl.MalhaData> malhaDataList = malhaList[0].cds;
                    Map<String, List<BudgetCtrl.Badge>> CampaignMap = getCampaignForCDs(paramsMalha.productCode, paramsProd.accountId, malhaDataList);
                    Set<BudgetCtrl.Badge> contractBadges = getContractItemsPrice(paramsProd.accountId, paramsMalha.productCode);
                    for(BudgetCtrl.MalhaData malhaDataUnit : malhaDataList){
                        BudgetCtrl.DistCenter dCUnit = new BudgetCtrl.DistCenter();
                        dCUnit.badges = new List<BudgetCtrl.Badge>();
                        dCUnit.id = malhaDataUnit.cnpj;
                        dCUnit.nome = malhaDataUnit.filial != null ? malhaDataUnit.filial : '';
                        dCUnit.cnpj = malhaDataUnit.cnpj != null ? malhaDataUnit.cnpj : '';
                        dCUnit.preco = malhaDataUnit.preco != null ? malhaDataUnit.preco.setScale(6, RoundingMode.HALF_UP) : 0;
                        dCUnit.precoFabrica = malhaDataUnit.pf != null ? malhaDataUnit.pf.setScale(6, RoundingMode.HALF_UP) : 0;
                        dCUnit.estoque = malhaDataUnit.saldo != null ? malhaDataUnit.saldo : 0;
                        dCUnit.prioridade = malhaDataUnit.prioridade != null ? malhaDataUnit.prioridade : '0';
                        dCUnit.aliquota = malhaDataUnit.aliquota != null ? malhaDataUnit.aliquota : 0;
                        dCUnit.custo = malhaDataUnit.custo != null ? malhaDataUnit.custo : 10;
                        dCUnit.foramalha = malhaDataUnit.foramalha == true;
                        dCUnit.cdBloqueado = !paramsProd.cdsBloqueados.containsIgnoreCase(dCUnit.cnpj);
                        dCUnit.bloqueioRegional = malhaDataUnit.BloqRegionalizacao == true;

                        dCUnit.unidadePrincipal = paramsProd.unidadePrincipal != null ? paramsProd.unidadePrincipal : '';
                        dCUnit.unidadeSecundaria = paramsProd.unidadeSecundaria;
                        dCUnit.conversaoUnidadeTexto = conversaoUnidadeTexto;
                        
                        dCUnit.estoqueSecundario = convertValues(
                            paramsProd.tipoConversao,
                            paramsProd.fatorConversao,
                            dCUnit.estoque
                        )?.setScale(3, RoundingMode.HALF_UP);

                        dCUnit.precoSecundario = inverseConvertValues(
                            paramsProd.tipoConversao,
                            paramsProd.fatorConversao,
                            dCUnit.preco
                        )?.setScale(2, RoundingMode.HALF_UP);

                        dCUnit.precoFabricaSecundario = inverseConvertValues(
                            paramsProd.tipoConversao,
                            paramsProd.fatorConversao,
                            dCUnit.precoFabrica
                        )?.setScale(2, RoundingMode.HALF_UP);

                        dCUnit.quantidadeElfa =  paramsProd.quantidadeSolicitada != null ? paramsProd.quantidadeSolicitada : 0;
                        dCUnit.valorElfa = dCUnit.preco;
                        dCUnit.quantidadePortal = paramsProd.quantidadeSolicitada != null ? paramsProd.quantidadeSolicitada : 0;
                        dCUnit.valorPortal = dCUnit.preco;

                        dCUnit.valorTotal = (dCUnit.quantidadePortal * dCUnit.valorPortal).setScale(2, RoundingMode.HALF_UP);

                        if(oliLost != null){
                            dCUnit.dataPerdido = oliLost.CreatedDate.format('dd/MM/yy');
                            dCUnit.valorPerdido = oliLost.ValorPortal__c.setScale(2, RoundingMode.HALF_UP);
                        }
                        if(oliWon != null){
                            dCUnit.dataGanho = oliWon.CreatedDate.format('dd/MM/yy');
                            dCUnit.valorGanho = oliWon.ValorPortal__c.setScale(2, RoundingMode.HALF_UP);
                        }
                        if(!estoqueMapByCNPJCD.isEmpty()){
                            Estoque__c currentEstoque = estoqueMapByCNPJCD.get(dCUnit.cnpj) != null && !estoqueMapByCNPJCD.get(dCUnit.cnpj).isEmpty() ? estoqueMapByCNPJCD.get(dCUnit.cnpj)[0] : null;
                            Date prevEntrada = currentEstoque != null ? currentEstoque.PrevisaoEntrada__c : null;
                            dCUnit.previsaoEntrada = prevEntrada != null ? prevEntrada.format() : null;
                            dCUnit.quantPrevista = currentEstoque != null ? currentEstoque.QuantidadePrevista__c : null;
                        }

                        dCUnit.badges = CampaignMap.get(malhaDataUnit.cd);
                        dCUnit.badges.addAll(contractBadges);
                        //dCUnit.badges.add(new BudgetCtrl.Badge('O',12.23));

                        dCUnit.desconto = 0;
                        dCUnit.validadeMin = null;
                        dCUnit.margem = 0;
                        dCUnit.margemAlvo = 0;
                        dCUnit.score = 100;
                        
                        distCenterList.add(dCUnit);
                    }
                }
                if(malhaList[0].code != null){
                    response.setData('erro', malhaList[0].code);
                }
                if(malhaList[0].msgErro != null){
                    response.setData('erro', malhaList[0].msgErro);
                }
            }

            response.setData('content', JSON.serialize(distCenterList));
        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    public static String getConversaoUnidadeTexto(String tipoConversao, String fatorConversao, String primeiraUnidade, String segundaUnidade){
        if(
            String.isEmpty(tipoConversao) ||
            String.isEmpty(fatorConversao) ||
            String.isEmpty(segundaUnidade) ||
            String.isEmpty(primeiraUnidade) ||
            fatorConversao == '0' 
        ){
            return null;
        }

        String pattern = '1 {0} = {1} {2}';
        if(tipoConversao == 'M'){
            return String.format(pattern, new List<String>{primeiraUnidade,fatorConversao,segundaUnidade});
        }else if(tipoConversao == 'D'){
            return String.format(pattern, new List<String>{segundaUnidade,fatorConversao,primeiraUnidade});
        }else{
            return null;
        }    
    }

    public static Map<String, List<BudgetCtrl.Badge>> getCampaignForCDs(String productCode, String accountId, List<BudgetCtrl.MalhaData> malhaDataList){
        Map<String, List<BudgetCtrl.Badge>> campaignByCodeCDMap = new Map<String, List<BudgetCtrl.Badge>>();

        List<String> cdCodeListQuery = new List<String>();

        for(BudgetCtrl.MalhaData malhaunit : malhaDataList){
            if(String.isNotEmpty(malhaunit.cd)){
                campaignByCodeCDMap.put(malhaunit.cd, new List<BudgetCtrl.Badge>());
                cdCodeListQuery.add('%'+malhaunit.cd+'%');
            }
        }

        List<ItemCampanha__c> itemCampanhaList = BudgetDetailSelector.getItemCampaignByCD(cdCodeListQuery, productCode, accountId);

        for(ItemCampanha__c campItem : itemCampanhaList){

            if(campItem.Campanha__r.CodigoCD__c == null){
                for(String codeCd : campaignByCodeCDMap.keySet()){
                    campaignByCodeCDMap.get(codeCd).add(
                        new BudgetCtrl.Badge(campItem.Campanha__r.RecordType.DeveloperName, campItem.PrecoUnitario__c)
                    );
                }
            }else{
                List<String> codesList = campItem.Campanha__r.CodigoCD__c.split(';');
                for(String codeCd : codesList){
                    if(campaignByCodeCDMap.get(codeCd) != null){
                        campaignByCodeCDMap.get(codeCd).add(
                            new BudgetCtrl.Badge(campItem.Campanha__r.RecordType.DeveloperName, campItem.PrecoUnitario__c)
                        );
                    }
                }
            }
        }
        return campaignByCodeCDMap;
    }

    public static Set<BudgetCtrl.Badge> getContractItemsPrice(String accountId, String productCode) {
        Set<BudgetCtrl.Badge> badges = new Set<BudgetCtrl.Badge>();
        List<ItemContrato__c> contractItems = BudgetDetailSelector.getContractByProduct(accountId, productCode);
        for(ItemContrato__c item : contractItems){
            badges.add(new BudgetCtrl.Badge(item.NumeroContrato__r.TipoRegra__c, item.PrecoUnitario__c));
        }
        return badges;
    }

    
    public static Decimal convertValues(String tipoConversao, String fatorConversao, Decimal value){
        try{
            Decimal fatCon = fatorConversao != null ? Decimal.valueOf(fatorConversao) : 1;
            if(tipoConversao == 'M'){
                return fatCon > 0 ? value * fatCon : value;
            }else if(tipoConversao == 'D'){
                return fatCon > 0 ? value / fatCon : value;
            }else{
                return value;
            }
        }catch(Exception ex){
            ExceptionUtils.debug(ex);
            return null;
        }
    }

    public static Decimal inverseConvertValues(String tipoConversao, String fatorConversao, Decimal value){
        if(tipoConversao == 'M'){
            return convertValues('D', fatorConversao, value);
        }else if(tipoConversao == 'D'){
            return convertValues('M', fatorConversao, value);
        }else{
            return convertValues(tipoConversao, fatorConversao, value);
        }
    }

    @AuraEnabled
    public static StandardResponse setItemCd(String resp, String cd, String extra){
        StandardResponse response = new StandardResponse();
        try {
            BudgetDetailEditItemController.BudgetResposta item = (BudgetDetailEditItemController.BudgetResposta)JSON.deserialize(resp, BudgetDetailEditItemController.BudgetResposta.class);
            BudgetCtrl.DistCenter dCenter = (BudgetCtrl.DistCenter)JSON.deserialize(cd, BudgetCtrl.DistCenter.class);
            BudgetCtrl.ExtraFields extraFields = (BudgetCtrl.ExtraFields)JSON.deserialize(extra, BudgetCtrl.ExtraFields.class);
            extraFields.tipoConversaoProd = extraFields.tipoConversaoProd == 'D' ? 'DIVIDIR' : extraFields.tipoConversaoProd == 'M' ? 'MULTIPLICAR' : 'NENHUMA';  
            AutomationsController.stop('QuoteItemTH.statusAndProductReset');

            Opportunity opp = BudgetDetailSelector.getOpportunity(extraFields.oppId);
            QuoteItem__c quoteitem = item.buildQuoteItem();
            OpportunityLineItem olItem = quoteitem?.OpportunityLineItem__c != null ? new OpportunityLineItem(Id = quoteitem.OpportunityLineItem__c) : null;         

            List<QuoteItem__c> lstquoteItemCd = BudgetDetailSelector.getQuoteItemForSetItemCd(opp.Id, dCenter.cnpj, quoteitem.Id, quoteitem.IdPortal__c);

            if(lstquoteItemCd.size() == 1 && (quoteitem.Product__c == lstquoteItemCd[0].Product__c)){
                response.addError('Não é permitido ter duas respostas com mesmo Produto e mesmo CD. Selecione outro CD ou Produto.', '201');
                return response;
            }

            if (lstquoteItemCd.size() > 1) {
                response.addError('Na Bionexo só é possível efetuar até duas respostas cotadas para o mesmo CD. Entre em contato com o vendedor que às efetuou, ou verifique a possibilidade de adicionar sua resposta por outro CD.', '201');
                return response;
            }

            if(opp.OrcamentoTravado__c == true){
                response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento', '205');
                return response;
            }

            if(olItem != null){
                olItem.CentroDistribuicao__c = dCenter.nome;
                olItem.CNPJCD__c = dCenter.cnpj;
                olItem.Quantity = dCenter.quantidadeElfa;
                olItem.UnitPrice = dCenter.valorElfa;
                olItem.ValidadeMinima__c = dCenter.validadeMin;
                olItem.ValorPortal__c = dCenter.valorPortal; 
                olItem.QuantidadePortal__c = dCenter.quantidadePortal;
                olItem.foraMalha__c = extraFields.foraMalha;
                olItem.FatorConversao__c = extraFields.fatorConversaoProd;
                olItem.TipoConversao__c  = extraFields.tipoConversaoProd;
                olItem.Comentarios__c  = extraFields.comentario;  
                olItem.ValorCx__c = extraFields.fatorConversaoProd;
                olItem.BloqueadoRegionalizacao__c = dCenter.bloqueioRegional == true;
                update olItem;

            } else {
                List<PricebookEntry> pbeList = BudgetDetailSelector.getPricebookEntryList(quoteItem.Product__c, opp.Pricebook2Id);
                PricebookEntry pbe = new PricebookEntry();
                if(!pbeList.isEmpty()){
                    pbe = pbeList[0];
                }else{
                    pbe = ProductHelper.buildNewPricebookEntry(opp.Pricebook2Id, quoteItem.Product__c, 0);
                    insert pbe;
                }
                olItem = item.buildOpportunityLineItem(opp, quoteItem, pbe);
                olItem.IdCustomer__c = quoteitem.IdCustomer__c;
                olItem.IdIntegrator__c = quoteitem.IdIntegrator__c;
                olItem.CentroDistribuicao__c = dCenter.nome;
                olItem.CNPJCD__c = dCenter.cnpj;
                olItem.Quantity = Integer.valueOf(dCenter.quantidadeElfa);
                olItem.UnitPrice = dCenter.valorElfa;
                olItem.ValidadeMinima__c = dCenter.validadeMin;
                olItem.ForaMalha__c = extraFields.foraMalha;
                olItem.ValorPortal__c = dCenter.valorPortal; 
                olItem.QuantidadePortal__c = dCenter.quantidadePortal;
                olItem.FatorConversao__c = extraFields.fatorConversaoProd;
                olItem.TipoConversao__c  = extraFields.tipoConversaoProd;   
                olItem.Comentarios__c  = extraFields.comentario;   
                olItem.ValorCx__c = extraFields.fatorConversaoProd;
                olItem.BloqueadoRegionalizacao__c = dCenter.bloqueioRegional == true;
                upsert olItem OpportunityLineItem.ExternalId__c;
                
                quoteitem.OpportunityLineItem__c = olItem.Id;
            }
            
            quoteitem.UnitPrice__c = olItem.UnitPrice;
            quoteitem.CNPJCD__c = dCenter.cnpj;
            quoteitem.DataHoraResposta__c = System.now();
            quoteitem.Status__c = 'Vinculado';
            quoteitem.TabulacaoN1__c = 'Cotado';
            quoteitem.FatorConversao__c = extraFields.fatorConversaoProd;
            quoteitem.TipoConversao__c = extraFields.tipoConversaoProd;
            
            Opportunity oppToUpdate = new Opportunity(Id = opp.Id, LastIntegratedItem__c = null);
            if(opp.StageName == 'Novo'){
                oppToUpdate.StageName = 'Em digitação';
            } 
            update oppToUpdate;
            
            List<CondicaoPagamentoPorCD__c> lcdPagCD = BudgetDetailSelector.getConditionPaymentByCD(opp.Id, dCenter.cnpj);
            
            if(lcdPagCD.isEmpty()){
                CondicaoPagamentoPorCD__c cdPagCD = buildCondicaoPagamentoPorCD(opp, dCenter.nome, dCenter.cnpj);
                insert cdPagCD;
                quoteitem.PaymentConditionByDC__c = cdPagCD.Id;
            }else{
                quoteitem.PaymentConditionByDC__c = lcdPagCD[0].Id;
            }
            update quoteitem;
            
            BudgetDetailEditItemController.BudgetResposta budgetResposta = new BudgetDetailEditItemController.BudgetResposta(BudgetDetailSelector.getQuoteItem(item.id));
            response.setData(JSON.serialize(budgetResposta));

        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }

        return response;
    }

    public static CondicaoPagamentoPorCD__c buildCondicaoPagamentoPorCD(Opportunity opp, String cds, String cnpjCd){
        CondicaoPagamentoPorCD__c cpPorCD = new CondicaoPagamentoPorCD__c(
            CentroDistribuicao__c = cds,
            CNPJCD__c = cnpjCd,
            orcamento__c = opp.Id,
            CloseDate__c = opp.CloseDate,
            MinimumBilling__c = opp.MinimumBilling__c,
            ObservacoesLongText__c = opp.ObservacoesLongText__c,
            PrazoEntrega__c = opp.PrazoEntrega__c,
            PrazoValidade__c = opp.PrazoValidade__c,
            FretePicklist__c = 'CIF',
            Integradora__c = opp.CanalEntrada__c,
            ExternalId__c = cnpjCd + '_' + opp.Id
        );
        if(cpPorCD.Integradora__c != 'Bionexo' || cpPorCD.Integradora__c != 'Apoio' || cpPorCD.Integradora__c != 'Sintese'){
            cpPorCD.Integradora__c = 'Bionexo';
        }
        
        Map<String, List<String>> filtredPickList = SobjectUtils.getDependentPicklistValues('CondicaoPagamentoPorCD__c','CondicaoPagamentoPL__c');
        if(opp.Account.CondicaoPagamento__c != null && filtredPickList.get(cpPorCD.Integradora__c) != null && filtredPickList.get(cpPorCD.Integradora__c).contains(opp.Account.CondicaoPagamento__r.Name)){
            cpPorCD.CondicaoPagamento__c = opp.Account.CondicaoPagamento__c;
            cpPorCD.CondicaoPagamentoPL__c = opp.Account.CondicaoPagamento__r.Name;

        }else if(opp.CondicaoPagamento__c != null && filtredPickList.get(cpPorCD.Integradora__c) != null && filtredPickList.get(cpPorCD.Integradora__c).contains(opp.CondicaoPagamento__r.Name)){
            cpPorCD.CondicaoPagamento__c = opp.CondicaoPagamento__c;
            cpPorCD.CondicaoPagamentoPL__c = opp.CondicaoPagamento__r.Name;
        }
        return cpPorCD;
        
    }

    public static void deleteOldPaymentConditions(String oppId){

        List<QuoteItem__c> items = BudgetDetailSelector.getQuoteItemsWithCNPJCD(oppId);
        if(!items.isEmpty()){
            Map<String,List<QuoteItem__c>> mapQuoteItemsByCNPJCd = (Map<String,List<QuoteItem__c>>) SObjectUtils.mapObjectsByField(items, 'CNPJCD__c');

            List<CondicaoPagamentoPorCD__c> lstCds = BudgetDetailSelector.getConditionPaymentList(oppId);
            List<CondicaoPagamentoPorCD__c> lstCdsToDelete = new List<CondicaoPagamentoPorCD__c>();
            
            for(CondicaoPagamentoPorCD__c cond : lstCds){
                if(!mapQuoteItemsByCNPJCd.containsKey(cond.CNPJCD__c)){
                    lstCdsToDelete.add(cond);
                }
                
            }
            if(!lstCdsToDelete.isEmpty()){
                delete lstCdsToDelete;
            }            

        }
    }

    /* budgetDetailInfoCDConverter */
    @AuraEnabled
    public static StandardResponse getFatorProduto(String prodId, String quoteitemId){
        
        StandardResponse response = new StandardResponse();
        Map<String, String> responseData = new Map<String, String>(); 

        QuoteItem__c quoteItem = BudgetDetailSelector.getQuoteItem(quoteitemId);

        try {

            if(quoteItem.Product__c != null){
                // Map<String, String> fatorMap = getFatorConversao(
                //     quoteItem.Product__r.FatorConversaoPortal__c,
                //     quoteItem.Product__r.FatorConversao__c,
                //     quoteItem.CustomerMeasurementUnit__c
                // );
                // responseData.put('tipoConversaoProd', fatorMap.get('tipo'));
                // responseData.put('fatorConversaoProd', fatorMap.get('fator'));
                
                
                if(quoteItem.Product__r.TipoConversao__c == 'M'){
                    responseData.put('tipoConversaoProd', 'D');
                    responseData.put('fatorConversaoProd', quoteItem.Product__r.FatorConversao__c);
                }else{
                    responseData.put('tipoConversaoProd', 'N');
                    responseData.put('fatorConversaoProd', '1');
                } // RETIRADO PARA CONTEMPLAR PORTAL-1448

            }

            response.setData(JSON.serialize(responseData));

        }catch(Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError(ex.getMessage());
        }
        return response;
    }

    @TestVisible
    private static Map<String, String> getFatorConversao(String fatorConversaoPortal, String fatorConversaoGen, String unidadePrincipal){
        
        Map<String, String> result = new Map<String, String>();

        String fatVal = String.isNotEmpty(fatorConversaoPortal) ? fatorConversaoPortal : String.isNotEmpty(fatorConversaoGen) ? fatorConversaoGen : null; 
        String convType = 'D';
        if(unidadePrincipal.containsIgnoreCase('caixa')  || unidadePrincipal.containsIgnoreCase('pacote') ){    
            convType = 'N';
        }
        result.put('fator',fatVal);
        result.put('tipo',convType);
        return result;
    }

    @AuraEnabled
    public static StandardResponse updateProduct(String prod, String relatedOppLineItem){
        StandardResponse response = new StandardResponse();
        try {
            if(String.isNotBlank(prod)){
                Product2 prodRec = (Product2)JSON.deserialize(prod, Product2.class);
                update new Product2(
                    Id = prodRec.Id,
                    FatorConversaoPortal__c = prodRec.FatorConversaoPortal__c,
                    TipoConversaoPortal__c = prodRec.TipoConversaoPortal__c,
                    CadastranteFator__c = UserInfo.getUserId(),
                    FatorConversaoData__c = System.now()
                );
                response.setData(prodRec);
            }

            if(String.isNotBlank(relatedOppLineItem)){
                OpportunityLineItem oli = (OpportunityLineItem) JSON.deserialize(relatedOppLineItem, OpportunityLineItem.class);
                if (oli.Id != null && String.isNotBlank(oli.Id)) {
                    update new OpportunityLineItem(
                        Id = oli.Id,
                        Comentarios__c = oli.comentarios__c
                    );
                }
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            response.addError(e.getMessage());
        }
        return response;
    }
}
