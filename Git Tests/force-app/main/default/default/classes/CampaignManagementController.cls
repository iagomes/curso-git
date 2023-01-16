public without sharing class CampaignManagementController {

    public CampaignManagementController() {}

    @AuraEnabled(cacheable=true)
    public static CampaignData getCampaignData(String campaignId) {
        
        CampaignData data = new CampaignData();
        data.params = loadParams();
        data.campaign = loadCampaign(campaignId);
        data.campaignItems = loadCampaignItems(campaignId);
        
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseAvailabeProducts getAvailableProducts(String data) {

        AvailableProductsParams params = (AvailableProductsParams) JSON.deserialize(
            data, 
            AvailableProductsParams.class
        );

        ResponseAvailabeProducts response = new ResponseAvailabeProducts();
        response.products = loadProducts(params.filter, params.offset);

        return response;
    }

    @AuraEnabled
    public static List<ItemCampanha__c> refreshProducts(String campaignId) {
        List<ItemCampanha__c> campaignItems = loadCampaignItems(campaignId);
        return campaignItems;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAvailableDistributionCenters() {
        Map<String, String> distributionCenters = new Map<String, String>{
            'Todos' => 'Todos os centros'
        };

        List<ListaCentroDistribuicao__c> listaCd = [
            SELECT 
                Id, 
                CNPJCD__c,
                NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            ORDER BY NomeCD__c
        ];

        for (ListaCentroDistribuicao__c Cd : listaCd) {
            distributionCenters.put(cd.CNPJCD__c, cd.NomeCD__c);
        }

        return distributionCenters;
    }

    @AuraEnabled
    public static  List<ItemCampanha__c> saveProducts(String campaignId, String records) {
        RecordType rtSalesmanCampaign = [SELECT Id FROM RecordType WHERE DeveloperName = 'ItemCampanhaVendedor' LIMIT 1];
        List<SaveData> dataList = (List<SaveData>) JSON.deserialize(records, List<SaveData>.class);

        List<ItemCampanha__c> recordsList = new List<ItemCampanha__c>();

        for (SaveData data : dataList) {
            String triggerType = null;

            if (data.MetaVolume != null && data.MetaValor != null) {
                triggerType = 'FLD;Volume';
            } else if (data.MetaVolume != null) {
                triggerType = 'Volume';
            } else if (data.MetaValor != null) {
                triggerType = 'FLD';
            }

            ItemCampanha__c campaignItem = new ItemCampanha__c(
                Id = data.Id,
                CNPJCD__c = data.CNPJCD,
                NomeEmpresa__c = data.NomeEmpresa,
                // VigenciaInicial__c = data.VigenciaInicial,
                // VigenciaFinal__c = data.VigenciaFinal,
                MetaVolume__c = data.MetaVolume,
                Meta__c = data.MetaValor,
                TipoGatilho__c = triggerType
            );

            if (campaignItem.Id == null) {
                campaignItem.Campanha__c = data.Campanha;
                campaignItem.NomeProduto__c = data.NomeProduto;
                campaignItem.RecordTypeId = rtSalesmanCampaign?.Id;
            }

            recordsList.add(campaignItem);
        }

        upsert recordsList;

        updateSequence(campaignId);

        List<ItemCampanha__c> campaignItems = loadCampaignItems(campaignId);
        return campaignItems;
    }

    @AuraEnabled(cacheable=false)
    public static  List<ItemCampanha__c> deleteProduct(String campaignId, String recordId) {
        delete new ItemCampanha__c(Id = recordId);

        List<ItemCampanha__c> campaignItems = loadCampaignItems(campaignId);
        return campaignItems;
    }

    @AuraEnabled(cacheable=false)
    public static List<ItemCampanha__c> createItemsByCSVFile(String campaignId, String documentId) {
        RecordType rtSalesmanCampaign = [SELECT Id FROM RecordType WHERE DeveloperName = 'ItemCampanhaVendedor' LIMIT 1];
        String documentData = ReadCSVFileService.getDocumentData(documentId);
        List<String> lines = ReadCSVFileService.getLines(documentData);
    
        Map<String, ItemCampanha__c> mapProductCodeToItem = new Map<String, ItemCampanha__c>();
        Set<String> productCodesSet = new Set<String>();
        
        for (Integer i=0; i<lines.size();i++) {
            
            if (i>0) {
                
                List<String> cols = lines[i].split(',');

                if (cols.size() == 4) { // ok
                    String productCode = cols[0].replaceAll('"', '');
                    // String validityFromCol = cols[1].replaceAll('"', '');
                    // String validityToCol = cols[2].replaceAll('"', '');
                    String MetaCol = cols[1].replaceAll('"', '');
                    String MetaVolumeCol = cols[2].replaceAll('"', '');
                    String CNPJCDcol = cols[3].replaceAll('"', '');

                    // List<String> dateFrom = validityFromCol.split('-');
                    // Date validityFrom = dateFrom.size() == 3 
                    //     ? Date.newInstance(
                    //         Integer.valueOf(dateFrom[0]),
                    //         Integer.valueOf(dateFrom[1]), 
                    //         Integer.valueOf(dateFrom[2])
                    //     ) : null;

                    // List<String> dateTo = validityToCol.split('-');
                    // Date validityTo = dateTo.size() == 3 
                    //     ? Date.newInstance(
                    //         Integer.valueOf(dateTo[0]),
                    //         Integer.valueOf(dateTo[1]), 
                    //         Integer.valueOf(dateTo[2])
                    //     ) : null;

                    Decimal metaVolume;
                    Decimal metaValor;

                    if (MetaVolumeCol != '') {
                        metaVolume = Decimal.valueOf(MetaVolumeCol);
                    }

                    if (MetaCol != '') {
                        metaValor = Decimal.valueOf(MetaCol);
                    }

                    String triggerType = null;

                    if (metaVolume != null && metaValor != null) {
                        triggerType = 'FLD;Volume';
                    } else if (metaVolume != null) {
                        triggerType = 'FLD';
                    } else if (metaValor != null) {
                        triggerType = 'Volume';
                    }

                    ItemCampanha__c campaignItem = new ItemCampanha__c(
                        // VigenciaInicial__c = validityFrom,
                        // VigenciaFinal__c = validityTo,
                        CNPJCD__c = CNPJCDcol.replaceAll(';', ','),
                        Meta__c = metaValor,
                        MetaVolume__c = metaVolume,
                        TipoGatilho__c = triggerType,
                        RecordTypeId = rtSalesmanCampaign?.Id
                    );
    
                    mapProductCodeToItem.put(productCode+'#'+CNPJCDcol, campaignItem);
                    productCodesSet.add(productCode);
                }
            }
        }

        // System.debug(mapProductCodeToItem);
        // System.debug('mapProductCodeToItem '+ mapProductCodeToItem.size());

        Map<String, Id> mapProductCodeToId = loadProductIdsByProductCode(productCodesSet);
        // System.debug('mapProductCodeToId ==>' + mapProductCodeToId);
        Map<String, ItemCampanha__c> mapProductCodeToExistItemCampanha = loadMapProductToCampaignItems(campaignId);

        List<ItemCampanha__c> itemsToUpsert = new List<ItemCampanha__c>();
        for (String customKey : mapProductCodeToItem.keySet()) {
            ItemCampanha__c updatedItem = mapProductCodeToItem.get(customKey);
            List<String> customKeyValues = customKey.split('#');

            System.debug('updatedItem ==>' + updatedItem);
            System.debug('customKeyValues ==>' + customKeyValues);

            if (mapProductCodeToExistItemCampanha.containsKey(customKey)) {
                updatedItem.Id = mapProductCodeToExistItemCampanha.get(customKeyValues[0]).Id;
                itemsToUpsert.add(updatedItem);
            } else {
                System.debug('customKeyValues[0] ==>' + customKeyValues[0]);
                System.debug('mapProductCodeToId.containsKey ==>' + mapProductCodeToId.containsKey(customKeyValues[0]));
                if (mapProductCodeToId.containsKey(customKeyValues[0])) {
                    updatedItem.Campanha__c = campaignId;
                    updatedItem.NomeProduto__c = mapProductCodeToId.get(customKeyValues[0]);
                    itemsToUpsert.add(updatedItem);
                }
            }
        }

        System.debug('itemsToUpsert ' + itemsToUpsert.size());

        upsert itemsToUpsert;
        updateSequence(campaignId);

        delete new ContentDocument(Id = documentId);

        List<ItemCampanha__c> campaignItems = loadCampaignItems(campaignId);
        return campaignItems;
    }

    public static ParamsData loadParams() {
        ParamsData params = new ParamsData();
        params.availableDistributionCenters = getAvailableDistributionCenters();

        return params;
    }

    public static List<Product2> loadProducts(FilterProductData filter, Integer offset) {
        String statement =
            ' SELECT '+
                ' Id, Name, ProductCode, Description, Fornecedor__r.Name ' +
            ' FROM Product2' +
            ' WHERE Id != NULL';
        
        if (filter.product != null && filter.product != '') {
            statement += 
            ' AND ( ' +
                '     Name LIKE \'%'+ filter.product +'%\'' +
                '     OR ProductCode LIKE \'%'+ filter.product +'%\'' +
                '     OR Description LIKE \'%'+ filter.product +'%\'' +
            ' )';
        }

        if (filter.producer != null && filter.producer != '') {
            statement += ' AND Fornecedor__r.Name LIKE \'%'+ filter.producer +'%\'';
        }

        if (offset == null) {
            offset = 20;
        }

        statement += ' ORDER BY Name LIMIT 20 OFFSET ' + offset;

        return Database.query(statement);
    }

    public static Campaign loadCampaign(String campaignId) {
        return [
            SELECT
                Id,
                Name,
                Validade__c,
                RecordType.Name,
                MetaValor__c,
                MetaVolume__c
            FROM Campaign
            WHERE Id =: campaignId
            LIMIT 1
        ];
    }

    public static List<ItemCampanha__c> loadCampaignItems(String campaignId) {
        return [
            SELECT
                Id,
                Campanha__c,
                CNPJCD__c,
                NomeEmpresa__c,
                VigenciaInicial__c,
                VigenciaFinal__c,
                Meta__c,
                MetaVolume__c,
                NomeProduto__c,
                NomeProduto__r.Name,
                NomeProduto__r.Description,
                NomeProduto__r.ProductCode,
                NomeProduto__r.Fornecedor__r.Name
            FROM ItemCampanha__c
            WHERE Campanha__c =: campaignId
            ORDER BY CreatedDate ASC
        ];
    }

    public static List<ItemCampanha__c> loadCampaignItemsByProductId(String campaignId, String productId) {
        return [
            SELECT
                Id
            FROM ItemCampanha__c
            WHERE Campanha__c =: campaignId
            AND NomeProduto__c =: productId
        ];
    }

    public static Map<String, ItemCampanha__c> loadMapProductToCampaignItems(String campaignId) {
        List<ItemCampanha__c> items = [
            SELECT
                Id,
                CNPJCD__c,
                VigenciaInicial__c,
                VigenciaFinal__c,
                NomeProduto__r.Name,
                NomeProduto__r.Description,
                NomeProduto__r.ProductCode,
                NomeProduto__r.Fornecedor__r.Name
            FROM ItemCampanha__c
            WHERE Campanha__c =: campaignId
        ];

        Map<String, ItemCampanha__c> mapItems = new Map<String, ItemCampanha__c>();
        for (ItemCampanha__c item : items) {
            mapItems.put(item.NomeProduto__r.ProductCode+'#'+item.CNPJCD__c, item);
        }

        return mapItems;
    }

    public static Map<String, Id> loadProductIdsByProductCode(Set<String> productCodes) {
        List<Product2> products = [
            SELECT Id, ProductCode
            FROM Product2
            WHERE ProductCode IN: productCodes
        ];

        Map<String, Id> mapProducts = new Map<String, Id>();
        for (Product2 product : products) {
            mapProducts.put(product.ProductCode, product.Id);
        }

        return mapProducts;
    }

    public static void updateSequence(String campaignId) {
        List<ItemCampanha__c> campaignItems = loadCampaignItems(campaignId);
        List<ItemCampanha__c> listToUpdate = new List<ItemCampanha__c>();

        for (Integer i=0; i<campaignItems.size(); i++) {
            String sequence = String.valueOf((i+1));
            String fullSequence = sequence.leftPad(5, '0');

            ItemCampanha__c campaignItem = new ItemCampanha__c(
                Id = campaignItems[i].Id,
                Name = fullSequence.right(5)
            );

            listToUpdate.add(campaignItem);
        }

        update listToUpdate;
    }

    public class ParamsData {
        @AuraEnabled public Map<String, String> availableDistributionCenters;
    }

    public class CampaignData {
        @AuraEnabled public ParamsData params;
        @AuraEnabled public Campaign campaign;
        @AuraEnabled public List<ItemCampanha__c> campaignItems;
    }

    public class AvailableProductsParams {
        @AuraEnabled public FilterProductData filter;
        @AuraEnabled public Integer offset;
    }

    public class ResponseAvailabeProducts {
        @AuraEnabled public List<Product2> products;
    }

    public class FilterProductData {
        @AuraEnabled public String product;
        @AuraEnabled public String producer;
    }

    public class SaveData {
        @AuraEnabled public String Id;
        @AuraEnabled public String Campanha;
        @AuraEnabled public String NomeProduto;
        @AuraEnabled public String CNPJCD;
        @AuraEnabled public String NomeEmpresa;
        @AuraEnabled public Date VigenciaInicial;
        @AuraEnabled public Date VigenciaFinal;
        @AuraEnabled public Decimal MetaVolume;
        @AuraEnabled public Decimal MetaValor;
    }
}
