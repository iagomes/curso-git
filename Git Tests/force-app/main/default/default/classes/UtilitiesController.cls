global without sharing class UtilitiesController {
    
    @AuraEnabled(cacheable=true)
    global static List<Map<String, String>> getPickListValuesList(String fieldAndObjectApiName){
        System.debug('fieldAndObjectApiName:::' + fieldAndObjectApiName);
        String[] apiNames = fieldAndObjectApiName.split('\\.');
        System.debug('apiNames:::' + apiNames);
        return SObjectUtils.getPickListValuesList(apiNames[0], apiNames[1]);
    }
    
    @AuraEnabled
    global static String getLookupRecords(String searchText, String objectName, String[] fieldNames, String[] lookupSelectFields, String complexSearchField){
        StandardResponse resp = new StandardResponse();
        try{
            resp.setData(getLookupRecordList(searchText, objectName, fieldNames, lookupSelectFields, complexSearchField, null));
        }catch(Exception ex){
            ExceptionUtils.debug(ex);
            resp.addError('Falha na busca de produtos: ' + ex.getMessage());
        }
        return JSON.serialize(resp);
    }
    
    public static List<SObject> getLookupRecordList(String searchText, String objectName, String[] fieldNames, String[] lookupSelectFields, String complexSearchField, QueryBuilder.ComplexCondition complexConditions){
        if(complexConditions == null){
            complexConditions = new QueryBuilder.ComplexCondition();
        }
        List<SObject> resultQ = new List<SObject>();
        StandardResponse resp = new StandardResponse();
        System.debug('lookupSelectFields:::' + lookupSelectFields);
        QueryBuilder qBuilder = new QueryBuilder(objectName)
            .addFields(lookupSelectFields)
            .addConditions()
            .add(
                new QueryBuilder.ComplexCondition()
                .andCondition(
                    buildDynamicConditions(searchText, objectName, fieldNames)        
                )
                .andCondition(complexConditions)
            )
            .endConditions()
            .setWithSecurityEnforced();
            //pesquisará o primeiro registro e pesquisará novamente adicionando a essa busca o resultado do campo complexSearchField. 
        if(complexSearchField != null && complexSearchField != ''){
            qBuilder.setLimit(1);
            List<SObject> firstQ = qBuilder.toList();
            if(!firstQ.isEmpty()){

                String fieldComplexValue = '';
                List<String> complexParent = complexSearchField.split('\\.');
                if(complexParent.size() > 1){
                    SObject getterObject = firstQ[0].getSobject(complexParent[0]);
                    for(Integer i = 1; i< complexParent.size()-1; i++){
                        getterObject = getterObject.getSobject(complexParent[i]);
                    }
                    fieldComplexValue = String.valueOf(getterObject.get(complexParent[complexParent.size()-1]));
                }
                else{
                    fieldComplexValue = String.valueOf(firstQ[0].get(complexSearchField));
                }
                if(fieldComplexValue != null) fieldComplexValue.replaceAll('\\s|\\n|-|\\.', '%');
                QueryBuilder qBuilderComplex = new QueryBuilder(objectName)
                    .addFields(lookupSelectFields)
                    .addConditions()
                    .add(
                        new QueryBuilder.ComplexCondition()
                        .andCondition(
                            new QueryBuilder.ComplexCondition()
                            .orCondition(buildDynamicConditions(searchText, objectName, fieldNames)) 
                            .orCondition(buildDynamicConditions(fieldComplexValue, objectName, new List<String>{complexSearchField}))
                        )
                        .andCondition(complexConditions)
                    )
                    .endConditions()
                    .setWithSecurityEnforced();

                    resultQ = qBuilderComplex.toList();
            }else{
                qBuilder.setLimit(0);
                resultQ = qBuilder.toList();
            }
        }else{
            resultQ = qBuilder.toList();
        }

        return resultQ;
    }

    private static QueryBuilder.ComplexCondition buildDynamicConditions(String searchText, String objectName, String[] fieldNames){
        QueryBuilder.ComplexCondition conditions = new QueryBuilder.ComplexCondition();
        DescribeSObjectResult objectDesc = ((SObject)(Type.forName('Schema.' + objectName).newInstance())).getSObjectType().getDescribe();
        System.debug('fieldNames:::' + fieldNames);
        Map<String,String> mapFieldTypes = new Map<String,String>();
        for(String fieldName: fieldNames){
            fieldName = fieldName.toLowerCase();
            
            List<String> splitedField = fieldName.split('\\.');
            if(splitedField.size() > 1){
                if(splitedField[splitedField.size()-2].right(3) == '__r'){
                    String parentObjectName = splitedField[splitedField.size()-2];
                    splitedField[splitedField.size()-2] = parentObjectName.substring(0, parentObjectName.length()-3) + '__c';
                }    
            }

            System.debug('fieldName:::' + fieldName);
            System.debug('objectDesc.fields.getMap():::' + objectDesc.fields.getMap());
            System.debug('objectDesc.fields.getMap().keys:::' + JSON.serializePretty(objectDesc.fields.getMap().keySet()));

            String fieldType = '';
            if(splitedField.size() > 1){
                DescribeSObjectResult parentObjectDesc = ((SObject)(Type.forName('Schema.' + splitedField[splitedField.size()-2]).newInstance())).getSObjectType().getDescribe();
                System.debug('objectDesc.fields.getMap().get('+ splitedField[splitedField.size()-1] +').getDescribe().getType():::' + parentObjectDesc.fields.getMap().get(splitedField[splitedField.size()-1]).getDescribe().getType());
                fieldType = String.valueOf(parentObjectDesc.fields.getMap().get(splitedField[splitedField.size()-1]).getDescribe().getType()).toUpperCase();
            }
            else{
                System.debug('objectDesc.fields.getMap().get('+ fieldName +').getDescribe().getType():::' + objectDesc.fields.getMap().get(fieldName).getDescribe().getType());
                fieldType = String.valueOf(objectDesc.fields.getMap().get(fieldName).getDescribe().getType()).toUpperCase();
            }

            System.debug('fieldName:::' + fieldName + ' fieldType:::' + fieldType);
            
            if(fieldType == 'PHONE' || fieldType == 'EMAIL' || fieldType == 'URL') {
                fieldType = 'STRING';
            }

            if(fieldType == 'REFERENCE'){
                fieldType = 'ID';
            }

            mapFieldTypes.put(
                fieldName, 
                fieldType
            );
            System.debug('mapFieldTypes:::' + JSON.serializePretty(mapFieldTypes));
        }

        for(String fieldName: fieldNames){
            fieldName = fieldName.toLowerCase();
            System.debug('fieldName:::' + fieldName + 'fieldType:::' + mapFieldTypes.get(fieldName));
            switch on mapFieldTypes.get(fieldName) {
                when 'STRING' {
                    conditions.orCondition(
                        new QueryBuilder.LikeCondition(fieldName).ignoreConditionsForNullValues().likeAnyBoth(searchText)
                    );
                }
                when 'ID' {
                    if(searchText.length() == 15 || searchText.length() == 18){
                        try{
                            Id recordId = searchText;
                            conditions.orCondition(
                                new QueryBuilder.CompareCondition(fieldName).ignoreConditionsForNullValues().eq(recordId)
                            );
                        }catch(Exception ex){}
                    }
                }
                when else {
                    conditions.orCondition(
                        new QueryBuilder.CompareCondition(fieldName).ignoreConditionsForNullValues().eq(searchText)
                    );
                }
            }
        }
        return conditions;
    }
    
    @AuraEnabled
    public static StandardResponse getRecordTypeByName(String name, String objectApiName){

        StandardResponse response = new StandardResponse();

        try {

            if(String.isNotEmpty(name)) {
                response.setData('record', Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByName().get(name).getRecordTypeId());
                
            } else {
                response.addError('Não foi possível encontrar o tipo de registro, por favor, entre em contato com o Administrador.');
            }
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
            response.addError('Não foi possível encontrar o tipo de registro, por favor, entre em contato com o Administrador. ');
            response.addError(ex.getMessage());
        }
        return response;
    }
}