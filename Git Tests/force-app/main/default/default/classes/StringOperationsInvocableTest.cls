@IsTest
public with sharing class StringOperationsInvocableTest {

    @IsTest
    static void removeNoNNumbers(){
        
        List<StringOperationsInvocable.InputData> inputs = new List<StringOperationsInvocable.InputData>();
        StringOperationsInvocable.InputData input = new StringOperationsInvocable.InputData();
        input.strings = new String[]{ 'asf@. erer! 12345' };
        input.operation = 'REMOVE_NON_NUMBERS';
        inputs.add(input);
        
        List<String> results = StringOperationsInvocable.processString(inputs);

        System.assertEquals(new String[]{ '12345' }, results);
        
    }
}