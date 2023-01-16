public without sharing class PaymentSlipPreviewController {
    
    @AuraEnabled
    public static String getPaymentSlip(String recordId){
        String cgc;
        if (recordId != null){
            NotasFiscais__c nf = [SELECT Name, Id,Conta__r.CNPJ__c,Conta__c,Conta__r.CPF__c,Conta__r.RecordType.Name 
                                FROM NotasFiscais__c 
                                WHERE Id =: recordId];

            if (nf.Conta__r.RecordType.Name == 'Pessoa Jurídica'){
                cgc = nf.Conta__r.CNPJ__c;
            }
            else if (nf.Conta__r.RecordType.Name == 'Pessoa Física'){
                cgc = nf.Conta__r.CPF__c;
            }
        }
        
        String json = calloutPaymantSlip(cgc);
        return json;
    }
    @AuraEnabled

    public static RetornoErro getBoleto(String recordId, String cgc, String numeroBoleto, String prefixo, String tipo, String parcela){
        RetornoErro RetornoErro = new RetornoErro();
        RetornoErro.msg = '';
        boleto boleto = new boleto();
        boleto.cnpj_cd = cgc;
        boleto.NumeroBoleto = numeroBoleto;
        boleto.prefixo = prefixo;
        boleto.tipo = tipo;
        boleto.parcela = parcela;

        // system.debug('boleto ' + boleto);
        // boleto.cnpj_cd = '52202744000192';
        // boleto.NumeroBoleto = '000900039';
        // boleto.prefixo = '1';
        // boleto.tipo = 'NF';
        // boleto.parcela = '';

        String jsonRetorno = '';
        jsonRetorno = calloutBoleto(JSON.serialize(boleto));
        RetornoBoleto RetornoBoleto = new RetornoBoleto();
        RetornoBoleto = (RetornoBoleto) JSON.deserialize(jsonRetorno, RetornoBoleto.class);

        Attachment attach = new Attachment();
        if(RetornoBoleto.lret){
            string nomePDF = numeroBoleto + '.pdf';
            nomePDF.replaceAll(' ', ''); 
            attach.contentType = 'application/pdf';
            attach.name = nomePDF;
            attach.parentId =  recordId ; //'0012100000w6s7BAAQ';
            attach.body = EncodingUtil.base64Decode(RetornoBoleto.boleto);
            insert attach;
            RetornoErro.boleto = attach.Id;
        }else{
            RetornoErro.msg = RetornoBoleto.result;
        }
        
        return RetornoErro; 
    }
    
    public static String calloutPaymantSlip(String cgc){

        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaTitulosAbertosAPI');
        
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Username', username);
        req.setHeader('Password', password);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setBody('{"CGC":"'+cgc+'"}');
        req.setTimeout(120000);
        HttpResponse response = http.send(req);

        // HttpRequest request = new HttpRequest();
        // //Obs: foi criada uma credencial nomeada na org para autenticação.
        // request.setEndpoint('callout:paymentSlip');
        // request.setMethod('POST');
        // request.setHeader('Username', '{!$Credential.Username}');
        // request.setHeader('Password', '{!$Credential.Password}');
        // request.setHeader('Content-Type', 'application/json');
        // request.setBody('{"CGC":"'+cgc+'"}');
        // request.setTimeout(120000);
        // HttpResponse response = http.send(request);
        
        return response.getBody();
    }

     @AuraEnabled
    public static String getPaymentTitle(String recordId){

        String cgc;
        Account acc = new Account();
        system.debug ('recordId ' + recordId);       
        if (recordId != null && recordId != '' ){
            acc = [SELECT Name, Id,CNPJ__c, CPF__c,RecordType.Name , LimiteCredito__c, GrauRisco__c
                                FROM Account 
                                WHERE Id =: recordId];
            if (acc.RecordType.Name == 'Pessoa Jurídica'){
                cgc = acc.CNPJ__c;
            } else if (acc.RecordType.Name == 'Pessoa Física'){
                cgc = acc.CPF__c;
            }
        }

        pgTituloAberto pgTitulos = new pgTituloAberto();
        System.debug(11);
        pgTitulos.semTitulo = true;
        String jsonString = calloutPaymantSlip(cgc);
        //  String jsonString = 
        //  '{"TituloAberto":[{"FILIAL":"01001","EMPRESA":"ATRIAL","NUM":"000764527","LINDIGITAVEL":"","PREFIXO":"1  ","CLIENTE":"034167","LOJA":"0001","CGC":"00136858000188","NUMBCO":"               ","PARCELA":"  ","PEDIDO":"068411","BANCO":"","AGENCIA":"","CONTA":"          ","EMISSAO":"20201215","VENCREA":"20210114","VALOR":100.5,"SALDO":100.5,"MULTA":0.0,"ORIGEM":"ATRIAL","DATA_INCLUSAO":"2021-06-08T00:22:03Z","DATA_ALTERACAO":"2021-06-08T11:27:22Z","DIFF":"","TIPO":"NF "},{"FILIAL":"01001","EMPRESA":"ATRIAL","NUM":"000772478","LINDIGITAVEL":"","PREFIXO":"1  ","CLIENTE":"034167","LOJA":"0001","CGC":"00136858000188","NUMBCO":"               ","PARCELA":"  ","PEDIDO":"080423","BANCO":"","AGENCIA":"","CONTA":"          ","EMISSAO":"20210125","VENCREA":"20210224","VALOR":241.5,"SALDO":241.5,"MULTA":0.0,"ORIGEM":"ATRIAL","DATA_INCLUSAO":"2021-06-08T00:22:03Z","DATA_ALTERACAO":"2021-06-08T11:27:22Z","DIFF":"","TIPO":"NF "},{"FILIAL":"01001","EMPRESA":"ATRIAL","NUM":"000781352","LINDIGITAVEL":"","PREFIXO":"1  ","CLIENTE":"034167","LOJA":"0001","CGC":"00136858000188","NUMBCO":"               ","PARCELA":"  ","PEDIDO":"086499","BANCO":"","AGENCIA":"","CONTA":"          ","EMISSAO":"20210309","VENCREA":"20210408","VALOR":620.34,"SALDO":620.34,"MULTA":0.0,"ORIGEM":"ATRIAL","DATA_INCLUSAO":"2021-06-08T00:22:03Z","DATA_ALTERACAO":"2021-06-08T11:27:22Z","DIFF":"","TIPO":"NF "}]}';
        if(jsonString.contains('error')){
            return null;
        }
        if(jsonString == '{}'){
            return JSON.serialize(pgTitulos);  
        }
        system.debug('jsonString ' + jsonString);
        Date datahoje = Date.today();
        pgTitulos  = (pgTituloAberto)System.JSON.deserialize(jsonString, pgTituloAberto.Class);
        pgTitulos.NomeCliente = acc.Name;
        pgTitulos.limCredito = acc.LimiteCredito__c;
        if(pgTitulos.limCredito ==  null ){
            pgTitulos.limCredito = 0.00;
        }
        pgTitulos.grauRisco = acc.GrauRisco__c;
        pgTitulos.dataHoje = String.valueOf(Date.today());
        Double limite = 0.00;
        Double saldoVencido = 0.00;
        Double saldoAVencer = 0.00;
        Double maiorCompra = 0.00;
        Double totalCompra = 0.00;
        if(pgTitulos != null && pgTitulos.TituloAberto != null && !pgTitulos.TituloAberto.isEmpty()){
            pgTitulos.semTitulo = false;
        }
        if(pgTitulos.TituloAberto != null){
            for(cls_TituloAberto tAberto : pgTitulos.TituloAberto){
            
                Date datavencimento = date.valueOf(tAberto.VENCREA.substring(0,4) + '-' + tAberto.VENCREA.substring(4,6) + '-' + tAberto.VENCREA.substring(6,8));
                tAberto.VENCREA = string.valueOf(datavencimento).split('T')[0];
                limite += tAberto.VALOR;
                if(tAberto.VENCREA > pgTitulos.dataHoje ){
                    saldoAVencer += tAberto.VALOR;
                }else{
                    saldoVencido += tAberto.VALOR;
                }
                if(tAberto.VALOR > maiorCompra){
                    maiorCompra = tAberto.VALOR;
                }
                totalCompra += tAberto.VALOR;
                
                tAberto.DATA_INCLUSAO = string.valueOf(tAberto.DATA_INCLUSAO).split('T')[0];
            }
        }
        pgTitulos.saldo = (pgTitulos.limCredito - totalCompra );
        pgTitulos.saldoAVencer =  saldoAVencer;
        pgTitulos.saldoVencido =  saldoVencido;
        pgTitulos.maiorCompra  =  maiorCompra;
        pgTitulos.totalCompra  =  totalCompra;
        pgTitulos.maiorTitulo  =  saldoVencido;
        pgTitulos.mediaAtraso = '0';

        system.debug('dadosTela ' + JSON.serialize(pgTitulos));
        return JSON.serialize(pgTitulos);        
    }

    public static String calloutBoleto(String body){

        Integracoes__c intCustomerApi = Integracoes__c.getValues('BoletoAPI');
        
        String method   = intCustomerApi.Method__c;
        String endpoint = intCustomerApi.Endpoint__c;
        String username = intCustomerApi.User__c;
        String password = intCustomerApi.Password__c;
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password)));
        req.setHeader('Username', username);
        req.setHeader('Password', password);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setBody(body);
        req.setTimeout(120000);
        HttpResponse response = http.send(req);
        
        return response.getBody();

    }
    public class boleto {
        public String cnpj_cd;
        public String NumeroBoleto;
        public String prefixo;
        public String tipo;
        public String parcela;
    }
    public class RetornoBoleto {
        public boolean lret;
        public String result;
        public String boleto;
    }
    public class RetornoErro {
        @AuraEnabled public String msg;
        @AuraEnabled public String boleto;
    }

    public class pgTituloAberto {
        @AuraEnabled public list<cls_TituloAberto> TituloAberto;
        @AuraEnabled public String dataHoje;
        @AuraEnabled public boolean semTitulo;
        @AuraEnabled public boolean pagVencer;
        @AuraEnabled public boolean pagVencido;
        @AuraEnabled public decimal limCredito;
        @AuraEnabled public String grauRisco;
        @AuraEnabled public decimal saldo;
        @AuraEnabled public decimal saldoAVencer;
        @AuraEnabled public decimal saldoVencido;
        @AuraEnabled public decimal maiorCompra;
        @AuraEnabled public decimal totalCompra;
        @AuraEnabled public decimal maiorTitulo;
        @AuraEnabled public String mediaAtraso;
        @AuraEnabled public String NomeCliente;
    }
	class cls_TituloAberto {
        @AuraEnabled public String FILIAL;	
        @AuraEnabled public String EMPRESA;	
        @AuraEnabled public String NUM;	
        @AuraEnabled public String LINDIGITAVEL;	
        @AuraEnabled public String PREFIXO;	
        @AuraEnabled public String CLIENTE;	
        @AuraEnabled public String LOJA;	
        @AuraEnabled public String CGC;	
        @AuraEnabled public String CGC_CD;	
        @AuraEnabled public String NUMBCO;	
        @AuraEnabled public String PARCELA;	 
        @AuraEnabled public String PEDIDO;	
        @AuraEnabled public String BANCO;	
        @AuraEnabled public String AGENCIA;	
        @AuraEnabled public String CONTA;	
        @AuraEnabled public String EMISSAO;	
        @AuraEnabled public String VENCREA;	
        @AuraEnabled public decimal VALOR;	
        @AuraEnabled public decimal SALDO;	
        @AuraEnabled public decimal MULTA;	
        @AuraEnabled public String ORIGEM;	
        @AuraEnabled public String DATA_INCLUSAO;	
        @AuraEnabled public String DATA_ALTERACAO;	
        @AuraEnabled public String DIFF;	
        @AuraEnabled public String TIPO;	
        
	}
}