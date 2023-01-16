public with sharing class CreateReservationFormController {
    
    @AuraEnabled(cacheable=true)
    public static List<DefaultOptions> getDeliveryCenters() {
        List<DefaultOptions> options = new List<DefaultOptions>();
        List<ListaCentroDistribuicao__c> deliveryCenters = ListaCentroDistribuicao__c.getAll().values();

        for (ListaCentroDistribuicao__c deliveryCenter : deliveryCenters) {
            DefaultOptions newOption = new DefaultOptions();
            newOption.label = deliveryCenter.CodigoCD__c + ' - ' +deliveryCenter.NomeCD__c;
            newOption.value = deliveryCenter.CodigoCD__c;

            options.add(newOption);
        }

        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<DefaultOptions> getRecordTypeOptions() {
        List<DefaultOptions> options = new List<DefaultOptions>();

        Map<Id, Schema.RecordTypeInfo> mapRecordTypesInfos = Schema.SObjectType.Reserva__c.getRecordTypeInfosById();

        for (RecordTypeInfo recordTypeInfo : mapRecordTypesInfos.values()) {
            if (!recordTypeInfo.isMaster()) {
                DefaultOptions newOption = new DefaultOptions();
                newOption.label = recordTypeInfo.getName();
                newOption.value = recordTypeInfo.getRecordTypeId();

                options.add(newOption);
            }
        }

        return options;
    }

    public class DefaultOptions {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}