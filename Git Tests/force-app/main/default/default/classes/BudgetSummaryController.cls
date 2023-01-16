public with sharing class BudgetSummaryController {
    @AuraEnabled(cacheable=true)
    public static List<BudgetData> getBudgetList(String userId, String accountId, String budgetStatus, Boolean allBudgets) {
        List<Opportunity> opportunityList;

        if (allBudgets) {
            opportunityList = getOpportunities(userId, budgetStatus, null);
        } else {
            opportunityList = getOpportunities(userId, budgetStatus, accountId);
        }

        List<BudgetData> budgetDataList = new List<BudgetData>();
        
        for (Opportunity opportunity : opportunityList) {
            BudgetData budget = new BudgetData(opportunity);
            budgetDataList.add(budget);
        }

        return budgetDataList;
    }

    public static List<Opportunity> getOpportunities(String userId, String status, String accountId) {
        String statement = ''+
        'SELECT '+
            'Id, CreatedById, Owner.CompanyName, '+
            'AccountId, Account.Name, NumeroOrcamento__c, CreatedDate, '+
            'CloseDate, StageName '+
        'FROM Opportunity '+
        'WHERE CreatedById = \''+ userId + '\' ';

        if (status == 'open') {
            statement += 'AND StageName IN (\'Em digitação\', \'Aguardando aprovação\', \'Aprovado\') ';
        } else if (status == 'closed') {
            statement += 'AND StageName = \'Fechado/Perdido\' ';
        }

        if (accountId != null) {
            statement += 'AND Account.Name = \''+ accountId +'\' ';
        }

        statement += 'ORDER BY StageName ASC, CloseDate ASC ';

        System.debug(statement);

        return Database.query(statement);
    }

    public class BudgetData {
        @AuraEnabled public String Id           {get; set;}
        @AuraEnabled public String CompanyName  {get; set;}
        @AuraEnabled public String AccountName  {get; set;}
        @AuraEnabled public String BudgetNumber {get; set;}
        @AuraEnabled public String CreatedDate  {get; set;}
        @AuraEnabled public String CloseDate    {get; set;}
        @AuraEnabled public String StageName    {get; set;}
        @AuraEnabled public Boolean isExpired   {get; set;}

        public budgetData(Opportunity opportunity) {
            this.Id = opportunity.Id;
            this.CompanyName = opportunity.Owner.CompanyName;
            this.AccountName = opportunity.Account.Name;
            this.BudgetNumber = opportunity.NumeroOrcamento__c;
            this.StageName = opportunity.StageName;

            List<String> closeDate = String.valueOf(opportunity.CloseDate).split('-');
            List<String> createdDate = String.valueOf(opportunity.CreatedDate).split(' ')[0].split('-');

            this.CreatedDate = createdDate[2] + '/' + createdDate[1] + '/' + createdDate[0];
            this.CloseDate = closeDate[2] + '/' + closeDate[1] + '/' + closeDate[0];

            Date todayDate = Date.today();
            if (opportunity.CloseDate > todayDate) {
                this.isExpired = true;
            } else {
                this.isExpired = false;
            }
        }
    }
}
