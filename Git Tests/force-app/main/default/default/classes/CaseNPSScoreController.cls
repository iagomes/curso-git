public with sharing class CaseNPSScoreController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getNPSScore(Id recordId) {
        
        try {

            Case record = [SELECT CaseNumber FROM Case WHERE Id =: recordId];
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SolucX' + '/transaction?search=' + record.CaseNumber);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('x-solucx-user-token', '{!$Credential.UserName}'); 
            req.setHeader('x-solucx-api-key', '{!$Credential.Password}'); 

            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                
                List<Object> desResponse = (List<Object>)JSON.deserializeUntyped(res.getBody());

                if (desResponse.isEmpty())
                    return new Map<String, String> { 'nodata' =>  'nodata' };

                Map<String, Object> rating = (Map<String, Object>)((Map<String, Object>)desResponse.get(0)).get('rating');
                
                return new Map<String, String> { 'value' => (String)rating.get('value'), 'source' =>  (String)rating.get('source') };
                
            } else {
                throw new NPSScoreException('Error');
            }

        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class NPSScoreException extends Exception {}

}
