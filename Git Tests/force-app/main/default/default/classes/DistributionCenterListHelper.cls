public without sharing class DistributionCenterListHelper {
    public Map<String, ListaCentroDistribuicao__c> mapCodeToListaCentroDistribuicao {get; private set;}
    public Map<String, ListaCentroDistribuicao__c> mapCNPJToListaCentroDistribuicao {get; private set;}
    public ListaCentroDistribuicao__c[] distributionCenterList {get; private set;}

    public DistributionCenterListHelper(Boolean populeAllFields) {
        if(populeAllFields) {
            this.populateFields();
        }
    }

    public void getListCentroDistribuicaoAndPopulateFields() {
        this.populateFields();
    }

    private void populateFields() {
        this.mapCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        this.mapCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        this.distributionCenterList = new ListaCentroDistribuicao__c[]{};
        for(ListaCentroDistribuicao__c iListaDistribuicao : [
                SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
                FROM ListaCentroDistribuicao__c 
                WHERE CNPJCD__c != NULL 
                AND CodigoCD__c != NULL 
                AND NomeCD__c != NULL]) {
                    this.mapCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
                    this.mapCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
                    this.distributionCenterList.add(iListaDistribuicao);
        }
    }
}
