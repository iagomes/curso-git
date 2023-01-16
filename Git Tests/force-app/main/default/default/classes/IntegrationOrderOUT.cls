global without sharing class IntegrationOrderOUT {
    public static final String STATUS_INTEGRATED = 'Integrado';
    public static final String STATUS_ERROR = 'Não Integrado';
    public static final Id MOTHERORDER_RECORDTYPE  = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();
    public static final Id BONIF_RECORDTYPPE       = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoBonificacao').getRecordTypeId(); 
    public static final Id ACC_ORDER_RECORDTYPE    = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoContaOrdem').getRecordTypeId(); 
    public static final Id DIRECT_ORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoVenda').getRecordTypeId(); 

    global class OrderRequest {
        public String BranchCGC;//CgcEmp;
        public String CustomerCGC;//CgcCli;
        public String IntegrationCode;//TpInteg;
        public String LaboratoryID;//laboratorio;
        public String IntegrationRule;//regra;
        public String ExternalOrderNumber;//PedidoIntegrador;
        public String ExternalMainOrderNumber;//PedidoPai;
        public String PaymentTerm;//CondicaoPagamento;
        public String Boleto;//boleto
        public String PriceList;//TabelaPreco;
        public String FreightType;//TipoFrete;
        public String OrderMessage;//observacoes;
        public String UserCode;//usuario;
        public String InvoiceMessage;//ObservacoesNF;
        public Decimal FreightValue;//ValorFrete;
        public Decimal InstallmentValue1;//ValorParcela1;
        public String  InstallmentDate1;//DataParcela1;
        public Decimal InstallmentValue2;//ValorParcela2;
        public String  InstallmentDate2;//DataParcela2;
        public Decimal InstallmentValue3;//ValorParcela3;
        public String  InstallmentDate3;//DataParcela3;
        public Decimal InstallmentValue4;//ValorParcela4;
        public String  InstallmentDate4;//DataParcela4;
        public Boolean Approved;
        public Decimal Discount = 0;
        public List<OrderItensRequest> Items;
        
        public OrderRequest (Order ord, list<OrderItensRequest> listOrderItens, String cnpjCD, Decimal valorTotalCd, Decimal discount) {
            this.BranchCGC         = cnpjCD;
            this.CustomerCGC       = ord.CNPJ__c == null ? ord.CPF__c : ord.CNPJ__c;
            this.IntegrationCode   = '11';
            this.LaboratoryID      = 'SFC';
            this.IntegrationRule   = 'CD';
            this.ExternalOrderNumber  = ord.OrderNumber;
            this.ExternalMainOrderNumber         = ord.PedidoPai__r?.OrderNumber;
            this.PaymentTerm       = ord.CondicaoPagamento__r?.ExternalId__c == null ? '' : ord.CondicaoPagamento__r?.ExternalId__c;
            this.PriceList         = ord.Pricebook2.ExternalId__c;
            this.FreightType       = ord.TipoFrete__c == null ? '' : getERPFreight(ord.TipoFrete__c);
            //this.observacoes       = ord.Description == null ? 'Número do pedido: ' + ord.OrderNumber : 'Número do pedido: ' + ord.OrderNumber + ' - ' + ord.Description;
            this.OrderMessage      = ord.ObservacoesPedido__c == null ? 'Número do pedido: ' + ord.OrderNumber : 'Número do pedido: ' + ord.OrderNumber + ' - ' + ord.ObservacoesPedido__c;
            this.Boleto            = ord.FormaPagamento__c == 'Boleto' ? 'S' : 'N';
            this.UserCode          = isNull(ord.CreatedBy.CodigoUsuarioProtheus__c);
            string logradouro = ord.Endereco_Entrega__c  == null ? '' : ord.Endereco_Entrega__r.Logradouro__c;
            if(logradouro != ''){
                if(ord.Endereco_Entrega__r.Numero__c != null){
                    logradouro += ' ' ;
                    logradouro += ord.Endereco_Entrega__r.Numero__c;
                }
                if(ord.Endereco_Entrega__r.Complemento__c != null){
                    logradouro += ' ' ;
                    logradouro += ord.Endereco_Entrega__r.Complemento__c;
                }
            }
            String endereco        = ord.Endereco_Entrega__c  == null ? '' : logradouro + ' - ' + ord.Endereco_Entrega__r.Bairro__c + ' - ' + ord.Endereco_Entrega__r.Cidade__c + ' - ' + ord.Endereco_Entrega__r.Estado__c + ', ' + ord.Endereco_Entrega__r.CEP__c + ' - ';
            String obsNF           = 'Pedido cliente: ' + isNull(ord.NumeroPedidoCliente__c) + ' - Local de entrega: ' + (ord.TipoFrete__c == 'CLIENTE RETIRA' ? 'CLIENTE IRÁ RETIRAR A MERCADORIA' : endereco) + isNull(ord.MensagemNF__c);
            //obsNF = normalizeSpecialCharacters(obsNF);
            this.InvoiceMessage    = obsNF.subString(0, obsNF.length() > 254 ? 254 : obsNF.length());
            this.Items             = listOrderItens;

            system.debug(ord.ValorFrete__c);
            system.debug(ord.DatasParcelas__c);
            system.debug(ord.Frete__c);

            this.FreightValue      = ord.ValorFrete__c != null ? ord.ValorFrete__c : 0;

            this.InstallmentValue1 = 0;
            this.InstallmentDate1  = null;
            this.InstallmentValue2 = 0;
            this.InstallmentDate2  = null;
            this.InstallmentValue3 = 0;
            this.InstallmentDate3  = null;
            this.InstallmentValue4 = 0;
            this.InstallmentDate4  = null;
            this.Approved      = ord.PedidoPai__r.Status == 'Aprovado' && ord.CondicaoPagamento__r?.ExternalId__c != 'RA' ? True : False;
            this.discount      = discount;
            
            if (ord.DatasParcelas__c != null) {
                List<String> listInstDates = OrderScreenController.reformatInstallmentDates(ord.DatasParcelas__c).remove('-').split(',');
                Decimal totalOrderValue = getTotalOrderValue(ord, valorTotalCd, listInstDates.size()).setScale(2);
                
                Decimal valParcela = listInstDates.size() == 0 ? 0 : getTotalOrderParcel(ord, valorTotalCd, listInstDates.size()).setScale(2);

                Decimal calculoDiferenca = (totalOrderValue - (valParcela * listInstDates.size())).setScale(2);
                system.debug('Valor parcela: ' + valParcela);
    
                if (listInstDates.size() >= 1) {
                    this.InstallmentValue1 = valParcela + calculoDiferenca;
                    this.InstallmentDate1  = listInstDates[0].trim();
                    if (listInstDates.size() >= 2) {
                        this.InstallmentValue2 = valParcela;
                        this.InstallmentDate2  = listInstDates[1].trim();
                        if (listInstDates.size() >= 3) {
                            this.InstallmentValue3 = valParcela;
                            this.InstallmentDate3  = listInstDates[2].trim();
                            if (listInstDates.size() == 4) {
                                this.InstallmentValue3 = valParcela;
                                this.InstallmentDate4  = listInstDates[3].trim();
                            }
                        }
                    }
                }
            }
        }
    }

    public static String normalizeSpecialCharacters(String textToBeConverted) {

        Map<String, String> normalizeMap = new Map<String, String>{
            'A' => '[ÀÁÂÃ]',
            'a' => '[àáâã]',
            'E' => '[ÈÉÊ]',
            'e' => '[èéê]',
            'I' => '[ÌÍÎ]',
            'i' => '[ìíî]',
            'O' => '[ÒÓÔÕ]',
            'o' => '[òóôõ]',
            'U' => '[ÙÚÛ]',
            'u' => '[ùúû]',
            'C' => '[Ç]',
            'c' => '[ç]',
            'n' => '[ñ]',
            'N' => '[Ñ]',
            '' => '[^a-zA-Z0-9\\s+]'
        };

        for (String key : normalizeMap.keySet()) {
            textToBeConverted = textToBeConverted.replaceAll(normalizeMap.get(key), key);
        } 
        return textToBeConverted;
    }

    global class OrderItensRequest {
        public String ProductCode;//produto;
        public String OperationCode;//TpOper;
        public String ShelfLife;
        public String BatchCode;//lote;
        public Decimal Price;//preco;
        public Decimal Quantity;//quantidade;
        public String PurchaseOrder;//OrdemCompra;
        public String PurchaseOrderItem;//ItemOrdemCompra;
        // public Decimal Discount;
        
        public OrderItensRequest (OrderItem orderItem) {
            this.ProductCode         = orderItem.CodigoProduto__c; 
            this.OperationCode          = getOperationType(orderItem); 
            this.ShelfLife       = orderItem.CampanhaShelfLife__c ? '' : isNull(orderItem.ValidadeMinima__c);
            this.BatchCode            = isNull(orderItem.Lote__c); 
            this.Price           = orderItem.UnitPrice; 
            this.Quantity      = orderItem.Quantity; 
            this.PurchaseOrder     = isNull(orderItem.Order.NumeroPedidoCliente__c);
            this.PurchaseOrderItem = isNull(orderItem.SequenciaOC__c);
            //CampanhaShielfLife__c
        }
    }
    public class ResultClass{
        public String result {get;set;}
        public Boolean incluido {get;set;}

    }

    public static void sendOrderToERP(Id ordId) {
        
        // String tokenERP = Test.isRunningTest() ? 'tokenERP' : IntegrationUtils.getERPAccessToken();       

        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaOrderAPI');
        
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setMethod(method);
        req.setTimeout(120000);

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));

        List<OrderItensRequest> listOrderItemReq = new List<OrderItensRequest>();
        OrderItensRequest orderItensRequest;
        String cnpjCD = '';
        String accountId = '';
        Decimal valorTotalCd = 0;
        Decimal discount = 0;
        List<OrderItem> listOrderItemUpdate = new List<OrderItem>();
        Boolean possuiItemContato = false;

        Map<String,ItemContrato__c> mapContractItem = getContractItemMap(ordId);

        for (OrderItem orderItem : [SELECT Id, UnitPrice, Quantity, TipoOperacao__c, CodigoProduto__c, Lote__c, PrecoTotal__c, ValidadeMinima__c, CNPJCD__c, CampanhaShelfLife__c,
                                            Order.RecordTypeId, Order.AccountId, Order.PedidoPai__r.AccountId, Order.PedidoPai__r.Endereco_Entrega__c, SequenciaOC__c, Order.NumeroPedidoCliente__c,TotalPrice
                                    FROM OrderItem WHERE OrderId = :ordId]) {

            orderItensRequest = new OrderItensRequest(orderItem);

            if (mapContractItem.containsKey(orderItem.CodigoProduto__c)) {

                double percent = mapContractItem.get(orderItem.CodigoProduto__c).PercentualDescontoBoleto__c / 100;                  
                
                discount += orderItem.TotalPrice * percent;

                orderItem.ItemContrato__c =  mapContractItem.get(orderItem.CodigoProduto__c).Id;
                listOrderItemUpdate.add(orderItem);
            }
            
            
            listOrderItemReq.add(orderItensRequest);
            cnpjCD = orderItem.CNPJCD__c;
            accountId = orderItem.Order.PedidoPai__r.AccountId;
            valorTotalCd += orderItem.PrecoTotal__c.setScale(2, RoundingMode.HALF_UP);
        }

        if (discount > 0) {
            possuiItemContato = true;
        }

        system.debug('listOrderItemReq: ' + listOrderItemReq);

        OrderRequest orderReq;
        Order orderContext = new Order();
        string StatusLab = '';
        for (Order order : [SELECT Id, AccountId, CNPJ__c, OrderNumber, Description, CondicaoPagamento__r.ExternalId__c, MensagemNF__c, TipoFrete__c, CreatedBy.CodigoUsuarioProtheus__c, PedidoPai__r.OrderNumber, CodigoIntegradora__c,
                                CNPJCD__c, Pricebook2.ExternalId__c, RecordTypeId, CPF__c, Endereco_Entrega__r.Bairro__c, NumeroPedidoCliente__c, ValorFrete__c, ValorTotal__c, TotalAmount,
                                Endereco_Entrega__r.CEP__c, Endereco_Entrega__r.Cidade__c, Endereco_Entrega__r.Estado__c, FormaPagamento__c, DatasParcelas__c, Frete__c, ExternalId__c, Status,
                                Endereco_Entrega__r.Logradouro__c, PedidoPai__r.Endereco_Entrega__c, Endereco_Entrega__c, Idportalcotacoes__c, Endereco_Entrega__r.Numero__c, Endereco_Entrega__r.Complemento__c, ObservacoesPedido__c, PedidoPai__r.Status FROM Order WHERE Id = :ordId]) {
            orderReq = new OrderRequest(order, listOrderItemReq, cnpjCD, valorTotalCd , discount);
            orderContext = order;
            StatusLab = order.Status;
        }

        system.debug('contractReq: ' + orderReq);

        String body;
        body = Json.serialize(orderReq);
        System.debug('Body: '+body);

        String resultString = '';
        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            system.debug(resp);
            system.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            system.debug('resp'+resultString);            
            String statusIntegracao = null;
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){        
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Pedido', 'Outbound', body, resultString, false);
            } else {
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Pedido', 'Outbound', body, resultString, true);
                statusIntegracao = STATUS_ERROR;
            }

            ResultClass resClass = null;

            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);                
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
            
            Boolean hasError    = statusIntegracao == STATUS_ERROR;
            String errorMessage = statusIntegracao == STATUS_ERROR ? 'Erro durante o envio do pedido para o Protheus, aguardar o tempo de reenvio ou enviar através do botão "Enviar para ERP".' : null;

            Order ord = new Order(
                Id                           = ordId,
                MensagemErroIntegracao__c    = errorMessage,
                ErroIntegracaoConfirmacao__c = hasError,
                PossuiItemContrato__c        = possuiItemContato
            );
            
            if (!hasError) {
                if(StatusLab != 'Aprovado na integradora' && StatusLab !=  'Aguardando processamento na integradora') {
                    ord.Status  = orderContext.ExternalId__c == null && orderContext.CodigoIntegradora__c == null ? 'Aguardando integração' : 'Pai - Em aprovação';
                }
                ord.MensagemErroIntegracaoConfirmacao__c = null;
                ord.StatusIntegracao__c                  = null;
                ord.MensagemErroIntegracao__c            = null;
            } else { 
                ord.StatusIntegracao__c = statusIntegracao;
                ord.Status              = 'ErroIntegracao';
            }

            if (listOrderItemUpdate.size() > 0) {
                OrderItemHandler.disableTrigger();
                update listOrderItemUpdate;
                OrderItemHandler.enableTrigger();
            }

            OrderHandler.disableTrigger();
            update ord;
            OrderHandler.enableTrigger();

        } catch (Exception e) {
            resultString = e.getMessage();
        }
    }

    public static String isNull(String entry) {
        return entry == null ? '' : entry;
    }

    public static String getERPFreight(String freight) {
        String erpFreight = '';
        if (freight == 'FOB') {
            erpFreight = 'F';
        } else if (freight == 'CIF') {
            erpFreight = 'C';
        } else {
            erpFreight = 'S';
        }
        return erpFreight;
    }

    public static String getOperationType(OrderItem oi) {
        String erpType = '';
        if (oi.Order.RecordTypeId == BONIF_RECORDTYPPE) {
            erpType = '20';
        } else if (oi.Order.RecordTypeId == ACC_ORDER_RECORDTYPE) {
            if (oi.Order.AccountId == oi.Order.PedidoPai__r.AccountId) {
                // erpType = '35';
                erpType = '09';
            } else {
                // erpType = '07';
                erpType = '30';
            }
        } else if (oi.Order.RecordTypeId == DIRECT_ORDER_RECORDTYPE) {
            erpType = '01';
        }
        return erpType;
    }

    public static Decimal getTotalOrderValue(Order ord, Decimal valorTotalCd, Decimal installmentQuantity) {
        return ((ord.ValorFrete__c != null ? ord.ValorFrete__c : 0) + valorTotalCd);
    }

    public static Decimal getTotalOrderParcel(Order ord, Decimal valorTotalCd, Decimal installmentQuantity) {
        return (((ord.ValorFrete__c != null ? ord.ValorFrete__c : 0) + valorTotalCd) / installmentQuantity);
    }

    public static Map<String, ItemContrato__c> getContractItemMap(String ordId) {
        

        Map<String, ItemContrato__c> mapContractItens = new Map<String, ItemContrato__c>();

        Account acc = new Account(Id = [SELECT AccountId FROM Order Where id =:ordId].AccountId);

        for (ItemContrato__c item : [SELECT id, CodigoProduto__c, PercentualDescontoBoleto__c FROM ItemContrato__c WHERE Status__c = 'Aprovado' AND PercentualDescontoBoleto__c > 0 AND NumeroContrato__r.AccountId =: acc.Id AND NumeroContrato__r.TipoRegra__c = 'O']) {

            if (!mapContractItens.containsKey(item.CodigoProduto__c)) {

                mapContractItens.put(item.CodigoProduto__c, item);
                
            }
            
        }


       return mapContractItens;

    }
}