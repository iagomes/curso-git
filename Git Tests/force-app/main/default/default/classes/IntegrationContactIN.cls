public without sharing class IntegrationContactIN {

    public static List<TemplateDataIntegrationFields.Response> upsertContact(Map<String, List<TemplateDataIntegrationFields.ContactINData>> mapAccountToContact) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<TemplateDataIntegrationFields.ContactINData> listContactsINData = new List<TemplateDataIntegrationFields.ContactINData>();
        List<Contact> listContacts = new List<Contact>();

        Set<String> setAccountExternalId = new Set<String>();

        for (String key : mapAccountToContact.keySet()) {
            setAccountExternalId.add(key);
            for (TemplateDataIntegrationFields.ContactINData cont : mapAccountToContact.get(key)) {
                // cont.ExternalId = key;
                listContactsINData.add(cont);
            }
        }

        // lookup para conta
        for(Account acc : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c = :setAccountExternalId]){
            lookups.put('Conta' + acc.ExternalId__c, acc.Id);
        }
        system.debug(listContactsINData);
        FactoryDataIntegration.convertSObject(new Contact(), 'IN', listContactsINData, responseList, listContacts, lookups);
        
        IntegrationUtils.upsertRecords(
            Database.upsert(listContacts, Contact.ExternalId__c, false), 
            responseList, 
            listContacts, 
            Contact.ExternalId__c
        );

        system.debug(responseList);

        return responseList;
    }
}