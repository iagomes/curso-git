global class BatchStockEmails implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, OrderId, ItemPendente__c, Order.Status, CNPJCD__c, CentroDistribuicao__c, Product2Id, Product2.Name, Product2.ProductCode, Product2.Fornecedor__r.Name, Quantity FROM OrderItem WHERE ItemPendente__c = true AND Order.Status = 'Em digitação']);
    }

    global void execute(Database.BatchableContext BC, List<OrderItem> scope) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Id templateEmailId;
        for (EmailTemplate template : [SELECT Id, Name, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'EmailStatusPendingOrder' LIMIT 1]) {
            templateEmailId = template.Id;
        }

        Map<Id, List<Estoque__c>> orderItemToStockMap = new Map<Id, List<Estoque__c>>();
        Map<Id, List<OrderItem>> orderToOrderItemMap = new Map<Id, List<OrderItem>>();
        Set<Id> productIdsSet = new Set<Id>();

        for (OrderItem orderItem : scope) {
            productIdsSet.add(orderItem.Product2Id);
            if (!orderToOrderItemMap.containsKey(orderItem.OrderId)) {
                orderToOrderItemMap.put(orderItem.OrderId, new List<OrderItem>{});
            }
            orderToOrderItemMap.get(orderItem.OrderId).add(orderItem);
        }
        for (Estoque__c stock : [SELECT Id, NomeProduto__r.Name, NomeProduto__c, NomeProduto__r.ProductCode, NomeCD__c, CNPJCD__c, Saldo__c FROM Estoque__c WHERE NomeProduto__c IN: productIdsSet AND CNPJCD__c <> null AND NomeCD__c <> null]) {
            for (OrderItem orderItem : scope) {
                if (orderItem.Product2Id == stock.NomeProduto__c) {
                    if (!orderItemToStockMap.containsKey(orderItem.Id)) {
                        orderItemToStockMap.put(orderItem.Id, new List<Estoque__c>{});
                    }
                    orderItemToStockMap.get(orderItem.Id).add(stock);
                }
            }
        }
        
        for (Order order : [SELECT Id, OrderNumber, CreatedById, CreatedBy.Email, Account.Name, Status FROM Order WHERE Id IN: orderToOrderItemMap.keySet() AND Status = 'Em digitação']) {
            System.debug('Pedido => ' + order.OrderNumber);
            String bodyEmail = 'Status do estoque do pedido ' + order.OrderNumber + '<br/><br/>';
            for (OrderItem orderItem : orderToOrderItemMap.get(order.Id)) {
                if (orderItemToStockMap.containsKey(orderItem.Id)) {
                    String bodyCds = '';
                    Integer stockCd = 0;
                    System.debug('Itens do Pedido => ' + orderItem.Product2.Name);
                    for (Estoque__c stock : orderItemToStockMap.get(orderItem.Id)) {
                        if (stock.NomeCD__c == orderItem.CentroDistribuicao__c) {
                            stockCd = stock.Saldo__c.intValue();
                        } else if (stock.Saldo__c > 0) {
                            bodyCds += stock.NomeCD__c + ' => <b>' + stock.Saldo__c.intValue() + '</b><br/>';
                        }
                    }
                    bodyEmail += 'Produto => <b>' + orderItem.Product2.ProductCode + '</b> - ' + orderItem.Product2.Name + '<br/>CD => ' + orderItem.CentroDistribuicao__c + '<br/>Fabricante => ' + orderItem.Product2.Fornecedor__r.Name + '<br/>Quantidade pendente => ' + orderItem.Quantity.intValue() + ' | <b>Quantidade disponível => ' + stockCd + '</b><br/><font color="#00cc00"><u><b>Quantidade em estoque de outros CDs:</font></u></b><br/>';
                    if (bodyCds == '') {
                        bodyEmail += '<b>Não há estoque disponível em outros CDs.</b>' + '<br/>';
                    } else {
                        bodyEmail += bodyCds + '<br/>';
                    }
                }
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>{order.CreatedBy.Email};
            
            mail.setSubject('Status dos pedidos pendentes');
            mail.setTargetObjectId(order.CreatedById);
            mail.setTemplateId(templateEmailId);
            mail.setToAddresses(toAddresses);
            mail.setSaveAsActivity(false);
            mail.setHtmlBody(bodyEmail);
            emailList.add(mail);
        }

        if (!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
            System.debug('Todos emails de pedido pendente enviados com sucesso.');
            System.debug(results);
        }
    }

    global void finish(Database.BatchableContext BC) {}
}
