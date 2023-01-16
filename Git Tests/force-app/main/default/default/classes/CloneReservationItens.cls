public without sharing class CloneReservationItens {
    private static final string REPLACE_CUSTOM_LABEL_ZERO_POSITION = '{0}';

    @InvocableMethod(label='Clone Reservation Itens' 
                    description='Button to clone the order and its items')
    public static List<FlowOutputs> flowCloneReservationItens(List<FlowInputs> flowInputs) {
        try {
            Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCNPJToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
            Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
            Map<String, ProdutoReserva__c> mapKeyToReservationProductToGetItens = new Map<String, ProdutoReserva__c>();
            Map<String, ProdutoReserva__c> mapKeyToReservationProductCurrent = new Map<String, ProdutoReserva__c>();
            Map<String, ProdutoReserva__c> mapKeyArmazenAndProductIdToReservationProductCurrent = new Map<String, ProdutoReserva__c>();
            Map<String, Estoque__c> mapKeyToInventory = new Map<String, Estoque__c>();

            Set<String> productIdGetItensSet = new Set<String>();
            Set<String> armazenCodeToGetItensSet = new Set<String>();
            Set<String> distributionCenterCNPJToGetItensSet = new Set<String>();

            String reservationToGetItens = '';

            System.debug(JSON.serialize(flowInputs));

            Map<Id, Reserva__c> mapIdReservationToReservation = new Map<Id, Reserva__c>(
                [
                    SELECT Id, CodigoCD__c,  SaldoFinanceiroDisponivel__c, Name, CodigoReserva__c
                    FROM Reserva__c 
                    WHERE Name =: flowInputs.get(0).reservationToGetItens 
                    OR Id =: flowInputs.get(0).currentReservationId]
            );

            System.debug(JSON.serialize(mapIdReservationToReservation.values()));

            for(Reserva__c iReserva : mapIdReservationToReservation.values()) {
                System.debug('=========== '+iReserva.Name);
                System.debug('=========== '+flowInputs.get(0).reservationToGetItens);
                if(iReserva.Name == flowInputs.get(0).reservationToGetItens) {
                    reservationToGetItens = iReserva.Id;
                }
            }

            if(String.isBlank(reservationToGetItens)) {
                return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_1.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, flowInputs.get(0).reservationToGetItens))};
            }

            for(ListaCentroDistribuicao__c iListaDistribuicao : [
                SELECT Id, CNPJCD__c, CodigoCD__c, NomeCD__c 
                FROM ListaCentroDistribuicao__c 
                WHERE CNPJCD__c != NULL 
                AND CodigoCD__c != NULL 
                AND NomeCD__c != NULL]) {
                mapDistributionCenterCNPJToListaCentroDistribuicao.put(iListaDistribuicao.CNPJCD__c, iListaDistribuicao);
                mapDistributionCenterCodeToListaCentroDistribuicao.put(iListaDistribuicao.CodigoCD__c, iListaDistribuicao);
            }

            for(ProdutoReserva__c iProdutoReserva : [
                SELECT Id, Reserva__c, Name, Produto__c, Produto__r.Name, Armazem__c, Reserva__r.CodigoCD__c, QuantidadeReservada__c, UltimaAprovacao__c, StatusReserva__c, QuantidadeAtiva__c, QuantidadeConsumida__c, Preco__c
                FROM ProdutoReserva__c 
                WHERE Reserva__c =: flowInputs.get(0).currentReservationId
                AND Reserva__r.CodigoCD__c != NULL 
                AND Armazem__c != NULL 
                AND Produto__c != NULL]) {
                if(mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(iProdutoReserva.Reserva__r.CodigoCD__c)) {
                    String key = iProdutoReserva.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(iProdutoReserva.Reserva__r.CodigoCD__c).CNPJCD__c + iProdutoReserva.Produto__c;
                    mapKeyToReservationProductCurrent.put(key, iProdutoReserva);
                    String key2 = iProdutoReserva.Armazem__c + iProdutoReserva.Produto__c;
                    if(!Test.isRunningTest()) {
                        mapKeyArmazenAndProductIdToReservationProductCurrent.put(key2, iProdutoReserva);
                    }
                } else {
                    return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_2.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, iProdutoReserva.Name))};
                }
            }

            System.debug('mapKeyToReservationProductCurrent ==> ' + mapKeyToReservationProductCurrent);

            for(ProdutoReserva__c iProdutoReserva : [
                SELECT Id, Reserva__c, Name, Produto__c, Produto__r.Name, Armazem__c, Reserva__r.CodigoCD__c, QuantidadeReservada__c, UltimaAprovacao__c, StatusReserva__c, QuantidadeAtiva__c, QuantidadeConsumida__c, Preco__c
                FROM ProdutoReserva__c 
                WHERE Reserva__c =: reservationToGetItens
                AND Reserva__r.CodigoCD__c != NULL 
                AND Armazem__c != NULL 
                AND Produto__c != NULL]) {
                System.debug('mapDistributionCenterCodeToListaCentroDistribuicao ==> ' + mapDistributionCenterCodeToListaCentroDistribuicao);
                System.debug('iProdutoReserva.Reserva__r.CodigoCD__c ==> ' + iProdutoReserva.Reserva__r.CodigoCD__c);
                if(mapDistributionCenterCodeToListaCentroDistribuicao.containsKey(iProdutoReserva.Reserva__r.CodigoCD__c)) {
                    String key = iProdutoReserva.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(iProdutoReserva.Reserva__r.CodigoCD__c).CNPJCD__c + iProdutoReserva.Produto__c;
                    String key2 = iProdutoReserva.Armazem__c + iProdutoReserva.Produto__c;
                    System.debug('key => ' + key);
                    System.debug('key2 => ' + key2);
                    System.debug('mapKeyArmazenAndProductIdToReservationProductCurrent => ' + mapKeyArmazenAndProductIdToReservationProductCurrent);
                    if(!mapKeyArmazenAndProductIdToReservationProductCurrent.containsKey(key2)) {
                        mapKeyToReservationProductToGetItens.put(key, iProdutoReserva);
                        productIdGetItensSet.add(iProdutoReserva.Produto__c);
                        armazenCodeToGetItensSet.add(iProdutoReserva.Armazem__c);
                        distributionCenterCNPJToGetItensSet.add(mapDistributionCenterCodeToListaCentroDistribuicao.get(iProdutoReserva.Reserva__r.CodigoCD__c).CNPJCD__c);
                    }
                } else {
                    return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_2.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, iProdutoReserva.Name))};
                }
            }

            if(mapKeyToReservationProductToGetItens.values().size() == 0) {
                return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_3.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapIdReservationToReservation.get(reservationToGetItens).Name))};
            }

            System.debug('mapKeyToReservationProductToGetItens ==> ' + mapKeyToReservationProductToGetItens);
            System.debug('armazenCodeToGetItensSet ==> ' + armazenCodeToGetItensSet);
            System.debug('distributionCenterCNPJToGetItensSet ==> ' + distributionCenterCNPJToGetItensSet);
            System.debug('productIdGetItensSet ==> ' + productIdGetItensSet);

            for(Estoque__c iEstoque : [
                SELECT Id, Name, NomeProduto__c, Armazem__c, NomeCD__c, Saldo__c, CNPJCD__c, PrecoMedio__c 
                FROM Estoque__c 
                WHERE NomeProduto__c IN: productIdGetItensSet 
                AND Saldo__c != 0 
                AND PrecoMedio__c != 0
                AND Saldo__c != NULL
                AND PrecoMedio__c != NULL
                AND Armazem__c IN: armazenCodeToGetItensSet 
                AND CNPJCD__c IN: distributionCenterCNPJToGetItensSet]) {
                String key = iEstoque.Armazem__c + iEstoque.CNPJCD__c + iEstoque.NomeProduto__c;
                if(mapDistributionCenterCNPJToListaCentroDistribuicao.containsKey(iEstoque.CNPJCD__c)) {
                    mapKeyToInventory.put(key, iEstoque);
                } else {
                    return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_4.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, iEstoque.Name))};
                }
            }

            List<ProdutoReserva__c> productReservationToClone = new List<ProdutoReserva__c>();

            if(mapKeyToInventory.values().size() > 0 && mapKeyToReservationProductToGetItens.values().size() > 0) {
                for(String key : mapKeyToInventory.keySet()) {
                    if(mapKeyToReservationProductToGetItens.containsKey(key) && mapKeyToInventory.containsKey(key)) {
                        Decimal balanceReservation = mapKeyToReservationProductToGetItens.get(key).QuantidadeReservada__c;
                        Decimal balanceInventory = mapKeyToInventory.get(key).Saldo__c;
                        if(balanceReservation <= balanceInventory) {
                            productReservationToClone.add(mapKeyToReservationProductToGetItens.get(key));
                        } else {
                            return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_5.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapKeyToReservationProductToGetItens.get(key).Name))};
                        }
                    } else {
                        return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_5.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapKeyToReservationProductToGetItens.get(key).Name))};
                    }
                }
            } else {
                return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_6.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapIdReservationToReservation.get(reservationToGetItens).Name))};
            }

            Decimal sumAllValuesProductReservationInventory = 0;

            for(ProdutoReserva__c iProdutoReserva : productReservationToClone) {
                String key = iProdutoReserva.Armazem__c + mapDistributionCenterCodeToListaCentroDistribuicao.get(iProdutoReserva.Reserva__r.CodigoCD__c).CNPJCD__c + iProdutoReserva.Produto__c;
                if(mapKeyToInventory.containsKey(key)) {
                    sumAllValuesProductReservationInventory = sumAllValuesProductReservationInventory + (mapKeyToInventory.get(key).PrecoMedio__c  * iProdutoReserva.QuantidadeReservada__c);
                }
            }

            if(sumAllValuesProductReservationInventory <= mapIdReservationToReservation.get(flowInputs.get(0).currentReservationId).SaldoFinanceiroDisponivel__c && sumAllValuesProductReservationInventory != 0) {
                List<ProdutoReserva__c> productReservationToUpdate = new List<ProdutoReserva__c>();

                for(ProdutoReserva__c iProdutoReserva : productReservationToClone) {
                    ProdutoReserva__c produtoReserva = new ProdutoReserva__c();
                    produtoReserva.Reserva__c = flowInputs.get(0).currentReservationId;
                    produtoReserva.Preco__c = iProdutoReserva.Preco__c;
                    produtoReserva.Armazem__c = iProdutoReserva.Armazem__c;
                    produtoReserva.Produto__c = iProdutoReserva.Produto__c;
                    produtoReserva.QuantidadeConsumida__c = iProdutoReserva.QuantidadeConsumida__c;
                    produtoReserva.QuantidadeReservada__c = iProdutoReserva.QuantidadeReservada__c;
                    produtoReserva.QuantidadeAtiva__c = iProdutoReserva.QuantidadeAtiva__c;
                    produtoReserva.StatusReserva__c = 'Aguardando Aprovação';
                    produtoReserva.UltimaAprovacao__c  = iProdutoReserva.UltimaAprovacao__c;
                    productReservationToUpdate.add(produtoReserva);
                }

                Database.SaveResult[] reservationInsertList = Database.insert(productReservationToUpdate, false);

                Boolean insertedSuccess = false;

                for(Database.SaveResult iDatabaseSaveResult : reservationInsertList) {
                    insertedSuccess = true;
                    if(!iDatabaseSaveResult.isSuccess()) {
                        insertedSuccess = false;
                        for(Database.Error err : iDatabaseSaveResult.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
                if(insertedSuccess) {
                    return new List<FlowOutputs>{new FlowOutputs(true, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_7)};
                } else {
                    return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_8.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapIdReservationToReservation.get(reservationToGetItens).Name))};
                }
            } else {
                return new List<FlowOutputs>{new FlowOutputs(false, SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_9.replace(REPLACE_CUSTOM_LABEL_ZERO_POSITION, mapIdReservationToReservation.get(flowInputs.get(0).currentReservationId).Name))};
            }
        } catch(Exception e) {
            return new List<FlowOutputs>{new FlowOutputs(false, e.getMessage() + ' ' + e.getStackTraceString())};
        }
    }

    public class FlowInputs{
    
        @InvocableVariable
        public String reservationToGetItens;

        @InvocableVariable
        public String currentReservationId;
    }

    public class FlowOutputs {
    
        @InvocableVariable
        public Boolean status;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public String messageAdminDefault;

        public FlowOutputs(Boolean status, String message) {
            this.status = status;
            this.message = message;
            this.messageAdminDefault = SYSTEM.LABEL.CLONE_RESERVATION_ITENS_MESSAGE_10;
        }
    }
}