global without sharing class OrderScreenController {

    public static final Id MOTHERORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();

    @AuraEnabled
    public static Boolean updatePaymentConditionAndNotesOrderSonAndSendToAutomaticIntegration(String orderHeaderInformation) {
        try {
            Map<String, Object> mapObjectToOrderHeaderEdited = (Map<String, Object>) JSON.deserializeUntyped(orderHeaderInformation);
            String recordId = String.valueOf(mapObjectToOrderHeaderEdited.get('recordId'));
            String orderFatherId = [SELECT OriginalOrder.Id FROM Order WHERE Id =: recordId].OriginalOrder.Id;

            if(OrderService.checkOriginalOrderTypeFromOrderSonId('Pedido de conta e ordem', recordId)) {
                OrderService.updatePaymentConditionAndNotesOrderSons(mapObjectToOrderHeaderEdited, orderFatherId);
                
                Map<Id, Order> mapOrderSonIdToOrder = new Map<Id, Order>([
                    SELECT Id
                    FROM Order 
                    WHERE OriginalOrder.Id =: orderFatherId
                    AND PedidoRemessa__c = false]);

                for(Id iOrderSonId : mapOrderSonIdToOrder.keySet()) {
                    System.enqueueJob(new IntegrationAutomaticLabOrderOUTQueueable(0, iOrderSonId, 'Pedido filho (edição da condição de pagamento)'));
                }
                 return true;
            } else {
                if(OrderService.updatePaymentConditionAndNotesOrder(mapObjectToOrderHeaderEdited)) {
                    System.enqueueJob(new IntegrationAutomaticLabOrderOUTQueueable(0, recordId, 'Pedido filho (edição da condição de pagamento)'));
                    return true;
                } else {
                    return false;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Method: OrderScreenController.updatePaymentConditionAndNotesOrderSon' + ' ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getConditionExternalId(String conditionId) {
        System.debug('conditionId: ' + conditionId);
        return conditionId == null ? null : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id =: conditionId][0].ExternalId__c;
    }

    @AuraEnabled(cacheable=true)
    public static String getContactData(String contatoOrcamento) {
        System.debug('contatoOrcamento: ' + contatoOrcamento);
        return contatoOrcamento == null ? null : [SELECT id, AccountId FROM Contact WHERE id = :contatoOrcamento][0].AccountId;
    }

    @AuraEnabled(cacheable=true)
    public static String getContactRelationData(Id accountId, Id contactId) {
        System.debug('AccountId: ' + accountId + ' / ContactId: ' + contactId);
        
        Id accountContactRelationId;
        for (AccountContactRelation accountContactRelation : [SELECT Id FROM AccountContactRelation WHERE AccountId =: accountId AND ContactId =: contactId]) {
            accountContactRelationId = accountContactRelation.Id;
        }

        return accountContactRelationId;
    }

    @AuraEnabled(cacheable=true)
    public static String getAddress(String addressId) {
        System.debug('enderecoEntregaId: ' + addressId);
        String stringAddress = '';
        EnderecoEntrega__c address = [
            SELECT 
                Id, 
                Logradouro__c, 
                Bairro__c, 
                Cidade__c, 
                Estado__c, 
                CEP__c
            FROM EnderecoEntrega__c
            WHERE Id =: addressId
            LIMIT 1
        ];

        if (address != null) {return address.Logradouro__c + ' - ' + address.Bairro__c + ' - ' + address.Cidade__c + ' - ' + address.Estado__c + ', ' + address.CEP__c;}

        return stringAddress;
    }

    @AuraEnabled
    public static String getAccountAddress(String accId){
        System.debug('enderecoEntregaId: ' + accId);
        String stringAddress = '';
        Account acc = [SELECT Id, ShippingStreet,ShippingState,ShippingPostalCode, ShippingCity  FROM Account WHERE Id =: accId];

        if (acc != null) {
            stringAddress += acc.ShippingStreet != null ? acc.ShippingStreet : '';
            stringAddress += acc.ShippingCity != null ? ' - ' + acc.ShippingCity : '';
            stringAddress += acc.ShippingState != null ? ' - ' + acc.ShippingState : '';
            stringAddress += acc.ShippingPostalCode != null ? ', ' + acc.ShippingPostalCode : '';
            System.debug('address => ' + stringAddress);
            return stringAddress;
        }

        return stringAddress;
    }

    @AuraEnabled(cacheable=true)
    public static String getEnderecoEntregaData(String enderecoEntregaId) {
        System.debug('enderecoEntregaId: ' + enderecoEntregaId);
        EnderecoEntrega__c enderecoEntrega = [
            SELECT 
                Id, 
                Estado__c 
            FROM EnderecoEntrega__c
            WHERE Id =: enderecoEntregaId
            LIMIT 1
        ];

        if (enderecoEntrega != null) {return enderecoEntrega.Estado__c;}

        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static String buscaCodigoLoja(String clienteId) {

        Account acc = [
            SELECT 
                Id, 
                CodigoLoja__c 
            FROM Account
            WHERE Id =: clienteId
        ];

        if (acc != null && acc.CodigoLoja__c != null) {
            return acc.CodigoLoja__c;
        }

        return '';
    }
    @AuraEnabled(cacheable=true)
    public static String getTpCondPag(String condicaoPagamento) {

        CondicaoPagamento__c condPag = [
            SELECT 
                Id, 
                TipoCondicaoPagamento__c 
            FROM CondicaoPagamento__c
            WHERE Id =: condicaoPagamento
        ];

        if (condPag != null && condPag.TipoCondicaoPagamento__c != null) {
            return condPag.TipoCondicaoPagamento__c;
        }

        return '';
    }
    

    // @AuraEnabled(cacheable=true)
    // public static AccountData getAccountData(String accId) {
    //     system.debug('entrou no apex getOrderData');

    //     AccountData accData;
    //     for (Account acc : [SELECT Id, CNPJ__c, CPF__c, ExternalId__c, Name
    //                         FROM Account WHERE Id =: accId]) {
    //         accData = new AccountData(acc);
    //     }

    //     return accData;
    // }
    
    @AuraEnabled(cacheable=true)
    public static AccountData getAccountData(String accId) {
        system.debug('entrou no apex getAccountData');
        Id contactRelationId;
        Id enderecoEntregaPadrao;
        Id contactId;
        for (Contact con : [SELECT Id FROM Contact WHERE AccountId =: accId AND Padrao__c = true]) {
            contactId = con.Id;
        }
        if (contactId != null) {
            for (AccountContactRelation contactRelation : [SELECT Id FROM AccountContactRelation WHERE AccountId =: accId AND ContactId =: contactId]) {
                contactRelationId = contactRelation.Id;
            }
        }

        for (EnderecoEntrega__c endEntrega : [SELECT Id FROM EnderecoEntrega__c WHERE Cliente__c = :accId AND EnderecoPrioritario__c = true]){ 
            enderecoEntregaPadrao = endEntrega.Id;
        }
        System.debug('enderecoEntregaPadrao: ' + enderecoEntregaPadrao);

        AccountData accData;
        for (Account acc : [SELECT Id, Name, ExternalId__c, CNPJ__c, CPF__c, NumeroRegistro__c, CondicaoPagamento__c, CondicaoPagamento__r.Name, TabelaPrecos__c, TabelaPrecos__r.Name,
                            BillingStreet, BillingCity, GeraBoleto__c, BillingState, BillingCountry, BillingPostalCode, Saldo__c, GrauRisco__c,
                            TipoFrete__c, FormaPagamento__c, Observacoes__c, Bloqueado__c, EnderecoEntrega__c, EnderecoEntrega__r.Estado__c FROM Account WHERE Id =: accId]) {
            accData = new AccountData(acc, contactRelationId, contactId);
        }

        if (accData != null) {
            accData.hasPermissionERB = false;
            for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
                accData.hasPermissionERB = true;
            }
        }
        
        Boolean hasAlvara = false;
        Boolean validDate = true;
        
        for (DocumentosRegulatorios__c docReg : [SELECT Id, Name, DataVencimento__c FROM DocumentosRegulatorios__c WHERE Conta__c =: accId]) {
            if (docReg.Name.toLowerCase().contains('alvará')) {
                hasAlvara = true;                
                if (docReg.DataVencimento__c > Date.today()) {
                    system.debug('FORA DA DATA');
                    validDate = false;
                }
            }
        }

        if (hasAlvara && accData != null) {
            accData.ContemDocAlvaraCrt = true;
            accData.DocumentosValidos  = validDate ? true : false;
        } else if (accData != null){
            accData.ContemDocAlvaraCrt = false;
            accData.DocumentosValidos  = validDate ? true : false;
        }

        return accData;
    }

    @AuraEnabled(cacheable=true)
    public static String getB01Pricebook() {
        String pricebook2Id = null;
        for (Pricebook2 pricebook : [SELECT Id FROM Pricebook2 WHERE ExternalId__c = :'B01']) {
            pricebook2Id = pricebook.id;
        }
        System.debug('pricebook2Id: ' + pricebook2Id);
        return pricebook2Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getPricebookExternalId(String pricebookId) {
        String pricebookExternalId = null;
        for (Pricebook2 pricebook : [SELECT Id, ExternalId__c FROM Pricebook2 WHERE Id = :pricebookId]) {
            pricebookExternalId = pricebook.ExternalId__c;
        }
        return pricebookExternalId;
    }

    @AuraEnabled(cacheable=true)
    public static String getApprovedOrder(String ordId) {
        String msg = '';
        for (Order ord: [SELECT Id, Status FROM Order WHERE Id =: ordId ]) {
            if(ord.Status == 'Aprovado'){
                msg = 'Pedido não pode ser alterada esta aprovada ';
            }
        }
        return msg;
    }

    public static Boolean checkAnyFieldIsNull(Object field) {
        if(field == null) return true;
        else return false;
    }

    @AuraEnabled(cacheable=true)
    public static OrderData getOrderData(String ordId, String condicaoPag) {
        system.debug('entrou no apex getOrderData');
        Id accId;
        OrderData ordData;
        Map<Id, Order> mapOrdIdToOrder = new Map<Id, Order>();
        for (Order ord : [SELECT Id, AccountId, Pricebook2Id, Account.NumeroRegistro__c, Account.ExternalId__c, Account.CPF__c, Account.CNPJ__c, OrderNumber, Score__c, NomeMedico__c, CondicaoPagamento__r.Name,
                          NumeroPedidoCliente__c, CNPJ__c, CanalEntrada__c, CompartilhamentoRealizado__c, CondicaoPagamento__c, CriadoPor__c, DataCriacao__c, Account.Name, Pricebook2.Name, TotalAmount, Status,
                          DataEntrega__c, DataUltimaModificacao__c, EnderecoEntrega__c, Endereco_Entrega__c, ExternalId__c, GerarBoleto__c, InscricaoEstadual__c, Margem__c, CodigoLoja__c, Account.Bloqueado__c, RecomendacaoRespondida__c,
                          MensagemNF__c, ModificadoPor__c, NomePaciente__c, NumeroNotaFiscal__c, Origem__c, StatusIntegracao__c, TipoFrete__c, TipoOperacao__c, RecordType.DeveloperName, MargemAlvo__c, PedidoPendente__c, ObservacoesPedido__c,
                          ValorTotal__c, CPF__c, ClienteRecebedor__c, CodigoPedido__c, ContatoOrcamento__c, EnderecoRecebedor__c, FormaPagamento__c, ValorFrete__c, ClienteRecebedor__r.CNPJ__c, Type, DatasParcelas__c, Frete__c,
                          Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode, Account.Observacoes__c, Account.GeraBoleto__c, Account.Saldo__c, Account.GrauRisco__c,
                          ClienteRecebedor__r.BillingStreet, ClienteRecebedor__r.BillingCity, ClienteRecebedor__r.BillingState, ClienteRecebedor__r.BillingCountry, ClienteRecebedor__r.BillingPostalCode,Idportalcotacoes__c, CodigoIntegradora__c
                          FROM Order WHERE Id =: ordId]) {
            accId = ord.AccountId;
            ordData = new OrderData(ord);
            mapOrdIdToOrder.put(ord.Id, ord);
            if (ordData != null) {ordData.isVansOrder = ord.CodigoIntegradora__c != null ? true : false;}
        }

        if (ordData != null) {
            for (AccountContactRelation accountContact: [SELECT Id FROM AccountContactRelation WHERE AccountId =: ordData.ClienteEmissorId AND ContactId =: ordData.ContatoOrcamento]) {
                ordData.AccountContactRelationId = accountContact.Id;
            }
            ordData.hasPermissionERB = false;
            for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
                ordData.hasPermissionERB = true;
            }
        }
        
        User usuario = [SELECT CompanyName, UserRoleId FROM User WHERE Id =: UserInfo.getUserId() ];
        Group papel = new Group();
        papel = [SELECT RelatedId, DeveloperName FROM Group WHERE RelatedId =: usuario.UserRoleId limit 1];

        List<OrderItemData> ordItemDataList = new List<OrderItemData>();
        Set<String> setProductId = new Set<String>();
        Map<String, String> prodCatMap  = Utils.getPicklistApi(Product2.CategoriaComercial__c);
        for (OrderItem ordItem : [SELECT Id, Custo__c, Desconto__c,  CentroDistribuicao__c, CodigoProduto__c, ServiceDate, EndDate, Description, ForaMalha__c, ItemCampanha__c, 
                                        QuoteLineItemId, ItemContrato__c, OriginalOrderItemId, Lote__c, MargemAlvo__c, Margem__c, Vendedor__c, ScoreItem__c, CategoriaComercial__c,
                                        ExternalId__c, OrderId, ListPrice, PrecoTotal__c, TotalPrice, UnitPrice, Product2Id, Quantity, QuantidadeUn__c, ScoreBU__c, Laboratorio__c,
                                        AvailableQuantity, ScoreAlvo__c, ScoreAtual__c, TipoOperacao__c, ValidadeMinima__c, ValorCx__c, ValorUn__c, ScoreMix__c, ValorMalha__c,
                                        PricebookEntryId, Product2.Temperatura__c, Product2.CategoriaComercial__c, Product2.NumeroAnvisa__c, Imposto__c, Product2.tipoConversao__c,
                                        Product2.DescricaoTecnica__c, Product2.Fornecedor__r.Name, Product2.ProductCode, Product2.EANProduto__c, Product2.UnidadeMedida__c,
                                        Product2.FatorConversao__c, Product2.ProductCodeElfa__c, Product2.Name, Product2.Description, PricebookEntry.PrecoFabrica__c, TipoIntegradora__c,
                                        PricebookEntry.UnitPrice, cnpjCd__c, PosicaoItem__c, PosicaoInsercao__c, SequenciaOC__c, ValorSugerido__c, Range__c, BloqueadoRegionalizacao__c, CampanhaShelfLife__c, ProdutoCampanha__c, UnidadeMedidaPDF__c, Product2.SegundaUnidade__c, ObservacoesComercial__c
                                 FROM OrderItem WHERE OrderId = :ordId]) {

            Decimal price = ordItem.PricebookEntry.PrecoFabrica__c == null ? ordItem.PricebookEntry.UnitPrice : ordItem.PricebookEntry.PrecoFabrica__c;
            
            Decimal fatVal = checkAnyFieldIsNull(ordItem.Product2.FatorConversao__c) ? 0 : Decimal.valueOf(ordItem.Product2.FatorConversao__c) == 0 ? 1 : Decimal.valueOf(ordItem.Product2.FatorConversao__c);
             
            setProductId.add(ordItem.Product2Id);
            OrderItemData ordItemData = new OrderItemData();
            ordItemData.id                       = ordItem.PricebookEntryId + '_' + ordItem.cnpjCd__c;
            ordItemData.cdId                     = ordItem.cnpjCd__c + '_' + ordItem.Product2.ProductCode;
            ordItemData.itemId                   = ordItem.Id;
            ordItemData.pbEntryId                = ordItem.PricebookEntryId;
            ordItemData.prodId                   = ordItem.Product2Id;
            ordItemData.prodCode                 = ordItem.CodigoProduto__c;
            ordItemData.nome                     = ordItem.Product2.name;
            ordItemData.principioAtivo           = ordItem.Product2.Description;
            ordItemData.fabricante               = ordItem.Product2.Fornecedor__r.Name;
            ordItemData.anvisa                   = ordItem.Product2.NumeroAnvisa__c;
            ordItemData.unidadePrincipal         = ordItem.Product2.UnidadeMedida__c;
            ordItemData.unidadeSecundaria        = ordItem.Product2.SegundaUnidade__c;
            ordItemData.SequenciaOC              = ordItem.SequenciaOC__c;
            ordItemData.unidadeMedida            = ordItem.UnidadeMedidaPDF__c;
            ordItemData.unidadeMedidaSeg         = ordItem.Product2.SegundaUnidade__c;
            
            if(papel == null || papel.DeveloperName.contains('VendedorSuporte') || papel.DeveloperName.contains('VendedorExterno') || papel.DeveloperName.contains('VendedorInterno')){
                ordItemData.verMargem = false;
            }else{
                ordItemData.verMargem = true;
            }
            ordItemData.categoria                = ordItem.CategoriaComercial__c;
            ordItemData.precoFabricaCx           = String.valueOf(ordItem.ValorCx__c);
            if(ordItem.Product2.FatorConversao__c != null && ordItem.Product2.FatorConversao__c != '0' ){
                ordItemData.precoFabricaUn       = ordItem.ValorUn__c != null ? String.valueOf(ordItem.ValorUn__c / fatVal) : '0';
            }

            String freightValue = getCdFreight(mapOrdIdToOrder, ordId, ordItem.cnpjCd__c, false);

            ordItemData.precoTabelaCx            = String.valueOf(price);
            ordItemData.precoTabelaUn            = String.valueOf(price / fatVal);
            ordItemData.temperatura              = ordItem.Product2.Temperatura__c;
            ordItemData.ean                      = ordItem.Product2.EANProduto__c;
            // ordItemData.index                    = currentMalha[i].prioridade;
            ordItemData.cds                      = ordItem.CentroDistribuicao__c;
            ordItemData.cnpjCd                   = ordItem.cnpjCd__c;
            ordItemData.lote                     = ordItem.Lote__c;
            ordItemData.un                       = 'UN';
            ordItemData.quantidade               = ordItem.QuantidadeUn__c;
            ordItemData.quantidadeCx             = ordItem.Quantity;
            ordItemData.unitario                 = String.valueOf(ordItem.ValorCx__c / fatVal);
            ordItemData.caixa                    = String.valueOf(ordItem.ValorCx__c);
            ordItemData.inicialUnitario          = String.valueOf((ordItem.ValorSugerido__c != null && ordItem.ValorSugerido__c > 0) ? ordItem.ValorSugerido__c / fatVal : (ordItem.ValorMalha__c == null ? ordItem.ListPrice : ordItem.ValorMalha__c / fatVal));
            ordItemData.inicialCaixa             = String.valueOf((ordItem.ValorSugerido__c != null && ordItem.ValorSugerido__c > 0) ? ordItem.ValorSugerido__c / fatVal : (ordItem.ValorMalha__c == null ? ordItem.ListPrice : ordItem.ValorMalha__c));
            ordItemData.conversaoUnidadeCx       = String.valueOf(fatval);
            ordItemData.valorTotalUnd            = ordItem.ValorUn__c;
            ordItemData.valorTotalCx             = ordItem.ValorCx__c;
            ordItemData.valorTotal               = ordItem.PrecoTotal__c;
            ordItemData.valorFrete               = freightValue != 'undefined' ? (freightValue != '' ? Decimal.valueOf(freightValue) : 0) : 0;
            ordItemData.tipoFrete                = getCdFreight(mapOrdIdToOrder, ordId, ordItem.cnpjCd__c, true);
            ordItemData.aliquota                 = ordItem.Imposto__c;
            ordItemData.score                    = ordItem.ScoreAtual__c;
            ordItemData.custoCx                  = ordItem.Custo__c;
            ordItemData.desconto                 = ordItem.Desconto__c;
            ordItemData.margem                   = ordItem.Margem__c;
            ordItemData.margemAlvo               = ordItem.MargemAlvo__c;
            ordItemData.foraMalha                = ordItem.ForaMalha__c;
            ordItemData.score                    = ordItem.ScoreItem__c;
            ordItemData.scoreBU                  = ordItem.ScoreBU__c;
            ordItemData.scoreMix                 = ordItem.ScoreMix__c;
            ordItemData.scoreItem                = ordItem.ScoreItem__c;
            ordItemData.indexPosition            = ordItem.PosicaoItem__c;
            ordItemData.indexInsertPosition      = ordItem.PosicaoInsercao__c == null ? 0 : ordItem.PosicaoInsercao__c;
            ordItemData.validadeMinima           = ordItem.ValidadeMinima__c;
            ordItemData.precoMalha               = ordItem.ValorMalha__c;
            ordItemData.precoSugerido            = ordItem.ValorSugerido__c;
            ordItemData.rangeStringify           = ordItem.Range__c;
            ordItemData.laboratorio              = ordItem.Laboratorio__c;
            ordItemData.tipoIntegradora          = ordItem.TipoIntegradora__c;
            ordItemData.bloqRegionalizacao       = ordItem.BloqueadoRegionalizacao__c != null ? ordItem.BloqueadoRegionalizacao__c : false;
            ordItemData.isInCampaign             = ordItem.ProdutoCampanha__c != null ? ordItem.ProdutoCampanha__c : false;
            ordItemData.tipoConversao            = ordItem.Product2.tipoConversao__c;
            ordItemData.unidadeMedidaSeg         = ordItem.Product2.SegundaUnidade__c;
            ordItemData.unidadeMedida            = ordItem.UnidadeMedidaPDF__c;
            ordItemData.showBadgeOL              = false;
            ordItemData.showBadgeCampanha        = false;
            ordItemData.showBadgeCampanhaVendedor = false;
            ordItemData.showBadgeCampanhaCD      = false;
            ordItemData.showBadgeConsignado      = false;
            ordItemData.showBadgeAcordoComercial = false;
            ordItemData.showBadgeshelflife       = false;
            ordItemData.valorBloqueado           = false;
            ordItemData.showBadgeReservadoCNPJ   = false;
            ordItemData.observacaoComercial = ordItem.ObservacoesComercial__c;
            ordItemDataList.add(ordItemData);
        }
        Map<String, String> mapCdCodeToCNPJ = new Map<String, String>();
        List<listaCentroDistribuicao__c> listaCd = listaCentroDistribuicao__c.getall().values();
        for (listaCentroDistribuicao__c Cd : listaCd) {mapCdCodeToCNPJ.put(cd.CNPJCD__c, cd.CodigoCD__c);}
        map<String, ProductData> mapProd = new map<String, ProductData>();
        system.debug(accId);
        mapProd = getContractCampaign(setProductId, accId, condicaoPag == null ? ordData?.CondicaoPagamento : condicaoPag);
        for (OrderItemData oi : ordItemDataList) {
            if (mapProd.containsKey(oi.prodId)) {
                ProductData prodData = mapProd.get(oi.prodId);
                System.debug('prodData.showBadgeReservadoCNPJ ==> ' + prodData.showBadgeReservadoCNPJ);
                System.debug('prodData ==> ' + prodData);
               // if (oi.prodId == prodData.id) {
                    oi.showBadgeOL              = prodData.showBadgeOL;
                    oi.showBadgeCampanha        = prodData.showBadgeCampanha;
                    oi.showBadgeCampanhaVendedor = prodData.showBadgeCampanhaVendedor;
                    if (mapCdCodeToCNPJ.get(oi.cnpjCd) != null) {
                        if(prodData.showBadgeCampanha != null) {
                            oi.showBadgeCampanhaCD      = prodData.showBadgeCampanha ? prodData.cnpjCampanhaCd == null ? true : prodData.cnpjCampanhaCd.contains(mapCdCodeToCNPJ.get(oi.cnpjCd)) ? true : false : false;
                        } else {
                            oi.showBadgeCampanhaCD = false;
                        }
                    } else {
                        oi.showBadgeCampanhaCD = false;
                    }
                    System.debug('cnpjCd ==> ' + oi.cnpjCd);
                    System.debug('cnpjCd ==> ' + prodData.dataBadgeReservadoCNPJ);
                    if( prodData.dataBadgeReservadoCNPJ != null){
                        if(oi.cnpjCd != null ){
                            if(prodData.dataBadgeReservadoCNPJ.containsAny(oi.cnpjCd)){
                                oi.showBadgeReservadoCNPJ = true;
                            }
                        }
                    }

                    oi.showBadgeConsignado      = prodData.showBadgeConsignado;
                    oi.showBadgeAcordoComercial = prodData.showBadgeAcordoComercial;
                    oi.showBadgeshelflife       = prodData.showBadgeshelflife;
                    oi.precoCNPJCampanha        = prodData.precoCNPJCampanha;
                    oi.listTagByCd              = prodData.listTagByCd;
                    oi.valorBloqueado           = prodData.valorBloqueado;
                    oi.unidadeMedida            = prodData.unidadeMedida;
                    oi.unidadeMedidaSeg         = prodData.unidadeMedidaSeg;
            }
        }
        system.debug('ordItemDataList ' + ordItemDataList);

        if (ordData != null) {ordData.Itens = ordItemDataList;}
        
        Boolean hasAlvara = false;
        Boolean validDate = true;

        for (DocumentosRegulatorios__c docReg : [SELECT Id, Name, DataVencimento__c FROM DocumentosRegulatorios__c WHERE Conta__c =: accId]) {
            if (docReg.Name.toLowerCase().contains('alvará')) {
                hasAlvara = true;                
                if (docReg.DataVencimento__c > Date.today()) {
                    system.debug('FORA DA DATA');
                    validDate = false;
                }
            }
        }

        if (hasAlvara && ordData != null) {
            ordData.ContemDocAlvaraCrt = true;
            ordData.DocumentosValidos  = validDate ? true : false;
        } else if (ordData != null){
            ordData.ContemDocAlvaraCrt = false;
            ordData.DocumentosValidos  = validDate ? true : false;
        }

        return ordData;
    }

    public static String getCdFreight(Map<Id, Order> mapOrdIdToOrder, Id ordId, String cnpjCd, Boolean getType) {
        if (mapOrdIdToOrder.get(ordId).Frete__c != null) {
            List<String> listFreightByCd = mapOrdIdToOrder.get(ordId).Frete__c.split(',');
            for (String freightByCd : listFreightByCd) {
                List<String> splittedFreightCd = freightByCd.split(':');
                if (cnpjCd.trim() == splittedFreightCd[0].trim()) {
                    return getType ? (splittedFreightCd.size() == 3 ? splittedFreightCd[2] : '') : (splittedFreightCd.size() == 2 ? splittedFreightCd[1] : '');
                }
            }
        }
        return '';
    }
    
    @AuraEnabled(cacheable=true)
    public static MapIdToPaymentConditionName getFilteredPaymentConditionData() {
        system.debug('getFilteredPaymentConditionData');
        Map<Id, String> mapCondIdToCondName = new Map<Id, String>();
        for (CondicaoPagamento__c cond : [SELECT Id, Name FROM CondicaoPagamento__c LIMIT 10]) {
            mapCondIdToCondName.put(cond.Id, cond.Name);
        }
        system.debug(mapCondIdToCondName);
        return new MapIdToPaymentConditionName(mapCondIdToCondName);
    }

    // @AuraEnabled(cacheable=true)
    // public static PricebookData getFilteredListPricebookData() {
    //     UserInfo.getOrganizationName();
    //     Map<Id, String> mapPbIdToPricebook = new Map<Id, String>();
    //     for (Account acc : [SELECT Id, Name FROM Pricebook2 LIMIT 10]) { // Segmento, UF
    //         if (UserInfo.getOrganizationName() == 'Elfa') {

    //         } else if (UserInfo.getOrganizationName() == 'Atrial'){

    //         } else {
    //             mapPbIdToPricebook.put(acc.Id, acc.ExternalId__c);
    //         }
    //     }
    //     return new PricebookData(mapPbIdToPricebook);
    // }

    public static String getObjectNameFromRecId(String recordIdOrPrefix){
        String objectName = '';
        try{
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                 
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    //System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        } catch(Exception e) {
            System.debug(e);
        }
        return objectName;
    }

    public static Boolean getUserProfileInfo(Id userProfile) {        
        // System.debug('User Profile Id: ' + userProfile);
        // String profileName = [SELECT Id, Name from Profile WHERE Id =:userProfile].Name;

        // Boolean isComercial = profileName == 'Comercial' ? true : false;
        
        // return isComercial;
        return true;
    }    
    
    @AuraEnabled(cacheable=true)
    public static BudgetData getBudgetData(String recordId, String condicaoPag) {
        System.debug('RECORDID: ' + recordId);

        String objectName = getObjectNameFromRecId(recordId);

        Boolean isComercial = getUserProfileInfo(UserInfo.getProfileId());
        // User userRtv  = isComercial == true ? getUserRtv(UserInfo.getUserId()) : null;

        User usuario = [SELECT CompanyName, UserRoleId FROM User WHERE Id =: UserInfo.getUserId() ];
        Group papel = new Group();
        papel = [SELECT RelatedId, DeveloperName FROM Group WHERE RelatedId =: usuario.UserRoleId limit 1];

        BudgetData data;
        
        Id accId;
        
        for (Opportunity opp : [SELECT Id, StageName, MotivoCancelamento__c, AccountId, Account.Name, Account.ExternalId__c, Account.TipoCliente__c, Account.TabelaPrecos__c, Account.TabelaPrecos__r.Name, Account.CondicaoPagamento__c, Account.CondicaoPagamento__r.name, CanalEntrada__c, CanalVendas__c, CNPJ__c, Score__c, Pricebook2Id, CloseDate, DatasParcelas__c, Frete__c,
        ContatoOrcamento__c, CPF__c, FormaPagamento__c, Margem__c, Observacoes__c, ObservacoesCliente__c, PrazoValidade__c, Amount, NumeroOrcamento__c, CondicaoPagamento__c, CondicaoPagamento__r.Name, Account.Observacoes__c, Account.Bloqueado__c, Pricebook2.Name, Account.Saldo__c, Account.GrauRisco__c, RecomendacaoRespondida__c,
        Account.BillingStreet, Account.BillingCity,Account.GeraBoleto__c, Account.BillingState, Idportalcotacoes__c, Account.BillingCountry, Account.BillingPostalCode, MargemAlvo__c, description
        FROM Opportunity WHERE Id =: recordId]) {
            accId = opp.AccountId;
            data = new BudgetData(opp, null);
        }

        List<BudgetItemData> oLineItemDataList = new List<BudgetItemData>();
        Set<String> setProductId = new Set<String>();
        Map<String, String> prodCatMap  = Utils.getPicklistApi(Product2.CategoriaComercial__c);
        
        for (OpportunityLineItem oLineItem : [SELECT Id, Custo__c, CategoriaComercial__c, CentroDistribuicao__c, ProductCode, ServiceDate, Discount, Description, cnpjCd__c,
                                                    ForaMalha__c, Fornecedor__c, ItemCampanha__c, JustificativaDesconto__c, Lote__c, MargemAlvo__c, MargemAtual__c,
                                                    Name, NumeroAnvisa__c, OpportunityId, ListPrice, UnitPrice, TotalPrice, PrincipioAtivo__c, Product2Id, Quantity,
                                                    QuantidadeUn__c, ScoreAlvo__c, ScoreAtual__c, Subtotal, Temperatura__c, ValidadeMinima__c, ValorCx__c, ValorUn__c,
                                                    ValorTotal__c, Vendedor__c, PricebookEntryId, Product2.Temperatura__c, Product2.CategoriaComercial__c, Imposto__c, ValorSugerido__c, Range__c,
                                                    Product2.NumeroAnvisa__c, Product2.DescricaoTecnica__c, Product2.Fornecedor__r.Name, Product2.ProductCode, ValorMalha__c, BloqueadoRegionalizacao__c, ProdutoCampanha__c,
                                                    Product2.EANProduto__c, Product2.FatorConversao__c, Product2.ProductCodeElfa__c, Product2.Name, Product2.UnidadeMedida__c, SequenciaOC__c,
                                                    Product2.Description, PricebookEntry.PrecoFabrica__c, PricebookEntry.UnitPrice, ScoreBU__c, ScoreMix__c, ScoreItem__c, PosicaoItem__c, PosicaoInsercao__c, UnidadeMedidaPDF__c, Product2.SegundaUnidade__c, ObservacoesComercial__c
                                            FROM OpportunityLineItem WHERE OpportunityId = :recordId]) {
            
            Decimal price = oLineItem.PricebookEntry.PrecoFabrica__c == null ? oLineItem.PricebookEntry.UnitPrice : oLineItem.PricebookEntry.PrecoFabrica__c;
            Decimal fatVal = checkAnyFieldIsNull(oLineItem.Product2.FatorConversao__c) ? 0 : Decimal.valueOf(oLineItem.Product2.FatorConversao__c) == 0 ? 1 : Decimal.valueOf(oLineItem.Product2.FatorConversao__c); 
            
            setProductId.add(oLineItem.Product2Id);
            BudgetItemData oLineItemData = new BudgetItemData();
            oLineItemData.id                       = oLineItem.PricebookEntryId + '_' + oLineItem.cnpjCd__c;
            oLineItemData.cdId                     = oLineItem.cnpjCd__c + '_' + oLineItem.ProductCode;
            oLineItemData.itemId                   = oLineItem.Id;
            oLineItemData.pbEntryId                = oLineItem.PricebookEntryId;
            oLineItemData.prodId                   = oLineItem.Product2Id;
            oLineItemData.prodCode                 = oLineItem.Product2.ProductCode;
            oLineItemData.nome                     = oLineItem.Product2.name;
            oLineItemData.principioAtivo           = oLineItem.PrincipioAtivo__c;
            oLineItemData.fabricante               = oLineItem.Product2.Fornecedor__r.Name;
            oLineItemData.anvisa                   = oLineItem.Product2.NumeroAnvisa__c;
            oLineItemData.categoria                = oLineItem.CategoriaComercial__c;
            oLineItemData.precoFabricaCx           = String.valueOf(oLineItem.ValorCx__c);
            oLineItemData.precoFabricaUn           = String.valueOf(oLineItem.ValorCx__c / fatVal);
            oLineItemData.precoTabelaCx            = String.valueOf(price);
            oLineItemData.precoTabelaUn            = String.valueOf(price / fatVal);
            oLineItemData.temperatura              = oLineItem.Product2.Temperatura__c;
            oLineItemData.ean                      = oLineItem.Product2.EANProduto__c;
            oLineItemData.unidadeMedida            = oLineItem.UnidadeMedidaPDF__c;
            oLineItemData.unidadeMedidaSeg         = oLineItem.Product2.SegundaUnidade__c;
            oLineItemData.unidadePrincipal         = oLineItem.Product2.UnidadeMedida__c;
            oLineItemData.unidadeSecundaria        = oLineItem.Product2.SegundaUnidade__c;
            if(papel == null || papel.DeveloperName.contains('VendedorSuporte') || papel.DeveloperName.contains('VendedorExterno')){oLineItemData.verMargem = false;
            }else{oLineItemData.verMargem = true;}
            // oLineItemData.index                    = currentMalha[i].prioridade;
            oLineItemData.cds                      = oLineItem.CentroDistribuicao__c;
            oLineItemData.cnpjCd                   = oLineItem.cnpjCd__c;
            oLineItemData.lote                     = oLineItem.Lote__c;
            oLineItemData.un                       = 'UN';
            oLineItemData.quantidade               = oLineItem.QuantidadeUn__c;
            oLineItemData.quantidadeCx             = oLineItem.Quantity;
            oLineItemData.desconto                 = oLineItem.Discount;
            oLineItemData.unitario                 = String.valueOf(oLineItem.ValorCx__c / fatVal);
            oLineItemData.caixa                    = String.valueOf(oLineItem.ValorCx__c);
            oLineItemData.inicialUnitario          = String.valueOf((oLineItem.ValorSugerido__c != null && oLineItem.ValorSugerido__c > 0) ? oLineItem.ValorSugerido__c / fatVal : ((oLineItem.ValorMalha__c == null ? oLineItem.listPrice : oLineItem.ValorMalha__c) / fatVal));
            oLineItemData.inicialCaixa             = String.valueOf((oLineItem.ValorSugerido__c != null && oLineItem.ValorSugerido__c > 0) ? oLineItem.ValorSugerido__c / fatVal : ((oLineItem.ValorMalha__c == null ? oLineItem.listPrice : oLineItem.ValorMalha__c)));
            oLineItemData.conversaoUnidadeCx       = String.valueOf(fatVal);
            oLineItemData.valorTotalUnd            = oLineItem.ValorUn__c;
            oLineItemData.valorTotalCx             = oLineItem.ValorCx__c;
            oLineItemData.valorTotal               = oLineItem.ValorTotal__c;
            oLineItemData.aliquota                 = oLineItem.Imposto__c;
            oLineItemData.score                    = oLineItem.ScoreItem__c;
            oLineItemData.scoreBU                  = oLineItem.ScoreBU__c;
            oLineItemData.scoreMix                 = oLineItem.ScoreMix__c;
            oLineItemData.scoreItem                = oLineItem.ScoreItem__c;
            oLineItemData.indexPosition            = oLineItem.PosicaoItem__c;
            oLineItemData.indexInsertPosition      = oLineItem.PosicaoInsercao__c == null ? 0 : oLineItem.PosicaoInsercao__c;
            oLineItemData.custoCx                  = oLineItem.Custo__c;
            oLineItemData.margem                   = oLineItem.MargemAtual__c;
            oLineItemData.margemAlvo               = oLineItem.MargemAlvo__c;
            oLineItemData.foraMalha                = oLineItem.ForaMalha__c;
            oLineItemData.precoMalha               = oLineItem.ValorMalha__c;
            oLineItemData.precoSugerido            = oLineItem.ValorSugerido__c;
            oLineItemData.rangeStringify           = oLineItem.Range__c;
            oLineItemData.bloqRegionalizacao       = oLineItem.BloqueadoRegionalizacao__c != null ? oLineItem.BloqueadoRegionalizacao__c : false;
            oLineItemData.isInCampaign             = oLineItem.ProdutoCampanha__c != null ? oLineItem.ProdutoCampanha__c : false;
            oLineItemData.validadeMinima           = oLineItem.ValidadeMinima__c;
            oLineItemData.SequenciaOC              = oLineItem.SequenciaOC__c;
            oLineItemData.showBadgeOL              = false;
            oLineItemData.showBadgeCampanha        = false;
            oLineItemData.showBadgeCampanhaVendedor = false;
            oLineItemData.showBadgeCampanhaCD      = false;
            oLineItemData.showBadgeConsignado      = false;
            oLineItemData.showBadgeAcordoComercial = false;
            oLineItemData.showBadgeshelflife       = false;
            oLineItemData.valorBloqueado           = false;
            oLineItemData.unidadeSecundaria        = oLineItem.Product2.SegundaUnidade__c;
            oLineItemData.observacaoComercial = oLineItem.ObservacoesComercial__c;
            oLineItemDataList.add(oLineItemData);
        }
        Map<String, String> mapCdCodeToCNPJ = new Map<String, String>();
        List<listaCentroDistribuicao__c> listaCd = listaCentroDistribuicao__c.getall().values();
        for (listaCentroDistribuicao__c Cd : listaCd) {
            mapCdCodeToCNPJ.put(cd.CNPJCD__c, cd.CodigoCD__c);
        }
        map<String, ProductData> mapProd = new map<String, ProductData>();
        mapProd = getContractCampaign(setProductId, accId, condicaoPag == null ? data?.CondicaoPagamento : condicaoPag);
        for (BudgetItemData oi : oLineItemDataList) {
            if (mapProd.containsKey(oi.prodId)) {
                ProductData prodData = mapProd.get(oi.prodId);
                if (oi.prodId == prodData.id) {
                    oi.showBadgeOL              = prodData.showBadgeOL;
                    oi.showBadgeCampanha        = prodData.showBadgeCampanha;
                    oi.showBadgeCampanhaVendedor = prodData.showBadgeCampanhaVendedor;
                    oi.showBadgeCampanhaCD      = prodData.showBadgeCampanha ? prodData.cnpjCampanhaCd == null ? true : prodData.cnpjCampanhaCd.contains(mapCdCodeToCNPJ.get(oi.cnpjCd)) ? true : false : false;
                    oi.showBadgeConsignado      = prodData.showBadgeConsignado;
                    oi.showBadgeAcordoComercial = prodData.showBadgeAcordoComercial;
                    oi.showBadgeshelflife       = prodData.showBadgeshelflife;
                    oi.precoCNPJCampanha        = prodData.precoCNPJCampanha;
                    oi.listTagByCd              = prodData.listTagByCd;
                    oi.valorBloqueado           = prodData.valorBloqueado;
                    oi.unidadeMedida            = prodData.unidadeMedida;
                    oi.unidadeMedidaSeg         = prodData.unidadeMedidaSeg;
                }
            }
        }

        if (data != null) { data.Itens = oLineItemDataList;}
        
        for (Account acc : [SELECT Id, Name, ExternalId__c, TipoCliente__c, GeraBoleto__c, TabelaPrecos__c, TabelaPrecos__r.Name, CNPJ__c, CPF__c, CondicaoPagamento__c, CondicaoPagamento__r.Name, FormaPagamento__c, Observacoes__c, Bloqueado__c, Saldo__c, GrauRisco__c FROM Account WHERE Id =: recordId]) {
            accId = acc.Id;
            data = new BudgetData(null, acc);
        }
        
        Boolean hasAlvara = false;
        Boolean validDate = true;

        for (DocumentosRegulatorios__c docReg : [SELECT Id, Name, DataVencimento__c FROM DocumentosRegulatorios__c WHERE Conta__c =: accId]) {
            if (docReg.Name.toLowerCase().contains('alvará')) {
                hasAlvara = true;                
                if (docReg.DataVencimento__c > Date.today()) {
                    system.debug('FORA DA DATA');
                    validDate = false;
                }
            }
        }

        if (hasAlvara && data != null) {
            data.ContemDocAlvaraCrt = true;
            data.DocumentosValidos  = validDate ? true : false;
        } else if (data != null) {
            data.ContemDocAlvaraCrt = false;
            data.DocumentosValidos  = validDate ? true : false;
        }
        
        Id contatoPadrao;
        Id contactRelationId;
        if (data != null && objectName == 'Account') {
            System.debug('Contato Criação');
            for (Contact con : [SELECT Id FROM Contact WHERE AccountId =: accId AND Padrao__c = true]) {
                contatoPadrao = con.Id;
            }
            for (AccountContactRelation contactRelation : [SELECT Id FROM AccountContactRelation WHERE AccountId =: accId AND ContactId =: contatoPadrao]) {
                contactRelationId = contactRelation.Id;
            }
            
            data.ContatoOrcamento = contatoPadrao;
            data.AccountContactRelationId = contactRelationId;

            data.hasPermissionERB = false;
            for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
                data.hasPermissionERB = true;
            }
        }
        else if (data != null && objectName == 'Opportunity') {
            System.debug('Contato Edição');
            for (Contact con : [SELECT Id FROM Contact WHERE Id =: data.ContatoOrcamento]) {
                contatoPadrao = con.Id;
            }
            for (AccountContactRelation contactRelation : [SELECT Id FROM AccountContactRelation WHERE AccountId =: accId AND ContactId =: contatoPadrao]) {
                contactRelationId = contactRelation.Id;
            }
            
            data.ContatoOrcamento = contatoPadrao;
            data.AccountContactRelationId = contactRelationId;
            System.debug('AccountContactRelationId: ' + data.AccountContactRelationId);
            data.hasPermissionERB = false;
            for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
                data.hasPermissionERB = true;
            }
        }

        return data;
    }

    @AuraEnabled
    public static String setInputExpiredReason(String recordId, String reason) {
        try{
            update new Opportunity(Id=recordId, MotivoCancelamento__c=reason);
            return 'Success!';
        }catch(Exception ex){
            return ex.getMessage()+', '+ex.getStackTraceString();
        }
    }

    @AuraEnabled(cacheable=true)
    public static ToastInfoData getToastInfoData() {
        system.debug('entrou no apex getOrderData');

        ToastInfoData tfData = new ToastInfoData();

        return tfData;
    }

    @AuraEnabled(cacheable=true)
    public static CurrentAccountData getSelectedAccountInfo(String recordId) {
        CurrentAccountData cAccData;
        Boolean isBlocked = false;
        system.debug('getSelectedAccountInfo: ' + recordId);
        for (Account acc : [SELECT Id, Bloqueado__c, CNPJ__c, CPF__c, ExternalId__c, NumeroRegistro__c FROM Account WHERE Id=: recordId]) {
            cAccData = new CurrentAccountData(acc);
        }

        return cAccData;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Object> getMalha(String clienteCGC, String productCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha) {        
        return getMalhaApi('InformaticaGetMalha', clienteCGC, null, productCode, calcMargem, pricebookExternalId, condPagamento, isForaMalha);
    }

    @AuraEnabled(cacheable=false)
    public static List<Object> getFirstMalha(String clienteCGC, String productCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha) {        
        return getFirstMalhaApi('InformaticaGetMalha', clienteCGC, null, productCode, calcMargem, pricebookExternalId, condPagamento, isForaMalha);
    }

    @AuraEnabled(cacheable=true)
    public static List<Object> getMalhaPortal(String clienteCGC, String UF, String productCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha) {        
        List<Object> lObj = new List<Object>();
        lObj = getMalhaApi('InformaticaGetMalhaPortal', clienteCGC, UF, productCode, calcMargem, pricebookExternalId, condPagamento, isForaMalha);
        // if(lObj.isEmpty()) lObj =  getMalhaApi('', UF, productCode, calcMargem, pricebookExternalId, condPagamento, isForaMalha);
        return lObj;
    }

    @AuraEnabled(cacheable=false)
    public static List<Object> getMalhaApi(String endpointConfig, String clienteCGC, String UF, String productCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha) {        

        Integracoes__c infoMalhaAPI = Integracoes__c.getValues(endpointConfig);

        Map<String, Object> mapResponse    = new Map<String, Object>();
        Map<String, Object> mapResponseCds = new Map<String, Object>();
        List<Object> listMalha             = new List<Object>();
        List<Object> listMalhaToCalcScore  = new List<Object>();
        
        String method      = infoMalhaAPI.Method__c;
        String endpoint    = infoMalhaAPI.Endpoint__c;
        // String accessToken = IntegrationUtils.getTotvsAccessToken();

        system.debug(method);
        system.debug(endpoint);
        // system.debug('TOTVS token: ' + accessToken);
        
        Blob headerValue = Blob.valueOf(infoMalhaAPI.User__c + ':' + infoMalhaAPI.Password__c);

        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');
        req.setTimeout(120000);
        
        List<ProductCode> listProducts = new List<ProductCode>();

        system.debug(productCode);

        List<String> listProd = productCode.split(',');

        for (String prod : listProd) {
            listProducts.add(new ProductCode(prod.trim()));
        }

        system.debug(condPagamento);
        List<CondicaoPagamento__c> listCondPag = [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id =: condPagamento];
        system.debug(listCondPag);

        MalhaRequest malhaData = new MalhaRequest(clienteCGC, UF, null, listProducts, calcMargem, pricebookExternalId,listCondPag.size() == 1 ? listCondPag[0].ExternalId__c : null, isForaMalha, true);

        system.debug('malhaReq: ' + malhaData);

        String body;
        body = Json.serializePretty(malhaData);
        system.debug(body);

        String resultString = '';

        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            system.debug(resp);
            system.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            system.debug('resp'+resultString);            
            
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201 || resp.getStatusCode() == 404){
                resultString = resp.getBody();
                system.debug(resultString);

                mapResponse = (Map<String, Object>) JSON.deserializeUntyped(resultString);
                listMalha   = (List<Object>) mapResponse.get('output') != null ? (List<Object>) mapResponse.get('output') : new List<Object>{(Object) JSON.deserializeUntyped(resp.getBody())};
                system.debug('listMalha: ' + listMalha);
            } else {
                listMalha = null;
                resultString = resp.getBody();
                system.debug(resultString);
            }
        } catch (Exception e) {
            listMalha = null;
            resultString = e.getMessage(); 
            system.debug(e.getMessage());
        }
        return listMalha != null ? listMalha : null;
    }

    @AuraEnabled(cacheable=false)
    public static List<ResponseFirstMalha> getFirstMalhaApi(String endpointConfig, String clienteCGC, String UF, String productCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha) {        

        Integracoes__c infoMalhaAPI = Integracoes__c.getValues(endpointConfig);

        Map<String, Object> mapResponse    = new Map<String, Object>();
        Map<String, Object> mapResponseCds = new Map<String, Object>();
        List<Object> listMalha             = new List<Object>();
        List<Object> listMalhaToCalcScore  = new List<Object>();
        Map<String, Object> mapResponseCdsProduct = new Map<String, Object>();

        List<ResponseFirstMalha> responseFirstMalhaLst = new List<ResponseFirstMalha>();
        
        String method      = infoMalhaAPI.Method__c;
        String endpoint    = infoMalhaAPI.Endpoint__c;
        
        Blob headerValue = Blob.valueOf(infoMalhaAPI.User__c + ':' + infoMalhaAPI.Password__c);

        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');
        req.setTimeout(120000);
        
        List<ProductCode> listProducts = new List<ProductCode>();

        List<String> listProd = productCode.split(',');

        for (String prod : listProd) {
            listProducts.add(new ProductCode(prod.trim()));
        }

        List<CondicaoPagamento__c> listCondPag = [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id =: condPagamento];

        MalhaRequest malhaData = new MalhaRequest(clienteCGC, 
                                                    '', 
                                                    null, 
                                                    listProducts, 
                                                    false, 
                                                    '',
                                                    listCondPag.size() == 1 ? listCondPag[0].ExternalId__c : null, 
                                                    isForaMalha, 
                                                    false);

        String body;
        body = Json.serializePretty(malhaData);

        String resultString = '';

        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            system.debug(resp);
            system.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            system.debug('resp'+resultString);            
            
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201 || resp.getStatusCode() == 404){
                resultString = resp.getBody();
                system.debug(resultString);

                Map<String,String> productCodeCdMap = new Map<String,String>();

                JsonParser result = (JsonParser) JSON.deserialize(resp.getBody(), JsonParser.class);
                for(output output : result.output){

                    if(output.codprotheus != null){
                        for(cds cds : output.cds){
                            if(cds.prioridade == '1'){
                                productCodeCdMap.put(output.codprotheus, cds.filial);
                            }
                        }
                    }
                    
                }

                Map<String, Decimal> estoqueMap = new  Map<String, Decimal>();                            
                for(Estoque__c estoque : [SELECT Id, NomeProduto__c, Saldo__c, Armazem__c, NomeProduto__r.ProductCode, CNPJCD__c, NomeCD__c 
                                            FROM Estoque__c 
                                            WHERE NomeProduto__r.ProductCode IN :productCodeCdMap.keyset() 
                                            AND NomeCD__c IN : productCodeCdMap.values()]){
                    estoqueMap.put(estoque.NomeProduto__r.ProductCode, estoque.Saldo__c);
                }

                Map<String, Decimal> pricebookEntryMap = new  Map<String, Decimal>();
                for(PricebookEntry pb : [SELECT id, UnitPrice, ProductCode 
                                            FROM PricebookEntry 
                                            WHERE Pricebook2Id =: pricebookExternalId 
                                            AND ProductCode IN :productCodeCdMap.keyset()]){
                    pricebookEntryMap.put(pb.ProductCode, pb.UnitPrice);
                }
                
                for(String prdCode: productCodeCdMap.keySet()){                   
                    ResponseFirstMalha responseFirstMalha = new ResponseFirstMalha();
                    responseFirstMalha.productCode = prdCode;
                    responseFirstMalha.filial = productCodeCdMap.get(prdCode);
                    responseFirstMalha.estoque = estoqueMap.get(prdCode) != null ? estoqueMap.get(prdCode) : 0;
                    responseFirstMalha.foundEstoque = estoqueMap.get(prdCode) != null ? true : false;
                    responseFirstMalha.unitPrice = pricebookEntryMap.get(prdCode);
                    responseFirstMalhaLst.add(responseFirstMalha);
                }

            } else {
                responseFirstMalhaLst = null;
                resultString = resp.getBody();
                system.debug(resultString);
            }
        } catch (Exception e) {
            responseFirstMalhaLst = null;
            resultString = e.getMessage(); 
            system.debug(e.getMessage());
        }
        return responseFirstMalhaLst != null ? responseFirstMalhaLst : null;
    }

    public class JsonParser{
		public list<output> output{get;set;}
    }
	public class output{
        public String codprotheus{get;set;}
		public list<cds> cds{get;set;}
	}
	public class cds{
		public String filial{get;set;}
		public String cd{get;set;}
		public String cnpj{get;set;}
		public String prioridade{get;set;}
	}

    public class ResponseFirstMalha{
		@AuraEnabled public String productCode {get;set;}
        @AuraEnabled public String cnpjCd {get;set;}
        @AuraEnabled public Decimal unitPrice {get;set;}
        @AuraEnabled public Decimal estoque {get;set;}
        @AuraEnabled public Boolean foundEstoque {get;set;}        
        @AuraEnabled public String filial {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<Object> getLotes(String clienteCGC, String productCode) {
		Integracoes__c infoLotesAPI = Integracoes__c.getValues('InformaticaConsultaLotes');

        Map<String, Object> mapResponse  = new Map<String, Object>();
        List<Object> listLote            = new List<Object>();
        
        String method      = infoLotesAPI.Method__c;
        String endpoint    = infoLotesAPI.Endpoint__c;
        // String accessToken = IntegrationUtils.getTotvsAccessToken();

        system.debug(method);
        system.debug(endpoint);
        // system.debug('TOTVS token: ' + accessToken);
        
        Blob headerValue = Blob.valueOf(infoLotesAPI.User__c + ':' + infoLotesAPI.Password__c);

        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');
        req.setTimeout(120000);

        LoteRequest loteData = new LoteRequest(clienteCGC, productCode);

        System.debug('LoteReq: ' + loteData);

        String body;
        body = Json.serializePretty(loteData);
        System.debug(body);

        String resultString = '';        

        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            System.debug(resp);
            System.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            System.debug('resp'+resultString);            
            
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){        
                resultString = resp.getBody();
                System.debug(resultString);
                mapResponse = (Map<String, Object>) JSON.deserializeUntyped(resultString);
                listLote   = (List<Object>) mapResponse.get('estoque');
            } else {
                resultString = resp.getBody();
                System.debug(resultString);
            }
        } catch (Exception e) {
            resultString = e.getMessage(); 
            System.debug(e.getMessage());
        }

        return !listLote.isEmpty() ? listLote : null;
    }

    @AuraEnabled
    public static String generateBudget(String budget, String headerInfo, Boolean sendToApproval, Boolean hasComplementOrder) {
        system.debug(budget);
        system.debug(headerInfo);

        List<Object> listObjBudget;

        listObjBudget = (List<Object>) JSON.deserializeUntyped(budget); 
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);

        system.debug(mapObjHeader);
        system.debug('valorTotal: '        + mapObjHeader.get('valorTotal'));
        system.debug('score: '             + mapObjHeader.get('score'));
        system.debug('clienteEmissorId: '  + mapObjHeader.get('clienteEmissorId'));
        system.debug('tabelaPreco: '       + mapObjHeader.get('tabelaPreco'));
        system.debug('canalEntrada: '      + mapObjHeader.get('canalEntrada'));
        system.debug('condicaoPagamento: ' + mapObjHeader.get('condicaoPagamento'));
        system.debug('formaPagamento: '    + mapObjHeader.get('formaPagamento'));
        system.debug('contatoOrcamento: '  + mapObjHeader.get('contatoOrcamento'));
        system.debug('prazoValidade: '     + mapObjHeader.get('prazoValidade'));
        system.debug('dtValidade: '        + mapObjHeader.get('dtValidade'));
        system.debug('observacaoCliente: ' + mapObjHeader.get('observacaoCliente'));
        system.debug('observacao: '        + mapObjHeader.get('observacao'));

        Opportunity opp = fillOppHeader(mapObjHeader, false, null);
        if (hasComplementOrder) {
            opp.StageName = 'Fechado/Gerado';
        }

        insert opp;  
        
        Id oppId = opp.Id;

        system.debug('Opp id: ' + oppId);

        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjBudget);  
        
        List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>();        
        List<OpportunityLineItem> listOppLineItemUpdate = new List<OpportunityLineItem>();        
        
        for (Object obj: listObjBudget) {            
            Map<String, Object> mapOppLineItem = (Map<String, Object>) (obj);
            system.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);
            
            OpportunityLineItem oppLineItem = fillOppLineItemObj(mapOppLineItem, oppId, setMap, prodMap);
            if(oppLineItem.Id == null)
                listOppLineItem.add(oppLineItem);
            else
                listOppLineItemUpdate.add(oppLineItem);
        }

        if (!listOppLineItem.isEmpty()) {
            insert listOppLineItem;
            // insertUserShare(listOppLineItem);
        }       
        if (!listOppLineItemUpdate.isEmpty()) {
            insert listOppLineItemUpdate;
            // insertUserShare(listOppLineItemUpdate);
        }            

        if (sendToApproval) {
            Opportunity updateOpp = new Opportunity();
            updateOpp.id = oppId;
            updateOpp.EnviarAprovacao__c = sendToApproval;

            update updateOpp;
        }

        return oppId;
    }

    @AuraEnabled
    public static Boolean getCanEditPrice(String ordId){
        for (Order ord : [SELECT Id, Inconsistencias__c, RecordTypeId, CodigoIntegradora__c, Status FROM Order WHERE Id =: ordId]) {
            if (ord.Inconsistencias__c == null && ord.RecordTypeId == MOTHERORDER_RECORDTYPE && ord.CodigoIntegradora__c != null && 
                ord.Status != 'Cancelado' && ord.Status != 'Reprovado' && ord.Status != 'Aprovado') {
                return true;
            }
        }
        return false;
    }

    @AuraEnabled
    public static Boolean getComplementOrderSituation(String ordId){
        for (Order ord : [SELECT Id, OrderNumber, PedidoPendente__c, ComplementoPedido__c, ComplementoPedido__r.Status, ComplementoPedido__r.StatusIntegracao__c, ComplementoPedido__r.ExternalId__c FROM Order WHERE Id =: ordId AND ComplementoPedido__c != null AND PedidoPendente__c = true]) {
            if (ord.ComplementoPedido__r.ExternalId__c == null) {
                return true;
            }
        }
        return false;
    }

    @AuraEnabled
    public static String generateComplementOrder(String complementOrder, String headerInfo, Boolean sendToApproval, String complementOrdId) {   
        system.debug('generateComplementOrder');     
        List<Object> listObjComplementOrder;

        system.debug(complementOrder);

        listObjComplementOrder = (List<Object>) JSON.deserializeUntyped(complementOrder);
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);

        system.debug(listObjComplementOrder);

        Order ord = fillOrderHeader(mapObjHeader, false, null);

        ord.Status = 'Em digitação';
        ord.PedidoPendente__c = true;
        ord.ComplementoPedido__c = complementOrdId;

        system.debug(JSON.serializePretty(ord));

        insert ord;

        Id ordId = ord.Id;

        system.debug('Order id: ' + ordId);
        
        List<OrderItem> listOrderItem = new List<OrderItem>();
        
        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjComplementOrder);
        for (Object obj: listObjComplementOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            system.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);
            OrderItem ordItem = fillOrderItemObj(mapOrdItem, ordId, setMap, prodMap);
            ordItem.Id = null;
            ordItem.ItemPendente__c = mapOrdItem.get('manterPendente') != null ? Boolean.valueOf(mapOrdItem.get('manterPendente')) : false;
            listOrderItem.add(ordItem);
        }

        system.debug(JSON.serializePretty(listOrderItem));
        if (!listOrderItem.isEmpty()) {
            insert listOrderItem;

            //W6884 - insert SolicitacaoCompras__c and update OrderItem

            listOrderItem = [SELECT Id, CNPJCD__c FROM OrderItem WHERE OrderId = :ordId];
            Map<String, List<Id>> cnpjCdToItemMap = new Map<String, List<Id>>();
            for (OrderItem oi : listOrderItem) {
                if (!cnpjCdToItemMap.containsKey(oi.CNPJCD__c)) {
                    cnpjCdToItemMap.put(oi.CNPJCD__c, new List<Id>());
                }
                cnpjCdToItemMap.get(oi.CNPJCD__c).add(oi.Id);
            }

            List<SolicitacaoCompras__c> solicComprasList = new List<SolicitacaoCompras__c>();
            for (String cnpjCd : cnpjCdToItemMap.keySet()) {
                SolicitacaoCompras__c solicCompras = new SolicitacaoCompras__c(
                    Pedido__c = ordId,
                    CNPJCD__c = cnpjCd
                );
                solicComprasList.add(solicCompras);
            }
            insert solicComprasList;

            List<Id> solicComprasIdList = Collection.of(solicComprasList).pluckIds();

            List<OrderItem> ordItemList = new List<OrderItem>();
            for (SolicitacaoCompras__c solic : [SELECT Id, CNPJCD__c FROM SolicitacaoCompras__c WHERE Id IN :solicComprasIdList]) {
                for (Id oiId : cnpjCdToItemMap.get(solic.CNPJCD__c)) {
                    OrderItem ordItem = new OrderItem(
                        Id                    = oiId,
                        SolicitacaoCompras__c = solic.Id
                    );
                    ordItemList.add(ordItem);
                }
            }
            OrderHandler.disableTrigger();
            update ordItemList;
            OrderHandler.enableTrigger();

            
            if (!solicComprasIdList.isEmpty()) {     
                System.enqueueJob(new IntegrationPurchaseReqQueueable(0, new List<Id>(solicComprasIdList)));     
            }
        }

        SendEmailMessage.emailMessage(ord);

        return ord.Id;
    }

    @AuraEnabled
    public static String generateOrder(String jsonOrder, String headerInfo, Boolean sendToApproval, Boolean keepComplementOrder, String oppId, Boolean isAutomaticSave) {
        system.debug(jsonOrder);
        system.debug(headerInfo);

        List<Object> listObjOrder;

        listObjOrder = (List<Object>) JSON.deserializeUntyped(jsonOrder); 
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);

        system.debug('CABEÇALHO DESERIALIZADO: ' + mapObjHeader);
        system.debug('clienteEmissor: '            + mapObjHeader.get('clienteEmissor'));
        system.debug('clienteEmissorId: '          + mapObjHeader.get('clienteEmissorId'));
        system.debug('clienteEmissorCGC: '         + mapObjHeader.get('clienteEmissorCGC'));
        system.debug('medico: '                    + mapObjHeader.get('medico'));
        system.debug('medicoId: '                  + mapObjHeader.get('medicoId'));
        system.debug('medicoCRM: '                 + mapObjHeader.get('medicoCRM'));
        system.debug('tabelaPreco: '               + mapObjHeader.get('tabelaPreco'));
        system.debug('tabelaPrecoNome: '           + mapObjHeader.get('tabelaPrecoNome'));
        system.debug('tipoFrete: '                 + mapObjHeader.get('tipoFrete'));
        system.debug('valorFrete: '                + mapObjHeader.get('valorFrete'));
        system.debug('numeroPedidoCliente: '       + mapObjHeader.get('numeroPedidoCliente'));
        system.debug('condicaoPagamento: '         + mapObjHeader.get('condicaoPagamento'));
        system.debug('condicaoPagamentoNome: '     + mapObjHeader.get('condicaoPagamentoNome'));
        system.debug('contatoOrcamento: '          + mapObjHeader.get('contatoOrcamento'));
        system.debug('canalVendas: '               + mapObjHeader.get('canalVendas'));
        system.debug('tipoOrdem: '                 + mapObjHeader.get('tipoOrdem'));
        system.debug('formaPagamento: '            + mapObjHeader.get('formaPagamento'));
        system.debug('dtPrevistaEntrega: '         + mapObjHeader.get('dtPrevistaEntrega'));
        system.debug('clienteRecebedor: '          + mapObjHeader.get('clienteRecebedor'));
        system.debug('clienteRecebedorCGC: '       + mapObjHeader.get('clienteRecebedorCGC'));
        system.debug('enderecoEntrega: '           + mapObjHeader.get('enderecoEntrega'));
        system.debug('enderecoEntregaId: '         + mapObjHeader.get('enderecoEntregaId'));
        system.debug('enderecoEntregaContaOrdem: ' + mapObjHeader.get('enderecoEntregaContaOrdem'));
        system.debug('observacao: '                + mapObjHeader.get('observacao'));
        system.debug('observacaoNF: '              + mapObjHeader.get('observacaoNF'));
        system.debug('cnpjCd: '                    + mapObjHeader.get('cnpjCd'));
        System.debug('Idportalcotacoes: '                     + mapObjHeader.get('Idportalcotacoes'));
        System.debug('score: '                     + mapObjHeader.get('score'));

        Order ord = fillOrderHeader(mapObjHeader, false, null);

        ord.PedidoPendente__c = keepComplementOrder;
        if (oppId != null) {
            ord.OpportunityId = oppId;
        }

        insert ord;

        Id ordId = ord.Id;

        if (oppId != null) {
            Opportunity opp = new Opportunity(
                Id = oppId,
                NumeroPedido__c = ordId
            );
            opportunityTH.disableTrigger();
            update opp;
            opportunityTH.enableTrigger();
        }

        system.debug('Order id: ' + ordId);
        
        List<OrderItem> listOrderItem = new List<OrderItem>();        
        
        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjOrder);
        for (Object obj: listObjOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            system.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);
            OrderItem ordItem = fillOrderItemObj(mapOrdItem, ordId, setMap, prodMap);
            ordItem.ItemPendente__c = mapOrdItem.get('manterPendente') != null ? Boolean.valueOf(mapOrdItem.get('manterPendente')) : false;
            listOrderItem.add(ordItem);
        }

        if (!listOrderItem.isEmpty()) {
            insert listOrderItem;
        }            
        
        system.debug('Enviar para aprovação? ' + sendToApproval);
        if (sendToApproval) {
            Order updateOrd = new Order();
            updateOrd.id = ordId;
            updateOrd.EnviarAprovacao__c = sendToApproval;
            updateOrd.Datageracaopedido__c = datetime.now();

            update updateOrd;
        }

        // insertUserShare(listOrderItem);

        if (keepComplementOrder && !isAutomaticSave) {
            SendEmailMessage.emailMessage(ord);
        }

        return ordId;
    }
    public static Id getVendedor(Map<String, Set<Id>> setMap, String prodId, String cats, String forn){
        Set<String> paramSet = new Set<String>{prodId, cats, forn};
        for(String param : paramSet){
            if(setMap.containsKey(param)){
                for(Id usId : setMap.get(param)){
                    if(!setMap.get(param).contains(UserInfo.getUserId()))
                        return usId;
                }
            }
        }
        return UserInfo.getUserId();
    }
    public static Map<String, Set<Id>> getSetorizacaoMap(String clientId){
        Map<String, Set<Id>> setMap = new Map<String, Set<Id>>();
        Set<String> fieldsSet = new Set<String>{'Produto__c', 'Categoria__c', 'Fornecedor__c'};
        for(Setorizacao__c sets : [SELECT id, Vendedor__c, Gerente__C, Produto__c, Categoria__c, Fornecedor__c
                                FROM Setorizacao__c 
                                WHERE Conta__C = :clientId AND vendedor__r.IsActive = true]){
            for(String field : fieldsSet){
                String fieldVal = (String)sets.get(field);
                if(!setMap.containsKey(fieldVal)){
                    setMap.put(fieldVal, new Set<Id>());
                }  
                if(sets.Vendedor__c != null) setMap.get(fieldVal).add(sets.Vendedor__c);
                if(sets.Gerente__c != null) setMap.get(fieldVal).add(sets.Gerente__c);
            }
        }
        return setMap;
    }
    public static Map<String, Product2> getProdCat(Object[] listObjOrder){
        Set<Id> prodIdSet = new Set<Id>();
        for (Object obj: listObjOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            prodIdSet.add(String.valueOf(mapOrdItem.get('prodId')));
        }

        Map<String, Product2> prodMap = new Map<String, Product2>();
        for(Product2 prod : [SELECT id, CategoriaComercial__c, Fornecedor__c FROM Product2 WHERE Id IN :prodIdSet]){
            prodMap.put(prod.Id, prod);
        }
        return prodMap;

    }

    @AuraEnabled
    public static String generateBudgetAndOrder(String jsonOrderBudget, String headerInfoOpp, String headerInfoOrd, Id oppIdToUpdate) {
        system.debug('generateBudgetAndOrder');
        List<Object> listGenericBudgetOrder;

        listGenericBudgetOrder = (List<Object>) JSON.deserializeUntyped(jsonOrderBudget);
        Map<String, Object> mapObjHeaderOpp = (Map<String, Object>) JSON.deserializeUntyped(headerInfoOpp);
        Map<String, Object> mapObjHeaderOrd = (Map<String, Object>) JSON.deserializeUntyped(headerInfoOrd);

        system.debug('mapObjHeaderOpp: ' + mapObjHeaderOpp);
        system.debug('mapObjHeaderOrd: ' + mapObjHeaderOrd);
        
        Opportunity opp; 

        Id oppId;

        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeaderOrd.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listGenericBudgetOrder);

        if (oppIdToUpdate != null) {
            opp = new Opportunity();
            opp.id = oppIdToUpdate;
            opp.StageName = 'Fechado/Gerado';
            oppId = oppIdToUpdate;
            update opp;
        } else {
            opp = fillOppHeader(mapObjHeaderOpp, true, null);
            insert opp;
            oppId = opp.Id;
        }

        List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>();
        List<OpportunityLineItem> listOppLineItemUpdate = new List<OpportunityLineItem>();
        
        for (Object obj : listGenericBudgetOrder) {
            Map<String, Object> mapOppLineItem = (Map<String, Object>) (obj);
            system.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);    
            OpportunityLineItem oppLineItem = fillOppLineItemObj(mapOppLineItem, oppId, setMap, prodMap);
            if(oppLineItem.Id == null)
                listOppLineItem.add(oppLineItem);
            else
                listOppLineItemUpdate.add(oppLineItem);
        }

        if (!listOppLineItem.isEmpty()) {
            OpportunityTH.disableTrigger();
            insert listOppLineItem;
            OpportunityTH.enableTrigger();
            // insertUserShare(listOppLineItem);
        }
        
        if (!listOppLineItemUpdate.isEmpty()) {
            OpportunityTH.disableTrigger();
            update listOppLineItemUpdate;
            OpportunityTH.enableTrigger();
            // insertUserShare(listOppLineItemUpdate);
        }
            
        Opportunity newOpp = [SELECT Id, StageName, NecessitaAprovacaoComercial__c, NecessitaAprovacaoPricing__c, AprovadoComercial__c, AprovadoPricing__c, Score__c, Margem__c, MargemAlvo__c FROM Opportunity WHERE Id = :oppId][0];

        Order ord = fillOrderHeader(mapObjHeaderOrd, true, newOpp);
        if (ord.DatasParcelas__c != null) {
            ord.DiaParcelas__c = getStrDaysBetween(ord.DatasParcelas__c);
        }
        
        insert ord;

        Id ordId = ord.id;

        List<OrderItem> listOrderItem = new List<OrderItem>();

        for (Object obj : listGenericBudgetOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            system.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);            
            listOrderItem.add(fillOrderItemObj(mapOrdItem, ordId, setMap, prodMap));
        }
        
        if (!listOrderItem.isEmpty()) {
            insert listOrderItem;
            // insertUserShare(listOrderItem);
        }

        newOpp.NumeroPedido__c = ord.id;
        update newOpp;

        // if(checkApproval(ord)){
            ord.EnviarAprovacao__C = true;
            ord.Datageracaopedido__c = datetime.now();
            update ord;
        // }

        return ordId;
    }
    public static Boolean checkApproval(Order ord){
        return (ord.AprovadoComercial__c && !ord.NecessitaAprovacaoPricing__c) || (ord.AprovadoPricing__c && !ord.NecessitaAprovacaoComercial__c) || (ord.AprovadoComercial__c && ord.AprovadoPricing__c);
    }

    @AuraEnabled
    public static String editLabOrder(String jsonOrder, String headerInfo, Boolean sendToApproval, String recordId, Boolean keepComplementOrder, Boolean isAutomaticSave) {
        System.debug(jsonOrder);
        System.debug(headerInfo);

        List<Object> listObjOrder;

        listObjOrder = (List<Object>) JSON.deserializeUntyped(jsonOrder); 
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);
        // Order oldOrd = [SELECT Id, CreatedDatetime__c FROM ORDER WHERE Id = :recordId LIMIT 1];
        Order ord = new Order();
        ord.Id = recordId;
        ord.DatasParcelas__c = mapObjHeader.get('dtList') != null ? formatInstallmentDates(String.valueOf(mapObjHeader.get('dtList'))) : null;
        ord.CondicaoPagamento__c  = mapObjHeader.get('condicaoPagamento') != null ? String.valueOf(mapObjHeader.get('condicaoPagamento')) : null;
        ord.FormaPagamento__c  = mapObjHeader.get('formaPagamento') != null ? String.valueOf(mapObjHeader.get('formaPagamento')) : null;
        ord.MensagemNF__c  = mapObjHeader.get('observacaoNF') != null ? String.valueOf(mapObjHeader.get('observacaoNF')) : null;
        ord.ObservacoesPedido__c  = mapObjHeader.get('observacaoPedido') != null ? String.valueOf(mapObjHeader.get('observacaoPedido')) : null;
        if (ord.DatasParcelas__c != null) {
            ord.DiaParcelas__c = getStrDaysBetween(ord.DatasParcelas__c);
        }
        ord.PedidoPendente__c = keepComplementOrder;

        Order updateSonOrder = new Order();
        for (Order sonOrd : [SELECT Id, DatasParcelas__c, CondicaoPagamento__c, FormaPagamento__c FROM Order WHERE PedidoPai__c =: recordId]) {
            sonOrd.DatasParcelas__c = ord.DatasParcelas__c;
            sonOrd.CondicaoPagamento__c = ord.CondicaoPagamento__c;
            sonOrd.FormaPagamento__c = ord.FormaPagamento__c;
            updateSonOrder = sonOrd;
        }
        OrderHandler.disableTrigger();
        update updateSonOrder;
        OrderHandler.enableTrigger();

        List<OrderItem> listOldOrderItem = [SELECT Id, OrderId FROM OrderItem WHERE OrderId = :recordId];

        System.debug('Order id: ' + recordId);
        
        Set<Id> setIdUpdate = new Set<Id>();              
        List<OrderItem> listOrderItemUpdate = new List<OrderItem>();    
        
        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjOrder);
        for (Object obj: listObjOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            System.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);    
            OrderItem ordItem = new OrderItem();            
            if (mapOrdItem.get('itemId') != null && String.valueOf(mapOrdItem.get('itemId')).startsWith('802')) {
                ordItem.Id = String.valueOf(mapOrdItem.get('itemId'));
                if (mapOrdItem.get('caixa') != null) {
                    ordItem.UnitPrice  = Decimal.valueOf(String.valueOf(mapOrdItem.get('caixa')));
                    ordItem.ValorCx__c = Decimal.valueOf(String.valueOf(mapOrdItem.get('caixa')));
                }
                ordItem.UnidadeMedidaPDF__c = String.Isblank(String.valueOf(mapOrdItem.get('unidadeMedida'))) ? String.valueOf(mapOrdItem.get('unidadePrincipal')) : String.valueOf(mapOrdItem.get('unidadeMedida'));
                
                ordItem.ObservacoesComercial__c = String.IsNotBlank(String.valueOf(mapOrdItem.get('observacaoComercial')))  ? String.valueOf(mapOrdItem.get('observacaoComercial')) : '';

                ordItem.QuantidadePDF__c = String.valueOf(mapOrdItem.get('quantidade'));
                ordItem.PrecoPDF__c = String.valueOf(mapOrdItem.get('unitario'));
    
            }

            if (ordItem.Id != null) {
                listOrderItemUpdate.add(ordItem);
            }
        }
        
        system.debug(listOrderItemUpdate);
        if (!listOrderItemUpdate.isEmpty()) {
            OrderHandler.disableTrigger();
            update listOrderItemUpdate;
            OrderHandler.enableTrigger();
        }

        system.debug(ord);
        update ord;
        return recordId;
    }

    @AuraEnabled
    public static String editOrder(String jsonOrder, String headerInfo, Boolean sendToApproval, String recordId, Boolean keepComplementOrder, Boolean isAutomaticSave) {
        System.debug(jsonOrder);
        System.debug(headerInfo);

        List<Object> listObjOrder;

        listObjOrder = (List<Object>) JSON.deserializeUntyped(jsonOrder); 
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);

        System.debug('CABEÇALHO DESERIALIZADO: '   + mapObjHeader);
        System.debug('clienteEmissor: '            + mapObjHeader.get('clienteEmissor'));
        System.debug('clienteEmissorId: '          + mapObjHeader.get('clienteEmissorId'));
        System.debug('clienteEmissorCGC: '         + mapObjHeader.get('clienteEmissorCGC'));
        System.debug('medico: '                    + mapObjHeader.get('medico'));
        System.debug('medicoId: '                  + mapObjHeader.get('medicoId'));
        System.debug('medicoCRM: '                 + mapObjHeader.get('medicoCRM'));
        System.debug('tabelaPreco: '               + mapObjHeader.get('tabelaPreco'));
        System.debug('tabelaPrecoNome: '           + mapObjHeader.get('tabelaPrecoNome'));
        System.debug('tipoFrete: '                 + mapObjHeader.get('tipoFrete'));
        System.debug('valorFrete: '                + mapObjHeader.get('valorFrete'));
        System.debug('numeroPedidoCliente: '       + mapObjHeader.get('numeroPedidoCliente'));
        System.debug('condicaoPagamento: '         + mapObjHeader.get('condicaoPagamento'));
        System.debug('condicaoPagamentoNome: '     + mapObjHeader.get('condicaoPagamentoNome'));
        System.debug('contatoOrcamento: '          + mapObjHeader.get('contatoOrcamento'));
        System.debug('canalVendas: '               + mapObjHeader.get('canalVendas'));
        System.debug('tipoOrdem: '                 + mapObjHeader.get('tipoOrdem'));
        System.debug('formaPagamento: '            + mapObjHeader.get('formaPagamento'));
        System.debug('dtPrevistaEntrega: '         + mapObjHeader.get('dtPrevistaEntrega'));
        System.debug('clienteRecebedor: '          + mapObjHeader.get('clienteRecebedor'));
        System.debug('clienteRecebedorCGC: '       + mapObjHeader.get('clienteRecebedorCGC'));
        System.debug('enderecoEntrega: '           + mapObjHeader.get('enderecoEntrega'));
        System.debug('enderecoEntregaContaOrdem: ' + mapObjHeader.get('enderecoEntregaContaOrdem'));
        System.debug('observacao: '                + mapObjHeader.get('observacao'));
        System.debug('observacaoNF: '              + mapObjHeader.get('observacaoNF'));
        System.debug('cnpjCd: '                    + mapObjHeader.get('cnpjCd'));
        System.debug('score: '                     + mapObjHeader.get('score'));
        System.debug('Idportalcotacoes: '                     + mapObjHeader.get('Idportalcotacoes'));
        // Order oldOrd = [SELECT Id, CreatedDatetime__c FROM ORDER WHERE Id = :recordId LIMIT 1];
        Order ord = fillOrderHeader(mapObjHeader, false, null);
        if (sendToApproval && ord.DatasParcelas__c != null) {
            ord.DiaParcelas__c = getStrDaysBetween(ord.DatasParcelas__c);
        }
        ord.Id = recordId;
        ord.PedidoPendente__c = keepComplementOrder;
        // if (oldOrd.CreatedDatetime__c != null)
        //     ord.CreatedDatetime__c = oldOrd.CreatedDatetime__c;
        OrderHandler.disableTrigger();
        update ord;
        OrderHandler.enableTrigger();

        List<OrderItem> listOldOrderItem = [SELECT Id, OrderId FROM OrderItem WHERE OrderId = :recordId];

        System.debug('Order id: ' + recordId);
        
        Set<Id> setIdUpdate = new Set<Id>();        
        List<OrderItem> listOrderItemAdd = new List<OrderItem>();        
        List<OrderItem> listOrderItemUpdate = new List<OrderItem>();        
        List<OrderItem> listOrderItemDelete = new List<OrderItem>();        
        
        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjOrder);
        for (Object obj: listObjOrder) {
            Map<String, Object> mapOrdItem = (Map<String, Object>) (obj);
            System.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + obj);    
            OrderItem ordItem = fillOrderItemObj(mapOrdItem, null, setMap, prodMap);
            ordItem.ItemPendente__c = mapOrdItem.get('manterPendente') != null ? Boolean.valueOf(mapOrdItem.get('manterPendente')) : false;
            ordItem.UnidadeMedidaPDF__c = String.Isblank(String.valueOf(mapOrdItem.get('unidadeMedida'))) ? String.valueOf(mapOrdItem.get('unidadePrincipal')) : String.valueOf(mapOrdItem.get('unidadeMedida'));

            ordItem.QuantidadePDF__c = String.valueOf(mapOrdItem.get('quantidade'));
            ordItem.PrecoPDF__c = String.valueOf(mapOrdItem.get('unitario'));

            if (ordItem.Id != null) {
                if (ordItem.quantity != null && ordItem.quantity != 0) {
                    listOrderItemUpdate.add(ordItem);
                    setIdUpdate.add(ordItem.Id);
                }
            } else {
                ordItem.OrderId = recordId;
                listOrderItemAdd.add(ordItem);
            }
        }
        
        for (OrderItem ordItem : listOldOrderItem) {
            if (!setIdUpdate.contains(ordItem.Id)) {
                listOrderItemDelete.add(ordItem);
            }
        }

        System.debug('listOrderItemAdd: ' + listOrderItemAdd);    
        System.debug('listOrderItemUpdate: ' + listOrderItemUpdate);    
        System.debug('listOrderItemDelete: ' + listOrderItemDelete);    

        if (!listOrderItemAdd.isEmpty()) {
            insert listOrderItemAdd;

            if(keepComplementOrder){
                insertSolicitacao(listOrderItemAdd, recordId);
            }
            // insertUserShare(listOrderItemAdd);
        } 

        if (!listOrderItemUpdate.isEmpty()) {
            update listOrderItemUpdate;

            if(keepComplementOrder){
                insertSolicitacao(listOrderItemUpdate, recordId);
            }
            // insertUserShare(listOrderItemUpdate);
        }     

        if (!listOrderItemDelete.isEmpty()) {
            delete listOrderItemDelete;
        }        

        if (sendToApproval) {
            ord.EnviarAprovacao__c = sendToApproval;
            ord.Datageracaopedido__c = datetime.now();
            update ord;
        }

        if (keepComplementOrder && !isAutomaticSave) {
            SendEmailMessage.emailMessage(ord);
        }
        
        return recordId;
    }

    @AuraEnabled
    public static String editBudget(String budget, String headerInfo, Boolean sendToApproval, String recordId, Boolean hasComplementOrder) {
        System.debug(budget);
        System.debug(headerInfo);

        List<Object> listObjBudget;

        listObjBudget = (List<Object>) JSON.deserializeUntyped(budget); 
        Map<String, Object> mapObjHeader = (Map<String, Object>) JSON.deserializeUntyped(headerInfo);

        System.debug(mapObjHeader);
        System.debug('valorTotal: '        + mapObjHeader.get('valorTotal'));
        System.debug('score: '             + mapObjHeader.get('score'));
        System.debug('clienteEmissorId: '  + mapObjHeader.get('clienteEmissorId'));
        System.debug('tabelaPreco: '       + mapObjHeader.get('tabelaPreco'));
        System.debug('canalEntrada: '      + mapObjHeader.get('canalEntrada'));
        System.debug('condicaoPagamento: ' + mapObjHeader.get('condicaoPagamento'));
        System.debug('formaPagamento: '    + mapObjHeader.get('formaPagamento'));
        System.debug('contatoOrcamento: '  + mapObjHeader.get('contatoOrcamento'));
        System.debug('prazoValidade: '     + mapObjHeader.get('prazoValidade'));
        System.debug('dtValidade: '        + mapObjHeader.get('dtValidade'));
        System.debug('observacaoCliente: ' + mapObjHeader.get('observacaoCliente'));
        System.debug('observacao: '        + mapObjHeader.get('observacao'));

        Opportunity opp = fillOppHeader(mapObjHeader, false, recordId);
        opp.Id = recordId;
        if (sendToApproval && opp.DatasParcelas__c != null) {
            opp.DiaParcelas__c = getStrDaysBetween(opp.DatasParcelas__c);
        }
        if (hasComplementOrder) {
            opp.StageName = 'Fechado/Gerado';
        }
        OpportunityTH.disableTrigger();
        update opp;
        OpportunityTH.enableTrigger();

        List<OpportunityLineItem> listOppLineItem = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :recordId];

        System.debug('Opportunity id: ' + recordId);
        
        Set<Id> setIdUpdate = new Set<Id>();        
        List<OpportunityLineItem> listOppLineItemAdd = new List<OpportunityLineItem>();        
        List<OpportunityLineItem> listOppLineItemUpdate = new List<OpportunityLineItem>();        
        List<OpportunityLineItem> listOppLineItemDelete = new List<OpportunityLineItem>();  

        Map<String, Set<Id>> setMap = getSetorizacaoMap(String.valueOf(mapObjHeader.get('clienteEmissorId')));
        Map<String, Product2> prodMap = getProdCat(listObjBudget);    
        
        Map<Id, Boolean> mapProdRecommended = new Map<Id, Boolean>();
        
        for (Object obj: listObjBudget) {
            Map<String, Object> mapOppLineItem = (Map<String, Object>) (obj);
            System.debug('PRODUTOS (CDs) DESERIALIZADOS: ' + json.serialize(obj));    
            OpportunityLineItem oppLineItem = fillOppLineItemObj(mapOppLineItem, null, setMap, prodMap);
            mapProdRecommended.put(oppLineItem.Product2Id, false);
            
            oppLineItem.UnidadeMedidaPDF__c = String.Isblank(String.valueOf(mapOppLineItem.get('unidadeSecundaria'))) || ( mapOppLineItem.get('uniSecundaria') != null && !Boolean.valueOf(mapOppLineItem.get('uniSecundaria')) )? String.valueOf(mapOppLineItem.get('unidadePrincipal')) : String.valueOf(mapOppLineItem.get('unidadeSecundaria'));
            
            oppLineItem.ObservacoesComercial__c = String.IsNotBlank(String.valueOf(mapOppLineItem.get('observacaoComercial')))  ? String.valueOf(mapOppLineItem.get('observacaoComercial')) : '';
            
            // if(String.valueOf(mapOppLineItem.get('unidadePrincipal')) != String.valueOf(mapOppLineItem.get('unidadeMedida')) && String.isNotBlank(String.valueOf(mapOppLineItem.get('unidadeMedida')))){
            if(String.valueOf(mapOppLineItem.get('unidadePrincipal')) != String.valueOf(mapOppLineItem.get('unidadeSecundaria')) && String.isNotBlank(String.valueOf(mapOppLineItem.get('unidadeSecundaria'))) && (mapOppLineItem.get('uniSecundaria') != null &&  Boolean.valueOf(mapOppLineItem.get('uniSecundaria')) ) ){
                oppLineItem.QuantidadePDF__c = String.valueOf(mapOppLineItem.get('quantidade'));
                oppLineItem.PrecoPDF__c = String.valueOf(mapOppLineItem.get('unitario'));
            }else{
                oppLineItem.QuantidadePDF__c = String.valueOf(mapOppLineItem.get('quantidadeCx'));
                oppLineItem.PrecoPDF__c = String.valueOf(mapOppLineItem.get('caixa'));
            }

            if (oppLineItem.Id != null) {
                listOppLineItemUpdate.add(oppLineItem);
                setIdUpdate.add(oppLineItem.Id);
            } else {
                oppLineItem.OpportunityId = recordId;
                listOppLineItemAdd.add(oppLineItem);
            }
        }

        for (AnaliseERB__c analise : [SELECT Id, StatusRecomendacao__c, Produto__c FROM AnaliseERB__c WHERE Produto__c IN: mapProdRecommended.keySet() AND Orcamento__c =: recordId]) {
            if (analise.StatusRecomendacao__c != null) {
                if (analise.StatusRecomendacao__c.contains('Aceita')) {
                    mapProdRecommended.put(analise.Produto__c, true);
                }
            } else {
                mapProdRecommended.put(analise.Produto__c, true);
            }
        }

        List<AnaliseERB__c> listAnaliseERB = new List<AnaliseERB__c>();

        for (RecomendacaoCotacao__c recQuote : [SELECT Id, Cotacao__c, Cotacao__r.OpportunityId, Produto__c FROM RecomendacaoCotacao__c WHERE Produto__c IN: mapProdRecommended.keySet() AND Cotacao__r.OpportunityId =: recordId]) {
            if (!mapProdRecommended.containsKey(recQuote.Produto__c)) {
                AnaliseERB__c analise = new AnaliseERB__c(
                    Orcamento__c = recQuote.Cotacao__r.OpportunityId,
                    Produto__c = recQuote.Produto__c
                );
                listAnaliseERB.add(analise);
            }
            mapProdRecommended.put(recQuote.Produto__c, true);            
        }
        
        for (OpportunityLineItem oppLineItem : listOppLineItem) {
            if (!setIdUpdate.contains(oppLineItem.Id)) {
                listOppLineItemDelete.add(oppLineItem);
            }
        }

        system.debug(mapProdRecommended);
        
        for (OpportunityLineItem oppLineItem : listOppLineItemUpdate) {
            oppLineItem.Recomendacao__c = mapProdRecommended.get(oppLineItem.Product2Id);
        }

        for (OpportunityLineItem oppLineItem : listOppLineItemAdd) {
            oppLineItem.Recomendacao__c = mapProdRecommended.get(oppLineItem.Product2Id);
        }


        System.debug('listAnaliseERB: ' + listAnaliseERB);    
        System.debug('listOppLineItemAdd: ' + listOppLineItemAdd);    
        System.debug('listOppLineItemUpdate: ' + listOppLineItemUpdate);    
        System.debug('listOppLineItemDelete: ' + listOppLineItemDelete);    

        if (!listAnaliseERB.isEmpty()) {
            insert listAnaliseERB;
        }

        if (!listOppLineItemAdd.isEmpty()) {
            insert listOppLineItemAdd;
            // insertUserShare(listOppLineItemAdd);
        }

        if (!listOppLineItemUpdate.isEmpty()) {
            update listOppLineItemUpdate;
        }

        if (!listOppLineItemDelete.isEmpty()) {
            delete listOppLineItemDelete;
        }

        if (sendToApproval) {
            opp.EnviarAprovacao__c = sendToApproval;
            update opp;
        }
        
        return recordId;
    }

    public static String getStrDaysBetween(String datasParcelas) {
        String dtStr = reformatInstallmentDates(datasParcelas);
        List<Integer> listDays = new List<Integer>();
        for (String dt : dtStr.split(', ')) {
            List<String> dtSplit = dt.split('-');
            Date currentDt = Date.newInstance(Integer.valueOf(dtSplit[0]), Integer.valueOf(dtSplit[1]), Integer.valueOf(dtSplit[2]));
            listDays.add(Date.today().daysBetween(currentDt));
            listDays.sort();
        }
        return String.join(listDays, ', ') + ' D';
    }

    public static String checkOppStatus(Opportunity opp) {
        return ( opp != null && opp.StageName == 'Fechado/Gerado' && ((opp.AprovadoComercial__c && !opp.NecessitaAprovacaoPricing__c) || 
        (opp.AprovadoPricing__c && !opp.NecessitaAprovacaoComercial__c) || 
        (opp.AprovadoComercial__c && opp.AprovadoPricing__c))) ? 'Aprovado' : 'Em digitação';
    }

    public static Order fillOrderHeader(Map<String, Object> mapObjHeader, Boolean isFromBudget, Opportunity opp) {
        System.debug(mapObjHeader);
        System.debug(mapObjHeader.get('createOrderDt'));
        String tipoOrdem = String.valueOf(mapObjHeader.get('tipoOrdem'));
        String data = String.valueOf(mapObjHeader.get('dtPrevistaEntrega'));
        Date dataEntrega = data != null ? Date.valueOf(data) : Date.today();    
        String createOrderDt = String.valueOf(mapObjHeader.get('createOrderDt'));
        Datetime dataCriacao = createOrderDt != null ? Datetime.valueOf(createOrderDt) : null;

        String ordRecType = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();

        Order ord = new Order();
        if (opp != null) {
            ord.OpportunityId      = opp.Id;
            ord.Score__c           = opp.Score__c != null  ?  opp.Score__c : null;
            ord.Margem__c          = opp.Margem__c != null ? opp.Margem__c : null;
            ord.MargemAlvo__c      = opp.MargemAlvo__c != null ? opp.MargemAlvo__c : null;
        } else {
            if(mapObjHeader.get('score') == ''){
                ord.Score__c           = null;    
            }else{
                ord.Score__c           = mapObjHeader.get('score') != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('score'))) : null;
            }
            if(mapObjHeader.get('margemAtual') == ''){
                ord.Margem__c          = null;
            }else{
                ord.Margem__c          = mapObjHeader.get('margemAtual') != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('margemAtual'))) : null;
            }
            if(mapObjHeader.get('margemAlvo') == ''){

            }else{
                ord.MargemAlvo__c      = mapObjHeader.get('margemAlvo')  != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('margemAlvo'))) : null;
            }
        }
        if (mapObjHeader.get('isVansOrder') != null) {
            if (!Boolean.valueOf(mapObjHeader.get('isVansOrder'))) {
                system.debug('testando');
                ord.Status = checkOppStatus(opp);
            }
        } else {
            system.debug('testando 2');
            ord.Status = checkOppStatus(opp);
        }
        ord.AccountId              = mapObjHeader.get('clienteEmissorId')    != null ? String.valueOf(mapObjHeader.get('clienteEmissorId')) : null;
        ord.NomeMedico__c          = mapObjHeader.get('medicoId')            != null ? String.valueOf(mapObjHeader.get('medicoId')) : null;
        ord.Pricebook2Id           = mapObjHeader.get('tabelaPreco')         != null ? String.valueOf(mapObjHeader.get('tabelaPreco')) : null;
        ord.TipoFrete__c           = mapObjHeader.get('tipoFrete')           != null ? String.valueOf(mapObjHeader.get('tipoFrete')) : null;
        ord.ValorFrete__c          = mapObjHeader.get('valorFrete')          != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('valorFrete'))) : null;
        ord.NumeroPedidoCliente__c = mapObjHeader.get('numeroPedidoCliente') != null ? String.valueOf(mapObjHeader.get('numeroPedidoCliente')) : null;
        ord.CondicaoPagamento__c   = mapObjHeader.get('condicaoPagamento')   != null ? String.valueOf(mapObjHeader.get('condicaoPagamento')) : null;
        ord.ContatoOrcamento__c    = mapObjHeader.get('contatoOrcamento')    != null ? String.valueOf(mapObjHeader.get('contatoOrcamento')) : null;
        ord.CanalEntrada__c        = mapObjHeader.get('canalVendas')         != null ? String.valueOf(mapObjHeader.get('canalVendas')) : null;
        ord.ValorTotal__c          = mapObjHeader.get('valorTotal')          != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('valorTotal'))) : null;
        // ord.FormaPagamento__c      = mapObjHeader.get('formaPagamento')      != null ? String.valueOf(mapObjHeader.get('formaPagamento')) == 'Deposito' ? 'Depósito' : 'Boleto' : null;
        ord.FormaPagamento__c      = mapObjHeader.get('formaPagamento')      != null ? String.valueOf(mapObjHeader.get('formaPagamento')) : null;
        ord.ClienteRecebedor__c    = mapObjHeader.get('clienteRecebedor')    != null ? String.valueOf(mapObjHeader.get('clienteRecebedor')) : null;
        ord.Description            = mapObjHeader.get('observacao')          != null ? String.valueOf(mapObjHeader.get('observacao')) : null;
        ord.MensagemNF__c          = mapObjHeader.get('observacaoNF')        != null ? String.valueOf(mapObjHeader.get('observacaoNF')) : null;
        ord.ObservacoesPedido__c   = mapObjHeader.get('observacaoPedido')    != null ? String.valueOf(mapObjHeader.get('observacaoPedido')) : null;
        //ord.cnpjCD__c              = mapObjHeader.get('cnpjCd')              != null ? String.valueOf(mapObjHeader.get('cnpjCd')) : null;
        // ord.CNPJCD__c              = mapObjHeader.get('cnpjCd')              != null ? String.valueOf(mapObjHeader.get('cnpjCd')) : null;
        ord.Endereco_Entrega__c    = mapObjHeader.get('enderecoEntregaId') != null ? String.valueOf(mapObjHeader.get('enderecoEntregaId')) : null;
        if (ord.Endereco_Entrega__c != null) {
            ord.EnderecoEntrega__c = getAddress(ord.Endereco_Entrega__c);
        } else if (ord.AccountId != null){
            ord.EnderecoEntrega__c = getAccountAddress(ord.AccountId);
        }
        // RUA + Cidade + Estado + CEP
        ord.DatasParcelas__c       = mapObjHeader.get('dtList')            != null ? formatInstallmentDates(String.valueOf(mapObjHeader.get('dtList'))) : null;
        ord.Frete__c               = mapObjHeader.get('freteList')         != null ? formatFreightValues(String.valueOf(mapObjHeader.get('freteList'))) : null;
        ord.EffectiveDate          = Date.today();
        ord.DataEntrega__c         = dataEntrega;
        if (dataCriacao != null) {
            ord.CreatedDatetime__c = dataCriacao;
        }
        ord.RecordTypeId           = ordRecType;
        ord.Type                   = tipoOrdem;
        ord.RecomendacaoRespondida__c = mapObjHeader.get('recomendacaoRespondida')  != null ? Boolean.valueOf(mapObjHeader.get('recomendacaoRespondida')): false;
        ord.NecessitaAprovacaoComercial__c = opp != null && opp.StageName =='Fechado/Gerado' ? opp.NecessitaAprovacaoComercial__c : false;
        ord.NecessitaAprovacaoPricing__c   = opp != null && opp.StageName =='Fechado/Gerado' ? opp.NecessitaAprovacaoPricing__c : false;
        ord.AprovadoComercial__c           = opp != null && opp.StageName =='Fechado/Gerado' ? opp.AprovadoComercial__c : false;
        ord.AprovadoPricing__c             = opp != null && opp.StageName =='Fechado/Gerado' ? opp.AprovadoPricing__c : false;
        ord.Idportalcotacoes__c    = mapObjHeader.get('Idportalcotacoes')  != null ? String.valueOf(mapObjHeader.get('Idportalcotacoes')): null;
        ord.Endereco_Entrega__c             = mapObjHeader.get('enderecoEntregaId')          != null ? String.valueOf(mapObjHeader.get('enderecoEntregaId')) : null;
        return ord;
    }

    public static OrderItem fillOrderItemObj(Map<String, Object> mapOrdItem, Id ordId, Map<String, Set<Id>> setMap, Map<String, Product2> prodMap) {
        OrderItem ordItem         = new OrderItem();
        system.debug(mapOrdItem.get('itemId'));
        if (mapOrdItem.get('itemId') != null && String.valueOf(mapOrdItem.get('itemId')).startsWith('802')) {
            ordItem.Id                = String.valueOf(mapOrdItem.get('itemId'));
        } else {
            ordItem.OrderId           = ordId;
            ordItem.PricebookEntryId  = String.valueOf(mapOrdItem.get('id')).substring(0, 18);
            ordItem.Product2Id        = String.valueOf(mapOrdItem.get('prodId'));
        }
        ordItem.Lote__c           = String.valueOf(mapOrdItem.get('lote'));
        ordItem.QuantidadeUn__c   = mapOrdItem.get('quantidade')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('quantidade'))) : null;
        ordItem.Quantity          = mapOrdItem.get('quantidadeCx')   != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('quantidadeCx'))) : null;
        ordItem.ValorUn__c        = mapOrdItem.get('unitario')       != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('unitario'))) : null;
        ordItem.UnitPrice         = mapOrdItem.get('caixa')          != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('caixa'))) : null;
        ordItem.ValorCx__c        = mapOrdItem.get('caixa')          != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('caixa'))) : null;
        ordItem.ValorMalha__c     = mapOrdItem.get('precoMalha')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('precoMalha'))) : null;
        ordItem.ValorSugerido__c  = mapOrdItem.get('precoSugerido')  != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('precoSugerido'))) : null;
        ordItem.Range__c          = mapOrdItem.get('rangeStringify') != null ? String.valueOf(mapOrdItem.get('rangeStringify')) : null;
        ordItem.PrecoTotal__c     = mapOrdItem.get('valorTotal')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('valorTotal'))) : null;
        ordItem.Margem__c         = mapOrdItem.get('margem')         != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('margem'))) : null;
        ordItem.MargemAlvo__c     = mapOrdItem.get('margemAlvo')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('margemAlvo'))) : null;
        ordItem.ForaMalha__c      = mapOrdItem.get('foraMalha')      != null ? Boolean.valueOf(String.valueOf(mapOrdItem.get('foraMalha'))) : false;
        ordItem.ValidadeMinima__c = mapOrdItem.get('validadeMinima') != null ? (String.valueOf(mapOrdItem.get('validadeMinima')) == 'Shelf Life' || String.valueOf(mapOrdItem.get('validadeMinima')) == 'Vazio') ? '168' : String.valueOf(mapOrdItem.get('validadeMinima')) : '168';
        ordItem.Desconto__c       = mapOrdItem.get('desconto')       != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('desconto')))      : null;
        // ordItem.ScoreAlvo__c     = mapOrdItem.get('foraMalha')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('foraMalha')))     : null;
        // ordItem.ScoreAtual__c    = mapOrdItem.get('foraMalha')     != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('foraMalha')))     : null;
        String prodId = String.valueOf(mapOrdItem.get('prodId'));
        ordItem.Vendedor__c      = getVendedor(setMap, prodId, prodMap.get(prodId).CategoriaComercial__c, prodMap.get(prodId).Fornecedor__c);
        // ordItem.Vendedor__c      = UserInfo.getUserId();        
        ordItem.CentroDistribuicao__c = mapOrdItem.get('cds')        != null ? String.valueOf(mapOrdItem.get('cds')) : null;
        ordItem.Custo__c         = mapOrdItem.get('custoCx')         != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('custoCx'))) : null;
        ordItem.Imposto__c       = mapOrdItem.get('aliquota')        != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('aliquota'))) : null;
        ordItem.ScoreItem__c     = mapOrdItem.get('scoreItem')       != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('scoreItem'))) : null;
        ordItem.ScoreBU__c       = mapOrdItem.get('scoreBU')         != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('scoreBU'))) : null;
        ordItem.ScoreMix__c      = mapOrdItem.get('scoreMix')        != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('scoreMix'))) : null;
        ordItem.PosicaoItem__c   = mapOrdItem.get('indexPosition')   != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('indexPosition'))) : null;
        ordItem.PosicaoInsercao__c = mapOrdItem.get('indexInsertPosition')   != null ? Decimal.valueOf(String.valueOf(mapOrdItem.get('indexInsertPosition'))) : null;
        ordItem.CNPJCD__c        = mapOrdItem.get('cnpjCd')          != null ? String.valueOf(mapOrdItem.get('cnpjCd')) : null;
        ordItem.ForaMalha__c     = mapOrdItem.get('foraMalha')       != null ? Boolean.valueOf(mapOrdItem.get('foraMalha')) : null;
        ordItem.SequenciaOC__c   = mapOrdItem.get('SequenciaOC')     != null ? String.valueOf(mapOrdItem.get('SequenciaOC')) : null; 
        ordItem.laboratorio__c   = mapOrdItem.get('laboratorio')     != null ? String.valueOf(mapOrdItem.get('laboratorio')) : null; 
        ordItem.BloqueadoRegionalizacao__c = mapOrdItem.get('bloqRegionalizacao') != null ? Boolean.valueOf(mapOrdItem.get('bloqRegionalizacao')) : false;
        ordItem.CampanhaShelfLife__c = mapOrdItem.get('showBadgeShelflifeCNPJ') != null ? Boolean.valueOf(mapOrdItem.get('showBadgeShelflifeCNPJ')) : false;
        ordItem.CampanhaShelfLifeAux__c = mapOrdItem.get('showBadgeShelflifeCNPJAux') != null ? Boolean.valueOf(mapOrdItem.get('showBadgeShelflifeCNPJAux')) : false;
        ordItem.ProdutoCampanha__c = mapOrdItem.get('isInCampaign') != null ? Boolean.valueOf(mapOrdItem.get('isInCampaign')) : false;
        ordItem.TipoIntegradora__c = mapOrdItem.get('tipoIntegradora') != null ? String.valueOf(mapOrdItem.get('tipoIntegradora')) : null;
        ordItem.ObservacoesComercial__c = mapOrdItem.get('observacaoComercial') != null ? String.valueOf(mapOrdItem.get('observacaoComercial')) : null;

        return ordItem;
    }

    public static Opportunity fillOppHeader(Map<String, Object> mapObjHeader, Boolean isBudgetClosed, String recId) {
        Opportunity opp = new Opportunity();
        system.debug(mapObjHeader.get('score'));
        system.debug(mapObjHeader.get('margemAtual'));
        opp.StageName             = isBudgetClosed ? 'Fechado/Gerado' : 'Em digitação';
        if (recId == null) {
            opp.Name                  = mapObjHeader.get('numOrcamento')      != null ? String.valueOf(mapObjHeader.get('numOrcamento')) : 'OR-00000000';
        }
        opp.Amount                = mapObjHeader.get('valorTotal')        != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('valorTotal'))): null;
        opp.Score__c              = mapObjHeader.get('score')             != null && mapObjHeader.get('score') != '' ? Decimal.valueOf(String.valueOf(mapObjHeader.get('score'))): null;
        opp.Margem__c             = mapObjHeader.get('margemAtual')       != null && mapObjHeader.get('margemAtual') != '' ? Decimal.valueOf(String.valueOf(mapObjHeader.get('margemAtual'))): null;
        opp.MargemAlvo__c         = mapObjHeader.get('margemAlvo')        != null && mapObjHeader.get('margemAlvo') != '' ? Decimal.valueOf(String.valueOf(mapObjHeader.get('margemAlvo'))): null;
        opp.AccountId             = mapObjHeader.get('clienteEmissorId')  != null ? String.valueOf(mapObjHeader.get('clienteEmissorId')): null;
        opp.Pricebook2Id          = mapObjHeader.get('tabelaPreco')       != null ? String.valueOf(mapObjHeader.get('tabelaPreco')): null;
        opp.CanalEntrada__c       = mapObjHeader.get('canalEntrada')      != null ? String.valueOf(mapObjHeader.get('canalEntrada')): null;
        opp.CondicaoPagamento__c  = mapObjHeader.get('condicaoPagamento') != null ? String.valueOf(mapObjHeader.get('condicaoPagamento')): null;
        // opp.FormaPagamento__c     = mapObjHeader.get('formaPagamento')    != null ? String.valueOf(mapObjHeader.get('formaPagamento')) == 'Deposito' ? 'Depósito' : 'Boleto' : null;
        opp.FormaPagamento__c     = mapObjHeader.get('formaPagamento')    != null ? String.valueOf(mapObjHeader.get('formaPagamento'))  : null;
        opp.ContatoOrcamento__c   = mapObjHeader.get('contatoOrcamento')  != null ? String.valueOf(mapObjHeader.get('contatoOrcamento')): null;
        opp.PrazoValidade__c      = mapObjHeader.get('prazoValidade')     != null ? Decimal.valueOf(String.valueOf(mapObjHeader.get('prazoValidade'))): null;
        opp.CloseDate             = mapObjHeader.get('dtValidade')        != null ? Date.valueOf(String.valueOf(mapObjHeader.get('dtValidade'))): date.today();
        opp.ObservacoesCliente__c = mapObjHeader.get('observacaoCliente') != null ? String.valueOf(mapObjHeader.get('observacaoCliente')): null;
        opp.Description           = mapObjHeader.get('observacao')        != null ? String.valueOf(mapObjHeader.get('observacao')): null;
        opp.DatasParcelas__c      = mapObjHeader.get('dtList')            != null ? formatInstallmentDates(String.valueOf(mapObjHeader.get('dtList'))) : null;
        opp.Frete__c              = mapObjHeader.get('freteList')         != null ? formatFreightValues(String.valueOf(mapObjHeader.get('freteList'))) : null;
        opp.Idportalcotacoes__c   = mapObjHeader.get('Idportalcotacoes')  != null ? String.valueOf(mapObjHeader.get('Idportalcotacoes')): null;        
        opp.RecomendacaoRespondida__c = mapObjHeader.get('recomendacaoRespondida')  != null ? Boolean.valueOf(mapObjHeader.get('recomendacaoRespondida')): false;        
        // opp.CNPJCD__c             = mapObjHeader.get('cnpjCd')            != null ? String.valueOf(mapObjHeader.get('cnpjCd')) : null;
        opp.RecordTypeId          = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Orcamento').getRecordTypeId();
        opp.NecessitaAprovacaoComercial__c = false;
        opp.NecessitaAprovacaoPricing__c   = false;
        opp.AprovadoComercial__c           = false;
        opp.AprovadoPricing__c             = false;

        return opp;
    }

    public static OpportunityLineItem fillOppLineItemObj(Map<String, Object> mapOppLineItem, Id oppId, Map<String, Set<Id>> setMap, Map<String, Product2> prodMap) {
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        if (mapOppLineItem.get('itemId') != null && String.valueOf(mapOppLineItem.get('itemId')).startsWith('00k')) {
            oppLineItem.Id                = String.valueOf(mapOppLineItem.get('itemId'));
        } else {
            oppLineItem.OpportunityId     = oppId;
            oppLineItem.PricebookEntryId  = String.valueOf(mapOppLineItem.get('id')).substring(0, 18);
            oppLineItem.Product2Id        = String.valueOf(mapOppLineItem.get('prodId'));
        }
        oppLineItem.Lote__c          = String.valueOf(mapOppLineItem.get('lote'));
        oppLineItem.QuantidadeUn__c  = mapOppLineItem.get('quantidade')    != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('quantidade')))    : null;
        oppLineItem.Quantity         = mapOppLineItem.get('quantidadeCx')  != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('quantidadeCx')))  : null;
        oppLineItem.Discount         = mapOppLineItem.get('desconto')      != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('desconto')))      : null;
        oppLineItem.ValorUn__c       = mapOppLineItem.get('unitario')      != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('unitario')))      : null;
        oppLineItem.ValorCx__c       = mapOppLineItem.get('caixa')         != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('caixa')))         : null;
        oppLineItem.ValorMalha__c    = mapOppLineItem.get('precoMalha')    != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('precoMalha')))    : null;
        oppLineItem.ValorSugerido__c = mapOppLineItem.get('precoSugerido') != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('precoSugerido'))) : null;        
        oppLineItem.Range__c         = mapOppLineItem.get('rangeStringify')!= null ? String.valueOf(mapOppLineItem.get('rangeStringify')) : null;
        oppLineItem.ValorTotal__c    = mapOppLineItem.get('valorTotal')    != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('valorTotal')))    : null;
        oppLineItem.TotalPrice       = mapOppLineItem.get('valorTotal')    != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('valorTotal')))    : null;
        oppLineItem.MargemAtual__c   = mapOppLineItem.get('margem')        != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('margem')))        : null;
        oppLineItem.MargemAlvo__c    = mapOppLineItem.get('margemAlvo')    != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('margemAlvo')))    : null;
        oppLineItem.ValidadeMinima__c= mapOppLineItem.get('validadeMinima')!= null ? (String.valueOf(mapOppLineItem.get('validadeMinima')) == 'Shelf Life' || String.valueOf(mapOppLineItem.get('validadeMinima')) == 'Vazio') ? '168' : String.valueOf(mapOppLineItem.get('validadeMinima')) : '168';
         String prodId           = String.valueOf(mapOppLineItem.get('prodId'));
       
        System.debug(setMap);
        System.debug(prodMap.get(prodId));
        System.debug(prodId);
        System.debug(getVendedor(setMap, prodId, prodMap.get(prodId).CategoriaComercial__c, prodMap.get(prodId).Fornecedor__c));
        oppLineItem.Vendedor__c = getVendedor(setMap, prodId, prodMap.get(prodId).CategoriaComercial__c, prodMap.get(prodId).Fornecedor__c);

        oppLineItem.CentroDistribuicao__c = mapOppLineItem.get('cds')        != null ? String.valueOf(mapOppLineItem.get('cds')) : null;        
        oppLineItem.Custo__c         = mapOppLineItem.get('custoCx')         != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('custoCx'))) : null;
        oppLineItem.Imposto__c       = mapOppLineItem.get('aliquota')        != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('aliquota'))) : null;
        system.debug(mapOppLineItem.get('scoreItem'));
        system.debug(mapOppLineItem.get('scoreBU'));
        system.debug(mapOppLineItem.get('scoreMix'));
        oppLineItem.ScoreItem__c     = mapOppLineItem.get('scoreItem')       != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('scoreItem'))) : null;
        oppLineItem.ScoreBU__c       = mapOppLineItem.get('scoreBU')         != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('scoreBU'))) : null;
        oppLineItem.ScoreMix__c      = mapOppLineItem.get('scoreMix')        != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('scoreMix'))) : null;
        oppLineItem.PosicaoItem__c   = mapOppLineItem.get('indexPosition')   != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('indexPosition'))) : null;
        oppLineItem.PosicaoInsercao__c = mapOppLineItem.get('indexInsertPosition')   != null ? Decimal.valueOf(String.valueOf(mapOppLineItem.get('indexInsertPosition'))) : null;
        oppLineItem.CNPJCD__c        = mapOppLineItem.get('cnpjCd')          != null ? String.valueOf(mapOppLineItem.get('cnpjCd')) : null;
        oppLineItem.ForaMalha__c     = mapOppLineItem.get('foraMalha')       != null ? Boolean.valueOf(mapOppLineItem.get('foraMalha')) : null;
        oppLineItem.SequenciaOC__c   = mapOppLineItem.get('SequenciaOC')     != null ? String.valueOf(mapOppLineItem.get('SequenciaOC')) : null; 
        oppLineItem.BloqueadoRegionalizacao__c = mapoppLineItem.get('bloqRegionalizacao') != null ? Boolean.valueOf(mapoppLineItem.get('bloqRegionalizacao')) : false;
        oppLineItem.CampanhaShelfLife__c = mapoppLineItem.get('showBadgeShelflifeCNPJ') != null ? Boolean.valueOf(mapoppLineItem.get('showBadgeShelflifeCNPJ')) : false;
        oppLineItem.CampanhaShelfLifeAux__c = mapoppLineItem.get('showBadgeShelflifeCNPJAux') != null ? Boolean.valueOf(mapoppLineItem.get('showBadgeShelflifeCNPJAux')) : false;
        oppLineItem.ProdutoCampanha__c = mapoppLineItem.get('isInCampaign') != null ? Boolean.valueOf(mapoppLineItem.get('isInCampaign')) : false;
        oppLineItem.ObservacoesComercial__c = mapOppLineItem.get('observacaoComercial"')!= null ? String.valueOf(mapOppLineItem.get('observacaoComercial"')) : null;
        
        return oppLineItem;
    }

    public static String formatFreightValues(String freightValues) {
        return String.join(freightValues.remove('[').remove(']').remove('"').split(','), ', ');
    }

    public static String formatInstallmentDates(String installmentDates) {
        List<String> listInstallmentDates = installmentDates.remove('[').remove(']').remove('"').split(',');
        List<String> listDatesToJoin = new List<String>();
        for (String dates : listInstallmentDates) {
            List<String> splittedDate = dates.split('-');
            listDatesToJoin.add(splittedDate[2].trim() + '/' + splittedDate[1].trim() + '/' + splittedDate[0].trim());
        }
        
        return String.join(listDatesToJoin, ', ');
    }

    public static String reformatInstallmentDates(String installmentDates) {
        List<String> listInstallmentDates = installmentDates.split(',');
        List<String> listDatesToJoin = new List<String>();
        for (String dates : listInstallmentDates) {
            List<String> splittedDate = dates.split('/');
            listDatesToJoin.add(splittedDate[2].trim() + '-' + splittedDate[1].trim() + '-' + splittedDate[0].trim());
        }
        
        return String.join(listDatesToJoin, ', ');
    }

    @AuraEnabled
    public static List<ProductData> getRecommendations(RecommendationContextRecordData contextRecordData) {
        GeneralParameters__c parameters = GeneralParameters__c.getValues('Parametro geral');
        Set<String> recommendedExternalIds = new Set<String>();
        Map<Id, RecommendationsService.RecommendationData> mapRecommendedProducts = 
            new Map<Id, RecommendationsService.RecommendationData>();
        
        List<RecommendationsService.RecommendationData> recommendations = 
            RecommendationsService.getRecommendations(contextRecordData.contextRecordId, Integer.valueOf(parameters.QuantidadeProdutosRecomendados__c));

        for (RecommendationsService.RecommendationData currentRecommendation : recommendations) {
            if (!contextRecordData.currentProducts.contains(currentRecommendation.externalId)) {
                recommendedExternalIds.add(currentRecommendation.externalId);
                mapRecommendedProducts.put(
                    currentRecommendation.externalId, 
                    currentRecommendation
                );
            }
        }

        List<ProductData> products = getRecommendedProductsDataByExternalIds(
            contextRecordData.pricebookId, 
            recommendedExternalIds,
            contextRecordData.accountId,
            contextRecordData.condPag
        );

        for (ProductData currProduct : products) {
            Id currProdId = currProduct.id;
            if (mapRecommendedProducts.containsKey(currProdId)) {
                RecommendationsService.RecommendationData recommendedProduct = mapRecommendedProducts.get(currProdId);
                currProduct.targetId         = recommendedProduct.targetId;
                currProduct.targetActionId   = recommendedProduct.targetActionId;
                currProduct.targetActionName = recommendedProduct.targetActionName;
            }
        }

        return products;
    }

    public static List<ProductData> getRecommendedProductsDataByExternalIds(String pricebook2Id, Set<String> productIds, String accountId, String condPag) {
        List<ProductData> products = new List<ProductData>();
        
        List<PricebookEntry> entries = [
            SELECT
                Id,
                UnitPrice,
                PrecoFabrica__c,
                Product2Id,
                Product2.ExternalId__c,
                Product2.ProductCode,
                Product2.TipoConversao__c,
                Product2.UnidadeMedida__c,
                Product2.SegundaUnidade__c,
                Product2.DescricaoTecnica__c,
                Product2.Name	,
                Product2.Description	,
                Product2.NumeroAnvisa__c,
                Product2.CategoriaComercial__c,
                Product2.Temperatura__c,
                Product2.EANProduto__c,
                Product2.FatorConversao__c,
                Product2.Fornecedor__r.Name
            FROM PricebookEntry 
            WHERE Pricebook2Id =: pricebook2Id
            AND Product2Id IN: productIds
        ];

        Map<String, Decimal> mapStockByProductId = getMapStockByProductIds(productIds);
        map<String,ProductData> mapProd = new map<String,ProductData>();
        Set<String> setProductId = new Set<String>();

        for (PricebookEntry currPricebookEntry: entries) {
            setProductId.add(currPricebookEntry.Product2Id);
        }

        mapProd = getContractCampaign(setProductId, accountId, condPag);

        for (PricebookEntry currPricebookEntry : entries) {
            Decimal fatVal = checkAnyFieldIsNull(currPricebookEntry.Product2.FatorConversao__c) ? 0 : Decimal.valueOf(currPricebookEntry.Product2.FatorConversao__c) == 0 ? 1 : Decimal.valueOf(currPricebookEntry.Product2.FatorConversao__c); 
            ProductData product = mapProd.containsKey(currPricebookEntry.Product2Id) ? mapProd.get(currPricebookEntry.Product2Id) : new ProductData();
            product.id = currPricebookEntry.Product2Id;
            product.code = currPricebookEntry.Product2.ExternalId__c;

            product.precoTabelaCx = product.precoTabelaCx > 0 ? product.precoTabelaCx : currPricebookEntry.UnitPrice;
            product.precoFabricaCx = (currPricebookEntry.PrecoFabrica__c == null || currPricebookEntry.PrecoFabrica__c == 0) ? currPricebookEntry.UnitPrice : currPricebookEntry.PrecoFabrica__c;
            product.unidadeSec = true;
            if(currPricebookEntry.Product2.UnidadeMedida__c == currPricebookEntry.Product2.SegundaUnidade__c){
                product.unidadeSec = false;
            }else if(currPricebookEntry.Product2.SegundaUnidade__c == '0' || currPricebookEntry.Product2.SegundaUnidade__c == null){
                product.unidadeSec = false;
            }else if(currPricebookEntry.Product2.TipoConversao__c == '0' || currPricebookEntry.Product2.TipoConversao__c == null){
                product.unidadeSec = false;
            }else if(fatVal == 0 || fatVal == null){
                product.unidadeSec = false;
            }
            product.verMargem = false;
            product.pbEntryId = currPricebookEntry.Id;
            product.tipoConversao = currPricebookEntry.Product2.TipoConversao__c;
            product.unidadePrincipal = currPricebookEntry.Product2.UnidadeMedida__c;
            product.unidadeSecundaria = currPricebookEntry.Product2.SegundaUnidade__c;
            product.descTecnica = currPricebookEntry.Product2.DescricaoTecnica__c;
            product.nome = currPricebookEntry.Product2.Name;
            product.principioAtivo = currPricebookEntry.Product2.Description;
            product.fabricante = currPricebookEntry.Product2.Fornecedor__r.Name;
            product.anvisa = currPricebookEntry.Product2.NumeroAnvisa__c;
            product.categoria = currPricebookEntry.Product2.CategoriaComercial__c;
            // product.categoriaCompleta = ;
            // product.categoriaDesc = ;
            product.temperatura = currPricebookEntry.Product2.Temperatura__c;
            product.ean = currPricebookEntry.Product2.EANProduto__c;
            product.fatorConversao = fatVal == 0 ? '1' : String.valueOf(fatVal);

            if (mapStockByProductId.containsKey(currPricebookEntry.Product2Id)) {
                product.estoque = (Integer)mapStockByProductId.get(currPricebookEntry.Product2Id);
            }

            products.add(product);
        }

        return products;
    }

    public static Map<String, Decimal> getMapStockByProductIds(Set<String> productIds) {
        AggregateResult[] stockResults = [
            SELECT 
                NomeProduto__c, 
                sum(Saldo__c) saldo
            FROM Estoque__c 
            WHERE NomeProduto__c IN: productIds
            GROUP BY NomeProduto__c
        ];
    
        Map<String, Decimal> mapStockByProductId = new Map<String, Decimal>();
    
        for (AggregateResult stockAr : stockResults) {
            mapStockByProductId.put(
                (String)stockAr.get('NomeProduto__c'),
                (Decimal)stockAr.get('saldo')
            );
        }
    
        return mapStockByProductId;
    }

    @AuraEnabled
    public static void setRecommendationReaction(RecommendationReactionData reactionData) {
        system.debug('reactionData: ' + reactionData);
        RecommendationsService.ReactionDataInput reactionInput = 
            new RecommendationsService.ReactionDataInput();

        reactionInput.externalId = reactionData.externalId;
        reactionInput.targetId = reactionData.targetId;
        reactionInput.targetActionId = reactionData.targetActionId;
        reactionInput.targetActionName = reactionData.targetActionName;
        reactionInput.contextRecordId = reactionData.contextRecordId;
        reactionInput.reaction = reactionData.reaction;
        reactionInput.reactionOption = reactionData.reactionOption;
        reactionInput.reactionMessage = reactionData.reactionMessage;

        RecommendationsService.setReaction(reactionInput);
    }

    public class RecommendationContextRecordData {
        @AuraEnabled public String contextRecordId {get;set;}
        @AuraEnabled public List<String> currentProducts {get;set;}
        @AuraEnabled public String pricebookId {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String condPag {get;set;}
    }

    public class RecommendationReactionData {
        @AuraEnabled public String externalId {get;set;}
        @AuraEnabled public String targetId {get;set;}
        @AuraEnabled public String targetActionId {get;set;}
        @AuraEnabled public String targetActionName {get;set;}
        @AuraEnabled public String contextRecordId {get;set;}
        @AuraEnabled public String reaction {get;set;}
        @AuraEnabled public String reactionMessage {get;set;}
        @AuraEnabled public String reactionOption {get;set;}
    }

    global class MalhaRequest {
        public String CgcCliente;
        public String uf;
        public String TabelaPreco;
        public Boolean ForaMalha;
        public Boolean CalculaMargem;
        public Boolean ConsultaEstoque;
        public Boolean ValidaRegionalizacao;
        public String CondicaoPagamento;
        public List<ProductCode> produtos;
        
        public MalhaRequest (String clienteCgc, String uf, list<String> foraMalha, list<ProductCode> listProductCode, Boolean calcMargem, String pricebookExternalId, String condPagamento, Boolean isForaMalha, Boolean ValidaRegionalizacao ){
            this.CgcCliente      = clienteCgc;
            this.uf              = uf;
            this.TabelaPreco     = pricebookExternalId == null ? '' : pricebookExternalId;
            this.ForaMalha       = isForaMalha;
            this.CalculaMargem   = calcMargem;
            this.ConsultaEstoque = (ValidaRegionalizacao == false && TabelaPreco == '' && CalculaMargem == false) ? false : true;
            this.ValidaRegionalizacao = ValidaRegionalizacao;
            this.CondicaoPagamento = condPagamento;
            this.produtos        = listProductCode;
        }
    }

    global class ProductCode {
        public String produto;
        
        public ProductCode (String codigoProduto){
            this.produto = codigoProduto; 
        }
    }

    global class LoteRequest {
        public String cnpj;
        public String produto;
        
        public LoteRequest (String clienteCgc, String productCode) {
            cnpj    = clienteCgc;
            produto = productCode;
        }
    }

    public class MapIdToPaymentConditionName {
        @AuraEnabled public Map<Id, String> MapCondIdToCondName {get; set;}

        public MapIdToPaymentConditionName(Map<Id, String> mapCondPag) {
            this.MapCondIdToCondName = mapCondPag;
        }
    }

    // public class PricebookData {
    //     @AuraEnabled public Pricebook2 pb2 {get; set;}
    // }

    public class BudgetData {
        @AuraEnabled public String NumOrcamento          {get; set;}
        @AuraEnabled public Decimal ValorTotal           {get; set;}
        @AuraEnabled public Decimal Score                {get; set;}
        @AuraEnabled public Decimal Margem               {get; set;}
        @AuraEnabled public Decimal MargemAlvo           {get; set;}
        @AuraEnabled public String ClienteEmissor        {get; set;}
        @AuraEnabled public String ClienteEmissorId      {get; set;}
        @AuraEnabled public String ClienteEmissorCGC     {get; set;}
        @AuraEnabled public String TabelaPreco           {get; set;}
        @AuraEnabled public String TabelaPrecoNome       {get; set;}
        @AuraEnabled public String CanalEntrada          {get; set;}
        @AuraEnabled public String CondicaoPagamento     {get; set;}
        @AuraEnabled public String CondicaoPagamentoNome {get; set;}
        @AuraEnabled public String NomeCondPagamento     {get; set;}
        @AuraEnabled public String FormaPagamento        {get; set;}
        @AuraEnabled public String GeraBoleto            {get; set;}
        @AuraEnabled public String ContatoOrcamento      {get; set;}
        @AuraEnabled public String AccountContactRelationId {get; set;}
        @AuraEnabled public Decimal PrazoValidade        {get; set;}
        @AuraEnabled public Date DataValidade            {get; set;}
        @AuraEnabled public String ObservacaoCliente     {get; set;}
        @AuraEnabled public String Observacao            {get; set;}
        @AuraEnabled public String StageName             {get; set;}
        @AuraEnabled public String motivoExpirado        {get; set;}
        @AuraEnabled public Boolean ContemDocAlvaraCrt   {get; set;}
        @AuraEnabled public Boolean DocumentosValidos    {get; set;}
        @AuraEnabled public Boolean ClienteBloqueado     {get; set;}
        @AuraEnabled public Boolean BloqueioFinanceiro   {get; set;}
        @AuraEnabled public Boolean IsCoordenador        {get; set;}
        @AuraEnabled public Boolean isVansOrder          {get; set;}
        @AuraEnabled public String DtParcelas            {get; set;}
        @AuraEnabled public String FretesPorCd           {get; set;}
        @AuraEnabled public String Idportalcotacoes      {get; set;}
        @AuraEnabled public Boolean allRecAnswered       {get; set;}
        @AuraEnabled public Boolean hasPermissionERB     {get; set;}
        @AuraEnabled public List<BudgetItemData> Itens   {get; set;}

        @AuraEnabled public EnderecoCobranca enderecoCobranca;

        public BudgetData (Opportunity opp, Account acc){
            if (opp != null) {
                this.NumOrcamento          = opp.NumeroOrcamento__c;
                this.StageName             = opp.StageName;
                this.motivoExpirado        = opp.MotivoCancelamento__c;
                this.ValorTotal            = opp.Amount;
                this.Score                 = opp.Score__c;
                this.ClienteEmissor        = opp.Account?.Name;
                this.ClienteEmissorId      = opp.AccountId;
                this.ClienteEmissorCGC     = opp.CNPJ__c == null ? opp.CPF__c : opp.CNPJ__c; 
                this.TabelaPreco           = opp.Pricebook2Id != null ? opp.Pricebook2Id : opp.Account?.TabelaPrecos__c;
                this.TabelaPrecoNome       = opp.Pricebook2Id != null ? opp.Pricebook2.Name : opp.Account?.TabelaPrecos__r?.Name;
                this.CanalEntrada          = opp.CanalEntrada__c;
                this.ContatoOrcamento      = opp.ContatoOrcamento__c;
                this.CondicaoPagamento     = opp.CondicaoPagamento__c;
                this.CondicaoPagamentoNome = opp.CondicaoPagamento__r?.Name;
                this.FormaPagamento        = opp.FormaPagamento__c;
                this.PrazoValidade         = opp.PrazoValidade__c;
                this.DataValidade          = opp.CloseDate;
                this.ObservacaoCliente     = opp.Account?.Observacoes__c;
                this.Observacao            = opp.Description;
                this.DtParcelas            = opp.DatasParcelas__c != null ? reformatInstallmentDates(opp.DatasParcelas__c) : null;
                system.debug(this.DtParcelas);
                this.FretesPorCd           = opp.Frete__c;
                this.ClienteBloqueado      = opp.Account?.Bloqueado__c == 'Ativo' ? true : false;
                this.BloqueioFinanceiro    = (opp.Account?.Saldo__c <= 0 || (opp.Account?.GrauRisco__c != 'A' && opp.Account?.GrauRisco__c != 'B')) ? true : false;
                this.IsCoordenador         = UserInfo.getUserRoleId() != 'Coord' ? true : false;
                if(opp.Account.GeraBoleto__c){
                  this.GeraBoleto          = 'Boleto';
                }else{
                  this.GeraBoleto          = 'Carteira';
                }
                this.Idportalcotacoes = opp.Idportalcotacoes__c;
                this.allRecAnswered   = opp.RecomendacaoRespondida__c;
                this.enderecoCobranca = new EnderecoCobranca();
                this.enderecoCobranca.RuaCobranca = opp.Account.BillingStreet;
                this.enderecoCobranca.CidadeCobranca = opp.Account.BillingCity;
                this.enderecoCobranca.EstadoCobranca = opp.Account.BillingState;
                this.enderecoCobranca.PaisCobranca = opp.Account.BillingCountry;
                this.enderecoCobranca.CEPCobranca = opp.Account.BillingPostalCode;
            } else {                
                this.ClienteEmissor        = acc.Name;
                this.ClienteEmissorId      = acc.Id;
                this.ClienteEmissorCGC     = acc.CNPJ__c == null ? acc.CPF__c : acc.CNPJ__c;
                this.TabelaPreco           = acc.TabelaPrecos__c;
                this.TabelaPrecoNome       = acc.TabelaPrecos__r?.Name;
                this.CondicaoPagamento     = acc.CondicaoPagamento__c;
                this.CondicaoPagamentoNome = acc.CondicaoPagamento__r?.Name;
                this.FormaPagamento        = acc.FormaPagamento__c;
                if(acc.GeraBoleto__c){
                  this.GeraBoleto          = 'Boleto';
                }else{
                  this.GeraBoleto          = 'Carteira';
                }
                this.ObservacaoCliente     = acc.Observacoes__c;
                this.ClienteBloqueado      = acc.Bloqueado__c == 'Ativo' ? true : false;
                this.BloqueioFinanceiro    = (acc.Saldo__c <= 0 || (acc.GrauRisco__c != 'A' && acc.GrauRisco__c != 'B')) ? true : false;
                this.IsCoordenador         = UserInfo.getUserRoleId() != 'Coord' ? true : false;
                // this.Observacao    => preenchido na tela
                // this.CanalEntrada  => preenchido na tela
                // this.PrazoValidade => preenchido na tela
                // this.DataValidade  => preenchido na tela
            }
        }
    }

    public class BudgetItemData {
        @AuraEnabled public String id                        {get; set;}
        @AuraEnabled public String cdId                      {get; set;}
        @AuraEnabled public String itemId                    {get; set;}
        @AuraEnabled public String pbEntryId                 {get; set;}
        @AuraEnabled public String prodId                    {get; set;}
        @AuraEnabled public String prodCode                  {get; set;}
        @AuraEnabled public String nome                      {get; set;}
        @AuraEnabled public String principioAtivo            {get; set;}
        @AuraEnabled public String fabricante                {get; set;}
        @AuraEnabled public String anvisa                    {get; set;}
        @AuraEnabled public String categoria                 {get; set;}
        @AuraEnabled public String precoFabricaCx            {get; set;}
        @AuraEnabled public String precoFabricaUn            {get; set;}
        @AuraEnabled public String precoTabelaCx             {get; set;}
        @AuraEnabled public String precoTabelaUn             {get; set;}
        @AuraEnabled public String temperatura               {get; set;}
        @AuraEnabled public String ean                       {get; set;}
        @AuraEnabled public String index                     {get; set;}
        @AuraEnabled public String cds                       {get; set;}
        @AuraEnabled public String cnpjCd                    {get; set;}
        @AuraEnabled public String lote                      {get; set;}
        @AuraEnabled public String listTagByCd               {get; set;}
        @AuraEnabled public Decimal estoque                  {get; set;}
        @AuraEnabled public Decimal estoqueUn                {get; set;}
        @AuraEnabled public String un                        {get; set;}
        @AuraEnabled public Decimal quantidade               {get; set;}
        @AuraEnabled public Decimal quantidadeCx             {get; set;}
        @AuraEnabled public String unitario                  {get; set;}
        @AuraEnabled public String caixa                     {get; set;}
        @AuraEnabled public String inicialUnitario           {get; set;}
        @AuraEnabled public String inicialCaixa              {get; set;}
        @AuraEnabled public String conversaoUnidadeCx        {get; set;}
        @AuraEnabled public Decimal desconto                 {get; set;}
        @AuraEnabled public Decimal valorTotalUnd            {get; set;}
        @AuraEnabled public Decimal valorTotalCx             {get; set;}
        @AuraEnabled public Decimal valorTotal               {get; set;}
        @AuraEnabled public Decimal aliquota                 {get; set;}
        @AuraEnabled public Decimal score                    {get; set;}
        @AuraEnabled public Decimal scoreBU                  {get; set;}
        @AuraEnabled public Decimal scoreMix                 {get; set;}
        @AuraEnabled public Decimal scoreItem                {get; set;}
        @AuraEnabled public Decimal indexPosition            {get; set;}
        @AuraEnabled public Decimal indexInsertPosition      {get; set;}
        @AuraEnabled public Decimal custoDif                 {get; set;}
        @AuraEnabled public Decimal custoCx                  {get; set;}
        @AuraEnabled public Decimal margem                   {get; set;}
        @AuraEnabled public Decimal margemAlvo               {get; set;}
        @AuraEnabled public Decimal margemAlvoInput          {get; set;}
        @AuraEnabled public String validadeMinima            {get; set;}
        @AuraEnabled public Boolean foraMalha                {get; set;}
        @AuraEnabled public Decimal precoMalha               {get; set;}
        @AuraEnabled public Decimal precoSugerido            {get; set;}
        @AuraEnabled public String laboratorio               {get; set;}
        @AuraEnabled public String tipoIntegradora           {get; set;}
        @AuraEnabled public String rangeStringify            {get; set;}
        @AuraEnabled public Boolean bloqRegionalizacao       {get; set;}
        @AuraEnabled public Boolean isInCampaign             {get; set;}
        @AuraEnabled public Boolean showBadgeOL              {get; set;}
        @AuraEnabled public Boolean showBadgeCampanha        {get; set;}
        @AuraEnabled public Boolean showBadgeCampanhaVendedor {get; set;}
        @AuraEnabled public Boolean showBadgeCampanhaCD      {get; set;}
        @AuraEnabled public Boolean showBadgeConsignado      {get; set;}
        @AuraEnabled public Boolean showBadgeAcordoComercial {get; set;}
        @AuraEnabled public Boolean showBadgeshelflife       {get; set;}
        @AuraEnabled public Boolean valorBloqueado           {get; set;}
        @AuraEnabled public String unidadePrincipal          {get; set;}
        @AuraEnabled public Boolean verMargem                {get; set;}
        @AuraEnabled public String SequenciaOC               {get; set;}
        @AuraEnabled public String precoCNPJCampanha         {get; set;}
        @AuraEnabled public String precoCNPJShelflife        {get; set;}
        @AuraEnabled public String unidadeMedida             {get; set;}
        @AuraEnabled public String unidadeMedidaSeg          {get; set;}
        @AuraEnabled public String unidadeSecundaria         {get; set;}
        @AuraEnabled public String observacaoComercial {get; set;}

        public BudgetItemData() {}
    }

    public class AccountCGCData {
        @AuraEnabled public String accId  {get; set;}
        @AuraEnabled public String accCGC {get; set;}

        public AccountCGCData(Id accId, String cgc) {
            this.accId = accId;
            this.accCGC = cgc;
        }
    }

    public class AccountData {
        @AuraEnabled public String ClienteEmissor        {get; set;}
        @AuraEnabled public String ClienteEmissorId      {get; set;}
        @AuraEnabled public String ClienteEmissorCGC     {get; set;}
        @AuraEnabled public String Medico                {get; set;}
        @AuraEnabled public String MedicoId              {get; set;}
        @AuraEnabled public String MedicoCRM             {get; set;}
        @AuraEnabled public String TabelaPreco           {get; set;}
        @AuraEnabled public String TabelaPrecoNome       {get; set;}
        @AuraEnabled public String CondicaoPagamento     {get; set;}
        @AuraEnabled public String CondicaoPagamentoNome {get; set;}
        @AuraEnabled public String ContatoOrcamento      {get; set;}
        @AuraEnabled public String AccountContactRelationId {get; set;}
        @AuraEnabled public String TipoFrete             {get; set;}
        @AuraEnabled public String FormaPagamento        {get; set;}
        @AuraEnabled public String GeraBoleto            {get; set;}
        @AuraEnabled public String Observacao            {get; set;}
        @AuraEnabled public Boolean ContemDocAlvaraCrt   {get; set;}
        @AuraEnabled public Boolean DocumentosValidos    {get; set;}
        @AuraEnabled public Boolean ClienteBloqueado     {get; set;}
        @AuraEnabled public Boolean BloqueioFinanceiro   {get; set;}
        @AuraEnabled public String EnderecoEntregaId     {get; set;}
        @AuraEnabled public String EstadoCliente         {get; set;}
        @AuraEnabled public Boolean hasPermissionERB     {get; set;}
	@AuraEnabled public String observacaoComercial {get; set;}

        @AuraEnabled public EnderecoCobranca enderecoCobranca;

        public AccountData(Account acc, Id accountContactRelationId, Id contactId) {
            this.ClienteEmissor            = acc.Name;
            this.ClienteEmissorId          = acc.Id;
            this.ClienteEmissorCGC         = acc.CNPJ__c == null ? acc.CPF__c : acc.CNPJ__c;
            this.Medico                    = acc.Name;
            this.MedicoId                  = acc.Id;
            this.MedicoCRM                 = acc.NumeroRegistro__c;
            this.TabelaPreco               = acc.TabelaPrecos__c;
            this.TabelaPrecoNome           = acc.TabelaPrecos__r?.Name;
            this.CondicaoPagamento         = acc.CondicaoPagamento__c;
            this.CondicaoPagamentoNome     = acc.CondicaoPagamento__r?.Name;
            this.ContatoOrcamento          = contactId;
            this.AccountContactRelationId  = accountContactRelationId;
            this.TipoFrete                 = acc.TipoFrete__c;
            this.FormaPagamento            = acc.FormaPagamento__c;
            this.Observacao                = acc.Observacoes__c;
            this.ClienteBloqueado          = acc.Bloqueado__c == 'Ativo' ? true : false;
            this.BloqueioFinanceiro        = (acc.Saldo__c <= 0 || (acc.GrauRisco__c != 'A' && acc.GrauRisco__c != 'B')) ?true : false;
            this.EstadoCliente             = acc.BillingState;
            if(acc.GeraBoleto__c){
                this.GeraBoleto          = 'Boleto';
            }else{
                this.GeraBoleto          = 'Carteira';
            }

            this.enderecoCobranca = new EnderecoCobranca();
            this.enderecoCobranca.RuaCobranca = acc.BillingStreet;
            this.enderecoCobranca.CidadeCobranca = acc.BillingCity;
            this.enderecoCobranca.EstadoCobranca = acc.BillingState;
            this.enderecoCobranca.PaisCobranca = acc.BillingCountry;
            this.enderecoCobranca.CEPCobranca = acc.BillingPostalCode;
        }
    }

    public class EnderecoCobranca {
        @AuraEnabled public String RuaCobranca;
        @AuraEnabled public String CidadeCobranca;
        @AuraEnabled public String EstadoCobranca;
        @AuraEnabled public String PaisCobranca;
        @AuraEnabled public String CEPCobranca;
    }
    
    @AuraEnabled(cacheable=true)
    public static list<HistoricData> getHistorico(String clienteId, String prodId){
        list<HistoricData> lprod = new list<HistoricData>();
        List<Account> lAccount = new List<Account>();
        Account acc = new Account();
        acc = [SELECT Id, CodigoGrupoClientes__c FROM Account WHERE Id =: clienteId ];
        if(acc == null){
            return null ;
        }
        Decimal contador = 0;
        if(acc.CodigoGrupoClientes__c != null){
            for(OrderItem pedido : [SELECT Id, Order.CreatedDate , UnitPrice, Quantity, Order.Status , Order.Account.CodigoCliente__c, 
                                            Order.Account.Name, CentroDistribuicao__c,OrderId,
                                            Order.OrderNumber, Order.Margem__c,Product2.UnidadeMedida__c, Margem__c
                                    FROM OrderItem 
                                    WHERE Product2Id =: prodId 
                                    AND Order.AccountId != null
                                    AND Order.Account.CodigoCliente__c != null
                                    AND Order.Account.Name != null
                                    AND Order.Account.CodigoGrupoClientes__c =: acc.CodigoGrupoClientes__c ORDER BY Order.CreatedDate DESC ]){
                HistoricData HistoricData = new HistoricData();
                HistoricData.dataPedido = Date.valueOf(pedido.Order.CreatedDate);
                HistoricData.Id = pedido.Id;
                HistoricData.codNomeCli = pedido.Order.Account.CodigoCliente__c + ' - ' + pedido.Order.Account.Name;
                HistoricData.pedidoId = pedido.OrderId;
                HistoricData.vlrUnitatio = pedido.UnitPrice;
                HistoricData.nroPedido = pedido.Order.OrderNumber;
                HistoricData.undMedida = pedido.Product2.UnidadeMedida__c;
                HistoricData.margemPrd = pedido.Margem__c;
                HistoricData.margemPedido = pedido.Order.Margem__c;
                HistoricData.qtd = pedido.Quantity;
                HistoricData.status = pedido.Order.Status;
                HistoricData.centroDistribuicao = pedido.CentroDistribuicao__c;
                lprod.add(HistoricData);
                // contador = contador + 1;
            }
            // if(contador < 6){
                for(OpportunityLineItem orcamento : [SELECT Id, Opportunity.CreatedDate ,UnitPrice, Quantity, Opportunity.StageName, CentroDistribuicao__c, Opportunity.Account.CodigoCliente__c, Opportunity.Account.Name,
                                                    Opportunity.NumeroOrcamento__c, Opportunity.Margem__c, MargemAlvo__c, Product2.UnidadeMedida__c, OpportunityId
                                                    FROM OpportunityLineItem 
                                                    WHERE Product2Id =: prodId
                                                    AND Opportunity.AccountId != null
                                                    AND Opportunity.Account.CodigoCliente__c != null
                                                    AND Opportunity.Account.Name != null
                                                    AND  Opportunity.Account.CodigoGrupoClientes__c =: acc.CodigoGrupoClientes__c ORDER BY Opportunity.CreatedDate DESC ]){
                    HistoricData HistoricData = new HistoricData();
                    HistoricData.dataPedido = Date.valueOf(orcamento.Opportunity.CreatedDate) ;
                    HistoricData.Id = orcamento.Id;
                    HistoricData.codNomeCli = orcamento.Opportunity.Account.CodigoCliente__c + ' - ' +  orcamento.Opportunity.Account.Name;
                    HistoricData.pedidoId = orcamento.OpportunityId;
                    HistoricData.vlrUnitatio = orcamento.UnitPrice;
                    HistoricData.nroPedido = orcamento.Opportunity.NumeroOrcamento__c;
                    HistoricData.undMedida = orcamento.Product2.UnidadeMedida__c;
                    HistoricData.margemPrd = orcamento.MargemAlvo__c;
                    HistoricData.margemPedido = orcamento.Opportunity.Margem__c;
                    HistoricData.qtd = orcamento.Quantity;
                    HistoricData.status = orcamento.Opportunity.StageName;
                    HistoricData.centroDistribuicao = orcamento.CentroDistribuicao__c;
                    lprod.add(HistoricData);
                    // contador = contador + 1;
                    // if(contador == 6){
                    //     break;
                    // }
                }
            // }
        }else{
            for(OrderItem pedido : [SELECT Id, Order.CreatedDate , UnitPrice, Quantity, Order.Status , Order.Account.CodigoCliente__c, 
                                            Order.Account.Name, CentroDistribuicao__c,OrderId,
                                            Order.OrderNumber, Order.Margem__c,Product2.UnidadeMedida__c, Margem__c
                                    FROM OrderItem 
                                    WHERE Product2Id =: prodId 
                                    AND Order.AccountId =: acc.Id
                                    AND Order.Account.CodigoCliente__c != null
                                    AND Order.Account.Name != null
                                    AND Order.Account.CodigoGrupoClientes__c =: acc.CodigoGrupoClientes__c ORDER BY Order.CreatedDate DESC  ]){
                HistoricData HistoricData = new HistoricData();
                HistoricData.dataPedido = Date.valueOf(pedido.Order.CreatedDate);
                HistoricData.Id = pedido.Id;
                HistoricData.codNomeCli = pedido.Order.Account.CodigoCliente__c + ' - ' + pedido.Order.Account.Name;
                HistoricData.pedidoId = pedido.OrderId;
                HistoricData.vlrUnitatio = pedido.UnitPrice;
                HistoricData.nroPedido = pedido.Order.OrderNumber;
                HistoricData.undMedida = pedido.Product2.UnidadeMedida__c;
                HistoricData.margemPrd = pedido.Margem__c;
                HistoricData.margemPedido = pedido.Order.Margem__c;
                HistoricData.qtd = pedido.Quantity;
                HistoricData.status = pedido.Order.Status;
                HistoricData.centroDistribuicao = pedido.CentroDistribuicao__c;
                lprod.add(HistoricData);
                // contador = contador + 1;
            }
            // if(contador < 6){
                for(OpportunityLineItem orcamento : [SELECT Id, Opportunity.CreatedDate ,UnitPrice, Quantity, Opportunity.StageName, CentroDistribuicao__c, Opportunity.Account.CodigoCliente__c, Opportunity.Account.Name,
                                                    Opportunity.NumeroOrcamento__c, Opportunity.Margem__c, MargemAlvo__c, Product2.UnidadeMedida__c, OpportunityId
                                                    FROM OpportunityLineItem 
                                                    WHERE Product2Id =: prodId
                                                    AND Opportunity.AccountId =: acc.Id
                                                    AND Opportunity.Account.CodigoCliente__c != null
                                                    AND Opportunity.Account.Name != null
                                                    AND  Opportunity.Account.CodigoGrupoClientes__c =: acc.CodigoGrupoClientes__c ORDER BY Opportunity.CreatedDate DESC  ]){
                    HistoricData HistoricData = new HistoricData();
                    HistoricData.dataPedido = Date.valueOf(orcamento.Opportunity.CreatedDate) ;
                    HistoricData.Id = orcamento.Id;
                    HistoricData.codNomeCli = orcamento.Opportunity.Account.CodigoCliente__c + ' - ' +  orcamento.Opportunity.Account.Name;
                    HistoricData.pedidoId = orcamento.OpportunityId;
                    HistoricData.vlrUnitatio = orcamento.UnitPrice;
                    HistoricData.nroPedido = orcamento.Opportunity.NumeroOrcamento__c;
                    HistoricData.undMedida = orcamento.Product2.UnidadeMedida__c;
                    HistoricData.margemPrd = orcamento.MargemAlvo__c;
                    HistoricData.margemPedido = orcamento.Opportunity.Margem__c;
                    HistoricData.qtd = orcamento.Quantity;
                    HistoricData.status = orcamento.Opportunity.StageName;
                    HistoricData.centroDistribuicao = orcamento.CentroDistribuicao__c;
                    lprod.add(HistoricData);
                    // contador = contador + 1;
                    // if(contador == 6){
                    //     break;
                    // }
                }
            // }
        }
        if(!lprod.isEmpty()){
            for(integer i = 0; i < lprod.size(); i++) {
                for (integer x = i; x < lprod.size(); x++) {
                    if(lprod[i].dataPedido < lprod[x].dataPedido){
                        HistoricData HistoricData = new HistoricData();
                        HistoricData = lprod[i];
                        lprod[i] = lprod[x];
                        lprod[x] = HistoricData;
                    }
                }
            }
        }
        return lprod;
    }
    public class HistoricData {
		@AuraEnabled public Date dataPedido;	
		@AuraEnabled public String Id;	
		@AuraEnabled public String orcamentoId;	
		@AuraEnabled public String pedidoId;	
		@AuraEnabled public String codNomeCli;	
		@AuraEnabled public String nroPedido;	
		@AuraEnabled public Decimal vlrUnitatio;	
		@AuraEnabled public Decimal qtd;	
		@AuraEnabled public String undMedida;	
		@AuraEnabled public String status;	
		@AuraEnabled public Decimal margemPrd;	
		@AuraEnabled public Decimal margemPedido;	
		@AuraEnabled public String centroDistribuicao;
    }
    @AuraEnabled(cacheable=true)
    public static String lockScreen(String servico, String OrcPedId){
        String mensagens = '';
        list<Order> lpedido = new list<Order>();
        lpedido = [SELECT Id, Status FROM Order WHERE Id =:OrcPedId ];
        if(!lpedido.isEmpty()){
            if(lpedido[0].Status != 'Novo' && lpedido[0].Status != 'Em digitação' ){
                mensagens = 'Não é possivel alterar um Pedido que esta com o status diferente de Em Digitação';
            }
        }else{
            list<Opportunity> lopp = new list<Opportunity>();
            lopp = [SELECT Id, StageName FROM Opportunity WHERE Id =:OrcPedId];
            if(!lopp.isEmpty()){
                if(lopp[0].StageName == 'Fechado/Gerado' ){
                    mensagens = 'Não é possivel alterar um Orçamento que esta com o status igual a Fechado/Gerado';
                }
            }
        }

        return mensagens;
    }

    @AuraEnabled(cacheable=true)
    public static ReturnObjGetProduct getProduct(String pricebook, String clienteId, String offSetValue, String searchGenericValue, String searchFabricanteValue, String condPag, Boolean isCampaign, List<String> prodList){
        system.debug('searchGenericValue: ' + searchGenericValue);
        searchGenericValue = searchGenericValue.replaceAll(' ', '%');
        searchFabricanteValue = searchFabricanteValue.replaceAll(' ', '%');
        system.debug('searchFabricanteValue: ' + searchFabricanteValue);
        list<ProductData> lprod = new list<ProductData>();
        User usuario = [SELECT CompanyName, UserRoleId FROM User WHERE Id =: UserInfo.getUserId() ];
        Group papel = new Group();
        papel = [SELECT RelatedId, DeveloperName FROM Group WHERE RelatedId =: usuario.UserRoleId limit 1];
        isCampaign = isCampaign == null ? false : isCampaign;

        string query = '';
        query = 'SELECT Id,PrecoFabrica__c, UnitPrice, Product2.Temperatura__c, Product2.CategoriaComercial__c,Product2Id, Product2.NumeroAnvisa__c, Product2.DescricaoTecnica__c, Product2.UnidadeMedida__c, Product2.SegundaUnidade__c, '
           + 'Product2.Fornecedor__r.Name, Product2.ProductCode,Product2.EANProduto__c, Product2.FatorConversao__c, Product2.ProductCodeElfa__c, Product2.Name, Product2.Description, Product2.TipoConversao__c ' 
           + 'FROM PricebookEntry WHERE Pricebook2Id = \'' + pricebook + '\' AND isActive = true AND (UnitPrice != null OR UnitPrice != 0) ' ;
        if(usuario.CompanyName == 'Elfa' ){
             query +=  ' AND Product2.isActiveElfa__c = true AND Product2.ProductCodeElfa__c != null AND Product2.ProductCode != null '  ;                           
        }else{
            if(checkContainsCompany(usuario.CompanyName)){
                query +=  ' AND Product2.IsActive = true AND Product2.ProductCode != null ' ;                           
            }else{
                if(usuario.CompanyName == 'Atrial/Elfa'){
                    query += ' AND ((Product2.isActiveElfa__c = true AND Product2.ProductCodeElfa__c != null) OR Product2.IsActive = true) AND Product2.ProductCode != null ';
                }
            }
        }
        String verifyGenericQuery = '';
        if (searchGenericValue != '' && !isCampaign) {
            verifyGenericQuery = ' AND (Product2.Name like \'%' + searchGenericValue + '%\' OR Product2.Description like \'%' + searchGenericValue + '%\' OR Product2.ProductCode like \'%' + searchGenericValue + '%\' ) ';
            query += ' AND (Product2.Name like \'%' + searchGenericValue + '%\' OR Product2.Description like \'%' + searchGenericValue + '%\' OR Product2.ProductCode like \'%' + searchGenericValue + '%\' ) ';
        }
        
        system.debug('verificando query generica: ' + verifyGenericQuery);
        
        String verifyQueryFabricante = '';
        if (searchFabricanteValue != '') {
            verifyQueryFabricante = ' AND (Product2.Name like \'%' + searchFabricanteValue + '%\' OR Product2.Description like \'%' + searchFabricanteValue + '%\' OR Product2.ProductCode like \'%' + searchFabricanteValue + '%\' ) ';
            query += ' AND (Product2.Fornecedor__r.Name like \'%' + searchFabricanteValue + '%\' ) ';
        }

        query += setorizacaoQuery(clienteId);

        system.debug('verificando query fabricante: ' + verifyQueryFabricante);
        
		system.debug('query ' + query);
        if (isCampaign) {
            List<String> listProdCode = new List<String>();
            system.debug(searchGenericValue);
            if (searchGenericValue != null && searchGenericValue != '') {
                listProdCode = searchGenericValue.split(',');
                system.debug('listProdCode.size(): ' + listProdCode.size());
                system.debug('listProdCode.size() > 0: ' + Boolean.valueOf(listProdCode.size() > 0));
            } else {
                listProdCode = null;
            }
            system.debug('listProdCode: ' + listProdCode);
            system.debug('prodList: ' + prodList);
            if (listProdCode != null) {
                query += ' AND Product2.ProductCode IN: listProdCode';
            } else {
                query += ' AND Product2Id IN: prodList';
            }
        } else {
            if (!query.contains('LIMIT')) {
                query += offSetValue != '' ? ' Order by Product2.Name LIMIT 20 OFFSET ' + String.escapeSingleQuotes(offSetValue) : ' Order by Product2.Name LIMIT 20';
            }
        }
		system.debug('query: ' + query);
        List<PricebookEntry> lPbEntry = new List<PricebookEntry>();
        lPbEntry = Database.query(query);
        system.debug('lPbEntry: ' + lPbEntry);
        set<String> setProductId = new set<String>();
        for(PricebookEntry pbEntry : lPbEntry){
            setProductId.add(pbEntry.Product2Id);
        }        

        Map<Id, Datetime> mapIdToLastBuy = new Map<Id, Datetime>();

        system.debug(setProductId);
        for (OrderItem ordItem: [SELECT Product2Id, Order.EffectiveDate FROM OrderItem WHERE Order.AccountId =: clienteId AND (Order.Status = 'Faturado' OR Order.Status = 'Faturado (Histórico)') AND Product2Id IN: setProductId Order by Order.EffectiveDate DESC LIMIT 30000]) {
            if (!mapIdToLastBuy.containsKey(ordItem.Product2Id)) {
                mapIdToLastBuy.put(ordItem.Product2Id, ordItem.Order.EffectiveDate);
            } else {
                if (mapIdToLastBuy.get(ordItem.Product2Id) < ordItem.Order.EffectiveDate) {
                    mapIdToLastBuy.put(ordItem.Product2Id, ordItem.Order.EffectiveDate);
                }
            }
        }

        Map<String, Set<String>> mapKeyToCodArmazem = new Map<String, Set<String>>();
        Map<String, Set<String>> mapKeyToMotivo = new Map<String, Set<String>>();
        for (RegraBloqueioArmazem__c reg : [SELECT Id, CodigoArmazem__c, Motivo__c, Produto__c, Cliente__c FROM RegraBloqueioArmazem__c WHERE Cliente__c =: clienteId]) {
            if (!mapKeyToCodArmazem.containsKey(String.valueOf(reg.Cliente__c) + reg.Produto__c)) {
                mapKeyToCodArmazem.put(String.valueOf(reg.Cliente__c) + reg.Produto__c, new Set<String>{reg.CodigoArmazem__c});
                mapKeyToMotivo.put(reg.Produto__c, new Set<String>{reg.Motivo__c});
            } else {
                mapKeyToCodArmazem.get(String.valueOf(reg.Cliente__c) + reg.Produto__c).add(reg.CodigoArmazem__c);
                mapKeyToMotivo.get(reg.Produto__c).add(reg.Motivo__c);
            }
        }

        system.debug('mapKeyToCodArmazem: ' + mapKeyToCodArmazem);
        system.debug('mapKeyToMotivo: ' + mapKeyToMotivo);

        Map<Id, Decimal> mapPbeIdToBalance = new Map<Id, Decimal>();
        Map<Id, Decimal> mapPbeIdToBalanceEstoque = new Map<Id, Decimal>();
        Map<Id, Set<String>> mapProdToArmazem = new Map<Id, Set<String>>();
        Map<String, Decimal> mapArmazemToSaldo = new Map<String, Decimal>();
        Map<String, List<Estoque__c>> mapProductIdToInventoryList = new Map<String, List<Estoque__c>>();
        for (Estoque__c e : [SELECT Id, NomeProduto__c, Saldo__c, Armazem__c, NomeCliente__c, NomeProduto__r.ProductCode, CNPJCD__c, QuantidadePrevista__c, PrevisaoEntrada__c FROM Estoque__c WHERE NomeProduto__c IN :setProductId]) {
            String keyPrevision = e.CNPJCD__c + '_' + e.NomeProduto__r.ProductCode;
            if (!mapProductIdToInventoryList.containsKey(keyPrevision)) {
                mapProductIdToInventoryList.put(keyPrevision, new List<Estoque__c>{e});
            } else {
                mapProductIdToInventoryList.get(keyPrevision).add(e);
            }
            if (!mapPbeIdToBalanceEstoque.containsKey(e.NomeProduto__c) && e.Armazem__c == '01') {
                mapPbeIdToBalanceEstoque.put(e.NomeProduto__c, e.Saldo__c);
            } else if (e.Armazem__c == '01') {
                Decimal calc = mapPbeIdToBalanceEstoque.get(e.NomeProduto__c) + e.Saldo__c;
                mapPbeIdToBalanceEstoque.put(e.NomeProduto__c, calc);
            }
            if (!mapPbeIdToBalance.containsKey(e.NomeProduto__c)) {
                mapPbeIdToBalance.put(e.NomeProduto__c, 0);
            }
            String key = String.valueOf(clienteId) + String.valueOf(e.NomeProduto__c);
            if (mapKeyToCodArmazem.containsKey(key)) {
                for (String armazem : mapKeyToCodArmazem.get(key)) {
                    List<String> listSplitArmazem = armazem.split(',');
                    for (String splittedArm : listSplitArmazem) {
                        system.debug(splittedArm);
                        system.debug(e.Armazem__c);
                        if (splittedArm.trim() == e.Armazem__c) {
                            Decimal balance = mapPbeIdToBalance.get(e.NomeProduto__c) + e.Saldo__c;
                            mapPbeIdToBalance.put(e.NomeProduto__c, balance);
                            if (!mapArmazemToSaldo.containsKey(e.Armazem__c)) {
                                mapArmazemToSaldo.put(e.Armazem__c, e.Saldo__c);
                            } else {
                                Decimal saldoArmazem = mapArmazemToSaldo.get(e.Armazem__c) + e.Saldo__c;
                                mapArmazemToSaldo.put(e.Armazem__c, saldoArmazem);
                            }
                            if (!mapProdToArmazem.containsKey(e.NomeProduto__c)) {
                                mapProdToArmazem.put(e.NomeProduto__c, new Set<String>{e.Armazem__c});
                            } else {
                                mapProdToArmazem.get(e.NomeProduto__c).add(e.Armazem__c);
                            }
                        }
                    }
                }
            }
        }
        Map<String, String> prodCatMap  = Utils.getPicklistApi(Product2.CategoriaComercial__c);
        map<String,ProductData> mapProd = new map<String,ProductData>();
        mapProd = getContractCampaign(setProductId, clienteId, condPag);
        system.debug('mapProd ' + mapProd);
        for(PricebookEntry pbEntry : lPbEntry){
            ProductData ProductData = new ProductData();
            if(mapProd.containsKey(pbEntry.Product2Id)){
                ProductData = mapProd.get(pbEntry.Product2Id);
                if(ProductData.precoTabelaCx == 0 ){
                    ProductData.precoTabelaCx = pbEntry.UnitPrice;
                }
            }else{
                ProductData.precoTabelaCx = pbEntry.UnitPrice;
            }
            if(papel == null || papel.DeveloperName.contains('VendedorSuporte') || papel.DeveloperName.contains('VendedorExterno') || papel.DeveloperName.contains('VendedorInterno')){
                ProductData.verMargem = false;
            }else{
                ProductData.verMargem = true;

            }
            ProductData.precoFabricaCx = (pbEntry.PrecoFabrica__c == null || pbEntry.PrecoFabrica__c == 0) ? pbEntry.UnitPrice : pbEntry.PrecoFabrica__c;
            ProductData.unidadeSec = true;
            ProductData.pbEntryId = pbEntry.Id;
		    ProductData.id = pbEntry.Product2Id;	
            if(usuario.CompanyName == 'Elfa' ){
                ProductData.code = pbEntry.Product2.ProductCodeElfa__c;
            }else{
                if(checkContainsCompany(usuario.CompanyName)) {
                    ProductData.code = pbEntry.Product2.ProductCode;
                }else{ 
                    if(usuario.CompanyName == 'Atrial/Elfa'){
                        ProductData.code = pbEntry.Product2.ProductCode;
                    }
                }
            }	
            ProductData.tipoConversao = pbEntry.Product2.TipoConversao__c;
            ProductData.unidadePrincipal = pbEntry.Product2.UnidadeMedida__c;
            if(pbEntry.Product2.UnidadeMedida__c == pbEntry.Product2.SegundaUnidade__c){
                ProductData.unidadeSec = false;
            }else if(pbEntry.Product2.SegundaUnidade__c == '0' || pbEntry.Product2.SegundaUnidade__c == null){
                ProductData.unidadeSec = false;
            }else if(pbEntry.Product2.TipoConversao__c == '0' || pbEntry.Product2.TipoConversao__c == null){
                ProductData.unidadeSec = false;
            }else if(pbEntry.Product2.FatorConversao__c == '0' || pbEntry.Product2.FatorConversao__c == null){
                ProductData.unidadeSec = false;
            }
            // ProductData.inventoryList = mapProductIdToInventoryList.containsKey(ProductData.Id) ? mapProductIdToInventoryList.get(ProductData.Id) : null;
            ProductData.unidadeSecundaria = pbEntry.Product2.SegundaUnidade__c;
            ProductData.descTecnica = pbEntry.Product2.DescricaoTecnica__c;
            ProductData.nome = pbEntry.Product2.Name;	
		    ProductData.principioAtivo = pbEntry.Product2.Description;	
		    ProductData.fabricante = pbEntry.Product2.Fornecedor__r.Name;
		    ProductData.anvisa = pbEntry.Product2.NumeroAnvisa__c;	
            ProductData.categoria = pbEntry.Product2.CategoriaComercial__c ;
    		ProductData.categoriaCompleta    = prodCatMap.containsKey(pbEntry.Product2.CategoriaComercial__c) ? prodCatMap.get(pbEntry.Product2.CategoriaComercial__c) : pbEntry.Product2.CategoriaComercial__c;
            ProductData.categoriaDesc        = prodCatMap.containsKey(pbEntry.Product2.CategoriaComercial__c) ? prodCatMap.get(pbEntry.Product2.CategoriaComercial__c) : pbEntry.Product2.CategoriaComercial__c;
		    ProductData.temperatura          = pbEntry.Product2.Temperatura__c;
		    ProductData.ean                  = pbEntry.Product2.EANProduto__c;	
            ProductData.fatorConversao       = checkAnyFieldIsNull(pbEntry.Product2.FatorConversao__c) ? '0' : pbEntry.Product2.FatorConversao__c == '0' ? '1' : pbEntry.Product2.FatorConversao__c;
		    ProductData.estoque              = mapPbeIdToBalanceEstoque.containsKey(ProductData.id) ? Integer.valueOf(mapPbeIdToBalanceEstoque.get(ProductData.id)) : 0;
            ProductData.possuiEstoqueArmazem = false;
            if (mapProdToArmazem.containsKey(ProductData.id)) {
                ProductData.possuiEstoqueArmazem = true;
                Set<String> listArmazem = mapProdToArmazem.get(ProductData.id);
                Set<String> listMotivo = mapKeyToMotivo.get(ProductData.id);
                system.debug(listArmazem);
                if (listArmazem != null) {
                    for (String codArmazem : listArmazem) {
                        if (ProductData.estoqueArmazem == null) {
                            ProductData.estoqueArmazem = mapArmazemToSaldo.get(codArmazem) + ' (' + codArmazem + ')';
                        } else {
                            ProductData.estoqueArmazem += '\n' + mapArmazemToSaldo.get(codArmazem) + ' (' + codArmazem + ')';
                        }
                    }
                }
                system.debug(listMotivo);
                if (listMotivo != null) {
                    for (String motivo: listMotivo) {
                        if (ProductData.regraBloqueioArmazem == null) {
                            ProductData.regraBloqueioArmazem = motivo;
                        } else {
                            ProductData.regraBloqueioArmazem += ';\n' + motivo;
                        }
                    }
                }
            }
		    ProductData.campoBusca           = ProductData.code + pbEntry.Product2.Name + pbEntry.Product2.Description;
            ProductData.campoBuscaFabricante = pbEntry.Product2.Fornecedor__r.Name != null ? pbEntry.Product2.Fornecedor__r.Name : '';
            system.debug('ProductData.precoTabelaCx ' + ProductData.precoTabelaCx);
            ProductData.valorZerado          = ProductData.precoTabelaCx == 0 ? true: false;

            system.debug(ProductData.id);
            if (mapIdToLastBuy.containsKey(ProductData.id)) {
                system.debug('Contem data de ultima compra');
                ProductData.possuiUltimaCompra = true;
                ProductData.ultimaCompra = formatDate(mapIdToLastBuy.get(ProductData.id).addDays(1));
            }

            lprod.add(ProductData);
        }
        return new ReturnObjGetProduct(lprod, mapProductIdToInventoryList);
    }

    public static Boolean checkContainsCompany(String value) {
        if(value == 'Atrial' || 
        value.contains('Procifar') || 
        value.contains('Art Medica') || 
        value.contains('Medcom') || 
        value.contains('Mostaert') ||
        value.contains('Oncorio') ||
        value.contains('Biohosp') ) {
            return true;
        } else {
            return false;
        }
    }

    public static String formatDate(Datetime dt) {
        List<String> splittedDate = String.valueOf(dt).split(' ')[0].split('-');
        return splittedDate[2] + '/' + splittedDate[1] + '/' + splittedDate[0];
    }

    public static String setorizacaoQuery(String clienteId){
        String query = '';
        Set<String> prodStringSet= new Set<String>();
        Set<String> catStringSet= new Set<String>();
        Set<String> fornStringSet= new Set<String>();
        for(Setorizacao__c sets : [SELECT id, Categoria__c, Produto__c, Fornecedor__c
                                FROM Setorizacao__c 
                                WHERE (Vendedor__c = :UserInfo.getUserid() 
                                OR Gerente__c = :UserInfo.getUserid())
                                AND Conta__c = :clienteId]){
            if(sets.Produto__c != null)    prodStringSet.add('\''+sets.Produto__c+'\'');
            if(sets.Categoria__c != null)  catStringSet.add('\''+sets.Categoria__c+'\'');
            if(sets.Fornecedor__c != null) fornStringSet.add('\''+sets.Fornecedor__c+'\'');

            if (catStringSet.contains('\'S\'')) {
                catStringSet.add('\'R\'');
            }
        }
        List<String> queryFilterSet = new List<String>();
        if(!prodStringSet.isEmpty() || !catStringSet.isEmpty() || !fornStringSet.isEmpty()){
            query += ' AND ( ';
            if(!catStringSet.isEmpty())  queryFilterSet.add(' Product2.CategoriaComercial__c IN ( '+String.join(new List<String>(catStringSet), ', ')+' ) ');
            if(!prodStringSet.isEmpty()) queryFilterSet.add(' Product2Id IN ( '+String.join(new List<String>(prodStringSet), ', ')+' ) ');
            if(!fornStringSet.isEmpty()) queryFilterSet.add(' Product2.Fornecedor__c IN ( '+String.join(new List<String>(fornStringSet), ', ')+' ) ');
            
            query += String.join(queryFilterSet, ' OR ')+' ) ';
        }
        System.debug(query);
        return query;
    }

    public static map<String,ProductData> getContractCampaign(set<String> setProductId, String clienteId, String condPag){
        map<String,ProductData> mapProd = new map<String,ProductData>();
        list<ItemContrato__c> lcontrato = new list<ItemContrato__c>();
        for(ItemContrato__c contrato : [SELECT NumeroContrato__c,NumeroContrato__r.TipoRegra__c , NomeProduto__c, PrecoUnitario__c, PrecoMinimo__c
                                                FROM ItemContrato__c 
                                                WHERE NumeroContrato__r.TipoRegra__c IN ('A', 'O')
                                                // AND NumeroContrato__r.Status = 'Aprovado'
                                                AND Status__c = 'Aprovado'
                                                AND NumeroContrato__r.AccountId =: clienteId
                                                AND NomeProduto__c =: setProductId
                                                // AND NumeroContrato__r.StartDate <= TODAY AND NumeroContrato__r.EndDate >= TODAY
                                                AND VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY
                                                ORDER BY NumeroContrato__r.TipoRegra__c DESC ] ){

            ProductData ProductData = new ProductData();
            ProductData.SequenciaOC = '';
          
            if(mapProd.containsKey(contrato.NomeProduto__c)){
                ProductData = mapProd.get(contrato.NomeProduto__c);
            }else{
                ProductData.valorBloqueado           = false;
                ProductData.showBadgeOL              = false;
                ProductData.showBadgeCampanha        = false;
                ProductData.showBadgeCampanhaVendedor = false;
                ProductData.showBadgeCampanhaCD      = false;
                ProductData.showBadgeConsignado      = false;
                ProductData.showBadgeReservado       = false;
                ProductData.showBadgeAcordoComercial = false;
                ProductData.showBadgeshelflife       = false;
                ProductData.precoCNPJCampanha = null;
                ProductData.precoBadgeOL = 0 ;
                ProductData.dataBadgeCampanha = null;
                ProductData.dataBadgeCampanhaVendedor = null;
                ProductData.dataBadgeCampanhaVendCNPJ = null;
                ProductData.precoBadgeConsignado = 0;
                ProductData.precoBadgeAcordoComercial = 0;
                ProductData.precoBadgeshelflife = 0;
                ProductData.precoCNPJShelflife = null;
                ProductData.unidadeMedida = null;
                ProductData.unidadeMedidaSeg = null;
                ProductData.dataBadgeReservadoCNPJ = null;
            }
            if(contrato.NumeroContrato__r.TipoRegra__c == 'A'){
                ProductData.valorBloqueado = true;
                ProductData.showBadgeAcordoComercial = true;
                ProductData.precoBadgeAcordoComercial = contrato.PrecoUnitario__c;
                if(!ProductData.showBadgeOL){
                    ProductData.precoTabelaCx = contrato.PrecoUnitario__c;
                }
            }else if(contrato.NumeroContrato__r.TipoRegra__c == 'O'){
                ProductData.showBadgeOL  = true;
                ProductData.valorBloqueado = true;
                ProductData.precoTabelaCx = contrato.PrecoUnitario__c;
                ProductData.precoBadgeOL  = contrato.PrecoUnitario__c;
                //ProductData.Id = contrato.NomeProduto__c;
            }
            mapProd.put(contrato.NomeProduto__c,ProductData);
        }
        system.debug('mapProd ' + mapProd);
        Set<String> setCodCampanha = new Set<String>();
        Set<Id> setGroupId = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, Set<Id>> mapCampIdToAccSetId = new Map<Id, Set<Id>>();
        Map<Id, String> mapCodCampaignToIdCampaign = new Map<Id, String>();
        setAccountId.add(clienteId);
        for (Campaign camp: [SELECT GrupoCliente__c, Cliente__c FROM Campaign WHERE RecordType.DeveloperName = 'Campanha' AND GrupoCliente__c != null]) {
            setCodCampanha.add(camp.GrupoCliente__c);
            if (camp.Cliente__c != null) {
                setAccountId.add(camp.Cliente__c);
            }
        }
        for (CondicaoPagamento__c condPagamento : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE Id =: condPag]) {
            if (condPagamento.ExternalId__c != null) {
                mapCodCampaignToIdCampaign.put(condPagamento.Id, condPagamento.ExternalId__c);
            }
        }
        if (!setCodCampanha.isEmpty()) {
            for (GrupoCliente__c gpCli : [SELECT Id, Name, CodigoGrupo__c FROM GrupoCliente__c WHERE CodigoGrupo__c IN: setCodCampanha]) {
                system.debug(gpCli.Name);
                setGroupId.add(gpCli.Id);
            }
            for (Account acc : [SELECT Id FROM Account WHERE GrupoCliente__c IN: setGroupId]) {
                system.debug(acc.Id);
                setAccountId.add(acc.Id);
            }
        }
        system.debug(setAccountId);
        system.debug(clienteId);
        Map<String, String> mapCdCodeToCdName = new Map<String, String>();
        Map<String, String> mapCdCodeToCdCnpj = new Map<String, String>();
        List<listaCentroDistribuicao__c> listaCd = listaCentroDistribuicao__c.getall().values();
        for (listaCentroDistribuicao__c Cd : listaCd) {
            mapCdCodeToCdName.put(cd.CodigoCD__c, cd.NomeCD__c);
            mapCdCodeToCdCnpj.put(cd.CodigoCD__c, cd.CNPJCD__c);
        }

        Map<String, String> mapKeyToProductData = new Map<String, String>();
        Map<String, String> mapKeyToProdByCd = new Map<String, String>();
        for(ItemCampanha__c campanha :[SELECT Id , NomeProduto__c, NomeProduto__r.ProductCode, NomeProduto__r.Name, PrecoUnitario__c, PrecoMinimo__c, Campanha__r.RecordType.DeveloperName, TipoGatilho__c, VigenciaFinal__c, CNPJCD__c, Campanha__r.EndDate, Lote__c, Campanha__r.Validade__c, Campanha__r.Cliente__c,
                                                Campanha__r.InicioRecorrencia__c, Campanha__r.FimRecorrencia__c, Campanha__r.CondicaoPagamento__c, Campanha__r.Type, Campanha__r.CNPJCD__c, Desconto__c, Campanha__r.CodigoCD__c, Campanha__r.RegrasCampanha__c, Campanha__r.NomeCD__c, NomeProduto__r.Fornecedor__r.Name, Campanha__c
                                                FROM ItemCampanha__c 
                                                WHERE Campanha__r.RecordType.DeveloperName IN ('ContratoShelfLife','Campanha', 'CampanhaVendedor')
                                                AND NomeProduto__c IN: setProductId AND (Campanha__r.Cliente__c IN: setAccountId OR (Campanha__r.Cliente__c = null AND Campanha__r.GrupoCliente__c = null))
                                                AND ((Campanha__r.StartDate <= TODAY AND Campanha__r.EndDate >= TODAY)
                                                OR (VigenciaInicial__c <= TODAY AND VigenciaFinal__c >= TODAY))
                                                ORDER BY Campanha__r.RecordType.DeveloperName DESC]){
            ProductData ProductData = new ProductData();
            if (campanha.Campanha__r?.Cliente__c != null) {
                setAccountId.add(campanha.Campanha__r?.Cliente__c);
                if (!mapCampIdToAccSetId.containsKey(campanha.Id)) {
                    mapCampIdToAccSetId.put(campanha.Id, new Set<Id>{campanha.Campanha__r?.Cliente__c});
                } else {
                    mapCampIdToAccSetId.get(campanha.Id).add(campanha.Campanha__r?.Cliente__c);
                }
            }
            system.debug('campanha ' + campanha);
            system.debug('recordtype ' + campanha.Campanha__r.RecordType.DeveloperName);
            if(mapProd.containsKey(campanha.NomeProduto__c)){
                ProductData = mapProd.get(campanha.NomeProduto__c);
                if (ProductData.campDesc == null) {
                    ProductData.campDesc = '';
                }
            }else{
                ProductData.campDesc = '';
                ProductData.valorBloqueado = false;
                ProductData.showBadgeOL = false;
                ProductData.showBadgeCampanha = false;
                ProductData.showBadgeCampanhaVendedor = false;
                ProductData.showBadgeCampanhaCD = false;
                ProductData.showBadgeConsignado = false ;
                ProductData.showBadgeReservado  = false;
                ProductData.showBadgeAcordoComercial = false;
                ProductData.showBadgeshelflife = false;
                ProductData.precoCNPJCampanha = null;
                ProductData.precoBadgeOL = 0;
                ProductData.dataBadgeCampanha = null;
                ProductData.dataBadgeCampanhaVendedor = null;
                ProductData.campanhaId = '';
                ProductData.dataBadgeCampanhaVendCNPJ = null;
                ProductData.precoBadgeConsignado = 0;
                ProductData.precoBadgeAcordoComercial =0;
                ProductData.precoBadgeshelflife = 0;
                ProductData.regraCampanha = '';
                ProductData.searchCampaignField = '';
                ProductData.unidadeMedida = '';
                ProductData.dataBadgeReservadoCNPJ = null;
                
            }
            if(campanha.Campanha__r.RecordType.DeveloperName == 'ContratoShelfLife'){
                ProductData.showBadgeshelflife = true;
                if (ProductData.searchCampaignField == null || ProductData.searchCampaignField == '') {
                    ProductData.searchCampaignField = campanha.NomeProduto__r.ProductCode + campanha.NomeProduto__r.Name + campanha.NomeProduto__r.Fornecedor__r.Name;
                }
                ProductData.precoBadgeshelflife = campanha.PrecoUnitario__c;

                if (campanha.Campanha__r.CodigoCD__c != null) {
                    system.debug('campanha.Campanha__r.CodigoCD__c: ' + campanha.Campanha__r.CodigoCD__c);
                    List<String> listCodCd = campanha.Campanha__r.CodigoCD__c.split(';');
                    system.debug('listCodCd: ' + listCodCd);
                    for (String codCd : listCodCd) {
                        if (ProductData.precoCNPJShelflife == null) {
                            ProductData.precoCNPJShelflife = mapCdCodeToCdCnpj.get(codCd) + '_' + campanha.Lote__c + '_' + campanha.PrecoMinimo__c;
                        } else {
                            ProductData.precoCNPJShelflife += ';' + mapCdCodeToCdCnpj.get(codCd) + '_' + campanha.Lote__c + '_' + campanha.PrecoMinimo__c;
                        }
                    }
                } else {
                    if (ProductData.precoProdShelfLife == null) {
                        ProductData.precoProdShelfLife = String.valueOf(campanha.PrecoMinimo__c);
                    }
                }
                if(!ProductData.showBadgeAcordoComercial && !ProductData.showBadgeOL ){
                    // ProductData.precoTabelaCx = campanha.PrecoUnitario__c;
                    ProductData.precoTabelaCx = 0;
                }
            }else if(campanha.Campanha__r.RecordType.DeveloperName == 'Campanha'){                
                if (ProductData.id == null) {
                    ProductData.id = campanha.NomeProduto__c;
                }                
                String fornecedor = campanha.NomeProduto__r.Fornecedor__r.Name != null ? campanha.NomeProduto__r.Fornecedor__r.Name : '';
                String prodName = campanha.NomeProduto__r.Name;
                String prodCode = campanha.NomeProduto__r.ProductCode;
                if (ProductData.searchCampaignField == null || ProductData.searchCampaignField == '') {
                    ProductData.searchCampaignField = prodCode + prodName + fornecedor;
                }
                system.debug('Tipo de campanha: ' + campanha.Campanha__r.Type);
                if (campanha.Campanha__r.Type == 'Y' || campanha.Campanha__r.Type == 'Z') {
                    Boolean ruleA = false;
                    Boolean ruleB = false;
                    if (((campanha.Campanha__r.InicioRecorrencia__c != null && campanha.Campanha__r.FimRecorrencia__c != null) || campanha.Campanha__r.Validade__c != null) /**REGRA A*/) {
                        if (campanha.Campanha__r.Validade__c != null) {
                            DateTime myDateTime = Datetime.now();
                            String dayOfWeek = translateDayOfTheWeek(myDateTime.format('E'));
                            List<String> listDaysOfWeek = campanha.Campanha__r.Validade__c.split(';');
                            system.debug(dayOfWeek);
                            system.debug(listDaysOfWeek);
                            for (String day : listDaysOfWeek) {
                                system.debug(day.trim() == dayOfWeek);
                                if (day.trim() == dayOfWeek) {
                                    system.debug('Entrou daytrim');
                                    if (Date.today().day() >= campanha.Campanha__r.InicioRecorrencia__c && Date.today().day() <= campanha.Campanha__r.FimRecorrencia__c) { //validar se esta entre os dias 
                                        system.debug('Entrou datetoday');
                                        system.debug(clienteId);
                                        system.debug(setAccountId);
                                        system.debug(mapCampIdToAccSetId);
                                        system.debug(mapCampIdToAccSetId.get(campanha.Id));
                                        if (setAccountId.isEmpty() || mapCampIdToAccSetId.get(campanha.Id) == null) {
                                            system.debug('Entrou setAccount empty');
                                            ProductData.showBadgeCampanha = true;
                                            ruleA = true;
                                            ProductData.cnpjCampanhaCd = campanha.Campanha__r.CodigoCD__c;
                                        } else if (setAccountId.contains(clienteId) || mapCampIdToAccSetId.get(campanha.Id).contains(clienteId)) {
                                            system.debug('Entrou setAccount contains');
                                            ProductData.showBadgeCampanha = true;
                                            ruleA = true;
                                            ProductData.cnpjCampanhaCd = campanha.Campanha__r.CodigoCD__c;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    system.debug('condPag: ' + condPag);
                    system.debug('mapCodCampaignToIdCampaign: ' + mapCodCampaignToIdCampaign);
                    if ((campanha.Campanha__r.CondicaoPagamento__c != null && campanha.Campanha__r.CondicaoPagamento__c == mapCodCampaignToIdCampaign.get(condPag)) /**REGRA B */) {
                        system.debug('entrou condicao pagamento setAccount');
                        if (setAccountId.isEmpty() || mapCampIdToAccSetId.get(campanha.Id) == null) {
                            ProductData.showBadgeCampanha = true;
                            ruleB = true;
                            ProductData.cnpjCampanhaCd = campanha.Campanha__r.CNPJCD__c;
                        } else if (setAccountId.contains(clienteId) || mapCampIdToAccSetId.get(campanha.Id).contains(clienteId)) {
                            ProductData.showBadgeCampanha = true;
                            ruleB = true;
                            ProductData.cnpjCampanhaCd = campanha.Campanha__r.CNPJCD__c;
                        }
                    }
                    system.debug('ProductData.tipoCampanha: ' + ProductData.tipoCampanha);
                    system.debug('campanha.Campanha__r.Type: ' + campanha.Campanha__r.Type);
                    system.debug('ProductData.desconto: ' + ProductData.desconto);
                    system.debug('campanha.Desconto__c: ' + campanha.Desconto__c);
                    String key = campanha.NomeProduto__r.ProductCode;
                    String tipoCamp    = campanha.Campanha__r.Type == 'Y' ? 'Dia D' : 'Condição de pagamento';
                    String condPagNome = campanha.Campanha__r.Type == 'Y' ? 'Dia D' : 'Condição de pagamento';
                    String valid       = campanha.Campanha__r.Validade__c != null ? campanha.Campanha__r.Validade__c : '';
                    system.debug(ProductData.showBadgeCampanha);
                    if (ProductData.showBadgeCampanha) {
                        system.debug(tipoCamp);
                        system.debug(ProductData.campDesc);
                        if (!ProductData.campDesc.contains(tipoCamp)) {
                            if (ProductData.campDesc != null && ProductData.campDesc != '') {
                                ProductData.campDesc += '; ' + tipoCamp;
                            } else {
                                ProductData.campDesc = tipoCamp;
                            }
                        }
                        if (!mapKeyToProductData.containsKey('product'+key) && campanha.Campanha__r.CodigoCD__c == null && (ruleA || ruleB)) {
                            ProductData.listTagByCd = campanha.Desconto__c + '%' + ' | ' + campanha.Campanha__r.Type;
                            system.debug(ProductData.listTagByCd);
                            mapKeyToProductData.put('product'+key, ProductData.listTagByCd);
                            if (campanha.Campanha__r.Validade__c != null) {
                                ProductData.regraCampanha = tipoCamp + ': ' + campanha.Campanha__r.Validade__c;
                            } else {
                                ProductData.regraCampanha = tipoCamp + ': ' + campanha.Campanha__r.CondicaoPagamento__c;
                            }
                            system.debug('campanha produto novo (sem codigo cd): ' + campanha);
                            system.debug('ProductData.listTagByCd (sem codigo cd): ' + ProductData.listTagByCd);
                        } else if (campanha.Campanha__r.CodigoCD__c == null && (ruleA || ruleB)) {
                            ProductData.listTagByCd = mapKeyToProductData.get('product'+key) + ';' + campanha.Desconto__c + '%' + ' | ' + campanha.Campanha__r.Type;
                            system.debug(ProductData.listTagByCd);
                            mapKeyToProductData.put('product'+key, ProductData.listTagByCd);
                            if (campanha.Campanha__r.Validade__c != null) {
                                ProductData.regraCampanha += '\n' + tipoCamp + ': ' + campanha.Campanha__r.Validade__c;
                            } else {
                                ProductData.regraCampanha += '\n' + tipoCamp + ': ' + campanha.Campanha__r.CondicaoPagamento__c;
                            }
                            ProductData.searchCampaignField += campanha.Campanha__r.NomeCD__c;
                            system.debug('campanha mesmo produto (sem codigo cd): ' + campanha);
                            system.debug('ProductData.listTagByCd (sem codigo cd): ' + ProductData.listTagByCd);
                        }
        
                        if (!mapKeyToProdByCd.containsKey(key) && campanha.Campanha__r.CodigoCD__c != null && (ruleA || ruleB)) {
                            List<String> listCodCd = campanha.Campanha__r.CodigoCD__c.split(';');
                            for (String codCd : listCodCd) {
                                if (ProductData.listTagByCd == null) {
                                    ProductData.listTagByCd = codCd + ',' + campanha.Desconto__c + '%' + ' | ' + campanha.Campanha__r.Type;
                                    mapKeyToProdByCd.put(key, ProductData.listTagByCd);
                                } else {
                                    ProductData.listTagByCd += ';' + codCd + ',' + campanha.Desconto__c + '%' + ' | ' + campanha.Campanha__r.Type;
                                    mapKeyToProdByCd.put(key, ProductData.listTagByCd);
                                }
                                ProductData.searchCampaignField += mapCdCodeToCdName.get(codCd);
                            }
                            if (campanha.Campanha__r.NomeCD__c != null) {
                                ProductData.searchCampaignField += campanha.Campanha__r.NomeCD__c;
                            }
                            if (campanha.Campanha__r.Validade__c != null) {
                                ProductData.regraCampanha = tipoCamp + ': ' + campanha.Campanha__r.Validade__c;
                            } else {
                                ProductData.regraCampanha = tipoCamp + ': ' + campanha.Campanha__r.CondicaoPagamento__c;
                            }
                            system.debug('campanha produto novo: ' + campanha);
                            system.debug('ProductData.listTagByCd: ' + ProductData.listTagByCd);
                        } else if (campanha.Campanha__r.CodigoCD__c != null && (ruleA || ruleB)) {
                            List<String> listCodCd = campanha.Campanha__r.CodigoCD__c.split(';');
                            for (String codCd : listCodCd) {
                                ProductData.listTagByCd = mapKeyToProdByCd.get(key) + ';' + codCd + ',' + campanha.Desconto__c + '%' + ' | ' + campanha.Campanha__r.Type;
                                mapKeyToProdByCd.put(key, ProductData.listTagByCd);
                                ProductData.searchCampaignField += mapCdCodeToCdName.get(codCd);
                            }
                            if (campanha.Campanha__r.NomeCD__c != null) {
                                ProductData.searchCampaignField += campanha.Campanha__r.NomeCD__c;
                            }
                            if (campanha.Campanha__r.Validade__c != null) {
                                ProductData.regraCampanha += '\n' + tipoCamp + ': ' + campanha.Campanha__r.Validade__c;
                            } else {
                                ProductData.regraCampanha += '\n' + tipoCamp + ': ' + campanha.Campanha__r.CondicaoPagamento__c;
                            }
                            system.debug('campanha mesmo produto: ' + campanha);
                            system.debug('ProductData.listTagByCd: ' + ProductData.listTagByCd);
                        }
                    }
                } else if (campanha.Campanha__r.Type == 'C') {
                    if (!ProductData.campDesc.contains('Campanha normal')) {
                        if (ProductData.campDesc != null && ProductData.campDesc != '') {
                            ProductData.campDesc += '; Campanha normal';
                        } else {
                            ProductData.campDesc = 'Campanha normal';
                        }
                    }
                    ProductData.showBadgeCampanha = true;
                    if (ProductData.precoCNPJCampanha == null) {
                        ProductData.precoCNPJCampanha = campanha.Campanha__r.CodigoCD__c + ',' + campanha.PrecoMinimo__c;
                    } else {
                        ProductData.precoCNPJCampanha += ';' + campanha.Campanha__r.CodigoCD__c + ',' + campanha.PrecoMinimo__c;
                    }
                    if (ProductData.dataBadgeCampanha == null) {
                        ProductData.dataBadgeCampanha = campanha.Campanha__r.CodigoCD__c == null ? 'null' : campanha.Campanha__r.CodigoCD__c;
                    } else {
                        ProductData.dataBadgeCampanha += ';' + campanha.Campanha__r.CodigoCD__c;
                    }
                    if(!ProductData.showBadgeAcordoComercial && !ProductData.showBadgeOL && !ProductData.showBadgeshelflife){
                        // ProductData.precoTabelaCx = campanha.PrecoUnitario__c;
                        ProductData.precoTabelaCx = 0;
                    }
                }
            } else if(campanha.Campanha__r.RecordType.DeveloperName == 'CampanhaVendedor'){
                ProductData.campanhaId = campanha.Campanha__c;
                if (ProductData.searchCampaignField == null || ProductData.searchCampaignField == '') {
                    ProductData.searchCampaignField = campanha.NomeProduto__r.ProductCode + campanha.NomeProduto__r.Name + campanha.NomeProduto__r.Fornecedor__r.Name;
                }
                DateTime myDateTime = Datetime.now();
                String dayOfWeek = translateDayOfTheWeek(myDateTime.format('E'));
                String validity = campanha.Campanha__r.Validade__c == null ? '' : campanha.Campanha__r.Validade__c;
                if (dayOfWeek != '' && validity.contains(dayOfWeek)) {
                    ProductData.showBadgeCampanhaVendedor = true;
                    if (ProductData.dataBadgeCampanhaVendCNPJ == null) {
                        ProductData.dataBadgeCampanhaVendCNPJ = campanha.CNPJCD__c == 'Todos' ? 'null' : campanha.CNPJCD__c;
                    } else {
                        ProductData.dataBadgeCampanhaVendCNPJ += ';' + campanha.CNPJCD__c;
                    }
                }
                System.debug('campanha: '+campanha);
                String[] campaignDateValues = String.valueOf(campanha.Campanha__r.EndDate).split('-');
                String campaignDate = campaignDateValues[2] + '-' + campaignDateValues[1] + '-' + campaignDateValues[0];
                System.debug('campaignDate: '+campaignDate);
                ProductData.dataBadgeCampanhaVendedor = campanha.TipoGatilho__c + ' | ' + campaignDate;
                System.debug('dataBadgeCampanhaVendedor: '+ProductData.dataBadgeCampanhaVendedor);
                ProductData.regraCampanha = campanha.Campanha__r.RegrasCampanha__c;
                if(!ProductData.showBadgeAcordoComercial && !ProductData.showBadgeOL && !ProductData.showBadgeshelflife && !ProductData.showBadgeCampanha){
                    // ProductData.precoTabelaCx = campanha.PrecoUnitario__c;
                    ProductData.precoTabelaCx = 0;
                }
            }
            mapProd.put(campanha.NomeProduto__c,ProductData);
        }
        //CodigoGrupoClientes__c => grupo
        //CodigoRegiao__c => setorizacao

        Set<String> setRegiao = new Set<String>();
        Set<String> setReservation = new Set<String>();

        for (Setorizacao__c seto : [SELECT Id, Regiao__c FROM Setorizacao__c WHERE Conta__c =: clienteId]) {
            if(!checkAnyFieldIsNull(seto.Regiao__c) && seto.Regiao__c != '') {
                setRegiao.add(seto.Regiao__c);
            }
        }

        List<DestinatarioReserva__c> listReservation = [
                                                            SELECT Id, Reserva__c, CodigoRegiao__c, Cliente__c
                                                            FROM
                                                            DestinatarioReserva__c
                                                            WHERE
                                                            Reserva__r.FimReserva__c >= TODAY
                                                            AND (CodigoRegiao__c IN:setRegiao OR Cliente__c =: clienteId)
                                                       ];
           
    if(listReservation.size() > 0){

            for (DestinatarioReserva__c desReserva : listReservation) {
                
                setReservation.add(desReserva.Reserva__c);
            }


            for (ProdutoReserva__c res : [SELECT Id, Produto__c, QuantidadeReservada__c, QuantidadeAtiva__c, QuantidadeConsumida__c, Reserva__c, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c IN:setReservation AND StatusReserva__c = 'Ativa']) {
                system.debug('prod reserva encontrado');
                ProductData prodData = mapProd.get(res.Produto__c);
                system.debug(res.Produto__c);
               
                if (prodData == null) {
                    prodData = new ProductData();
                }
                prodData.showBadgeReservado = true;
                prodData.precoBadgeReservado = res.QuantidadeAtiva__c;
                System.debug('-----'+prodData.showBadgeReservado );

                if (res.Reserva__r.CodigoCD__c != null) {
                    system.debug('res.Reserva__r.CodigoCD__c: ' + res.Reserva__r.CodigoCD__c);
                    List<String> listCodCd = res.Reserva__r.CodigoCD__c.split(';');
                    system.debug('listCodCd: ' + listCodCd);
                   
                    for (String codCd : listCodCd) {
                        if (res.QuantidadeAtiva__c != null && res.QuantidadeConsumida__c != null) {
                            Decimal saldo = res.QuantidadeAtiva__c - res.QuantidadeConsumida__c;
                            system.debug(mapCdCodeToCdCnpj.get(codCd));
                            if(saldo > 0) {
                                if (prodData.dataBadgeReservadoCNPJ == null) {
                                    prodData.dataBadgeReservadoCNPJ = mapCdCodeToCdCnpj.get(codCd) + '_' + String.valueOf(saldo);
                                } else {
                                    prodData.dataBadgeReservadoCNPJ += ';' + mapCdCodeToCdCnpj.get(codCd) + '_' + String.valueOf(saldo);
                                }
                            }
                            system.debug('prodData.dataBadgeReservadoCNPJ: ' + prodData.dataBadgeReservadoCNPJ);
                            system.debug('prodData.showBadgeReservadoCNPJ: ' + prodData.showBadgeReservadoCNPJ);
                        }

                        if (mapCdCodeToCdCnpj.containsKey(codCd)) {
                            
                            //prodData.showBadgeReservado = false;
                        }
                    }
                } else {
                    if (prodData.precoBadgeReservado == null) {
                        prodData.precoBadgeReservado = res.QuantidadeAtiva__c - res.QuantidadeConsumida__c;
                    }
                }
                System.debug('-----'+res.Produto__c);
                mapProd.put(res.Produto__c, prodData);
                System.debug('-----'+mapProd.get(res.Produto__c).showBadgeReservado);
            }
        }      

        return mapProd;
    }
    // public static void insertUserShare(List<Orderitem> ordItemList){
    //     Map<String, OrderShare> ordShareList = new Map<String, OrderShare>();
    //     for(OrderItem ordItem : ordItemList){
    //         system.debug('ordItem.OrderId: ' + ordItem.OrderId);
    //         if(ordItem.Vendedor__c != Userinfo.getUserId() && ordItem.OrderId != null) {
    //             ordShareList.put(ordItem.OrderId+'_'+ordItem.Vendedor__c, new OrderShare(OrderAccessLevel = 'Edit', OrderId = ordItem.OrderId, UserOrGroupId = ordItem.Vendedor__c));
    //         } else {
    //             continue;
    //         }
    //     }
    //     if(!ordShareList.isEmpty())
    //         insert ordShareList.values();
    // }

    // OrderScreenController.insertUserShare(new List<OpportunityLineItem>{new OpportunityLineItem(Vendedor__c = UserInfo.getUserId(), OpportunityId = '0062100000E3uIpAAJ')});
    // public static void insertUserShare(List<OpportunityLineitem> oppItemList){
    //     Map<String, OpportunityTeamMember> oppShareList = new Map<String, OpportunityTeamMember>();
    //     for(OpportunityLineItem oppItem : oppItemList){
    //         system.debug('oppItem.OpportunityId: ' + oppItem.OpportunityId);
    //         if(oppItem.Vendedor__c != Userinfo.getUserId() && oppItem.OpportunityId != null) {
    //             oppShareList.put(oppItem.OpportunityId+'_'+oppItem.Vendedor__c, new OpportunityTeamMember(TeamMemberRole = 'Sales Rep', UserId = oppItem.Vendedor__c, OpportunityId = oppItem.OpportunityId, OpportunityAccessLevel = 'Edit'));
    //         } else {
    //             continue;
    //         }
    //     }
    //     System.debug(oppShareList);
    //     if(!oppShareList.isEmpty())
    //         insert oppShareList.values();
    // }
    public class ProductData {
		@AuraEnabled public String pbEntryId                 {get; set;}
		@AuraEnabled public String id                        {get; set;}
		@AuraEnabled public String code                      {get; set;}
		@AuraEnabled public String nome                      {get; set;}
		@AuraEnabled public String campDesc                  {get; set;}
		@AuraEnabled public String principioAtivo            {get; set;}
		@AuraEnabled public String descTecnica               {get; set;}
		@AuraEnabled public String fabricante                {get; set;}
		@AuraEnabled public String anvisa                    {get; set;}
		@AuraEnabled public String categoria                 {get; set;}
		@AuraEnabled public String categoriaCompleta         {get; set;}
		@AuraEnabled public String categoriaDesc             {get; set;}
		@AuraEnabled public Double precoFabricaCx            {get; set;}
		@AuraEnabled public Double precoTabelaCx             {get; set;}
		@AuraEnabled public String temperatura               {get; set;}
		@AuraEnabled public String ultimaCompra              {get; set;}
		@AuraEnabled public Boolean possuiUltimaCompra       {get; set;}
		@AuraEnabled public String ean                       {get; set;}
		@AuraEnabled public String regraCampanha             {get; set;}
		@AuraEnabled public String searchCampaignField       {get; set;}
		@AuraEnabled public String fatorConversao            {get; set;}
		@AuraEnabled public boolean valorBloqueado           {get; set;}
		@AuraEnabled public boolean valorZerado              {get; set;}
		@AuraEnabled public boolean verMargem                {get; set;}
		@AuraEnabled public boolean showBadgeOL              {get; set;}
		@AuraEnabled public Decimal precoBadgeOL             {get; set;}
		@AuraEnabled public String campanhaId                {get; set;}
		@AuraEnabled public boolean showBadgeCampanha        {get; set;}
		@AuraEnabled public boolean showBadgeCampanhaCD      {get; set;}
		@AuraEnabled public String  precoCNPJCampanha        {get; set;}
		@AuraEnabled public String  dataBadgeCampanha        {get; set;}
		@AuraEnabled public String  dataBadgeCampanhaVendCNPJ {get; set;}
		@AuraEnabled public Decimal precoBadgeCampanhaProduto {get; set;}
		@AuraEnabled public boolean showBadgeCampanhaVendedor {get; set;}
		@AuraEnabled public String  dataBadgeCampanhaVendedor {get; set;}
		@AuraEnabled public boolean showBadgeConsignado      {get; set;}
		@AuraEnabled public Decimal precoBadgeConsignado     {get; set;}
		@AuraEnabled public boolean showBadgeReservado       {get; set;}
		@AuraEnabled public Decimal precoBadgeReservado      {get; set;}
		@AuraEnabled public boolean showBadgeReservadoCNPJ   {get; set;}
		@AuraEnabled public String dataBadgeReservadoCNPJ    {get; set;}
		@AuraEnabled public boolean showBadgeAcordoComercial {get; set;}
		@AuraEnabled public Decimal precoBadgeAcordoComercial{get; set;}
		@AuraEnabled public boolean showBadgeshelflife       {get; set;}
		@AuraEnabled public Decimal precoBadgeshelflife      {get; set;}
		@AuraEnabled public String  precoCNPJShelflife       {get; set;}
		@AuraEnabled public String  precoProdShelfLife       {get; set;}
        @AuraEnabled public String  desconto                 {get; set;}
        @AuraEnabled public String listTagByCd               {get; set;}
		@AuraEnabled public Integer estoque                  {get; set;}
		@AuraEnabled public Boolean possuiEstoqueArmazem     {get; set;}
		@AuraEnabled public String estoqueArmazem            {get; set;}
		@AuraEnabled public String regraBloqueioArmazem      {get; set;}
		@AuraEnabled public String campoBusca                {get; set;}
        @AuraEnabled public String campoBuscaFabricante      {get; set;}
        @AuraEnabled public String tipoConversao             {get; set;}
        @AuraEnabled public String unidadePrincipal          {get; set;}
        @AuraEnabled public String unidadeSecundaria         {get; set;}
		@AuraEnabled public boolean unidadeSec               {get; set;}
        @AuraEnabled public String SequenciaOC               {get; set;}
        @AuraEnabled public String tipoCampanha              {get; set;}
        @AuraEnabled public String cnpjCampanhaCd            {get; set;}
        @AuraEnabled public String unidadeMedida             {get; set;}
        @AuraEnabled public String unidadeMedidaSeg          {get; set;}
        @AuraEnabled public String targetId                  {get; set;}
        @AuraEnabled public String targetActionId            {get; set;}
        @AuraEnabled public String targetActionName          {get; set;}
        @AuraEnabled public List<Estoque__c> inventoryList {get; set;}
    }

    public class OrderData {
        @AuraEnabled public String HeaderId              {get; set;}
        @AuraEnabled public String NumeroPedido          {get; set;}
        @AuraEnabled public Decimal ValorTotal           {get; set;}
        @AuraEnabled public Decimal Margem               {get; set;}
        @AuraEnabled public Decimal MargemAlvo           {get; set;}
        @AuraEnabled public Decimal Score                {get; set;}
        @AuraEnabled public String ClienteEmissor        {get; set;}
        @AuraEnabled public String ClienteEmissorId      {get; set;}
        @AuraEnabled public String ClienteEmissorCGC     {get; set;}
        @AuraEnabled public String Medico                {get; set;}
        @AuraEnabled public String MedicoCRM             {get; set;}
        @AuraEnabled public String TabelaPreco           {get; set;}
        @AuraEnabled public String TabelaPrecoNome       {get; set;}
        @AuraEnabled public String CanalVendas           {get; set;}
        @AuraEnabled public String CondicaoPagamento     {get; set;}
        @AuraEnabled public String CondicaoPagamentoNome {get; set;}
        @AuraEnabled public String FormaPagamento        {get; set;}
        @AuraEnabled public String ContatoOrcamento      {get; set;}
        @AuraEnabled public String AccountContactRelationId {get; set;}
        @AuraEnabled public String TipoFrete             {get; set;}
        @AuraEnabled public Decimal ValorFrete           {get; set;}
        @AuraEnabled public String TipoOrdem             {get; set;}
        @AuraEnabled public String EnderecoEntregaId     {get; set;}
        @AuraEnabled public String EnderecoEntrega       {get; set;}
        @AuraEnabled public String NumeroPedidoCliente   {get; set;}
        @AuraEnabled public Date DtPrevistaEntrega       {get; set;}
        @AuraEnabled public String Observacao            {get; set;}
        @AuraEnabled public String ObservacaoNotaFiscal  {get; set;}
        @AuraEnabled public String ObservacaoPedido      {get; set;}
        @AuraEnabled public String ClienteRecebedor      {get; set;}
        @AuraEnabled public String ClienteRecebedorCGC   {get; set;}
        @AuraEnabled public String StatusPedido          {get; set;}
        @AuraEnabled public String Status                {get; set;}
        @AuraEnabled public Boolean ContemDocAlvaraCrt   {get; set;}
        @AuraEnabled public Boolean DocumentosValidos    {get; set;}
        @AuraEnabled public Boolean ClienteBloqueado     {get; set;}
        @AuraEnabled public Boolean BloqueioFinanceiro   {get; set;}
        @AuraEnabled public Boolean isVansOrder          {get; set;}
        @AuraEnabled public List<OrderItemData> Itens    {get; set;}
        @AuraEnabled public String EstadoCliente         {get; set;}
        @AuraEnabled public String GeraBoleto            {get; set;}
        @AuraEnabled public String DtParcelas            {get; set;}
        @AuraEnabled public String FretesPorCd           {get; set;}
        @AuraEnabled public Boolean PedidoComplementar   {get; set;}
        @AuraEnabled public String Idportalcotacoes      {get; set;}
        @AuraEnabled public Boolean allRecAnswered       {get; set;}
        @AuraEnabled public Boolean hasPermissionERB     {get; set;}

        @AuraEnabled public EnderecoCobranca enderecoCobranca;
        @AuraEnabled public EnderecoCobranca enderecoCobrancaRecebedor;

        public OrderData(Order ord) {
            this.HeaderId              = ord.Id;
            this.NumeroPedido          = ord.OrderNumber;
            this.ValorTotal            = ord.TotalAmount;
            this.Margem                = ord.Margem__c;
            this.MargemAlvo            = ord.MargemAlvo__c;
            this.Score                 = ord.Score__c;
            this.ClienteEmissor        = ord.Account?.Name;
            this.ClienteEmissorId      = ord.AccountId;
            this.ClienteEmissorCGC     = ord.CNPJ__c == null ? ord.CPF__c : ord.CNPJ__c;
            this.Medico                = ord.AccountId;
            this.MedicoCRM             = ord.Account?.NumeroRegistro__c;
            this.TabelaPreco           = ord.Pricebook2Id;
            this.TabelaPrecoNome       = ord.Pricebook2.Name;
            this.CanalVendas           = ord.CanalEntrada__c;
            this.CondicaoPagamento     = ord.CondicaoPagamento__c;
            this.CondicaoPagamentoNome = ord.CondicaoPagamento__r?.name;
            this.FormaPagamento        = ord.FormaPagamento__c;
            this.ContatoOrcamento      = ord.ContatoOrcamento__c;
            this.TipoFrete             = ord.TipoFrete__c;
            this.ValorFrete            = ord.ValorFrete__c;
            this.TipoOrdem             = ord.type;//RecordType?.DeveloperName;
            this.EnderecoEntrega       = ord.EnderecoEntrega__c;
            this.EnderecoEntregaId       = ord.Endereco_Entrega__c;
            this.EstadoCliente         = ord.Account.BillingState;
            this.NumeroPedidoCliente   = ord.NumeroPedidoCliente__c;
            this.DtPrevistaEntrega     = ord.DataEntrega__c;
            this.Observacao            = ord.Account?.Observacoes__c;
            this.ObservacaoNotaFiscal  = ord.MensagemNF__c;
            this.ObservacaoPedido      = ord.ObservacoesPedido__c;
            this.DtParcelas            = ord.DatasParcelas__c != null ? reformatInstallmentDates(ord.DatasParcelas__c) : null;
            system.debug(this.DtParcelas);
            this.FretesPorCd           = ord.Frete__c;
            this.ClienteRecebedor      = ord.ClienteRecebedor__c;
            this.ClienteRecebedorCGC   = ord.ClienteRecebedor__r?.CNPJ__c;
            this.StatusPedido          = ord.StatusIntegracao__c;
            this.Status                = ord.Status;
            this.ClienteBloqueado      = ord.Account?.Bloqueado__c == 'Ativo' ? true : false;
            this.BloqueioFinanceiro    = (ord.Account?.Saldo__c <= 0 || (ord.Account?.GrauRisco__c != 'A' && ord.Account?.GrauRisco__c != 'B')) ? true : false;
            this.PedidoComplementar    = ord.PedidoPendente__c;
            this.Idportalcotacoes      = ord.Idportalcotacoes__c;
            this.allRecAnswered        = ord.RecomendacaoRespondida__c;
            this.enderecoCobranca = new EnderecoCobranca();
            this.enderecoCobranca.RuaCobranca = ord.Account.BillingStreet;
            this.enderecoCobranca.CidadeCobranca = ord.Account.BillingCity;
            this.enderecoCobranca.EstadoCobranca = ord.Account.BillingState;
            this.enderecoCobranca.PaisCobranca = ord.Account.BillingCountry;
            this.enderecoCobranca.CEPCobranca = ord.Account.BillingPostalCode;

            if (this.ClienteRecebedor != null) {
                this.enderecoCobrancaRecebedor = new EnderecoCobranca();
                this.enderecoCobrancaRecebedor.RuaCobranca = ord.ClienteRecebedor__r.BillingStreet;
                this.enderecoCobrancaRecebedor.CidadeCobranca = ord.ClienteRecebedor__r.BillingCity;
                this.enderecoCobrancaRecebedor.EstadoCobranca = ord.ClienteRecebedor__r.BillingState;
                this.enderecoCobrancaRecebedor.PaisCobranca = ord.ClienteRecebedor__r.BillingCountry;
                this.enderecoCobrancaRecebedor.CEPCobranca = ord.ClienteRecebedor__r.BillingPostalCode;
            }
            if(ord.Account?.GeraBoleto__c){
                this.GeraBoleto = 'Boleto';
            }else{
                this.GeraBoleto = 'Carteira';
            }
        }
    }

    public class OrderItemData {
        @AuraEnabled public String id                        {get; set;}
        @AuraEnabled public String cdId                      {get; set;}
        @AuraEnabled public String itemId                    {get; set;}
        @AuraEnabled public String pbEntryId                 {get; set;}
        @AuraEnabled public String prodId                    {get; set;}
        @AuraEnabled public String prodCode                  {get; set;}
        @AuraEnabled public String nome                      {get; set;}
        @AuraEnabled public String principioAtivo            {get; set;}
        @AuraEnabled public String fabricante                {get; set;}
        @AuraEnabled public String anvisa                    {get; set;}
        @AuraEnabled public String categoria                 {get; set;}
        @AuraEnabled public String precoFabricaCx            {get; set;}
        @AuraEnabled public String precoFabricaUn            {get; set;}
        @AuraEnabled public String precoTabelaCx             {get; set;}
        @AuraEnabled public String precoTabelaUn             {get; set;}
        @AuraEnabled public String temperatura               {get; set;}
        @AuraEnabled public String ean                       {get; set;}
        @AuraEnabled public String index                     {get; set;}
        @AuraEnabled public String cds                       {get; set;}
        @AuraEnabled public String cnpjCd                    {get; set;}
        @AuraEnabled public String lote                      {get; set;}
        @AuraEnabled public Decimal estoque                  {get; set;}
        @AuraEnabled public Decimal estoqueUn                {get; set;}
        @AuraEnabled public String un                        {get; set;}
        @AuraEnabled public Decimal quantidade               {get; set;}
        @AuraEnabled public Decimal quantidadeCx             {get; set;}
        @AuraEnabled public String unitario                  {get; set;}
        @AuraEnabled public String caixa                     {get; set;}
        @AuraEnabled public String inicialUnitario           {get; set;}
        @AuraEnabled public String inicialCaixa              {get; set;}
        @AuraEnabled public String conversaoUnidadeCx        {get; set;}
        @AuraEnabled public String listTagByCd               {get; set;}
        @AuraEnabled public Decimal desconto                 {get; set;}
        @AuraEnabled public Decimal valorTotalUnd            {get; set;}
        @AuraEnabled public Decimal valorTotalCx             {get; set;}
        @AuraEnabled public Decimal valorTotal               {get; set;}
        @AuraEnabled public Decimal valorFrete               {get; set;}
        @AuraEnabled public String tipoFrete                 {get; set;}
        @AuraEnabled public Decimal aliquota                 {get; set;}
        @AuraEnabled public Decimal score                    {get; set;}
        @AuraEnabled public Decimal scoreBU                  {get; set;}
        @AuraEnabled public Decimal scoreMix                 {get; set;}
        @AuraEnabled public Decimal scoreItem                {get; set;}
        @AuraEnabled public Decimal indexPosition            {get; set;}
        @AuraEnabled public Decimal indexInsertPosition      {get; set;}
        @AuraEnabled public Decimal custoDif                 {get; set;}
        @AuraEnabled public Decimal custoCx                  {get; set;}
        @AuraEnabled public Decimal margem                   {get; set;}
        @AuraEnabled public Decimal margemAlvo               {get; set;}
        @AuraEnabled public Decimal margemAlvoInput          {get; set;}
        @AuraEnabled public String validadeMinima            {get; set;}
        @AuraEnabled public Decimal precoMalha               {get; set;}
        @AuraEnabled public Decimal precoSugerido            {get; set;}
        @AuraEnabled public String rangeStringify            {get; set;}
        @AuraEnabled public String tipoIntegradora           {get; set;}
        @AuraEnabled public Boolean bloqRegionalizacao       {get; set;}
        @AuraEnabled public Boolean isInCampaign             {get; set;}
        @AuraEnabled public String laboratorio             {get; set;}
        @AuraEnabled public String tipoConversao             {get; set;}
        @AuraEnabled public String SequenciaOC               {get; set;}
        @AuraEnabled public String precoCNPJShelflife        {get; set;}
        @AuraEnabled public Boolean foraMalha                {get; set;}
        @AuraEnabled public Boolean showBadgeOL              {get; set;}
        @AuraEnabled public Boolean showBadgeCampanha        {get; set;}
        @AuraEnabled public Boolean showBadgeCampanhaCD      {get; set;}
		@AuraEnabled public boolean showBadgeCampanhaVendedor {get; set;}
        @AuraEnabled public Boolean showBadgeConsignado      {get; set;}
        @AuraEnabled public Boolean showBadgeAcordoComercial {get; set;}
        @AuraEnabled public Boolean showBadgeshelflife       {get; set;}
        @AuraEnabled public Boolean showBadgeReservadoCNPJ   {get; set;}
        @AuraEnabled public Boolean valorBloqueado           {get; set;}
        @AuraEnabled public String unidadePrincipal          {get; set;}
        @AuraEnabled public Boolean verMargem                {get; set;}
        @AuraEnabled public String precoCNPJCampanha         {get; set;}
        @AuraEnabled public String unidadeMedida             {get; set;}
        @AuraEnabled public String unidadeMedidaSeg          {get; set;}
        @AuraEnabled public String unidadeSecundaria          {get; set;}
        @AuraEnabled public String observacaoComercial {get; set;}
	
        public OrderItemData() {}
    }

    public class CurrentAccountData {
        @AuraEnabled public String ClienteEmissorCGC {get; set;}
        @AuraEnabled public String ClienteBloqueado {get; set;}
        @AuraEnabled public Boolean hasAlvara {get; set;}
        @AuraEnabled public Boolean hasCTR {get; set;}
        @AuraEnabled public String CRM {get; set;}

        public CurrentAccountData(Account acc) {
            this.ClienteEmissorCGC = acc.ExternalId__c;
            this.ClienteBloqueado = acc.Bloqueado__c;
            this.hasAlvara = true;
            this.hasCTR = true;
            this.CRM = acc.NumeroRegistro__c;
        }
    }

    public class ToastInfoData {
        @AuraEnabled public ToastInfo ToastInfoErrorRequired   {get; set;}
        @AuraEnabled public ToastInfo ToastInfoOrdIntegrated   {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorBlockedAcc {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorDocMissing {get; set;}
        @AuraEnabled public ToastInfo ToastInfoErrorDocExpired {get; set;}
        @AuraEnabled public ToastInfo ToastInfoWarningDeposito {get; set;}
        @AuraEnabled public ToastInfo ToastInfoWarningBoleto   {get; set;}
        @AuraEnabled public ToastInfo ToastInfoFinancialBlock  {get; set;}

        ToastInfoData() {
            this.ToastInfoErrorRequired   = new ToastInfo('Erro', 'Preencher todos os campos obrigatórios: {fields}', 'Error');
            this.ToastInfoOrdIntegrated   = new ToastInfo('Erro', 'Pedido já integrado, não pode ser editado.', 'Error');
            this.ToastInfoErrorBlockedAcc = new ToastInfo('Erro', 'O cliente possui um bloqueio financeiro.', 'Error');
            this.ToastInfoErrorDocMissing = new ToastInfo('Erro', 'O cliente possui documentos regulatórios (Alvará) pendentes.', 'Error');
            this.ToastInfoErrorDocExpired = new ToastInfo('Erro', 'O cliente possui documentos regulatórios (Alvará) fora da data de vigência.', 'Error');
            this.ToastInfoWarningDeposito = new ToastInfo('Aviso', 'Para condição de pagamento do tipo "RA", a forma de pagamento foi alterada para Depósito.', 'Warning');
            this.ToastInfoWarningBoleto   = new ToastInfo('Aviso', 'Para condição de pagamento do tipo diferente de "RA", a forma de pagamento foi alterada para Boleto.', 'Warning');
            this.ToastInfoFinancialBlock  = new ToastInfo('Aviso', 'O cliente possui um bloqueio financeiro.', 'Warning');
        }
    }
    
    public class ToastInfo {
        @AuraEnabled public String Title   {get;set;}
        @AuraEnabled public String Message {get;set;}
        @AuraEnabled public String Type    {get;set;}

        public ToastInfo(String title, String message, String type) {
            this.Title   = title;
            this.Message = message;
            this.Type    = type;
        }
    }

    public static String translateDayOfTheWeek(String engDay){
        String ptDay = '';
        if (engDay == 'Mon') {
            ptDay = 'Segunda';
        } else if (engDay == 'Tue') {
            ptDay = 'Terça';
        } else if (engDay == 'Wed') {
            ptDay = 'Quarta';
        } else if (engDay == 'Thu') {
            ptDay = 'Quinta';
        } else if (engDay == 'Fri') {
            ptDay = 'Sexta';
        }
        return ptDay;
    }

    public class ReturnObjGetProduct{ 
        @AuraEnabled public ProductData[] productDataList;
        @AuraEnabled public Map<String, List<Estoque__c>> mapProductDataToInventoryList;

        public ReturnObjGetProduct(ProductData[] productDataList, Map<String, List<Estoque__c>> mapProductDataToInventoryList) {
            this.productDataList = productDataList;
            this.mapProductDataToInventoryList = mapProductDataToInventoryList;
        }
    }

    public static void insertSolicitacao(List<OrderItem> listOrderItem, String ordId){

        //W6884 - insert SolicitacaoCompras__c and update OrderItem

        Map<String, List<Id>> cnpjCdToItemMap = new Map<String, List<Id>>();
        for (OrderItem oi : listOrderItem) {
            if (!cnpjCdToItemMap.containsKey(oi.CNPJCD__c)) {
                cnpjCdToItemMap.put(oi.CNPJCD__c, new List<Id>());
            }
            cnpjCdToItemMap.get(oi.CNPJCD__c).add(oi.Id);
        }

        List<SolicitacaoCompras__c> solicComprasList = new List<SolicitacaoCompras__c>();
        for (String cnpjCd : cnpjCdToItemMap.keySet()) {
            SolicitacaoCompras__c solicCompras = new SolicitacaoCompras__c(
                Pedido__c = ordId,
                CNPJCD__c = cnpjCd
            );
            solicComprasList.add(solicCompras);
        }
        insert solicComprasList;

        List<Id> solicComprasIdList = Collection.of(solicComprasList).pluckIds();

        List<OrderItem> ordItemList = new List<OrderItem>();
        for (SolicitacaoCompras__c solic : [SELECT Id, CNPJCD__c FROM SolicitacaoCompras__c WHERE Id IN :solicComprasIdList]) {
            for (Id oiId : cnpjCdToItemMap.get(solic.CNPJCD__c)) {
                OrderItem ordItem = new OrderItem(
                    Id                    = oiId,
                    SolicitacaoCompras__c = solic.Id
                );
                ordItemList.add(ordItem);
            }
        }
        OrderHandler.disableTrigger();
        update ordItemList;
        OrderHandler.enableTrigger();

        
        if (!solicComprasIdList.isEmpty()) {     
            System.enqueueJob(new IntegrationPurchaseReqQueueable(0, new List<Id>(solicComprasIdList)));     
        }
    }
}