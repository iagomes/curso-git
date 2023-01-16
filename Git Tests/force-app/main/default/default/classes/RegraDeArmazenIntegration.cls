public with sharing class RegraDeArmazenIntegration {

    public class RegraBloqueioArmazemRequest {
        public String  CgcCliente;
        
        public RegraBloqueioArmazemRequest(String CgcCliente) {
            this.CgcCliente     = CgcCliente;
           
        }
    }

    public class Regras {
        public List<RegraBloqueioArmazemResponse> regras;      
        
        public Regras() {
            this.regras   = new List<RegraBloqueioArmazemResponse>();
                       
        }
    }

    public class RegraBloqueioArmazemResponse {
        public String  codigo;
        public String  descricao;
        public String  armazem;
        public String  TipoBloqueio;
        public String  CgcCliente;
        public String  produto;
    }

    public class IntegrationRegraArmazenException extends Exception {}

    @InvocableMethod(label='Get CgcCliente' callout='true')
    public static List<String> RecalculaRegras(List<FlowInputs> flowInputs) {

        Integracoes__c intCustomerApi = Integracoes__c.getValues('ElfaConsultaRegraArmazen');
        
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

        String CgcCliente = flowInputs[0].cgcCliente;

        RegraBloqueioArmazemRequest RegraBloqueioArmazemReq = new RegraBloqueioArmazemRequest(CgcCliente);  
        Regras regrasArmazen = new Regras();
        List<RegraBloqueioArmazem__c> lstregras = new List<RegraBloqueioArmazem__c>();
        RegraBloqueioArmazem__c regrasUpsert = new RegraBloqueioArmazem__c();
        List<String> lstReturn = new List<String>{'Erro!!'};
        String body;
        body = Json.serialize(RegraBloqueioArmazemReq);
        System.debug('Body: '+ body);

        String resultString = '';
        HttpResponse resp = new HttpResponse();
        Boolean hasError = false;
        try {
            req.setBody(body);
            resp = new Http().send(req);
            
            System.debug(resp);
            System.debug(resp.getStatusCode());

         
            resultString = resp.getBody();
            System.debug('resp' + resultString);     

            if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {    

                regrasArmazen = (Regras)JSON.deserialize(resultString, Regras.class);
                System.debug('regras' + regrasArmazen);     
              
                for(RegraBloqueioArmazemResponse regras: regrasArmazen.regras){

                    regrasUpsert = new RegraBloqueioArmazem__c();
                    regrasUpsert.CodigoArmazem__c = regras.armazem;
                    regrasUpsert.TipoRegra__c = regras.TipoBloqueio;               
                    regrasUpsert.ExternalId__c= regras.codigo;     
                    lstregras.add(regrasUpsert);    
                }
               
               
                upsert lstregras RegraBloqueioArmazem__c.ExternalId__c;
                System.debug('lstregras' + lstregras);   
                lstReturn = new List<String>{'Sucesso!!'};             
                IntegrationUtils.WSLog('Regras Do Cliente', 'Outbound', body, resultString, hasError);
                
            } else {

                hasError = true;
                resultString = resp.getBody();
                IntegrationUtils.WSLog('Regras Do Cliente', 'Outbound', body, resultString, hasError);
                lstReturn = new List<String>{'Nenhuma regra encontrada para o cliente!'};
            }            
           
        } catch (Exception e) {
            resultString = e.getMessage();
            lstReturn = new List<String>{'Erro!!'};
            throw new IntegrationRegraArmazenException(resultString);
        }
        System.debug('=== '+lstReturn);
        return lstReturn;

    }

    public class FlowInputs{    
        
        @InvocableVariable
        public String cgcCliente;
    }
}
