public with sharing class StringOperationsInvocable {

    public class InputData {
        @InvocableVariable(label='Input strings' description='Strings to be processed' required=true)
        public List<String> strings;

        @InvocableVariable(label='Operation' description='Operation to be executed' required=true)
        public String operation;        
    }

    @InvocableMethod(label='Performs custom string operations' description='Return processed string according to the selected operation')
    public static List<String> processString(List<InputData> inputsData) {
      
        List<String> results = new List<String>();
        for (InputData inputData : inputsData) {
           switch on inputData.operation {
                when 'REMOVE_NON_NUMBERS' {	
                    results.addAll(removeNonNumbers(inputData.strings));
                }	
                when else {}
            }
        }

      return results;

    }

    private static List<String> removeNonNumbers(List<String> strings) {
        List<String> results = new List<String>();
        for (String str : strings) {
            results.add(StringUtils.removeNonNumericCharacters(str));
        }
        return results;
    }

}