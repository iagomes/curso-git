global class BatchSendNotificationReservation implements Database.Batchable<sObject>, Database.Stateful{

    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug('entrou no batch');
        return Database.getQueryLocator(
                                            [
                                                SELECT Id, Name,DiasVencimentoUltimaMovimentacao__c, DiasVencimento__c, (SELECT Id, CreatedById FROM ProdutosReserva__r ) 
                                                FROM Reserva__c 
                                                WHERE (DiasVencimento__c = 7 OR DiasVencimentoUltimaMovimentacao__c = 52) 
                                                AND StatusReserva__c != 'Expirada'
                                            ]
                                        );
    }

    global void execute(Database.BatchableContext BC, List<Reserva__c> scope) {

        System.debug(scope);
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'NotificationPendingOrder'];
        Set<String> recipientsIds = new Set<String>();
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        List<Reserva__c> lstUpdateVencido = new List<Reserva__c>();
        
        for (Reserva__c reserva : scope) {

            if (reserva.ProdutosReserva__r.size() > 0 ) {
                
                for (ProdutoReserva__c produtoReserva : reserva.ProdutosReserva__r) {

                    if (!recipientsIds.contains(produtoReserva.CreatedById)) {

                        try {

                            if (reserva.DiasVencimento__c == 7 || reserva.DiasVencimentoUltimaMovimentacao__c == 52) {
            
                                notification = new Messaging.CustomNotification();
            
                                notification.setTitle('Vencimento da reserva!');
                                notification.setBody('Reserva '+reserva.Name+ ' está próxima do vencimento!');
                    
                                notification.setNotificationTypeId(notificationType.Id);
                                notification.setTargetId(reserva.Id);
                    
                                recipientsIds.add(produtoReserva.CreatedById);
                                System.debug(recipientsIds);
                                notification.send(recipientsIds);
            
                            } 

                        } catch (Exception e) {
                            System.debug(e.getMessage());
                        }                        
                    }                    
                }
            }           
        }        
    }

    global void finish(Database.BatchableContext BC) {}
}
