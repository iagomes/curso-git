@isTest
public with sharing class CloneContractTest {
    
    @isTest
    public static void testFlowCloneContract() {
        Account acc = TestUtility.createAccPJ();
        insert acc;

        Account acc2 = TestUtility.createAccount();
        insert acc2;

        Contract con = TestUtility.createContractOL(acc);
        con.TipoRegra__c = null;
        insert con;        

        Pricebook2 pricebook = new Pricebook2(
            Name = 'Pricebook Test',
            ExternalId__c = 'B01'
        );
        insert pricebook;

        Product2 product = TestUtility.createProduct();
        product.FatorConversao__c = '1';
        insert product;

        ItemContrato__c itemCont = TestUtility.createContractItem(con, product);
        insert itemCont;

        Date dt = Date.today();

        CloneContract.FlowInputs fInputs = new CloneContract.FlowInputs();
        fInputs.contractId = con.Id;
        fInputs.accountId = acc2.id;
        fInputs.vigenciaInicial = dt;
        fInputs.vigenciaFinal = dt.addDays(30);

        CloneContract.flowCloneContract(new List<CloneContract.FlowInputs>{fInputs});
    }
}
