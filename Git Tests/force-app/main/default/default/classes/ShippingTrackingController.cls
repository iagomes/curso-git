public without sharing class ShippingTrackingController {
    
    @AuraEnabled(cacheable=true)
    public static List<StatusData> getDeliveryHistory(String recordId) {
        List<OrderHistory> orderHistoryList = [
            SELECT 
                OrderId,
                Order.DescricaoStatusEntrega__c, 
                NewValue, 
                OldValue, 
                CreatedDate 
            FROM OrderHistory 
            WHERE Field = 'StatusEntrega__c' 
            AND OrderId = :recordId
            ORDER BY CreatedDate DESC
        ];
        
        List<StatusData> statusDataList = new List<StatusData>();

        for (OrderHistory oh : orderHistoryList) {
            StatusData newStatusData = new StatusData();
            newStatusData.label        = String.valueOf(oh.NewValue);
            newStatusData.description  = '';
            newStatusData.modifiedDate = oh.CreatedDate.format('HH:mm | dd/MM/YYYY');
            newStatusData.type         = getStatusType(String.valueOf(oh.NewValue));
            if (oh.NewValue != 'Link de rastreamento disponível') 
                statusDataList.add(newStatusData);
            System.debug(newStatusData);
        }
        if (!orderHistoryList.isEmpty()) {
            StatusData statusData = statusDataList.get(0);
            statusData.description = orderHistoryList[0].Order.DescricaoStatusEntrega__c;
        }
        System.debug(statusDataList);
        return statusDataList;
    }

    @AuraEnabled(cacheable=true)
    public static String getDeliveryURL(String recordId) {
        return [SELECT URLRastreio__c FROM Order WHERE Id = :recordId LIMIT 1].URLRastreio__c;
    }

    public class StatusData {
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String modifiedDate;
        @AuraEnabled public String type;
    }

    public static String getStatusType(String type) {
        Set<String> completedStatus = new Set<String>{'Entregue', 'Entregue SL'};
        Set<String> canceledStatus = new Set<String>{'Não entregue', 'Abortada', 'Não coletado', 'Sem rota', 'Devolvido', 'Cancelado'};
        if (completedStatus.contains(type)) {
            return 'completed';
        } else if (canceledStatus.contains(type)) {
            return 'error';
        } else {
            return 'onHold';
        }
    }
}
