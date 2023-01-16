@isTest
public class ProductDistributionCenterLotsControllerT {
    @isTest
    static void getShelfLifeProducts(){
        ListaCentroDistribuicao__c listaCentroDistribuicao = TestUtility.createListaCentroDistribuicao();

        Product2 product = TestUtility.createProduct();
        insert product;
        Campaign campaign = TestUtility.createCampaignShelfLife();
        campaign.NomeCD__c = '1234';
        insert campaign;
        ItemCampanha__c itemcampanha = TestUtility.createItemCampanha(campaign.Id, product.Id);
        itemcampanha.Lote__c = '1';
        itemcampanha.PrecoMinimo__c = 1;
        insert itemcampanha;
        ProductDistributionCenterLotsController.getShelfLifeProducts(product.Id, listaCentroDistribuicao.CNPJCD__c);
    }
}
