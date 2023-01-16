global without sharing class BudgetController {

    // public static final List<String> PAPEIS_QUE_PODEM_VER_MARGEM = new List<String>{ 'Pricing', 'Coordenador'};
    // public static final List<String> VIEW_ONLY_STAGENAME = new List<String>{'Cancelada', 'Sem Retorno', 'Não Respondida', 'Não Ganha'};

    // @TestVisible
    // private static Boolean verMargem {
    //     get {
    //         if(verMargem == null){
    //             verMargem = PAPEIS_QUE_PODEM_VER_MARGEM.contains([SELECT DeveloperName FROM Group WHERE RelatedId IN (SELECT UserRoleId FROM User WHERE Id =: UserInfo.getUserId()) LIMIT 1]?.DeveloperName);
    //         }
    //         return verMargem;
    //     }
    //     set;
    // }
    
    // @AuraEnabled
    // public static StandardResponse getDistCenter(String malha, String produto){
    //     StandardResponse response = new StandardResponse();
    //     List<BudgetCtrl.DistCenter> distCenterList = new List<BudgetCtrl.DistCenter>();
    //     try {
    //         BudgetCtrl.ParamsMalha paramsMalha = (BudgetCtrl.ParamsMalha)JSON.deserialize(malha, BudgetCtrl.ParamsMalha.class);
    //         BudgetCtrl.ParamsProd paramsProd = (BudgetCtrl.ParamsProd)JSON.deserialize(produto, BudgetCtrl.ParamsProd.class);
    //         String cnpj = paramsProd.accountType == 'PreConta' ? null : paramsMalha.cnpj;
    //         String uf = paramsMalha.UF?.length() > 2 ? StringUtils.getSiglaEstado(paramsMalha.UF) : paramsMalha.UF;
    //         List<Object> malhaCrude = (List<Object>)OrderScreenController.getMalhaApi(
    //             'InformaticaGetMalhaPortal',
    //             cnpj,
    //             uf,
    //             paramsMalha.productCode,
    //             paramsMalha.calcMargem,
    //             paramsMalha.pricebookExternalId,
    //             paramsMalha.condPagamento,
    //             paramsMalha.isForaMalha
    //         );

    //         List<Estoque__c> estoqueList = [
    //             SELECT CNPJCD__c, PrevisaoEntrada__c, QuantidadePrevista__c
    //             FROM Estoque__c
    //             WHERE CodigoProduto__c = :paramsMalha.productCode
    //         ];
    //         Map<String, List<Estoque__c>> estoqueMapByCNPJCD = (Map<String, List<Estoque__c>>)SObjectUtils.mapObjectsByField(estoqueList, 'CNPJCD__c', true);

    //         List<OpportunityLineItem> loliWon = [
    //             SELECT Id, ValorPortal__c, CreatedDate
    //             FROM OpportunityLineItem
    //             WHERE Product2.ProductCode = :paramsMalha.productCode
    //             AND Opportunity.AccountId = :paramsProd.accountId
    //             AND Opportunity.StageName = 'Gerar Pedido'
    //             AND ValorPortal__c > 0
    //             ORDER BY CreatedDate DESC LIMIT 1
    //         ];

    //         List<OpportunityLineItem> loliLost = [
    //             SELECT Id, ValorPortal__c, CreatedDate
    //             FROM OpportunityLineItem
    //             WHERE Product2.ProductCode = :paramsMalha.productCode
    //             AND Opportunity.AccountId = :paramsProd.accountId
    //             AND Opportunity.StageName = 'Sem Retorno'
    //             AND ValorPortal__c > 0
    //             ORDER BY CreatedDate
    //             DESC LIMIT 1
    //         ];
    //         String conversaoUnidadeTexto = getConversaoUnidadeTexto(
    //             paramsProd.tipoConversao,
    //             paramsProd.fatorConversao,
    //             paramsProd.unidadePrincipal,
    //             paramsProd.unidadeSecundaria
    //         );

    //         List<BudgetCtrl.Malha>  malhaList = (List<BudgetCtrl.Malha>)JSON.deserialize((JSON.serialize(malhaCrude)), List<BudgetCtrl.Malha>.class);

    //         System.debug(JSON.serialize(malhaList));
    //         if(malhaList != null && !malhaList.isEmpty()){

    //             if( malhaList[0].cds != null && !malhaList[0].cds.isEmpty()){

    //                 List<BudgetCtrl.MalhaData> malhaDataList = malhaList[0].cds;
    //                 Map<String, List<BudgetCtrl.Badge>> CampaignMap = getCampaignForCDs(paramsMalha.productCode, paramsProd.accountId, malhaDataList);
    //                 Set<BudgetCtrl.Badge> contractBadges = getContractItemsPrice(paramsProd.accountId, paramsMalha.productCode);
    //                 for(BudgetCtrl.MalhaData malhaDataUnit : malhaDataList){
    //                     BudgetCtrl.DistCenter dCUnit = new BudgetCtrl.DistCenter();
    //                     dCUnit.badges = new List<BudgetCtrl.Badge>();
    //                     dCUnit.id = malhaDataUnit.cnpj;
    //                     dCUnit.nome = malhaDataUnit.filial != null ? malhaDataUnit.filial : '';
    //                     dCUnit.cnpj = malhaDataUnit.cnpj != null ? malhaDataUnit.cnpj : '';
    //                     dCUnit.preco = malhaDataUnit.preco != null ? malhaDataUnit.preco.setScale(6, RoundingMode.HALF_UP) : 0;
    //                     dCUnit.precoFabrica = malhaDataUnit.pf != null ? malhaDataUnit.pf.setScale(6, RoundingMode.HALF_UP) : 0;
    //                     dCUnit.estoque = malhaDataUnit.saldo != null ? malhaDataUnit.saldo : 0;
    //                     dCUnit.prioridade = malhaDataUnit.prioridade != null ? malhaDataUnit.prioridade : '0';
    //                     dCUnit.aliquota = malhaDataUnit.aliquota != null ? malhaDataUnit.aliquota : 0;
    //                     dCUnit.custo = malhaDataUnit.custo != null ? malhaDataUnit.custo : 10;
    //                     dCUnit.foramalha = malhaDataUnit.foramalha == true;
    //                     dCUnit.cdBloqueado = !paramsProd.cdsBloqueados.containsIgnoreCase(dCUnit.cnpj);
    //                     dCUnit.bloqueioRegional = malhaDataUnit.BloqRegionalizacao == true;

    //                     dCUnit.unidadePrincipal = paramsProd.unidadePrincipal != null ? paramsProd.unidadePrincipal : '';
    //                     dCUnit.unidadeSecundaria = paramsProd.unidadeSecundaria;
    //                     dCUnit.conversaoUnidadeTexto = conversaoUnidadeTexto;
                        
    //                     dCUnit.estoqueSecundario = convertValues(
    //                         paramsProd.tipoConversao,
    //                         paramsProd.fatorConversao,
    //                         dCUnit.estoque
    //                     )?.setScale(3, RoundingMode.HALF_UP);

    //                     dCUnit.precoSecundario = inverseConvertValues(
    //                         paramsProd.tipoConversao,
    //                         paramsProd.fatorConversao,
    //                         dCUnit.preco
    //                     )?.setScale(2, RoundingMode.HALF_UP);

    //                     dCUnit.precoFabricaSecundario = inverseConvertValues(
    //                         paramsProd.tipoConversao,
    //                         paramsProd.fatorConversao,
    //                         dCUnit.precoFabrica
    //                     )?.setScale(2, RoundingMode.HALF_UP);

    //                     dCUnit.quantidadeElfa =  paramsProd.quantidadeSolicitada != null ? paramsProd.quantidadeSolicitada : 0;
    //                     dCUnit.valorElfa = dCUnit.preco;
    //                     dCUnit.quantidadePortal = paramsProd.quantidadeSolicitada != null ? paramsProd.quantidadeSolicitada : 0;
    //                     dCUnit.valorPortal = dCUnit.preco;

    //                     dCUnit.valorTotal = (dCUnit.quantidadePortal * dCUnit.valorPortal).setScale(2, RoundingMode.HALF_UP);

    //                     if(!loliLost.isEmpty()){
    //                         dCUnit.dataPerdido = loliLost[0].CreatedDate.format('dd/MM/yy');
    //                         dCUnit.valorPerdido = loliLost[0].ValorPortal__c.setScale(2, RoundingMode.HALF_UP);
    //                     }
    //                     if(!loliWon.isEmpty()){
    //                         dCUnit.dataGanho = loliWon[0].CreatedDate.format('dd/MM/yy');
    //                         dCUnit.valorGanho = loliWon[0].ValorPortal__c.setScale(2, RoundingMode.HALF_UP);
    //                     }
    //                     if(!estoqueMapByCNPJCD.isEmpty()){
    //                         Estoque__c currentEstoque = estoqueMapByCNPJCD.get(dCUnit.cnpj) != null && !estoqueMapByCNPJCD.get(dCUnit.cnpj).isEmpty() ? estoqueMapByCNPJCD.get(dCUnit.cnpj)[0] : null;
    //                         Date prevEntrada = currentEstoque != null ? currentEstoque.PrevisaoEntrada__c : null;
    //                         dCUnit.previsaoEntrada = prevEntrada != null ? prevEntrada.format() : null;
    //                         dCUnit.quantPrevista = currentEstoque != null ? currentEstoque.QuantidadePrevista__c : null;
    //                     }

    //                     dCUnit.badges = CampaignMap.get(malhaDataUnit.cd);
    //                     dCUnit.badges.addAll(contractBadges);
    //                     //dCUnit.badges.add(new BudgetCtrl.Badge('O',12.23));

    //                     dCUnit.desconto = 0;
    //                     dCUnit.validadeMin = null;
    //                     dCUnit.margem = 0;
    //                     dCUnit.margemAlvo = 0;
    //                     dCUnit.score = 100;
                        
    //                     distCenterList.add(dCUnit);
    //                 }
    //             }
    //             if(malhaList[0].code != null){
    //                 response.setData('erro', malhaList[0].code);
    //             }
    //             if(malhaList[0].msgErro != null){
    //                 response.setData('erro', malhaList[0].msgErro);
    //             }
    //         }

    //         response.setData('content', JSON.serialize(distCenterList));
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // public static Map<String, List<BudgetCtrl.Badge>> getCampaignForCDs(String productCode, String accountId, List<BudgetCtrl.MalhaData> malhaDataList){
    //     Map<String, List<BudgetCtrl.Badge>> campaignByCodeCDMap = new Map<String, List<BudgetCtrl.Badge>>();

    //     List<String> cdCodeListQuery = new List<String>();

    //     for(BudgetCtrl.MalhaData malhaunit : malhaDataList){
    //         if(String.isNotEmpty(malhaunit.cd)){
    //             campaignByCodeCDMap.put(malhaunit.cd, new List<BudgetCtrl.Badge>());
    //             cdCodeListQuery.add('%'+malhaunit.cd+'%');
    //         }
    //     }

    //     List<ItemCampanha__c> itemCampanhaList = [
    //         SELECT Campanha__r.RecordType.DeveloperName,
    //         NomeProduto__c, PrecoUnitario__c, Campanha__r.CodigoCD__c
    //         FROM ItemCampanha__c
    //         WHERE NomeProduto__r.ProductCode = :productCode
    //         AND (
    //             Campanha__r.Cliente__c = :accountId 
    //             OR (Campanha__r.Cliente__c = null AND Campanha__r.GrupoCliente__c = null)
    //         )
    //         AND (
    //             (Campanha__r.StartDate <= TODAY AND Campanha__r.EndDate >= TODAY) 
    //             OR (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY)
    //         )
    //         AND (
    //             Campanha__r.CodigoCD__c = NULL 
    //             OR Campanha__r.CodigoCD__c LIKE :cdCodeListQuery
    //         )
    //         ORDER BY Campanha__r.CodigoCD__c ASC NULLS LAST
    //     ];

    //     for(ItemCampanha__c campItem : itemCampanhaList){

    //         if(campItem.Campanha__r.CodigoCD__c == null){
    //             for(String codeCd : campaignByCodeCDMap.keySet()){
    //                 campaignByCodeCDMap.get(codeCd).add(
    //                     new BudgetCtrl.Badge(campItem.Campanha__r.RecordType.DeveloperName, campItem.PrecoUnitario__c)
    //                 );
    //             }
    //         }else{
    //             List<String> codesList = campItem.Campanha__r.CodigoCD__c.split(';');
    //             for(String codeCd : codesList){
    //                 if(campaignByCodeCDMap.get(codeCd) != null){
    //                     campaignByCodeCDMap.get(codeCd).add(
    //                         new BudgetCtrl.Badge(campItem.Campanha__r.RecordType.DeveloperName, campItem.PrecoUnitario__c)
    //                     );
    //                 }
    //             }
    //         }
    //     }
    //     return campaignByCodeCDMap;
    // }

    // public static Set<BudgetCtrl.Badge> getContractItemsPrice(String accountId, String productCode) {
    //     Set<BudgetCtrl.Badge> badges = new Set<BudgetCtrl.Badge>();
    //     List<ItemContrato__c> contractItems = [
    //         SELECT NomeProduto__c, PrecoMinimo__c, PrecoUnitario__c,
    //         NumeroContrato__c, NumeroContrato__r.TipoRegra__c
    //         FROM ItemContrato__c 
    //         WHERE NumeroContrato__r.AccountId = :accountId
    //         AND NumeroContrato__r.TipoRegra__c IN ('O', 'A')
    //         AND Status__c = 'Aprovado'
    //         AND (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY)
    //         AND NomeProduto__r.ProductCode = :productCode
    //     ];
    //     for(ItemContrato__c item : contractItems){
    //         badges.add(new BudgetCtrl.Badge(item.NumeroContrato__r.TipoRegra__c, item.PrecoUnitario__c));
    //     }
    //     return badges;
    // }

    // @AuraEnabled
    // public static StandardResponse getGroup(){
    //    StandardResponse response = new StandardResponse();
    //     try {
    //         response.setData(verMargem);
    //     } catch (Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //    return response;
    // }

    // @AuraEnabled
    // public static StandardResponse getFatorProduto(String prodId, String quoteitemId ){
        
    //     StandardResponse response = new StandardResponse();
    //     Map<String, String> responseData = new Map<String, String>(); 

    //     QuoteItem__c quoteItem = [
    //         SELECT Id, CustomerMeasurementUnit__c, OpportunityId__c, OpportunityId__r.AccountId, Product__c,
    //         Product__r.FatorConversao__c, Product__r.FatorConversaoPortal__c, OpportunityLineItem__c,
    //         Product__r.TipoConversaoPortal__c, Product__r.UnidadeMedida__c, Product__r.TipoConversao__c
    //         FROM QuoteItem__c
    //         WHERE Id =: quoteitemId
    //     ];

    //     try {

    //         if(quoteItem.Product__c != null){
    //             // Map<String, String> fatorMap = getFatorConversao(
    //             //     quoteItem.Product__r.FatorConversaoPortal__c,
    //             //     quoteItem.Product__r.FatorConversao__c,
    //             //     quoteItem.CustomerMeasurementUnit__c
    //             // );
    //             // responseData.put('tipoConversaoProd', fatorMap.get('tipo'));
    //             // responseData.put('fatorConversaoProd', fatorMap.get('fator'));
    //             //RETIRADO PARA CONTEMPLAR PORTAL-1295 ponto 2 e 3
                
    //             if(quoteItem.Product__r.TipoConversao__c == 'M'){
    //                 responseData.put('tipoConversaoProd', 'D');
    //                 responseData.put('fatorConversaoProd', quoteItem.Product__r.FatorConversao__c);
    //             }else{
    //                 responseData.put('tipoConversaoProd', 'N');
    //                 responseData.put('fatorConversaoProd', '1');
    //             }

    //         }

    //         response.setData(JSON.serialize(responseData));

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // private static Map<String, String> getFatorConversao(String fatorConversaoPortal, String fatorConversaoGen, String unidadePrincipal){
        
    //     Map<String, String> result = new Map<String, String>();
    //     String portalFatCon = fatorConversaoPortal; //StringUtils.removeNonNumericCharacters(fatorConversaoPortal);
    //     String genericFatCon = StringUtils.removeNonNumericCharacters(fatorConversaoGen);

    //     String fatVal = portalFatCon != null && portalFatCon != '' ? portalFatCon : genericFatCon != null && genericFatCon != '' ? genericFatCon : null; 
    //     String convType = 'D';
    //     if(unidadePrincipal.containsIgnoreCase('caixa')  || unidadePrincipal.containsIgnoreCase('pacote') ){    
    //         convType = 'N';
    //     }
    //     result.put('fator',fatVal);
    //     result.put('tipo',convType);
    //     return result;
    // }

    // private static String getConversaoUnidadeTexto(String tipoConversao, String fatorConversao, String primeiraUnidade, String segundaUnidade){
    //     if(
    //         String.isEmpty(tipoConversao) ||
    //         String.isEmpty(fatorConversao) ||
    //         String.isEmpty(segundaUnidade) ||
    //         String.isEmpty(primeiraUnidade) ||
    //         fatorConversao == '0' 
    //     ){
    //         return null;
    //     }

    //     String pattern = '1 {0} = {1} {2}';
    //     if(tipoConversao == 'M'){
    //         return String.format(pattern, new List<String>{primeiraUnidade,fatorConversao,segundaUnidade});
    //     }else if(tipoConversao == 'D'){
    //         return String.format(pattern, new List<String>{segundaUnidade,fatorConversao,primeiraUnidade});
    //     }else{
    //         return null;
    //     }    
    // }

    // public static Decimal convertValues(String tipoConversao, String fatorConversao, Decimal value){
    //     try{
    //         Decimal fatCon = fatorConversao != null ? Decimal.valueOf(fatorConversao) : 1;
    //         if(tipoConversao == 'M'){
    //             return fatCon > 0 ? value * fatCon : value;
    //         }else if(tipoConversao == 'D'){
    //             return fatCon > 0 ? value / fatCon : value;
    //         }else{
    //             return value;
    //         }
    //     }catch(Exception ex){
    //         ExceptionUtils.debug(ex);
    //         return null;
    //     }
    // }

    // public static Decimal inverseConvertValues(String tipoConversao, String fatorConversao, Decimal value){
    //     if(tipoConversao == 'M'){
    //         return convertValues('D', fatorConversao, value);
    //     }else if(tipoConversao == 'D'){
    //         return convertValues('M', fatorConversao, value);
    //     }else{
    //         return convertValues(tipoConversao, fatorConversao, value);
    //     }
    // }

    // @AuraEnabled
    // public static StandardResponse getQuoteItems(String oppId, List<String> quoteItemIds){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         BudgetData data = new BudgetData(oppId, quoteItemIds);
    //         response.setData(data);
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse setItemTabulacaoN1(List<String> quoteItemIdsPortal, String oppId, String accId, List<String> categorias, String tabulacaoN1){
    //     StandardResponse response = new StandardResponse();
    //     try {

    //         Id userId = UserInfo.getUserId();
    //         List<QuoteItem__c> quoteItensUpsertList = new List<QuoteItem__c>();
    //         Map<String, List<String>> idPortalMapByCategory = new Map<String, List<String>>();
    //         for(String category : categorias){
    //             idPortalMapByCategory.put(category, new List<String>(quoteItemIdsPortal));
    //         }

    //         List<QuoteItem__c> quoteItems = [
    //             SELECT Id, IdPortal__c, Vendedor__c, OpportunityId__r.StageName, Categoria__c
    //             FROM QuoteItem__c 
    //             WHERE IdPortal__c IN: quoteItemIdsPortal 
    //                 AND OpportunityId__c =: oppId
    //                 AND Vendedor__c =: userId
    //                 AND TabulacaoN1__c !=: tabulacaoN1
    //                 AND Categoria__c IN :categorias
    //         ];
            
    //         //Portal-980 problema de multitabulação
    //         for(QuoteItem__c qItem: quoteItems){
    //             List<String> categoryList = idPortalMapByCategory.get(qItem.Categoria__c);
    //             Integer indexCategoty = categoryList.indexOf(qItem.IdPortal__c);
    //             qItem.Status__c = tabulacaoN1 == 'Não tem no portifólio' ? 'Não Vinculado' : 'Vinculado';
    //             qItem.TabulacaoN1__c = tabulacaoN1;
    //             qItem.DataHoraResposta__c = system.now();
    //             qItem.VendedorRespondeu__c = userInfo.getUserId();
    //             quoteItensUpsertList.add(qItem);
    //             //removendo da lista do mapa de idportal por categoria.
    //             if(indexCategoty >= 0)categoryList.remove(indexCategoty);
    //         }
    //         Set<String> idPortalQueryList = new Set<String>();
    //         for(List<String> idportalList : idPortalMapByCategory.values()){
    //             idPortalQueryList.addAll(idportalList);
    //         }
    //         if(!idPortalQueryList.isEmpty()){
    //             List<QuoteItem__c> quoteItemsListToCopy = [
    //                 SELECT OpportunityId__c, IdIntegrator__c, IdPortal__c,
    //                 IdCustomer__c, ProdutosVinculadosAnteriormente__c, Quantity__c,  
    //                 CustomerDescription__c, CustomerMeasurementUnit__c, OpportunityId__r.StageName,
    //                 SequenciaOC__c, IntegratorMeasurementUnit__c, OpportunityId__r.ExternalPortal__c
    //                 FROM QuoteItem__c 
    //                 WHERE IdPortal__c IN : idPortalQueryList
    //                 AND OpportunityId__c = :oppId
    //             ];
    //             Map<String, QuoteItem__c> qItemMapToCopyByIdPortal = new Map<String, QuoteItem__c>();
    //             for(QuoteItem__c qItem : quoteItemsListToCopy){
    //                 qItemMapToCopyByIdPortal.put(qItem.IdPortal__c, qItem);
    //             }
    
    //             for(String category : idPortalMapByCategory.keySet()){
    //                 for(String idPortal : idPortalMapByCategory.get(category)){
    //                     QuoteItem__c qItemToCopy = qItemMapToCopyByIdPortal.get(idPortal);
    //                     QuoteItem__c newQi = qItemToCopy.clone(false, false, false, false);
    //                     newQi.Vendedor__c = UserInfo.getUserId();
    //                     newQi.Categoria__c = category;
    //                     newQi.CNPJCD__c = null;
    //                     newQi.ExternalId__c = qItemToCopy.OpportunityId__r?.ExternalPortal__c + category + newQi.IdPortal__c + newQi.Vendedor__c + Datetime.now();
    //                     newQi.Status__c = tabulacaoN1 == 'Não tem no portifólio' ? 'Não Vinculado' : 'Vinculado';
    //                     newQi.TabulacaoN1__c = tabulacaoN1;
    //                     newQi.Product__c = null;
    //                     newQi.DataHoraResposta__c = system.now();
    //                     quoteItensUpsertList.add(newQi);
    //                 }
    //             }
    //         }

    //         AutomationsController.stop('QuoteItemTH.statusAndProductReset');
    //         upsert quoteItensUpsertList;
    //         system.debug(JSON.serializePretty(quoteItensUpsertList));
    //         if(!quoteItensUpsertList.isEmpty() && quoteItensUpsertList[0].OpportunityId__r.StageName == 'Novo'){
    //             update new Opportunity(Id= oppId, StageName = 'Em digitação');
    //         }
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }


    // @AuraEnabled
    // public static StandardResponse saveBudget(Opportunity opp, Boolean sendBudgetToPortal, String cdValues){
    //     Savepoint sp;
        
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         if(String.isNotEmpty(cdValues)){
    //             System.debug('cdValues '+ cdValues);
    //             saveConditionPayment(response, cdValues);
    //             if(response.hasError){
    //                 return response;
    //             }
    //         }

    //         List<OpportunityTeamMember> lstOppTeamMembers = [SELECT ID, TabulacaoN1__c, TabulacaoN2__c FROM OpportunityTeamMember WHERE OpportunityId =: opp.Id AND UserId =: UserInfo.getUserId() FOR UPDATE];
            
    //         if(!lstOppTeamMembers.isEmpty()){
    //             lstOppTeamMembers[0].TabulacaoN1__c = opp.TabulacaoN1__c;
    //             lstOppTeamMembers[0].TabulacaoN2__c = opp.TabulacaoN2__c;
    //         }
    //         else{
    //             OpportunityTeamMember oppTM = new OpportunityTeamMember(
    //                 TabulacaoN1__c = opp.TabulacaoN1__c,
    //                 TabulacaoN2__c = opp.TabulacaoN2__c,
    //                 UserId = UserInfo.getUserId(),
    //                 OpportunityId = opp.Id,
    //                 AllQuotes__c = 0,
    //                 AnsweredQuotes__c = 0,
    //                 TeamMemberRole = 'Sales Rep',
    //                 OpportunityAccessLevel = 'Edit'
    //             );
    //             lstOppTeamMembers.add(oppTM);
    //         }
        
    //         if(sendBudgetToPortal){

    //             if(!lstOppTeamMembers.isEmpty() && (lstOppTeamMembers[0].TabulacaoN1__c == null || lstOppTeamMembers[0].TabulacaoN2__c == null)){ // valida pela oportunidade caso o usuário não possua OpportunityTeamMember
    //                 return response.addError('Os campos de "TabulaçãoN1" e "TabulaçãoN2" da cotação são obrigatórios para preenchimento');
    //             }

    //             // if(
    //             //     !lstOppTeamMembers.isEmpty() &&
    //             //     (lstOppTeamMembers[0].TabulacaoN1__c != 'Improdutiva' || lstOppTeamMembers[0].TabulacaoN2__c != 'Bloqueio Financeiro')
    //             // ){
    //             //     Boolean noAnswerFound = true;
    //             //     List<QuoteItem__c> lstQuoteItems = [
    //             //         SELECT Id, 
    //             //             Categoria__c,
    //             //             CustomerDescription__c,
    //             //             IdPortal__c,
    //             //             OpportunityId__r.DataVencimento__c, 
    //             //             TabulacaoN1__c, 
    //             //             Vendedor__c,
    //             //             VendedorRespondeu__c,
    //             //             Status__c
    //             //         FROM
    //             //             QuoteItem__c 
    //             //         WHERE 
    //             //             OpportunityId__c =: opp.Id
    //             //     ];
    //             //     for(QuoteItem__c item : lstQuoteItems){
    //             //         if( (item.Vendedor__c == UserInfo.getUserId()) && (String.isBlank(item.TabulacaoN1__c)) ){
    //             //             return response.addError('Antes de enviar cotação você deve responder todos os produtos que estão em sua BU: O item "' +
    //             //                 item.CustomerDescription__c + '" não foi respondido corretamente.'
    //             //             );
    //             //         }
    //             //         if(item.VendedorRespondeu__c == UserInfo.getUserId()){
    //             //             noAnswerFound = false;
    //             //         }
    //             //     }
    //             //     if(noAnswerFound){
    //             //         return response.addError('Para enviar a cotação é necessário efetuar as respostas dos itens');
    //             //     }
    //             // }
            
    //             if(!lstOppTeamMembers.isEmpty()){
    //                 if(lstOppTeamMembers[0].TabulacaoN2__c != 'Cotação Vencida'){
    //                     if([SELECT Id, DataVencimento__c FROM Opportunity WHERE Id =: opp.Id].DataVencimento__c <= Datetime.now()){
    //                         return response.addError('Não é permitido responder um orçamento vencido.');
    //                     }
    //                 }
    //             }
             
    //         }
        
    //         sp = Database.setSavepoint();

    //         if(sendBudgetToPortal && !response.hasError){
    //             opp.LastIntegratedItem__c = null;
    //             update opp;
    //         }else if(opp.StageName == 'Novo'){
    //             opp.StageName = 'Em digitação';
    //             update opp;
    //         }
            
    //         if(!lstOppTeamMembers.isEmpty()){
    //             upsert lstOppTeamMembers[0];
    //         }
            
    //         if(sendBudgetToPortal && !response.hasError){

    //             if(String.isBlank(opp.TabulacaoN1__c) || String.isBlank(opp.TabulacaoN2__c)){
    //                 response.addError('Os campos de "TabulaçãoN1" e "TabulaçãoN2" da cotação são obrigatórios para preenchimento');
    //             } else {
    //                 System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(0, new List<Id>{opp.Id}));
    //             }
    //         }
            
    //     } catch(Exception ex) {
    //         if(sp != null){
    //             Database.rollback(sp);
    //         }
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static list<Object> getConsolidatedBudget(String oppId){
    //     list<Object> response = new list<Object>(); 
    //     response = [SELECT Id, AccountId, Account.Name, Account.CNPJ__c, Account.CPF__c FROM Order WHERE OpportunityId =: oppId ];
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse getConditionPayment(String oppId){
    //     StandardResponse response = new StandardResponse();
    //     List<String> cnpjList = new List<String>();
    //     List<DistCenterDTO> responsedata = new List<DistCenterDTO>();
    //     try {
    //         List<CondicaoPagamentoPorCD__c> condPayCDlist = [
    //             SELECT Id, CentroDistribuicao__c, CNPJCD__c, CloseDate__c, FretePicklist__c,
    //             CondicaoPagamentoPL__c, PrazoValidade__c, PrazoEntrega__c, MinimumBilling__c,
    //             ObservacoesLongText__c
    //             FROM CondicaoPagamentoPorCD__c 
    //             WHERE orcamento__c =: oppId 
    //         ];
    //         for(CondicaoPagamentoPorCD__c conpg : condPayCDlist){
    //             cnpjList.add(conpg.CNPJCD__c);
    //         }
    //         Map<String,SomatoriaDTO> sumaryMap = getSumaryResponse(oppId, cnpjList);
    //         for(CondicaoPagamentoPorCD__c cd : condPayCDlist){
    //             DistCenterDTO distCenter = new DistCenterDTO(sumaryMap.get(cd.CNPJCD__c), cd);
    //             responsedata.add(distCenter);
    //         }
    //         response.setData(JSON.serialize(responsedata));
           
    //     } catch (Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
        
    //     return response;
    // }
    
    // @AuraEnabled
    // public static Map<String,SomatoriaDTO> getSumaryResponse(String oppId, List<String> CNPJList){
    //     Map<String,SomatoriaDTO> response = new Map<String,SomatoriaDTO>();
    //     Decimal AmountOK = 0;
    //     //response.resp = 0;
    //     //response.totItem = 0;
        
    //     for(List<QuoteItem__c> listOli: [
    //         SELECT OpportunityLineItem__r.QuantidadePortal__c, OpportunityLineItem__r.ValorPortal__c,
    //         OpportunityLineItem__r.CNPJCD__c, OpportunityId__r.QuantidadeItensTotal__c  
    //         FROM QuoteItem__c 
    //         WHERE Product__c != null 
    //         AND OpportunityLineItem__c != null
    //         AND OpportunityId__c =: oppId ORDER BY Product__c
    //     ]){
            
    //         for(QuoteItem__c oli: listOli){
    //             if(response.get(oli.OpportunityLineItem__r.CNPJCD__c) == null){
    //                 response.put(oli.OpportunityLineItem__r.CNPJCD__c, new SomatoriaDTO());

    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).resp = 0;
    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).totItem = 0;
    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).qtdItensTotal = 0;
    //             }
                
    //             Decimal qntPortal = oli.OpportunityLineItem__r.QuantidadePortal__c != null ? oli.OpportunityLineItem__r.QuantidadePortal__c : 0;
    //             Decimal valuePortal = oli.OpportunityLineItem__r.ValorPortal__c != null ? oli.OpportunityLineItem__r.ValorPortal__c : 0;
    //             Decimal totItem = qntPortal * valuePortal; 
    //             AmountOK += totItem;

    //             if(!CNPJList.isEmpty() && CNPJList.contains(oli.OpportunityLineItem__r?.CNPJCD__c)){
    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).totItem += totItem;
    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).qtdItensTotal = oli.OpportunityId__r.QuantidadeItensTotal__c;
    //                 response.get(oli.OpportunityLineItem__r.CNPJCD__c).resp++;
    //             }
    //         }
    //     }
        
    //     if(AmountOK != 0){
    //         try {
    //             Opportunity opp = new Opportunity();
    //             opp.Id = oppId;
    //             opp.TotalPortal__c = AmountOK.setScale(6, RoundingMode.HALF_UP);
    //             update opp;
    //         } catch (Exception ex) {}
    //     }
    //     for(SomatoriaDTO resp : response.values()){
    //         resp.totItem = resp.totItem.setScale(6, RoundingMode.HALF_UP);
    //     }

    //     return response;
    // }
  
    // public class SomatoriaDTO  {
    //     @AuraEnabled
    //     public Decimal resp             {get; set;}
    //     @AuraEnabled
    //     public Decimal totItem          {get; set;}
    //     @AuraEnabled
    //     public Double qtdItensTotal      {get; set;}
        
    //     public SomatoriaDTO(){
    //         this.resp = 0;
    //         this.totItem = 0;
    //         this.qtdItensTotal = 0;
    //     }
    // }

    // public class DistCenterDTO {
    //     public Decimal resp {get;set;}
    //     public Decimal totItem {get;set;}
    //     public Double qtdItensTotal {get;set;}
    //     public String Id {get;set;}
    //     public String CentroDistribuicao {get;set;}
    //     public String CNPJCD {get;set;}
    //     public String FretePicklist {get;set;}
    //     public String CondicaoPagamentoPL {get;set;}
    //     public String ObservacoesLongText {get;set;}
    //     public Date CloseDate {get; set;}
    //     public Decimal PrazoValidade {get;set;}
    //     public Decimal PrazoEntrega {get;set;}
    //     public Decimal MinimumBilling {get;set;}

    //     public DistCenterDTO(SomatoriaDTO sum, CondicaoPagamentoPorCD__c cd){
    //         this.resp = sum.resp;
    //         this.totItem = sum.totItem;
    //         this.qtdItensTotal = sum.qtdItensTotal;

    //         this.Id = cd.Id;
    //         this.CentroDistribuicao = cd.CentroDistribuicao__c;
    //         this.CNPJCD = cd.CNPJCD__c;
    //         this.FretePicklist = cd.FretePicklist__c;
    //         this.CondicaoPagamentoPL = cd.CondicaoPagamentoPL__c;
    //         this.ObservacoesLongText = cd.ObservacoesLongText__c;
    //         this.CloseDate = cd.CloseDate__c;
    //         this.PrazoValidade = cd.PrazoValidade__c;
    //         this.PrazoEntrega = cd.PrazoEntrega__c;
    //         this.MinimumBilling = cd.MinimumBilling__c;
    //     }

    //     public CondicaoPagamentoPorCD__c build(){
    //         return new CondicaoPagamentoPorCD__c(
    //             Id = this.Id,
    //             CentroDistribuicao__c = this.CentroDistribuicao,
    //             CNPJCD__c = this.CNPJCD,
    //             FretePicklist__c = this.FretePicklist,
    //             CondicaoPagamentoPL__c = this.CondicaoPagamentoPL,
    //             ObservacoesLongText__c = this.ObservacoesLongText,
    //             CloseDate__c = this.CloseDate,
    //             PrazoValidade__c = this.PrazoValidade,
    //             PrazoEntrega__c = this.PrazoEntrega,
    //             MinimumBilling__c = this.MinimumBilling
    //         );
    //     }
    // }

    // @AuraEnabled
    // public static StandardResponse saveConditionPayment(StandardResponse response, String jsonRequest){
    //     //System.debug('\n\n inital: '+jsonRequest);
    //     List<DistCenterDTO> distCenterList = (List<DistCenterDTO>)JSON.deserialize(jsonRequest, List<DistCenterDTO>.class);
    //     List<CondicaoPagamentoPorCD__c> listCondPagCD = new List<CondicaoPagamentoPorCD__c>();
    //     List<String> condPagNameList = new List<String>();
    //     try {
    //         for(DistCenterDTO distCenter : distCenterList){
    //             CondicaoPagamentoPorCD__c condPag = distCenter.build();
    //             condPagNameList.add(condPag.CondicaoPagamentoPL__c);
    //             if(validateConditionPayment(condPag) && !response.hasError){
    //                 response.addError('Preencha todos os campos dos CDs.');
    //             }
    //             listCondPagCD.add(condPag);
    //         }

    //         List<CondicaoPagamento__c> conditionPaymentList = [
    //             SELECT Id, Name
    //             FROM CondicaoPagamento__c
    //             WHERE Name IN :condPagNameList
    //         ];

    //         Map<String, String> conditionPaymentMap = new Map<String, String>();
    //         for(CondicaoPagamento__c cp : conditionPaymentList){
    //             conditionPaymentMap.put(cp.Name, cp.Id);
    //         }

    //         for(CondicaoPagamentoPorCD__c condPagCD : listCondPagCD){
    //             condPagCD.CondicaoPagamento__c = conditionPaymentMap.get(condPagCD.CondicaoPagamentoPL__c);
    //             if(condPagCD.CondicaoPagamento__c == null  && !response.hasError){
    //                 response.addError('Condição de pagamento mal cadastrada, selecione outra para continuar.');
    //             }
    //         }

    //         Database.update(listCondPagCD);
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // public class QuoteItemsDTO {
    //     public List<QuoteItem__c> items { get;set; }

    //     public QuoteItemsDTO(String jsonReqBody){
    //         this.items = (List<QuoteItem__c>)JSON.deserialize(jsonReqBody, List<QuoteItem__c>.class);
    //     }
    // }

    // public static Boolean validateConditionPayment(CondicaoPagamentoPorCD__c cd){
    //     return (
    //         cd.MinimumBilling__c        == null ||
    //         cd.CloseDate__c             == null ||
    //         cd.PrazoEntrega__c          == null ||
    //         cd.PrazoValidade__c         == null ||
    //         cd.CondicaoPagamentoPL__c   == null ||
    //         cd.CNPJCD__c                == null ||
    //         cd.FretePicklist__c         == null ||
    //         cd.CondicaoPagamentoPL__c   == ''   ||
    //         cd.CNPJCD__c                == ''   ||
    //         cd.FretePicklist__c         == ''   ||
    //         cd.MinimumBilling__c        <= 0    ||
    //         cd.PrazoEntrega__c          <= 0    ||
    //         cd.PrazoValidade__c         <= 0    
    //     );
        
    // }

    // @AuraEnabled
    // public static StandardResponse changeOpportunityLineItemStatus(String jsonReqBody){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         QuoteItemsDTO result = new QuoteItemsDTO(jsonReqBody);
            
    //         Map<Id,QuoteItem__c> mapItems = new Map<Id, QuoteItem__c>(result.items);

    //         Set<Id> setQuoteIds = new Set<Id>();
    //         Set<Id> setQuoteIds2 = new Set<Id>();
    //         for(QuoteItem__c item: result.items){
    //             setQuoteIds2.add(item.Id);
    //             // if(mapItems.get(item.Id)?.Status__c != null){
    //             //     item.Status__c = mapItems.get(item.Id).Status__c;
    //             // }
    //             if(mapItems.get(item.Id)?.TabulacaoN1__c != null){   
    //                 item.DataHoraResposta__c = system.now();
    //                 item.VendedorRespondeu__c = UserInfo.getUserId();                
    //                 if(item.TabulacaoN1__c == 'Cotado'){
    //                     setQuoteIds.add(item.Id);
    //                 }else{
    //                     item.TabulacaoN1__c = mapItems.get(item.Id).TabulacaoN1__c;
    //                 }
    //             }else{
    //                 item.TabulacaoN1__c = null;
    //             }
                
    //         }

    //         Opportunity opp = getOppWithQuoteItemByQuoteItemIds(setQuoteIds2);
    //         if(opp.OrcamentoTravado__c == true){
                
    //             response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento','205');
    //             return response;
    //         }

    //         if (setQuoteIds.size() > 0 ) {

    //             QuoteItem__c quoteitem = opp.QuoteItems__r[0];    
    
    //             List<QuoteItem__c> lstquoteItemIdPortal  = [
    //                 SELECT id 
    //                 FROM QuoteItem__c 
    //                 WHERE OpportunityId__c =: opp.Id 
    //                 AND Id !=: quoteitem.Id 
    //                 AND TabulacaoN1__c = 'Cotado'
    //                 AND IdPortal__c =: quoteitem.IdPortal__c
    //                 AND OpportunityId__r.CanalEntrada__c = 'Bionexo' 
    //             ];
                            
    //             if(lstquoteItemIdPortal.size() >= 2) {
    //                 response.addError('Não é permitido enviar mais de duas ofertas para o mesmo item da Bionexo.');
    //             }else{

    //                 Database.update(result.items);
    //                 response.setData('items', result.items);
    //             }
    //         }else{
    //             Database.update(result.items);
    //             response.setData('items', result.items);
    //         }
    //         if(opp != null && opp.StageName == 'Novo'){
    //             update new Opportunity(Id = opp.Id, StageName = 'Em digitação'); 
    //         }
           
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse setComentario(String comentario, String oppLineItemId ){
    //     StandardResponse response = new StandardResponse();

    //     OpportunityLineItem olItem = new OpportunityLineItem();
    //     olItem.Comentarios__c  = comentario;  
    //     olItem.Id = oppLineItemId;
    //     update olItem;
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse setItemCd(String resp, String cd, String extra){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         BudgetItemData item = (BudgetItemData)JSON.deserialize(resp, BudgetItemData.class);
    //         BudgetCtrl.DistCenter dCenter = (BudgetCtrl.DistCenter)JSON.deserialize(cd, BudgetCtrl.DistCenter.class);
    //         BudgetCtrl.ExtraFields extraFields = (BudgetCtrl.ExtraFields)JSON.deserialize(extra, BudgetCtrl.ExtraFields.class);
    //         extraFields.tipoConversaoProd = extraFields.tipoConversaoProd == 'D' ? 'DIVIDIR' : extraFields.tipoConversaoProd == 'M' ? 'MULTIPLICAR' : 'NENHUMA';  
    //         AutomationsController.stop('QuoteItemTH.statusAndProductReset');

    //         Opportunity opp = getOppWithQuoteItemByQuoteItemIds(new Set<Id>{item.id});
    //         QuoteItem__c quoteitem = opp.QuoteItems__r[0];
            
    //         OpportunityLineItem olItem = quoteitem?.OpportunityLineItem__c != null ? quoteitem.OpportunityLineItem__r : null;         

    //         List<QuoteItem__c> lstquoteItemCd = [
    //             SELECT Id, Product__c
    //             FROM QuoteItem__c 
    //             WHERE OpportunityId__c =: opp.Id 
    //             AND CNPJCD__c =: dCenter.cnpj 
    //             AND Id !=: quoteitem.Id 
    //             AND IdPortal__c =: quoteitem.IdPortal__c
    //         ];

    //         if(lstquoteItemCd.size() == 1 && (quoteitem.Product__c == lstquoteItemCd[0].Product__c)){
    //             response.addError('Não é permitido ter duas respostas com mesmo Produto e mesmo CD. Selecione outro CD ou Produto.', '201');
    //             return response;
    //         }

    //         if (lstquoteItemCd.size() > 1) {
    //             response.addError('Na Bionexo só é possível efetuar até duas respostas cotadas para o mesmo CD. Entre em contato com o vendedor que às efetuou, ou verifique a possibilidade de adicionar sua resposta por outro CD.', '201');
    //             return response;
    //         }

    //         if(opp.OrcamentoTravado__c == true){
    //             response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento', '205');
    //             return response;
    //         }

    //         if(olItem != null){

    //             olItem.CentroDistribuicao__c = dCenter.nome;
    //             olItem.CNPJCD__c = dCenter.cnpj;
    //             olItem.Quantity = dCenter.quantidadeElfa;
    //             olItem.UnitPrice = dCenter.valorElfa;
    //             // olItem.ValorCx__c =  Decimal.valueOf(quoteitem.Product__r.FatorConversao__c) == 0 ? valor : quoteitem.Product__r.TipoConversao__c == 'M' ? valor * Decimal.valueOf(quoteitem.Product__r.FatorConversao__c) : valor / Decimal.valueOf(quoteitem.Product__r.FatorConversao__c);
    //             olItem.ValidadeMinima__c = dCenter.validadeMin;
    //             olItem.ValorPortal__c = dCenter.valorPortal; 
    //             olItem.QuantidadePortal__c = dCenter.quantidadePortal;
    //             olItem.foraMalha__c = extraFields.foraMalha;
    //             olItem.FatorConversao__c = extraFields.fatorConversaoProd;
    //             olItem.TipoConversao__c  = extraFields.tipoConversaoProd;
    //             olItem.Comentarios__c  = extraFields.comentario;  
    //             olItem.ValorCx__c = extraFields.fatorConversaoProd;
    //             olItem.BloqueadoRegionalizacao__c = dCenter.bloqueioRegional == true;

    //             update olItem;

    //         } else {
    //             // System.debug('passou >>>>>>>>>>>>> b');
                
    //             olItem = buildOLItem(opp, quoteItem, dCenter.nome, dCenter.cnpj, Integer.valueOf(dCenter.quantidadeElfa), dCenter.valorElfa, dCenter.validadeMin, extraFields.foraMalha);
    //             olItem.ValorPortal__c = dCenter.valorPortal; 
    //             olItem.QuantidadePortal__c = dCenter.quantidadePortal;
    //             olItem.FatorConversao__c = extraFields.fatorConversaoProd;
    //             olItem.TipoConversao__c  = extraFields.tipoConversaoProd;   
    //             olItem.Comentarios__c  = extraFields.comentario;   
    //             olItem.ValorCx__c = extraFields.fatorConversaoProd;
    //             olItem.BloqueadoRegionalizacao__c = dCenter.bloqueioRegional == true;
    //             upsert olItem OpportunityLineItem.ExternalId__c;
                
    //             quoteitem.OpportunityLineItem__c = olItem.Id;
    //         }
            
    //         quoteitem.UnitPrice__c = olItem.UnitPrice;
    //         quoteitem.CNPJCD__c = dCenter.cnpj;
    //         quoteitem.DataHoraResposta__c = System.now();
    //         quoteitem.Status__c = 'Vinculado';
    //         quoteitem.TabulacaoN1__c = 'Cotado';
    //         quoteitem.FatorConversao__c = extraFields.fatorConversaoProd;
    //         quoteitem.TipoConversao__c = extraFields.tipoConversaoProd;
    //         update quoteitem;

    //         update new Opportunity(Id = opp.Id, LastIntegratedItem__c = null);
    //         quoteitem = opp.QuoteItems__r[0];

    //         List<CondicaoPagamentoPorCD__c> lcdPagCD = [
    //             SELECT Id, 
    //                 CondicaoPagamento__c,
    //                 CondicaoPagamentoPL__c,
    //                 CloseDate__c,
    //                 MinimumBilling__c,
    //                 ObservacoesLongText__c,
    //                 Orcamento__c,
    //                 PrazoEntrega__c,
    //                 PrazoValidade__c,
    //                 FretePicklist__c 
    //             FROM CondicaoPagamentoPorCD__c 
    //             WHERE orcamento__c =: opp.Id 
    //                 AND  CNPJCD__c =: dCenter.cnpj
    //         ];
            
    //         if(lcdPagCD.isEmpty()){
    //             CondicaoPagamentoPorCD__c cdPagCD = buildCondicaoPagamentoPorCD(opp, dCenter.nome, dCenter.cnpj);
    //             insert cdPagCD;
    //         }

    //         BudgetItemData iData = new BudgetItemData(quoteitem, opp, new Map<String,String>{dCenter.cnpj => dCenter.nome});

    //         deleteOldPaymentConditions(opp.Id);
    //         response.setData('item', iData);

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }

    //     return response;
    // }

    // @TestVisible
    // private static void deleteOldPaymentConditions(String oppId){

    //     List<QuoteItem__c> items = [SELECT CNPJCD__c FROM QuoteItem__c WHERE CNPJCD__c != NULL AND OpportunityId__c =: oppId];
    //     if(!items.isEmpty()){
    //         Map<String,List<QuoteItem__c>> mapQuoteItemsByCNPJCd = (Map<String,List<QuoteItem__c>>) SObjectUtils.mapObjectsByField(items, 'CNPJCD__c');

    //         List<CondicaoPagamentoPorCD__c> lstCdsToDelete = new List<CondicaoPagamentoPorCD__c>();
            
    //         for(CondicaoPagamentoPorCD__c cond: [SELECT ID, CNPJCD__c FROM CondicaoPagamentoPorCD__c WHERE Orcamento__c =: oppId AND CNPJCD__c != NULL]){
    //             if(!mapQuoteItemsByCNPJCd.containsKey(cond.CNPJCD__c)){
    //                 lstCdsToDelete.add(cond);
    //             }
    //         }
    //         if(!lstCdsToDelete.isEmpty()){
    //             delete lstCdsToDelete;
    //         }            

    //     }
    // }

    // @AuraEnabled
    // public static StandardResponse updateProduct(String prod, String relatedOppLineItem){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         if(String.isNotBlank(prod)){
    //             Product2 prodRec = (Product2)JSON.deserialize(prod, Product2.class);
    //             update new Product2(
    //                 Id = prodRec.Id,
    //                 FatorConversaoPortal__c = prodRec.FatorConversaoPortal__c,
    //                 TipoConversaoPortal__c = prodRec.TipoConversaoPortal__c,
    //                 CadastranteFator__c = UserInfo.getUserId(),
    //                 FatorConversaoData__c = System.now()
    //             );
    //             response.setData(prodRec);
    //         }

    //         if(String.isNotBlank(relatedOppLineItem)){
    //             OpportunityLineItem oli = (OpportunityLineItem) JSON.deserialize(relatedOppLineItem, OpportunityLineItem.class);
    //             if (oli.Id != null && String.isNotBlank(oli.Id)) {
    //                 update new OpportunityLineItem(
    //                     Id = oli.Id,
    //                     Comentarios__c = oli.comentarios__c
    //                 );
    //             }
    //         }
    //     }catch(Exception e){
    //         System.debug(e.getMessage());
    //         response.addError(e.getMessage());
    //     }
    //     return response;
    // }

    // @TestVisible
    // private static CondicaoPagamentoPorCD__c buildCondicaoPagamentoPorCD(Opportunity opp, String cds, String cnpjCd){
    //     CondicaoPagamentoPorCD__c cpPorCD = new CondicaoPagamentoPorCD__c(
    //         CentroDistribuicao__c = cds,
    //         CNPJCD__c = cnpjCd,
    //         orcamento__c = opp.Id,
    //         CloseDate__c = opp.CloseDate,
    //         MinimumBilling__c = opp.MinimumBilling__c,
    //         ObservacoesLongText__c = opp.ObservacoesLongText__c,
    //         PrazoEntrega__c = opp.PrazoEntrega__c,
    //         PrazoValidade__c = opp.PrazoValidade__c,
    //         FretePicklist__c = 'CIF',
    //         Integradora__c = opp.CanalEntrada__c
    //     );
    //     if(cpPorCD.Integradora__c != 'Bionexo' || cpPorCD.Integradora__c != 'Apoio' || cpPorCD.Integradora__c != 'Sintese'){
    //         cpPorCD.Integradora__c = 'Bionexo';
    //     }
        
    //     Map<String, List<String>> filtredPickList = SobjectUtils.getDependentPicklistValues('CondicaoPagamentoPorCD__c','CondicaoPagamentoPL__c');
    //     if(opp.Account.CondicaoPagamento__c != null && filtredPickList.get(cpPorCD.Integradora__c) != null && filtredPickList.get(cpPorCD.Integradora__c).contains(opp.Account.CondicaoPagamento__r.Name)){
    //         cpPorCD.CondicaoPagamento__c = opp.Account.CondicaoPagamento__c;
    //         cpPorCD.CondicaoPagamentoPL__c = opp.Account.CondicaoPagamento__r.Name;

    //     }else if(opp.CondicaoPagamento__c != null && filtredPickList.get(cpPorCD.Integradora__c) != null && filtredPickList.get(cpPorCD.Integradora__c).contains(opp.CondicaoPagamento__r.Name)){
    //         cpPorCD.CondicaoPagamento__c = opp.CondicaoPagamento__c;
    //         cpPorCD.CondicaoPagamentoPL__c = opp.CondicaoPagamento__r.Name;
    //     }
    //     return cpPorCD;
        
    // }

    // @TestVisible
    // private static OpportunityLineItem buildOLItem(Opportunity opp, QuoteItem__c quoteItem, String cds, String cnpjCd, Integer quantidade, Decimal valor, String validadeMinima, Boolean foraMalha){
    //     map<String,OpportunityLineItem> mOli = new map<String,OpportunityLineItem>();
    //     for(OpportunityLineItem oli :[SELECT Id, Opportunity.StageName, CreatedDate ,  UnitPrice, ValorUn__c, ValorCx__c , ValorPortal__c
    //                                         FROM OpportunityLineItem 
    //                                         WHERE Product2Id = :quoteItem.Product__c 
    //                                         AND Opportunity.AccountId = :opp.AccountId 
    //                                         AND  Opportunity.StageName IN ('Fechado/Gerado','Gerar Pedido', 'Ganha') 
    //                                         ORDER BY CreatedDate DESC ]){
    //             mOli.put('Ganho', oli);
    //             break;
    //     }
    //     for(OpportunityLineItem oli :[SELECT Id, Opportunity.StageName, CreatedDate ,  UnitPrice, ValorUn__c, ValorCx__c , ValorPortal__c
    //                                         FROM OpportunityLineItem 
    //                                         WHERE Product2Id = :quoteItem.Product__c 
    //                                         AND Opportunity.AccountId = :opp.AccountId 
    //                                         AND  Opportunity.StageName IN ('Fechado/Perdido','Cancelada', 'Perdida', 'Não Respondida', 'Sem Retorno', 'Não Ganha') 
    //                                         ORDER BY CreatedDate DESC ]){
    //             mOli.put('Perdido', oli);
    //             break;
    //     }
            
    //     Product2 product = [
    //         SELECT 
    //             Id,
    //             ExternalId__c,
    //             (
    //                 SELECT Id, UnitPrice
    //                 FROM PricebookEntries
    //                 WHERE 
    //                     IsActive = TRUE
    //                     AND Pricebook2Id =: opp.Pricebook2Id
    //                 LIMIT 1
    //             )
    //         FROM Product2 
    //         WHERE Id =: quoteItem.Product__c
    //     ];

    //     PricebookEntry pbe = getPricebookEntry(product, opp.Pricebook2Id);
        
    //     return new OpportunityLineItem(
    //         ExternalId__c = (quoteItem.Id + '_' + quoteitem.IdPortal__c + (quoteitem.Vendedor__c != null ? '_' + quoteitem.Vendedor__c : '')),
    //         IdCustomer__c = quoteitem.IdCustomer__c,
    //         IdIntegrator__c = quoteitem.IdIntegrator__c,
    //         IdPortal__c = quoteitem.IdPortal__c,
    //         OpportunityId = opp.Id,
    //         Product2Id = quoteItem.Product__c,
    //         SequenciaOC__c = quoteitem.SequenciaOC__c,
    //         Status__c = 'Vinculado',
    //         PricebookEntryId = pbe.Id,
    //         CentroDistribuicao__c = cds,
    //         CNPJCD__c = cnpjCd,
    //         Quantity = quantidade,
    //         UnitPrice = valor,
    //         ValidadeMinima__c = validadeMinima,
    //         ForaMalha__c = foraMalha,
    //         ValorPedidoGanho__c = (mOli.containsKey('Ganho')) ? (mOli.get('Ganho').ValorPortal__c != null && mOli.get('Ganho').ValorPortal__c != 0  ) ? mOli.get('Ganho').ValorPortal__c: mOli.get('Ganho').UnitPrice : 0,
    //         ValorPedidoPerdido__c = (mOli.containsKey('Perdido')) ? (mOli.get('Perdido').ValorPortal__c != null && mOli.get('Perdido').ValorPortal__c != 0) ? mOli.get('Perdido').ValorPortal__c: mOli.get('Perdido').UnitPrice:0,
    //         DataPedidoGanho__c = (mOli.containsKey('Ganho')) ? date.valueOf(mOli.get('Ganho').CreatedDate): null,
    //         DataPedidoPerdido__c = (mOli.containsKey('Perdido')) ? date.valueOf(mOli.get('Perdido').CreatedDate) : null
    //     );
    // }

    // @AuraEnabled
    // public static StandardResponse getQuoteItemKeys(String oppId){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         Map<String,Integer> mapQuoteItemsByIntegratorId = new Map<String, Integer>();
    //         AggregateResult[] groupedResults = [
    //             SELECT 
    //                 IdPortal__c,
    //                 count(Id)
    //             FROM QuoteItem__c 
    //             WHERE OpportunityId__c =: oppId
    //             GROUP BY IdPortal__c
    //             ORDER BY IdPortal__c DESC
    //         ];
    //         for (AggregateResult ar : groupedResults)  {
    //             mapQuoteItemsByIntegratorId.put((String)ar.get('IdPortal__c'), (Integer)ar.get('expr0'));
    //         }
    //         response.setData('mapQuoteItemsByIntegratorId', mapQuoteItemsByIntegratorId);
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse vincularProduto(String quoteitemId, String productId){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         AutomationsController.stop('QuoteItemTH.statusAndProductReset');

    //         if(String.isEmpty(productId)){
    //             return response.addError('Não foi possível identificar o produto.');
    //         } else if(String.isEmpty(quoteitemId)){
    //             return response.addError('Não foi possível identificar o item da cotação.');
    //         }

    //         Opportunity opp = getOppWithQuoteItemByQuoteItemIds(new Set<Id>{quoteitemId});
    //         if(opp.OrcamentoTravado__c == true){
    //             return response.addError('Não é possível adicionar mais respostas, a cotação já foi enviada para integradora devido estar próxima ao vencimento', '205');
    //         }
    //         QuoteItem__c quoteitem = !opp.QuoteItems__r.isEmpty() ? opp.QuoteItems__r[0] : null;
    //         OpportunityLineItem item = quoteitem != null && quoteitem.OpportunityLineItem__c != null ? quoteitem.OpportunityLineItem__r : null;
            
            
    //         // System.debug('passou >>>>>>>>>>>>> a');
    //         if(String.isBlank(opp.CondicaoPagamento__c)){
    //             // System.debug('passou >>>>>>>>>>>>> a.1');
    //             response.addError('A condição de pagamento deve ser especificada antes de responder a uma cotação.');
    //         }

    //         if(quoteitem.Status__c == 'Resgatado' || quoteitem.Status__c == 'Aprovado'){
    //             // System.debug('passou >>>>>>>>>>>>> a.2');
    //             return response.addError('Não é possível alterar o vínculo deste produto, pois já foi gerado um pedido.');

    //             // if(quoteitem.OpportunityLineItem__c != null){
    //             //     // System.debug('passou >>>>>>>>>>>>> a.2.1');
    //             //     update new OpportunityLineItem(Id = quoteitem.OpportunityLineItem__c, UnitPrice = 0, Status__c = 'CANCELADO', IdPortal__c = 'CANCELADO:' + Datetime.now() + ':' + quoteitem.IdPortal__c);
    //             // }
    //         } else if(quoteitem.OpportunityLineItem__c != null && quoteitem.Product__c != productId){
    //             // System.debug('passou >>>>>>>>>>>>> a.3');
    //             delete item;
    //         }
    //         if(quoteitem.Product__c != productId){
    //             quoteitem.CNPJCD__c = null;
    //             quoteitem.UnitPrice__c = null;
    //             quoteitem.OpportunityLineItem__c = null;
    //             quoteItem.Product__c = productId;
    //             quoteitem.StatusIntegracaoVinculoProdutos__c = 'Não integrado';
    //             quoteItem.DataHoraResposta__c = system.now();
    //             //PORTAL-980 revisar
    //             quoteItem.Status__c = 'Vinculado';
    //             quoteItem.TabulacaoN1__c = null;
    //             update quoteItem;
    //         }
            
    //         response.setData('item', getUpdatedItem(quoteItemId));
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @TestVisible
    // private static BudgetItemData getUpdatedItem(String quoteItemId){
    //     Opportunity opp = getOppWithQuoteItemByQuoteItemIds(new Set<Id>{quoteitemId});
    //     QuoteItem__c quoteitem = opp.QuoteItems__r[0];
    //     return new BudgetItemData(quoteitem, opp, new Map<String,String>());
    // }

    // @TestVisible
    // private static Opportunity getOppWithQuoteItemByQuoteItemIds(Set<Id> qItemIds){
    //     List<Opportunity> lstOpps = [
    //         SELECT Id,
    //             AccountId,
    //             Account.BillingCity,
    //             Account.BillingCountry,
    //             Account.BillingPostalCode,
    //             Account.BillingState,
    //             Account.BillingStreet,
    //             Account.Bloqueado__c,
    //             Account.CondicaoPagamento__c,
    //             Account.CondicaoPagamento__r.Name,
    //             Account.ExternalId__c,
    //             Account.GeraBoleto__c,
    //             Account.GrauRisco__c,
    //             Account.Name,
    //             Account.Observacoes__c,
    //             Account.Saldo__c,
    //             Account.TabelaPrecos__c,
    //             Account.TabelaPrecos__r.Name,
    //             Account.TipoCliente__c,
    //             Account.ShippingState,
    //             Amount,
    //             CanalEntrada__c,
    //             CanalVendas__c,
    //             CloseDate,
    //             CNPJ__c,
    //             CondicaoPagamento__c,
    //             CondicaoPagamento__r.Name,
    //             ContatoOrcamento__c,
    //             CPF__c,
    //             DatasParcelas__c,
    //             Description,
    //             FormaPagamento__c,
    //             Frete__c,
    //             FretePicklist__c,
    //             ExternalPortal__c,
    //             Margem__c,
    //             MargemAlvo__c,
    //             MotivoCancelamento__c,
    //             NumeroOrcamento__c,
    //             ObservacoesLongText__c,
    //             ObservacoesCliente__c,
    //             PrazoValidade__c,
    //             Pricebook2Id,
    //             Pricebook2.ExternalId__c,
    //             Pricebook2.Name,
    //             QuantidadeItensConfirmados__c,
    //             QuantidadeItensQualificados__c,
    //             RecomendacaoRespondida__c,
    //             Score__c,
    //             CDsBloqueado__c,
    //             StageName,
    //             MinimumBilling__c,
    //             PrazoEntrega__c,
    //             TabulacaoN1__c,
    //             TabulacaoN2__c,
    //             OrcamentoTravado__c,
    //             (
    //                 SELECT 
    //                     Id,
    //                     CNPJCD__c,
    //                     LastModifiedDate,
    //                     Categoria__c,
    //                     CategoriaCliente__c,
    //                     CustomerDescription__c,
    //                     CustomerMeasurementUnit__c,
    //                     FavoriteBrands__c,
    //                     IdIntegrator__c,
    //                     IdPortal__c,
    //                     IdCustomer__c,
    //                     Name,
    //                     ProdutosVinculadosAnteriormente__c,
    //                     ProgramacaoEntrega__c,
    //                     Quantity__c,
    //                     Status__c,
    //                     UnitPrice__c,
    //                     SequenciaOC__c,
    //                     TabulacaoN1__c,
    //                     OpportunityId__r.AccountId,
    //                     OpportunityId__r.CanalEntrada__c,
    //                     OpportunityLineItem__c,
    //                     OpportunityLineItem__r.FatorConversao__c,
    //                     OpportunityLineItem__r.TipoConversao__c,
    //                     OpportunityLineItem__r.CategoriaComercial__c,
    //                     OpportunityLineItem__r.CentroDistribuicao__c,
    //                     OpportunityLineItem__r.CNPJCD__c,
    //                     OpportunityLineItem__r.Custo__c,
    //                     OpportunityLineItem__r.Discount,
    //                     OpportunityLineItem__r.ExternalId__c,
    //                     OpportunityLineItem__r.ForaMalha__c,
    //                     OpportunityLineItem__r.Imposto__c,
    //                     OpportunityLineItem__r.ListPrice,
    //                     OpportunityLineItem__r.Lote__c,
    //                     OpportunityLineItem__r.MargemAlvo__c,
    //                     OpportunityLineItem__r.MargemAtual__c,
    //                     OpportunityLineItem__r.PosicaoInsercao__c,
    //                     OpportunityLineItem__r.PosicaoItem__c,
    //                     OpportunityLineItem__r.PricebookEntry.PrecoFabrica__c,
    //                     OpportunityLineItem__r.PricebookEntry.UnitPrice,
    //                     OpportunityLineItem__r.PricebookEntryId,
    //                     OpportunityLineItem__r.PrincipioAtivo__c,
    //                     OpportunityLineItem__r.QuantidadeUn__c,
    //                     OpportunityLineItem__r.Quantity,
    //                     OpportunityLineItem__r.Range__c,
    //                     OpportunityLineItem__r.ScoreBU__c,
    //                     OpportunityLineItem__r.ScoreItem__c,
    //                     OpportunityLineItem__r.ScoreMix__c,
    //                     OpportunityLineItem__r.SequenciaOC__c,
    //                     OpportunityLineItem__r.Status__c,
    //                     OpportunityLineItem__r.UnitPrice,
    //                     OpportunityLineItem__r.ValidadeMinima__c,
    //                     OpportunityLineItem__r.ValorCx__c,
    //                     OpportunityLineItem__r.ValorMalha__c,
    //                     OpportunityLineItem__r.ValorSugerido__c,
    //                     OpportunityLineItem__r.ValorTotal__c,
    //                     OpportunityLineItem__r.ValorUn__c,
    //                     OpportunityLineItem__r.DataPedidoPerdido__c,
    //                     OpportunityLineItem__r.DataPedidoGanho__c,
    //                     OpportunityLineItem__r.ValorPedidoPerdido__c,
    //                     OpportunityLineItem__r.ValorPedidoGanho__c,
    //                     OpportunityLineItem__r.ProgramacaoEntrega__c,
    //                     OpportunityLineItem__r.Vendedor__c,
    //                     OpportunityLineItem__r.Vendedor__r.IsActive,
    //                     OpportunityLineItem__r.ValorPortal__c,
    //                     OpportunityLineItem__r.QuantidadePortal__c,
    //                     OpportunityLineItem__r.comentarios__c,
    //                     OpportunityLineItem__r.Product2Id,
    //                     Product__c,
    //                     Product__r.CategoriaComercial__c,
    //                     Product__r.Description,
    //                     Product__r.DescricaoTecnica__c,
    //                     Product__r.EANProduto__c,
    //                     Product__r.FatorConversao__c,
    //                     Product__r.TipoConversao__c,
    //                     Product__r.FatorConversaoPortal__c,
    //                     Product__r.TipoConversaoPortal__c,
    //                     Product__r.CadastranteFator__c,
    //                     Product__r.Fornecedor__r.Name,
    //                     Product__r.Name,
    //                     Product__r.NumeroAnvisa__c,
    //                     Product__r.ProductCode,
    //                     Product__r.Temperatura__c,
    //                     Product__r.UnidadeMedida__c,
    //                     Product__r.SegundaUnidade__c,
    //                     Vendedor__c,
    //                     Vendedor__r.Name,
    //                     Vendedor__r.IsActive,
    //                     DataHoraResposta__c
    //                 FROM QuoteItems__r 
    //                 WHERE ID IN: qItemIds
    //                 ORDER BY IdPortal__c DESC
    //             )
    //         FROM Opportunity 
    //         WHERE Id IN (SELECT OpportunityId__c FROM QuoteItem__c WHERE ID IN: qItemIds)
    //     ];
    //     if(lstOpps.size() > 0){
    //         return lstOpps[0];
    //     } else {
    //         throw new CustomException('Orçamento não encontrado no Salesforce.');
    //     }
    // }

    // @TestVisible
    // private static PricebookEntry getPricebookEntry(Product2 product, Id pricebook2Id){
    //     PricebookEntry pbe;
    //     if(product != null && !product.PricebookEntries.isEmpty()){
    //         pbe = product.PricebookEntries[0];
    //     } else {
    //         List<PricebookEntry> pbes = [SELECT Id, UnitPrice, Pricebook2Id, Product2Id, IsActive FROM PricebookEntry WHERE Product2Id =: product.Id AND Pricebook2Id =: pricebook2Id LIMIT 1];                
    //         if(!pbes.isEmpty()){
    //             pbe = pbes[0];
    //             if(!pbe.IsActive){
    //                 pbe.IsActive = true;
    //                 pbe.UnitPrice = 0;
    //                 update pbe;
    //             }
    //         }
    //     }
    //     if(pbe == null){
    //         pbe = ProductHelper.buildNewPricebookEntry(
    //             pricebook2Id,
    //             product.Id,
    //             0
    //         );
    //         insert pbe;
    //     }
    //     return pbe;
    // }

    // @AuraEnabled
    // public static StandardResponse cancelBudget(String oppId){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         Database.update(new Opportunity(Id = oppId, StageName = 'Fechado/Perdido'));
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled(cacheable=true)
    // public static String getCustomerCategory(String oppId){
    //     List<PicklistOption> categoriaList = new List<PickListOption>();
    //     try{
    //         system.debug('oppId: '+oppId);
    //         List<AggregateResult> quoteItemList = [
    //             SELECT CategoriaCliente__c 
    //             FROM QuoteItem__c 
    //             WHERE OpportunityId__c = :oppId 
    //             AND CategoriaCliente__c != null 
    //             GROUP BY CategoriaCliente__c
    //         ];
    //         categoriaList.add(new PicklistOption(true,'all', 'Todas as categorias'));
    //         for(AggregateResult qItem : quoteItemList){
    //             categoriaList.add(new PicklistOption(false, (String)qItem.get('CategoriaCliente__c'), (String)qItem.get('CategoriaCliente__c')));
    //         }
    //         return JSON.serialize(categoriaList);
    //     }catch(Exception e){
    //         System.debug(e.getMessage());
    //         return e.getMessage();
    //     }
    // }

    // public class PicklistOption {
    //     public Boolean selected {get; set;}
    //     public String value {get; set;}
    //     public String label {get; set;}
        
    //     public PicklistOption(Boolean slc,String param1, String param2 ){
    //         this.selected = slc;
    //         this.value = param1;
    //         this.label = param2;
    //     }
    // }

    // public class BudgetData {
    //     @AuraEnabled
    //     public Id oppId                                                     {get; set;}
    //     @AuraEnabled
    //     public String ClienteEmissorId                                      {get; set;}
    //     @AuraEnabled
    //     public String ClienteEmissorCGC                                     {get; set;}
    //     @AuraEnabled
    //     public String ClienteEmissorUF                                      {get; set;}
    //     @AuraEnabled
    //     public String TabelaPrecoExternalId                                 {get; set;}
    //     @AuraEnabled
    //     public String CondicaoPagamento                                     {get; set;}
    //     @AuraEnabled
    //     public String StageName                                             {get; set;}
    //     @AuraEnabled
    //     public String CDsBloqueado                                          {get; set;}
    //     @AuraEnabled
    //     public List<BudgetItemData> Itens                                   {get; set;}
    //     @AuraEnabled 
    //     public String tabulacaoN1                                           {get; set;}
    //     @AuraEnabled 
    //     public String tabulacaoN2                                           {get; set;}
    //     @AuraEnabled 
    //     public String userTeamMemberId                                      {get; set;}
    //     @AuraEnabled 
    //     public String consolidadas                                          {get; set;}
    //     @AuraEnabled 
    //     public String statusIntegracaoPortal                                {get; set;}
    //     @AuraEnabled 
    //     public String MensagemErroIntegracaoPortalCotacoes                  {get; set;}
    //     @AuraEnabled 
    //     public Boolean viewOnly                                             {get; set;}
    //     @AuraEnabled 
    //     public Datetime dataVencimento                                      {get; set;}
    //     @AuraEnabled 
    //     public Set<String> categorias                                       {get; set;}
    //     @AuraEnabled 
    //     public String accountType                                           {get; set;} 

    //     public BudgetData(Id oppId, List<String> quoteItemIds){
    //         this.oppId = oppId;
            
    //         Opportunity opp = getOpportunity(oppId, quoteItemIds);
    //         this.categorias = getCategories(opp.AccountId);
    //         this.viewOnly = false;
    //         if(opp.orcamentoTravado__c || VIEW_ONLY_STAGENAME.contains(opp.StageName)){
    //             this.viewOnly = true;
    //         }
            
    //         this.statusIntegracaoPortal = opp.StatusIntegracaoPortalCotacoes__c;

    //         if(!opp.OpportunityTeamMembers.isEmpty() && opp.TabulacaoN1__c != 'Envio Automático' && opp.TabulacaoN1__c != 'Recusa'){
    //             this.tabulacaoN1 = opp.OpportunityTeamMembers[0].TabulacaoN1__c;
    //             this.tabulacaoN2 = opp.OpportunityTeamMembers[0].TabulacaoN2__c;
    //             this.userTeamMemberId = opp.OpportunityTeamMembers[0].Id;
    //         } else{
    //             this.tabulacaoN1 = opp.TabulacaoN1__c;
    //             this.tabulacaoN2 = opp.TabulacaoN2__c;
    //         }

    //         this.statusIntegracaoPortal = opp.StatusIntegracaoPortalCotacoes__c;
    //         this.StageName = opp.StageName;
    //         this.ClienteEmissorId = opp.AccountId;
    //         this.accountType = opp.Account?.RecordType.DeveloperName;
    //         this.ClienteEmissorCGC = opp.CNPJ__c == null ? opp.CPF__c : opp.CNPJ__c; 
    //         this.ClienteEmissorUF = opp.Account?.ShippingState;
    //         this.accountType = opp.Account?.RecordType.DeveloperName;
    //         this.CondicaoPagamento = opp.CondicaoPagamento__c;
    //         this.CDsBloqueado = opp.CDsBloqueado__c;
    //         this.consolidadas = opp.CotacoesConsolidadas__c; // List<Consolidador>
    //         this.MensagemErroIntegracaoPortalCotacoes = opp.MensagemErroIntegracaoPortalCotacoes__c;
    //         this.dataVencimento = opp.DataVencimento__c;
    //         this.TabelaPrecoExternalId = 'B01';

    //         this.Itens = buildItems(opp);
    //     }
    // }

    // public static Opportunity getOpportunity(Id oppId, List<String> quoteItemIds){
    //     return [
    //         SELECT Id,
    //             AccountId,
    //             Account.RecordType.DeveloperName,
    //             Account.ShippingState,
    //             CDsBloqueado__c,
    //             CNPJ__c,
    //             CondicaoPagamento__c,
    //             CotacoesConsolidadas__c,
    //             CPF__c,
    //             DataVencimento__c,
    //             MensagemErroIntegracaoPortalCotacoes__c,
    //             OrcamentoTravado__c,
    //             StageName,
    //             StatusIntegracaoPortalCotacoes__c,
    //             TabulacaoN1__c,
    //             TabulacaoN2__c,
    //             (
    //                 SELECT 
    //                     Id,
    //                     CNPJCD__c,
    //                     LastModifiedDate,
    //                     CustomerDescription__c,
    //                     CustomerMeasurementUnit__c,
    //                     FavoriteBrands__c,
    //                     IdIntegrator__c,
    //                     IdPortal__c,
    //                     IdCustomer__c,
    //                     Name,
    //                     ProdutosVinculadosAnteriormente__c,
    //                     Quantity__c,
    //                     Status__c,
    //                     UnitPrice__c,
    //                     SequenciaOC__c,
    //                     TabulacaoN1__c,
    //                     Categoria__c,
    //                     CategoriaCliente__c,
    //                     ProgramacaoEntrega__c,
    //                     OpportunityId__r.AccountId,
    //                     OpportunityLineItem__c,
    //                     OpportunityLineItem__r.CategoriaComercial__c,
    //                     OpportunityLineItem__r.CentroDistribuicao__c,
    //                     OpportunityLineItem__r.CNPJCD__c,
    //                     OpportunityLineItem__r.Comentarios__c,
    //                     OpportunityLineItem__r.Custo__c,
    //                     OpportunityLineItem__r.FatorConversao__c,
    //                     OpportunityLineItem__r.TipoConversao__c,
    //                     OpportunityLineItem__r.Discount,
    //                     OpportunityLineItem__r.ForaMalha__c,
    //                     OpportunityLineItem__r.Imposto__c,
    //                     OpportunityLineItem__r.ListPrice,
    //                     OpportunityLineItem__r.Lote__c,
    //                     OpportunityLineItem__r.MargemAlvo__c,
    //                     OpportunityLineItem__r.MargemAtual__c,
    //                     OpportunityLineItem__r.PosicaoInsercao__c,
    //                     OpportunityLineItem__r.PosicaoItem__c,
    //                     OpportunityLineItem__r.PricebookEntry.PrecoFabrica__c,
    //                     OpportunityLineItem__r.PricebookEntry.UnitPrice,
    //                     OpportunityLineItem__r.PricebookEntryId,
    //                     OpportunityLineItem__r.PrincipioAtivo__c,
    //                     OpportunityLineItem__r.QuantidadeUn__c,
    //                     OpportunityLineItem__r.QuantidadePortal__c,
    //                     OpportunityLineItem__r.Quantity,
    //                     OpportunityLineItem__r.Range__c,
    //                     OpportunityLineItem__r.ScoreBU__c,
    //                     OpportunityLineItem__r.ScoreItem__c,
    //                     OpportunityLineItem__r.ScoreMix__c,
    //                     OpportunityLineItem__r.SequenciaOC__c,
    //                     OpportunityLineItem__r.Status__c,
    //                     OpportunityLineItem__r.TabulacaoN1__c,
    //                     OpportunityLineItem__r.UnitPrice,
    //                     OpportunityLineItem__r.ValidadeMinima__c,
    //                     OpportunityLineItem__r.ValorCx__c,
    //                     OpportunityLineItem__r.ValorMalha__c,
    //                     OpportunityLineItem__r.ValorPortal__c,
    //                     OpportunityLineItem__r.ValorSugerido__c,
    //                     OpportunityLineItem__r.ValorTotal__c,
    //                     OpportunityLineItem__r.ValorUn__c,
    //                     OpportunityLineItem__r.DataPedidoPerdido__c,
    //                     OpportunityLineItem__r.DataPedidoGanho__c,
    //                     OpportunityLineItem__r.ValorPedidoPerdido__c,
    //                     OpportunityLineItem__r.ValorPedidoGanho__c,
    //                     OpportunityLineItem__r.ProgramacaoEntrega__c,
    //                     OpportunityLineItem__r.Vendedor__c,
    //                     OpportunityLineItem__r.Vendedor__r.IsActive,
    //                     OpportunityLineItem__r.CreatedDate,
    //                     Product__c,
    //                     Product__r.CategoriaComercial__c,
    //                     Product__r.Description,
    //                     Product__r.DescricaoTecnica__c,
    //                     Product__r.EANProduto__c,
    //                     Product__r.FatorConversao__c,
    //                     Product__r.FatorConversaoPortal__c,
    //                     Product__r.TipoConversaoPortal__c,
    //                     Product__r.Fornecedor__r.Name,
    //                     Product__r.Name,
    //                     Product__r.NumeroAnvisa__c,
    //                     Product__r.ProductCode,
    //                     Product__r.Temperatura__c,
    //                     Product__r.TipoConversao__c,
    //                     Product__r.UnidadeMedida__c,
    //                     Product__r.SegundaUnidade__c,
    //                     Vendedor__c,
    //                     Vendedor__r.Name,
    //                     Vendedor__r.IsActive,
    //                     DataHoraResposta__c
    //                 FROM QuoteItems__r 
    //                 WHERE IdPortal__c IN: quoteItemIds
    //             ),
    //             (
    //                 SELECT Id, CentroDistribuicao__c, CNPJCD__c FROM Condicespagamentospor_CD__r
    //             ),
    //             (
    //                 SELECT Id, OpportunityId, TabulacaoN1__c, TabulacaoN2__c FROM OpportunityTeamMembers WHERE OpportunityId =: oppId AND UserId =: UserInfo.getUserId() LIMIT 1
    //             )
    //         FROM Opportunity 
    //         WHERE Id =: oppId
    //     ];
    // }

    // public static Set<String> getCategories(String accountId){
    //     Set<String> categories = new Set<String>();
    //     List<Setorizacao__c> setorizacaoList = [
    //         SELECT Categoria__c
    //         FROM Setorizacao__c
    //         WHERE Conta__c = :accountId
    //         AND VendedorSuporte__c = :UserInfo.getUserId()
    //         AND Categoria__c IN ('M','S','G')
    //     ];
    //     for(Setorizacao__c setor : setorizacaoList){
    //         categories.add(setor.Categoria__c);
    //     }
    //     return categories;
    // }

    // public static List<BudgetItemData> buildItems(Opportunity opp){

    //     Map<String,String> mapCds = buildMapCds(opp.Condicespagamentospor_CD__r);
    //     List<BudgetItemData> Itens = new List<BudgetItemData>();

    //     Set<Id> setProductId = new Set<Id>();
    //     Map<String, List<BudgetItemData>> mapRespostasByIdPortal = new Map<String, List<BudgetItemData>>();

    //     for(QuoteItem__c item: opp.QuoteItems__r){
    //         if(item.Product__c != null){
    //             setProductId.add(item.Product__c);
    //         }
    //         List<BudgetItemData> respostas = mapRespostasByIdPortal.get(item.IdPortal__C);
    //         if(respostas == null){
    //             respostas = new List<BudgetItemData>();
    //         }
    //         respostas.add(new BudgetItemData(item, opp, mapCds));
    //         mapRespostasByIdPortal.put(item.IdPortal__c, respostas);
    //     }

    //     Map<String,BudgetItemData> mapItens = new Map<String,BudgetItemData>();
    //     for(QuoteItem__c item: opp.QuoteItems__r){
    //         String idPortal = item.IdPortal__c;
    //         if(!mapItens.containsKey(idPortal)){
    //             mapItens.put(idPortal, new BudgetItemData(idPortal, item, opp, mapRespostasByIdPortal.get(idPortal), mapCds));
    //         }
    //     }
        
    //     Itens = mapItens.values();
        
    //     Map<Id, Decimal> mapEstoque = ProductHelper.getMapEstoqueByProductId(setProductId, opp.AccountId);

    //     //map<String, OrderScreenController.ProductData> mapProd = OrderScreenController.getContractCampaign(new Set<String>( (List<String>)new List<Id>( setProductId ) ), opp.AccountId, opp.CondicaoPagamento__c);
    //     for (BudgetItemData item : Itens) {
    //         String estoqueResult = 'Produto não vinculado';
    //         for (BudgetItemData resp : item.respostas) {
    //             if(String.isBlank(resp.prodId)){
    //                 continue;
    //             }

    //             if(mapEstoque.containsKey(resp.prodId)){
    //                 resp.estoqueStr = String.valueOf(mapEstoque.get(resp.prodId));
    //                 estoqueResult = resp.estoqueStr;
    //                 item.prodId = resp.prodId;
    //                 break;
    //             }else{
    //                 resp.estoqueStr = 'Informação não disponível';
    //                 estoqueResult = resp.estoqueStr;
    //                 item.prodId = resp.prodId;
    //             }
    //         }
    //         item.estoqueStr = estoqueResult;
                
    //         // if (mapProd.containsKey(item.prodId)) {
    //         //     OrderScreenController.ProductData prodData = mapProd.get(item.prodId);
    //         //     item.showBadgeOL              = prodData.showBadgeOL;
    //         //     item.showBadgeCampanha        = prodData.showBadgeCampanha;
    //         //     item.showBadgeCampanhaVendedor = prodData.showBadgeCampanhaVendedor;
    //         //     item.showBadgeCampanhaCD      = prodData.showBadgeCampanhaCD;
    //         //     item.showBadgeConsignado      = prodData.showBadgeConsignado;
    //         //     item.showBadgeAcordoComercial = prodData.showBadgeAcordoComercial;
    //         //     item.showBadgeshelflife       = prodData.showBadgeshelflife;
    //         //     item.precoCNPJCampanha        = prodData.precoCNPJCampanha;
    //         //     item.valorBloqueado           = prodData.valorBloqueado;
    //         // }
    //     }
    //     return Itens;
    // }

    // @AuraEnabled
    // public static StandardResponse getHistoricoVinculos(String idPortalItem, String oppId){
    //     StandardResponse response = new StandardResponse();
        
    //     if(String.isBlank(idPortalItem)){
    //         return response.addError('É necessário o IdPortal__c do item para consultar o histórico de vínculos.');
    //     }
    //     try {

    //         List<VinculosData> historico = new List<VinculosData>();

    //         List<QuoteItem__c> qItemList = [
    //             SELECT Id,
    //                 OpportunityId__c,
    //                 OpportunityId__r.AccountId,
    //                 Product__c,
    //                 Product__r.ProductCode,
    //                 ProdutosVinculadosAnteriormente__c
    //             FROM QuoteItem__c
    //             WHERE IdPortal__c =: idPortalItem
    //             AND OpportunityId__c =: oppId
    //             LIMIT 1
    //         ];
    //         if(qItemList != null && !qItemList.isEmpty()){
    //             QuoteItem__c qItem = qItemList[0];
            
    //             if(String.isNotBlank(qItem.ProdutosVinculadosAnteriormente__c) && qItem.ProdutosVinculadosAnteriormente__c != '[]'){
    //                 System.debug('VINCULOS: '+qItem.ProdutosVinculadosAnteriormente__c);
    //                 Map<String, VinculosDataDTO> mapProdutosVinculados = new Map<String, VinculosDataDTO>();
                    
    //                 //Preenche código de itens para o array de vinculos antigos retornados pelo Portal
    //                 List<VinculosDataDTO> vinculosExistentes = (List<VinculosDataDTO>) JSON.deserialize(qItem.ProdutosVinculadosAnteriormente__c, List<VinculosDataDTO>.class);
    //                 for(VinculosDataDTO vinculo: vinculosExistentes){
                        
    //                     String idERP = String.isNotBlank(vinculo.codigoProdutoERP) ? vinculo.codigoProdutoERP.trim() : null;
    //                     if(String.isNotEmpty(idERP)){
    //                         mapProdutosVinculados.put(idERP, vinculo);
    //                     }
    //                 }
                
    //                 if(!mapProdutosVinculados.isEmpty()){

    //                     Map<String, Decimal> mapEstoque = ProductHelper.getMapEstoqueByProductCode(mapProdutosVinculados.keySet(), qItem.OpportunityId__r.AccountId);
    //                     Map<String, Product2> mapProductsByIdERP = new Map<String,Product2>();

    //                     for(List<Product2> lstProducts: [SELECT Id, ProductCode, Name, Description, Fabricante__c, UnidadeMedida__c, CategoriaComercial__c, Fornecedor__r.Name FROM Product2 WHERE ProductCode IN :mapProdutosVinculados.keySet()]){
    //                         for(Product2 prod: lstProducts){
    //                             mapProductsByIdERP.put(prod.ProductCode, prod);
    //                         }
    //                     }
            
    //                     if(!mapProductsByIdERP.isEmpty()){

    //                         Map<String,QuoteItem__c> mapItens = new Map<String,QuoteItem__c>();
    //                         Map<String,Id> mapLastItemsByProduct = new Map<String,Id>();

    //                         for (AggregateResult ar : [
    //                             SELECT ProductCode, Max(Id) FROM OpportunityLineItem
    //                             WHERE Opportunity.AccountId =: qItem.OpportunityId__r.AccountId
    //                                 AND ProductCode IN: mapProductsByIdERP.keySet()
    //                                 AND CreatedDate >= LAST_N_MONTHS: 11
    //                                 AND Opportunity.StageName IN ('Fechado/Perdido','Cancelada', 'Perdida', 'Sem Retorno', 'Fechado/Gerado','Gerar Pedido', 'Ganha')
    //                                 AND (Opportunity.RecordType.DeveloperName != 'OrcamentoPortal' OR Status__c IN ('Resgatado', 'Aprovado'))
    //                                 AND TabulacaoN1__c != 'SEM OFERTA'
    //                             GROUP BY ProductCode
    //                         ]) {
    //                             mapLastItemsByProduct.put((String)ar.get('ProductCode'), (Id)ar.get('expr0'));
    //                         }

    //                         Map<String, VinculosData> mapVinculos = new Map<String, VinculosData>();
    //                         Map<String,OpportunityLineItem> mapOppLineItems = new Map<String,OpportunityLineItem>();

    //                         for(List<OpportunityLineItem> lstOppLineItems: [
    //                             SELECT
    //                                 Id,
    //                                 CreatedDate,
    //                                 DataPedidoGanho__c,
    //                                 DataPedidoPerdido__c,
    //                                 FatorConversao__c,
    //                                 Opportunity.AccountId,
    //                                 Opportunity.Probability,
    //                                 Opportunity.StageName,
    //                                 ProductCode,
    //                                 TipoConversao__c,
    //                                 UnitPrice,
    //                                 ValorTotal__c
    //                             FROM OpportunityLineItem
    //                             WHERE Id IN: mapLastItemsByProduct.values()
    //                         ]){
    //                             for(OpportunityLineItem item: lstOppLineItems){
    //                                 mapOppLineItems.put(item.ProductCode, item);
    //                             }
    //                         }

    //                         for(Product2 prod: mapProductsByIdERP.values()){
    //                             mapVinculos.put(prod.ProductCode, new VinculosData(qItem, mapProductsByIdERP.get(prod.ProductCode), mapProdutosVinculados.get(prod.ProductCode), mapEstoque, mapOppLineItems.get(prod.ProductCode)));
    //                         }
                        
    //                         historico = mapVinculos.values();
    //                     }
    //                 }
    //             }
    //         }
    //         response.setData('vinculos', historico);

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // public static Map<String,String> buildMapCds(List<CondicaoPagamentoPorCD__c> condicaoPagamentoPorCD){
    //     Map<String,String> mapCds = new Map<String,String>();
    //     for(CondicaoPagamentoPorCD__c cond: condicaoPagamentoPorCD){
    //         if(!mapCds.containsKey(cond.CNPJCD__c)){
    //             mapCds.put(cond.CNPJCD__c, cond.CentroDistribuicao__c);
    //         }
    //     }
    //     return mapCds;
    // }

    // @AuraEnabled
    // public static StandardResponse getPdfPage(String oppId){
    //     StandardResponse response = new StandardResponse();
    //     try {
    //         System.debug(oppId);
    //         PageReference pdf = Page.BudgetPortalPDF;
    //         pdf.getParameters().put('Id', oppId);
            
    //         response.setData(URL.getSalesforceBaseUrl().toExternalForm()+pdf.getUrl());

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     System.debug(response.data);

    //     return response;
    // }

    // // public class Consolidador {
    // //     public String idPdcConsolidador { get; set; }
    // //     public String nomeHospitalConsolidador { get; set; }
    // //     public String cnpjConsolidador { get; set; }
    // //     public String uf { get; set; }
    // //     public String cidade { get; set; }
    // // }

    // // public class ProductOption{
    // //     public String code;
    // //     public String name;
    // //     public String principioAtivo;
    // //     public String fabricante;
    // //     public String unidadeMed;
    // //     public Date   lastOferData;
    // //     public String lastOferStatus;
    // //     public Double lastOferAmount;
    // //     public String simbol;
    // //     public String id;

    // //     public ProductOption(Product2 product){
    // //         this.code           = product.ProductCode;
    // //         this.name           = product.Name;
    // //         this.principioAtivo = product.Description;
    // //         this.fabricante     = product.Fabricante__c;
    // //         this.unidadeMed     = product.UnidadeMedida__c;
    // //         this.lastOferData   = Date.newInstance(2022, 01, 01);//TO CHANGE
    // //         this.lastOferStatus = 'Ganho';//TO CHANGE
    // //         this.lastOferAmount = 1000.99;//TO CHANGE
    // //         this.simbol         = 'E';
    // //         this.id             = product.Id;
    // //     }
    // // }

    // // //idk if it's been used
    // // @AuraEnabled(Cacheable=true)
    // // public static String getProductOptions(String dinamicParam, String staticParam){

    // //     System.debug('staticParam:'+staticParam);
    // //     List<Product2> productList =[
    // //         SELECT 
    // //             Id,
    // //             ProductCode,
    // //             Name,
    // //             Description,
    // //             Fabricante__c,
    // //             UnidadeMedida__c,
    // //             Fornecedor__r.Name
    // //         FROM Product2 
    // //         WHERE ID 
    // //         IN (
    // //             SELECT 
    // //                 Product2Id 
    // //             FROM PricebookEntry 
    // //             WHERE UnitPrice > 0 
    // //             AND Pricebook2.ExternalId__c = 'B01' 
    // //             AND IsActive = true
    // //             ) 
    // //         LIMIT 8
    // //         ];

    // //     List<ProductOption> productOptList = new List<ProductOption>();
    // //     for(Product2 prod : productList){
    // //         productOptList.add(new ProductOption(prod));
    // //     }

    // //     return JSON.serialize(productOptList);
    // // }
    
    // public class BudgetItemData {
        
    //     @AuraEnabled
    //     public Boolean foraMalha                {get; set;}
    //     @AuraEnabled 
    //     public Boolean show                     {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeAcordoComercial {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeCampanha        {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeCampanhaCD      {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeCampanhaVendedor {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeConsignado      {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeOL              {get; set;}
    //     @AuraEnabled 
    //     public Boolean showBadgeshelflife       {get; set;}
    //     @AuraEnabled 
    //     public Boolean valorBloqueado           {get; set;}
    //     @AuraEnabled 
    //     public Boolean verMargem                {get; set;}
    //     @AuraEnabled 
    //     public Decimal aliquota                 {get; set;}
    //     @AuraEnabled 
    //     public Decimal custoCx                  {get; set;}
    //     @AuraEnabled 
    //     public Decimal custoDif                 {get; set;}
    //     @AuraEnabled 
    //     public Decimal desconto                 {get; set;}
    //     @AuraEnabled 
    //     public Decimal estoque                  {get; set;}
    //     @AuraEnabled 
    //     public String  estoqueStr               {get; set;}
    //     @AuraEnabled 
    //     public Decimal estoqueUn                {get; set;}
    //     @AuraEnabled 
    //     public Decimal indexInsertPosition      {get; set;}
    //     @AuraEnabled 
    //     public Decimal indexPosition            {get; set;}
    //     @AuraEnabled 
    //     public String DataPedidoPerdido         {get; set;}
    //     @AuraEnabled 
    //     public String DataPedidoGanho           {get; set;}
    //     @auraEnabled
    //     public String tipoConversaoProd         {get; set;}
    //     @AuraEnabled 
    //     public Double fatorConversaoProd        {get; set;}
    //     @AuraEnabled 
    //     public String tipoConversao             {get; set;}
    //     @AuraEnabled 
    //     public String fatorConversao            {get; set;}
    //     @auraEnabled
    //     public Decimal quantidadePortal         {get; set;}
    //     @AuraEnabled 
    //     public Decimal unitarioPortal           {get; set;}
    //     @AuraEnabled 
    //     public Decimal ValorPedidoPerdido       {get; set;}
    //     @AuraEnabled 
    //     public Decimal ValorPedidoGanho         {get; set;}
    //     @AuraEnabled 
    //     public Decimal margem                   {get; set;}
    //     @AuraEnabled 
    //     public Decimal margemAlvo               {get; set;}
    //     @AuraEnabled 
    //     public Decimal margemAlvoInput          {get; set;}
    //     @AuraEnabled 
    //     public Decimal precoMalha               {get; set;}
    //     @AuraEnabled 
    //     public Decimal precoSugerido            {get; set;}
    //     @AuraEnabled 
    //     public Decimal quantidade               {get; set;}
    //     @AuraEnabled 
    //     public Decimal quantidadeCx             {get; set;}
    //     @AuraEnabled 
    //     public Decimal quantidadeSolicitada     {get; set;}
    //     @AuraEnabled 
    //     public Decimal score                    {get; set;}
    //     @AuraEnabled 
    //     public Decimal scoreBU                  {get; set;}
    //     @AuraEnabled 
    //     public Decimal scoreItem                {get; set;}
    //     @AuraEnabled 
    //     public Decimal scoreMix                 {get; set;}
    //     @AuraEnabled 
    //     public Decimal valorTotal               {get; set;}
    //     @AuraEnabled 
    //     public Decimal valorTotalCx             {get; set;}
    //     @AuraEnabled 
    //     public Decimal valorTotalUnd            {get; set;}
    //     @AuraEnabled 
    //     public String anvisa                    {get; set;}
    //     @AuraEnabled 
    //     public String caixa                     {get; set;}
    //     @AuraEnabled 
    //     public String categoriaVendedor         {get; set;}
    //     @AuraEnabled 
    //     public String categoriaVendedorDesc     {get; set;}
    //     @AuraEnabled 
    //     public String categoria                 {get; set;}
    //     @AuraEnabled 
    //     public String categoriaCliente          {get; set;}
    //     @AuraEnabled 
    //     public String categoriaDesc             {get; set;}
    //     @AuraEnabled 
    //     public String cdId                      {get; set;}
    //     @AuraEnabled 
    //     public String cds                       {get; set;}
    //     @AuraEnabled 
    //     public String cnpjCd                    {get; set;}
    //     @AuraEnabled 
    //     public String descTecnica               {get; set;}
    //     @AuraEnabled 
    //     public String nomeCd                    {get; set;}
    //     @AuraEnabled 
    //     public String conversaoUnidadeCx        {get; set;}
    //     @AuraEnabled 
    //     public String ean                       {get; set;}
    //     @AuraEnabled 
    //     public String fabricante                {get; set;}
    //     @AuraEnabled 
    //     public String favoriteBrands            {get; set;}
    //     @AuraEnabled 
    //     public String marcaProdOfertado         {get; set;}
    //     @AuraEnabled 
    //     public String id                        {get; set;}
    //     @AuraEnabled 
    //     public String itemUrl                   {get; set;}
    //     @AuraEnabled 
    //     public String quoteitemUrl              {get; set;}
    //     @AuraEnabled 
    //     public String pbeExternalId             {get; set;}
    //     @AuraEnabled 
    //     public String quoteitemid               {get; set;}
    //     // @AuraEnabled 
    //     // public Integer index                    {get; set;}//Serafim edit
    //     @AuraEnabled 
    //     public String inicialCaixa              {get; set;}
    //     @AuraEnabled 
    //     public String inicialUnitario           {get; set;}
    //     @AuraEnabled 
    //     public String itemId                    {get; set;}
    //     @AuraEnabled 
    //     public String lote                      {get; set;}
    //     @AuraEnabled 
    //     public String nome                      {get; set;}
    //     @AuraEnabled 
    //     public String nomeProdutoCliente        {get; set;}
    //     @AuraEnabled 
    //     public String nomeVendedor              {get; set;}
    //     @AuraEnabled 
    //     public String vendedorId                {get; set;}
    //     @AuraEnabled 
    //     public Boolean visivelVendedor          {get; set;}
    //     @AuraEnabled 
    //     public Boolean isCurrentUser            {get; set;}
    //     @AuraEnabled 
    //     public String pbEntryId                 {get; set;}
    //     @AuraEnabled 
    //     public String precoCNPJCampanha         {get; set;}
    //     @AuraEnabled 
    //     public String precoFabricaCx            {get; set;}
    //     @AuraEnabled 
    //     public String precoFabricaUn            {get; set;}
    //     @AuraEnabled 
    //     public String precoTabelaCx             {get; set;}
    //     @AuraEnabled 
    //     public String precoTabelaUn             {get; set;}
    //     @AuraEnabled 
    //     public String principioAtivo            {get; set;}
    //     @AuraEnabled 
    //     public String prodCode                  {get; set;}
    //     @AuraEnabled 
    //     public String prodId                    {get; set;}
    //     @AuraEnabled 
    //     public String rangeStringify            {get; set;}
    //     @AuraEnabled 
    //     public String SequenciaOC               {get; set;}
    //     @AuraEnabled 
    //     public String temperatura               {get; set;}
    //     @AuraEnabled 
    //     public String un                        {get; set;}
    //     @AuraEnabled 
    //     public String unidadePrincipal          {get; set;}
    //     @AuraEnabled
    //     public String unidadeSecundaria         {get; set;}
    //     @AuraEnabled 
    //     public String conversaoUnidadeTexto     {get; set;}
    //     @AuraEnabled 
    //     public String customerDescription       {get; set;}
    //     @AuraEnabled 
    //     public String customerMeasurementUnit   {get; set;}
    //     @AuraEnabled 
    //     public String status                    {get; set;}
    //     @AuraEnabled 
    //     public String tabulacaoN1               {get; set;}
    //     @AuraEnabled 
    //     public String statusItem                {get; set;}
    //     @AuraEnabled 
    //     public String unitario                  {get; set;}
    //     @AuraEnabled 
    //     public String validadeMinima            {get; set;}
    //     @AuraEnabled 
    //     public String idPortal                  {get; set;}
    //     @AuraEnabled 
    //     public String comentario                {get; set;}
    //     @AuraEnabled 
    //     public String idCustomer                {get; set;}
    //     @AuraEnabled 
    //     public String idIntegrator              {get; set;}
    //     @AuraEnabled 
    //     public String createdDate               {get; set;}
    //     @AuraEnabled 
    //     public String dataHoraResposta          {get; set;}
    //     @AuraEnabled 
    //     public String ProgramacaoEntrega        {get; set;}
    //     @AuraEnabled 
    //     public String style2Class               {get; set;}
    //     @AuraEnabled 
    //     public String styleStatus2Class         {get; set;}
    //     @AuraEnabled
    //     public List<BudgetItemData> respostas   {get; set;}

    //     public BudgetItemData(){}


    //     public BudgetItemData(String idPortal, QuoteItem__c item, Opportunity opp, List<BudgetItemData> respostas, Map<String,String> mapCds) {
    //         this(item, opp, mapCds);
    //         this.idPortal = idPortal;
    //         this.respostas = respostas;
    //         Integer itensRespondididos = 0;
    //         this.ProgramacaoEntrega = item.ProgramacaoEntrega__c;
    //         this.categoriaCliente = String.isNotBlank(item.CategoriaCliente__c) ? item.CategoriaCliente__c : 'Informação não disponível';

    //         Boolean respondidoVendedor = false;
    //         for(BudgetItemData resp : this.respostas) {
    //             if (String.isNotBlank(resp.tabulacaoN1) && resp.tabulacaoN1 != 'SEM OFERTA') {
                    
    //                 itensRespondididos ++;
    //                 if(resp.vendedorId == UserInfo.getUserId()){
    //                     respondidoVendedor = true;
    //                 }
    //             }
    //         }
    //         this.verMargem = BudgetController.verMargem;

    //         if(itensRespondididos == this.respostas.size()) {

    //             this.statusItem = 'TOTALMENTE RESPONDIDO';
    //             if(respondidoVendedor){
    //                 this.styleStatus2Class = 'gBackgText';
    //                 this.style2Class       = 'gBack';
    //             } else{
    //                 this.styleStatus2Class = 'wBackgText';
    //                 this.style2Class       = 'wBack';
    //             }

    //         }else if(itensRespondididos == 0){
                
    //             this.statusItem = 'NENHUMA RESPOSTA';
    //             this.styleStatus2Class = 'wBackwText';
    //             this.style2Class       = 'wBack';
                
    //         }else  if (itensRespondididos > 0 && itensRespondididos < this.respostas.size()){

    //             this.statusItem = 'PARCIALMENTE RESPONDIDO';
    //             if(respondidoVendedor){
    //                 this.styleStatus2Class = 'gBackyText';
    //                 this.style2Class       = 'gBack';
    //             } else{
    //                 this.styleStatus2Class = 'wBackyText';
    //                 this.style2Class       = 'wBack';
    //             }

    //         }
           
    //     }

    //     public BudgetItemData(QuoteItem__c item, Opportunity opp, Map<String,String> mapCds) {
    //         if(item != null){
                
    //             //Decimal price;
    //             //Decimal fatval;
                
    //             this.id                                    = item.Id;
    //             this.idCustomer                            = item.IdCustomer__c;
    //             this.idPortal                              = item.IdPortal__c;
    //             this.idIntegrator                          = item.IdIntegrator__c;
    //             this.createdDate                           = '';
    //             this.dataHoraResposta                      = '';
    //             this.customerDescription                   = item.CustomerDescription__c;
    //             this.customerMeasurementUnit               = item.CustomerMeasurementUnit__c;
    //             this.status                                = item.Status__c;
    //             //this.status                                = (item.Status__c == 'Não Vinculado') && item.Vendedor__c == UserInfo.getUserId() ? 'Vinculado' : item.Status__c;
    //             this.favoriteBrands                        = item.FavoriteBrands__c;
    //             this.nomeProdutoCliente                    = item.Name;
    //             this.quantidadeSolicitada                  = item.Quantity__c;
    //             this.tabulacaoN1                           = item.TabulacaoN1__c;
    //             this.nomeVendedor                          = item.Vendedor__r?.Name;
    //             this.vendedorId                            = item.Vendedor__c;
    //             this.isCurrentUser                         = item.Vendedor__c == UserInfo.getUserId();

    //             if(this.isCurrentUser || (item.Vendedor__c != null && item.Vendedor__r.IsActive == false)){
    //                 this.visivelVendedor                   = true;
    //             } else{
    //                 this.visivelVendedor                   = false;
                    
    //             }
                
    //             // if(item.SequenciaOC__c != null){
    //             //     this.index                                 = Integer.valueOf(item.SequenciaOC__c);
    //             // }
    //             this.quoteitemUrl                          = '/' + item.Id;
    //             this.show                                  = true;
    //             this.categoriaVendedor                     = item.Categoria__c;
    //             if(!String.isEmpty(this.categoriaVendedor)){
    //                 this.categoriaVendedorDesc = Utils.getPicklistApi(Product2.CategoriaComercial__c).get(this.categoriaVendedor);
    //             }


    //             if(String.isNotBlank(item.CNPJCD__c)){
    //                 this.cnpjCd                            = item.CNPJCD__c;
    //             }
    //             if(this.tabulacaoN1 != null){
    //                 this.createdDate                       = String.valueOf(item.LastModifiedDate) ;
    //                 this.dataHoraResposta                  = String.valueOf(item.dataHoraResposta__c) ;
    //             }
                
    //             if(item.Product__c != null){
    //                 this.cdId                              = item.CNPJCD__c  + '_' + item.Product__r.ProductCode;
    //                 this.createdDate                       = String.valueOf(item.LastModifiedDate) ;
    //                 this.dataHoraResposta                  = String.valueOf(item.dataHoraResposta__c) ;
    //                 this.itemUrl                           = '/' + item.Product__c;
    //                 this.prodId                            = item.Product__c;
    //                 this.marcaProdOfertado                 = item.Product__r.Fornecedor__r.Name;
    //                 this.principioAtivo                    = item.Product__r.Description; // OpportunityLineItem__r.PrincipioAtivo__c
    //                 this.ean                               = item.Product__r.EANProduto__c;
    //                 this.fabricante                        = item.Product__r.Fornecedor__r.Name;
    //                 this.nome                              = item.Product__r.Name;
    //                 this.anvisa                            = item.Product__r.NumeroAnvisa__c;
    //                 this.prodCode                          = item.Product__r.ProductCode;
    //                 this.temperatura                       = item.Product__r.Temperatura__c;
    //                 this.unidadePrincipal                  = item.Product__r.UnidadeMedida__c;
    //                 this.unidadeSecundaria                 = item.Product__r.SegundaUnidade__c;
    //                 this.tipoConversao                     = item.Product__r.tipoConversao__c;
    //                 this.fatorConversao                    = item.Product__r.FatorConversao__c;

    //                 Map<String, String> resultFator = getFatorConversao(
    //                     item.Product__r.FatorConversaoPortal__c,
    //                     item.Product__r.FatorConversao__c,
    //                     item.CustomerMeasurementUnit__c
    //                 );
    //                 this.fatorConversaoProd                = resultFator.get('fator') != null ? Decimal.valueOf(resultFator.get('fator')) : null;
    //                 this.tipoConversaoProd                 = resultFator.get('tipo');

    //                 this.conversaoUnidadeCx                = resultFator.get('fator') != null ? resultFator.get('fator') : null;
    //                 this.categoria                         = item.Product__r.CategoriaComercial__c;
    //                 this.descTecnica                       = item.Product__r.DescricaoTecnica__c;
                    
    //             }

    //             if(!String.isEmpty(this.categoria)){
    //                 this.categoriaDesc = Utils.getPicklistApi(Product2.CategoriaComercial__c).get(this.categoria);
    //             }

    //             if(String.isNotBlank(item.OpportunityLineItem__c)){

    //                 this.itemId                            = item.OpportunityLineItem__c;
    //                 if(item.OpportunityLineItem__r != null){
    //                     //price = item.OpportunityLineItem__r.PricebookEntry.PrecoFabrica__c == null ? item.OpportunityLineItem__r.PricebookEntry.UnitPrice : item.OpportunityLineItem__r.PricebookEntry.PrecoFabrica__c;
    //                     this.pbEntryId                         = item.OpportunityLineItem__r.PricebookEntryId;
    //                     this.cnpjCd                            = item.OpportunityLineItem__r.cnpjCd__c;
    //                     this.lote                              = item.OpportunityLineItem__r.Lote__c;
    //                     this.quantidade                        = item.OpportunityLineItem__r.QuantidadeUn__c;
    //                     this.quantidadeCx                      = item.OpportunityLineItem__r.Quantity;
    //                     this.desconto                          = item.OpportunityLineItem__r.Discount;
    //                     this.valorTotalUnd                     = item.OpportunityLineItem__r.ValorUn__c;
    //                     this.valorTotalCx                      = item.OpportunityLineItem__r.ValorCx__c;
    //                     this.valorTotal                        = item.OpportunityLineItem__r.ValorTotal__c;
    //                     this.aliquota                          = item.OpportunityLineItem__r.Imposto__c;
    //                     this.score                             = item.OpportunityLineItem__r.ScoreItem__c;
    //                     this.scoreBU                           = item.OpportunityLineItem__r.ScoreBU__c;
    //                     this.scoreMix                          = item.OpportunityLineItem__r.ScoreMix__c;
    //                     this.scoreItem                         = item.OpportunityLineItem__r.ScoreItem__c;
    //                     this.indexPosition                     = item.OpportunityLineItem__r.PosicaoItem__c;
    //                     this.custoCx                           = item.OpportunityLineItem__r.Custo__c;
    //                     this.margem                            = item.OpportunityLineItem__r.MargemAtual__c;
    //                     this.margemAlvo                        = item.OpportunityLineItem__r.MargemAlvo__c;
    //                     this.foraMalha                         = item.OpportunityLineItem__r.ForaMalha__c;
    //                     this.precoMalha                        = item.OpportunityLineItem__r.ValorMalha__c;
    //                     this.precoSugerido                     = item.OpportunityLineItem__r.ValorSugerido__c;
    //                     this.rangeStringify                    = item.OpportunityLineItem__r.Range__c;
    //                     this.validadeMinima                    = item.OpportunityLineItem__r.ValidadeMinima__c;
    //                     this.SequenciaOC                       = item.OpportunityLineItem__r.SequenciaOC__c;
    //                     this.status                            = item.OpportunityLineItem__r.Status__c;
    //                     this.indexInsertPosition               = item.OpportunityLineItem__r.PosicaoInsercao__c == null ? 0 : item.OpportunityLineItem__r.PosicaoInsercao__c;
    //                     this.pbeExternalId                     = item.OpportunityLineItem__r.PricebookEntryId + '_' + item.OpportunityLineItem__r.CnpjCd__c;
    //                     this.nomeCd                            = item.OpportunityLineItem__r.CentroDistribuicao__c;
    //                     this.unitarioPortal                    = item.OpportunityLineItem__r.ValorPortal__c;
    //                     this.quantidadePortal                  = item.OpportunityLineItem__r.QuantidadePortal__c;
    //                     this.comentario                        = item.OpportunityLineItem__r.comentarios__c;
    //                     List<ProgramacaoEntrega> lprgEntrada = new List<ProgramacaoEntrega>();
    //                     if(item.OpportunityLineItem__r.ProgramacaoEntrega__c != null){
    //                         lprgEntrada = (List<ProgramacaoEntrega>)JSON.deserialize(item.OpportunityLineItem__r.ProgramacaoEntrega__c, List<ProgramacaoEntrega>.class);
    //                         if(lprgEntrada.isEmpty()){
    //                             if(item.ProgramacaoEntrega__c != null ){
    //                                 lprgEntrada = new List<ProgramacaoEntrega>();
    //                                 lprgEntrada = (List<ProgramacaoEntrega>)JSON.deserialize(item.ProgramacaoEntrega__c, List<ProgramacaoEntrega>.class);
    //                                 if(lprgEntrada.isEmpty()){
    //                                     this.ProgramacaoEntrega        = '';
    //                                 }else{
    //                                     this.ProgramacaoEntrega        = item.ProgramacaoEntrega__c;
    //                                 }
    //                             }else{
    //                                 this.ProgramacaoEntrega        = '';
    //                             }
    //                         }else{
    //                             this.ProgramacaoEntrega        = item.OpportunityLineItem__r.ProgramacaoEntrega__c;
    //                         }
    //                     }else{
    //                         if(item.ProgramacaoEntrega__c != null ){
    //                             lprgEntrada = new List<ProgramacaoEntrega>();
    //                             lprgEntrada = (List<ProgramacaoEntrega>)JSON.deserialize(item.ProgramacaoEntrega__c, List<ProgramacaoEntrega>.class);
    //                             if(lprgEntrada.isEmpty()){
    //                                 this.ProgramacaoEntrega        = '';
    //                             }else{
    //                                 this.ProgramacaoEntrega        = item.ProgramacaoEntrega__c;
    //                             }
    //                         }else{
    //                             this.ProgramacaoEntrega        = '';
    //                         }
    //                     }
                
    //                     this.ProgramacaoEntrega                = (item.OpportunityLineItem__r.ProgramacaoEntrega__c == null) ? item.ProgramacaoEntrega__c:item.OpportunityLineItem__r.ProgramacaoEntrega__c ;
    //                     this.unitario                          = String.valueOf(item.OpportunityLineItem__r.ValorCx__c);// != null && fatVal != null ? String.valueOf(item.OpportunityLineItem__r.ValorCx__c / fatVal) : item.OpportunityLineItem__r.UnitPrice != null ? String.valueOf(item.OpportunityLineItem__r.UnitPrice) : null;
    //                     if(this.unitario == null){
    //                         this.unitario = String.valueOf(item.OpportunityLineItem__r.UnitPrice);
    //                     }
    //                     // this.caixa                             = item.OpportunityLineItem__r.ValorCx__c != null ? String.valueOf(item.OpportunityLineItem__r.ValorCx__c) : null;
    //                     // this.inicialUnitario                   = fatVal != null ? (String.valueOf((item.OpportunityLineItem__r.ValorSugerido__c != null && item.OpportunityLineItem__r.ValorSugerido__c > 0) && fatVal != null ? item.OpportunityLineItem__r.ValorSugerido__c / fatVal : ((item.OpportunityLineItem__r.ValorMalha__c == null ? item.OpportunityLineItem__r.ListPrice : item.OpportunityLineItem__r.ValorMalha__c) / fatVal))) : null;
    //                     // this.inicialCaixa                      = String.valueOf((item.OpportunityLineItem__r.ValorSugerido__c != null && item.OpportunityLineItem__r.ValorSugerido__c > 0) && fatVal != null ? item.OpportunityLineItem__r.ValorSugerido__c / fatVal : ((item.OpportunityLineItem__r.ValorMalha__c == null ? item.OpportunityLineItem__r.ListPrice : item.OpportunityLineItem__r.ValorMalha__c)));
    //                     // this.precoFabricaCx                    = item.OpportunityLineItem__r.ValorCx__c != null ? String.valueOf(item.OpportunityLineItem__r.ValorCx__c) : null;
    //                     // this.precoFabricaUn                    = item.OpportunityLineItem__r.ValorCx__c != null && fatVal != null ? String.valueOf(item.OpportunityLineItem__r.ValorCx__c / fatVal) : null;
    //                 }
    //                 // this.precoTabelaCx                     = price != null ? String.valueOf(price) : null;
    //                 // this.precoTabelaUn                     = price != null && fatVal != null ? String.valueOf(price / fatVal) : null;
    //             }
    //         }
    //     }
    // }

    // public class VinculosDataDTO {

        
    //     public String codigoProdutoERP;	//123
    //     public String bu;	//Materiais
    //     public String mesa;	//A
    //     public String vendedor;	//001234
    //     public String createdAt;	//2021-11-11T12:14:19.000Z
    //     public String updateAt;
    //     public Double fatorConversao;
    //     public String tipoConversaoUnidadeMedida;
    //             //2021-11-11T12:14:19.000Z
    //     // public static fromJSON parse(String json){
    //     //     return (fromJSON) System.JSON.deserialize(json, fromJSON.class);
    //     // }
    
    //     // static testMethod void testParse() {
    //     //     String json=		'{'+
    //     //     '                    "codigoProdutoERP": "123",'+
    //     //     '                    "bu": "Materiais",'+
    //     //     '                    "mesa": "A",'+
    //     //     '                    "vendedor": "001234",'+
    //     //     '                    "createdAt": "2021-11-11T12:14:19.000Z",'+
    //     //     '                }';
    //     //     fromJSON obj = parse(json);
    //     //     System.assert(obj != null);
    //     // }
    // }

    // public class VinculosData {
    //     @AuraEnabled public String idCustomer;
    //     @AuraEnabled public String nome;
    //     @AuraEnabled public String id;
    //     @AuraEnabled public String estoque;
    //     @AuraEnabled public String prodCode;
    //     @AuraEnabled public String unidadePrincipal;
    //     //@AuraEnabled public Decimal quantidadeCx; ainda não foi decidido
    //     @AuraEnabled public String principioAtivo;
    //     @AuraEnabled public String fornecedor;
    //     @AuraEnabled public String lastOferDate;
    //     @AuraEnabled public String lastOferStage;
    //     @AuraEnabled public Double lastOferAmount;
    //     @AuraEnabled public String tipoConversao;
    //     @AuraEnabled public Double fatorConversao;
    //     @AuraEnabled public String CategoriaComercial;
    //     @AuraEnabled public String createdAt;
    //     @AuraEnabled public String updateAt;

    //     // usado para mostrar os valores de um único item solicitado, getHistoricoVinculos
    //     public VinculosData(QuoteItem__c qItem, Product2 prod, VinculosDataDTO vinculo, Map<String, Decimal> mapEstoque, OpportunityLineItem lastItem) {

    //         if(lastItem != null){
                
    //             this.fatorConversao         = lastItem.FatorConversao__c;
    //             this.tipoConversao          = lastItem.TipoConversao__c;

    //             Boolean pedidoGanho         = lastItem.Opportunity.Probability == 100;

    //             this.lastOferDate           = lastItem.CreatedDate.formatGMT('dd/MM/yyyy');
    //             this.lastOferAmount         = lastItem.ValorTotal__c != null && lastItem.ValorTotal__c != 0 ? lastItem.ValorTotal__c : lastItem.UnitPrice;
    //             this.lastOferStage          = pedidoGanho ? 'Ganha' : 'Perdida';

    //         } else if(vinculo != null){
    //             this.fatorConversao     = vinculo.fatorConversao;
    //             this.tipoConversao      = vinculo.tipoConversaoUnidadeMedida;
    //             this.createdAt = String.isNotBlank(vinculo.createdAt) ? vinculo.createdAt : null;
    //             this.updateAt = String.isNotBlank(vinculo.updateAt) ? vinculo.updateAt : null;
    //         }

    //         if(prod != null){
    //             this.nome               = prod.Name;
    //             this.id                 = prod.Id;
    //             this.prodCode           = prod.ProductCode;
    //             this.unidadePrincipal   = prod.UnidadeMedida__c;
    //             this.principioAtivo     = prod.Description;
    //             this.fornecedor         = prod.Fornecedor__r?.Name;
    //             this.CategoriaComercial = prod.CategoriaComercial__c;
    //             this.estoque = String.isBlank(this.prodCode) ? 'Produto não identificado' : mapEstoque.containsKey(this.prodCode) ? String.valueOf(mapEstoque.get(this.prodCode)) : 'Informação não disponível';
    //         }
    //     }
    // }

    // public class ProgramacaoEntrega {
    //     @AuraEnabled public String data;
    //     @AuraEnabled public String quantidade;
    // }

    // @AuraEnabled
    // public static list<ProgramacaoEntrega> getProgramacaoEntrega(String quoteIdPortal){
        
    //     List<QuoteItem__c> qItemList = [SELECT Id, ProgramacaoEntrega__c FROM QuoteItem__c WHERE IdPortal__c =: quoteIdPortal ];
    //     List<ProgramacaoEntrega> lprgEntrada = new List<ProgramacaoEntrega>();
    //     for(QuoteItem__c qItem : qItemList){
    //         if(String.isNotEmpty(qitem.ProgramacaoEntrega__c) && qitem.ProgramacaoEntrega__c != '[]'){
    //             lprgEntrada = (List<ProgramacaoEntrega>)JSON.deserialize(qItem.ProgramacaoEntrega__c, List<ProgramacaoEntrega>.class);
    //             break;
    //         }
    //     }
    //     return lprgEntrada;
    // }

    // public class EnderecoCobranca {
    //     @AuraEnabled public String RuaCobranca;
    //     @AuraEnabled public String CidadeCobranca;
    //     @AuraEnabled public String EstadoCobranca;
    //     @AuraEnabled public String PaisCobranca;
    //     @AuraEnabled public String CEPCobranca;

    //     public EnderecoCobranca(Account acc){
    //         if(acc != null){
    //             this.RuaCobranca = acc.BillingStreet;
    //             this.CidadeCobranca = acc.BillingCity;
    //             this.EstadoCobranca = acc.BillingState;
    //             this.PaisCobranca = acc.BillingCountry;
    //             this.CEPCobranca = acc.BillingPostalCode;
    //         }
    //     }
    // }


    // @AuraEnabled
    // public static StandardResponse deletarResposta(String quoteitemId){
    //     List<SObject> lstDelete = new List<SObject>();
    //     StandardResponse response = new StandardResponse();
    //     try { 

    //         Opportunity opp = getOppWithQuoteItemByQuoteItemIds(new Set<Id>{quoteitemId});
    //         lstDelete.add(opp.QuoteItems__r[0]);
           
    //         if(opp.QuoteItems__r[0].Status__c == 'Respondido' || opp.QuoteItems__r[0].Status__c == 'Resgatado' || opp.QuoteItems__r[0].Status__c == 'Aguardando Integração' /*|| opp.QuoteItems__r[0].Status__c == 'Cancelado'*/ ){
    //             response.addError('Não é possível deletar um item cuja resposta já foi enviada.');
              
    //         } else if(opp.QuoteItems__r[0].OpportunityLineItem__c != null){
    //             lstDelete.add(opp.QuoteItems__r[0].OpportunityLineItem__r);            
    //         }

    //         if (lstDelete.size() > 0) {
    //             delete lstDelete;                      
    //         } 

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
        
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse getBudgetItemData(String oppId, String idPortalItem, String idCustomer){
    //     StandardResponse response = new StandardResponse();
    //     try {

    //         Opportunity opp = getOpportunity(oppId, new List<String>{idPortalItem});

    //         List<BudgetItemData> Itens = buildItems(opp);
            
    //         if(!Itens.isEmpty()){
    //             try{
    //                 Itens = setTabulacaoRules(opp, Itens, idCustomer);
    //             }catch(Exception ex){
    //                 response.code = '201';
    //             }
    //         }

    //         response.setData('Itens', Itens);

    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @testVisible
    // private static List<BudgetItemData> setTabulacaoRules(Opportunity opp, List<BudgetItemData> Itens, String idCustomer){
    //     List<QuoteItem__c> itemsToUpdate = new List<QuoteItem__c>();
    //     List<QuoteItem__c> qItemMateriaisList = [
    //         SELECT TabulacaoN1__c
    //         FROM QuoteItem__c 
    //         WHERE OpportunityId__r.AccountId =: opp.AccountId
    //         AND OpportunityId__c !=: opp.Id
    //         AND IdCustomer__c =: idCustomer
    //         AND IdIntegrator__c != null
    //         AND Categoria__c = 'M'
    //         AND TabulacaoN1__c != null
    //         AND DataHoraResposta__c != null
    //         ORDER BY DataHoraResposta__c DESC
    //         LIMIT 1
    //     ];
    //     List<QuoteItem__c> qItemEspecialidadeList = [
    //         SELECT TabulacaoN1__c 
    //         FROM QuoteItem__c 
    //         WHERE OpportunityId__r.AccountId =: opp.AccountId
    //         AND OpportunityId__c !=: opp.Id 
    //         AND IdCustomer__c =: idCustomer
    //         AND IdIntegrator__c != null
    //         AND Categoria__c = 'S'
    //         AND TabulacaoN1__c != null
    //         AND DataHoraResposta__c != null
    //         ORDER BY DataHoraResposta__c DESC
    //         LIMIT 1
    //     ];
    //     List<QuoteItem__c> qItemGenericoList = [
    //         SELECT TabulacaoN1__c 
    //         FROM QuoteItem__c 
    //         WHERE OpportunityId__r.AccountId =: opp.AccountId
    //         AND OpportunityId__c !=: opp.Id 
    //         AND IdCustomer__c =: idCustomer
    //         AND IdIntegrator__c != null
    //         AND Categoria__c = 'G'
    //         AND TabulacaoN1__c != null
    //         AND DataHoraResposta__c != null
    //         ORDER BY DataHoraResposta__c DESC
    //         LIMIT 1
    //     ];
        
    //     Map<String, String> tabulacaoN1byBUMap = new Map<String, String>();
    //     if(!qItemGenericoList.isEmpty()){
    //         tabulacaoN1byBUMap.put('G', qItemGenericoList[0].TabulacaoN1__c);
    //     }
    //     if(!qItemMateriaisList.isEmpty()){
    //         tabulacaoN1byBUMap.put('M', qItemMateriaisList[0].TabulacaoN1__c);
    //     }
    //     if(!qItemEspecialidadeList.isEmpty()){
    //         tabulacaoN1byBUMap.put('S', qItemEspecialidadeList[0].TabulacaoN1__c);
    //     }
    //     for(BudgetItemData item: Itens[0].respostas){
    //         if(String.isBlank(item.categoriaVendedor) || (String.isNotBlank(item.tabulacaoN1) && item.tabulacaoN1 != 'SEM OFERTA')){
    //             continue;
    //         }
    //         if(tabulacaoN1byBUMap.get(item.categoriaVendedor) == 'Não pertence a minha BU'){
    //             item.tabulacaoN1 = 'Não pertence a minha BU';
    //             itemsToUpdate.add(new QuoteItem__c(Id = item.Id, TabulacaoN1__c = item.tabulacaoN1));
    //         }
    //     }
    //     if(!itemsToUpdate.isEmpty()){
    //         update itemsToUpdate;
    //     }
        
    //     return Itens;
    // }

    // @AuraEnabled
    // public static StandardResponse adicionarResposta(String quoteitemId, String selectedBU){

    //     StandardResponse response = new StandardResponse();
    //     QuoteItem__c Qi = [SELECT CNPJCD__c, CreatedDate, OpportunityId__c, 
    //                             IdIntegrator__c, IdPortal__c, IdCustomer__c, Name, ProdutosVinculadosAnteriormente__c, Quantity__c,  
    //                             CustomerDescription__c, CustomerMeasurementUnit__c,  
    //                             Status__c, UnitPrice__c, SequenciaOC__c, Vendedor__c, Product__c, IntegratorMeasurementUnit__c 
    //                         FROM QuoteItem__c WHERE Id =: quoteitemId]; 
    //     Opportunity opp = [SELECT AccountId, ExternalPortal__c FROM Opportunity WHERE Id =: Qi.OpportunityId__c];
    //     list<QuoteItem__c> lQi = [SELECT Id FROM QuoteItem__c WHERE Product__c =: Qi.Product__c AND OpportunityId__c =: Qi.OpportunityId__c AND  OpportunityId__r.Integradora__c = 'BIONEXO'  AND Status__c IN ('Respondido','Resgatado','Aprovado','Aguardando Integração') AND TabulacaoN1__c = 'Cotado'];
    //     if(!lQi.isEmpty()){
    //         response.addError('Não é possível adicionar');
    //         return response;
    //     }
    //     try { 
    //         QuoteItem__c newQi = new QuoteItem__c();
    //         newQi = Qi.clone(false, false, false, false);
    //         newQi.Vendedor__c = UserInfo.getUserId();
    //         newQi.Categoria__c = selectedBU;
    //         newQi.CNPJCD__c = null;
    //         newQi.ExternalId__c = opp.ExternalPortal__c + newQi.IdPortal__C + newQi.Vendedor__c + Datetime.now();
    //         newQi.Status__c = 'Não Vinculado';
    //         //Portal-980
    //         newQi.TabulacaoN1__c = null;//?
    //         newQi.Product__c = null;
    //         // newQi.OpportunityLineItem__c = newOli.Id;
    //         insert newQi;
    //         response.setData('item', getUpdatedItem(newQi.Id));
    //     }catch(Exception ex) {
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static StandardResponse getUserCategories(Id opportunityId) {
    //     StandardResponse response = new StandardResponse();
    //     List<PicklistOption> options = new List<PicklistOption>();
    //     try {
    //         List<AggregateResult> userSetorizationList = [
    //             SELECT Categoria__c
    //             FROM Setorizacao__c 
    //             WHERE VendedorSuporte__c = :UserInfo.getUserId()
    //             AND Conta__c IN (SELECT AccountId FROM Opportunity WHERE Id = :opportunityId)
    //             AND Categoria__c != null
    //             GROUP BY Categoria__c
    //         ];
    //         Map<String, String> categoriesLabels = getSectorizationCategoriesLabels();
    //         for(AggregateResult userSetorization : userSetorizationList){

    //             String categoryValue = (String)userSetorization.get('Categoria__c');
    //             String categoryLabel = categoriesLabels.get(categoryValue);

    //             if(categoryLabel != null){

    //                 options.add(new PicklistOption(false, categoryValue, categoryLabel));
    //             }
    //         }
    //         if(!options.isEmpty()){
    //             response.setData(JSON.serialize(options));
    //         }
    //     } catch (Exception ex){
    //         ExceptionUtils.debug(ex);
    //         response.addError(ex.getMessage());
    //     }
    //     return response;
    // }

    // @AuraEnabled
    // public static Map<String,String> getSectorizationCategoriesLabels() {
    //     Map<String,String> mapCategories = new Map<String,String>();
    //     List<Schema.PicklistEntry> pickListEntries = Schema.SObjectType.Setorizacao__c.fields.Categoria__c.getPicklistValues();
    //     for (Schema.PicklistEntry  pickListEntry: pickListEntries) {
    //         mapCategories.put(pickListEntry.getValue(), pickListEntry.getLabel());
    //     }
    //     return mapCategories;
    // }

}
