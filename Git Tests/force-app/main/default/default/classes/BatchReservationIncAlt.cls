global class BatchReservationIncAlt implements Database.batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    public IntegrationReservationOUT.ResultClass response;
    public List<Reserva__c> reservationList;

    global BatchReservationIncAlt() {}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // return Database.getQueryLocator([SELECT Id, CodigoReserva__c, FimReserva__c, CentroDistribuicao__c, MensagemErroIntegracao__c, StatusReserva__c FROM Reserva__c WHERE StatusReserva__c = :IntegrationConstants.STATUS_INTEGRATION_ERROR ORDER BY FimReserva__c DESC]);
        return Database.getQueryLocator([SELECT Id, Reserva__c FROM ProdutoReserva__c WHERE StatusReserva__c ='Erro de integração' ORDER BY Reserva__r.FimReserva__c DESC]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {        
        List<ProdutoReserva__c> lstProdutoReserva  = (List<ProdutoReserva__c>) scope;
        List<Id> reservas = new List<Id>();

        for (ProdutoReserva__c pd : lstProdutoReserva) {
            
            reservas.add(pd.Reserva__c);
        }

        if (reservas.size() > 0) {
            reservationList = IntegrationReservationOUT.getReservations(reservas);
            response = IntegrationReservationOUT.sendReservationERP(reservationList, true);

        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            IntegrationReservationOUT.updateReservationInt(reservationList,response);            
        }
	}
}