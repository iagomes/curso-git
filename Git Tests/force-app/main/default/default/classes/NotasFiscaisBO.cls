public virtual without sharing class NotasFiscaisBO {

     public void validateCFOP(Map<Id,NotasFiscais__c> oldMap, List<NotasFiscais__c> newRecordList) {

        Id DEVOLUCAO_RECORDTYPE = Schema.SObjectType.NotasFiscais__c.getRecordTypeInfosByDeveloperName().get('Devolucao').getRecordTypeId();
        for(NotasFiscais__c nf: newRecordList){
            
            if (CodigosCFOP__c.getAll().get(nf.CFOP__c) != null) {
                
                //nf.RecordTypeId = DEVOLUCAO_RECORDTYPE;
            }
        }
    }
}