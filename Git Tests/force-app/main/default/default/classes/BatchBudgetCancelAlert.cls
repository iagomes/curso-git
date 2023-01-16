global class BatchBudgetCancelAlert implements Database.Batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'workingDays'];
        Date targetDate = Date.today().addDays(2);
        Datetime targetTime = Datetime.now().addDays(2);
        Boolean isWithin;
        do {
            isWithin = BusinessHours.isWithin(bh.Id, targetTime);
            if (!isWithin) {
                targetDate = targetDate.addDays(1);
                targetTime = targetTime.addDays(1);
            }
        } while (!isWithin);

        return Database.getQueryLocator([SELECT Id, Name, CreatedById, CloseDate, StageName FROM Opportunity WHERE CloseDate =: targetDate AND (StageName = 'Em digitação' OR StageName = 'Aprovado') ORDER BY CloseDate DESC]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'BudgetExpirationNotification'];

        for (Opportunity opportunity : scope) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();

            List<String> dueDate = String.valueOf(opportunity.CloseDate).split(' ')[0].split('-');
            //dueDate = dueDate[0].split('-');
            notification.setTitle('Notificação de vencimento de orçamento');
            notification.setBody('O orçamento ' + opportunity.Name + ' vencerá em 2 dias (' + dueDate[2] + '/' + dueDate[1] + '/' + dueDate[0] + ')');

            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(opportunity.Id);

            try {
                Set<String> recipientsIds = new Set<String>();
                recipientsIds.add(opportunity.CreatedById);
                notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
