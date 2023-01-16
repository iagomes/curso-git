public without sharing class SalesmanNotificationPortal {

    @future
    public static void orderInNotification(String orderId, String oppId, List<String> quoteItemIdList, Decimal totalAmount){
        try {
            
            Order newOrder = getOrder(orderId);
            Opportunity opp = getOpportunity(oppId);
            Map<Id, QuoteItem__c> qItemMap = getQuoteItemMap(oppId);
            Map<String, Set<String>> salesManBuMap = getSalesManBuMap(opp.AccountId);

            Map<String, List<QuoteItem__c>> qItemMapByIdPortal = new Map<String, List<QuoteItem__c>>();
            List<QuoteItem__c> qItemWonList = new List<QuoteItem__c>();
            Set<String> idsVDS = new Set<String>();


            for(QuoteItem__c qItem : qItemMap.values()){
                if(!qItemMapByIdPortal.containsKey(qItem.IdPortal__c)){
                    qItemMapByIdPortal.put(qItem.IdPortal__c, new List<QuoteItem__c>());
                }

                qItemMapByIdPortal.get(qItem.IdPortal__c).add(qItem);

                if(quoteItemIdList.contains(qItem.Id)){
                    qItemWonList.add(qItem);
                }
            }

            for(QuoteItem__c qItemWon : qItemWonList){

                List<QuoteItem__c> qItemRelatedList = qItemMapByIdPortal.get(qItemWon.IdPortal__c);
                Set<String> salesManBuSet = salesManBuMap.get(qItemWon.Vendedor__c);

                idsVDS.add(qItemWon.Vendedor__c);
                if(qItemWon.Vendedor__c != qItemWon.VendedorRespondeu__c && qItemWon.VendedorRespondeu__c != null){
                    idsVDS.add(qItemWon.VendedorRespondeu__c);
                    salesManBuSet.addAll(salesManBuMap.get(qItemWon.VendedorRespondeu__c));
                }


                for(QuoteItem__c qItemRelated : qItemRelatedList){
                    if(qItemWon.Id == qItemRelated.Id){
                        continue;
                    }

                    if(salesManBuSet != null && salesManBuSet.contains(qItemRelated.Categoria__c)){
                        idsVDS.add(qItemRelated.Vendedor__c);
                    }
                }
            }

            notifyUsers(newOrder, idsVDS, opp);
            sendEmailVDS(idsVDS, newOrder, opp, totalAmount);
        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
        }
    }    

    public static void notifyUsers(Order order , Set<String> IdsVDS, Opportunity opp){

        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'NotificaoCasoEncerrado'
        ];
      
        notification.setTitle('Pedido ' + order.IdPortalCotacoes__c + ' Confirmado - '+opp.CanalEntrada__c);
        notification.setBody(opp.Account.Name +' confirmou um pedido: BIONEXO ID '+ order.IdPortalCotacoes__c +' - SF ID '+ order.Id);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(order.Id);
        notification.send(IdsVDS);
    }

    public static void sendEmailVDS(Set<String> IdsVDS, Order newOrder, Opportunity opp, Decimal totalAmount){

        try {

            List<Messaging.SingleEmailMessage> emailList  = new List<Messaging.SingleEmailMessage>();
            List<String> subjectValues = new List<String>{    
                opp.CanalEntrada__c,
                newOrder.IdPortalCotacoes__c,
                opp.Account.Name
            };
            String subjectPattern = 'Pedido confirmado: {0} - {1} - {2}';
            String emailSubject = String.format(subjectPattern, subjectValues);
            
            String emailHtmlBody = createEmailTemplateBody(newOrder, opp, totalAmount);

            for(String id : IdsVDS){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setSenderDisplayName('Salesforce');
                email.setBccSender(false);
                email.setTargetObjectId(id);
                email.setSubject(emailSubject);
                email.setHtmlBody(emailHtmlBody);
                email.saveAsActivity = false;
                emailList.add(email);
            }
            Messaging.reserveSingleEmailCapacity(emailList.size()); 

            if(!Test.isRunningTest()) {
                Messaging.sendEmail(emailList, false);
            }
            
        }  catch (Exception e) {
            ExceptionUtils.debug(e);
        }
    }

    public static String createEmailTemplateBody(Order newOrder, Opportunity opp, Decimal totalAmount){
        
        List<String> values = new List<String>{
            newOrder.Idportalcotacoes__c,
            opp.DataVencimento__c.formatGMT('dd/MM/yy HH:mm'),
            String.valueOf(TotalAmount),
            opp.Account.Name,
            URL.getSalesforceBaseUrl().toExternalForm()+'/'+newOrder.Id
        };

        String template = (
            '<p>Foram confirmados itens da cotação <b>{0}</b></p>'+
            '<p>Com vencimento em {1} </p>'+
            '<p>Com  Valor Total R$ {2}</p>'+
            '<p>Cotada pela empresa {3}.</p>'+
            '<p><a href={4}>Link do Pedido</a></p>'
        );

        return String.format(template, values);
    }

    public static Map<String, Set<String>> getSalesManBuMap(String accountId){
        Map<String, Set<String>> salesManBuMap = new Map<String, Set<String>>();

        List<Setorizacao__c> setorList = [
            SELECT VendedorSuporte__c, Categoria__c
            FROM Setorizacao__c 
            WHERE conta__c = :accountId
            AND VendedorSuporte__c != null
        ];

        for(Setorizacao__c setor : setorList){
            if(!salesManBuMap.containsKey(setor.VendedorSuporte__c)){
                salesManBuMap.put(setor.VendedorSuporte__c, new Set<String>());
            }
            salesManBuMap.get(setor.VendedorSuporte__c).add(setor.Categoria__c);
        }

        return salesManBuMap;
    }

    public static Map<Id, QuoteItem__c> getQuoteItemMap(String oppId){
        if(oppId != null){

            return new Map<Id, QuoteItem__c>([
                SELECT Id, 
                Categoria__c, CNPJCD__c, 
                IdPortal__c,
                OpportunityLineItem__c, OpportunityLineItem__r.PriceBookEntryId, 
                OpportunityLineItem__r.CentroDistribuicao__c, OpportunityLineItem__r.Product2Id, 
                OpportunityLineItem__r.ValorPortal__c, OpportunityLineItem__r.FatorConversao__c,
                OpportunityLineItem__r.TipoConversao__c, OpportunityLineItem__r.UnitPrice,
                OpportunityLineItem__r.Quantity, OpportunityLineItem__r.QuantidadePortal__c,
                Status__c,
                Vendedor__c, VendedorRespondeu__c
                FROM QuoteItem__c
                WHERE OpportunityId__c = :oppId
            ]);
        }
        else{
            return new Map<Id, QuoteItem__c>();
        }
    }

    public static Order getOrder(String orderId){

        List<Order> orderList = [
            SELECT Id,
            AccountId,
            IdPortalCotacoes__c
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        return !orderList.isEmpty() ? orderList[0] : null;
    }

    public static Opportunity getOpportunity(String oppId){
        
        List<Opportunity> opportunityList = [
            SELECT Id,
            AccountId, Account.Name,
            CanalEntrada__c,
            DataVencimento__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        return !opportunityList.isEmpty() ? opportunityList[0] : null;
    }
}
