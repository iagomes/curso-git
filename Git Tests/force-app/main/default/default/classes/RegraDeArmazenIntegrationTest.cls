@istest
global with sharing class RegraDeArmazenIntegrationTest {
   
    
    @TestSetup
    static void makeData(){
        Integracoes__c integration =  new Integracoes__c(
			Name        = 'ElfaConsultaRegraArmazen',
			Method__c   = 'POST',
			Endpoint__c = 'https://na1.ai.dm-us.informaticacloud.com/active-bpel/rt/P-PROTHEUS-CONSULTA-REGRA',
			User__c     = 'cloud.dev@grupoelfa.com.br',
			Password__c = 'Elf@Cloud'
		);
        insert integration;

        RegraBloqueioArmazem__c regrasUpsert = new RegraBloqueioArmazem__c();
        regrasUpsert.CodigoArmazem__c = '01';
        regrasUpsert.TipoRegra__c = '';               
        regrasUpsert.ExternalId__c= 'LUC00101677517760001140006688';  
        insert regrasUpsert;

        RegraBloqueioArmazem__c regrasUpsert2 = new RegraBloqueioArmazem__c();
        regrasUpsert2.CodigoArmazem__c = '01';
        regrasUpsert2.TipoRegra__c = '';               
        regrasUpsert2.ExternalId__c= 'LUC00101677517760001140023647';  
        insert regrasUpsert2;
       
    }

    global class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;

        public MockHttpResponseGenerator(Boolean isSuccess){
            this.isSuccess = isSuccess;
        }
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"CgcCliente": "67751776000114"}]}');
            res.setStatusCode(this.isSuccess? 201 : 500);

            if (res.getStatusCode() == 201){
                res.setBody('{"regras": [{"codigo": "LUC00101677517760001140023647","descricao": "Teste do Lucas","armazem": "01","TipoBloqueio": "2", "CgcCliente": "67751776000114", "produto": "0023647"}]}');
            } else {
                res.setBody('{"result": "Nenhuma regra encontrada para o cliente!"}');
            }
            return res;
        }
    }

    @isTest
    public static void callRegraArmazen() {

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        RegraDeArmazenIntegration regras = new RegraDeArmazenIntegration();
        RegraDeArmazenIntegration.FlowInputs inputs = new RegraDeArmazenIntegration.FlowInputs();
        inputs.cgcCliente = '67751776000114';
        RegraDeArmazenIntegration.RecalculaRegras(new List< RegraDeArmazenIntegration.FlowInputs>{inputs});
        
        Test.stopTest();
    }
}