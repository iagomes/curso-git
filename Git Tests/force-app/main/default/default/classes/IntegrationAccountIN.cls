@RestResource(urlMapping='/upsertAccount/*')
global without sharing class IntegrationAccountIN {

    @HttpPost
    global static ResponseModel upsertAccount(TemplateDataIntegrationFields.ContadorINData request) {
        Map<String, Id> lookups = new Map<String, Id>();
        List<TemplateDataIntegrationFields.Response> responseList = new List<TemplateDataIntegrationFields.Response>();
        List<Account> listAccountsToUpsert = new List<Account>();
        Map<String, List<TemplateDataIntegrationFields.ContactINData>> mapKeyAccountToContacts = new Map<String, List<TemplateDataIntegrationFields.ContactINData>>();

        Set<String> setContactKey = new Set<String>();
        Set<String> setPaymentConditionKey = new Set<String>();
        Set<String> setAccountKey = new Set<String>();
        Set<String> setPricebookKey = new Set<String>();
        Set<String> setOwnerKey = new Set<String>();
        Set<String> setGroupKey = new Set<String>();

        for (TemplateDataIntegrationFields.AccountINData acc : request.Clientes) {
            if (String.isNotEmpty(acc.ContatoRecebimento)) setContactKey.add(acc.ContatoRecebimento);
            if (String.isNotEmpty(acc.CondicaoPagamento)) setPaymentConditionKey.add(acc.CondicaoPagamento);
            if (String.isNotEmpty(acc.ContaPai)) setAccountKey.add(acc.ContaPai);
            if (String.isNotEmpty(acc.TabelaPrecoCliente)) setPricebookKey.add(acc.TabelaPrecoCliente);
            if (String.isNotEmpty(acc.ProprietarioConta)) setOwnerKey.add(acc.ProprietarioConta);
            if (String.isNotEmpty(acc.CodigoGrupoCliente)) setGroupKey.add(acc.CodigoGrupoCliente);

            if(acc.Contatos != null){
                for (TemplateDataIntegrationFields.ContactINData cont : acc.Contatos) {
                    if (!mapKeyAccountToContacts.containsKey(acc.CGC)) {
                        mapKeyAccountToContacts.put(acc.CGC, new List<TemplateDataIntegrationFields.ContactINData>{cont});
                    } else {
                        mapKeyAccountToContacts.get(acc.CGC).add(cont);
                    }
                }
            }
        }

        // Lookup para Conta Pai
        for(Account acc : [SELECT Id, ExternalId__c FROM Account WHERE ExternalId__c = :setAccountKey]){
            lookups.put('ContaPai' + acc.ExternalId__c, acc.Id);
        }

        // Lookup para Contato Recebimento
        for(Contact con : [SELECT Id, ExternalId__c FROM Contact WHERE ExternalId__c = :setContactKey]){
            lookups.put('ContatoRecebimento' + con.ExternalId__c, con.Id);
        }

        // Lookup para Condição de Pagamento
        for(CondicaoPagamento__c condPag : [SELECT Id, ExternalId__c FROM CondicaoPagamento__c WHERE ExternalId__c = :setPaymentConditionKey]){
            lookups.put('CondicaoPagamento' + condPag.ExternalId__c, condPag.Id);
        }
        
        // Lookup para Tabela de Preço
        for(Pricebook2 pb : [SELECT Id, ExternalId__c FROM Pricebook2 WHERE ExternalId__c = :setPricebookKey]){
            lookups.put('TabelaPreco' + pb.ExternalId__c, pb.Id);
        }
        
        // Lookup para Usuário
        for(User us : [SELECT Id, CodigoUsuario__c FROM User WHERE CodigoUsuario__c = :setOwnerKey AND IsActive = true AND userType != 'Guest']){
            lookups.put('Usuario' + us.CodigoUsuario__c, us.Id);
        }

        // Lookup para Grupo Cliente
        for(GrupoCliente__c gc : [SELECT Id, CodigoGrupo__c FROM GrupoCliente__c WHERE CodigoGrupo__c = :setGroupKey]){
            lookups.put('GrupoCliente' + gc.CodigoGrupo__c, gc.Id);
        }

        Map<String, GrupoCliente__c> mapKeyToAccountGroupToInsertList = new Map<String, GrupoCliente__c>();
        for (TemplateDataIntegrationFields.AccountINData acc : request.Clientes) {
            GrupoCliente__c newClientGroup = new GrupoCliente__c(CodigoGrupo__c = acc.CodigoGrupoCliente, Name = acc.NomeGrupoCliente);
            if (String.isNotEmpty(acc.CodigoGrupoCliente) && !lookups.containsKey('GrupoCliente'+ acc.CodigoGrupoCliente) && !mapKeyToAccountGroupToInsertList.containsKey(newClientGroup.CodigoGrupo__c + newClientGroup.Name)) {
                mapKeyToAccountGroupToInsertList.put(newClientGroup.CodigoGrupo__c + newClientGroup.Name, newClientGroup);
            }
        }

        if (!mapKeyToAccountGroupToInsertList.values().isEmpty()) {
            upsert mapKeyToAccountGroupToInsertList.values() CodigoGrupo__c;
        }

        for (GrupoCliente__c gc : mapKeyToAccountGroupToInsertList.values()){
            lookups.put('GrupoCliente' + gc.CodigoGrupo__c, gc.Id);
        }

        FactoryDataIntegration.convertSObject(new Account(), 'IN', request.Clientes, responseList, listAccountsToUpsert, lookups);
        
		Boolean hasError = IntegrationUtils.upsertRecords(
            Database.upsert(listAccountsToUpsert, Account.ExternalId__c, false), 
            responseList, 
            listAccountsToUpsert, 
            Account.ExternalId__c
        );
        
        if (!mapKeyAccountToContacts.keySet().isEmpty()) {
            system.debug('mapKeyAccountToContacts: ' + mapKeyAccountToContacts);
            responseList.addAll(IntegrationContactIN.upsertContact(mapKeyAccountToContacts));
        }

        for(TemplateDataIntegrationFields.Response res : responseList){
            if(res.status == false) hasError = true;
        }
		
        IntegrationUtils.WSLog('Account', 'Inbound', JSON.serialize(request), JSON.serialize(responseList), hasError);
        
        ResponseModel modelo = new ResponseModel();
        modelo.response = responseList;
        return modelo;
    }
}