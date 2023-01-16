public with sharing class ReservationRecipientTriggerHelper {

    public ReservationRecipientTriggerHelper() {}

    public static void getReservationRecordType(Map<Id, DestinatarioReserva__c> newMap){

        Set<String> setRecType = new Set<String>();
        Set<String> clientIdSet = new Set<String>();
        Map<String, Set<String>> clienteIdToRegiaoList = new Map<String, Set<String>>();

        for (DestinatarioReserva__c reservationRecipient : newMap.values()){
            
            setRecType.add(reservationRecipient.Reserva__c);
        }

        List<Reserva__c> listReservation = [SELECT id, RecordType.DeveloperName, RegioesSaldoFinanceiro__c FROM Reserva__c WHERE Id IN:setRecType];
        Map<String, String> mapReservationRecType = new Map<String, String>();   
        Map<String, Reserva__c> mapIdToReservation = new Map<String, Reserva__c>();   

        for (Reserva__c reserva : listReservation) {
            
            if (!mapReservationRecType.containsKey(reserva.Id)) {
                
                mapReservationRecType.put(reserva.Id, reserva.RecordType.DeveloperName);
            }
            mapIdToReservation.put(reserva.id, reserva);
        }

        for(DestinatarioReserva__c iDestinatarioReserva : newMap.values()) {
            clientIdSet.add(iDestinatarioReserva.Cliente__c);
        }

        for(Setorizacao__c iSetorizacao : [SELECT Regiao__c, Conta__c from Setorizacao__c WHERE Conta__c IN:clientIdSet]) {
            if(!clienteIdToRegiaoList.containsKey(iSetorizacao.Conta__c)) {
                clienteIdToRegiaoList.put(iSetorizacao.Conta__c, new Set<String>{iSetorizacao.Regiao__c});
            } else {
                clienteIdToRegiaoList.get(iSetorizacao.Conta__c).add(iSetorizacao.Regiao__c);
            }
        }

        validateReservationRecipient(newMap, mapReservationRecType, clienteIdToRegiaoList, mapIdToReservation);
        
    }

    public static void validateReservationRecipient(Map<Id, DestinatarioReserva__c> newMap, Map<String,String> mapReservationRecType, Map<String, Set<String>> clienteIdToRegiaoList, Map<String, Reserva__c> mapIdToReservation){

        Set<String> setProduct = new Set<String>();

        for (DestinatarioReserva__c reservationRecipient : newMap.values()){

            if (String.isBlank(reservationRecipient.Cliente__c) && String.isBlank(reservationRecipient.GrupoClientes__c ) && String.isBlank(reservationRecipient.CodigoRegiao__c)) {
                
                reservationRecipient.addError('Obrigatório preenchimento dos campos Cliente, Grupo de clientes ou Código da região');

            } else if (!String.isBlank(reservationRecipient.Cliente__c) && !String.isBlank(reservationRecipient.GrupoClientes__c ) && !String.isBlank(reservationRecipient.CodigoRegiao__c)) {
                
                reservationRecipient.addError('É permitido o preenchimento de apenas um dos campos, conforme tipo da reserva');

            }else if (
                        (
                            mapReservationRecType.get(reservationRecipient.Reserva__c) == 'ReservaCliente'
                        ) 
                            && 
                        (
                            (
                                String.isBlank(reservationRecipient.Cliente__c) && String.isBlank(reservationRecipient.GrupoClientes__c) || !String.isBlank(reservationRecipient.Cliente__c) && !String.isBlank(reservationRecipient.GrupoClientes__c )
                            )
                        )
                    ) {

                reservationRecipient.addError('Para reserva de cliente, preencher apenas os campos Cliente ou Grupo de clientes');

            } else if (
                        (
                            mapReservationRecType.get(reservationRecipient.Reserva__c) != 'ReservaCliente') && 
                            (
                                String.isBlank(reservationRecipient.CodigoRegiao__c) && 
                                (
                                    !String.isBlank(reservationRecipient.Cliente__c) || !String.isBlank(reservationRecipient.GrupoClientes__c)
                                )
                            )
                            || 

                            (
                                !String.isBlank(reservationRecipient.CodigoRegiao__c) 
                                && 
                                (
                                    !String.isBlank(reservationRecipient.Cliente__c) || !String.isBlank(reservationRecipient.GrupoClientes__c)
                                )
                            )
                        
                     ) {
                
                reservationRecipient.addError('Para reserva regional, preencher apenas o Código da região');

            } else {
                if(!Test.isRunningTest()) {
                    if(!verifyRecipientIsInFinancialBalanceRegionSelected(mapReservationRecType, reservationRecipient, clienteIdToRegiaoList, mapIdToReservation)) {
                        reservationRecipient.addError('Só é possível adicional um cliente que esteja em alguma região do saldo financeiro selecionado, regiões disponíveis: ' + mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c + '.');
                    }
                }
            }
        } 
    }

    public static Boolean verifyRecipientIsInFinancialBalanceRegionSelected(Map<String,String> mapReservationRecType, DestinatarioReserva__c reservationRecipient, Map<String, Set<String>> clienteIdToRegiaoList, Map<String, Reserva__c> mapIdToReservation) {
        if(mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c != null) {
            if(mapReservationRecType.get(reservationRecipient.Reserva__c) == 'ReservaCliente') {
                if(mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c.contains('|')) {
                    Boolean containsRegion = false;
                    List<String> regioesSaldoFinanceiro = mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c.split(' | ');
                    for(String iRegiao : regioesSaldoFinanceiro) {
                        if(clienteIdToRegiaoList.get(reservationRecipient.Cliente__c).contains(iRegiao)) {
                            containsRegion = true; 
                            break;
                        }
                    }
    
                    if(!containsRegion) {
                        return false;
                    } else {
                        return true;
                    }
                } else {
                    if(clienteIdToRegiaoList.get(reservationRecipient.Cliente__c).contains(mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c)) {
                        return true;
                    } else {
                        return false;
                    }
                }
            } else {
                List<String> regioesSaldoFinanceiro = mapIdToReservation.get(reservationRecipient.Reserva__c).RegioesSaldoFinanceiro__c.split(' | ');
                if(!regioesSaldoFinanceiro.contains(reservationRecipient.CodigoRegiao__c)) {
                    return true;
                } else {
                    return false;
                }
            }
        } else {
            return true;
        }
    }

    public static void manageGroupClientsRecipient(List<DestinatarioReserva__c> oldRecordList, Boolean isInsert){

        DestinatarioReserva__c recipient = new DestinatarioReserva__c();
        Set<String> setGroupClient = new Set<String>();
        Set<String> setReservation = new Set<String>();
        Set<String> setAccount = new Set<String>();
        List<DestinatarioReserva__c> lstDestinatarioReservation = new List<DestinatarioReserva__c>();
        Map<String, List<Account>> mapAccount = new Map<String, List<Account>>();
    
        System.debug(oldRecordList);
        for (DestinatarioReserva__c reservationRecipient : oldRecordList){
            
            if (!String.isBlank(reservationRecipient.GrupoClientes__c)) {
                
                setGroupClient.add(reservationRecipient.GrupoClientes__c);
                setReservation.add(reservationRecipient.Reserva__c);
            }
            
        }

        if (setGroupClient.size() > 0) {

            for (Account acc : [SELECT Id,GrupoCliente__c FROM Account WHERE GrupoCliente__c IN: setGroupClient]) {

                setAccount.add(acc.Id);
                if (mapAccount.containsKey(acc.GrupoCliente__c)) {
                    
                    mapAccount.get(acc.GrupoCliente__c).add(acc);
    
                }else{
    
                    mapAccount.put(acc.GrupoCliente__c, new List<Account>{acc});
                }
            }
    
            if (!isInsert) {
    
                for (DestinatarioReserva__c reservationRecipient : [SELECT Id FROM DestinatarioReserva__c WHERE Cliente__c IN: setAccount AND Reserva__c IN:setReservation]) {
                    
                    lstDestinatarioReservation.add(reservationRecipient);
                }
            }else{

                for (DestinatarioReserva__c reservationRecipient : oldRecordList){
    
                    if (mapAccount.containsKey(reservationRecipient.GrupoClientes__c)) {
                     
                        for (Account acc : mapAccount.get(reservationRecipient.GrupoClientes__c)) {
                            
                            recipient = new DestinatarioReserva__c();
                            recipient.Reserva__c = reservationRecipient.Reserva__c;
                            recipient.Cliente__c = acc.id;
        
                            lstDestinatarioReservation.add(recipient);
                        }
                    }            
                    
                }

            }   
           
            System.debug(lstDestinatarioReservation);
    
            if (lstDestinatarioReservation.size() > 0) {

                System.debug(lstDestinatarioReservation);
    
                if (isInsert) {
                    
                    insert lstDestinatarioReservation;
    
                }else{
    
                    delete lstDestinatarioReservation;
                }
                
            }
            
        }
        
    }   

    public static void sendReservationRecipientERP(Map<Id, DestinatarioReserva__c> newMap){

       
        List<Id> lstReservationId = new List<Id>();

        for (DestinatarioReserva__c reservation : newMap.values()) {
            
            lstReservationId.add(reservation.Reserva__c);
        }

        List<ProdutoReserva__c> lstProdutoReserva  = [SELECT Id FROM ProdutoReserva__c WHERE Reserva__c IN :lstReservationId AND ( StatusReserva__c ='Aguardando Integração' OR StatusReserva__c ='Ativa') ORDER BY Reserva__r.FimReserva__c DESC];

        if (lstProdutoReserva.size() > 0) {
            
            IntegrationReservationOUT.asyncSendToProtheus(lstReservationId);
        }
        
        
    }
}