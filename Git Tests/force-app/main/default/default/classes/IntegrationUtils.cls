public class IntegrationUtils {
    
    //String check
    public static Boolean convertEmptyString(String str) {
        return ((String.isBlank(str) || str == 'null' || str == null || str == '') ? true : false); 
    }

    public static Boolean upsertRecords(List<Database.UpsertResult> upsResults, List<TemplateDataIntegrationFields.Response> responseList, List<SObject> sObjectListToUpsert, Schema.SObjectField field){
        TemplateDataIntegrationFields.Response responseData;
        Boolean hasError = false;
        for (TemplateDataIntegrationFields.Response response : responseList) {
            if(response.status == false)
				hasError = true;                
        }

        for (Integer i = 0; i < upsResults.size(); i++) {
            responseData = new TemplateDataIntegrationFields.Response();

            SObject objResult = sObjectListToUpsert[i];
            Database.UpsertResult upsResult = upsResults[i];

            if (upsResult.isSuccess()) {
                responseData.success(
                    upsResult.getId(), 
                    String.valueOf(objResult.get(field)), 
                    String.valueOf(objResult.getSObjectType())
                );
            }
            else {
                responseData.error(
                    String.valueOf(objResult.get(field)),
                    upsResult.getErrors()[0].getMessage().replace('Campos obrigatórios ausentes', 'Valor inválido para o campo obrigatório'), 
                    String.valueOf(objResult.getSObjectType())
                );
                hasError = true;
            }
            responseList.add(responseData);
        }
        return hasError;
    }

    public static void WSLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors){
        WSLog(integrationName, recordTypeName, payloadIN, payloadOUT, hasAnyErrors, null, null);
    }

    public static void WSLog(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors, String endpoint, String statusCode){

        Boolean shouldUseAttachmentIN  = String.isNotBlank(payloadIN) && (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = String.isNotBlank(payloadOUT) && (payloadOUT.length() > 100000);

        Datetime tNow = System.now();

        LogIntegration__c log = new LogIntegration__c(
            RecordTypeId        = Schema.SObjectType.LogIntegration__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
            Integration__c      = integrationName,
            HasAttachment__c    = (shouldUseAttachmentIN || shouldUseAttachmentOUT),
            PayloadIN__c        = (shouldUseAttachmentIN  ? '' : payloadIN),
            PayloadOUT__c       = (shouldUseAttachmentOUT ? '' : payloadOUT),
            Status__c           = (hasAnyErrors ? 'ERROR' : 'SUCCESS'),
            ExecuteDate__c      = tNow,
            HTTPStatusCode__c   = statusCode
        );

		if(String.isNotEmpty(endpoint) && endpoint.length() > 255) {
			log.LongEndpoint__c	 = endpoint;
			log.Endpoint__c		 = endpoint.substring(0, 252) + '...';
		} else {
			log.Endpoint__c		 = endpoint;
		}

        try{
            insert log;

            // Maximum Size for a String
            List<Attachment> attachmentListToInsert = new List<Attachment>();
            
            if (shouldUseAttachmentIN) {
                attachmentListToInsert.add(createAttachment(log.Id, integrationName, 'IN', log.Name, String.valueOf(tNow), payloadIN));
            }

            if (shouldUseAttachmentOUT) {
                attachmentListToInsert.add(createAttachment(log.Id, integrationName, 'OUT', log.Name, String.valueOf(tNow), payloadOUT));
            }

            if (attachmentListToInsert.size() != 0) {
                Database.insert(attachmentListToInsert);
            }
            
        }catch(Exception e){
            System.debug('EXCEPTION ON LOG - Please review parameters - '+e.getMessage()+' - '+e.getStackTraceString());
        }
    }

    public static String WSLogReturningId(String integrationName, String recordTypeName, String payloadIN, String payloadOUT, Boolean hasAnyErrors, String endpoint, String statusCode){

        Boolean shouldUseAttachmentIN  = String.isNotBlank(payloadIN) && (payloadIN.length() > 100000);
        Boolean shouldUseAttachmentOUT = String.isNotBlank(payloadOUT) && (payloadOUT.length() > 100000);

        Datetime tNow = System.now();

        LogIntegration__c log = new LogIntegration__c(
            RecordTypeId        = Schema.SObjectType.LogIntegration__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
            Integration__c      = integrationName,
            HasAttachment__c    = (shouldUseAttachmentIN || shouldUseAttachmentOUT),
            PayloadIN__c        = (shouldUseAttachmentIN  ? '' : payloadIN),
            PayloadOUT__c       = (shouldUseAttachmentOUT ? '' : payloadOUT),
            Status__c           = (hasAnyErrors ? 'ERROR' : 'SUCCESS'),
            ExecuteDate__c      = tNow,
            HTTPStatusCode__c   = statusCode
        );

		if(String.isNotEmpty(endpoint) && endpoint.length() > 255) {
			log.LongEndpoint__c	 = endpoint;
			log.Endpoint__c		 = endpoint.substring(0, 252) + '...';
		} else {
			log.Endpoint__c		 = endpoint;
		}

        try{
            insert log;

            // Maximum Size for a String
            List<Attachment> attachmentListToInsert = new List<Attachment>();
            
            if (shouldUseAttachmentIN) {
                attachmentListToInsert.add(createAttachment(log.Id, integrationName, 'IN', log.Name, String.valueOf(tNow), payloadIN));
            }

            if (shouldUseAttachmentOUT) {
                attachmentListToInsert.add(createAttachment(log.Id, integrationName, 'OUT', log.Name, String.valueOf(tNow), payloadOUT));
            }

            if (attachmentListToInsert.size() != 0) {
                Database.insert(attachmentListToInsert);
            }
            return log.Id;
            
        }catch(Exception e){
            System.debug('EXCEPTION ON LOG - Please review parameters - '+e.getMessage()+' - '+e.getStackTraceString());
            return null;
        }
    }

    @TestVisible
    private static Attachment createAttachment(String recordId, String integrationName, String inOrOut, String logName, String timeAsString, String payload){    	
    	return new Attachment(Name = 'LOG-'+integrationName+'-'+inOrOut+'-'+timeAsString+'.txt', Body = Blob.valueOf(payload), ParentId = recordId);
    }

    public static String getTotvsAccessToken() {
		Integracoes__c totvsAPI = Integracoes__c.getValues('TotvsAccessTokenAPI');
        
        HttpRequest reqTotvs = new HttpRequest();
        reqTotvs.setMethod(totvsAPI.Method__c);
        reqTotvs.setEndpoint(totvsAPI.Endpoint__c + 'password=' + totvsAPI.Password__c + '&username=' + totvsAPI.User__c);
        reqTotvs.setHeader('Accept', 'application/json');
        reqTotvs.setTimeout(120000);
		if(Test.isRunningTest()) {
			return 'tokenTotvs';
		}else {
            try {                
			    HttpResponse respTotvs = new Http().send(reqTotvs);		
			    system.debug(respTotvs.getBody());			
    
			    Map<String, Object> mapResponseTotvs = (Map<String, Object>) JSON.deserializeUntyped(respTotvs.getBody());
			    String tokenTotvs = String.valueOf(mapResponseTotvs.get('access_token'));			
			    
			    return tokenTotvs;
            } catch (Exception e) {
                return e.getMessage();
            }
		}
	}

    public static String sendSyncronousRequestByIntegrationCustomSettings(String integrationCustomSettingsName, String body) {
        try {
            Integracoes__c intCustomerApi = Integracoes__c.getValues(integrationCustomSettingsName);

            HttpRequest request = new HttpRequest();
            request.setEndpoint(intCustomerApi.Endpoint__c);
            request.setHeader(IntegrationConstants.AUTHORIZATION, IntegrationConstants.BASIC + EncodingUtil.base64Encode(Blob.valueOf(intCustomerApi.User__c + ':' + intCustomerApi.Password__c)));
            request.setHeader(IntegrationConstants.HEADER_TYPE_CONTENT, IntegrationConstants.HEADER_TYPE_CONTENT_JSON);
            request.setMethod(intCustomerApi.Method__c);
            request.setTimeout(IntegrationConstants.TIMEOUT);
            request.setBody(body);

            HttpResponse response = new HttpResponse();
            response = new Http().send(request);

            return response.getBody();
        } catch(Exception ex) {
            throw new CustomException('Erro na requisição \n' + ex.getMessage() + '.');
        }
    }
}
