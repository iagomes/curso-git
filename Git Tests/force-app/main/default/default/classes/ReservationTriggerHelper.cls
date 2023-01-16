public with sharing class ReservationTriggerHelper {

    public ReservationTriggerHelper() {}

    public static void updateCodigoReserva(Map<Id, Reserva__c> newMap){

        List<Id> lstReservationId = new List<Id>();

        for (Reserva__c reservation : newMap.values()) {
            
            lstReservationId.add(reservation.Id);
        }

        IntegrationReservationOUT.asyncSendToProtheus(lstReservationId);
    }

    public static void updateDeliveryCenterName(List<Reserva__c> newList) {
        List<ListaCentroDistribuicao__c> deliveryCenters = ListaCentroDistribuicao__c.getAll().values();
        
        for (Reserva__c reservation : newList) {
            for (ListaCentroDistribuicao__c deliveryCenter : deliveryCenters) {
    
                if (reservation.CodigoCD__c == deliveryCenter.CodigoCD__c) {
                    reservation.CentroDistribuicao__c = deliveryCenter.NomeCD__c;
                    break;
                }
            }
        }
    }
}
