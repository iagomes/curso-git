public with sharing class BudgetDetailTabulacaoController {
    @AuraEnabled
    public static Map<String, Boolean> oppDueDateWasUpdatedByPortal(Id oppId){
        Map<String, Boolean> response = new Map<String,Boolean>();
        try {
            List<OpportunityFieldHistory> fildHistory =  [SELECT OpportunityId, CreatedDate, Field, OldValue, NewValue FROM OpportunityFieldHistory WHERE field = 'DataVencimento__c' AND OpportunityId = :oppId ORDER BY CreatedDate DESC];
            if(fildHistory.size() > 0){
                response.put('updatedByPortal',true);
            }else{
                response.put('updatedByPortal',false);
            
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static StandardResponse getTabulacaoValues(Id oppId){
        StandardResponse response = new StandardResponse();
        try {
            Opportunity opp =  [SELECT TabulacaoN1__c, TabulacaoN2__c FROM Opportunity WHERE Id = :oppId];
            response.setData('tabulacao', opp);
        } catch (Exception e) {
            response.addError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static StandardResponse getTabulacaoTeamMember(Id oppId){
        StandardResponse response = new StandardResponse();
        try {
            UserInfo.getUserId();
            List<OpportunityTeamMember> oppTeamMemberList =  [SELECT TabulacaoN1__c, TabulacaoN2__c FROM OpportunityTeamMember  WHERE OpportunityId = :oppId AND UserId = :UserInfo.getUserId() limit 1];
            if(oppTeamMemberList.size()>0){
                response.setData('tabulacaoTeamMember', oppTeamMemberList[0]);
            }else{
                Opportunity opp =  [SELECT TabulacaoN1__c, TabulacaoN2__c FROM Opportunity WHERE Id = :oppId limit 1];
                response.setData('tabulacaoTeamMember', opp);
            }
        } catch (Exception e) {
            response.addError(e.getMessage());
        }
        return response;
    }
}
