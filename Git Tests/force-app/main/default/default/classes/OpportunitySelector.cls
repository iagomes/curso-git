public without sharing class OpportunitySelector {
    
    private static OpportunitySelector instance;

    public static OpportunitySelector getInstance(){
        if(instance == null){
            instance = new OpportunitySelector();
        }
        return instance;
    }
    
    // public Opportunity getOpportunityById(Id accId){
    //     List<Opportunity> lstOpp = getOpportunitysById(new Set<Id>{accId});
    //     if(lstOpp.size() > 0){
    //         return lstOpp[0];
    //     } else {
    //         return null;
    //     }
    // }

    // public List<Opportunity> getOpportunitysById(Set<Id> setIds){
    //     return [
    //         SELECT 
    //             Id,
    //             CNPJ__c,
    //             Documento__c,
    //             Name,
    //             ExternalId__c
    //         FROM Opportunity 
    //         WHERE Id IN: setIds
    //     ];
    // }

    public Opportunity getOpportunityByIdForIntegrationPortalQuoteOUT(Id oppId){
        return [
            SELECT 
                Id,
                Name,
                ExternalPortal__c,
                Integradora__c,
                IdPortal__c,
                IdIntegrator__c,
                LastIntegratedItem__c,
                CDsBloqueado__c,
                CNPJ__c,
                StageName,
                RepresentanteVDELookup__r.Email,
                CanalEntrada__c,
                AccountId,
                Account.Name,
                DataVencimento__c,
                (
                    SELECT 
                        MinimumBilling__c,
                        CloseDate__c,
                        PrazoEntrega__c,
                        PrazoValidade__c,
                        CondicaoPagamento__r.ExternalId__c,
                        ObservacoesLongText__c,
                        CNPJCD__c,
                        FretePicklist__c
                    FROM Condicespagamentospor_CD__r
                ),
                (
                    SELECT
                        Id,
                        IdPortal__c,
                        IdArtigo__c,
                        CNPJCD__c,
                        Quantity,
                        UnitPrice,
                        ListPrice,
                        CodigoRastreio__c,
                        Comentarios__c,
                        TabulacaoN1__c,
                        Product2.ExternalId__c,
                        Product2.Fornecedor__r.Name,
                        Product2.UnidadeMedida__c,
                        Product2.Fornecedor__r.ExternalId__c,
                        Vendedor__r.CodigoUsuario__c
                    FROM OpportunityLineItems
                ),
                (
                    SELECT
                        TabulacaoN1__c,
                        TabulacaoN2__c,
                        User.CodigoUsuario__c,
                        HasChangesUnsync__c,
                        User.Name
                    FROM OpportunityTeamMembers
                    WHERE User.CodigoUsuario__c != NULL
                )
            FROM Opportunity 
            WHERE Id =: oppId
        ];
        // Vendedor__r.CodigoUsuario__c
    }
    
}