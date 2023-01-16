global class BatchBudgetCancel implements Database.Batchable<sObject>, Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT 
                Id, 
                CloseDate, 
                StageName, 
                MotivoCancelamento__c, 
                (
                    SELECT 
                        Id, 
                        MotivoCancelamento__c
                    FROM OpportunityLineItems
                )
            FROM Opportunity
            WHERE CloseDate <= YESTERDAY
            AND (StageName = 'Em digitação' OR StageName = 'Aprovado')
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<OpportunityLineItem> opportunityItemList = new List<OpportunityLineItem>();

        for (Opportunity opportunity : scope) {
            opportunity.StageName = 'Fechado/Perdido';
            opportunity.MotivoCancelamento__c = 'Orçamento cancelado automaticamente por falta de tratativa dentro do vencimento';

            for (OpportunityLineItem opportunityItems : opportunity.OpportunityLineItems) {
                opportunityItems.MotivoCancelamento__c = 'Orçamento cancelado por falta de tratativa dentro do vencimento';
                opportunityItemList.add(opportunityItems);
            }
        }
        
        if (!opportunityItemList.isEmpty()) {
            update opportunityItemList;
        }
        if (!scope.isEmpty()) {
            update scope;
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
