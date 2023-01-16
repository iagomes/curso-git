public with sharing class ContractUploadController {
    @AuraEnabled
    public static string getTemplate(){
        String csv = '';
        for (Configuration_Contract_Temp__mdt config : getDataFields()) {
            csv += '"' + config.MasterLabel + '"' + ';';
        }
        return csv.removeEnd(';');
    }

    @AuraEnabled
    public static List<Configuration_Contract_Temp__mdt> getDataFields(){
        return ContractUploadService.getDataFields();
    }

    @AuraEnabled
    public static Map<String,Object> insertContract(Map<String,Object> dataMap){
        try {
            dataMap = ContractUploadService.processContract(dataMap);
        } catch (Exception ex) {
            dataMap = dataMap == null ? new Map<String,Object>() : dataMap ;
            dataMap.put(ContractUploadConstants.IS_SUCCESS,false);
            dataMap.put(ContractUploadConstants.MESSAGE,ex.getMessage());
        }finally{
            //
        }
        return dataMap;
    }
}
