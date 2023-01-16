public with sharing class ContractUploadService {

    public static Map<String,Object> processContract(Map<String,Object> dataMap){
        Boolean isSuccess = false;
        String message = '';
        if(dataMap.containsKey(ContractUploadConstants.JSON_STR) && String.isNotBlank((String)dataMap.get(ContractUploadConstants.JSON_STR)) && dataMap.containsKey(ContractUploadConstants.HEADER_LIST_STR) ){
            
            /*BatchContractUpload batch =  new BatchContractUpload(dataMap);
            Database.executeBatch(batch, 100);*/

            List<ItemContrato__c> contractToInsertList = new List<ItemContrato__c>();
            Set<String> productsName = new Set<String>();
            List<Configuration_Contract_Temp__mdt> configList = getDataFields();

            String jsonToUpload = (String)dataMap.get(ContractUploadConstants.JSON_STR);
            String jsonHeader = (String)dataMap.get(ContractUploadConstants.HEADER_LIST_STR);
            List<Configuration_Contract_Temp__mdt> headerList = (List<Configuration_Contract_Temp__mdt>) JSON.deserialize(jsonHeader, List<Configuration_Contract_Temp__mdt>.class);
            for(Configuration_Contract_Temp__mdt key: headerList){
                for(Configuration_Contract_Temp__mdt config : configList){
                    jsonToUpload = jsonToUpload.replace('"'+config.MasterLabel+'"','"'+key.Field_Name_SF__c+'"');
                }
            }
            contractToInsertList = (List<ItemContrato__c>) JSON.deserialize(jsonToUpload, List<ItemContrato__c>.class);
    
            Set<String> contractNumberList = new Set<String>();
            for(ItemContrato__c contract : contractToInsertList){
                contractNumberList.add(contract.NumeroContrato__c);
                productsName.add(contract.NomeProduto__c);
            }

            List<Contract> scope = Database.query('SELECT Id, ContractNumber FROM Contract WHERE ContractNumber IN :contractNumberList ');
            
            Map<String,Contract> contractMap = new Map<String,Contract>();
            for(Contract contract : scope){
                contractMap.put(contract.ContractNumber,contract);
            }
            List<ItemContrato__c> itensToInsertList = new List<ItemContrato__c>();
    
            Map<String,ItemContrato__c> contractItemMap = new Map<String,ItemContrato__c>();
            for(ItemContrato__c contract : [SELECT Id, NomeProduto__c, NumeroContrato__c, NumeroContrato__r.ContractNumber, NomeProduto__r.ProductCode FROM ItemContrato__c WHERE NumeroContrato__c IN :scope]){
                contractItemMap.put(contract.NomeProduto__r.ProductCode+contract.NumeroContrato__r.ContractNumber,contract);
            }
    
            Map<String,Product2> prodtct2Map = new Map<String,Product2>();
            for(Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :productsName]){
                prodtct2Map.put(product.ProductCode,product);
            }

            for(ItemContrato__c contract : contractToInsertList){
                if(contractMap.containsKey(contract.NumeroContrato__c)){
                    Contract contractObj = contractMap.get(contract.NumeroContrato__c);
                    String contractItemKey = contract.NomeProduto__c+contractObj.ContractNumber;
    
                    ItemContrato__c newContractLineItem;
                    if(contractItemMap.containsKey(contractItemKey)){
                        newContractLineItem = contractItemMap.get(contractItemKey);
                    }else{
                        Product2 product = prodtct2Map.get(contract.NomeProduto__c);
                        newContractLineItem = new ItemContrato__c();
                        newContractLineItem.NomeProduto__c = product.Id;
                        newContractLineItem.NumeroContrato__c = contractObj.Id;
                        newContractLineItem.Status__c = 'Rascunho';
                    }
                    newContractLineItem.PrecoMinimo__c = contract.PrecoMinimo__c;
                    newContractLineItem.PrecoUnitario__c = contract.PrecoUnitario__c;
                    newContractLineItem.Quantidade__c = contract.Quantidade__c;                
                    newContractLineItem.VigenciaFinal__c = contract.VigenciaFinal__c;
                    newContractLineItem.VigenciaInicial__c = contract.VigenciaInicial__c;
        
                    itensToInsertList.add(newContractLineItem);
                }
            }
            upsert itensToInsertList;

            dataMap.put(ContractUploadConstants.IS_SUCCESS,true);
            dataMap.put(ContractUploadConstants.MESSAGE,ContractUploadConstants.SUCCESS_MSG);
        }else{
            dataMap.put(ContractUploadConstants.IS_SUCCESS,false);
            dataMap.put(ContractUploadConstants.MESSAGE,ContractUploadConstants.INVALID_PARAMS_MSG);  
        }
        return dataMap;
    }

    public static List<Configuration_Contract_Temp__mdt> getDataFields(){
        return [SELECT Field_Name_CSV__c, Field_Name_SF__c, Data_Type__c, MasterLabel, OrderShow__c FROM Configuration_Contract_Temp__mdt ORDER BY OrderShow__c ASC];
    }
}
