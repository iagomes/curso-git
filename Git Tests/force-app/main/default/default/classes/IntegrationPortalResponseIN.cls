/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 17-05-2022
 * @last modified by  : raphael.holanda.ext@iconit.com.br
**/
@RestResource(urlMapping='/integrationResponse/v1/*')
global without sharing class IntegrationPortalResponseIN {
    
    global static final List<String> FALSE_STATUS = new List<String>{'Não Integrado', 'Falha na Integração'};

    @HttpPost
    global static void saveResponse() {
        StandardResponse response = new StandardResponse();
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        RestResponse res = RestContext.response;
        String responseBody;

        Opportunity opp;
        Opportunity oppToUpdate = new Opportunity();
        Map<String, QuoteItem__c> mapItemsToUpdate = new Map<String, QuoteItem__c>();
        
        try{
            
            RequestData reqData = validateRequestBody(requestBody);

            List<Opportunity> oppList = [
                SELECT Id, NumeroOrcamento__c,
                    (SELECT UserId FROM OpportunityTeamMembers)
                FROM Opportunity 
                WHERE ExternalPortal__c =: reqData.idPortalOrcamento
                LIMIT 1
            ];

            if(oppList.isEmpty()){
                throw new CustomException('O idPortalOrcamento:\''+reqData.idPortalOrcamento+'\' não foi encontrado no Salesforce');
            }
            opp = oppList[0];
            oppToUpdate.Id = opp.Id;
            oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c = null;
            
            if(!reqData.success){
                oppToUpdate.StageName = 'Falha na integração';
                oppToUpdate.StatusIntegracaoPortalCotacoes__c = 'Falha na Integração';

                if(!String.isBlank(reqData.messages)){
                    oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c = Datetime.now().format('dd/MM/yyyy\' \'HH:mm:ss') + ';' + reqData.messages;
                }
            }

            Map<Id, QuoteItem__c> quoteItemMap = new Map<Id, QuoteItem__c>([
                SELECT Id, Status__c, StatusIntegrationResponse__c
                FROM QuoteItem__c
                WHERE OpportunityId__c = :opp.Id
                FOR UPDATE
            ]);

            Boolean fail = false;

            for(ItemResult item: reqData.items){
                QuoteItem__c qitem = quoteItemMap.get(item.idSalesforce);
                if(item.success){

                    qItem.Status__c = 'Respondido';
                    qItem.StatusIntegrationResponse__c = 'Integrado';
                } else {
                    fail = true;
                    oppToUpdate.StageName = 'Falha na integração';
                    oppToUpdate.StatusIntegracaoPortalCotacoes__c = 'Falha na Integração';
                    qItem.StatusIntegrationResponse__c = 'Falha na Integração';
                    if(String.isEmpty(oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c)){
                        oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c = 'Falha na integração:';
                    }
                }
            }
            if(reqData.success && !fail && validateChangeStatus(quoteItemMap.values())){
                oppToUpdate.StageName = 'Respondida';
                oppToUpdate.StatusIntegracaoPortalCotacoes__c = 'Integrado';
            }

            update quoteItemMap.values();
            oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c = StringUtils.cutByFieldLength(Opportunity.MensagemErroIntegracaoPortalCotacoes__c, oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c);
            update oppToUpdate;

            if(!mapItemsToUpdate.isEmpty()){
                update mapItemsToUpdate.values();
            }

        } catch(Exception ex){
            response.addError(ExceptionUtils.debug(ex));
        }

        Boolean hasError = response.code != '200';
        res.statuscode = Integer.valueOf(response.code);
        res.headers.put('Content-Type', 'application/json;charset=UTF-8');
        responseBody = response.toJSON();
        res.responseBody = Blob.valueOf(responseBody);

        if(!String.isBlank(oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c) && !opp.OpportunityTeamMembers.isEmpty()){

            Set<String> targetUserIds = new Set<String>();
            for(OpportunityTeamMember otm: opp.OpportunityTeamMembers){
                targetUserIds.add(otm.UserId);
            }
            
            sendNotification(targetUserIds, opp.Id, 'A cotação de número ' + opp.NumeroOrcamento__c + ' teve falha na integração, acesse-a para mais detalhes', oppToUpdate.MensagemErroIntegracaoPortalCotacoes__c);
        }
        
        IntegrationUtils.WSLog('IntegrationResponse', 'Inbound', requestBody, responseBody, hasError, '/integrationResponse/v1/*', response.code);
    }

    private static RequestData validateRequestBody(String requestBody){
        RequestData rData;
        // System.debug('requestBody:::' + requestBody);
        if(String.isBlank(requestBody)){
            throw new CustomException('Dados não enviados.');
        } else {
            rData = (RequestData)JSON.deserialize(requestBody, RequestData.class);
        }
        if(String.isBlank(rData.idPortalOrcamento)){
            throw new CustomException('O campo \'idPortalOrcamento\' é obrigatório!');
        }
        if(rData.items == null || rData.items.isEmpty()){
            throw new CustomException('É obrigatório conter ao menos um item na requsição');
        }
        return rData;
    }

    public static Boolean validateChangeStatus(List<QuoteItem__c> qitemList){
        Map<String, List<QuoteItem__c>> qitemByStatusInt = (Map<String, List<QuoteItem__c>>)SObjectUtils.mapObjectsByField(qitemList, 'StatusIntegrationResponse__c', true);
        for(String stat : FALSE_STATUS){
            if(qitemByStatusInt.get(stat) != null && qitemByStatusInt.get(stat).size() > 0){
                return false;
            }
        }
        return true;
    }

    public static void sendNotification(Set<String> targetUserIds, String targetId, String title, String body){
            
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'NotificaoCasoEncerrado'
        ];
        
        notification.setTitle(title);
        notification.setBody('\n' + body.replaceAll(';', '\n'));
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        try {
            notification.send(targetUserIds);
        }
        catch (Exception e) {
            ExceptionUtils.debug(e);
        }

    }

    public class RequestData {
        public Boolean success;
        public String messages;
        public String idPortalOrcamento;
        public List<ItemResult> items;
    }

    public class ItemResult {
        public Boolean success;
        public String idSalesforce;
        public String messages;
    }

    public static RequestData parse(String json){
        return (RequestData) System.JSON.deserialize(json, RequestData.class);
    }
}