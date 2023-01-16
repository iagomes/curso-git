@isTest
public with sharing class CampaignManagementControllerTest {
    @isTest
    public static void CampaignManagementControllerTest() {
        try {
            Account account = TestUtility.createAccPJ();
        insert account;

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;
        
        Order order = TestUtility.createOrder(account);
        order.Pricebook2Id = pricebook.Id;
        insert order;

        Product2 prod = TestUtility.createProduct();
        prod.FatorConversao__c = '1';
        Product2 prod2 = TestUtility.createProduct();
        prod.Name += '2';
        prod.FatorConversao__c = '2';
        Product2 prod3 = TestUtility.createProduct();
        prod.Name += '3';
        prod.FatorConversao__c = '3';

        insert new List<Product2>{prod, prod2, prod3};

        PricebookEntry pricebookEntry = TestUtility.createPricebookEntry(pricebook.Id, prod.Id);
        insert pricebookEntry;

        Campaign campaign = new Campaign(
            Name = 'Campaign Test',
            ExternalId__c = '2186',
            RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Campanha').getRecordTypeId()
        );
        insert campaign;

        ItemCampanha__c campaignItem = new ItemCampanha__c(
            Campanha__c = campaign.Id,
            NomeProduto__c = prod.Id,
            VigenciaInicial__c = Date.today().addDays(-10),
            VigenciaFinal__c = Date.today()
        );
        ItemCampanha__c campaignItem2 = new ItemCampanha__c(
            Campanha__c = campaign.Id,
            NomeProduto__c = prod2.Id,
            VigenciaInicial__c = Date.today().addDays(-10),
            VigenciaFinal__c = Date.today()
        );
        ItemCampanha__c campaignItem3 = new ItemCampanha__c(
            Campanha__c = campaign.Id,
            NomeProduto__c = prod3.Id,
            VigenciaInicial__c = Date.today().addDays(-10),
            VigenciaFinal__c = Date.today()
        );
        insert new List<ItemCampanha__c>{campaignItem, campaignItem2, campaignItem3};
        
        ContentVersion ctVersion = TestUtility.createContentVersion();
        insert ctVersion;
        
        List<ContentDocument> contentDocumentList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = order.Id;
        link.ContentDocumentId = contentDocumentList[0].Id;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';
        insert link;

        CampaignManagementController camp = new CampaignManagementController();

        CampaignManagementController.CampaignData campData = new CampaignManagementController.CampaignData();

        CampaignManagementController.FilterProductData filterProd = new CampaignManagementController.FilterProductData();
        filterProd.product  = 'Pricebook Test';
        filterProd.producer = 'B01';
        
        CampaignManagementController.AvailableProductsParams availableProductsParams = new CampaignManagementController.AvailableProductsParams();
        availableProductsParams.filter = filterProd;
        availableProductsParams.offset = 0;

        String availableProductsParamsStr = JSON.serialize(availableProductsParams);
        system.debug(availableProductsParamsStr);

        CampaignManagementController.SaveData saveData = new CampaignManagementController.SaveData();
        saveData.Id          = campaignItem.Id;
        saveData.Campanha    = campaign.Id;
        saveData.NomeProduto = prod.Id;
        saveData.CNPJCD      = '1234564';
        saveData.NomeEmpresa = 'Nome Empresa 1';
        saveData.MetaVolume  = 10;
        saveData.MetaValor   = 123;

        CampaignManagementController.SaveData saveData2 = new CampaignManagementController.SaveData();
        saveData2.Id          = campaignItem2.Id;
        saveData2.Campanha    = campaign.Id;
        saveData2.NomeProduto = prod2.Id;
        saveData2.CNPJCD      = '1234563';
        saveData2.NomeEmpresa = 'Nome Empresa 12';
        saveData2.MetaVolume  = null;
        saveData2.MetaValor   = 123;

        CampaignManagementController.SaveData saveData3 = new CampaignManagementController.SaveData();
        saveData3.Id          = null;
        saveData3.Campanha    = campaign.Id;
        saveData3.NomeProduto = prod3.Id;
        saveData3.CNPJCD      = '1234562';
        saveData3.NomeEmpresa = 'Nome Empresa 123';
        saveData3.MetaVolume  = 10;
        saveData3.MetaValor   = null;

        List<CampaignManagementController.SaveData> listSaveData = new List<CampaignManagementController.SaveData>{saveData, saveData2, saveData3};

        String saveDataString = JSON.serialize(listSaveData);
        system.debug(saveDataString);
        
        CampaignManagementController.loadParams();
        CampaignManagementController.getCampaignData(campaign.Id);
        CampaignManagementController.refreshProducts(campaign.Id);
        CampaignManagementController.updateSequence(campaign.Id);
        CampaignManagementController.loadProducts(filterProd, 0);
        CampaignManagementController.loadCampaign(campaign.Id);
        CampaignManagementController.loadCampaignItems(campaign.Id);
        CampaignManagementController.loadCampaignItemsByProductId(campaign.Id, prod.Id);
        CampaignManagementController.loadMapProductToCampaignItems(campaign.Id);
        CampaignManagementController.loadProductIdsByProductCode(new Set<String>{prod.Id, prod2.Id, prod3.Id});
        CampaignManagementController.getAvailableDistributionCenters();
        CampaignManagementController.createItemsByCSVFile(campaign.id, contentDocumentList[0].Id);
        CampaignManagementController.getAvailableProducts(availableProductsParamsStr);
        CampaignManagementController.saveProducts(campaign.Id, saveDataString);
        
        CampaignManagementController.deleteProduct(campaign.id, campaignItem.id);
        } catch(Exception e) {
            System.debug(e);
        }

    }
}
