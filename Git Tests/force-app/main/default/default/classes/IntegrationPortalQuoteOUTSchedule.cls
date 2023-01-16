public class IntegrationPortalQuoteOUTSchedule implements Schedulable {

    public static final Id RECORDTYPE_PORTALID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('OrcamentoPortal').getRecordTypeId();

    public void execute(SchedulableContext sc) {
        System.debug('método principal');
        Savepoint sp;
        try {
            Map<Id, Opportunity> oppMap = getOpportunityMap();
            String standardConPayId = getStandardConditionPaymentId();
            sp = Database.setSavepoint();
            List<Id> oppIdList = updateOpportunities(oppMap, standardConPayId);

            if(!oppIdList.isEmpty()) System.enqueueJob(new IntegrationPortalQuoteOUTQueueable(0, oppIdList));
        } catch (Exception ex) {
            if(sp != null){
                Database.rollback(sp);
            }
            ExceptionUtils.debug(ex);
        }


    }

    public static void scheduleQueue() {
        
        IntegrationPortalQuoteOUTSchedule s = new IntegrationPortalQuoteOUTSchedule();
        for(String cronExp : getCronExpList()){
            System.debug('agendando '+cronExp);
            System.schedule(Test.isRunningTest() ? 'IntegrateQuoteOUT'+cronExp.mid(2, 2)+'min job test' : 'IntegrateQuoteOUT'+cronExp.mid(2, 2)+'min job', cronExp, s);
        }
    }

    private static List<String> getCronExpList(){
        return new List<String>{
            '0 0 * * * ?',
            '0 5 * * * ?',
            '0 10 * * * ?',
            '0 15 * * * ?',
            '0 20 * * * ?',
            '0 25 * * * ?',
            '0 30 * * * ?',
            '0 35 * * * ?',
            '0 40 * * * ?',
            '0 45 * * * ?',
            '0 50 * * * ?',
            '0 55 * * * ?'
        };
    }

    private static Map<Id, Opportunity> getOpportunityMap(){
        return new Map<Id, Opportunity> ([
            SELECT Id, 
            (SELECT Id, MinimumBilling__c, PrazoEntrega__c, FretePicklist__c, CondicaoPagamento__c, CondicaoPagamentoPL__c, ObservacoesLongText__c FROM Condicespagamentospor_CD__r),
            (SELECT Id FROM OpportunityTeamMembers WHERE HasChangesUnsync__c = true)
            FROM Opportunity
            WHERE DataVencimento__c > :Datetime.now().addMinutes(-1)
            AND DataVencimento__c < :Datetime.now().addMinutes(5).addSeconds(30)
            AND RecordTypeId = :RECORDTYPE_PORTALID
            AND HasChangesUnsync__c = true
        ]);
    }

    private static String getStandardConditionPaymentId(){
        String standardConPayId = null;
        List<CondicaoPagamento__c> conPayList = [
            SELECT Id 
            FROM CondicaoPagamento__c 
            WHERE Name = '043/A VISTA'
        ];
        if(!conPayList.isEmpty()) standardConPayId = conPayList[0].Id;
        return standardConPayId;
    }

    private static List<Id> updateOpportunities(Map<Id, Opportunity> oppMap, String standardConPayId){
        List<Id> oppIdList = new List<Id>();
        List<CondicaoPagamentoPorCD__c> cdList = new List<CondicaoPagamentoPorCD__c>();
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        List<OpportunityTeamMember> oppTeamMemberToUpdate = new List<OpportunityTeamMember>();
        
        for(Opportunity opp : oppMap.values()){
            oppIdList.add(opp.id);
            oppToUpdate.add(
                new Opportunity(
                    id= opp.id,
                    StageName = 'Aguardando Integração',
                    TabulacaoN1__c = 'Aceite',
                    TabulacaoN2__c = 'Envio Automático',
                    OrcamentoTravado__c = true
                )
            );

            if(!opp.OpportunityTeamMembers.isEmpty()){
                for(OpportunityTeamMember oppTm : opp.OpportunityTeamMembers){
                    oppTeamMemberToUpdate.add(
                        new OpportunityTeamMember(
                            id= oppTm.id,
                            TabulacaoN1__c = 'Aceite',
                            TabulacaoN2__c = 'Envio Automático'
                        )
                    );
                }
            }

            if(opp.Condicespagamentospor_CD__r.isEmpty()) continue;
            
            for(CondicaoPagamentoPorCD__c cd : opp.Condicespagamentospor_CD__r){
                Boolean changeCD = false;
                if(cd.MinimumBilling__c == 0  || cd.MinimumBilling__c == null){
                    cd.MinimumBilling__c = 600;
                    changeCD = true;
                }
                if(cd.PrazoEntrega__c   == 0  || cd.PrazoEntrega__c   == null){
                    cd.PrazoEntrega__c = 5;
                    changeCD = true;
                }
                if(String.isEmpty(cd.FretePicklist__c)){
                    cd.FretePicklist__c = 'CIF';
                    changeCD = true;
                }
                if(String.isEmpty(cd.CondicaoPagamento__c)){
                    cd.CondicaoPagamentoPL__c = '043/A VISTA';
                    cd.CondicaoPagamento__c = standardConPayId;
                    cd.ObservacoesLongText__c = String.isEmpty(cd.ObservacoesLongText__c) ? '' : cd.ObservacoesLongText__c + '\n';
                    cd.ObservacoesLongText__c += 'Atenção: Condição de pagamento a combinar!';
                    changeCD = true;
                }

                if(changeCD) cdList.add(cd);
            }
            
        }
        update oppToUpdate;
        update oppTeamMemberToUpdate;
        update cdList;
        return oppIdList;
    }
}
