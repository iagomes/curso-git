/**
* @description       : 
* @author            : Raphael Soares
* @author username   : raphael.holanda.ext@iconit.com.br
* @company           : Icon IT Solutions
* @last modified on  : 23-11-2021
* @last modified by  : raphael.holanda.ext@iconit.com.br
**/
public with sharing class CaseController {
    
    @AuraEnabled
    public static void closeCase(String recordId) {

        try {
            
            Case c = new Case(
                Id = recordId, 
                Status = 'Closed',
                BypassValidationRules__c = true
            );
            update c;
            
        }
        catch(DMLException ex) {
            ExceptionUtils.debug(ex);
            List<String> errors = new List<String>();
            for (Integer i=0; i < ex.getNumDml(); i++) {
                errors.add(ex.getdmlMessage(i));
            }
            throw new AuraHandledException(String.join(errors, ' '));
        }
        catch(Exception ex) {
            ExceptionUtils.debug(ex);
            throw new AuraHandledException(Label.Error_performing_the_request_action + ' ' + ex.getCause());            
        }
    }
    
    @AuraEnabled
    public static void changeOwner(String recordId) {
        
        try {
            
            Case record = [SELECT   
                           Forward__c,
                           BypassValidationRules__c
                           FROM Case WHERE Id =: recordId];

    
            record.Forward__c = !record.Forward__c;
            record.BypassValidationRules__c = !record.BypassValidationRules__c;
            

            update record;
            
        } catch(Exception ex) {
            ExceptionUtils.debug(ex);
            String error = String.format('{0} - {1}', new String[] 
            {
                Label.Error_performing_the_request_action,
                ex.getMessage()
            });
            throw new AuraHandledException(error);
        }
    }    
}