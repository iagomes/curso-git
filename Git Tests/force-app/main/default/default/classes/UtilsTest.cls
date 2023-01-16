@isTest
public with sharing class UtilsTest {
    @isTest
    public static void stringIsEmptyTest() {
        String str = '';
        System.assertEquals(true, Utils.stringIsEmpty(str), 'stringIsEmptyTest');
    }

    @isTest
    public static void decimalIsEmptyTest() {
        Decimal dec;
        System.assertEquals(true, Utils.decimalIsEmpty(dec), 'decimalIsEmptyTest');
    }

    @isTest
    public static void requiredStringTest() {
        String str = 'Test';
        Utils.requiredString(str);
    }

    @isTest
    public static void clearNonDigitsTest() {
        String str = 'test\\d';
        System.assertEquals('', Utils.clearNonDigits(str), 'clearNonDigitsTest');
    }

    @isTest
    public static void stringToDecimalTest() {
        String str = '10';
        System.assertEquals(10, Utils.stringToDecimal(str), 'stringToDecimalTest');
    }

    @isTest
    public static void stringToIntegerTest() {
        String str = '10';
        System.assertEquals(10, Utils.stringToInteger(str), 'stringToIntegerTest');
    }

    @isTest
    public static void stringToDoubleTest() {
        String str = '10.10';
        System.assertEquals(10.10, Utils.stringToDouble(str), 'stringToDoubleTest');
    }

    @isTest
    public static void stringToLongTest() {
        String str = '10';
        System.assertEquals(10, Utils.stringToLong(str), 'stringToLongTest');
    }

    @isTest
    public static void stringToDateTest() {
        Date dateNow = Date.today();
        String str   = String.valueOf(dateNow);
        System.assertEquals(dateNow, Utils.stringToDate(str), 'stringToDateTest');
    }

    @isTest
    public static void stringToTimeTest() {
        Time timeNow = Time.newInstance(12, 20, 30, 0);
        String str   = '12:20:30';
        System.assertEquals(timeNow, Utils.stringToTime(str), 'stringToTimeTest Hours');
    }

    @isTest
    public static void emailAddressIsValidTest() {
        String str = '';
        System.assertEquals(true, Utils.emailAddressIsValid(str), 'emailAddressIsValidTest 1');

        str = 'test@testClass.com';
        System.assertEquals(true, Utils.emailAddressIsValid(str), 'emailAddressIsValidTest 2');

        str = 'test';
        System.assertEquals(false, Utils.emailAddressIsValid(str), 'emailAddressIsValidTest 3');
    }

    @isTest
    public static void replaceSpecialCaracterTest() {
        String str = 'Testé';
        System.assertEquals('Teste', Utils.replaceSpecialCaracter(str), 'replaceSpecialCaracterTest');
    }

    @isTest
    public static void formatCNPJTest() {
        String str = '22118175000199';
        System.assertEquals('22.118.175/0001-99', Utils.formatCNPJ(str), 'formatCNPJTest');
    }

    @isTest
    public static void formatCPFTest() {
        String str = '12345678920';
        System.assertEquals('12.345.678-92', Utils.formatCPF(str, true), 'formatCPFTest');
    }

    @isTest
    public static void formatCEPTest() {
        Integer value = 19853005;
        System.assertEquals('19853-005', Utils.formatCEP(value), 'formatCEPTest');
    }

    @isTest
    public static void leftZeroesTrimTest() {
        String str = '0123';
        System.assertEquals('123', Utils.leftZeroesTrim(str), 'leftZeroesTrimTest');
    }

    @isTest
    public static void leftZeroesFixTest() {
        Long value = 123;
        System.assertEquals('00123', Utils.leftZeroesFix(value, 2), 'leftZeroesFixTest');
    }

    @isTest
    public static void leftZeroesFillTest() {
        Long value = 123;
        System.assertEquals('00123', Utils.leftZeroesFill(value, 5), 'leftZeroesFillTest');
    }

    /*@isTest
    public static void getPicklistValuesTest() {
        Account account = TestUtility.createAccPJ();
        Order order = TestUtility.createOrder(account);
        Set<String> statusOrderList = new Set<String>{
            'Ativado', 'Em aberto (Histórico)', 'Faturado (Histórico)', 'Cancelado (Histórico)', 
            'Novo', 'Em digitação', 'Gerado pedido filho', 'Aguardando aprovação', 'Aprovado', 
            'Aguardando faturamento', 'Aguardando integração', 'Integrado/Reservado', 'Pai - Em aprovação', 
            'Pai - Aprovado', 'Liberado ERP', 'Bloqueado ERP', 'Aguardando separação', 'Separado', 
            'Faturado', 'Expedido', 'Entregue', 'Cancelado'
        };
        System.debug('Picklist: ' + statusOrderList);
        Set<String> result = Utils.getPicklistValues(??);
        System.assertEquals(statusOrderList, , 'getPicklistValuesTest');
    }

    @isTest
    public static void getPicklistApiTest() {
        Account account = TestUtility.createAccPJ();
        Order order = TestUtility.createOrder(account);
        Map<String, String> statusOrderMap = new Map<String, String>{
            'Ativado' => 'Activated', 'Em aberto (Histórico)' => 'Em aberto (Histórico)', 'Faturado (Histórico)' => 'Faturado (Histórico)',
            'Cancelado (Histórico)' => 'Cancelado (Histórico)', 'Novo' => 'Novo', 'Em digitação' => 'Em digitação', 'Gerado pedido filho' => 'Gerado pedido filho', 
            'Aguardando aprovação' => 'Aguardando aprovação', 'Aprovado' => 'Aprovado', 'Aguardando faturamento' => 'Aguardando faturamento', 
            'Aguardando integração' => 'Aguardando integração', 'Integrado/Reservado' => 'IntegradoReservado', 'Pai - Em aprovação' => 'Pai - Em aprovação', 
            'Pai - Aprovado' => 'Pai - Aprovado', 'Liberado ERP' => 'Liberado ERP', 'Bloqueado ERP' => 'Bloqueado ERP', 'Aguardando separação' => 'Aguardando separação', 
            'Separado' => 'Separado', 'Faturado' => 'Faturado', 'Expedido' => 'Expedido', 'Entregue' => 'Entregue', 'Cancelado' => 'Cancelado'
        };
        Map<String, String> mapResult = Utils.getPicklistApi(??);
        System.assertEquals(statusOrderMap, mapResult, 'getPicklistApiTest');
    }*/

    @isTest
    public static void fileSizeToStringTest() {
        Long value = 123;
        System.assertEquals('123 Bytes', Utils.fileSizeToString(value), 'fileSizeToStringTest 1');
        value = 123456;
        System.assertEquals('120.56 KB', Utils.fileSizeToString(value), 'fileSizeToStringTest 2');
        value = 1000567890;
        System.assertEquals('954.22 MB', Utils.fileSizeToString(value), 'fileSizeToStringTest 3');
        value = 1234567890;
        System.assertEquals('1.15 GB', Utils.fileSizeToString(value), 'fileSizeToStringTest 4');
    }

    @isTest
    public static void beautifyJSONTest() {
        String str        = '{"id": "0123","name": "Teste"}';
        String jsonPretty = JSON.serializePretty(JSON.deserializeUntyped(str));
        System.assertEquals(jsonPretty, Utils.beautifyJSON(str), 'beautifyJSONTest');
    }

    /*@isTest
    public static void formatExceptionMessageTest() {
        String str = '';
        String response = 'Exception: xxxx - Stack Trace: yyyy';
        System.assertEquals(response, Utils.formatExceptionMessage(), 'formatExceptionMessageTest');
    }*/

    @isTest
    public static void getAllFieldsFromObjectTest() {
        String str = 'PricebookEntry';
        /*List<String> objectFieldList = new List<String>{
            'Id', 'Name', 'Pricebook2Id', 'Product2Id', 'UnitPrice', 'IsActive', 'UseStandardPrice', 'CreatedDate', 
            'CreatedById', 'LastModifiedDate', 'ProductCode', 'PrincipioAtivo__c', 'PrecoFabrica__c', 'ExternalId__c'
        };*/

        List<String> objectFieldList = new List<String>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(str).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.values())
        {
            Schema.Describefieldresult dfield = sfield.getDescribe();
            objectFieldList.add(dfield.getName());
        }
        System.assertEquals(objectFieldList, Utils.getAllFieldsFromObject(str), 'getAllFieldsFromObjectTest');
    }
}