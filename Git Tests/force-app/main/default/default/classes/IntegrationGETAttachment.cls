public without sharing class IntegrationGETAttachment {
    @InvocableMethod(label='Get Open Title Attachment' 
                    description='Call integration to get the Attachment of this "Título em Aberto"')
    public static List<String> flowHandler(List<String> titleIdSet){
        String integrationType = 'GetTitulosAttachment';

        String titleExternalId = '';
        String titleAccountExternalId = '';
        String titleSerieExternalId = '3';   

        for(TitulosAbertos__c nf : [SELECT id, NumeroBoleto__c, Conta__r.ExternalId__c FROM TitulosAbertos__c WHERE Id IN :titleIdSet]){
            titleExternalId = nf.NumeroBoleto__c;
            titleAccountExternalId = nf.Conta__r.ExternalId__c;
        }

        return getAttachment(titleIdSet.get(0), integrationType, titleExternalId, titleAccountExternalId, titleSerieExternalId);
    }

    public static List<String> getAttachment(String objId, String endpointType, string nfExternalId, string accountExternalId, string serieExternalId){
        String returnMsg = '';
        try{
            Integracoes__c endpoint = Integracoes__c.getAll().get(endpointType);
            HttpRequest req = new HttpRequest();
            // 172.30.0.20:1006/DEV/GetXML?cCgcEmp={{CGC}}&cNota={{externalId}}&cSerie={{nfSerieExternalId}}&cTpNF=S
            req.setEndpoint(endpoint.Endpoint__c.replace('{{CGC}}', accountExternalId).replace('{{externalId}}', nfExternalId).replace('{{nfSerieExternalId}}', serieExternalId));
            req.setMethod(endpoint.Method__c);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(endpoint.user__c + ':' + endpoint.Password__c)));
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setTimeout(120000);

            HttpResponse resp = new HttpResponse();
            resp = new Http().send(req);

            System.debug(resp.getStatusCode());

            String resultString = resp.getBody();

            System.debug(resultString);
            if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201){
                system.debug(resp.getBody());
                returnMsg = null;
            }else{
                system.debug(resp.getStatusCode());
                system.debug(resp.getBody());
                returnMsg = 'Erro';
            }
        }catch(Exception ex){
            system.debug(ex.getMessage());
            returnMsg = ex.getMessage();
        }
        system.debug('returnMsg: '+ returnMsg);
        return new List<String>{returnMsg};
    }

    public static List<String> flowHandlerNF(List<String> nfIdSet, String documentType){
        String nfExternalId = '';
        String nfAccountExternalId = '';
        String nfSerieExternalId = '';

        for(NotasFiscais__c nf : [SELECT id, ExternalId__c, Pedido__r.CNPJCD__c, SerieNota__c FROM NotasFiscais__c WHERE Id IN: nfIdSet]){
            nfAccountExternalId =  nf.Pedido__r.CNPJCD__c;
            nfSerieExternalId = nf.SerieNota__c;
            nfExternalId =  nf.ExternalId__c.substring(5, 14);
        }

        RequestDTO requestData = new RequestDTO(documentType, nfAccountExternalId, nfSerieExternalId, nfExternalId);

        return IntegrationGETAttachment.getAttachmentNF(requestData);
    }

    public static List<String> getAttachmentNF(RequestDTO requestData){
        String returnMsg = '';
        try {
            Integracoes__c endpoint = Integracoes__c.getAll().get('GetFiscalAttachment');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint.Endpoint__c);
            req.setMethod(endpoint.Method__c);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(endpoint.user__c + ':' + endpoint.Password__c)));
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setBody(JSON.serialize(requestData));
            req.setTimeout(120000);

            HttpResponse resp = new HttpResponse();
            resp = new Http().send(req);

            System.debug(resp.getStatusCode());

            String resultString = resp.getBody();

            ResultClass resClass = null;
            try {
                resClass = (ResultClass)JSON.deserialize(resultString, ResultClass.class);                
            } catch (Exception e) {
                System.debug(e.getMessage());
            }

            System.debug(resultString);
            if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201){
                System.debug(resp.getBody());
                returnMsg = resClass.result;
            } else {
                System.debug(resp.getStatusCode());
                System.debug(resp.getBody());
                returnMsg = resClass.result;
            }
        } catch (Exception ex){
            System.debug(ex.getMessage());
            returnMsg = ex.getMessage();
        }

        System.debug('returnMsg: ' + returnMsg);
        return new List<String>{returnMsg};
    }

    public class ResultClass{
        public String result {get;set;}
        public Boolean incluido {get;set;}
    }

    public class RequestDTO {
        public String tipo;
        public String cnpj_cd;
        public String serie;
        public String nota;
        public String origem = 'SFC';

        public RequestDTO(String tipo, String cnpj_cd, String serie, String nota) {
            this.tipo = tipo;
            this.cnpj_cd = cnpj_cd;
            this.serie = serie;
            this.nota = nota;
        }
    }
}
