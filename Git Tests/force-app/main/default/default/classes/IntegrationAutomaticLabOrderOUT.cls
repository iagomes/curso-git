global without sharing class IntegrationAutomaticLabOrderOUT {

    global class LabRequest {
        public List<LabOrderRequest> pedidos;

        public LabRequest() {
            this.pedidos = new List<LabOrderRequest>();
        }
    }
    
    global class LabOrderRequest {
        public String CgcEmp;
        public String PedidoERP;
        public String CondicaoPagamento;
        public String ObsNF;
        public String ObsPedido;
        public Decimal ValorParcela1;
        public String  DataParcela1;
        public Decimal ValorParcela2;
        public String  DataParcela2;
        public Decimal ValorParcela3;
        public String  DataParcela3;
        public Decimal ValorParcela4;
        public String  DataParcela4;
        public List<LabOrderItemRequest> itens;

        public LabOrderRequest(Order ord, String cnpjCD, Decimal valorTotalCd, List<LabOrderItemRequest> lItens) {
            this.CgcEmp            = cnpjCD;
            this.PedidoERP         = ord.ExternalId__c != null ? getExternalId(ord.ExternalId__c) : '';
            this.CondicaoPagamento = ord.CondicaoPagamento__r?.ExternalId__c;
            this.ObsNF             = ord.MensagemNF__c;
            this.ObsPedido         = ord.ObservacoesPedido__c;

            this.ValorParcela1 = 0;
            this.DataParcela1  = null;
            this.ValorParcela2 = 0;
            this.DataParcela2  = null;
            this.ValorParcela3 = 0;
            this.DataParcela3  = null;
            this.ValorParcela4 = 0;
            this.DataParcela4  = null;
            this.itens = lItens;
            
            if (ord.DatasParcelas__c != null) {
                List<String> listInstDates = OrderScreenController.reformatInstallmentDates(ord.DatasParcelas__c).remove('-').split(',');
                Decimal totalOrderValue = IntegrationOrderOUT.getTotalOrderValue(ord, valorTotalCd, listInstDates.size()).setScale(2);
                
                Decimal valParcela = listInstDates.size() == 0 ? 0 : IntegrationOrderOUT.getTotalOrderParcel(ord, valorTotalCd, listInstDates.size()).setScale(2);

                Decimal calculoDiferenca = (totalOrderValue - (valParcela * listInstDates.size())).setScale(2);
                system.debug('Valor parcela: ' + valParcela);
    
                if (listInstDates.size() >= 1) {
                    this.ValorParcela1 = valParcela + calculoDiferenca;
                    this.DataParcela1  = listInstDates[0].trim();
                    if (listInstDates.size() >= 2) {
                        this.ValorParcela2 = valParcela;
                        this.DataParcela2  = listInstDates[1].trim();
                        if (listInstDates.size() >= 3) {
                            this.ValorParcela3 = valParcela;
                            this.DataParcela3  = listInstDates[2].trim();
                            if (listInstDates.size() == 4) {
                                this.ValorParcela4 = valParcela;
                                this.DataParcela4  = listInstDates[3].trim();
                            }
                        }
                    }
                }
            }
        }
    }

    global class LabOrderItemRequest {
        public String produto;
        public Decimal preco;

        public LabOrderItemRequest(String prod, Decimal preco) {
            this.produto = prod;
            this.preco = preco;
        }
    }

    public class ResultClass {
        public String  result   { get; set; }
        public String incluido { get; set; }
    }

    // IntegrationAutomaticLabOrderOUT.sendApprovalOrderToERP('801q0000001DUQdAAO');

    public static void sendAutomaticLabOrderToERP(Id ordId) {
        sendAutomaticLabOrderToERP(ordId, null);
    }

    public static void sendAutomaticLabOrderToERP(Id ordId, String integrationLogName) {
        system.debug('sendAutomaticLabOrderToERP');
        
        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaAutomaticLabOrderAPI');
        
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setTimeout(120000);

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));

        LabRequest orderReq = new LabRequest();
        String cnpjCD = '';
        Decimal valorTotalCd = 0;

        List<LabOrderItemRequest> listLabOrdItemReq = new List<LabOrderItemRequest>();
        for (OrderItem orderItem : [SELECT Id, CNPJCD__c, TotalPrice, Product2.ProductCode, UnitPrice FROM OrderItem WHERE OrderId = :ordId LIMIT 1]) {
            cnpjCD = orderItem.CNPJCD__c;
            system.debug('orderItem.TotalPrice: ' + orderItem.TotalPrice);
            valorTotalCd += orderItem.TotalPrice.setScale(2, RoundingMode.HALF_UP);
            listLabOrdItemReq.add(new LabOrderItemRequest(orderItem.Product2.ProductCode, orderItem.UnitPrice));
        }
        Boolean shouldSend = true;
        for (Order order : [SELECT 
                                Id, 
                                ExternalId__c, 
                                Status, 
                                OrderNumber,
                                CNPJCD__c, 
                                CondicaoPagamento__r.ExternalId__c, 
                                MensagemNF__c,
                                ObservacoesPedido__c,
                                Description,
                                DatasParcelas__c,
                                ValorFrete__c
                            FROM Order 
                            WHERE Id = :ordId]) {
            if (cnpjCD == null || cnpjCD == '') {
                cnpjCD = order.CNPJCD__c;
            }
            orderReq.pedidos.add(new LabOrderRequest(order, cnpjCD, valorTotalCd, listLabOrdItemReq));
        }
        System.debug('orderReq: ' + orderReq);

        String body;
        body = Json.serialize(orderReq);
        System.debug('Body: '+ body);

        HttpResponse resp = new HttpResponse();
        try {
            Boolean hasError = false;
            req.setBody(body);
            resp = new Http().send(req);
            
            System.debug(resp);
            System.debug(resp.getStatusCode());

            if (resp.getStatusCode() != 200 && resp.getStatusCode() != 201) {hasError = true;}

            if(integrationLogName == null) {
                IntegrationUtils.WSLog('Pedido de laboratório automático', 'Outbound', body, resp.getBody(), hasError);
            } else {
                IntegrationUtils.WSLog(integrationLogName, 'Outbound', body, resp.getBody(), hasError);
            }

            try {
                ResultClass resClass = (ResultClass)JSON.deserialize(resp.getBody(), ResultClass.class);
            } catch (Exception e) {
                system.debug(e.getMessage());
            }

        } catch (Exception e) {
            System.debug(e.getMessage() +''+e.getStackTraceString());
        }
    }
    
    public static String getExternalId(String val){
        return val.trim().substring(5, val.length());
    }
}