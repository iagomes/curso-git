@isTest
global class IntegrationContractOUTTest {
    @TestSetup
    static void makeData(){
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        List<Contract> listContract = new List<Contract>();
        Contract con1 = TestUtility.createContract(acc);
        listContract.add(con1);
        
        Contract con2 = TestUtility.createContractOL(acc);
        listContract.add(con2);

        ContractHandler.disableTrigger();
        insert listContract;
        ContractHandler.enableTrigger();

        List<ItemContrato__c> listContractItem = new List<ItemContrato__c>();
        ItemContrato__c contractItem1 = TestUtility.createContractItemApproved(con1, prod);
        listContractItem.add(contractItem1);
        
        ItemContrato__c contractItem2 = TestUtility.createContractItemApproved(con2, prod);
        listContractItem.add(contractItem2);

        ContractHandler.disableTrigger();
        ContractItemHandler.disableTrigger();
        insert listContractItem;
        ContractItemHandler.enableTrigger();
        ContractHandler.enableTrigger();

        Integracoes__c integration = TestUtility.createCustomSettingContract();
        insert integration;
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
            res.setBody('{"CgcCliente": "","TipoRegra": "","CodSalesForce": "","observacoes": "","itens": [{"produto": "","ProdutoElfa": "","VigenciaInicial": "AAAAMMDD","VigencialFinal": "AAAAMMDD","lote": "","validade": "","preco": 0.00,"PrecoMinimo": 0.00,"PercDesconto": 0.0}]}');
            res.setStatusCode(this.isSuccess? 201 : 500);

            if (res.getStatusCode() == 201){
                res.setBody('{"result": "Contrato incluido na fila de processamento!!","incluido": true}');
            } else {
                res.setBody('{"result": "Contrato não incluido na fila de processamento!!","incluido": false}');
            }
            return res;
        }
    }

    @isTest
    public static void sendContractToERPTest(){        
        List<Contract> listContract = [SELECT Id, Name FROM Contract LIMIT 2];

        Test.startTest();            

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationContractOUT.sendContractToERP(listContract[0].id);         

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        IntegrationContractOUT.sendContractToERP(listContract[1].id);      

        Test.stopTest();        

        System.enqueueJob(new IntegrationContractOUTQueueable(0, new List<Id>{listContract[0].id}));
    }
}