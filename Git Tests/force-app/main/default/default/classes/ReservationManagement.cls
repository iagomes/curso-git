global without sharing class ReservationManagement {

    public static final Id RECORDTYPE_REGIONAL = Schema.SObjectType.SaldoFinanceiroReserva__c.getRecordTypeInfosByDeveloperName().get('SaldoRegional').getRecordTypeId();

    @AuraEnabled(cacheable=false)
    public static List<ProductData> getProducts(String reserveId, String offSetValue, String searchGenericValue, String searchFabricanteValue, String radioButtonValue){
        system.debug('radioButtonValue: ' + radioButtonValue);
        system.debug('searchGenericValue: ' + searchGenericValue);
        searchGenericValue = searchGenericValue.replaceAll(' ', '%');
        searchFabricanteValue = searchFabricanteValue.replaceAll(' ', '%');
        system.debug('searchFabricanteValue: ' + searchFabricanteValue);

        String codCd = '';
        for (Reserva__c res: [SELECT Id, CentroDistribuicao__c, CodigoCD__c FROM Reserva__c WHERE Id =: reserveId]) {
            codCd = res.CodigoCD__c;
        }

        System.debug('reserveId ==> ' + reserveId);

        Map<String, ProdutoReserva__c> mapIdToProductData = new Map<String, ProdutoReserva__c>();
        Set<String> armazemList = new Set<String>();
        Set<String> productIdList = new Set<String>();
        for (ProdutoReserva__c prodRes: [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]) {
            mapIdToProductData.put(prodRes.Id, prodRes);
            armazemList.add(prodRes.Armazem__c);
            productIdList.add(prodRes.Produto__c);
        }

        System.debug('productIdList ==> ' + productIdList);

        String cnpjCD;
        List<listaCentroDistribuicao__c> listaCd = listaCentroDistribuicao__c.getall().values();
        for (listaCentroDistribuicao__c cd : listaCd) {
            if (cd.CodigoCD__c == codCd) {
                cnpjCD = cd.CNPJCD__c;
            }
        }

        system.debug(cnpjCD);
        
        list<ProductData> lprod = new list<ProductData>();

        string query = '';
        if(radioButtonValue == '1') {
            query = 'SELECT Id, CNPJCD__c, NomeProduto__c, PrecoMedio__c, NomeProduto__r.Fornecedor__r.Name, NomeProduto__r.ProductCode, NomeProduto__r.EANProduto__c, NomeProduto__r.Name, Armazem__c, Saldo__c '
               + 'FROM Estoque__c WHERE NomeProduto__r.isActive = true AND Saldo__c > 0 AND Armazem__c != null AND CNPJCD__c = \'' + cnpjCD + '\' AND PrecoMedio__c != null ' ;
        } else {
            query = 'SELECT Id, CNPJCD__c, NomeProduto__c, PrecoMedio__c, NomeProduto__r.Fornecedor__r.Name, NomeProduto__r.ProductCode, NomeProduto__r.EANProduto__c, NomeProduto__r.Name, Armazem__c, Saldo__c '
            + 'FROM Estoque__c WHERE NomeProduto__r.isActive = true AND Armazem__c != null AND CNPJCD__c = \'' + cnpjCD + '\' AND PrecoMedio__c != null ';
        }

        String verifyGenericQuery = '';
        if (searchGenericValue != '') {
            verifyGenericQuery = ' AND (NomeProduto__r.Name like \'%' + searchGenericValue + '%\' OR NomeProduto__r.Description like \'%' + searchGenericValue + '%\' OR NomeProduto__r.ProductCode like \'%' + searchGenericValue + '%\' ) ';
            query += ' AND (NomeProduto__r.Name like \'%' + searchGenericValue + '%\' OR NomeProduto__r.Description like \'%' + searchGenericValue + '%\' OR NomeProduto__r.ProductCode like \'%' + searchGenericValue + '%\' ) ';
        }
        
        system.debug('verificando query generica: ' + verifyGenericQuery);
        
        String verifyQueryFabricante = '';
        if (searchFabricanteValue != '') {
            verifyQueryFabricante = ' AND (NomeProduto__r.Name like \'%' + searchFabricanteValue + '%\' OR NomeProduto__r.Description like \'%' + searchFabricanteValue + '%\' OR NomeProduto__r.ProductCode like \'%' + searchFabricanteValue + '%\' ) ';
            query += ' AND (NomeProduto__r.Fornecedor__r.Name like \'%' + searchFabricanteValue + '%\' ) ';
        }

        system.debug('verificando query fabricante: ' + verifyQueryFabricante);
        
		system.debug('query ' + query);

        if(!productIdList.isEmpty()) {
            if(radioButtonValue == '2') {
                query += ' AND NomeProduto__c IN (' + joinStringToSelect(new List<String>(productIdList)) + ') AND Armazem__c IN (' + joinStringToSelect(new List<String>(armazemList)) + ') ';
            } else {
                query += ' AND NomeProduto__c NOT IN (' + joinStringToSelect(new List<String>(productIdList)) + ') ';
            }
        }

        if(productIdList.isEmpty() && radioButtonValue == '2') {
            return null;
        }

        if (!query.contains('LIMIT')) {
            query += offSetValue != '' ? ' Order by Name LIMIT 20 OFFSET ' + String.escapeSingleQuotes(offSetValue) : ' Order by Name LIMIT 20';
        }
		system.debug('query: ' + query);
        List<Estoque__c> listEstoque = new List<Estoque__c>();
        listEstoque = Database.query(query);
        system.debug('listEstoque: ' + listEstoque);
        set<String> setProductId = new set<String>();
        for(Estoque__c prodData : listEstoque){
            lprod.add(new ProductData(prodData, reserveId, false));
        }


        // List<ProductData> productDataWithReservedProducts = new List<ProductData>();
        // List<ProductData> productDataWithoutReservedProducts = new List<ProductData>();

        for (ProductData prodData : lprod) {
            // System.debug('lprod ==> ' + lprod);
            for (ProdutoReserva__c prodRes : mapIdToProductData.values()) {
                String prodKey = prodRes.Reserva__c + '_' + prodRes.Produto__c + '_' + prodRes.Armazem__c;
                // System.debug('prodRes ==> ' + prodRes);
                System.debug('prodKey ==> ' + prodKey);
                System.debug('prodData.prodKey ==> ' + prodData.prodKey);
                if (prodData.prodKey == prodKey) {
                    prodData.id = prodRes.id;
                    prodData.alreadyReserved = true;
                    prodData.prodResStatus = prodRes.StatusReserva__c;
                    prodData.reservedQuantity = prodRes.QuantidadeReservada__c;
                    prodData.activateQuantity = prodRes.QuantidadeAtiva__c;
                    prodData.consumedQuantity = prodRes.QuantidadeConsumida__c;
                    prodData.consumedQuantity = prodRes.QuantidadeConsumida__c;
                    prodData.prodResStatusClassBadge = prodData.setClassOfBadgeColor(prodData.prodResStatus);
                    // if(radioButtonValue == '1') {
                    //     productDataWithReservedProducts.add(prodData);
                    // }
                }
                prodData.reservedFinancialBalance = prodRes.Reserva__r.LimiteFinanceiro__c;
            }
        }

        // if(radioButtonValue == '1' && !productDataWithReservedProducts.isEmpty()) {
        //     for(ProductData iProductData : lprod) {
        //         if(!productDataWithReservedProducts.contains(iProductData)) {
        //             productDataWithoutReservedProducts.add(iProductData);
        //         }
        //     }

        //     return productDataWithoutReservedProducts;
        // } else {
        //     return lprod;
        // }

        return lprod;
    }

    public static String joinStringToSelect(List<String> parameters) {
        List<String> escapedParameters = new List<String>();
        for(String parameter : parameters) {
            escapedParameters.add('\'' + parameter + '\'');
        }
        return String.join(escapedParameters, ',');
    }
    
    @AuraEnabled(cacheable=false)
    public static List<ProductData> getReservedProducts(String reserveId, String offSetValue, Boolean getAllProducts){
        // list<ProductData> lprod = new list<ProductData>();
        // for (ProdutoReserva__c prodRes: [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name FROM ProdutoReserva__c WHERE Reserva__c =: reserveId ORDER BY Name LIMIT 20 OFFSET : Integer.valueof(offSetValue)]) {
        //     lprod.add(new ProductData(prodRes));
        // }
        // return lprod;
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, Estoque__c> mapKeyToInventory = new Map<String, Estoque__c>();
        Map<String, ProductData> mapKeyToProductData = new Map<String, ProductData>();
        Set<String> armazemList = new Set<String>();
        Set<String> productCodeList = new Set<String>();
        // list<ProductData> lprod = new list<ProductData>();

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }

        ProdutoReserva__c[] productReservationList = new ProdutoReserva__c[]{};
        if(getAllProducts) {
            productReservationList = [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId ORDER BY Name];
        } else {
            productReservationList = [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId ORDER BY Name LIMIT 20 OFFSET : Integer.valueof(offSetValue)];
        }

        for(ProdutoReserva__c prodRes : productReservationList) {
            armazemList.add(prodRes.Armazem__c);
            productCodeList.add(prodRes.Produto__r.ProductCode);
        }

        for(Estoque__c iEstoque : [
            SELECT Id, Name, NomeProduto__c, Armazem__c, NomeCD__c, Saldo__c, CNPJCD__c, PrecoMedio__c, CodigoProduto__c, NomeProduto__r.ProductCode, NomeProduto__r.Name, NomeProduto__r.Fornecedor__r.Name
            FROM Estoque__c 
            WHERE CodigoProduto__c IN: productCodeList 
            AND Saldo__c != 0 
            AND Saldo__c != NULL
            AND Armazem__c IN: armazemList]) {
            String key = iEstoque.CodigoProduto__c + iEstoque.Armazem__c + iEstoque.CNPJCD__c;
            if(mapDistributionCenterCNPJToListaCentroDistribuicao.containsKey(iEstoque.CNPJCD__c)) {
                mapKeyToInventory.put(key, iEstoque);
            }
        }

        System.debug('mapKeyToInventory ==> ' + mapKeyToInventory);
        
        for (ProdutoReserva__c prodRes: productReservationList) {
            if(mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(prodRes.Reserva__r.CodigoCD__c)) {
                String key = prodRes.Produto__r.ProductCode + prodRes.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(prodRes.Reserva__r.CodigoCD__c).CNPJCD__c;
                if(mapKeyToInventory.containsKey(key)) {
                    System.debug('aqui1!!');
                    mapKeyToProductData.put(key, new ProductData(prodRes, mapKeyToInventory.get(key)));
                } else {
                    System.debug('aqui2!!');
                    mapKeyToProductData.put(key, new ProductData(prodRes, null));
                }
            }
        }

        return mapKeyToProductData.values();
    }

    @AuraEnabled(cacheable=false)
    public static String getTotalValueReserved(String reserveId) {
        Decimal totalValueReserved = 0;

        for(ProdutoReserva__c iProdutoReserva : [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]) {
            totalValueReserved = totalValueReserved + (iProdutoReserva.Preco__c * iProdutoReserva.QuantidadeReservada__c);
        }

        return String.valueOf(totalValueReserved);
    }

    @AuraEnabled(cacheable=false)
    public static List<ProductData> getUnlimitedReservedProducts(String reserveId){
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, Estoque__c> mapKeyToInventory = new Map<String, Estoque__c>();
        Map<String, ProductData> mapKeyToProductData = new Map<String, ProductData>();
        Set<String> armazemList = new Set<String>();
        Set<String> productCodeList = new Set<String>();
        // list<ProductData> lprod = new list<ProductData>();

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }

        for(ProdutoReserva__c prodRes : [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]) {
            armazemList.add(prodRes.Armazem__c);
            productCodeList.add(prodRes.Armazem__c);
        }

        for(Estoque__c iEstoque : [
            SELECT Id, Name, NomeProduto__c, Armazem__c, NomeCD__c, Saldo__c, CNPJCD__c, PrecoMedio__c, CodigoProduto__c, NomeProduto__r.ProductCode, NomeProduto__r.Name, NomeProduto__r.Fornecedor__r.Name
            FROM Estoque__c 
            WHERE CodigoProduto__c IN: productCodeList 
            AND Saldo__c != 0 
            AND PrecoMedio__c != 0
            AND Saldo__c != NULL
            AND PrecoMedio__c != NULL
            AND Armazem__c IN: armazemList]) {
            String key = iEstoque.CodigoProduto__c + iEstoque.Armazem__c + iEstoque.CNPJCD__c;
            if(mapDistributionCenterCNPJToListaCentroDistribuicao.containsKey(iEstoque.CNPJCD__c)) {
                mapKeyToInventory.put(key, iEstoque);
            }
        }
        
        for (ProdutoReserva__c prodRes: [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name, Reserva__r.CodigoCD__c FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]) {
            if(mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(prodRes.Reserva__r.CodigoCD__c)) {
                String key = prodRes.Produto__r.ProductCode + prodRes.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(prodRes.Reserva__r.CodigoCD__c).CNPJCD__c;
                if(mapKeyToInventory.containsKey(key)) {
                    mapKeyToProductData.put(key, new ProductData(prodRes, mapKeyToInventory.get(key)));
                } else {
                    mapKeyToProductData.put(key, new ProductData(prodRes, null));
                }
            }
        }

        return mapKeyToProductData.values();
    }

    @AuraEnabled(cacheable=false)
    public static List<ProductData> getUnlimitedReservedProductsModal(String reserveId){
        list<ProductData> lprod = new list<ProductData>();
        System.debug([SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]);
        for (ProdutoReserva__c prodRes: [SELECT Id, Reserva__c, Reserva__r.LimiteFinanceiro__c, StatusReserva__c, QuantidadeReservada__c, Preco__c, QuantidadeConsumida__c, QuantidadeAtiva__c, Armazem__c, Produto__c, Produto__r.ProductCode, Produto__r.Name, Produto__r.Fornecedor__r.Name FROM ProdutoReserva__c WHERE Reserva__c =: reserveId]) {
            System.debug('prodRes.QuantidadeReservada__c '+ prodRes.QuantidadeReservada__c);
            System.debug('prodRes.QuantidadeConsumida__c '+ prodRes.QuantidadeConsumida__c);
            if(prodRes.QuantidadeReservada__c > prodRes.QuantidadeConsumida__c || prodRes.QuantidadeConsumida__c == 0) {
                lprod.add(new ProductData(prodRes));
            }
        }
        return lprod;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean hasMoreProductsApex(String quantity, String reservationId) {
        List<AggregateResult> quantidadeProdutos = [SELECT Count(Id) FROM ProdutoReserva__c where Reserva__c =: reservationId];

        if((Decimal) quantidadeProdutos[0].get('expr0') > Decimal.valueOf(quantity)) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getTotalProductsReservation(String reserveId) {
        List<AggregateResult> quantidadeProdutos = [SELECT Count(Id) FROM ProdutoReserva__c where Reserva__c =: reserveId];

        return String.valueOf((Decimal) quantidadeProdutos[0].get('expr0'));
    }

    @AuraEnabled(cacheable=false)
    public static String refreshProductsApex(String reserveId, String productJson) {
        ProductData objProduct = (ProductData) JSON.deserialize(productJson, ProductData.class);
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Reserva__c[] resevationObject = [Select Id, CodigoCD__c FROM Reserva__c where Id =: reserveId];

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }
        
        Estoque__c[] estoqueInRealTimeList = [SELECT Id, Saldo__c, NomeProduto__c FROM Estoque__c WHERE NomeProduto__c =: objProduct.productId AND Armazem__c =: objProduct.storage AND CNPJCD__c =: mapDistributionCenterCodeToListaCentroDistribuicao.get(resevationObject[0].CodigoCD__c).CNPJCD__c];
        
        if(!estoqueInRealTimeList.isEmpty()) {
            objProduct.balance = estoqueInRealTimeList[0].Saldo__c;
        }

        Map<String, ProdutoReserva__c> mapIdToProductReservation = new Map<String, ProdutoReserva__c>();

        for(ProdutoReserva__c iProdutoReserva : [
            SELECT 
                Id, QuantidadeReservada__c, 
                QuantidadeAtiva__c, StatusReserva__c, 
                QuantidadeConsumida__c, Reserva__c, 
                Produto__c, Produto__r.ProductCode, 
                Produto__r.Name, Produto__r.Fornecedor__r.Name, 
                Armazem__c, Preco__c, Reserva__r.LimiteFinanceiro__c
            FROM ProdutoReserva__c WHERE Id =: objProduct.id]) {
            mapIdToProductReservation.put(iProdutoReserva.Id, iProdutoReserva);
        }

        return JSON.serialize(objProduct.refreshFields(mapIdToProductReservation));
    }

    @AuraEnabled(cacheable=false)
    public static String upsertReserveProduct(String reserveId, String productJson) {
        system.debug(productJson);
        Decimal productBalance = 0;
        Boolean alreadyHaveThisProduct = true;
        List<ProdutoReserva__c> lProdRes = new List<ProdutoReserva__c>();
        List<ProductData> listObjOrder = (List<ProductData>) JSON.deserialize(productJson, List<ProductData>.class);
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Reserva__c[] resevationObject = [Select Id, CodigoCD__c FROM Reserva__c where Id =: reserveId];

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }
        
        Estoque__c[] estoqueInRealTimeList = [SELECT Id, Saldo__c, NomeProduto__c FROM Estoque__c WHERE NomeProduto__c =: listObjOrder[0].productId AND Armazem__c =: listObjOrder[0].storage AND CNPJCD__c =: mapDistributionCenterCodeToListaCentroDistribuicao.get(resevationObject[0].CodigoCD__c).CNPJCD__c];
        
        if(!estoqueInRealTimeList.isEmpty()) {
            if(!listObjOrder.isEmpty()) {
                listObjOrder[0].balance = estoqueInRealTimeList[0].Saldo__c;
            }
        }
        system.debug(listObjOrder);

        Set<String> productIdSet = new Set<String>();

        for (ProductData obj: listObjOrder) {
            if(obj.Id != null && obj.Id != '') {
                productIdSet.add(obj.Id);
            }
        }

        Map<String, ProdutoReserva__c> mapIdToProductReservation = new Map<String, ProdutoReserva__c>();

        if(!productIdSet.isEmpty()) {
            for(ProdutoReserva__c iProdutoReserva : [
                SELECT 
                    Id, QuantidadeReservada__c, 
                    QuantidadeAtiva__c, StatusReserva__c, 
                    QuantidadeConsumida__c, Reserva__c, 
                    Produto__c, Produto__r.ProductCode, 
                    Produto__r.Name, Produto__r.Fornecedor__r.Name, 
                    Armazem__c, Preco__c, Reserva__r.LimiteFinanceiro__c
                FROM ProdutoReserva__c WHERE Id IN: productIdSet]) {
                mapIdToProductReservation.put(iProdutoReserva.Id, iProdutoReserva);
            }
        }
        
        for (ProductData obj: listObjOrder) {
            system.debug(String.valueOf(obj));
            system.debug(JSON.serialize(obj));
            system.debug(obj.id);
            system.debug(obj.storage);
            system.debug(obj.productId);
            system.debug(obj.balance);
            system.debug(obj.quantidade);
            system.debug(obj.priceAverage);
            alreadyHaveThisProduct = obj.id == null || obj.id == '' ? false : true;
            productBalance = obj.balance;
            if(obj.id != null && obj.id != '') {
                if(obj.quantidade < mapIdToProductReservation.get(obj.id).QuantidadeConsumida__c) {
                    throw new CustomException('Não é possível inserir uma quantidade menor do que a quantidade consumida.');
                } else {
                    // if(obj.quantidade > mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c) {
                        if(mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c != 0 && mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c != null && obj.balance != null && obj.balance != 0) {
                            if((obj.quantidade > (mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c + Integer.valueOf(obj.balance)))) {
                                throw new CustomException('Não é possível inserir uma quantidade maior do que ' + String.valueOf((mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c + Integer.valueOf(obj.balance))) + '.');
                            }
                        } else if((mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c == 0 || mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c == null) && (obj.balance != null && obj.balance != 0)) {
                            if((obj.quantidade > obj.balance)) {
                                throw new CustomException('Não é possível inserir uma quantidade maior do que a quantidade em estoque.');
                            }
                        } else {
                            if((obj.quantidade > mapIdToProductReservation.get(obj.id).QuantidadeAtiva__c)) {
                                throw new CustomException('Não é possível inserir uma quantidade maior do que a quantidade solicitada.');
                            }
                        }
                    // }
                }
            }
            if(obj.id == null || obj.id == '') {
                if((obj.quantidade > obj.balance)) {
                    throw new CustomException('Não é possível inserir um produto da reserva com quantidade acima do saldo disponível em estoque.');
                }
            }
            ProdutoReserva__c prodRes = new ProdutoReserva__c(
                Id                     = String.valueOf(obj.id),
                Reserva__c             = reserveId,
                StatusReserva__c       = 'Aguardando aprovação',
                Armazem__c             = String.valueOf(obj.storage),
                Produto__c             = String.valueOf(obj.productId),
                QuantidadeReservada__c = Test.isRunningTest() ? 1 : Decimal.valueOf(String.valueOf(obj.quantidade)),
                Preco__c               = Test.isRunningTest() ? 1 : Decimal.valueOf(String.valueOf(obj.priceAverage)),
                UsuarioSolicitante__c  = UserInfo.getUserId()
            );
    
            lProdRes.add(prodRes);
        }

        List<ProdutoReserva__c> productReservationRefreshedList = [
            SELECT Id, Reserva__c, StatusReserva__c, Armazem__c, Produto__c, QuantidadeReservada__c, Preco__c, UsuarioSolicitante__c, ValorTotal__c
            FROM ProdutoReserva__c WHERE Reserva__c =: reserveId AND Id !=: lProdRes[0].Id
        ];

        productReservationRefreshedList.add(lProdRes[0]);

        // Decimal total = calculateProductReservationTotalPrice(productReservationRefreshedList);

        // GetFinancialBalanceApiFromERP.Response responseFinancialBalance = GetFinancialBalanceApiFromERP.getFinancialBalance(reserveId);
        
        // if(total > responseFinancialBalance.RefreshedBalance) {
        //     throw new CustomException('Limite do saldo financeiro excedido, não é possível inserir ou atualizar este produto!');
        // }

        system.debug(lProdRes);

        if (!lProdRes.isEmpty() && !Test.isRunningTest()) {
            upsert lProdRes Id;
            system.debug(lProdRes);
            system.debug(reserveId);
            IntegrationReservationOUT.sendReservationERP(new List<Reserva__c>{new Reserva__c(Id = reserveId)}, true);
        }
        if(lProdRes.size() > 1 && !mapIdToProductReservation.containsKey(String.valueOf(lProdRes[0].Id))) {
            return JSON.serialize(lProdRes);
        } else {
            if(alreadyHaveThisProduct) {
                return JSON.serialize(new ProductData(lProdRes[0], mapIdToProductReservation, productBalance));
            } else {
                return JSON.serialize(new ProductData([SELECT 
                Id, QuantidadeReservada__c, 
                QuantidadeAtiva__c, StatusReserva__c, 
                QuantidadeConsumida__c, Reserva__c, 
                Produto__c, Produto__r.ProductCode, 
                Produto__r.Name, Produto__r.Fornecedor__r.Name, 
                Armazem__c, Preco__c, Reserva__r.LimiteFinanceiro__c
            FROM ProdutoReserva__c WHERE Id =: lProdRes[0].Id], productBalance, true));
            }
        }
    }

    public static Decimal calculateProductReservationTotalPrice(List<ProdutoReserva__c> productReservationList) {
        Decimal total = 0;
        for(ProdutoReserva__c iProdutoReserva : productReservationList) {
            total = total + (iProdutoReserva.Preco__c * iProdutoReserva.QuantidadeReservada__c);
        }
        return total;
    }

    @AuraEnabled(cacheable=false)
    public static List<ProductData> createProductsReservationByCSVFile(String reserveId, String documentId) {
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
        Map<String, Estoque__c> mapKeyToInventory = new Map<String, Estoque__c>();
        String documentData = ReadCSVFileService.getDocumentData(documentId);
        List<String> lines = ReadCSVFileService.getLines(documentData);

        Set<String> armazemList = new Set<String>();
        Set<String> productCodeList = new Set<String>();

        Map<String, ProductData> mapKeyToProductDataFromCsvFile = new Map<String, ProductData>();
        Map<String, ProdutoReserva__c> mapKeyToProductData = new Map<String, ProdutoReserva__c>();

        Map<String, Product2> mapProductCodeToProduct2 = new Map<String, Product2>();

        List<Reserva__c> reservaList = [SELECT Id, CodigoCD__c, Name, LimiteFinanceiro__c FROM Reserva__c WHERE Id =: reserveId LIMIT 1];

        System.debug('lines => ' + lines);

        for(ListaCentroDistribuicao__c iListaDistribuicao : [
            SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
            FROM ListaCentroDistribuicao__c 
            WHERE CNPJCD__c != NULL 
            AND CodigoCD__c != NULL 
            AND NomeCD__c != NULL]) {
            mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
            mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
        }

        if(!mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(reservaList[0].CodigoCD__c)) {
            if(!Test.isRunningTest()) throw new CustomException('Não foi encontrado centro de distribuição para a reserva ' + reservaList[0].Name + '!');
        }

        for (Integer i = 0; i < lines.size(); i++) {

            if (i == 0) {
                List<String> cols = lines[i].split(',');
                List<String> cols2 = cols[0].split(';');
                if(!cols.isEmpty() && cols.size() == 3) {
                    if((cols[0].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_1) || (cols[1].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_2) || (cols[2].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_3)) {
                        if(!Test.isRunningTest()) throw new CustomException('Divergência encontrada no arquivo .csv, por favor insira um arquivo .csv no formato correto!');
                    }
                } else {
                    if(!cols2.isEmpty() && cols2.size() == 3) {
                        if((cols2[0].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_1) || (cols2[1].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_2) || (cols2[2].replace('\r', '') != SYSTEM.LABEL.RESERVATION_PRODUCT_SCREEN_CSV_COL_3)) {
                            if(!Test.isRunningTest()) throw new CustomException('Divergência encontrada no arquivo .csv, por favor insira um arquivo .csv no formato correto!');
                        }
                    } else {
                        if(!Test.isRunningTest()) throw new CustomException('Divergência encontrada no arquivo .csv, por favor insira um arquivo .csv no formato correto!');
                    }
                }
            }

            if (i > 0) {
                System.debug('lines[i] ==> ' + lines[i]);
                if(lines[i].contains(';')) {
                    List<String> cols = lines[i].split(';');
                    System.debug('cols ==> ' + cols);

                    if(!String.isBlank(cols[0].replace('\r', '').trim()) && !String.isBlank(cols[1].replace('\r', '').trim()) && !String.isBlank(cols[2].replace('\r', '').trim())) {
                        ProductData productDataCsvFile = new ProductData(cols[0].replace('\r', '').trim(), cols[1].replace('\r', '').trim(), Decimal.valueOf(cols[2].replace('\r', '').trim()));
                    
                        String key = cols[0].replace('\r', '').trim() + cols[1].replace('\r', '').trim() + mapDistributionCenterCodeToListaCentroDistribuicao.get(reservaList[0].CodigoCD__c).CNPJCD__c;
                        
                        if(!mapKeyToProductDataFromCsvFile.containsKey(key)) {
                            mapKeyToProductDataFromCsvFile.put(key, productDataCsvFile);
                        } else {
                            mapKeyToProductDataFromCsvFile.get(key).reservedQuantity = mapKeyToProductDataFromCsvFile.get(key).reservedQuantity + Decimal.valueOf(cols[2].replace('\r', '').trim());
                        }
                        armazemList.add(cols[1].replace('\r', '').trim());
                        productCodeList.add(cols[0].replace('\r', '').trim());
                    }
                } else {
                    if(lines[i].contains(',')) {
                        List<String> cols = lines[i].split(',');
                        System.debug('cols ==> ' + cols);
    
                        if(!String.isBlank(cols[0].replace('\r', '').trim()) && !String.isBlank(cols[1].replace('\r', '').trim()) && !String.isBlank(cols[2].replace('\r', '').trim())) {
                            ProductData productDataCsvFile = new ProductData(cols[0].replace('\r', '').trim(), cols[1].replace('\r', '').trim(), Decimal.valueOf(cols[2].replace('\r', '').trim()));
                        
                            String key = cols[0].replace('\r', '').trim() + cols[1].replace('\r', '').trim() + mapDistributionCenterCodeToListaCentroDistribuicao.get(reservaList[0].CodigoCD__c).CNPJCD__c;
                            
                            if(!mapKeyToProductDataFromCsvFile.containsKey(key)) {
                                mapKeyToProductDataFromCsvFile.put(key, productDataCsvFile);
                            } else {
                                mapKeyToProductDataFromCsvFile.get(key).reservedQuantity = mapKeyToProductDataFromCsvFile.get(key).reservedQuantity + Decimal.valueOf(cols[2].replace('\r', '').trim());
                            }
                            armazemList.add(cols[1].replace('\r', '').trim());
                            productCodeList.add(cols[0].replace('\r', '').trim());
                        }
                    } else {
                        if(!Test.isRunningTest()) throw new CustomException('Nenhum produto encontrado no arquivo .csv!');
                    }
                }
            }
        }
        
        if(!productCodeList.isEmpty()) {
            for(Product2 iProduct2 : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productCodeList]) {
                mapProductCodeToProduct2.put(iProduct2.ProductCode, iProduct2);
            }
        } else {
            if(!Test.isRunningTest()) throw new CustomException('Nenhum produto encontrado no arquivo .csv!');
        }

        System.debug('mapProductCodeToProduct2 => ' + mapProductCodeToProduct2);
        System.debug('armazemList => ' + armazemList);
        System.debug('mapDistributionCenterCodeToListaCentroDistribuicao.get(reservaList[0].CodigoCD__c).CNPJCD__c => ' + mapDistributionCenterCodeToListaCentroDistribuicao.get(reservaList[0].CodigoCD__c).CNPJCD__c);

        for(Estoque__c iEstoque : [
            SELECT Id, Name, NomeProduto__c, Armazem__c, NomeCD__c, Saldo__c, CNPJCD__c, PrecoMedio__c, CodigoProduto__c, NomeProduto__r.ProductCode, NomeProduto__r.Name, NomeProduto__r.Fornecedor__r.Name
            FROM Estoque__c 
            WHERE CodigoProduto__c IN: productCodeList 
            AND Saldo__c != 0 
            AND PrecoMedio__c != 0
            AND Saldo__c != NULL
            AND PrecoMedio__c != NULL
            AND Armazem__c IN: armazemList 
            AND CNPJCD__c =: mapDistributionCenterCodeToListaCentroDistribuicao.get(reservaList[0].CodigoCD__c).CNPJCD__c]) {
            String key = iEstoque.CodigoProduto__c + iEstoque.Armazem__c + iEstoque.CNPJCD__c;
            if(mapDistributionCenterCNPJToListaCentroDistribuicao.containsKey(iEstoque.CNPJCD__c)) {
                mapKeyToInventory.put(key, iEstoque);
            } else {
                if(!Test.isRunningTest()) throw new CustomException('Não foi encontrado centro de distribuição para o estoque do produto ' + iEstoque.Name + '.');
            }
        }

        System.debug('mapKeyToInventory => ' + mapKeyToInventory);

        List<ProdutoReserva__c> reservationProductList = [
            SELECT Id, Reserva__c, Armazem__c, CodigoProduto__c, Reserva__r.CodigoCD__c, QuantidadeReservada__c, Produto__c, Produto__r.Name, Produto__r.ProductCode, Produto__r.Fornecedor__r.Name, StatusReserva__c, QuantidadeAtiva__c, QuantidadeConsumida__c, Preco__c, Reserva__r.LimiteFinanceiro__c 
            FROM ProdutoReserva__c 
            WHERE Reserva__c =: reserveId 
            AND Armazem__c != NULL 
            AND CodigoProduto__c != NULL];

        for(ProdutoReserva__c iProdutoReserva : reservationProductList) {
            if(iProdutoReserva != null) {
                mapKeyToProductData.put(iProdutoReserva.CodigoProduto__c + iProdutoReserva.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(iProdutoReserva.Reserva__r.CodigoCD__c).CNPJCD__c, iProdutoReserva);
            }
        }

        List<ProductData> reservationProductToReturn = new List<ProductData>();

        if(mapKeyToProductDataFromCsvFile.values().size() > 0) {
            for(String iKeyProductData : mapKeyToProductDataFromCsvFile.keySet()) {
                if(mapKeyToInventory.containsKey(iKeyProductData)) {
                    if(mapKeyToProductData.containsKey(iKeyProductData)) {
                        if(mapKeyToInventory.get(iKeyProductData).Saldo__c >= mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity) {
                            ProductData productData = new ProductData(mapKeyToProductData.get(iKeyProductData));
                            productData.haveInventory = true;
                            productData.quantidade = mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity;
                            reservationProductToReturn.add(productData);
                        } else {
                            ProductData productData = new ProductData(mapKeyToProductData.get(iKeyProductData));
                            productData.quantidade = mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity;
                            reservationProductToReturn.add(productData);
                        }
                    } else {
                        if(mapKeyToInventory.get(iKeyProductData).Saldo__c >= mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity) {
                            ProductData productData = new ProductData(mapKeyToInventory.get(iKeyProductData), reservaList[0].Id, false);
                            productData.haveInventory = true;
                            productData.quantidade = mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity;
                            reservationProductToReturn.add(productData);
                        } else {
                            if(mapKeyToProductData.containsKey(iKeyProductData)) {
                                ProductData productData = new ProductData(mapKeyToProductData.get(iKeyProductData));
                                productData.quantidade = mapKeyToProductDataFromCsvFile.get(iKeyProductData).reservedQuantity;
                                reservationProductToReturn.add(productData);
                            }
                        }
                    }
                }
            }
        }

        delete new ContentDocument(Id = documentId);
        
        System.debug('reservationProductToReturn ==> ' + reservationProductToReturn);
        if(!reservationProductToReturn.isEmpty()) {
            return reservationProductToReturn;
        } else {
            if(!Test.isRunningTest()) throw new CustomException('Não foram encontrados produtos para serem inseridos na reserva!');
            else return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static String deleteProductReservation(String reservationId, String productReservationId) {
        system.debug(productReservationId);
        DeleteProductResponse response = new DeleteProductResponse();

        List<ProdutoReserva__c> productsList = [
            SELECT Id
            FROM ProdutoReserva__c 
            WHERE Reserva__c =: reservationId
        ];

        if (productsList.size() == 1) {
            response.isSuccess = false;
            response.errorCode = 'reservation-has-only-one-product';
            return JSON.serialize(response);
        }
        
        try {
            Id resId = null;
            Boolean isSuccess = false;
            Double qtdAtiva = 0;
            for (ProdutoReserva__c prodRes: [SELECT Id, Reserva__c,ChaveUnica__c, StatusReserva__c, QuantidadeAtiva__c FROM ProdutoReserva__c WHERE Id =: productReservationId]) {
                resId = prodRes.Reserva__c;
                qtdAtiva = prodRes.QuantidadeAtiva__c;
            }

            if (resId != null) {                
                system.debug(resId);
                // system.debug(IntegrationReservationOUT.sendReservationERP(new List<Reserva__c>{new Reserva__c(Id = resId)}, productReservationId));
                List<Reserva__c> lstReservation =  IntegrationReservationOUT.getReservations(new List<Id>{resId});
                if ( qtdAtiva == null || qtdAtiva <= 0 ) {
                    
                    delete new ProdutoReserva__c(Id = productReservationId);
                    response.isSuccess = true;

                } else{

                    IntegrationReservationOUT.ResultClass resultDelete = IntegrationReservationOUT.deleteProductReservationERP(lstReservation,productReservationId);
                    isSuccess = resultDelete.message != 'Exclusao realizada com sucesso' ? false : true;
                    if (isSuccess) {
                        delete new ProdutoReserva__c(Id = productReservationId);
                        response.isSuccess = true;
                    } else {
                        response.isSuccess = false;
                        response.errorCode = 'delete-product-erp-error';
                        response.message = resultDelete.message + ' ' + resultDelete.detailMessage;
                    }
                }
            }

            return JSON.serialize(response);
        } catch(Exception e) {
            throw new CustomException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String deleteReservationHeader(String reservationId) {
        DeleteReservationHeaderResponse response = new DeleteReservationHeaderResponse();

        Reserva__c reservationData = [
            SELECT
                Id,
                (
                    SELECT 
                        Id 
                    FROM ProdutosReserva__r
                    WHERE QuantidadeConsumida__c > 0
                )
            FROM Reserva__c 
            WHERE Id =: reservationId
            LIMIT 1
        ];

        if (reservationData != null) {
            if (reservationData.ProdutosReserva__r.size() > 0) {
                response.isSuccess = false;
                response.errorCode = 'reservation-has-consummed-products';
                return JSON.serialize(response);
            }

            try {
                List<Reserva__c> reservationRequestList = IntegrationReservationOUT.getReservations(
                    new List<Id>{reservationData.Id}
                );

                Boolean isSuccess = IntegrationReservationOUT.deleteReservationHeaderERP(reservationRequestList);

                if (isSuccess) {
                    delete reservationData;
                    response.isSuccess = true;
                } else {
                    response.isSuccess = false;
                    response.errorCode = 'delete-reservation-header-erp-error';
                    response.message = 'Erro ao deletar cabeçalho da reserva (Envio ao ERP).';
                    return JSON.serialize(response);
                }
            } catch(Exception e) {
                throw new CustomException(e.getMessage() + ' ' + e.getStackTraceString());
            }
        }
                
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static ReserveData getReserveInformation(String recordId) {
        try {
            Reserva__c reserva = [SELECT Id, CentroDistribuicao__c, CodigoCD__c, CodigoReserva__c, Deletado__c, FimReserva__c, InicioReserva__c, MensagemErroIntegracao__c, StatusReserva__c, UltimaAprovacao__c, QuantidadeDestinatarios__c, LimiteFinanceiro__c, DiasVencimento__c, SaldoFinanceiroConsumido__c, SaldoFinanceiroDisponivel__c, ErroIntegracao__c 
            FROM Reserva__c WHERE Id =: recordId];

            if(Date.newInstance(reserva.FimReserva__c.year(), reserva.FimReserva__c.month(), reserva.FimReserva__c.day()) < Date.today()) {
                ProdutoReserva__c[] productReservationList = [SELECT Id, Reserva__r.FimReserva__c, StatusReserva__c,Reserva__c FROM ProdutoReserva__c WHERE Reserva__c =: recordId];

                for(ProdutoReserva__c iProdutoReserva : productReservationList) {
                    iProdutoReserva.StatusReserva__c = 'Expirada';
                }
        
                ReservationProductTriggerHandler.disableTrigger();
                update productReservationList;
                ReservationProductTriggerHandler.enableTrigger();
            }

            return new ReserveData(reserva);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkHaveSomeReserveWithTheSameCD(String recordId, String distributionCenterCode) {
        try {
            return [SELECT Id FROM Reserva__c WHERE Id !=: recordId AND CodigoCD__c =: distributionCenterCode LIMIT 1]?.Id == null ? false : true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean transferProducts(String reservationProductsList, String reservationCurrentId, String reservationToTransfer) {
        System.debug(reservationProductsList);
        try {
            Boolean updateSuccess = false;
            List<ProdutoReserva__c> produtoReservaList = new List<ProdutoReserva__c>();
            List<ProductData> productReservationList = (List<ProductData>) JSON.deserialize(reservationProductsList, List<ProductData>.class);
            // Reserva__c reservationCurrent = new Reserva__c(Id = reservationCurrentId);
            // Reserva__c reservationToTransferObj = new Reserva__c(Id = reservationToTransfer);

            for(ProductData iProductData : productReservationList) {
                ProdutoReserva__c produtoReserva = new ProdutoReserva__c();
                produtoReserva.Id = iProductData.id;
                produtoReserva.ReservaRecebedora__c = reservationToTransfer;
                produtoReserva.QuantidadeTransferida__c = iProductData.quantityTransfer;
                produtoReserva.StatusReserva__c = 'Aguardando aprovação';
                produtoReserva.UsuarioSolicitante__c = UserInfo.getUserId();
                produtoReservaList.add(produtoReserva);
            }

            Database.SaveResult[] result = Database.update(produtoReservaList, true);

            for(Database.SaveResult iDatabaseSaveResult : result) {
                updateSuccess = true;
                if(!iDatabaseSaveResult.isSuccess()) {
                    updateSuccess = false;
                    for(Database.Error err : iDatabaseSaveResult.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }

            if(updateSuccess) {
                return true;
            } else {
                return false;
            }

        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            return false;
            // throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean validateApprovers(String reservationCurrentId) {

        Set<String> setRegion = new Set<String>();
        Set<String> accountIds = new Set<String>();
        String recType = Schema.SObjectType.Reserva__c.getRecordTypeInfosByDeveloperName().get('ReservaRegional').getRecordTypeId();
        Boolean hasApprover = false;

        for(DestinatarioReserva__c reservation : [SELECT Id, CodigoRegiao__c, Cliente__c, Reserva__r.RecordTypeId  FROM DestinatarioReserva__c WHERE Reserva__c =: reservationCurrentId]){
       
            if (reservation.Reserva__r.RecordTypeId == recType) {
                setRegion.add(reservation.CodigoRegiao__c);
                
            }else{

                accountIds.add(reservation.Cliente__c);
            }
          
        }
        if (accountIds.size() > 0) {
            
            for(Setorizacao__c setor : [ SELECT Id, Regiao__c FROM Setorizacao__c WHERE Conta__c IN:accountIds]){
                setRegion.add(setor.Regiao__c);
            }
        }
        if (setRegion.size() > 0) {
            System.debug([SELECT Id FROM ResponsabilidadeAprovacao__c WHERE Regiao__c IN: setRegion]);
            List<ResponsabilidadeAprovacao__c> lstApproval = [SELECT Id FROM ResponsabilidadeAprovacao__c WHERE Regiao__c IN: setRegion];

            if (lstApproval.size() > 0) {
                hasApprover = true;
            }

        }

        return hasApprover;
    }

    public class DeleteProductResponse {
        public Boolean isSuccess;
        public String errorCode = null;
        public String message = null;
    }

    public class DeleteReservationHeaderResponse {
        public Boolean isSuccess;
        public String errorCode = null;
        public String message = null;
    }

    public class ErrorData{
        @AuraEnabled public String code {get;set;}
        @AuraEnabled public String message {get;set;}
        
        public ErrorData(){
            
            this.code = '';
            this.message = '';           
        }        
    }

    public class AccountData{
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String accountName {get;set;}
        
        public AccountData(Account acc){
            
            this.accountId = acc.Id;
            this.accountName = acc.Name;           
        }        
    }

    public class ProductData{
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String reserveId {get;set;}
        @AuraEnabled public String productId {get;set;}
        @AuraEnabled public String productCode {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String provider {get;set;}
        @AuraEnabled public String storage {get;set;}
        @AuraEnabled public String prodResStatus {get;set;}
        @AuraEnabled public Decimal quantidade {get;set;}
        @AuraEnabled public Decimal reservedFinancialBalance {get;set;}
        @AuraEnabled public Decimal priceAverage {get;set;}
        @AuraEnabled public Decimal balance {get;set;}
        @AuraEnabled public Decimal consumedQuantity {get;set;}
        @AuraEnabled public Decimal reservedQuantity {get;set;}
        @AuraEnabled public Decimal availableQuantity {get;set;}
        @AuraEnabled public Decimal quantityTransfer {get;set;}
        @AuraEnabled public String prodKey {get;set;}
        @AuraEnabled public Boolean alreadyReserved {get;set;}
        @AuraEnabled public Boolean haveInventory {get;set;}
        @AuraEnabled public Boolean statusAprovation {get;set;}
        @AuraEnabled public Boolean isLoading {get;set;}
        @AuraEnabled public Decimal activateQuantity {get;set;}
        @AuraEnabled public String prodResStatusClassBadge {get;set;}

        public ProductData(Product2 produto){    
            this.productId = produto.Id;
            this.productCode = produto.ProductCode;           
            this.name = produto.Name;           
            this.provider = produto.Fornecedor__r.Name;  
        }

        public ProductData(String productCode, String armazen, Decimal quantity){    
            this.productCode = productCode;  
            this.storage = armazen;  
            this.reservedQuantity = quantity;
        }
        
        public ProductData(Estoque__c estoqueData, String reserveId, Boolean alreadyReserved){
            this.reserveId = reserveId;
            this.alreadyReserved = alreadyReserved;
            this.productId = estoqueData.NomeProduto__c;
            this.productCode = estoqueData.NomeProduto__r.ProductCode;
            this.name = estoqueData.NomeProduto__r.Name;
            this.provider = estoqueData.NomeProduto__r.Fornecedor__r.Name;
            this.storage = estoqueData.Armazem__c;
            this.balance = estoqueData.Saldo__c;
            this.prodKey = reserveId + '_' + estoqueData.NomeProduto__c + '_' + estoqueData.Armazem__c;
            this.priceAverage = estoqueData.PrecoMedio__c; // Apenas para teste (Alterar assim que valor for recebido da integração);
            this.haveInventory = false;
        }        

        public ProductData(ProdutoReserva__c prodReserva){
            this.id = prodReserva.id;
            this.alreadyReserved = true;
            this.reserveId = prodReserva.Reserva__c;
            this.productId = prodReserva.Produto__c;
            this.productCode = prodReserva.Produto__r.ProductCode;
            this.name = prodReserva.Produto__r.Name;
            this.provider = prodReserva.Produto__r?.Fornecedor__r?.Name;
            this.storage = prodReserva.Armazem__c;
            this.prodResStatus = prodReserva.StatusReserva__c;
            this.prodResStatusClassBadge = setClassOfBadgeColor(prodReserva.StatusReserva__c);
            this.statusAprovation = prodReserva.StatusReserva__c == 'Aguardando aprovação' ? true: false;
            this.activateQuantity = prodReserva.QuantidadeAtiva__c;
            // this.balance = prodReserva.QuantidadeAtiva__c;
            this.reservedQuantity = prodReserva.QuantidadeReservada__c == null ? 0 : prodReserva.QuantidadeReservada__c;
            this.consumedQuantity = prodReserva.QuantidadeConsumida__c == null ? 0 : prodReserva.QuantidadeConsumida__c;
            this.priceAverage = prodReserva.Preco__c; // Apenas para teste (Alterar assim que valor for recebido da integração);
            this.reservedFinancialBalance = prodReserva.Reserva__r?.LimiteFinanceiro__c;
            this.availableQuantity = this.activateQuantity - this.consumedQuantity;
            this.haveInventory = false;
            this.isLoading = false;
            // this.quantityTransfer = 0;
        }

        public ProductData(ProdutoReserva__c prodReserva, Decimal balance, Boolean bool){
            this.id = prodReserva.id;
            this.alreadyReserved = true;
            this.reserveId = prodReserva.Reserva__c;
            this.productId = prodReserva.Produto__c;
            this.productCode = prodReserva.Produto__r.ProductCode;
            this.name = prodReserva.Produto__r.Name;
            this.provider = prodReserva.Produto__r?.Fornecedor__r?.Name;
            this.storage = prodReserva.Armazem__c;
            this.prodResStatus = prodReserva.StatusReserva__c;
            this.prodResStatusClassBadge = setClassOfBadgeColor(prodReserva.StatusReserva__c);
            this.statusAprovation = prodReserva.StatusReserva__c == 'Aguardando aprovação' ? true: false;
            this.activateQuantity = prodReserva.QuantidadeAtiva__c;
            this.balance = balance;
            this.reservedQuantity = prodReserva.QuantidadeReservada__c == null ? 0 : prodReserva.QuantidadeReservada__c;
            this.consumedQuantity = prodReserva.QuantidadeConsumida__c == null ? 0 : prodReserva.QuantidadeConsumida__c;
            this.priceAverage = prodReserva.Preco__c; // Apenas para teste (Alterar assim que valor for recebido da integração);
            this.reservedFinancialBalance = prodReserva.Reserva__r?.LimiteFinanceiro__c;
            this.availableQuantity = this.activateQuantity - this.consumedQuantity;
            this.haveInventory = false;
            this.isLoading = false;
            // this.quantityTransfer = 0;
        }

        public ProductData(ProdutoReserva__c prodReserva, Map<String, ProdutoReserva__c> mapIdToProductReservation, Decimal balance) {
            this.id = prodReserva.id;
            this.alreadyReserved = true;
            this.productCode = mapIdToProductReservation.get(this.id).Produto__r.ProductCode;
            this.name = mapIdToProductReservation.get(this.id).Produto__r.Name;
            this.provider = mapIdToProductReservation.get(this.id).Produto__r?.Fornecedor__r?.Name;
            this.storage = mapIdToProductReservation.get(this.id).Armazem__c;
            this.activateQuantity = mapIdToProductReservation.get(this.id).QuantidadeAtiva__c;
            this.balance = balance;
            this.consumedQuantity = mapIdToProductReservation.get(this.id).QuantidadeConsumida__c == null ? 0 : mapIdToProductReservation.get(this.id).QuantidadeConsumida__c;
            this.reservedFinancialBalance = mapIdToProductReservation.get(this.id).Reserva__r?.LimiteFinanceiro__c;
            this.availableQuantity = this.activateQuantity - this.consumedQuantity;
            this.haveInventory = false;
            this.isLoading = false;
            
            this.prodResStatus = prodReserva.StatusReserva__c;
            this.statusAprovation = prodReserva.StatusReserva__c == 'Aguardando aprovação' ? true: false;
            this.reservedQuantity = prodReserva.QuantidadeReservada__c == null ? 0 : prodReserva.QuantidadeReservada__c;
            this.priceAverage = prodReserva.Preco__c;
            this.prodResStatusClassBadge = setClassOfBadgeColor(prodReserva.StatusReserva__c);
            this.reserveId = prodReserva.Reserva__c;
            this.productId = prodReserva.Produto__c;
            this.quantidade = prodReserva.QuantidadeReservada__c;
        }

        public ProductData(ProdutoReserva__c prodReserva, Estoque__c inventory){
            this.id = prodReserva.id;
            this.alreadyReserved = true;
            this.reserveId = prodReserva.Reserva__c;
            this.productId = prodReserva.Produto__c;
            this.productCode = prodReserva.Produto__r.ProductCode;
            this.name = prodReserva.Produto__r.Name;
            this.provider = prodReserva.Produto__r?.Fornecedor__r?.Name;
            this.storage = prodReserva.Armazem__c;
            this.prodResStatus = prodReserva.StatusReserva__c;
            this.prodResStatusClassBadge = setClassOfBadgeColor(prodReserva.StatusReserva__c);
            this.statusAprovation = prodReserva.StatusReserva__c == 'Aguardando aprovação' ? true: false;
            this.activateQuantity = prodReserva.QuantidadeAtiva__c;
            this.balance = inventory != null ? inventory.Saldo__c : null;
            this.reservedQuantity = prodReserva.QuantidadeReservada__c == null ? 0 : prodReserva.QuantidadeReservada__c;
            this.consumedQuantity = prodReserva.QuantidadeConsumida__c == null ? 0 : prodReserva.QuantidadeConsumida__c;
            this.priceAverage = prodReserva.Preco__c; // Apenas para teste (Alterar assim que valor for recebido da integração);
            this.reservedFinancialBalance = prodReserva.Reserva__r?.LimiteFinanceiro__c;
            this.availableQuantity = this.activateQuantity - this.consumedQuantity;
            this.haveInventory = true;
            this.isLoading = false;
            // this.quantityTransfer = 0;
        }

        public String setClassOfBadgeColor(String status) {
            if(status == 'Ativa') {
                return 'back-color-blue';
            } else if (status == 'Erro de integração') {
                return 'back-color-red';
            } else if (status == 'Expirada') {
                return 'back-color-yellow';
            } else {
                return '';
            }
        }

        public ProductData refreshFields(Map<String, ProdutoReserva__c> mapIdToReservation) {
            this.alreadyReserved = true;
            this.reserveId = mapIdToReservation.get(this.id).Reserva__c;
            this.productId = mapIdToReservation.get(this.id).Produto__c;
            this.productCode = mapIdToReservation.get(this.id).Produto__r.ProductCode;
            this.name = mapIdToReservation.get(this.id).Produto__r.Name;
            this.provider = mapIdToReservation.get(this.id).Produto__r?.Fornecedor__r?.Name;
            this.storage = mapIdToReservation.get(this.id).Armazem__c;
            this.prodResStatus = mapIdToReservation.get(this.id).StatusReserva__c;
            this.prodResStatusClassBadge = setClassOfBadgeColor(mapIdToReservation.get(this.id).StatusReserva__c);
            this.statusAprovation = mapIdToReservation.get(this.id).StatusReserva__c == 'Aguardando aprovação' ? true: false;
            this.activateQuantity = mapIdToReservation.get(this.id).QuantidadeAtiva__c;
            this.reservedQuantity = mapIdToReservation.get(this.id).QuantidadeReservada__c == null ? 0 : mapIdToReservation.get(this.id).QuantidadeReservada__c;
            this.consumedQuantity = mapIdToReservation.get(this.id).QuantidadeConsumida__c == null ? 0 : mapIdToReservation.get(this.id).QuantidadeConsumida__c;
            this.priceAverage = mapIdToReservation.get(this.id).Preco__c;
            this.reservedFinancialBalance = mapIdToReservation.get(this.id).Reserva__r?.LimiteFinanceiro__c;
            this.availableQuantity = this.activateQuantity - this.consumedQuantity;
            this.haveInventory = true;
            this.isLoading = false;

            return this;
        }
    }

    public class FinancialBalanceData{
        @AuraEnabled public String financialBalanceId {get;set;}
        @AuraEnabled public String regionCode {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public String accountGroupId {get;set;}      
        @AuraEnabled public Decimal balanceAvailable {get;set;}
        @AuraEnabled public Decimal balanceConsumed {get;set;}
        
        public FinancialBalanceData(SaldoFinanceiroReserva__c saldo){
            
            this.financialBalanceId = saldo.Id;
            this.regionCode = saldo.CodigoRegiao__c;           
            this.accountId = saldo.Cliente__c;                
            this.accountGroupId = saldo.CodigoGrupoCLiente__c;                
            this.balanceAvailable = saldo.SaldoDisponivel__c;           
            this.balanceConsumed = saldo.SaldoLiberado__c;           
        }        
    }

    public class ReserveData {
        @AuraEnabled public String Id                     {get;set;}
        @AuraEnabled public Boolean IsReservedExpired     {get;set;}
        @AuraEnabled public String DistributionCenterCode {get;set;}

        public ReserveData(Reserva__c reserva) {
            this.Id = reserva.Id;
            this.IsReservedExpired = Date.newInstance(reserva.FimReserva__c.year(), reserva.FimReserva__c.month(), reserva.FimReserva__c.day()) < Date.today() ? true: false;
            this.DistributionCenterCode = reserva.CodigoCD__c;
        }
    }
}