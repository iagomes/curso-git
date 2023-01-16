@isTest
global with sharing class ContractHelperTest {

    @TestSetup
    static void makeData(){

        User user = TestUtility.createUser();
        insert user;
        
        List<Account> listAcc = new List<Account>();
        Account acc = TestUtility.createAccPJ();
        acc.ExternalId__c = '04585497000108';
        listAcc.add(acc);

        Account acc2 = TestUtility.createAccPJ();
        acc2.CNPJ__c = '05411870000177';
        acc2.ExternalId__c = '05411870000177';
        listAcc.add(acc2);

        Account acc3 = TestUtility.createAccPJ();
        acc3.CNPJ__c = '05411870000178';
        acc3.ExternalId__c = '05411870000178';
        listAcc.add(acc3);


        Account acc4 = TestUtility.createAccPJ();
        acc4.CNPJ__c = '05411870000278';
        acc4.ExternalId__c = '05411870000278';
        listAcc.add(acc4);

        insert listAcc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        List<Contract> listContract = new List<Contract>();
        Contract con1 = TestUtility.createContract(acc);
        listContract.add(con1);
        
        Contract conOL2 = TestUtility.createContractOL(acc);
        listContract.add(conOL2);
        
        Contract con3 = TestUtility.createContract(acc2);
        con3.TipoRegra__c = 'O';
        listContract.add(con3);
        
        Contract conOL1 = TestUtility.createContractOL(acc2);
        listContract.add(conOL1);

        Contract con4 = TestUtility.createContractOL(acc3);
        listContract.add(con4);

        insert listContract;

        List<ItemContrato__c> listContractItem = new List<ItemContrato__c>();
        ItemContrato__c contractItem1 = TestUtility.createContractItemInApproval(con1, prod);
        listContractItem.add(contractItem1);
        
        ItemContrato__c contractItem2 = TestUtility.createContractItemInApproval(con3, prod);
        listContractItem.add(contractItem2);

        ContractHandler.disableTrigger();
        ContractItemHandler.disableTrigger();
        insert listContractItem;
        ContractItemHandler.enableTrigger();
        ContractHandler.enableTrigger();

        // listContract[0].Status = 'Aprovado';
      
        Integracoes__c integration = TestUtility.createCustomSettingContract();
        insert integration;


        

        Contract con5 = TestUtility.createContractOL(acc4);
        con5.isApprovalProcess__c = true;
        con5.Status = 'Rascunho';
        insert con5;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        IntegrationContractOUT.sendContractToERP(con5.id);         

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        IntegrationContractOUT.sendContractToERP(con5.id);  
        
     
        Approval.ProcessSubmitRequest req =     new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval via form');
        req.setObjectId(con5.Id);
        
        //Step 3:  Submit on behalf of a specific submitter
        req.setSubmitterId(UserInfo.getUserId());
    
        //Step 4:  Submit the record to specific process and skip the criteria evaluation
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new Id[]{UserInfo.getUserId()});

        //Step 5:  Submit the approval request for the bid
        Approval.ProcessResult result = Approval.process(req);

          List<Id> newWorkItemIds = result.getNewWorkitemIds();
        // Instantiate the new ProcessWorkitemRequest object and populate it
        Approval.ProcessWorkitemRequest req2 = 
        new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        // Use the ID from the newly created item to specify the item to be worked
        req2.setWorkitemId(newWorkItemIds.get(0));
        
        // Submit the request for approval
        Approval.ProcessResult result2 =  Approval.process(req2);
     
        // con5.Status = 'Aprovado';
        // update con5;

        // con5.Status = 'Reprovado';
        // update con5;

        
        System.runAs(user) {
            delete con4;

        }
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
    public static void validateStatusFieldTest() {
        List<Contract> listContract = new List<Contract>();
        for (Contract con : [SELECT Id, Name, Status, AccountId, ContractTerm, TipoRegra__c FROM Contract LIMIT 1]) {
            con.Status = 'Aprovado';
            listContract.add(con);
        }      

        // Test when Status changes on Update
        try {
            update listContract;
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
        
        Contract con1 = TestUtility.createContract([SELECT Id FROM Account LIMIT 1][0]);
        con1.Status = 'Reprovado';

        // Test when Status changes on Insert
        try {
            insert con1;
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
    }

    /*@isTest
    public static void checkContractTypeTest() {
        List<Contract> listContract = new List<Contract>();
        Set<Id> setContractId = new Set<Id>();

        for (Contract con : [SELECT Id, Name, Status, AccountId, ContractTerm, TipoRegra__c FROM Contract WHERE TipoRegra__c = 'A' LIMIT 2]) {
            con.isApprovalProcess__c = true;
            con.Status = 'Aprovado';
            listContract.add(con);
        }

        update listContract;
        System.debug('CheckContractTypeTest');
        ContractHelper.checkContractType(listContract);
        System.debug('CheckContractTypeTest 2');

        delete listContract;
    }*/

    @isTest
    public static void updateContractItensStatusTest() {
        List<Contract> listContract = new List<Contract>();
        Set<Id> setContractId = new Set<Id>();
        
        List<Approval.ProcessSubmitRequest> listReq = new List<Approval.ProcessSubmitRequest>();

        for (Contract con : [SELECT Id, Name, Status, AccountId, ContractTerm, TipoRegra__c FROM Contract LIMIT 5]) {            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Envio automático do contrato para processo de aprovação do Pricing.');
            req.setObjectId(con.Id);
            req.setProcessDefinitionNameOrId('Contrato_AprovacaoPricing');
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});

            listReq.add(req);
            listContract.add(con);
        }

        if (!listReq.isEmpty()) {
            // Submit the approval request for the Contract
            ContractHandler.disableTrigger();
            List<Approval.ProcessResult> listResult = Approval.process(listReq);
            ContractHandler.enableTrigger();
        }

        ContractHelper.unlockContract(listContract);

        for (Contract con : listContract) {            
            if (con.TipoRegra__c == 'A') {
                con.Status = 'Aprovado';
            } else if (con.TipoRegra__c == 'O') {
                con.Status = 'Reprovado';
            }
            con.isApprovalProcess__c = true;
        }
        system.debug(listContract);
        ContractHandler.disableTrigger();
        update listContract;
        ContractHandler.enableTrigger();
        ContractHelper.checkContractType(listContract);
    }

    @isTest
    public static void ContractHelperTest() {
        system.debug(ContractHandler.disableTrigger());
        system.debug(ContractHandler.enableTrigger());
        System.assertEquals(false, ContractHandler.disableTrigger());
        System.assertEquals(true, ContractHandler.enableTrigger());
    }

}