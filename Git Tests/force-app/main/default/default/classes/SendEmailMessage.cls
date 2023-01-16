global without sharing class SendEmailMessage { 
    public static void emailMessage(Order pendingOrder) {
        Order orderEmail = [SELECT Id, OrderNumber, CreatedBy.Email, CreatedBy.CompanyName, Account.Name, Account.CNPJ__c, Account.CodigoLoja__c FROM Order WHERE Id = :pendingOrder.Id][0];

        Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        List<OrderItem> orderItemList = [SELECT Id, OrderId, Quantity, Product2.ProductCode, Product2.Name, ItemPendente__c, CentroDistribuicao__c FROM OrderItem WHERE OrderId = :pendingOrder.Id AND ItemPendente__c = true];
        
        List<String> splitList = orderEmail.CreatedBy.CompanyName.split('/');
        List<String> toAddresses = new List<String>{};
        String tituloEmail = '';
        for (String split : splitList) {
            if (tituloEmail == '') {
                tituloEmail = split;
            } else {
                tituloEmail = tituloEmail + ' | ' + split;
            }
            CompanyParameters__c emails = CompanyParameters__c.getAll().get(split);
            toAddresses.add(Test.isRunningTest() ? 'test@test.com' : emails?.Email__c);
        }
        toAddresses.add(orderEmail.CreatedBy.Email);
        
        mail.setToAddresses(toAddresses);
        mail.setSaveAsActivity(false);
        mail.setSubject('[ ' + tituloEmail.toUppercase() + ' ]' + ' Solicitação de compras');

        String bodyEmail = 'Foi gerado o pedido ' + orderEmail.OrderNumber + ' com pendências.<br/>' + orderEmail.Account.Name + ' | ' + orderEmail.Account.CNPJ__c + ' | ' + orderEmail.Account.CodigoLoja__c + '<br/>Produtos:<br/>';
        for (OrderItem orderItem : orderItemList) {
            bodyEmail = bodyEmail + orderItem.Product2.ProductCode + '-' + orderItem.Product2.Name + ' | Quantidade pendente: ' + orderItem.Quantity + ' | ' + orderItem.CentroDistribuicao__c + '<br/>';
        }

        mail.setHtmlBody(bodyEmail);
        emailList.add(mail);

        if (!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
            System.debug('Email de pedido pendente enviado com sucesso para:');
            System.debug(toAddresses);
            System.debug(results);
        }
        System.debug('Enviou Email de Pedido Pendente.');
    }

    public static void sendEmailMessageCancelledOrder(List<Order> listCancelledOrders){
        Set<String> orderOwnerIds = new Set<String>();
        Set<String> orderAccountIds = new Set<String>();

        for(Order cancelledOrder : listCancelledOrders){
            orderOwnerIds.add(cancelledOrder.OwnerId);
            orderAccountIds.add(cancelledOrder.AccountId);
        }

        Map<Id, User> mapUsers = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id IN : orderOwnerIds]);
        Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, Name, CNPJ__c, CodigoLoja__c FROM Account WHERE Id IN : orderAccountIds]);
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'CancelledOrderNotification'];

        List<Messaging.SingleEmailMessage> emailListCancelledOrders = new List<Messaging.SingleEmailMessage>();
        for(Order cancelledOrder : listCancelledOrders){
            if(mapUsers.containsKey(cancelledOrder.OwnerId)){
                if(mapAccounts.containsKey(cancelledOrder.AccountId)){
                    User currentUser = mapUsers.get(cancelledOrder.OwnerId);
                    Account currentAccount = mapAccounts.get(cancelledOrder.AccountId);
                    
                    Messaging.reserveSingleEmailCapacity(2);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    List<String> toAddresses = new List<String>{currentUser.Email};

                    mail.setToAddresses(toAddresses);
                    mail.setSubject('Aviso de cancelamento de pedido - ' + cancelledOrder.OrderNumber);

                    String bodyEmail;

                    if (cancelledOrder.MotivoCancelamento__c == null) {
                        bodyEmail = 'Olá ' + currentUser.Name + '.<br/><br/>O pedido ' + cancelledOrder.OrderNumber + ' do cliente ' + currentAccount.Name + ' - ' + currentAccount.CNPJ__c + ' - ' + currentAccount.CodigoLoja__c + ' foi cancelado no dia ' + cancelledOrder.LastModifiedDate.format() + '<br/>Motivo do cancelamento: ' + cancelledOrder.StatusIntegracao__c + ' - ' + cancelledOrder.ComentariosCancelamento__c;
                    } else {
                        bodyEmail = 'Olá ' + currentUser.Name + '.<br/><br/>O pedido ' + cancelledOrder.OrderNumber + ' do cliente ' + currentAccount.Name + ' - ' + currentAccount.CNPJ__c + ' - ' + currentAccount.CodigoLoja__c + ' foi cancelado no dia ' + cancelledOrder.LastModifiedDate.format() + '<br/>Motivo do cancelamento: ' + cancelledOrder.MotivoCancelamento__c + ' - ' + cancelledOrder.SubmotivosCancelamento__c;
                    }

                    mail.setHtmlBody(bodyEmail);
                    emailListCancelledOrders.add(mail);                     
        
                    Messaging.CustomNotification cancelledOrderNotification = new Messaging.CustomNotification();
                        
                    String bodyNotification;

                    cancelledOrderNotification.setTitle('Aviso de cancelamento de pedido');
                    cancelledOrderNotification.setTargetId(cancelledOrder.Id);
                    cancelledOrderNotification.setNotificationTypeId(notificationType.Id);
                    
                    if (cancelledOrder.MotivoCancelamento__c == null) {
                        bodyNotification = 'O pedido ' + cancelledOrder.OrderNumber + ' do cliente ' + currentAccount.Name + ' - ' + currentAccount.CNPJ__c + ' - ' + currentAccount.CodigoLoja__c + ' foi cancelado no dia ' + cancelledOrder.LastModifiedDate.format() + '\nMotivo do cancelamento: ' + cancelledOrder.StatusIntegracao__c + ' - ' + cancelledOrder.ComentariosCancelamento__c;
                        System.debug('Cancelamento automático');
                    } else {
                        bodyNotification = 'O pedido ' + cancelledOrder.OrderNumber + ' do cliente ' + currentAccount.Name + ' - ' + currentAccount.CNPJ__c + ' - ' + currentAccount.CodigoLoja__c + ' foi cancelado no dia ' + cancelledOrder.LastModifiedDate.format() + '\nMotivo do cancelamento: ' + cancelledOrder.MotivoCancelamento__c + ' - ' + cancelledOrder.SubmotivosCancelamento__c;
                        System.debug('Cancelamento manual');
                    } 
                    cancelledOrderNotification.setBody(bodyNotification);
                    
                    try {
                        cancelledOrderNotification.send(orderOwnerIds);
                    }
                    catch (Exception e) {
                        System.debug('Erro na notificação de sininho cancelamento de pedido ' + e.getMessage());
                    } 
                }
            }
        }     
        if (!emailListCancelledOrders.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailListCancelledOrders);
            System.debug(results);
        }
    }
}