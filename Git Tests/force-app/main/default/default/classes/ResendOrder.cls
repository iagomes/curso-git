public without sharing class ResendOrder {
    
    @InvocableMethod(label='Resend order' description='Send to TOTVS')
    public static List<String> resendOrderToTOTVS(List<Id> ordIdList){
        Id ordId = null;
        for (Id oId : ordIdList) {
            ordId = oId;
        }
        List<Order> ordList = [SELECT Id, ErroIntegracaoAprovacao__c, ErroIntegracaoCancelamento__c, ErroIntegracaoConfirmacao__c, ErroIntegracaoRejeitado__c, ExternalId__c, StatusIntegracao__c
                                 FROM Order WHERE Id = :ordId];
        BatchResendOrder.executeBatch(ordList[0]);

        return null;
    }
}
