@IsTest
public with sharing class StandardResponseTest {


    @IsTest
    public static void testAllMethods() {

        StandardResponse std = new StandardResponse();
        std = new StandardResponse('200');
        std = new StandardResponse('Teste','200');
        std = new StandardResponse('TESTE', 'String code', std.data);
        std.addUniqueError('Teste');
        std.addError('Teste');
        //std.addError(new Exception());
        std.addError('Teste','200');
        std.setData('Name', std.data);
        std.addError(new CustomException('test'));
        std.toJSON();
    }

    @IsTest
    public static void test_exception() {

        StandardResponse std = new StandardResponse();
        std.setData(new List<Map<String,Object>>{new Map<String,Object>{'test' => 1}});
        std.setData('test', 123);
        std.setData(std.data);
    }
}
