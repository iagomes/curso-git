public without sharing class AccountSelector {
    
    private static AccountSelector instance;

    public static AccountSelector getInstance(){
        if(instance == null){
            instance = new AccountSelector();
        }
        return instance; 
    }
    
    public Account getAccountByDocument(String documentNumber){
        Map<String, Account> macAccs = getAccountsByDocument(new Set<String>{documentNumber});
        if(!macAccs.isEmpty()){
            return macAccs.get(documentNumber);
        } else {                  
            return null;                                         
        }
    }

    public Map<String, Account> getAccountsByDocument(Set<String> documentNumbers){
        Map<String, Account> result = new Map<String,Account>();
        List<Account> lstAccs = [
            SELECT 
                Id, 
                CNPJ__c,
                Documento__c,
                CondicaoPagamento__c,
                CondicaoPagamento__r.Name,
                Name,
                ExternalId__c,
                TabelaPrecos__c
            FROM Account 
            WHERE Documento__c IN: documentNumbers
        ];
        for(Account acc: lstAccs){
            result.put(acc.Documento__c, acc);
        }
        return result;
    }
    
}
