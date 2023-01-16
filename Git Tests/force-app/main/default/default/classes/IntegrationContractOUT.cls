global without sharing class IntegrationContractOUT {

    global class ContractRequest {
        public String CgcCliente;
        public String TipoRegra;
        public String CodSalesForce;
        public String observacoes;
        public String descricao;
        public String ArquivoOL;
        public List<ContractItensRequest> itens;
        
        public ContractRequest (Contract con, list<ContractItensRequest> listContractItens){
            this.CgcCliente    = con.Account.CNPJ__c != null ? con.Account.CNPJ__c : con.Account.CPF__c;
            this.TipoRegra     = con.TipoRegra__c;
            this.CodSalesForce = con.Id;
            this.observacoes   = con.Description;
            this.descricao     = con.Description;
            this.ArquivoOL     = this.TipoRegra == 'O' ? 'S' : 'N';
            this.itens         = listContractItens;

        }
    }

    global class ContractItensRequest {
        public String produto;
        //public String ProdutoElfa;
        public String VigenciaInicial;
        public String VigenciaFinal;
        public String lote;
        public String validade;
        public String uf;
        public Decimal preco;
        public Decimal PrecoMinimo;
        public Decimal PercDesconto;
        // public Decimal PercentualDescontoBoleto;
        
        public ContractItensRequest (ItemContrato__c contractItem){
            this.produto         = contractItem.CodigoProduto__c; 
            //this.ProdutoElfa     = contractItem.NomeProduto__r.ProductCodeElfa__c; 
            this.VigenciaInicial = contractItem.VigenciaInicial__c == null ? null : getFormattedDate(contractItem.VigenciaInicial__c); 
            this.VigenciaFinal  = contractItem.VigenciaFinal__c == null ? null : getFormattedDate(contractItem.VigenciaFinal__c);
            this.uf              = contractItem.NumeroContrato__r.Account.ShippingState;  
            this.lote            = contractItem.Lote__c; 
            this.PercDesconto    = contractItem.Desconto__c; 
            this.preco           = contractItem.PrecoUnitario__c; 
            this.validade        = contractItem.ValidadeLote__c == null ? null : getFormattedDate(contractItem.ValidadeLote__c); 
            this.PrecoMinimo     = contractItem.PrecoMinimo__c; 
            // this.PercentualDescontoBoleto     = contractItem.PercentualDescontoBoleto__c; // precisamos do nome desse campo na estrutura Json para enviar ao ERP
        }
    }
    public class ResultClass{
        public String result {get;set;}
        public Boolean incluido {get;set;}

    }

    public static void sendContractToERP(Id conId) {
        
        // String tokenERP = Test.isRunningTest() ? 'tokenERP' : IntegrationUtils.getERPAccessToken();       

        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaContractAPI');
        
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        // req.setHeader('Username', username);
        // req.setHeader('Password', password);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setTimeout(120000);

        System.debug(EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));

        List<ContractItensRequest> listContractItemReq = new List<ContractItensRequest>();

        for (ItemContrato__c contractItem : [SELECT Id, NumeroContrato__r.Account.ShippingState, CodigoProduto__c, VigenciaInicial__c, VigenciaFinal__c, Lote__c, ValidadeLote__c, PrecoUnitario__c, 
                                             PrecoMinimo__c, Desconto__c, Status__c, PercentualDescontoBoleto__c FROM ItemContrato__c WHERE NumeroContrato__c =: conId]) {
            listContractItemReq.add(new ContractItensRequest(contractItem));
        }

        system.debug('listContractItemReq: ' + listContractItemReq);

        ContractRequest contractReq;

        for (Contract cont : [SELECT Id, AccountId, Account.CNPJ__c, Account.CPF__c, TipoRegra__c, CodigoContrato__c, Description FROM Contract WHERE Id =: conId]) {
            contractReq = new ContractRequest(cont, listContractItemReq);
        }

        system.debug('contractReq: ' + contractReq);

        String body;
        body = Json.serialize(contractReq);
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
            
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){        
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Contrato', 'Outbound', body, resultString, false);
            } else {
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Contrato', 'Outbound', body, resultString, true);
            }

            ResultClass resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);
            
            ContractHandler.disableTrigger();
            update new Contract(Id = conId, RetornoIntegracao__c = resClass.result.subString(0,resClass.result.length() > 255 ? 255 : resClass.result.length()));
            ContractHandler.enableTrigger();

        } catch (Exception e) {
            resultString = e.getMessage();
        }
    }

    // method to get ERP's date format
    public static String getFormattedDate(Date data) {
        return String.valueOf(data.year()) + (data.month() <= 9 ? '0'+String.valueOf(data.month()) : String.valueOf(data.month())) + (data.day() <= 9 ? '0'+String.valueOf(data.day()) : String.valueOf(data.day()));
    }


}
