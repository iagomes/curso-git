@isTest
public class ContractUploadControllerTest {
    
    private static final Double DEFAULT_EPSILON = 0.0001;

    @isTest
    public static void getTemplateTest() {
        String template = ContractUploadController.getTemplate();
        system.assertNotEquals(null,template);
    }

    @isTest
    public static void insertContractErrorTest() {
        Map<String,Object> dataMap = ContractUploadController.insertContract(null);
        system.assertEquals(false,(Boolean)dataMap.get(ContractUploadConstants.IS_SUCCESS));
    }

    @isTest
    public static void insertContractErrorService() {
        Map<String,Object> dataMap = new Map<String,Object>{
            'AAAAAA' => ''
        };
        dataMap = ContractUploadController.insertContract(dataMap);
        system.assertEquals(false,(Boolean)dataMap.get(ContractUploadConstants.IS_SUCCESS));
    }    

    @isTest
    public static void insertContractTest() {
        List<Account> listAcc = new List<Account>();
        Account acc = TestUtility.createAccPJ();
        acc.ExternalId__c = '04585497000108';
        insert acc;

        Product2 prod = TestUtility.createProduct();
        insert prod;

        Contract con1 = TestUtility.createContract(acc);
        insert con1;

        List<Contract> contractList = new List<Contract>([SELECT ContractNumber FROM Contract WHERE Id = :con1.Id LIMIT 1]);
        system.debug('contractList '+contractList);
        String jsonStr = '[{"NomeProduto":"'+TestUtility.PRODUCT_TESTCODE+'","NumeroContrato":"'+contractList.get(0).ContractNumber+'","PrecoMinimo":"10","PrecoUnitario":"11","Quantidade":"10","VigenciaFinal" : "'+String.valueOf(System.today().addDays(10))+'","VigenciaInicial":"'+String.valueOf(System.today())+'"}]';
        Map<String,Object> dataMap = new Map<String,Object>{
            ContractUploadConstants.JSON_STR => jsonStr,
            ContractUploadConstants.HEADER_LIST_STR => JSON.serialize(ContractUploadController.getDataFields())
        };

        Test.startTest();
            //test insert
            dataMap = ContractUploadController.insertContract(dataMap);
            //test update
            dataMap = ContractUploadController.insertContract(dataMap);
        Test.stopTest();
        system.debug('Mesage '+(String)dataMap.get(ContractUploadConstants.MESSAGE));
        system.assertEquals(true,(Boolean)dataMap.get(ContractUploadConstants.IS_SUCCESS));
    }
}
