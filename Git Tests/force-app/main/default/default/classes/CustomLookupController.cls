public with sharing class CustomLookupController {

    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
        system.debug('ObjectName-->' + ObjectName);
        String searchKey = searchKeyWord + '%';
        
        List < sObject > returnList = new List < sObject > ();
      
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }

    @AuraEnabled
    public static List<Account> getAccounts(){
        try {
            List<Account> listAccount = [SELECT Id, Name, ExternalId__c, TipoCliente__c, TabelaPrecos__c, CondicaoPagamento__c, CondicaoPagamento__r.Name, Bloqueado__c FROM Account WHERE Deletado__c = false LIMIT 10];
            return listAccount;
        } catch (Exception e) {
            system.debug('Entrou no catch, exception: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<sObject> searchObject(String objectName, List<String> fields, String searchTerm){
        String searchKeyword = searchTerm + '*';
        String returningQuery = '';
        returningQuery = objectName+' ( Id, '+String.join(fields,',')+')';
        String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING '+returningQuery+' LIMIT 20';
        System.debug(' query '+query);
        List<List<sObject>> searchRecords = Search.Query(Query);
        return searchRecords.get(0);
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, string myObject, String filter) {
        String myQuery = null;
        if(filter != null && filter != ''){
            myQuery = 'SELECT Id, Name FROM '+myObject+' WHERE Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
        } else {
            if(searchTerm == null || searchTerm == ''){
                myQuery = 'SELECT Id, Name FROM '+myObject+' WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
            } else {
                myQuery = 'SELECT Id, Name FROM '+myObject+' WHERE Name Like  \'%' + searchTerm + '%\' LIMIT  5';
            }
        }
        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList;
    }
    
    @AuraEnabled(cacheable=true)
    public static string getAvailableData(String clientId, String condId, String filter, string checkType) {
        if(checkType == 'Pricebook2'){
            return getAvailablePriceData(clientId, condId, filter);
        }else if(checkType == 'CondicaoPagamento__c'){
            return getAvailableCondicaoData(filter);
        }else if(checkType == 'Contact'){
            return getAvailableContactData(filter, clientId);
        }else if(checkType == 'GrupoCliente__c') {
            return getAvailableGrupoClienteData(filter);
        }
        return '[]';
    }
    
    @AuraEnabled(cacheable=true)
    public static String getRecords(String query, String checkType) {
        List<AccountData> listAccData = new List<AccountData>();
        List<CondicaoData> listCondPagData = new List<CondicaoData>();
        List<Pricebook2Data> listPricebookData = new List<Pricebook2Data>();
        if (checkType == 'Account') {
            for (Account acc : Database.query(query)) {
                listAccData.add(new AccountData(acc));
            }
            return JSON.serialize(listAccData);
        } else if (checkType == 'CondicaoPagamento__c') {
            for (CondicaoPagamento__c con : Database.query(query)) {
                listCondPagData.add(new CondicaoData(con));
            }
            return JSON.serialize(listCondPagData);
        } else if (checkType == 'Pricebook2') {
            for (Pricebook2 pb : Database.query(query)) {
                listPricebookData.add(new Pricebook2Data(pb));
            }
            return JSON.serialize(listPricebookData);
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String getContaOrdem( string clientId, string searchValue) {
        List<Account> listAccData = new List<Account>();
        if(searchValue == null){
            searchValue = '';
        }
         Id MedicoRecord = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Medico').getRecordTypeId();
         
        string ajudaQuery = '\'%' + searchValue + '%\'';
        String query = 'SELECT Id, Name, CNPJ__c, CPF__c FROM Account WHERE Id != \'' + clientId + '\' AND Name LIKE ' + ajudaQuery + ' AND RecordTypeId != \'' + MedicoRecord + '\' LIMIT 50';
        system.debug('query ' + query);
        list<AccData> lAcc = new list<AccData>();
        for(Account conta : Database.query(query)){
            lAcc.add(new AccData(conta));
        }
        return JSON.serialize(lAcc);
    }


    public static string getAvailableCondicaoData(String filter) {
        List<CondicaoData> ctList = new List<CondicaoData>();
        for(CondicaoPagamento__c ct : [SELECT id, name FROM CondicaoPagamento__c WHERE Ativo__c = true and Deletado__c = false]){
            if(!ct.Name.toLowerCase().contains(filter.toLowerCase())) continue;
            ctList.add(new CondicaoData(ct));
        }
        return JSON.serialize(ctList);

    }
    public static string getAvailableGrupoClienteData(String filter) {
        system.debug('Entrou');
        List<GrupoCliente> ctList = new List<GrupoCliente>();
        for(GrupoCliente__c ct : [SELECT id, Name, CodigoGrupo__c FROM GrupoCliente__c WHERE Name =: filter OR CodigoGrupo__c =: filter]){
            system.debug('Achou: ' + ct);
            if(!ct.Name.toLowerCase().contains(filter.toLowerCase())) continue;
            ctList.add(new GrupoCliente(ct));
        }
        return JSON.serialize(ctList);
    }

    public static string getAvailableContactData(String filter, string clientId) {
        List<ContactData> ctList = new List<ContactData>();
        for(Contact ct : [SELECT id, name FROM Contact WHERE AccountId = :clientId]){
            if(!ct.Name.toLowerCase().contains(filter.toLowerCase())) continue;
            ctList.add(new ContactData(ct));
        }
        return JSON.serialize(ctList);
    }
    public static string getAvailablePriceData(String clientId, String condId, String filter) {
        List<String> filterList = new List<String>();
        
        String ufCliente = '';
        String segmentoCliente = '';
        for(Account acc : [SELECT id, ShippingState, SegmentoCliente__c FROM Account WHERE id = :clientId]){
            ufCliente = acc.ShippingState;
            segmentoCliente = acc.SegmentoCliente__c;
        }
        
        if(UserInfo.getOrganizationName().contains('Elfa')){
            filterList.add('UnidadeFederativa__c = :ufCliente');
        }   
        if(UserInfo.getOrganizationName().contains('Atrial')){
            filterList.add('SegmentoCliente__c = :segmentoCliente');            
        }
        filterList.add('(SegmentoCliente__c = null AND UnidadeFederativa__c = null)');            

        List<SObject> recordsList =
                Database.query(
                    'SELECT Id, DataInicio__c, isActive, DataFim__C, NomeCentroDistribuicao__c, CodigoCentroDistribuicao__c, name '+
                    ' FROM Pricebook2'+
                    ' WHERE ('+String.join (filterList, ' OR ')+' ) '+
                    // ' AND isActive = TRUE '+
                    ' AND ( DataInicio__c <= TODAY OR DataInicio__c = NULL) '+
                    ' AND ( DataFim__C >= TODAY OR DataFim__c = NULL) '+
                    ' AND CodigoTabela__c = NULL'
                );
                system.debug(recordsList);

        Map<String, Pricebook2Data> priceDataMap = new Map<String, Pricebook2Data>();
        for(SObject obj : recordsList){
            Pricebook2 priceData = (Pricebook2)obj;
            if(!priceData.Name.toLowerCase().contains(filter.toLowerCase())) continue;
            if(!priceDataMap.containsKey(priceData.name)){
                priceDataMap.put(priceData.name, new Pricebook2Data(priceData));
            }
            priceDataMap.get(priceData.name).addList(priceData);
            
        }
        system.debug(priceDataMap);
        return JSON.serialize(priceDataMap.values());
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecordTypeIds(String objectApiName, String fieldApiName, String filter) {
        System.debug(objectApiName);

        if(String.isNotBlank(objectApiName)) {
            List<SObject> recordsList =
            Database.query(
                'SELECT Id, ' + fieldApiName  +
                ' FROM '      + objectApiName +
                ' WHERE '     + filter
            );
        return recordsList;
        }
        else {
            return NULL;
        }
    }

    @AuraEnabled
    public static boolean isCommunity(){
        Id siteId = Site.getSiteId(); // take a look at the apex class Site, you may find more useful method concerning site/community
        if (siteId != null) {
            return true;
        }
        return false;
    }

    public class Pricebook2Data{
        public String id {get;set;}
        public String name {get;set;}
        public String[] centros {get;set;}
        public Pricebook2Data(Pricebook2 price){
            this.Id = price.Id;
            this.name = price.name;            
            this.centros = new List<String>();
        }
        public void addList(Pricebook2 price){
            centros.add(price.CodigoCentroDistribuicao__c+'_'+price.NomeCentroDistribuicao__c);
        }
    }

    public class AccountData{
        public String id {get;set;}
        public String name {get;set;}
        
        public AccountData(Account acc){
            this.id = acc.Id;
            this.name = acc.name;
        }
    }

    public class AccData{
        public String id {get;set;}
        public String name {get;set;}
        public String cpf {get;set;}
        public String cnpj {get;set;}
        
        public AccData(Account acc){
            this.id = acc.Id;
            this.name = acc.name;
            this.cpf = acc.CPF__c;
            this.cnpj = acc.CNPJ__c;
        }
    }

    public class ContactData{
        public String id {get;set;}
        public String name {get;set;}
        public ContactData(Contact price){
            this.Id = price.Id;
            this.name = price.name;    
        }
    }

    public class CondicaoData {
        public String id {get;set;}
        public String name {get;set;}
        public CondicaoData(CondicaoPagamento__c price){
            this.Id = price.Id;
            this.name = price.name;    
        }
    }

    public class GrupoCliente {
        public String id {get;set;}
        public String name {get;set;}
        public String codigoGrupo {get;set;}
        public GrupoCliente(GrupoCliente__c gpCli){
            this.Id = gpCli.Id;
            this.name = gpCli.name;
            this.codigoGrupo = gpCli.CodigoGrupo__c;
        }
    }

}