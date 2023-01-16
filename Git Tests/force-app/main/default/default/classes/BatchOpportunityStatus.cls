global class BatchOpportunityStatus implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();

        return Database.getQueryLocator([
            SELECT Id, StageName, DataVencimento__c, TabulacaoN1__c, TabulacaoN2__c
            FROM Opportunity WHERE DataVencimento__c <= :Datetime.now()
            AND (StageName = 'Novo' OR StageName = 'Respondida')
            AND RecordTypeId = :recordTypeId
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope ) {
        List<Opportunity> listOpp = (List<Opportunity>)scope;
        for(Opportunity opp : listOpp){

            if(opp.StageName == 'Novo' && opp.DataVencimento__c < Datetime.now()){
                opp.StageName = 'Não Respondida';
                opp.TabulacaoN1__c = 'Recusa';
                opp.TabulacaoN2__c = 'Cotação Vencida';
            }

            if(opp.StageName == 'Respondida' && opp.DataVencimento__c < Datetime.now().addDays(-10)){
                opp.StageName = 'Sem Retorno';
            }
        }

        update listOpp;
    }

    global void finish(Database.BatchableContext BC) {}

}
