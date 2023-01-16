global without sharing class IntegrationPurchaseReqOUT {

    global class PurchaseRequest {
        public String CgcEmp;
        public String CgcCliente;
        public String usuario;
        public String ObservacoesPedido;
        public String ObservacoesNF;
        public String origem;
        public List<OrderItensRequest> itens;
        
        public PurchaseRequest (SolicitacaoCompras__c pReq, list<OrderItensRequest> listOrderItens) {
            this.CgcEmp            = pReq.CNPJCD__c;
            this.CgcCliente        = pReq.Pedido__r.CNPJ__c;
            this.usuario           = 'elfa.middleware';
            this.ObservacoesPedido = pReq.Pedido__r.Description == null ? '' : pReq.Pedido__r.Description;
            this.ObservacoesNF     = pReq.Pedido__r.MensagemNF__c == null ? '' : pReq.Pedido__r.MensagemNF__c;
            this.origem            = 'SFC';
            this.itens             = listOrderItens;      
        }
    }

    global class OrderItensRequest {
        public String  produto;
        public String  item;
        public Decimal quantidade;
        public Decimal ValorEstimado;
        public String  CCusto;
        public String  PrevisaoFaturamento;
        public String  observacao;
        
        public OrderItensRequest (OrderItem orderItem, Integer ordItemSize, String CentroCusto) {
            this.produto             = orderItem.CodigoProduto__c; 
            this.item                = ordItemSize < 10 ? '0' + String.valueOf(ordItemSize) : String.valueOf(ordItemSize); 
            this.quantidade          = orderItem.Quantity; 
            this.ValorEstimado       = orderItem.UnitPrice;
            this.CCusto              = CentroCusto; 
            this.PrevisaoFaturamento = Date.today().format(); 
            this.observacao          = ''; 
        }
    }

    public class ResultClass{
        public String Result {get;set;}
        public String Doc {get;set;}
        public String lret {get;set;}
    }

    public static void sendPurchaseReqToERP(Id purshReqId) {
        
        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaPurchaseReqAPI');
        
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

        List<SolicitacaoCompras__c> pReqList = [
            SELECT 
                Id,
                Pedido__r.CNPJ__c,
                Pedido__r.Description,
                Pedido__r.MensagemNF__c,
                CreatedBy.CodigoUsuarioProtheus__c,
                CNPJCD__c,
                StatusIntegracao__c,
                MensagemIntegracao__c,
                CodigoSolicitacao__c,  
                ( 
                    SELECT
                        Id, 
                        UnitPrice,
                        Quantity,
                        CodigoProduto__c,
                        CNPJCD__c,
                        Custo__c
                    FROM Itens_de_pedido__r
                )
            FROM SolicitacaoCompras__c WHERE Id = :purshReqId
        ];
        PurchaseRequest purshReq;

        GeneralParameters__c gParam = GeneralParameters__c.getValues('Parametro geral');
        
        for (SolicitacaoCompras__c pReq : pReqList) {
            purshReq = fillOrderItems(pReq, gParam.CentroCusto__c);
        }

        System.debug('purshReq: ' + purshReq);

        String body;
        body = Json.serialize(purshReq);
        System.debug('Body: '+body);

        String resultString = '';
        HttpResponse resp = new HttpResponse();
        try {
            req.setBody(body);
            resp = new Http().send(req);
            System.debug(resp);
            System.debug(resp.getStatusCode());
            
            resultString = resp.getBody();
            System.debug('resp'+resultString);
            Boolean hasError = false;
            String message = '';
            String doc = '';
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){        
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Solicitação de compras', 'Outbound', body, resultString, false);
            } else {
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Solicitação de compras', 'Outbound', body, resultString, true);
                hasError = true;
            }
            ResultClass resClass = null;
            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
                message  = resClass.Result;
                doc      = resClass.Doc;
            } catch (Exception e) {
                System.debug(e.getMessage());
                hasError = true;
                message  = 'Erro no envio da solicitação de compras';
            }
            SolicitacaoCompras__c purchaseReq = pReqList[0];
            purchaseReq.StatusIntegracao__c   = hasError ? 'Erro' : 'Sucesso';
            purchaseReq.MensagemIntegracao__c = hasError ? message : null;
            purchaseReq.CodigoSolicitacao__c  = doc != '' ? doc : null;
            update purchaseReq;

        } catch (Exception e) {
            resultString = e.getMessage();
        }
    }

    public static PurchaseRequest fillOrderItems(SolicitacaoCompras__c pReq, String CentroCusto) {
        List<OrderItensRequest> listOrderItemReq = new List<OrderItensRequest>();
        Integer count = 1;
        for (OrderItem oi : pReq.Itens_de_pedido__r) {
            listOrderItemReq.add(new OrderItensRequest(oi, count++, CentroCusto));
        }
        return new PurchaseRequest(pReq, listOrderItemReq);
    }

}
