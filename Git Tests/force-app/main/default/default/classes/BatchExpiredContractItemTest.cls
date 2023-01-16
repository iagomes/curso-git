@isTest
public with sharing class BatchExpiredContractItemTest {
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
        contractItem2.VigenciaFinal__c = Date.today().addDays(-1);
        listContractItem.add(contractItem2);

        insert listContractItem;
    }

    @isTest
    public static void BatchExpiredContractItem() {
        BatchExpiredContractItemSchedule batchSchedule = new BatchExpiredContractItemSchedule();
        batchSchedule.execute(null);
        BatchExpiredContractItemSchedule.scheduleBatch();
    }
}
