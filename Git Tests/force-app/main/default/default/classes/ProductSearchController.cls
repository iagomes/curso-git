global without sharing class ProductSearchController {
    
    @AuraEnabled
    global static String getLookupRecords(String searchText, String oppId){
        
        StandardResponse resp = new StandardResponse();
        try{
            List<Product> results = new List<Product>();

            List<String> fieldNames = new List<String>{
                'Product2Id',
                'Product2.ProductCode',
                'Product2.Name',
                'Product2.UnidadeMedida__c',
                'Product2.Description',
                'Product2.DescriptionQueryable__c'
            };
    
            List<String> lookupSelectFields = new List<String>{
                'Pricebook2Id',
                // 'PrecoFabrica__c', NEED PERMISSION ON PERMISSION SET
                'ExternalId__c',
                'UnitPrice',
                'Product2Id',
                'Product2.ProductCode',
                'toLabel(Product2.CategoriaComercial__c)',
                'Product2.Name',
                'Product2.UnidadeMedida__c',
                'Product2.Description',
                'Product2.DescriptionQueryable__c',
                'Product2.Nomefornecedor__c',
                'Product2.UnidadeMedida__c'
            };
    
            Opportunity opp = [SELECT Id, AccountId, Pricebook2Id FROM Opportunity WHERE Id =: oppId];
    
            QueryBuilder.ComplexCondition complexCondition = new QueryBuilder.ComplexCondition()
            // .andCondition(new QueryBuilder.CompareCondition('Pricebook2Id').eq(opp.Pricebook2Id));
            .andCondition(new QueryBuilder.CompareCondition('Pricebook2.Name').eq('Standard Price Book'));//Pricebook2.Name = 'Standard Price Book'
    
            List<PricebookEntry> pbEntries = (List<PricebookEntry>) UtilitiesController.getLookupRecordList(searchText, 'PricebookEntry', fieldNames, lookupSelectFields, 'Product2.DescriptionQueryable__c', complexCondition);

            Set<Id> setProductId = new Set<Id>();
            for(PricebookEntry pbe: (List<PricebookEntry>)pbEntries){
                setProductId.add(pbe.Product2Id);
            }

            Map<Id, Decimal> mapPbeIdToBalance = ProductHelper.getMapEstoqueByProductId(setProductId, opp.AccountId);

            for(PricebookEntry pbe: pbEntries){
                results.add(new Product(pbe, (pbe.Product2Id != null ? mapPbeIdToBalance.get(pbe.Product2Id) : null)));
            }

            resp.setData('records', results);

        }catch(Exception ex){
            ExceptionUtils.debug(ex);
            resp.addError('Falha na busca de produtos: ' + ex.getMessage());
        }
        return resp.toJSON();
    }

    public class Product {

        public String CategoriaComercial {get;set;}
        public String Description {get;set;}
        public String DescriptionQueryable {get;set;}
        public String ExternalId {get;set;}
        public String Name {get;set;}
        public String Nomefornecedor {get;set;}
        // public Decimal PrecoFabrica {get;set;}
        public String Pricebook2Id {get;set;}
        public String Id {get;set;}
        public String ProductCode {get;set;}
        public String UnidadeMedida {get;set;}
        public Decimal UnitPrice {get;set;}
        public String estoque {get;set;}


        public Product(PricebookEntry pbe, Decimal estoque){
            
            this.CategoriaComercial = String.isNotBlank(pbe.Product2.CategoriaComercial__c) ? pbe.Product2.CategoriaComercial__c : '-';
            this.Description = pbe.Product2.Description;
            this.DescriptionQueryable = pbe.Product2.DescriptionQueryable__c;
            this.ExternalId = pbe.ExternalId__c;
            this.Name = pbe.Product2.Name;
            this.Nomefornecedor = pbe.Product2.Nomefornecedor__c;
            // this.PrecoFabrica = pbe.PrecoFabrica__c;
            this.Pricebook2Id = pbe.Pricebook2Id;
            this.Id = pbe.Product2Id;
            this.ProductCode = pbe.Product2.ProductCode;
            this.UnidadeMedida = pbe.Product2.UnidadeMedida__c;
            this.UnitPrice = pbe.UnitPrice;

            if(estoque != null){
                this.estoque = String.valueOf(estoque);
            } else {
                this.estoque = 'Informação não disponível';
            }
        }


    }
}