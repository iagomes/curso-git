public without sharing class ChatBot {
    
    @InvocableVariable(required=true)
    public String cnpj;
    
    @InvocableMethod(label='Create a case')
    public static List<String> createCase(List<String> cnpj) {
        
        try {
            
            Contact con = [SELECT Id, Account.Id, Email FROM Contact WHERE Account.CNPJ__c =: cnpj LIMIT 1];
            Group gr = [SELECT Id FROM Group WHERE DeveloperName =: 'AtendimentoAoClienteQueue'];
            
            Case c = new Case(
                AccountId = con.Account.Id,
                ContactId = con.Id,
                Status = 'New',
                AnaliseDoCaso__c = 'Procedente',
                Origin = 'Chatbot',
                Priority = 'Medium',
                SuppliedEmail = con.Email,
                ToAddress__c = con.Email,
                Type = 'Solicitação',
                Razao__c = 'Cadastro',
                OwnerId = gr.Id
            );
            
            insert c;
            
            c = [SELECT CaseNumber 
                 FROM Case WHERE Id=: c.Id];
            
            return new String[]{ c.CaseNumber};
                
                } catch (Exception ex) {
                    LogIntegration__c log = new LogIntegration__c(
                        RecordTypeId      = Schema.SObjectType.LogIntegration__c.getRecordTypeInfosByDeveloperName().get('Chatbot').getRecordTypeId(),
                        Integration__c    = ChatBot.class.getName(),
                        Status__c         = 'ERROR',
                        ExecuteDate__c    = System.today(),
                        Message__c = ex.getMessage() + ' ' + ex.getStackTraceString()
                    );
                }
        
        return null;
    }
    
    @AuraEnabled
    public static String fetchBase64File(Map<String, Object> params) {
        
        try {
            
            String customerId = (String)params.get('customerId');
            String invoiceNumber = (String)params.get('invoiceNumber');
            String documentType = (String)params.get('documentType');
            String orderNumber = (String)params.get('orderNumber');
            
            Map<String, Object> body;
            
            switch on documentType {
                when 'invoice' {		
                    return getInvoice(customerId, invoiceNumber);            
                }	
                when 'paymentSlip' {	
                    return getPaymentSlip(customerId, orderNumber);
                }
            }        
            
        } catch (Exception ex) {
            LogIntegration__c log = new LogIntegration__c(
                RecordTypeId      = Schema.SObjectType.LogIntegration__c.getRecordTypeInfosByDeveloperName().get('Chatbot').getRecordTypeId(),
                Integration__c    = ChatBot.class.getName(),
                Status__c         = 'ERROR',
                ExecuteDate__c    = System.today()
            );
            String message = ex.getMessage() + ' ' + ex.getStackTraceString();
            if (message.length() >= 255) {
                message = message.substring(0, 254);
            }
            log.Message__c = message;
            insert log;

            return log.Id;
        }
        
        return null;
    }  
    
    private static String getInvoice(String customerId, String invoiceNumber) {
        
        String likeCondition = '%' + invoiceNumber + '%';
        NotasFiscais__c invoice = [ SELECT Pedido__r.CNPJCD__c, SerieNota__c, ExternalId__c
                                   FROM NotasFiscais__c
                                   WHERE ExternalId__c LIKE :likeCondition];
                        
        String path = '/P-PROTHEUS-PORT-CLIENTE-DANFE-XML';
        Map<String, String> body = new Map<String, String> {
            'cnpj_cd' => invoice.Pedido__r.CNPJCD__c,
                'Nota' => invoice.ExternalId__c.substring(5, 14),
                'Serie' => invoice.SerieNota__c,
                'tipo' => 'D'
                };
                    
                    
                    Map<String, Object> desResponse = (Map<String, Object>)JSON.deserializeUntyped(requestData(path, body));
        
        return (String)desResponse.get('danfe');
        
    }
    
    private static String getPaymentSlip(String customerId, String orderNumber) {
        
        String path = '/P-SFDC-Consulta-TitulosAbertos';
        Map<String, String> body = new Map<String, String> {
            'CGC' => customerId
                };
                    
		OpenPayments payments = (OpenPayments)JSON.deserialize(requestData(path, body), OpenPayments.class);

        Order order = [SELECT Numero_da_Nota_Fiscal_Normalizado__c FROM Order WHERE CNPJ__c=: customerId AND NumeroPedidoCliente__c =: orderNumber AND PedidoPai__c <> NULL LIMIT 1];

        OpenPayment openPayment;
        for (OpenPayment op : payments.TituloAberto) {
            if ((String.isNotBlank(order.Numero_da_Nota_Fiscal_Normalizado__c) && order.Numero_da_Nota_Fiscal_Normalizado__c.contains(op.NUM)) || op.PEDIDO == orderNumber) {
                openPayment = op;
                break;
            }
        }

        if (openPayment == null) {
            return null;
        }
        
        path = '/P-SFDC-BOLETOS';
        body = new Map<String, String> {
            'cnpj_cd' => openPayment.CGC_CD,
                'NumeroBoleto' => openPayment.NUM,
                'prefixo' => openPayment.PREFIXO,
                'tipo' => openPayment.TIPO,
                'parcela' => openPayment.PARCELA
                };
                    
		Map<String, Object> desResponse = (Map<String, Object>)JSON.deserializeUntyped(requestData(path, body));   
        
        
        return (String)desResponse.get('boleto');
        
    }  
    
    private static String requestData(String path, Map<String, String> body) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DanfeSync' + path);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Accept-Encoding', 'gzip');
        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        
        if (res.getStatusCode() == 200) {
            
            Map<String, Object> desResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            
            if (desResponse.containsKey('error')) {
                throw new ChatbotException(res.getBody());
            }
            
            return res.getBody();
            
        } else {
            throw new ChatbotException(res.getBody());
        }
        
    }
    
    private class ChatbotException extends Exception {}
    
    private class OpenPayments {
        List<OpenPayment> TituloAberto;
    }
    
    private class OpenPayment {
        String NUM;
        String CLIENTE;
        String CGC;
        String NUMBCO;
        String PARCELA;
        String PEDIDO;
        String PREFIXO;
        String TIPO;
        String CGC_CD;     
    }
    
}