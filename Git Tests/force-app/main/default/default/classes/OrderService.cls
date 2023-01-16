/**
 * @author matheus.campos@nescara.com
 * @date 18/10/2022
 * @description Esta classe foi criada para armazenar regras de negócios relacionadas ao objeto Order, 
 * o prefixo service é utilizado para introduzir uma camada de separação de conceitos dentro da organização, 
 * separando cada módulo para fazer apenas uma atividade.
 */
public with sharing class OrderService {
    /**
    * @description Atualiza os campos de CondicaoPagamento__c, MensagemNF__c, ObservacoesPedido__c e Status a partir de um mapa contendo o cabeçalho do pedido.
    * @param mapObjectToOrderHeader um objeto deserializado do javascript que contém o nome do campo e o valor dele
    * @return Retorna true se a atualização do pedido foi feita com sucesso.
    * @example
    * Boolean isUpdated = OrderService.updatePaymentConditionAndNotesOrder(mapObjectToOrderHeader);
    */
    public static Boolean updatePaymentConditionAndNotesOrder(Map<String, Object> mapObjectToOrderHeader) {
        Database.SaveResult orderUpdatedRegisterList = Database.update(new Order(Id                   = String.valueOf(mapObjectToOrderHeader.get('recordId')), MensagemNF__c        = mapObjectToOrderHeader.get('observacaoNF')      != null ? String.valueOf(mapObjectToOrderHeader.get('observacaoNF'))      : null,ObservacoesPedido__c = mapObjectToOrderHeader.get('observacaoPedido')  != null ? String.valueOf(mapObjectToOrderHeader.get('observacaoPedido'))  : null,CondicaoPagamento__c = mapObjectToOrderHeader.get('condicaoPagamento') != null ? String.valueOf(mapObjectToOrderHeader.get('condicaoPagamento')) : null,Status               = 'Aguardando integração',NecessarioComprovante__c = isRequiredProof(mapObjectToOrderHeader.get('condicaoPagamento') != null ? String.valueOf(mapObjectToOrderHeader.get('condicaoPagamento')) : null)));
        return orderUpdatedRegisterList.isSuccess();
    }

    /**
    * @description Atualiza os campos de CondicaoPagamento__c, MensagemNF__c, ObservacoesPedido__c e Status de todos os pedidos filhos a partir de um mapa contendo o cabeçalho do pedido editado.
    * @param mapObjectToOrderHeader um objeto deserializado do javascript que contém o nome do campo e o valor dele
    * @param orderFatherId Id do pedido pai
    * @return Retorna true se a atualização dos pedidos obteve sucesso.
    * @example
    * Boolean isUpdated = OrderService.updatePaymentConditionAndNotesOrder(mapObjectToOrderHeader, recordId);
    */
    public static Boolean updatePaymentConditionAndNotesOrderSons(Map<String, Object> mapObjectToOrderHeader, String orderFatherId) {
        List<Order> orderSonList = new List<Order>();
        String messageNF         = mapObjectToOrderHeader.get('observacaoNF')      != null ? String.valueOf(mapObjectToOrderHeader.get('observacaoNF'))      : null;
        String orderNotes        = mapObjectToOrderHeader.get('observacaoPedido')  != null ? String.valueOf(mapObjectToOrderHeader.get('observacaoPedido'))  : null;
        String paymentCondition  = mapObjectToOrderHeader.get('condicaoPagamento') != null ? String.valueOf(mapObjectToOrderHeader.get('condicaoPagamento')) : null;
        
        for(Order iOrderSon : [
            SELECT Id, CondicaoPagamento__c, MensagemNF__c, ObservacoesPedido__c 
            FROM Order 
            WHERE OriginalOrder.Id =: orderFatherId
            AND PedidoRemessa__c = false]) {
            Boolean hadModified     = false;

            if(paymentCondition != null && iOrderSon.CondicaoPagamento__c != paymentCondition) {
                iOrderSon.CondicaoPagamento__c = paymentCondition;
                hadModified = true;
            }
            if(messageNF != null && iOrderSon.MensagemNF__c != messageNF) {
                iOrderSon.MensagemNF__c = messageNF;
                hadModified = true;
            }
            if(orderNotes != null && iOrderSon.ObservacoesPedido__c != orderNotes) {
                iOrderSon.ObservacoesPedido__c = orderNotes;
                hadModified = true;
            }
            if(hadModified) {
                orderSonList.add(iOrderSon);
            }
        }

        Database.SaveResult[] orderUpdatedRegisterList = Database.update(orderSonList, true);

        return orderUpdatedRegisterList[0].isSuccess();
    }

    /**
    * @description Verifica o nome do RecordType do pedido pai
    * @param type Nome do RecordType irá ser verificado
    * @param orderSonId Id do pedido fillho
    * @return Retorna true se o nome do tipo de registro for igual ao passado como parâmetro
    * @example
    * Boolean isUpdated = OrderService.checkOriginalOrderTypeFromOrderSonId('Pedido de venda', recordId);
    */
    public static Boolean checkOriginalOrderTypeFromOrderSonId(String type, String orderSonId) {
        return [SELECT OriginalOrder.RecordType.Name FROM Order WHERE Id =: orderSonId].OriginalOrder.RecordType.Name == type ? true : false;
    }

    public static Boolean isRequiredProof(String condicaoPagamento) {
        if(condicaoPagamento == null) {
            return false;
        } else {
            Boolean isRequiredProod = false;
            for (CondicaoPagamento__c iCondicaoPagamento : [
                SELECT Id, Name 
                FROM CondicaoPagamento__c 
                WHERE Id =: condicaoPagamento limit 1]) {
                if(iCondicaoPagamento.Name == 'RA' || iCondicaoPagamento.Name == 'RA/RECEB. ANTECIP.') {
                    isRequiredProod = true;
                } else {
                    isRequiredProod = false;
                }
            }
            return isRequiredProod;
        }
    }

    @TestVisible
    private class OrderServiceException extends Exception {}
}
