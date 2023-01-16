@RestResource(urlMapping='/upsertPortalOrder/v1/*')
global class IntegrationPortalOrderIN {

    global static final Id MOTHERORDER_RECORDTYPE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('PedidoMae').getRecordTypeId();

    global static final Map<String, String> ERROR_MAP = new Map<String, String>{
        'OpportunityNULL' => 'Orçamento não encontrado na base de dados do SalesForce.\n',
        'CnpjOppDiff' => 'Inconsistências encontradas no Cnpj, orçamento referenciando outro cliente.\n',
        'OppLineItemMissing' => 'Não foi encontrado OpportunityLineItem relacionado ao item.\n',
        'QItemMissing' => 'O item da cotação não foi encontrado.\n',
        'QuantityInconsistence' => 'Foram encontradas inconsistencias na quantidade do item.\n'
    };// inserir labels

    @HttpPost
    global static void upsertOrder() {

        StandardResponse resp = new StandardResponse();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, OrderItem> orderItemMapByQItem = new Map<String, OrderItem>();
        List<QuoteItem__c> quoteItemStatusUpdate = new List<QuoteItem__c>();
        List<ItemResult> resultListItem = new List<ItemResult>();
        Decimal totalAmount = 0;
        Opportunity opp;
        Order newOrder;
        String requestBody = req.requestBody.toString();
        Savepoint sp;
        try {
            OrderINData orderData = new OrderINData().deserialize(requestBody);
            opp = getOpportunity(orderData.idPortal);
            Map<Id, QuoteItem__c> qItemMap = getQuoteItemMap(orderData);
            newOrder = orderData.buildOrder(opp);

            for(OrderItemINData orderItemData : orderData.itensConfirmados){
                OrderItem newOrderItem = orderItemData.buildOrderItem(newOrder, qItemMap.get(orderItemData.idSalesforce));
                totalAmount += newOrderItem.PrecoTotal__c != null ? newOrderItem.PrecoTotal__c : 0;
                orderItemMapByQItem.put(orderItemData.idSalesforce, newOrderItem);
            }

            sp = Database.setSavepoint();
            
            upsert newOrder Order.ChaveUnica__c;
            resp.setData('PedidoId', newOrder.Id);
            if(newOrder.MensagemErroIntegracao__c != ''){
                resp.addError(newOrder.MensagemErroIntegracao__c.replaceAll('\\n',' '), '201');
            }

            List<Database.upsertResult> orderItemResultList = Database.upsert(orderItemMapByQItem.values(), OrderItem.ExternalId__c, false);
            Boolean hasErrorItem = false;
            List<ItemResult> itemsResult = new List<ItemResult>();
            for(OrderItemINData orderItemData : orderData.itensConfirmados){
                OrderItem newOrderItem = orderItemMapByQItem.get(orderItemData.idSalesforce);
                QuoteItem__c qItem = qItemMap.get(newOrderItem.QuoteItem__c);
                if(newOrderItem.Id == null){
                    itemsResult.add(new ItemResult(qItem.Id, false, 'OrderItem was not created'));
                    hasErrorItem = true;
                    continue;
                }else{
                    itemsResult.add(new ItemResult(qItem.Id, true, 'OrderItem was created with id: ' + newOrderItem.Id));
                }
                if(qItem == null || qItem.Status__c == 'Aprovado'){
                    continue;
                }
                quoteItemStatusUpdate.add(new QuoteItem__c(Id = qItem.Id, Status__c = 'Aprovado'));
            }
            
            resp.setData('itemsResult', itemsResult);
            if(hasErrorItem){
                for(Database.UpsertResult upResult : orderItemResultList){
                    if(!upResult.isSuccess()){
                        resp.setData('itemErrorList-'+upResult.Id, upResult.getErrors());
                    }
                }
            }

            if(opp != null && opp.StageName != 'Gerar Pedido'){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id, StageName = 'Gerar Pedido');
                update oppToUpdate;
            }

            if(!quoteItemStatusUpdate.isEmpty()){
                update quoteItemStatusUpdate;
            }

        } catch (Exception ex) {
            if(sp != null){
                Database.rollback(sp);
            }
            resp.addError(ExceptionUtils.debug(ex));
        }
        String responseBody = resp.toJSON();
        res.responseBody = Blob.valueOf(responseBody);
        
        IntegrationUtils.WSLog('Pedido do Portal', 'Inbound', requestBody.normalizeSpace(), responseBody, resp.code != '200' && resp.code != '201', '/upsertPortalOrder/v1/*', resp.code);

        try {
            if(opp != null){
                SalesmanNotificationPortal.orderInNotification(
                    newOrder.Id,
                    opp.Id,
                    new List<String>(orderItemMapByQItem.keySet()),
                    totalAmount
                );
            }

        } catch (Exception ex) {
            ExceptionUtils.debug(ex);
        }
    }

    public static Opportunity getOpportunity(String idPortal){
        List<Opportunity> oppList = [
            SELECT Id, CanalEntrada__c, Pricebook2Id, CondicaoPagamento__c, StageName, DataVencimento__c,
            ExternalPortal__c, DataPrevistaEntrega__c, AccountId, Account.CNPJ__c, Account.Name
            FROM Opportunity
            WHERE ExternalPortal__c =: idPortal Limit 1
        ];
        return oppList.size() > 0 ? oppList[0] : null;
    }
    
    public static Map<Id, QuoteItem__c> getQuoteItemMap(OrderINData orderData){
        if(orderData.itensConfirmados != null){
            Set<String> qItemIdSet = new Set<String>();
            for(OrderItemINData orderItemData : orderData.itensConfirmados){
                qItemIdSet.add(orderItemData.idSalesforce);
            }

            return new Map<Id, QuoteItem__c>([
                SELECT Id, OpportunityLineItem__c, OpportunityLineItem__r.PriceBookEntryId, 
                OpportunityLineItem__r.CentroDistribuicao__c, OpportunityLineItem__r.Product2Id, 
                OpportunityLineItem__r.ValorPortal__c, OpportunityLineItem__r.FatorConversao__c,
                OpportunityLineItem__r.TipoConversao__c, OpportunityLineItem__r.UnitPrice,
                OpportunityLineItem__r.Quantity, VendedorRespondeu__c, CNPJCD__c, Status__c,
                OpportunityLineItem__r.QuantidadePortal__c
                FROM QuoteItem__c
                WHERE Id IN :qItemIdSet
            ]);
        }
        else{
            return new Map<Id, QuoteItem__c>();
        }
    }

    private static String getChaveUnicaPedido(String chaveUnica){
        String result;
        List<Order> lstOrders = [SELECT Status, Id, ChaveUnica__c FROM Order WHERE ChaveUnica__c LIKE: (chaveUnica + '%') ORDER BY CreatedDate DESC];
        for(Integer i = 0 ; i < lstOrders.size() ; i ++){
            if(lstOrders[i].Status == 'Em digitação'){
                result = lstOrders[i].ChaveUnica__c;
                break;
            }
        } 

        if(String.isBlank(result)){
            if(!lstOrders.isEmpty()){
                result = lstOrders[0].ChaveUnica__c + '1';
            } else {
                result = chaveUnica;
            }
        }

        return result;
    }

    private static Decimal getConversionFactor(String ConversionType, Decimal conversionFactor){
        if(conversionFactor > 0 && ConversionType == 'MULTIPLICAR'){
            return conversionFactor;
        }
        
        if(conversionFactor > 0 && ConversionType == 'DIVIDIR'){
            return 1/conversionFactor;
        }

        return 1;
    }

    global class OrderINData {
    
        global String idPortal {get;set;}
        global String integradoraId {get;set;}
        global String integradora {get;set;}
        global Customer cliente {get;set;}
        global String cnpjCd {get;set;}
        global PaymentCondition condicaoPagamento {get;set;}
        global String observacao {get;set;}
        global String termosCondicoes {get;set;}
        global String enderecoEntrega {get;set;}
        global List<ExtraField> campoExtra {get;set;}
        global String nomeContato {get;set;}
        global List<OrderItemINData> itensConfirmados {get;set;}

        global OrderINData deserialize(String requestBody){
        
            OrderINData orderData = (OrderINData)JSON.deserialize(requestBody, OrderINData.class);
            Map<FieldType, Object> requiredFields = orderData.getRequiredFieldMap();
            for(FieldType field : requiredFields.keySet()){
                if(requiredFields.get(field) == null){
                    throw new CustomException('O campo:\''+field.Name+'\' é obrigatório');
                }
                if(field.Type == 'String' && String.isBlank((String)requiredFields.get(field))){
                    throw new CustomException('O campo:\''+field.Name+'\' é obrigatório');
                }
            }
            return orderData;
        }

        global Order buildOrder(Opportunity opp){

            Order newOrder = new Order();

            String chaveUnica = this.integradoraId + this.integradora + this.idPortal;
            newOrder.ChaveUnica__c = getChaveUnicaPedido(chaveUnica);
            newOrder.Idportalcotacoes__c = this.integradoraId;
            newOrder.CanalEntrada__c = this.integradora;
            newOrder.AprovadoComercial__c = false;
            newOrder.AprovadoPricing__c = false;
            newOrder.NecessitaAprovacaoComercial__c = false;
            newOrder.NecessitaAprovacaoPricing__c = false;
            newOrder.EnviarAprovacao__c = false;
            newOrder.EffectiveDate = Date.today();
            newOrder.Status = 'Em digitação';
            newOrder.Type = 'PedidoVenda';
            newOrder.MensagemErroIntegracao__c = '';
            newOrder.RecordTypeId = MOTHERORDER_RECORDTYPE;

            if(opp != null){

                newOrder.OpportunityId = opp.Id;
                newOrder.CanalEntrada__c = opp.CanalEntrada__c;
                newOrder.Pricebook2Id = opp.Pricebook2Id;
                newOrder.CondicaoPagamento__c = opp.CondicaoPagamento__c;
                newOrder.ExternalPortal__c = opp.ExternalPortal__c;
                newOrder.DataEntrega__c = opp.DataPrevistaEntrega__c;
            }
            else{

                newOrder.MensagemErroIntegracao__c += ERROR_MAP.get('OpportunityNULL');
            }

            newOrder.Account = new Account(CNPJ__c = this.cliente.cnpj);
            newOrder.CamposExtras__c = StringUtils.cutByFieldLength(Order.CamposExtras__c, JSON.serialize(this.campoExtra));
            newOrder.EnderecoEntrega__c = StringUtils.cutByFieldLength(Order.EnderecoEntrega__c, this.enderecoEntrega);
            newOrder.Observacao__c = StringUtils.cutByFieldLength(Order.Observacao__c, this.observacao);
            newOrder.TermosCondicoes__c = StringUtils.cutByFieldLength(Order.TermosCondicoes__c, this.termosCondicoes);
                        
            if(opp != null && this.cliente.cnpj != opp.Account?.CNPJ__c){

                newOrder.MensagemErroIntegracao__c += ERROR_MAP.get('CnpjOppDiff');
            }
            return newOrder;
        }

        global Map<FieldType, Object> getRequiredFieldMap(){
            return new Map<FieldType, Object>{
                new FieldType('integradoraId','String') => this.integradoraId,
                new FieldType('idPortal','String') => this.idPortal,
                new FieldType('cliente','Object') => this.cliente,
                new FieldType('cliente.cnpj','String') => this.cliente?.cnpj
            };
        }
    }
    
    global class Customer {

        global String cnpj {get;set;}
    }

    global class PaymentCondition {

        global String id {get;set;}
        global String nome {get;set;}
    }

    global class ExtraField {

        global String nome {get;set;}
        global String valor {get;set;}
    }
    
    global class OrderItemINData {

        global String idPortal {get;set;}
        global String cnpjCd {get;set;}
        global String idItemConfirmado {get;set;}
        global String idSalesforce {get;set;}
        global Decimal quantidade {get;set;}
        global List<ExtraField> campoExtra {get;set;}
        global List<DeliveryProgram> programacaoEntrega {get;set;}
        global Integer sequencia {get;set;}
        global String idConfirmacao {get;set;}
        //preco
        //quantidadeEmbalagem
        //codigoproduto

        global OrderItem buildOrderItem(Order newOrder, QuoteItem__c qItem){
            OrderItem newOrderItem = new OrderItem();
            newOrderItem.Description = '';
            newOrderItem.Order = new Order(ChaveUnica__c = newOrder.ChaveUnica__c);
            newOrderItem.ExternalId__c = newOrder.ChaveUnica__c + this.idSalesforce;
            newOrderItem.CamposExtras__c = JSON.serialize(this.campoExtra);
            newOrderItem.ProgramacaoEntrega__c = JSON.serialize(this.programacaoEntrega);
            newOrderItem.SequenciaOC__c = String.valueOf(this.sequencia);

            if(qItem != null){
                newOrderItem.QuoteItem__c = qItem.Id;
                newOrderItem.cnpjCD__c = qItem.CNPJCD__c;
                if(String.isNotBlank(qItem.OpportunityLineItem__c)){
                    Decimal conversionFactor = getConversionFactor(qItem.OpportunityLineItem__r.TipoConversao__c, qItem.OpportunityLineItem__r.FatorConversao__c);
                    Decimal quantity;
                    if(this.quantidade > 0){
                        quantity = this.quantidade * conversionFactor;
                        newOrderItem.Quantity = quantity.setScale(0, RoundingMode.HALF_UP) > 0 ? quantity.setScale(0, RoundingMode.HALF_UP) : 1;
                    }
                    else{
                        newOrderItem.Quantity = qItem.OpportunityLineItem__r.Quantity;
                        newOrderItem.Description += ERROR_MAP.get('QuantityInconsistence');
                    }
                    newOrderItem.UnitPrice = qItem.OpportunityLineItem__r.UnitPrice;
                    newOrderItem.ValorCx__c = qItem.OpportunityLineItem__r.UnitPrice;
                    newOrderItem.ValorUn__c = qItem.OpportunityLineItem__r.UnitPrice;
                    newOrderItem.PricebookEntryId = qItem.OpportunityLineItem__r.PricebookEntryId;
                    newOrderItem.CentroDistribuicao__c = qItem.OpportunityLineItem__r.CentroDistribuicao__c;
                    newOrderItem.Product2Id = qItem.OpportunityLineItem__r.Product2Id;
                    newOrderItem.Vendedor__c = qItem.VendedorRespondeu__c;
                    newOrderItem.QuantityChanged__c = (qItem.OpportunityLineItem__r.QuantidadePortal__c != this.quantidade || quantity != newOrderItem.Quantity);
                }
                else{
                    newOrderItem.Description += ERROR_MAP.get('OppLineItemMissing');
                }
            }
            else{
                newOrderItem.Description += ERROR_MAP.get('QItemMissing');
            }

            if(newOrderItem.Quantity != null && newOrderItem.UnitPrice != null){
                newOrderItem.PrecoTotal__c = newOrderItem.Quantity * newOrderItem.UnitPrice;
            }
            return newOrderItem;
        }
    }

    global class DeliveryProgram {

        global String data {get;set;}
        global String quantidade {get;set;}
    }
/****************************************************************/
    global class FieldType{
        global String Name {get;set;}
        global String Type {get;set;}
        
        global FieldType(String Name, String Type){
            this.Name = Name;
            this.Type = type;
        }
    }
    global class ItemResult{
        global String idSalesforce {get;set;}
        global Boolean success {get;set;}
        global String message {get;set;}
        
        global ItemResult(String idSalesforce, Boolean success, String message){
            this.idSalesforce = idSalesforce;
            this.success = success;
            this.message = message;
        }
    }
}
