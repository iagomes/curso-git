public without sharing class BudgetDetailSelector {

    /* budgetDetail */
    public static List<CondicaoPagamentoPorCD__c> getCondicaoPagamentoPorCD(String oppId){
        return [
            SELECT Id, 
            CentroDistribuicao__c, CloseDate__c, CNPJCD__c, CondicaoPagamentoPL__c,
            FretePicklist__c,
            MinimumBilling__c,
            ObservacoesLongText__c,
            PrazoEntrega__c, PrazoValidade__c
            FROM CondicaoPagamentoPorCD__c 
            WHERE Orcamento__c =: oppId 
        ];
    }

    public static List<AggregateResult> getEstoqueAggregated(String accountId, Set<Id> productIdSet){
        return getEstoqueAggregated(accountId, new List<Id>(productIdSet));
    }

    public static List<AggregateResult> getEstoqueAggregated(String accountId, List<String> productIdSet){
        return [    
            SELECT NomeProduto__c,
            SUM(Saldo__c) Saldo
            FROM Estoque__c
            WHERE (NomeCliente__c = null OR NomeCliente__c = :accountId)
            AND NomeProduto__c IN :productIdSet
            GROUP BY NomeProduto__c
            HAVING SUM(Saldo__c) > 0
            LIMIT 2000
        ];
    }

    public static Opportunity getOpportunity(String oppId){
        return [
            SELECT Id,
            AccountId, Account.RecordType.DeveloperName, Account.ShippingState,
            Account.CondicaoPagamento__c, Account.CondicaoPagamento__r.Name,
            CanalEntrada__c, CDsBloqueado__c, CloseDate, CNPJ__c, CondicaoPagamento__c,
            CondicaoPagamento__r.Name, CotacoesConsolidadas__c, CPF__c,
            DataVencimento__c,
            ExternalPortal__c,
            MensagemErroIntegracaoPortalCotacoes__c, MinimumBilling__c,
            ObservacoesLongText__c, OrcamentoTravado__c,
            PrazoEntrega__c, PrazoValidade__c, Pricebook2Id,
            StageName, StatusIntegracaoPortalCotacoes__c,
            TabulacaoN1__c, TabulacaoN2__c
            FROM Opportunity 
            WHERE Id =: oppId
        ];
    }

    public static OpportunityTeamMember getOpportunityTeamMember(String oppId){
        List<OpportunityTeamMember> oppTeamList = [
            SELECT Id, 
            OpportunityId, 
            TabulacaoN1__c, TabulacaoN2__c 
            FROM OpportunityTeamMember
            WHERE OpportunityId =: oppId 
            AND UserId =: UserInfo.getUserId() 
            LIMIT 1
        ];
        return oppTeamList.size() > 0 ? oppTeamList[0] : null;
    }

    public static List<QuoteItem__c> getAllQuoteItemList(String oppId){
        return [
            SELECT Id, 
            CategoriaCliente__c, CustomerDescription__c, CustomerMeasurementUnit__c, 
            FavoriteBrands__c, 
            IdPortal__c, IdCustomer__c, 
            Product__c, ProgramacaoEntrega__c, 
            Quantity__c, 
            SequenciaOC__c,
            TabulacaoN1__c, 
            Vendedor__c 
            FROM QuoteItem__c 
            WHERE OpportunityId__c = :oppId  
            ORDER BY IdPortal__c ASC
        ];
    }

    public static List<Setorizacao__c> getSetorizacaoList(String accountId){
        return [
            SELECT Categoria__c
            FROM Setorizacao__c
            WHERE Conta__c = :accountId
            AND VendedorSuporte__c = :UserInfo.getUserId()
        ];
    }

    /* budgetDetailEditItem */
    public static QuoteItem__c getUniqueQuoteItemByIdPortal(String idPortal, String oppId){
        List<QuoteItem__c> qItemList = [
            SELECT Id,
            Categoria__c, CNPJCD__c, CustomerDescription__c, CustomerMeasurementUnit__c,
            DataHoraResposta__c,
            IdPortal__c, IdIntegrator__c, IdCustomer__c, IntegratorMeasurementUnit__c,
            OpportunityId__c,
            OpportunityLineItem__c, OpportunityLineItem__r.CentroDistribuicao__c, OpportunityLineItem__r.comentarios__c,
            OpportunityLineItem__r.FatorConversao__c, OpportunityLineItem__r.SequenciaOC__c, OpportunityLineItem__r.Status__c,
            OpportunityLineItem__r.TipoConversao__c, OpportunityLineItem__r.ValorPortal__c,
            Name,
            Product__c, Product__r.CategoriaComercial__c, Product__r.Description, Product__r.FatorConversao__c,
            Product__r.Fornecedor__r.Name, Product__r.Name, Product__r.ProductCode, Product__r.SegundaUnidade__c,
            Product__r.Temperatura__c, Product__r.TipoConversao__c, Product__r.UnidadeMedida__c,
            ProdutosVinculadosAnteriormente__c,
            Quantity__c,
            SequenciaOC__c, Status__c,
            TabulacaoN1__c,
            UnitPrice__c,
            Vendedor__c, Vendedor__r.Name, VendedorRespondeu__c
            FROM QuoteItem__c
            WHERE IdPortal__c = :idPortal
            AND OpportunityId__c = :oppId
            LIMIT 1
        ];
        return !qItemList.isEmpty() ? qItemList[0] : null;
    }

    public static List<QuoteItem__c> getQuoteItemsByIdPortal(String idPortal, String oppId){
        return [
            SELECT Id,
            Categoria__c, CNPJCD__c,
            DataHoraResposta__c,
            IdPortal__c,
            OpportunityId__c, OpportunityId__r.DataVencimento__c,
            OpportunityLineItem__c, OpportunityLineItem__r.CentroDistribuicao__c, OpportunityLineItem__r.comentarios__c,
            OpportunityLineItem__r.FatorConversao__c, OpportunityLineItem__r.SequenciaOC__c, OpportunityLineItem__r.Status__c,
            OpportunityLineItem__r.TipoConversao__c, OpportunityLineItem__r.ValorPortal__c,
            Product__c, Product__r.CategoriaComercial__c, Product__r.Description, Product__r.FatorConversao__c,
            Product__r.Fornecedor__r.Name, Product__r.Name, Product__r.ProductCode, Product__r.SegundaUnidade__c,
            Product__r.Temperatura__c, Product__r.TipoConversao__c, Product__r.UnidadeMedida__c,
            SequenciaOC__c, Status__c, StatusIntegrationResponse__c,
            TabulacaoN1__c,
            Vendedor__c, Vendedor__r.Name, VendedorRespondeu__c
            FROM QuoteItem__c
            WHERE IdPortal__c = :idPortal
            AND OpportunityId__c = :oppId
        ];
    }

    public static QuoteItem__c getQuoteItem(String qItemId){
        return getQuoteItemList(new List<String>{qItemId})[0];
    }

    public static Map<Id, QuoteItem__c> getQuoteItemMap(List<String> qItemIdList){
        return new Map<Id, QuoteItem__c>(getQuoteItemList(qItemIdList));
    }

    public static List<QuoteItem__c> getQuoteItemList(List<String> qItemIdList){ 
        return [
            SELECT Id,
            Categoria__c, CNPJCD__c, CustomerMeasurementUnit__c,
            DataHoraResposta__c,
            IdPortal__c,
            OpportunityId__c, OpportunityId__r.DataVencimento__c,
            OpportunityLineItem__c, OpportunityLineItem__r.CentroDistribuicao__c, OpportunityLineItem__r.comentarios__c,
            OpportunityLineItem__r.FatorConversao__c, OpportunityLineItem__r.SequenciaOC__c, OpportunityLineItem__r.Status__c,
            OpportunityLineItem__r.TipoConversao__c, OpportunityLineItem__r.ValorPortal__c,
            Product__c, Product__r.CategoriaComercial__c, Product__r.Description, 
            Product__r.FatorConversao__c, Product__r.FatorConversaoPortal__c, Product__r.Fornecedor__r.Name,
            Product__r.Name, Product__r.ProductCode, Product__r.SegundaUnidade__c,
            Product__r.Temperatura__c, Product__r.TipoConversao__c, Product__r.UnidadeMedida__c,
            SequenciaOC__c, Status__c, StatusIntegrationResponse__c,
            TabulacaoN1__c,
            Vendedor__c, Vendedor__r.Name, VendedorRespondeu__c
            FROM QuoteItem__c
            WHERE Id IN :qItemIdList
        ];
    }

    public static List<PricebookEntry> getPricebookEntryList(String productId, String pricebook2Id){
        return [
            SELECT Id,
            IsActive, 
            UnitPrice, 
            Pricebook2Id, Product2Id 
            FROM PricebookEntry 
            WHERE Product2Id =: productId
            AND Pricebook2Id =: pricebook2Id 
            LIMIT 1
        ];
    }

    public static List<CondicaoPagamentoPorCD__c> getConditionPaymentByCD(String oppId, String cnpj){
        return getConditionPaymentByCD(oppId, new List<String>{cnpj});
    }

    public static List<CondicaoPagamentoPorCD__c> getConditionPaymentByCD(String oppId, List<String> cnpjList){
        return [
            SELECT Id, 
            CloseDate__c,CondicaoPagamento__c, CondicaoPagamentoPL__c, 
            MinimumBilling__c,
            ObservacoesLongText__c, Orcamento__c,
            PrazoEntrega__c, PrazoValidade__c,
            FretePicklist__c 
            FROM CondicaoPagamentoPorCD__c 
            WHERE orcamento__c =: oppId 
            AND  CNPJCD__c IN :cnpjList
        ];
    }

    public static Group getCurrentUserGroup(){
        List<Group> groupList = getCurrentUserGroupList();
        return !groupList.isEmpty() ? groupList[0] : null;
    }

    public static List<Group> getCurrentUserGroupList(){
        return [
            SELECT DeveloperName 
            FROM Group 
            WHERE RelatedId 
            IN (SELECT UserRoleId FROM User WHERE Id =: UserInfo.getUserId())
        ];
    }

    public static List<Estoque__c> getEstoqueListByProdCode(String productCode){
        return [
            SELECT CNPJCD__c, PrevisaoEntrada__c, QuantidadePrevista__c
            FROM Estoque__c
            WHERE CodigoProduto__c = :productCode
        ];
    }

    public static OpportunityLineItem getLastOppLineItemWon(String productCode, String accountId){

        List<OpportunityLineItem> oppLineItemList = [
            SELECT Id, CreatedDate, ValorPortal__c
            FROM OpportunityLineItem
            WHERE Product2.ProductCode = :productCode
            AND Opportunity.AccountId = :accountId
            AND Opportunity.StageName = 'Gerar Pedido'
            AND ValorPortal__c > 0
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        return !oppLineItemList.isEmpty() ? oppLineItemList[0] : null;
    }

    public static OpportunityLineItem getLastOppLineItemLost(String productCode, String accountId){
    
        List<OpportunityLineItem> oppLineItemList = [
            SELECT Id, CreatedDate, ValorPortal__c
            FROM OpportunityLineItem
            WHERE Product2.ProductCode = :productCode
            AND Opportunity.AccountId = :accountId
            AND Opportunity.StageName = 'Sem Retorno'
            AND ValorPortal__c > 0
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        return !oppLineItemList.isEmpty() ? oppLineItemList[0] : null;
    }

    public static List<QuoteItem__c> getQuoteItemsWithCNPJCD(String oppId){
        return [
            SELECT CNPJCD__c
            FROM QuoteItem__c 
            WHERE CNPJCD__c != null 
            AND OpportunityId__c =: oppId
        ];
    }

    public static List<CondicaoPagamentoPorCD__c> getConditionPaymentList(String oppId){
        return [
            SELECT ID, 
            CNPJCD__c 
            FROM CondicaoPagamentoPorCD__c 
            WHERE Orcamento__c =: oppId 
            AND CNPJCD__c != NULL
        ];
    }

    public static List<AggregateResult> getUserCategoriesAggregated(String oppId){
        return [
            SELECT Categoria__c
            FROM Setorizacao__c 
            WHERE VendedorSuporte__c = :UserInfo.getUserId()
            AND Conta__c IN (SELECT AccountId FROM Opportunity WHERE Id = :oppId)
            AND Categoria__c IN ('S','M','G')
            GROUP BY Categoria__c
        ];
    }

    public static List<QuoteItem__c> getQuoteItemForSetItemCd(String oppId, String cnpjcd, String qItemId, String idPotal){
        return [
            SELECT Id, Product__c
            FROM QuoteItem__c 
            WHERE OpportunityId__c =: oppId
            AND CNPJCD__c =:  cnpjcd
            AND Id !=: qItemId
            AND IdPortal__c =: idPotal
        ];
    }

    public static List<ItemCampanha__c> getItemCampaignByCD(List<String> cdCodeList, String productCode, String accountId){
        return [
            SELECT Campanha__r.RecordType.DeveloperName,
            NomeProduto__c, PrecoUnitario__c, Campanha__r.CodigoCD__c
            FROM ItemCampanha__c
            WHERE NomeProduto__r.ProductCode = :productCode
            AND (
                Campanha__r.Cliente__c = :accountId 
                OR (Campanha__r.Cliente__c = null AND Campanha__r.GrupoCliente__c = null)
            )
            AND (
                (Campanha__r.StartDate <= TODAY AND Campanha__r.EndDate >= TODAY) 
                OR (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY)
            )
            AND (
                Campanha__r.CodigoCD__c = NULL 
                OR Campanha__r.CodigoCD__c LIKE :cdCodeList
            )
            ORDER BY Campanha__r.CodigoCD__c ASC NULLS LAST
        ];
    }

    public static List<ItemContrato__c> getContractByProduct(String accountId, String productCode){
        return [
            SELECT NomeProduto__c, PrecoMinimo__c, PrecoUnitario__c,
            NumeroContrato__c, NumeroContrato__r.TipoRegra__c
            FROM ItemContrato__c 
            WHERE NumeroContrato__r.AccountId = :accountId
            AND NumeroContrato__r.TipoRegra__c IN ('O', 'A')
            AND Status__c = 'Aprovado'
            AND (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY)
            AND NomeProduto__r.ProductCode = :productCode
        ];
    }

    public static List<QuoteItem__c> getQuoteItemsFromIdPortalUserBu(List<String> quoteItemIdsPortal, String oppId, String userId, List<String> categorias){
        return [
            SELECT Id, 
            Categoria__c,
            IdPortal__c, 
            OpportunityId__r.StageName, 
            Vendedor__c
            FROM QuoteItem__c 
            WHERE IdPortal__c IN: quoteItemIdsPortal 
            AND OpportunityId__c =: oppId
            AND Vendedor__c =: userId
            AND Categoria__c IN :categorias
        ];
    }

    public static List<QuoteItem__c> getQuoteItemListToCopy(Set<String> idPortalSet, String oppId){
        return getQuoteItemListToCopy(new List<String>(idPortalSet), oppId);
    }

    public static List<QuoteItem__c> getQuoteItemListToCopy(List<String> idPortalList, String oppId){
        return [
            SELECT OpportunityId__c, IdIntegrator__c, IdPortal__c,
            IdCustomer__c, ProdutosVinculadosAnteriormente__c, Quantity__c,  
            CustomerDescription__c, CustomerMeasurementUnit__c, OpportunityId__r.StageName,
            SequenciaOC__c, IntegratorMeasurementUnit__c, OpportunityId__r.ExternalPortal__c
            FROM QuoteItem__c 
            WHERE IdPortal__c IN : idPortalList
            AND OpportunityId__c = :oppId
        ];
    }

    public static List<QuoteItem__c> getQuoteItemProgramacaoEntrega(String idPortal){
        return [
            SELECT Id, ProgramacaoEntrega__c
            FROM QuoteItem__c 
            WHERE IdPortal__c =: idPortal 
        ];
    }

    public static List<AggregateResult> getQuoteItemCategoryAggregate(String oppId){
        return [
            SELECT CategoriaCliente__c 
            FROM QuoteItem__c 
            WHERE OpportunityId__c = :oppId 
            AND CategoriaCliente__c != null 
            GROUP BY CategoriaCliente__c
        ];
    }

    public static List<CondicaoPagamento__c> getConditionPaymentByName(List<String> nameList){
        return [
            SELECT Id, Name
            FROM CondicaoPagamento__c
            WHERE Name IN :nameList
        ];
    }

    public static QuoteItem__c getQuoteItemWithHistory(String idPortalItem, String oppId){
        List<QuoteItem__c> qItemList =  [
            SELECT Id,
            IdCustomer__c,
            OpportunityId__c, OpportunityId__r.AccountId,
            Product__c, Product__r.ProductCode, ProdutosVinculadosAnteriormente__c
            FROM QuoteItem__c
            WHERE IdPortal__c =: idPortalItem
            AND OpportunityId__c =: oppId
            LIMIT 1
        ];
        return !qItemList.isEmpty() ? qItemList[0] : null;
    }

    public static List<Product2> getProductListFromCode(Set<String> prodIdSet){
        return getProductListFromCode(new List<String>(prodIdSet));
    }

    public static Map<Id, Product2> getProductMapFromCode(Set<String> prodIdSet){
        return new Map<Id, Product2>(getProductListFromCode(new List<String>(prodIdSet)));
    }

    public static List<Product2> getProductListFromCode(List<String> prodIdList){
        return [
            SELECT Id,
            CategoriaComercial__c,
            Description,
            Fornecedor__r.Name,
            Name,
            ProductCode,
            UnidadeMedida__c
            FROM Product2
            WHERE ProductCode IN :prodIdList
        ];
    }
    public static List<AggregateResult> getLastOpportunityLineItemAggr(Id accountId, Set<Id> prodIdSet){
        return getLastOpportunityLineItemAggr(accountId, new List<Id>(prodIdSet));
    }

    public static List<AggregateResult> getLastOpportunityLineItemAggr(String accountId, List<String> prodIdList){
        return [
            SELECT ProductCode, Max(Id) id FROM OpportunityLineItem
            WHERE Opportunity.AccountId =: accountId
            AND Product2Id IN: prodIdList
            AND CreatedDate >= LAST_N_MONTHS: 11
            AND Opportunity.StageName IN ('Fechado/Perdido','Cancelada', 'Perdida', 'Sem Retorno', 'Fechado/Gerado','Gerar Pedido', 'Ganha')
            AND Opportunity.RecordType.DeveloperName = 'OrcamentoPortal'
            AND TabulacaoN1__c = 'Cotado'
            GROUP BY ProductCode
        ];
    }


    public static Map<Id, OpportunityLineItem> getLastOpportunityLineItemMap(List<String> oppLineItemIdList){
        return new Map<Id, OpportunityLineItem>(getLastOpportunityLineItemList(oppLineItemIdList));
    }

    public static List<OpportunityLineItem> getLastOpportunityLineItemList(List<String> oppLineItemIdList){
        return [
            SELECT Id,
            CreatedDate,
            DataPedidoGanho__c, DataPedidoPerdido__c,
            FatorConversao__c,
            Opportunity.AccountId, Opportunity.Probability, Opportunity.StageName,
            ProductCode,
            TipoConversao__c,
            UnitPrice,
            ValorTotal__c
            FROM OpportunityLineItem
            WHERE Id IN: oppLineItemIdList
        ];
    }

    public static List<QuoteItem__c> getQuoteItensUsingSameProduct(String oppId, Set<String> productSet, String idPortal){
        return [
            SELECT Product__c, SequenciaOC__c, OpportunityLineItem__r.SequenciaOC__c
            FROM QuoteItem__c
            WHERE OpportunityId__c = :oppId
            AND Product__c IN :productSet
            AND IdPortal__c != :idPortal
            AND OpportunityLineItem__c != null
        ];
    }
    
    public static List<CondicaoPagamentoPorCD__c> getUnfilledConditionPayment(String oppId, List<String> condPagCDIds){
        return [
            SELECT Id
            FROM CondicaoPagamentoPorCD__c
            WHERE 
            Orcamento__c = :oppId AND (
                MinimumBilling__c        = null OR
                CloseDate__c             = null OR
                PrazoEntrega__c          = null OR
                PrazoValidade__c         = null OR
                CondicaoPagamentoPL__c   = null OR
                CNPJCD__c                = null OR
                FretePicklist__c         = null OR
                CondicaoPagamentoPL__c   = ''   OR
                CNPJCD__c                = ''   OR
                FretePicklist__c         = ''   OR
                MinimumBilling__c        <= 0   OR
                PrazoEntrega__c          <= 0   OR
                PrazoValidade__c         <= 0    
            ) AND
            Id NOT IN :condPagCDIds
        ];
    }
}