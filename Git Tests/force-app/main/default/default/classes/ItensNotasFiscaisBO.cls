public virtual without sharing class ItensNotasFiscaisBO {

    public void vinculaItemVenda(Map<Id,ItensNotaFiscal__c> oldMap, List<ItensNotaFiscal__c> newRecordList) {

        Map<String,String> mapCodItem = new Map<String,String>();
        Set<String> setCodItem = new Set<String>();
        List<ItensNotaFiscal__c> lstNotasVenda = new List<ItensNotaFiscal__c>();

        for(ItensNotaFiscal__c item: newRecordList){

            if (!String.isBlank(item.CodigoItemNotaVenda__c)) {               
                
                setCodItem.add(item.CodigoItemNotaVenda__c);                
            }
        }

        if (setCodItem.size() > 0){
            
            lstNotasVenda = [SELECT Id, ExternalId__c, NotaFiscal__c  FROM ItensNotaFiscal__c WHERE ExternalId__c IN: setCodItem];
            System.debug(lstNotasVenda);
            if (lstNotasVenda.size() > 0) {

                for (ItensNotaFiscal__c item : lstNotasVenda) {

                    if (!mapCodItem.containsKey(item.ExternalId__c)) {
                        
                        mapCodItem.put(item.ExternalId__c, item.Id);
                    }                    
                }

                for (ItensNotaFiscal__c itemDevolucao: newRecordList){                      
                        
                    if (mapCodItem.containsKey(itemDevolucao.CodigoItemNotaVenda__c)) {
                        System.debug('======= '+ itemDevolucao.CodigoItemNotaVenda__c);
                        
                        itemDevolucao.ItemNotaVenda__c = mapCodItem.get(itemDevolucao.CodigoItemNotaVenda__c);
                    }
                }                
            }
        }
    }

    public void validateCFOP(Map<Id,ItensNotaFiscal__c> oldMap, List<ItensNotaFiscal__c> newRecordList) {

        Map<String,ItensNotaFiscal__c> mapNotaxItem = new Map<String,ItensNotaFiscal__c>();
        List<NotasFiscais__c> lstNotas = new List<NotasFiscais__c>();
        Id DEVOLUCAO_RECORDTYPE = Schema.SObjectType.NotasFiscais__c.getRecordTypeInfosByDeveloperName().get('Devolucao').getRecordTypeId();
        NotasFiscais__c nf = new NotasFiscais__c();
        for(ItensNotaFiscal__c item: newRecordList){

            if (!mapNotaxItem.containsKey(item.NotaFiscal__c)) {
                        
                mapNotaxItem.put(item.NotaFiscal__c, item);
            } 
        }

        if (mapNotaxItem.size() > 0){
            Set<String> setIds = new Set<String>();
            for(ItensNotaFiscal__c item: newRecordList){
                if (!String.isBlank(mapNotaxItem.get(item.NotaFiscal__c).CFOP__c) && CodigosCFOP__c.getAll().get(mapNotaxItem.get(item.NotaFiscal__c).CFOP__c) != null && !setIds.contains(item.NotaFiscal__c)) {
                    nf = new NotasFiscais__c();
                    nf.Id = item.NotaFiscal__c;
                    nf.RecordTypeId = DEVOLUCAO_RECORDTYPE;
                    nf.NaturezaOperacao__c = 'DEVOLUÇÃO';
                    lstNotas.add(nf);
                    setIds.add(item.NotaFiscal__c);
                }

            }
           
        }

        if (lstNotas.size() > 0) {
            update lstNotas;
        }
    }
}