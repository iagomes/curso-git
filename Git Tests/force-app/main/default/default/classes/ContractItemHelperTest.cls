@isTest
public with sharing class ContractItemHelperTest {

    @TestSetup
    static void makeData(){
        List<Account> listAcc = new List<Account>();
        Account acc = TestUtility.createAccPJ();
        acc.ExternalId__c = '04585497000108';
        listAcc.add(acc);

        Account acc2 = TestUtility.createAccPJ();
        acc2.CNPJ__c = '05411870000177';
        acc2.ExternalId__c = '05411870000177';
        listAcc.add(acc2);

        insert listAcc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        List<Contract> listContract = new List<Contract>();
        Contract con1 = TestUtility.createContract(acc);
        listContract.add(con1);
        
        Contract con2 = TestUtility.createContract(acc2);
        con2.TipoRegra__c = 'O';
        listContract.add(con2);

        insert listContract;

        List<ItemContrato__c> listContractItem = new List<ItemContrato__c>();
        ItemContrato__c contractItem1 = TestUtility.createContractItem(con1, prod);
        listContractItem.add(contractItem1);
        
        ItemContrato__c contractItem2 = TestUtility.createContractItem(con2, prod);
        listContractItem.add(contractItem2);

        insert listContractItem;        
        
        ItemContrato__c contractError = TestUtility.createContractItem(con1, prod);
        contractError.Status__c = 'Reprovado';
        
        try {
            insert contractError;
        } catch (Exception e) {
            system.debug(e.getMessage());            
        }
    }

    @isTest
    public static void contractItemUpdateAndDeleteTest() {
        List<ItemContrato__c> listContractItem = new List<ItemContrato__c>();
        for (ItemContrato__c contractItem : [SELECT Id, Status__c FROM ItemContrato__c LIMIT 2]) {
            contractItem.VigenciaFinal__c = Date.today().addDays(1);
            listContractItem.add(contractItem);
        }

        update listContractItem;

        ItemContrato__c contractItemError = listContractItem[0];
        contractItemError.Status__c = 'Aprovado';
        
        try {
            update contractItemError;
        } catch (Exception e) {
            system.debug(e.getMessage());
        }

        delete listContractItem;

        ContractItemHandler.disableTrigger();
        ContractItemHandler.enableTrigger();
    }

    @isTest
    public static void getProcessRequestTest() {
        User newUser         = TestUtility.createUser();
        insert newUser;
        Account newAccount   = TestUtility.createAccount();
        insert newAccount;
        Contract newContract = TestUtility.createContract(newAccount);
        insert newContract;

        System.assertNotEquals(null, ContractItemHelper.getProcessRequest(newContract.Id, newUser.Id), 'getProcessRequestTest');
    }
}
