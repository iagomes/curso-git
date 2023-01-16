@isTest
public with sharing class SetorizacaoHelperTest {

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

        User us = TestUtility.createUser();
        system.debug(us);
        insert us;

        List<Setorizacao__c> listSetorizacao = new List<Setorizacao__c>();

        Setorizacao__c setValid1 = TestUtility.createSetorizacaoWithValidData(acc, us);
        setValid1.ExternalId__c = '001';
        listSetorizacao.add(setValid1);
        system.debug(setValid1);

        Setorizacao__c setValid2 = TestUtility.createSetorizacaoWithValidData(acc2, us);
        setValid2.ExternalId__c = '002';
        listSetorizacao.add(setValid2);
        system.debug(setValid2);

        Setorizacao__c setInvalid1 = TestUtility.createSetorizacaoWithInvalidData(acc, us);
        setInvalid1.ExternalId__c = '003';
        listSetorizacao.add(setInvalid1);
        system.debug(setInvalid1);

        insert listSetorizacao;
    }

    @isTest
    public static void addAccTeamMemberBySectorizationTest() {

        List<Setorizacao__c> listSetorizacao = [SELECT Id, Conta__c, Vendedor__c, Gerente__c, DataInicial__c, DataFinal__c FROM Setorizacao__c WHERE ExternalId__c != '003'];

        SetorizacaoHelper.addAccTeamMemberBySectorization(listSetorizacao);
    }

    
    @isTest
    public static void upAccTeamMemberBySectorizationTest() {
        Setorizacao__c setValid1 = new Setorizacao__c();
        Setorizacao__c setValid2 = new Setorizacao__c();
        Setorizacao__c setInvalid1 = new Setorizacao__c();


        for (Setorizacao__c setorizacao : [SELECT Id, Conta__c, Vendedor__c, DataInicial__c, DataFinal__c, ExternalId__c FROM Setorizacao__c]) {
            if (setorizacao.ExternalId__c == '001') {
                setValid1 = setorizacao;
            }
            if (setorizacao.ExternalId__c == '002') {
                setValid2 = setorizacao;
            }
            if (setorizacao.ExternalId__c == '003') {
                setInvalid1 = setorizacao;
            }
        }

		setInvalid1.DataInicial__c = Date.Today().addDays(-1);
		setInvalid1.DataFinal__c   = Date.Today().addDays(1);
        
		setValid1.DataInicial__c = Date.Today().addDays(-5);
		setValid1.DataFinal__c   = Date.Today().addDays(-2);

        setValid2.DataFinal__c = null;
        
        List<Setorizacao__c> listSetorizacaoToUpdate = new List<Setorizacao__c>{setValid1, setValid2, setInvalid1};
        
        update listSetorizacaoToUpdate;
    }
    
    @isTest
    public static void delAccTeamMemberBySectorizationTest() {
        Setorizacao__c setValid1 = [SELECT Id, Conta__c, Vendedor__c, DataInicial__c, DataFinal__c FROM Setorizacao__c WHERE ExternalId__c = '001'][0];

        delete setValid1;
    }
    
    @isTest
    public static void SetorizacaoHelperTest() {
        SetorizacaoHelper setHelp = new SetorizacaoHelper();
        System.debug(SetorizacaoHandler.disableTrigger());
        System.debug(SetorizacaoHandler.enableTrigger());
    }
}
