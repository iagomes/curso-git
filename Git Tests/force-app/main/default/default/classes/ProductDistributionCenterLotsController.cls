public without sharing class ProductDistributionCenterLotsController {
    
    @AuraEnabled(cacheable=true)
    public static String getShelfLifeProducts(Id productId, String distributionCenterCNPJ) {
        try {
            System.debug('productId: ' + productId);
            System.debug('distributionCenterCNPJ: '+ distributionCenterCNPJ);

            List<ListaCentroDistribuicao__c> distributionCenters = [
                SELECT 
                    CNPJCD__c, 
                    CodigoCD__c 
                FROM ListaCentroDistribuicao__c
                WHERE CNPJCD__c = :distributionCenterCNPJ
                LIMIT 1
            ];

            if (distributionCenters.size() <= 0) {
                throw new AuraHandledException('Centro de distribuição não encontrado.');
            }

            Map<String, Decimal> productPriceByLot = new Map<String, Decimal>();

            List<ItemCampanha__c> shelfLifeItems = [
                SELECT 
                    Id,
                    Lote__c,
                    PrecoMinimo__c
                FROM ItemCampanha__c 
                WHERE NomeProduto__c = :productId
                AND RecordType.DeveloperName = 'ItemContratoShelfLife'
                // AND VigenciaFinal__c <= TODAY 
                // AND VigenciaInicial__c >= TODAY
                AND Campanha__r.NomeCD__c = :distributionCenters[0].CodigoCD__c
            ];

            System.debug('distributionCenters[0].CodigoCD__c: '+ distributionCenters[0].CodigoCD__c);
            System.debug('shelfLifeItems: '+ shelfLifeItems);

            for (ItemCampanha__c item : shelfLifeItems) {
                productPriceByLot.put(item.Lote__c, item.PrecoMinimo__c);
            }
            
            return JSON.serialize(productPriceByLot);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
