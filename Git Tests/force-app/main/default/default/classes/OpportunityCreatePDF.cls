public without sharing class OpportunityCreatePDF {
    
    @InvocableMethod(label='Generate PDF' description='Button to generate the opportunity PDF')
    public static List<String> flowCreatePDF(List<FlowInputs> flowInputsList) {

        String oppId = null;
        String pdf = null;
        String prodCode = '';
        for (FlowInputs flow : flowInputsList) {
            oppId = flow.opportunityId;
            pdf = flow.pdfChoice;
            prodCode = flow.productCode;
        }

        List<String> prodCodeList = prodCode.split(',');
        System.debug('prodCodeList => '+ prodCodeList);
        Map<String, Product2> prodCodeToIdMap = new Map<String, Product2>();
        for (Product2 prod : [SELECT Id, ExternalId__c, Description, CategoriaComercial__c, UnidadeMedida__c FROM Product2 WHERE ExternalId__c IN: prodCodeList]) {
            prodCodeToIdMap.put(prod.ExternalId__c, prod);
        }
        System.debug('prodCodeToIdMap => '+ prodCodeToIdMap);

        Opportunity contextOpportunity = null;
        for (Opportunity o : [SELECT Id, Name, ContatoOrcamento__c, CloseDate, Account.CNPJ__c, Account.CPF__c, Pricebook2.ExternalId__c, CondicaoPagamento__r.ExternalId__c FROM Opportunity WHERE Id = :oppId]) {
            contextOpportunity = o;
        }

        Boolean hasPermissionERB = false;
        for (PermissionSetAssignment pSet : [SELECT Id, PermissionSet.Name, Assignee.Name, AssigneeId FROM PermissionSetAssignment WHERE Assignee.Username =: UserInfo.getUsername() AND PermissionSet.Name =: 'UsuarioERB']) {
            hasPermissionERB = true;
        }

        // List<RecomendacaoCotacao__c> recommendationQuoteList = [SELECT Id FROM RecomendacaoCotacao__c WHERE Cotacao__r.OpportunityId = :oppId];
        // if (recommendationQuoteList.size() > 0) {
        //     hasPermissionERB = false;
        // }

        List<Object> malhaResult = null;
        if (pdf == 'ElfaQuoteRecommendationTemplate' && hasPermissionERB) {
            malhaResult = OrderScreenController.getMalha(contextOpportunity.Account.CNPJ__c != null ? contextOpportunity.Account.CNPJ__c : contextOpportunity.Account.CPF__c, prodCode, true, contextOpportunity.Pricebook2.ExternalId__c, contextOpportunity.CondicaoPagamento__r.ExternalId__c, false);
            System.debug(malhaResult);
        }        
        
        Quote newQuote = new Quote(
            name           = contextOpportunity.name,
            OpportunityId  = contextOpportunity.Id,
            ContactId      = contextOpportunity.ContatoOrcamento__c,
            ExpirationDate = contextOpportunity.CloseDate
        );
        insert newQuote;

        List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();

        List<OpportunityLineItem> newOppLineItemList = new List<OpportunityLineItem>();

        for (OpportunityLineItem oLineItem : [SELECT Id, CategoriaComercial__c, CentroDistribuicao__c, ProductCode, ServiceDate, Discount, Description, 
                                                ForaMalha__c, Fornecedor__c, ItemCampanha__c, JustificativaDesconto__c, Lote__c, MargemAlvo__c, MargemAtual__c, 
                                                Name, NumeroAnvisa__c, OpportunityId, ListPrice, UnitPrice, TotalPrice, PrincipioAtivo__c, Product2Id, Quantity, 
                                                QuantidadeUn__c, ScoreAlvo__c, ScoreAtual__c, Subtotal, Temperatura__c, ValidadeMinima__c, ValorCx__c, ValorUn__c,
                                                ValorTotal__c, Vendedor__c, Product2.FatorConversao__c, Product2.Fornecedor__r.Name, Product2.ProductCode,
                                                Product2.UnidadeMedida__c, Product2.Name, PricebookEntryId, CNPJCD__c, Product2.CategoriaComercial__c
                                                FROM OpportunityLineItem WHERE OpportunityId = :contextOpportunity.Id]) {
            
            QuoteLineItem quoteLineItem            = new QuoteLineItem();
            quoteLineItem.CentroDistribuicao__c    = oLineItem.CentroDistribuicao__c;
            quoteLineItem.CodigoItem__c            = oLineItem.Product2.ProductCode;
            quoteLineItem.ServiceDate              = oLineItem.ServiceDate;
            quoteLineItem.Discount                 = oLineItem.Discount;
            quoteLineItem.Description              = oLineItem.Description;
            quoteLineItem.Fabricante__c            = oLineItem.Product2.Fornecedor__r.Name;
            quoteLineItem.FatorConversao__c        = oLineItem.Product2.FatorConversao__c;
            quoteLineItem.Product2Id               = oLineItem.Product2Id;
            quoteLineItem.QuoteId                  = newQuote.Id;
            quoteLineItem.PricebookEntryId         = oLineItem.PricebookEntryId;
            quoteLineItem.Produto__c               = oLineItem.Product2.name;
            quoteLineItem.Quantity                 = oLineItem.Quantity;
            quoteLineItem.UnidadeMedida__c         = oLineItem.Product2.UnidadeMedida__c;
            quoteLineItem.ValorCx__c               = oLineItem.ValorCx__c;
            quoteLineItem.UnitPrice                = oLineItem.UnitPrice;
            quoteLineItem.CNPJCD__c                = oLineItem.CNPJCD__c;
            quoteLineItem.OpportunityLineItemId    = oLineItem.Id;

            if (oLineItem.Product2.CategoriaComercial__c == 'S' || oLineItem.Product2.CategoriaComercial__c == 'G') {
                quoteLineItem.PrincipioAtivo__c    = oLineItem.PrincipioAtivo__c;
            }

            quoteLineItemList.add(quoteLineItem);
        }

        if (!quoteLineItemList.isEmpty()) {
            insert quoteLineItemList;
        }

        if (pdf == 'ElfaQuoteRecommendationTemplate' && hasPermissionERB) {
            List<RecomendacaoCotacao__c> quoteRecommendationList = new List<RecomendacaoCotacao__c>();
            for (Object obj: malhaResult) {
                MalhaObject malhaObj = (MalhaObject) JSON.deserialize(JSON.serialize(obj), MalhaObject.class);
                System.debug('malhaObj: ' + malhaObj);
                if (malhaObj != null && malhaObj.cds != null) {
                    for (CdObject cdObj : malhaObj.cds) {
                        if (cdObj.saldo == 0) 
                            continue;
                        RecomendacaoCotacao__c quoteRecommendation = new RecomendacaoCotacao__c();
                        quoteRecommendation.Name = malhaObj.codprotheus;
                        quoteRecommendation.Cotacao__c = newQuote.Id;
                        quoteRecommendation.Estoque__c = cdObj.saldo;
                        quoteRecommendation.ValorUnitario__c = cdObj.preco;
                        quoteRecommendation.CentroDistribuicao__c = cdObj.filial;
                        quoteRecommendation.Produto__c = prodCodeToIdMap.containsKey(malhaObj.codprotheus) ? prodCodeToIdMap.get(malhaObj.codprotheus).Id : null;                        
                        quoteRecommendation.UnidadeMedida__c = prodCodeToIdMap.containsKey(malhaObj.codprotheus) ? prodCodeToIdMap.get(malhaObj.codprotheus).UnidadeMedida__c : null;                        
                        System.debug('recomendação => ' + quoteRecommendation);
                        quoteRecommendationList.add(quoteRecommendation);
                        break;
                    }                    
                }
            }

            if (!quoteRecommendationList.isEmpty()) {
                insert quoteRecommendationList;
            }
        }

        getQuoteTemplate(newQuote.id, pdf);
        
        return new List<String>{newQuote.id};
    }

    @AuraEnabled
    public static void getQuoteTemplate(Id recordId, String pdf) {
        insertQuoteTemplate(recordId, pdf);
    }

    @future(callout=true)
    public static void insertQuoteTemplate(Id recordId, String pdf) {

        TemplatePDF__c template = TemplatePDF__c.getValues(pdf);
        String templateId = template.Id__c;

        PageReference pr = new PageReference('/quote/quoteTemplateDataViewer.apexp?id=' + recordId + '&summlid=' + templateId); 

        QuoteDocument qd = new QuoteDocument(); 
        Blob b = !Test.isRunningTest() ? pr.getContentAsPDF() : Blob.valueOf('Test');

        qd.Document = b;
        qd.QuoteId = recordId;
        insert qd;

        Quote contextQuote = null;
        for (Quote quote : [SELECT Id, Opportunity.Name, OpportunityId/*, ContatoOrcamento__c, ContatoOrcamento__r.Email*/ FROM Quote WHERE Id = :recordId]) {
            contextQuote = quote;
        }

        ContentVersion ctVersion    = new ContentVersion();
        String attName = 'Orçamento' + contextQuote.Opportunity.Name +'.pdf';
        ctVersion.Title             = attName;
        ctVersion.PathOnClient      = attName;
        ctVersion.VersionData       = b;
        insert ctVersion;

        ContentDocumentLink cdl     = new ContentDocumentLink();
        cdl.ContentDocumentId       = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: ctVersion.Id].ContentDocumentId;
        cdl.LinkedEntityId          = contextQuote.OpportunityId;
        cdl.ShareType               = 'V';
        cdl.Visibility              = 'AllUsers';
        insert cdl;

        // Id templateEmailId;
        // for (EmailTemplate e : [SELECT Id, Name, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'EmailGeracaoPDF' LIMIT 1]) {
        //     templateEmailId = e.Id;
        // }

        // List<Messaging.singleEmailMessage> messageList = new List<Messaging.singleEmailMessage>();
        // Messaging.singleEmailMessage ownerMessage = new Messaging.singleEmailMessage();
        // Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        // efa.setFileName(attName);
        // efa.setBody(b);
       
        // ownerMessage.setToAddresses(new List<String>{contextQuote.ContatoOrcamento__r.Email});
        // ownerMessage.setTemplateId(templateEmailId);
        // ownerMessage.setTargetObjectId(contextQuote.ContatoOrcamento__c);
        // ownerMessage.setWhatId(contextQuote.OpportunityId);
        // ownerMessage.setSaveAsActivity(false);
        // ownerMessage.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        // messageList.add(ownerMessage);

        // if(!messageList.isEmpty()) {
        //     Messaging.sendEmail(messageList);
        // } 
    }
    
    public class FlowInputs{
    
        @InvocableVariable
        public String opportunityId;
        
        @InvocableVariable
        public String pdfChoice;

        @InvocableVariable
        public String productCode;
    }

    public class MalhaObject {
    
        public List<CdObject> cds;
        public String codprotheus;
        public String ean;
    }

    public class CdObject {
    
        public Decimal aliquota;
        public String  foramalha;
        public String  prioridade;
        public String  cnpj;
        public Decimal saldo;
        public Decimal custo;
        public String  cd;
        public String  filial;
        public String  tipopreco;
        public Decimal preco;
        public String  BloqRegionalizacao;
        public String  laboratorio;
        // public List<Object> range;
    }
}
